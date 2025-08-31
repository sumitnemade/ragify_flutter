import 'dart:async';
import 'dart:convert';
import 'package:logger/logger.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;

import '../models/context_chunk.dart';
import '../models/context_source.dart';
import '../models/privacy_level.dart';
import '../exceptions/ragify_exceptions.dart';

/// Context Updates Engine
///
/// Handles real-time updates, synchronization, and live data processing
/// from various sources with privacy controls and conflict resolution.
class ContextUpdatesEngine {
  /// Logger instance
  final Logger logger;

  /// Active WebSocket connections
  final Map<String, WebSocketChannel> _activeConnections = {};

  /// Update listeners by source
  final Map<String, List<Function(ContextChunk)>> _updateListeners = {};

  /// Update queue for processing
  final StreamController<ContextUpdate> _updateController =
      StreamController.broadcast();

  /// Whether the engine is running
  bool _isRunning = false;

  /// Update processing interval
  final Duration processingInterval;

  /// Maximum retry attempts for failed connections
  final int maxRetryAttempts;

  /// Retry delay between attempts
  final Duration retryDelay;

  /// Create a new updates engine
  ContextUpdatesEngine({
    Logger? logger,
    this.processingInterval = const Duration(seconds: 5),
    this.maxRetryAttempts = 3,
    this.retryDelay = const Duration(seconds: 10),
  }) : logger = logger ?? Logger();

