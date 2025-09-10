import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:logger/logger.dart';

import '../models/context_chunk.dart';
import '../models/context_source.dart';
import '../models/privacy_level.dart';
import '../utils/ragify_logger.dart';
import '../sources/base_data_source.dart';

/// Realtime connection configuration
class RealtimeConfig {
  final String url;
  final String protocol; // 'websocket', 'mqtt', 'redis'
  final Map<String, dynamic> options;
  final Duration connectionTimeout;
  final Duration reconnectInterval;
  final int maxReconnectAttempts;
  final bool enableHeartbeat;
  final Duration heartbeatInterval;

  const RealtimeConfig({
    required this.url,
    required this.protocol,
    this.options = const {},
    this.connectionTimeout = const Duration(seconds: 30),
    this.reconnectInterval = const Duration(seconds: 5),
    this.maxReconnectAttempts = 5,
    this.enableHeartbeat = true,
    this.heartbeatInterval = const Duration(seconds: 30),
  });

  Map<String, dynamic> toJson() => {
    'url': url,
    'protocol': protocol,
    'options': options,
    'connection_timeout': connectionTimeout.inMilliseconds,
    'reconnect_interval': reconnectInterval.inMilliseconds,
    'max_reconnect_attempts': maxReconnectAttempts,
    'enable_heartbeat': enableHeartbeat,
    'heartbeat_interval': heartbeatInterval.inMilliseconds,
  };
}

/// Realtime message with metadata
class RealtimeMessage {
  final String id;
  final String topic;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;
  final String? sourceId;

  RealtimeMessage({
    required this.id,
    required this.topic,
    required this.data,
    required this.timestamp,
    this.metadata = const {},
    this.sourceId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'topic': topic,
    'data': data,
    'timestamp': timestamp.toIso8601String(),
    'metadata': metadata,
    'source_id': sourceId,
  };

  factory RealtimeMessage.fromJson(Map<String, dynamic> json) {
    return RealtimeMessage(
      id: json['id'] as String,
      topic: json['topic'] as String,
      data: Map<String, dynamic>.from(json['data'] ?? {}),
      timestamp: DateTime.parse(json['timestamp'] as String),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      sourceId: json['source_id'] as String?,
    );
  }
}

/// Realtime connection interface
abstract class RealtimeConnection {
  final RealtimeConfig config;
  bool _isConnected = false;
  bool _isClosed = false;
  DateTime? _lastConnected;
  DateTime? _lastMessage;
  int _messageCount = 0;
  int _errorCount = 0;

  RealtimeConnection(this.config);

  bool get isConnected => _isConnected;
  bool get isClosed => _isClosed;
  DateTime? get lastConnected => _lastConnected;
  DateTime? get lastMessage => _lastMessage;
  int get messageCount => _messageCount;
  int get errorCount => _errorCount;

  Future<void> connect();
  Future<void> disconnect();
  Future<void> subscribe(String topic);
  Future<void> unsubscribe(String topic);
  Future<void> publish(String topic, Map<String, dynamic> data);
  Stream<RealtimeMessage> get messageStream;

  void _updateConnectionStatus(bool connected) {
    _isConnected = connected;
    if (connected) {
      _lastConnected = DateTime.now();
    }
  }

  void _updateMessageReceived() {
    _lastMessage = DateTime.now();
    _messageCount++;
  }

  void _updateError() {
    _errorCount++;
  }
}

/// WebSocket connection implementation
class WebSocketConnection extends RealtimeConnection {
  WebSocketChannel? _channel;
  StreamController<RealtimeMessage>? _messageController;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;

  WebSocketConnection(super.config);

  @override
  Future<void> connect() async {
    if (_isClosed) return;

    try {
      _channel = WebSocketChannel.connect(Uri.parse(config.url));
      _messageController = StreamController<RealtimeMessage>.broadcast();

      // Listen for messages
      _channel!.stream.listen(
        (data) {
          try {
            final message = _parseWebSocketMessage(data);
            _messageController!.add(message);
            _updateMessageReceived();
          } catch (e) {
            _updateError();
            Logger().e('Error parsing WebSocket message: $e');
          }
        },
        onError: (error) {
          _updateError();
          Logger().e('WebSocket error: $error');
          _scheduleReconnect();
        },
        onDone: () {
          Logger().i('WebSocket connection closed');
          _updateConnectionStatus(false);
          if (!_isClosed) {
            _scheduleReconnect();
          }
        },
      );

      _updateConnectionStatus(true);
      _startHeartbeat();
      Logger().i('WebSocket connected to ${config.url}');
    } catch (e) {
      _updateError();
      Logger().e('Failed to connect WebSocket: $e');
      _scheduleReconnect();
    }
  }

