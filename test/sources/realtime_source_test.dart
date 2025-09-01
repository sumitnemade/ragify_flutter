import 'package:flutter_test/flutter_test.dart';
import 'package:ragify_flutter/src/sources/realtime_source.dart';
import 'package:ragify_flutter/src/models/context_source.dart';
import 'package:ragify_flutter/src/models/privacy_level.dart';
import 'package:ragify_flutter/src/cache/cache_manager.dart';
import 'package:logger/logger.dart';

void main() {
  group('RealtimeSource Tests', () {
    late RealtimeSource realtimeSource;
    late RealtimeConfig realtimeConfig;

    setUp(() {
      realtimeConfig = RealtimeConfig(
        url: 'ws://localhost:8080/realtime',
        protocol: 'websocket',
        connectionTimeout: Duration(seconds: 30),
        reconnectInterval: Duration(seconds: 5),
        maxReconnectAttempts: 3,
        enableHeartbeat: true,
        heartbeatInterval: Duration(seconds: 30),
        options: {'custom': 'option'},
      );
      
      realtimeSource = RealtimeSource(
        name: 'Test Realtime Source',
        sourceType: SourceType.realtime,
        url: 'ws://localhost:8080/realtime',
        privacyLevel: PrivacyLevel.private,
        realtimeConfig: realtimeConfig,
        metadata: {'test': 'metadata'},
        maxBufferSize: 1000,
      );
    });

    group('Constructor Tests', () {
      test('should create realtime source with default values', () {
        final config = RealtimeConfig(
          url: 'ws://default.localhost:8080',
          protocol: 'websocket',
        );

        final source = RealtimeSource(
          name: 'Default Realtime Source',
          sourceType: SourceType.realtime,
          url: 'ws://default.localhost:8080',
          privacyLevel: PrivacyLevel.public,
          realtimeConfig: config,
        );

        expect(source.name, equals('Default Realtime Source'));
        expect(source.url, equals('ws://default.localhost:8080'));
        expect(source.sourceType, equals(SourceType.realtime));
        expect(source.privacyLevel, equals(PrivacyLevel.public));
        expect(source.realtimeConfig.url, equals('ws://default.localhost:8080'));
        expect(source.realtimeConfig.protocol, equals('websocket'));
        expect(source.realtimeConfig.connectionTimeout, equals(Duration(seconds: 30)));
        expect(source.realtimeConfig.reconnectInterval, equals(Duration(seconds: 5)));
        expect(source.realtimeConfig.maxReconnectAttempts, equals(5));
        expect(source.realtimeConfig.enableHeartbeat, isTrue);
        expect(source.realtimeConfig.heartbeatInterval, equals(Duration(seconds: 30)));
        expect(source.isActive, isFalse);
        expect(source.config, isA<Map<String, dynamic>>());
        expect(source.metadata, isEmpty);
      });

      test('should create realtime source with custom values', () {
        final config = RealtimeConfig(
          url: 'wss://secure.localhost:8080/realtime',
          protocol: 'websocket',
          connectionTimeout: Duration(seconds: 60),
          reconnectInterval: Duration(seconds: 10),
          maxReconnectAttempts: 5,
          enableHeartbeat: false,
          heartbeatInterval: Duration(seconds: 60),
          options: {'secure': true, 'compression': true},
        );

        final source = RealtimeSource(
          name: 'Custom Realtime Source',
          sourceType: SourceType.realtime,
          url: 'wss://secure.localhost:8080/realtime',
          privacyLevel: PrivacyLevel.private,
          realtimeConfig: config,
          metadata: {'custom': 'metadata'},
          maxBufferSize: 2000,
        );

        expect(source.name, equals('Custom Realtime Source'));
        expect(source.url, equals('wss://secure.localhost:8080/realtime'));
        expect(source.realtimeConfig.url, equals('wss://secure.localhost:8080/realtime'));
        expect(source.realtimeConfig.connectionTimeout, equals(Duration(seconds: 60)));
        expect(source.realtimeConfig.reconnectInterval, equals(Duration(seconds: 10)));
        expect(source.realtimeConfig.maxReconnectAttempts, equals(5));
        expect(source.realtimeConfig.enableHeartbeat, isFalse);
        expect(source.realtimeConfig.heartbeatInterval, equals(Duration(seconds: 60)));
        expect(source.realtimeConfig.options, equals({'secure': true, 'compression': true}));
        expect(source.metadata, equals({'custom': 'metadata'}));
      });

      test('should create context source correctly', () {
        final source = realtimeSource.source;

        expect(source.name, equals('Test Realtime Source'));
        expect(source.sourceType, equals(SourceType.realtime));
        expect(source.url, equals('ws://localhost:8080/realtime'));
        expect(source.metadata, equals({'test': 'metadata'}));
        expect(source.privacyLevel, equals(PrivacyLevel.private));
        expect(source.authorityScore, equals(0.8));
        expect(source.freshnessScore, equals(1.0));
      });
    });

    group('RealtimeConfig Tests', () {
      test('should create RealtimeConfig with defaults', () {
        final config = RealtimeConfig(
          url: 'ws://localhost:8080',
          protocol: 'websocket',
        );

        expect(config.url, equals('ws://localhost:8080'));
        expect(config.protocol, equals('websocket'));
        expect(config.connectionTimeout, equals(Duration(seconds: 30)));
        expect(config.reconnectInterval, equals(Duration(seconds: 5)));
        expect(config.maxReconnectAttempts, equals(5));
        expect(config.enableHeartbeat, isTrue);
        expect(config.heartbeatInterval, equals(Duration(seconds: 30)));
        expect(config.options, isEmpty);
      });

      test('should create RealtimeConfig with custom values', () {
        final config = RealtimeConfig(
          url: 'wss://secure.localhost:8080',
          protocol: 'websocket',
          connectionTimeout: Duration(seconds: 60),
          reconnectInterval: Duration(seconds: 10),
          maxReconnectAttempts: 10,
          enableHeartbeat: false,
          heartbeatInterval: Duration(seconds: 60),
          options: {'secure': true, 'compression': true},
        );

        expect(config.url, equals('wss://secure.localhost:8080'));
        expect(config.protocol, equals('websocket'));
        expect(config.connectionTimeout, equals(Duration(seconds: 60)));
        expect(config.reconnectInterval, equals(Duration(seconds: 10)));
        expect(config.maxReconnectAttempts, equals(10));
        expect(config.enableHeartbeat, isFalse);
        expect(config.heartbeatInterval, equals(Duration(seconds: 60)));
        expect(config.options, equals({'secure': true, 'compression': true}));
      });

      test('should convert RealtimeConfig to JSON', () {
        final config = RealtimeConfig(
          url: 'ws://localhost:8080',
          protocol: 'websocket',
          options: {'custom': 'option'},
        );

        final json = config.toJson();
        expect(json['url'], equals('ws://localhost:8080'));
        expect(json['protocol'], equals('websocket'));
        expect(json['options']['custom'], equals('option'));
        expect(json['connection_timeout'], equals(30000));
        expect(json['reconnect_interval'], equals(5000));
        expect(json['max_reconnect_attempts'], equals(5));
        expect(json['enable_heartbeat'], isTrue);
        expect(json['heartbeat_interval'], equals(30000));
      });
    });

    group('RealtimeMessage Tests', () {
      test('should create RealtimeMessage with all fields', () {
        final message = RealtimeMessage(
          id: 'msg123',
          topic: 'sensor/temperature',
          data: {'temperature': 25.5, 'humidity': 60.0},
          timestamp: DateTime(2023, 1, 1),
          metadata: {'sensor_type': 'temperature', 'location': 'room1'},
          sourceId: 'sensor1',
        );

        expect(message.id, equals('msg123'));
        expect(message.topic, equals('sensor/temperature'));
        expect(message.data, equals({'temperature': 25.5, 'humidity': 60.0}));
        expect(message.timestamp, equals(DateTime(2023, 1, 1)));
        expect(message.metadata, equals({'sensor_type': 'temperature', 'location': 'room1'}));
        expect(message.sourceId, equals('sensor1'));
      });

      test('should create RealtimeMessage with defaults', () {
        final message = RealtimeMessage(
          id: 'msg123',
          topic: 'test/topic',
          data: {'key': 'value'},
          timestamp: DateTime.now(),
        );

        expect(message.id, equals('msg123'));
        expect(message.topic, equals('test/topic'));
        expect(message.data, equals({'key': 'value'}));
        expect(message.timestamp, isA<DateTime>());
        expect(message.metadata, isEmpty);
        expect(message.sourceId, isNull);
      });

      test('should create RealtimeMessage from JSON', () {
        final json = {
          'id': 'msg123',
          'topic': 'sensor/temperature',
          'data': {'temperature': 25.5},
          'timestamp': '2023-01-01T00:00:00.000',
          'metadata': {'sensor_type': 'temperature'},
          'source_id': 'sensor1',
        };

        final message = RealtimeMessage.fromJson(json);

        expect(message.id, equals('msg123'));
        expect(message.topic, equals('sensor/temperature'));
        expect(message.data, equals({'temperature': 25.5}));
        expect(message.timestamp, equals(DateTime(2023, 1, 1)));
        expect(message.metadata, equals({'sensor_type': 'temperature'}));
        expect(message.sourceId, equals('sensor1'));
      });

      test('should convert RealtimeMessage to JSON', () {
        final message = RealtimeMessage(
          id: 'msg123',
          topic: 'sensor/temperature',
          data: {'temperature': 25.5},
          timestamp: DateTime(2023, 1, 1),
          metadata: {'sensor_type': 'temperature'},
          sourceId: 'sensor1',
        );

        final json = message.toJson();

        expect(json['id'], equals('msg123'));
        expect(json['topic'], equals('sensor/temperature'));
        expect(json['data'], equals({'temperature': 25.5}));
        expect(json['timestamp'], equals('2023-01-01T00:00:00.000'));
        expect(json['metadata'], equals({'sensor_type': 'temperature'}));
        expect(json['source_id'], equals('sensor1'));
      });
    });

    group('Error Handling Tests', () {
      test('should handle inactive source gracefully', () async {
        // Realtime source is not active by default
        expect(realtimeSource.isActive, isFalse);

        // When not initialized, getChunks returns empty list
        final chunks = await realtimeSource.getChunks(query: 'test');
        expect(chunks, isEmpty);
      });
    });

    group('Lifecycle Tests', () {
      test('should close successfully', () async {
        expect(() => realtimeSource.close(), returnsNormally);
        expect(realtimeSource.isActive, isFalse);
      });

      test('should get stats successfully', () async {
        final stats = await realtimeSource.getStats();
        expect(stats, isA<Map<String, dynamic>>());
        expect(stats['protocol'], equals('websocket'));
        expect(stats['url'], equals('ws://localhost:8080/realtime'));
        expect(stats['is_initialized'], isFalse);
        expect(stats['is_connected'], isFalse);
        expect(stats['is_subscribed'], isFalse);
      });

      test('should get configuration successfully', () {
        final config = realtimeSource.getConfiguration();
        expect(config, isA<Map<String, dynamic>>());
        expect(config['protocol'], equals('websocket'));
        expect(config['url'], equals('ws://localhost:8080/realtime'));
        expect(config['options']['custom'], equals('option'));
        expect(config['connection_timeout'], equals(30000));
        expect(config['reconnect_interval'], equals(5000));
        expect(config['max_reconnect_attempts'], equals(3));
        expect(config['enable_heartbeat'], isTrue);
        expect(config['heartbeat_interval'], equals(30000));
      });

      test('should update configuration successfully', () async {
        expect(() => realtimeSource.updateConfiguration({'new': 'config'}), returnsNormally);
      });
    });
  });
}