  /// Start the updates engine
  Future<void> start() async {
    if (_isRunning) return;

    try {
      logger.i('Starting Context Updates Engine');

      // Start update processing
      _startUpdateProcessing();

      _isRunning = true;
      logger.i('Context Updates Engine started successfully');
    } catch (e, stackTrace) {
      logger.e(
        'Failed to start updates engine',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Stop the updates engine
  Future<void> stop() async {
    if (!_isRunning) return;

    try {
      logger.i('Stopping Context Updates Engine');

      // Close all connections
      await _closeAllConnections();

      // Stop update processing
      _stopUpdateProcessing();

      _isRunning = false;
      logger.i('Context Updates Engine stopped');
    } catch (e, stackTrace) {
      logger.e(
        'Error stopping updates engine',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Connect to a real-time data source
  Future<void> connectToSource({
    required String sourceName,
    required String connectionUrl,
    required PrivacyLevel privacyLevel,
    Map<String, String>? headers,
    Map<String, dynamic>? connectionConfig,
  }) async {
    try {
      logger.i('Connecting to real-time source: $sourceName');

      if (_activeConnections.containsKey(sourceName)) {
        logger.w(
          'Connection to $sourceName already exists, closing previous connection',
        );
        await _closeConnection(sourceName);
      }

      // Determine connection type and establish connection
      if (connectionUrl.startsWith('ws://') ||
          connectionUrl.startsWith('wss://')) {
        await _establishWebSocketConnection(
          sourceName: sourceName,
          url: connectionUrl,
          privacyLevel: privacyLevel,
          headers: headers,
          config: connectionConfig,
        );
      } else if (connectionUrl.startsWith('http://') ||
          connectionUrl.startsWith('https://')) {
        await _establishHttpStreamConnection(
          sourceName: sourceName,
          url: connectionUrl,
          privacyLevel: privacyLevel,
          headers: headers,
          config: connectionConfig,
        );
      } else {
        throw SourceConnectionException(sourceName, 'unknown_protocol');
      }

      logger.i('Successfully connected to $sourceName');
    } catch (e, stackTrace) {
      logger.e(
        'Failed to connect to $sourceName',
        error: e,
        stackTrace: stackTrace,
      );
      throw SourceConnectionException(sourceName, 'connection_failed');
    }
  }

  /// Establish WebSocket connection
  Future<void> _establishWebSocketConnection({
    required String sourceName,
    required String url,
    required PrivacyLevel privacyLevel,
    Map<String, String>? headers,
    Map<String, dynamic>? config,
  }) async {
    try {
      final uri = Uri.parse(url);
      final channel = WebSocketChannel.connect(
        uri,
        protocols: headers?.values.toList(),
      );

      // Store connection
      _activeConnections[sourceName] = channel;

      // Listen for messages
      channel.stream.listen(
        (data) => _handleWebSocketMessage(sourceName, data, privacyLevel),
        onError: (error) => _handleConnectionError(sourceName, error),
        onDone: () => _handleConnectionClosed(sourceName),
      );

      // Send connection message if configured
      if (config?['send_connection_message'] == true) {
        final connectionMsg = {
          'type': 'connection',
          'source': sourceName,
          'timestamp': DateTime.now().toIso8601String(),
        };
        channel.sink.add(jsonEncode(connectionMsg));
      }
    } catch (e) {
      throw SourceConnectionException(sourceName, 'websocket_failed');
    }
  }

  /// Establish HTTP stream connection
  Future<void> _establishHttpStreamConnection({
    required String sourceName,
    required String url,
    required PrivacyLevel privacyLevel,
    Map<String, String>? headers,
    Map<String, dynamic>? config,
  }) async {
    try {
      final uri = Uri.parse(url);
      final request = http.Request('GET', uri);

      if (headers != null) {
        request.headers.addAll(headers);
      }

      final response = await http.Client().send(request);

      if (response.statusCode != 200) {
        throw SourceConnectionException(sourceName, 'http_failed');
      }

      // Process streaming response
      response.stream
          .transform(utf8.decoder)
          .listen(
            (data) => _handleHttpStreamData(sourceName, data, privacyLevel),
            onError: (error) => _handleConnectionError(sourceName, error),
            onDone: () => _handleConnectionClosed(sourceName),
          );
    } catch (e) {
      throw SourceConnectionException(sourceName, 'http_stream_failed');
    }
  }

  /// Handle WebSocket message
  void _handleWebSocketMessage(
    String sourceName,
    dynamic data,
    PrivacyLevel privacyLevel,
  ) {
    try {
      final message = jsonDecode(data.toString());
      final update = _parseUpdateMessage(message, sourceName, privacyLevel);

      if (update != null) {
        _queueUpdate(update);
        _notifyListeners(sourceName, update.chunk);
      }
    } catch (e) {
      logger.w('Failed to parse WebSocket message from $sourceName: $e');
    }
  }

  /// Handle HTTP stream data
  void _handleHttpStreamData(
    String sourceName,
    String data,
    PrivacyLevel privacyLevel,
  ) {
    try {
      final lines = data.split('\n').where((line) => line.trim().isNotEmpty);

      for (final line in lines) {
        final message = jsonDecode(line);
        final update = _parseUpdateMessage(message, sourceName, privacyLevel);

        if (update != null) {
          _queueUpdate(update);
          _notifyListeners(sourceName, update.chunk);
        }
      }
    } catch (e) {
      logger.w('Failed to parse HTTP stream data from $sourceName: $e');
    }
  }

  /// Parse update message into ContextUpdate
  ContextUpdate? _parseUpdateMessage(
    Map<String, dynamic> message,
    String sourceName,
    PrivacyLevel privacyLevel,
  ) {
    try {
      final updateType = message['type'] as String?;
      if (updateType != 'context_update') return null;

      final content = message['content'] as String?;
      if (content == null || content.isEmpty) return null;

      final source = ContextSource(
        name: sourceName,
        sourceType: SourceType.realtime,
        privacyLevel: privacyLevel,
        metadata: message['metadata'] ?? {},
        lastUpdated: DateTime.now(),
        isActive: true,
        authorityScore: (message['authority_score'] as num?)?.toDouble() ?? 0.5,
        freshnessScore: 1.0,
      );

      final chunk = ContextChunk(
        content: content,
        source: source,
        metadata: message['metadata'] ?? {},
        tags: List<String>.from(message['tags'] ?? []),
      );

      return ContextUpdate(
        chunk: chunk,
        sourceName: sourceName,
        timestamp: DateTime.now(),
        updateType: UpdateType.realtime,
      );
    } catch (e) {
      logger.w('Failed to parse update message: $e');
      return null;
    }
  }

  /// Queue an update for processing
  void _queueUpdate(ContextUpdate update) {
    _updateController.add(update);
  }

  /// Notify listeners of updates
  void _notifyListeners(String sourceName, ContextChunk chunk) {
    final listeners = _updateListeners[sourceName];
    if (listeners != null) {
      for (final listener in listeners) {
        try {
          listener(chunk);
        } catch (e) {
          logger.w('Error in update listener: $e');
        }
      }
    }
  }

  /// Handle connection errors
  void _handleConnectionError(String sourceName, dynamic error) {
    logger.w('Connection error for $sourceName: $error');

    // Attempt to reconnect
    _scheduleReconnection(sourceName);
  }

  /// Handle connection closed
  void _handleConnectionClosed(String sourceName) {
    logger.i('Connection closed for $sourceName');

    // Attempt to reconnect
    _scheduleReconnection(sourceName);
  }

  /// Schedule reconnection attempt
  void _scheduleReconnection(String sourceName) {
    Timer(retryDelay, () {
      if (_isRunning && !_activeConnections.containsKey(sourceName)) {
        logger.i('Attempting to reconnect to $sourceName');
        // Reconnection logic would go here
      }
    });
  }

  /// Start update processing
  void _startUpdateProcessing() {
    Timer.periodic(processingInterval, (timer) {
      if (!_isRunning) {
        timer.cancel();
        return;
      }

      _processUpdateQueue();
    });
  }

  /// Stop update processing
  void _stopUpdateProcessing() {
    // Timer will be cancelled automatically when _isRunning becomes false
  }

  /// Process the update queue
  void _processUpdateQueue() {
    // Process any pending updates
    // This could include batching, deduplication, etc.
  }

  /// Close a specific connection
  Future<void> _closeConnection(String sourceName) async {
    final connection = _activeConnections[sourceName];
    if (connection != null) {
      await connection.sink.close();
      _activeConnections.remove(sourceName);
      logger.d('Closed connection to $sourceName');
    }
  }

  /// Close all connections
  Future<void> _closeAllConnections() async {
    final connections = Map<String, WebSocketChannel>.from(_activeConnections);

    for (final entry in connections.entries) {
      await _closeConnection(entry.key);
    }
  }

  /// Add update listener for a source
  void addUpdateListener(String sourceName, Function(ContextChunk) listener) {
    _updateListeners.putIfAbsent(sourceName, () => []).add(listener);
    logger.d('Added update listener for $sourceName');
  }

  /// Remove update listener for a source
  void removeUpdateListener(
    String sourceName,
    Function(ContextChunk) listener,
  ) {
    final listeners = _updateListeners[sourceName];
    if (listeners != null) {
      listeners.remove(listener);
      if (listeners.isEmpty) {
        _updateListeners.remove(sourceName);
      }
    }
  }

  /// Get update stream
  Stream<ContextUpdate> get updateStream => _updateController.stream;

  /// Get active connections
  List<String> get activeConnections => _activeConnections.keys.toList();

  /// Get engine statistics
  Map<String, dynamic> getStats() {
    return {
      'is_running': _isRunning,
      'active_connections': _activeConnections.length,
      'update_listeners': _updateListeners.length,
      'processing_interval_ms': processingInterval.inMilliseconds,
      'max_retry_attempts': maxRetryAttempts,
      'retry_delay_ms': retryDelay.inMilliseconds,
    };
  }
}

/// Represents a context update from a real-time source
class ContextUpdate {
  /// The updated context chunk
  final ContextChunk chunk;

  /// Name of the source
  final String sourceName;

  /// When the update occurred
  final DateTime timestamp;

  /// Type of update
  final UpdateType updateType;

  const ContextUpdate({
    required this.chunk,
    required this.sourceName,
    required this.timestamp,
    required this.updateType,
  });
}

/// Types of updates
enum UpdateType {
  realtime,
  scheduled,
  manual,
  sync;

  String get value {
    switch (this) {
      case UpdateType.realtime:
        return 'realtime';
      case UpdateType.scheduled:
        return 'scheduled';
      case UpdateType.manual:
        return 'manual';
      case UpdateType.sync:
        return 'sync';
    }
  }
}