  @override
  Future<void> disconnect() async {
    _isClosed = true;
    _stopHeartbeat();
    _stopReconnect();

    if (_channel != null) {
      await _channel!.sink.close();
      _channel = null;
    }

    if (_messageController != null) {
      await _messageController!.close();
      _messageController = null;
    }

    _updateConnectionStatus(false);
    Logger().i('WebSocket disconnected');
  }

  @override
  Future<void> subscribe(String topic) async {
    // WebSocket doesn't have built-in pub/sub, so we'll track topics locally
    // In a real implementation, you might send a subscription message to the server
    Logger().d('WebSocket subscription to topic: $topic');
  }

  @override
  Future<void> unsubscribe(String topic) async {
    Logger().d('WebSocket unsubscription from topic: $topic');
  }

  @override
  Future<void> publish(String topic, Map<String, dynamic> data) async {
    if (!_isConnected || _channel == null) {
      throw StateError('WebSocket not connected');
    }

    final message = {
      'topic': topic,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    };

    _channel!.sink.add(jsonEncode(message));
  }

  @override
  Stream<RealtimeMessage> get messageStream {
    return _messageController?.stream ?? Stream.empty();
  }

  RealtimeMessage _parseWebSocketMessage(dynamic data) {
    if (data is String) {
      final json = jsonDecode(data) as Map<String, dynamic>;
      return RealtimeMessage.fromJson(json);
    } else if (data is Map<String, dynamic>) {
      return RealtimeMessage.fromJson(data);
    } else {
      throw FormatException('Invalid WebSocket message format');
    }
  }

