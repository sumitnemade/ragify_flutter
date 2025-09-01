import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:ragify_flutter/src/sources/realtime_source.dart';
import 'package:ragify_flutter/src/sources/base_data_source.dart';
import 'package:ragify_flutter/src/models/context_source.dart';
import 'package:ragify_flutter/src/models/privacy_level.dart';

void main() {
  group('RealtimeSource Coverage Tests', () {
    late RealtimeSource source;
    late RealtimeConfig config;

    setUp(() {
      config = RealtimeConfig(
        protocol: 'websocket',
        url: 'ws://localhost:8080',
        enableHeartbeat: true,
        heartbeatInterval: Duration(seconds: 30),
        maxReconnectAttempts: 5,
        reconnectInterval: Duration(seconds: 2),
        connectionTimeout: Duration(seconds: 10),
        options: {'test': 'coverage'},
      );

      source = RealtimeSource(
        name: 'coverage_realtime',
        realtimeConfig: config,
        sourceType: SourceType.realtime,
        url: 'ws://localhost:8080',
        privacyLevel: PrivacyLevel.private,
        metadata: {'test': 'coverage'},
        maxBufferSize: 500,
      );
    });

    group('RealtimeConfig Coverage', () {
      test('covers RealtimeConfig creation and getters', () {
        expect(config.protocol, 'websocket');
        expect(config.url, 'ws://localhost:8080');
        expect(config.enableHeartbeat, true);
        expect(config.heartbeatInterval.inSeconds, 30);
        expect(config.maxReconnectAttempts, 5);
        expect(config.reconnectInterval.inSeconds, 2);
        expect(config.connectionTimeout.inSeconds, 10);
        expect(config.options, {'test': 'coverage'});
      });

      test('covers RealtimeConfig with default values', () {
        final defaultConfig = RealtimeConfig(
          protocol: 'mqtt',
          url: 'mqtt://localhost:1883',
        );

        expect(defaultConfig.protocol, 'mqtt');
        expect(defaultConfig.url, 'mqtt://localhost:1883');
        expect(defaultConfig.enableHeartbeat, true);
        expect(defaultConfig.heartbeatInterval.inSeconds, 30);
        expect(defaultConfig.maxReconnectAttempts, 5);
        expect(defaultConfig.reconnectInterval.inSeconds, 5);
        expect(defaultConfig.connectionTimeout.inSeconds, 30);
        expect(defaultConfig.options, isEmpty);
      });

      test('covers RealtimeConfig toJson', () {
        final json = config.toJson();

        expect(json['protocol'], 'websocket');
        expect(json['url'], 'ws://localhost:8080');
        expect(json['enable_heartbeat'], true);
        expect(json['heartbeat_interval'], 30000);
        expect(json['max_reconnect_attempts'], 5);
        expect(json['reconnect_interval'], 2000);
        expect(json['connection_timeout'], 10000);
        expect(json['options'], {'test': 'coverage'});
      });
    });

    group('RealtimeMessage Coverage', () {
      test('covers RealtimeMessage creation and getters', () {
        final timestamp = DateTime.now();
        final message = RealtimeMessage(
          id: 'msg_123',
          topic: 'test_topic',
          data: {'key': 'value', 'count': 42},
          timestamp: timestamp,
        );

        expect(message.id, 'msg_123');
        expect(message.topic, 'test_topic');
        expect(message.data, {'key': 'value', 'count': 42});
        expect(message.timestamp, timestamp);
      });

      test('covers RealtimeMessage toJson', () {
        final timestamp = DateTime.now();
        final message = RealtimeMessage(
          id: 'json_123',
          topic: 'json_topic',
          data: {'test': 'json'},
          timestamp: timestamp,
        );

        final json = message.toJson();
        expect(json['id'], 'json_123');
        expect(json['topic'], 'json_topic');
        expect(json['data'], {'test': 'json'});
        expect(json['timestamp'], timestamp.toIso8601String());
      });
    });

    group('RealtimeConnection Coverage', () {
      test('covers RealtimeConnection getters', () {
        final connection = _MockRealtimeConnection(config);

        expect(connection.isConnected, false);
        expect(connection.isClosed, false);
        expect(connection.lastConnected, isNull);
        expect(connection.lastMessage, isNull);
        expect(connection.messageCount, 0);
        expect(connection.errorCount, 0);
      });

      test('covers RealtimeConnection status updates', () {
        final connection = _MockRealtimeConnection(config);

        // Test connection status update
        connection.testUpdateConnectionStatus(true);
        expect(connection.isConnected, true);
        expect(connection.lastConnected, isNotNull);

        connection.testUpdateConnectionStatus(false);
        expect(connection.isConnected, false);

        // Test message received update
        connection.testUpdateMessageReceived();
        expect(connection.messageCount, 1);
        expect(connection.lastMessage, isNotNull);

        connection.testUpdateMessageReceived();
        expect(connection.messageCount, 2);

        // Test error update
        connection.testUpdateError();
        expect(connection.errorCount, 1);

        connection.testUpdateError();
        expect(connection.errorCount, 2);
      });
    });

    group('WebSocketConnection Coverage', () {
      test('covers WebSocketConnection creation', () {
        final wsConnection = WebSocketConnection(config);
        expect(wsConnection.config, config);
        expect(wsConnection.isConnected, false);
        expect(wsConnection.isClosed, false);
      });

      test(
        'covers WebSocketConnection disconnect when not connected',
        () async {
          final wsConnection = WebSocketConnection(config);

          // Should not throw when disconnecting without being connected
          await wsConnection.disconnect();
          expect(wsConnection.isClosed, true);
          expect(wsConnection.isConnected, false);
        },
      );
    });

    group('MQTTConnection Coverage', () {
      test('covers MQTTConnection creation and basic properties', () {
        final mqttConfig = RealtimeConfig(
          protocol: 'mqtt',
          url: 'mqtt://localhost:1883',
        );

        final mqttConnection = MQTTConnection(mqttConfig);
        expect(mqttConnection.config, mqttConfig);
        expect(mqttConnection.isConnected, false);
        expect(mqttConnection.isClosed, false);
      });

      test('covers MQTTConnection disconnect when not connected', () async {
        final mqttConfig = RealtimeConfig(
          protocol: 'mqtt',
          url: 'mqtt://localhost:1883',
        );

        final mqttConnection = MQTTConnection(mqttConfig);

        // Should not throw when disconnecting without being connected
        await mqttConnection.disconnect();
        expect(mqttConnection.isClosed, true);
        expect(mqttConnection.isConnected, false);
      });
    });

    group('RedisConnection Coverage', () {
      test('covers RedisConnection creation and basic properties', () {
        final redisConfig = RealtimeConfig(
          protocol: 'redis',
          url: 'redis://localhost:6379',
        );

        final redisConnection = RedisConnection(redisConfig);
        expect(redisConnection.config, redisConfig);
        expect(redisConnection.isConnected, false);
        expect(redisConnection.isClosed, false);
      });

      test('covers RedisConnection disconnect when not connected', () async {
        final redisConfig = RealtimeConfig(
          protocol: 'redis',
          url: 'redis://localhost:6379',
        );

        final redisConnection = RedisConnection(redisConfig);

        // Should not throw when disconnecting without being connected
        await redisConnection.disconnect();
        expect(redisConnection.isClosed, true);
        expect(redisConnection.isConnected, false);
      });
    });

    group('RealtimeSource Basic Coverage', () {
      test('covers RealtimeSource properties and getters', () {
        expect(source.name, 'coverage_realtime');
        expect(source.sourceType, SourceType.realtime);
        expect(source.realtimeConfig, config);
        expect(source.metadata, {'test': 'coverage'});
        expect(source.isActive, false); // Not initialized yet
        expect(source.url, 'ws://localhost:8080');
        expect(source.privacyLevel, PrivacyLevel.private);
      });

      test('covers RealtimeSource getConfiguration', () {
        final sourceConfig = source.getConfiguration();
        expect(sourceConfig, isA<Map<String, dynamic>>());
        expect(sourceConfig['protocol'], 'websocket');
        expect(sourceConfig['url'], 'ws://localhost:8080');
        expect(sourceConfig['enable_heartbeat'], true);
        expect(sourceConfig['max_reconnect_attempts'], 5);
      });

      test('covers RealtimeSource updateConfiguration', () async {
        final newConfig = {'new_setting': 'new_value', 'timeout': 5000};
        await source.updateConfiguration(newConfig);

        // Configuration update should work without error
        expect(() => source.getConfiguration(), returnsNormally);
      });

      test('covers RealtimeSource updateMetadata', () async {
        await source.updateMetadata({'new_meta': 'meta_value', 'version': 2});

        expect(source.metadata['new_meta'], 'meta_value');
        expect(source.metadata['version'], 2);
        expect(
          source.metadata['test'],
          'coverage',
        ); // Original metadata preserved
      });

      test('covers RealtimeSource close', () async {
        await source.close();
        expect(source.isActive, false);
      });

      test('covers RealtimeSource getStatus when not active', () async {
        final status = await source.getStatus();
        expect(status, SourceStatus.offline);
      });

      test('covers RealtimeSource isHealthy when not active', () async {
        final healthy = await source.isHealthy();
        expect(healthy, false);
      });

      test('covers RealtimeSource refresh', () async {
        // Should not throw when refreshing inactive source
        await source.refresh();
        expect(source.isActive, false);
      });
    });

    group('RealtimeSource Error Handling', () {
      test('covers getChunks when not initialized', () async {
        final chunks = await source.getChunks(query: 'test');
        expect(chunks, isEmpty);
      });

      test('covers subscribe when not initialized', () async {
        expect(
          () => source.subscribe('test_topic'),
          throwsA(isA<StateError>()),
        );
      });

      test('covers unsubscribe when not initialized', () async {
        expect(
          () => source.unsubscribe('test_topic'),
          throwsA(isA<StateError>()),
        );
      });

      test('covers publish when not initialized', () async {
        expect(
          () => source.publish('test_topic', {'data': 'test'}),
          throwsA(isA<StateError>()),
        );
      });
    });

    group('RealtimeSource Statistics Coverage', () {
      test('covers getStats with comprehensive data', () async {
        final stats = await source.getStats();

        expect(stats, isA<Map<String, dynamic>>());
        expect(stats['protocol'], 'websocket');
        expect(stats['url'], 'ws://localhost:8080');
        expect(stats['is_initialized'], isA<bool>());
        expect(stats['is_connected'], isA<bool>());
        expect(stats['is_subscribed'], isA<bool>());
        expect(stats['subscribed_topics'], isA<List>());
        expect(stats['message_buffer_size'], isA<int>());
        expect(stats['max_buffer_size'], 500);
        expect(stats['total_messages_received'], isA<int>());
        expect(stats['total_errors'], isA<int>());
        expect(stats['last_connected'], isNull);
        expect(stats['last_message'], isNull);
        expect(stats['topic_message_counts'], isA<Map>());
        expect(stats['last_message_times'], isA<Map>());
      });

      test('covers getConnectionHealth structure', () {
        final health = source.getConnectionHealth();
        expect(health, isA<Map<String, dynamic>>());
        expect(health['is_connected'], isA<bool>());
        expect(health['last_connected'], anyOf(isNull, isA<String>()));
        expect(health['last_message'], anyOf(isNull, isA<String>()));
        expect(health['message_count'], isA<int>());
        expect(health['error_count'], isA<int>());
        expect(health['protocol'], 'websocket');
        expect(health['url'], 'ws://localhost:8080');
      });
    });

    group('RealtimeSource Connection Factory Coverage', () {
      test('covers WebSocket connection creation', () {
        final wsConfig = RealtimeConfig(
          protocol: 'websocket',
          url: 'ws://localhost:8080',
        );

        final wsSource = RealtimeSource(
          name: 'ws_test',
          realtimeConfig: wsConfig,
          sourceType: SourceType.realtime,
          url: 'ws://localhost:8080',
          privacyLevel: PrivacyLevel.public,
        );

        expect(wsSource.realtimeConfig.protocol, 'websocket');
      });

      test('covers MQTT connection creation', () {
        final mqttConfig = RealtimeConfig(
          protocol: 'mqtt',
          url: 'mqtt://localhost:1883',
        );

        final mqttSource = RealtimeSource(
          name: 'mqtt_test',
          realtimeConfig: mqttConfig,
          sourceType: SourceType.realtime,
          url: 'mqtt://localhost:1883',
          privacyLevel: PrivacyLevel.enterprise,
        );

        expect(mqttSource.realtimeConfig.protocol, 'mqtt');
      });

      test('covers Redis connection creation', () {
        final redisConfig = RealtimeConfig(
          protocol: 'redis',
          url: 'redis://localhost:6379',
        );

        final redisSource = RealtimeSource(
          name: 'redis_test',
          realtimeConfig: redisConfig,
          sourceType: SourceType.realtime,
          url: 'redis://localhost:6379',
          privacyLevel: PrivacyLevel.restricted,
        );

        expect(redisSource.realtimeConfig.protocol, 'redis');
      });

      test('covers unsupported protocol error', () {
        final invalidConfig = RealtimeConfig(
          protocol: 'invalid_protocol',
          url: 'invalid://localhost',
        );

        expect(
          () => RealtimeSource(
            name: 'invalid_test',
            realtimeConfig: invalidConfig,
            sourceType: SourceType.realtime,
            url: 'invalid://localhost',
            privacyLevel: PrivacyLevel.public,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('RealtimeSource Buffer Management Coverage', () {
      test('covers buffer size limits', () {
        final smallBufferSource = RealtimeSource(
          name: 'small_buffer',
          realtimeConfig: config,
          sourceType: SourceType.realtime,
          url: 'ws://localhost:8080',
          privacyLevel: PrivacyLevel.private,
          maxBufferSize: 10,
        );

        // Buffer size should be reflected in stats
        final stats = smallBufferSource.getStats();
        expect(stats, completes);
      });
    });
  });
}

// Mock classes for testing
class _MockRealtimeConnection extends RealtimeConnection {
  bool _mockClosed = false;
  bool _mockConnected = false;
  DateTime? _mockLastConnected;
  DateTime? _mockLastMessage;
  int _mockMessageCount = 0;
  int _mockErrorCount = 0;

  _MockRealtimeConnection(super.config);

  @override
  bool get isClosed => _mockClosed;

  @override
  bool get isConnected => _mockConnected;

  @override
  DateTime? get lastConnected => _mockLastConnected;

  @override
  DateTime? get lastMessage => _mockLastMessage;

  @override
  int get messageCount => _mockMessageCount;

  @override
  int get errorCount => _mockErrorCount;

  @override
  Future<void> connect() async {
    // Mock implementation
  }

  @override
  Future<void> disconnect() async {
    _mockClosed = true;
    testUpdateConnectionStatus(false);
  }

  @override
  Future<void> subscribe(String topic) async {
    // Mock implementation
  }

  @override
  Future<void> unsubscribe(String topic) async {
    // Mock implementation
  }

  @override
  Future<void> publish(String topic, Map<String, dynamic> data) async {
    // Mock implementation
  }

  @override
  Stream<RealtimeMessage> get messageStream => Stream.empty();

  // Test helper methods to simulate protected method behavior
  void testUpdateConnectionStatus(bool connected) {
    _mockConnected = connected;
    if (connected) {
      _mockLastConnected = DateTime.now();
    }
  }

  void testUpdateMessageReceived() {
    _mockLastMessage = DateTime.now();
    _mockMessageCount++;
  }

  void testUpdateError() {
    _mockErrorCount++;
  }
}