  void _startHeartbeat() {
    if (!config.enableHeartbeat) return;

    _heartbeatTimer = Timer.periodic(config.heartbeatInterval, (timer) {
      if (_isConnected && _channel != null) {
        _channel!.sink.add(
          jsonEncode({
            'type': 'heartbeat',
            'timestamp': DateTime.now().toIso8601String(),
          }),
        );
      }
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _scheduleReconnect() {
    if (_isClosed || _reconnectAttempts >= config.maxReconnectAttempts) return;

    _reconnectTimer = Timer(config.reconnectInterval, () async {
      _reconnectAttempts++;
      Logger().i(
        'Attempting WebSocket reconnection ($_reconnectAttempts/${config.maxReconnectAttempts})',
      );
      await connect();
    });
  }

  void _stopReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }
}

/// MQTT connection implementation (placeholder for future implementation)
class MQTTConnection extends RealtimeConnection {
  StreamController<RealtimeMessage>? _messageController;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  final Set<String> _subscribedTopics = {};

  MQTTConnection(super.config);

  @override
  Future<void> connect() async {
    if (_isClosed) return;

    try {
      // TODO: Implement MQTT connection when mqtt_client package is added
      Logger().w(
        'MQTT support not yet implemented. Please add mqtt_client package to pubspec.yaml',
      );

      _messageController = StreamController<RealtimeMessage>.broadcast();
      _updateConnectionStatus(true);
      _startHeartbeat();
      Logger().i('MQTT placeholder connected (not functional)');
    } catch (e) {
      _updateError();
      Logger().e('Failed to connect MQTT: $e');
      _scheduleReconnect();
    }
  }

  @override
  Future<void> disconnect() async {
    _isClosed = true;
    _stopHeartbeat();
    _stopReconnect();

    if (_messageController != null) {
      await _messageController!.close();
      _messageController = null;
    }

    _updateConnectionStatus(false);
    Logger().i('MQTT placeholder disconnected');
  }

  @override
  Future<void> subscribe(String topic) async {
    if (!_isConnected) {
      throw StateError('MQTT not connected');
    }

    _subscribedTopics.add(topic);
    Logger().d('MQTT placeholder subscribed to topic: $topic (not functional)');
  }

  @override
  Future<void> unsubscribe(String topic) async {
    if (!_isConnected) {
      throw StateError('MQTT not connected');
    }

    _subscribedTopics.remove(topic);
    Logger().d(
      'MQTT placeholder unsubscribed from topic: $topic (not functional)',
    );
  }

  @override
  Future<void> publish(String topic, Map<String, dynamic> data) async {
    if (!_isConnected) {
      throw StateError('MQTT not connected');
    }

    Logger().d('MQTT placeholder published to topic: $topic (not functional)');
  }

  @override
  Stream<RealtimeMessage> get messageStream {
    return _messageController?.stream ?? Stream.empty();
  }

  void _startHeartbeat() {
    if (!config.enableHeartbeat) return;

    _heartbeatTimer = Timer.periodic(config.heartbeatInterval, (timer) {
      if (_isConnected) {
        Logger().d('MQTT placeholder heartbeat (not functional)');
      }
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _scheduleReconnect() {
    if (_isClosed || _reconnectAttempts >= config.maxReconnectAttempts) return;

    _reconnectTimer = Timer(config.reconnectInterval, () async {
      _reconnectAttempts++;
      Logger().i(
        'Attempting MQTT placeholder reconnection ($_reconnectAttempts/${config.maxReconnectAttempts})',
      );
      await connect();
    });
  }

  void _stopReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }
}

/// Redis pub/sub connection implementation (placeholder for future implementation)
class RedisConnection extends RealtimeConnection {
  StreamController<RealtimeMessage>? _messageController;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  final Set<String> _subscribedChannels = {};

  RedisConnection(super.config);

  @override
  Future<void> connect() async {
    if (_isClosed) return;

    try {
      // TODO: Implement Redis connection when redis package is added
      Logger().w(
        'Redis support not yet implemented. Please add redis package to pubspec.yaml',
      );

      _messageController = StreamController<RealtimeMessage>.broadcast();
      _updateConnectionStatus(true);
      _startHeartbeat();
      Logger().i('Redis placeholder connected (not functional)');
    } catch (e) {
      _updateError();
      Logger().e('Failed to connect Redis: $e');
      _scheduleReconnect();
    }
  }

  @override
  Future<void> disconnect() async {
    _isClosed = true;
    _stopHeartbeat();
    _stopReconnect();

    if (_messageController != null) {
      await _messageController!.close();
      _messageController = null;
    }

    _updateConnectionStatus(false);
    Logger().i('Redis placeholder disconnected');
  }

  @override
  Future<void> subscribe(String channel) async {
    if (!_isConnected) {
      throw StateError('Redis not connected');
    }

    _subscribedChannels.add(channel);
    Logger().d(
      'Redis placeholder subscribed to channel: $channel (not functional)',
    );
  }

  @override
  Future<void> unsubscribe(String channel) async {
    if (!_isConnected) {
      throw StateError('Redis not connected');
    }

    _subscribedChannels.remove(channel);
    Logger().d(
      'Redis placeholder unsubscribed from channel: $channel (not functional)',
    );
  }

  @override
  Future<void> publish(String channel, Map<String, dynamic> data) async {
    if (!_isConnected) {
      throw StateError('Redis not connected');
    }

    Logger().d(
      'Redis placeholder published to channel: $channel (not functional)',
    );
  }

  @override
  Stream<RealtimeMessage> get messageStream {
    return _messageController?.stream ?? Stream.empty();
  }

  void _startHeartbeat() {
    if (!config.enableHeartbeat) return;

    _heartbeatTimer = Timer.periodic(config.heartbeatInterval, (timer) {
      if (_isConnected) {
        Logger().d('Redis placeholder heartbeat (not functional)');
      }
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _scheduleReconnect() {
    if (_isClosed || _reconnectAttempts >= config.maxReconnectAttempts) return;

    _reconnectTimer = Timer(config.reconnectInterval, () async {
      _reconnectAttempts++;
      Logger().i(
        'Attempting Redis placeholder reconnection ($_reconnectAttempts/${config.maxReconnectAttempts})',
      );
      await connect();
    });
  }

  void _stopReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }
}

/// Main RealtimeSource class that integrates all realtime protocols
class RealtimeSource extends BaseDataSource {
  final RealtimeConfig realtimeConfig;
  late final RealtimeConnection _connection;
  final List<RealtimeMessage> _messageBuffer = [];
  final int _maxBufferSize;
  final StreamController<ContextChunk> _chunkController;
  final RAGifyLogger _logger;

  bool _isInitialized = false;
  bool _isSubscribed = false;
  final Set<String> _subscribedTopics = {};
  final Map<String, DateTime> _lastMessageTime = {};
  final Map<String, int> _messageCounts = {};

  // BaseDataSource required fields
  @override
  final String name;
  @override
  final SourceType sourceType;
  final String url;
  final PrivacyLevel privacyLevel;
  final Map<String, dynamic> _metadata;

  RealtimeSource({
    required this.realtimeConfig,
    required this.name,
    required this.sourceType,
    required this.url,
    required this.privacyLevel,
    Map<String, dynamic>? metadata,
    int maxBufferSize = 1000,
    RAGifyLogger? logger,
  }) : _maxBufferSize = maxBufferSize,
       _metadata = metadata ?? const {},
       _chunkController = StreamController<ContextChunk>.broadcast(),
       _logger = logger ?? const RAGifyLogger.disabled() {
    _connection = _createConnection();
  }

  /// Create appropriate connection based on protocol
  RealtimeConnection _createConnection() {
    switch (realtimeConfig.protocol.toLowerCase()) {
      case 'websocket':
        return WebSocketConnection(realtimeConfig);
      case 'mqtt':
        return MQTTConnection(realtimeConfig);
      case 'redis':
        return RedisConnection(realtimeConfig);
      default:
        throw ArgumentError(
          'Unsupported realtime protocol: ${realtimeConfig.protocol}',
        );
    }
  }

  @override
  Map<String, dynamic> get config => {
    'protocol': realtimeConfig.protocol,
    'url': realtimeConfig.url,
    'options': realtimeConfig.options,
    'connection_timeout': realtimeConfig.connectionTimeout.inMilliseconds,
    'reconnect_interval': realtimeConfig.reconnectInterval.inMilliseconds,
    'max_reconnect_attempts': realtimeConfig.maxReconnectAttempts,
    'enable_heartbeat': realtimeConfig.enableHeartbeat,
    'heartbeat_interval': realtimeConfig.heartbeatInterval.inMilliseconds,
  };

  @override
  Map<String, dynamic> get metadata => _metadata;

  @override
  bool get isActive => _isInitialized && _connection.isConnected;

  @override
  ContextSource get source => ContextSource(
    id: 'realtime_${name}_${DateTime.now().millisecondsSinceEpoch}',
    name: name,
    sourceType: sourceType,
    url: url,
    metadata: _metadata,
    lastUpdated: DateTime.now(),
    isActive: isActive,
    privacyLevel: privacyLevel,
    authorityScore: 0.8,
    freshnessScore: 1.0,
  );

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _connection.connect();
      _isInitialized = true;
      _logger.i('RealtimeSource initialized: ${realtimeConfig.protocol}');
    } catch (e) {
      _logger.e('Failed to initialize RealtimeSource: $e');
      rethrow;
    }
  }

  @override
  Future<List<ContextChunk>> getChunks({
    required String query,
    int? maxChunks,
    double minRelevance = 0.0,
    String? userId,
    String? sessionId,
  }) async {
    if (!_isInitialized) {
      return [];
    }

    // Filter messages based on query and convert to chunks
    final filteredMessages = _messageBuffer
        .where((msg) => _matchesQuery(msg, query))
        .take(maxChunks ?? _maxBufferSize)
        .toList();

    return filteredMessages.map((msg) => _messageToChunk(msg)).toList();
  }

  @override
  Future<void> refresh() async {
    if (!_isInitialized) return;

    // Reconnect to refresh the connection
    await _connection.disconnect();
    await _connection.connect();

    // Resubscribe to all topics
    for (final topic in _subscribedTopics) {
      await _connection.subscribe(topic);
    }
  }

  @override
  Future<Map<String, dynamic>> getStats() async {
    return {
      'protocol': realtimeConfig.protocol,
      'url': realtimeConfig.url,
      'is_initialized': _isInitialized,
      'is_connected': _connection.isConnected,
      'is_subscribed': _isSubscribed,
      'subscribed_topics': _subscribedTopics.toList(),
      'message_buffer_size': _messageBuffer.length,
      'max_buffer_size': _maxBufferSize,
      'total_messages_received': _connection.messageCount,
      'total_errors': _connection.errorCount,
      'last_connected': _connection.lastConnected?.toIso8601String(),
      'last_message': _connection.lastMessage?.toIso8601String(),
      'topic_message_counts': _messageCounts,
      'last_message_times': _lastMessageTime.map(
        (k, v) => MapEntry(k, v.toIso8601String()),
      ),
    };
  }

  @override
  Future<bool> isHealthy() async {
    if (!_isInitialized) return false;
    return _connection.isConnected;
  }

  @override
  Future<SourceStatus> getStatus() async {
    if (!_isInitialized) return SourceStatus.offline;

    final isHealthy = await this.isHealthy();
    if (isHealthy) {
      return SourceStatus.healthy;
    } else {
      return SourceStatus.unhealthy;
    }
  }

  @override
  Future<void> updateMetadata(Map<String, dynamic> metadata) async {
    // Update metadata
    _metadata.addAll(metadata);
  }

  @override
  Map<String, dynamic> getConfiguration() {
    return config;
  }

  @override
  Future<void> updateConfiguration(Map<String, dynamic> config) async {
    // Update configuration
    // Note: This is a simplified implementation
    Logger().w('Configuration update not fully implemented for RealtimeSource');
  }

  /// Subscribe to a topic/channel
  Future<void> subscribe(String topic) async {
    if (!_isInitialized) {
      throw StateError('RealtimeSource not initialized');
    }

    await _connection.subscribe(topic);
    _subscribedTopics.add(topic);
    _isSubscribed = true;

    // Start listening for messages on this topic
    _connection.messageStream.listen((message) {
      _processMessage(message);
    });

    _logger.i('Subscribed to topic: $topic');
  }

  /// Unsubscribe from a topic/channel
  Future<void> unsubscribe(String topic) async {
    if (!_isInitialized) {
      throw StateError('RealtimeSource not initialized');
    }

    await _connection.unsubscribe(topic);
    _subscribedTopics.remove(topic);
    _isSubscribed = _subscribedTopics.isNotEmpty;

    _logger.i('Unsubscribed from topic: $topic');
  }

  /// Publish a message to a topic/channel
  Future<void> publish(String topic, Map<String, dynamic> data) async {
    if (!_isInitialized) {
      throw StateError('RealtimeSource not initialized');
    }

    await _connection.publish(topic, data);
    _logger.d('Published message to topic: $topic');
  }

  /// Get stream of context chunks from realtime messages
  Stream<ContextChunk> get chunkStream => _chunkController.stream;

  /// Process incoming realtime message
  void _processMessage(RealtimeMessage message) {
    // Update message tracking
    _lastMessageTime[message.topic] = message.timestamp;
    _messageCounts[message.topic] = (_messageCounts[message.topic] ?? 0) + 1;

    // Add to buffer
    _messageBuffer.add(message);

    // Maintain buffer size
    if (_messageBuffer.length > _maxBufferSize) {
      _messageBuffer.removeAt(0);
    }

    // Convert to context chunk and emit
    final chunk = _messageToChunk(message);
    _chunkController.add(chunk);

    _logger.d('Processed message from topic: ${message.topic}');
  }

  /// Convert realtime message to context chunk
  ContextChunk _messageToChunk(RealtimeMessage message) {
    return ContextChunk(
      id: message.id,
      content: jsonEncode(message.data),
      metadata: {
        ...message.metadata,
        'topic': message.topic,
        'source_id': message.sourceId,
        'protocol': realtimeConfig.protocol,
        'timestamp': message.timestamp.toIso8601String(),
      },
      source: source,
      createdAt: message.timestamp,
      updatedAt: message.timestamp,
      relevanceScore:
          null, // Realtime messages don't have relevance scores initially
      tags: ['realtime', realtimeConfig.protocol, message.topic],
    );
  }

  /// Check if message matches query
  bool _matchesQuery(RealtimeMessage message, String query) {
    if (query.isEmpty) return true;

    final queryLower = query.toLowerCase();
    final topicLower = message.topic.toLowerCase();
    final dataString = jsonEncode(message.data).toLowerCase();

    return topicLower.contains(queryLower) || dataString.contains(queryLower);
  }

  /// Get connection health information
  Map<String, dynamic> getConnectionHealth() {
    return {
      'is_connected': _connection.isConnected,
      'last_connected': _connection.lastConnected?.toIso8601String(),
      'last_message': _connection.lastMessage?.toIso8601String(),
      'message_count': _connection.messageCount,
      'error_count': _connection.errorCount,
      'protocol': realtimeConfig.protocol,
      'url': realtimeConfig.url,
    };
  }

  /// Set message buffer size
  void setBufferSize(int size) {
    if (size < 1) {
      throw ArgumentError('Buffer size must be at least 1');
    }

    while (_messageBuffer.length > size) {
      _messageBuffer.removeAt(0);
    }
  }

  /// Clear message buffer
  void clearBuffer() {
    _messageBuffer.clear();
    _messageCounts.clear();
    _lastMessageTime.clear();
  }

  @override
  Future<void> close() async {
    _isInitialized = false;
    _isSubscribed = false;

    await _connection.disconnect();
    await _chunkController.close();

    _logger.i('RealtimeSource closed');
  }
}
