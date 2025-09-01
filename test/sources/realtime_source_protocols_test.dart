import 'package:flutter_test/flutter_test.dart';
import 'package:ragify_flutter/src/sources/realtime_source.dart';
import 'package:ragify_flutter/src/models/privacy_level.dart';
import 'package:ragify_flutter/src/models/context_source.dart';

void main() {
  group('RealtimeSource Protocols', () {
    late RealtimeSource source;
    late RealtimeConfig config;

    setUp(() {
      config = RealtimeConfig(
        url: 'ws://localhost:8080',
        protocol: 'websocket',
        connectionTimeout: Duration(seconds: 10),
        heartbeatInterval: Duration(seconds: 30),
        maxReconnectAttempts: 3,
        reconnectInterval: Duration(seconds: 5),
        enableHeartbeat: true,
      );

      source = RealtimeSource(
        realtimeConfig: config,
        name: 'test_realtime',
        sourceType: SourceType.realtime,
        url: 'ws://localhost:8080',
        privacyLevel: PrivacyLevel.public,
        maxBufferSize: 1000,
      );
    });

    tearDown(() {
      source.close();
    });

    group('WebSocket Protocol', () {
      test('initializes with WebSocket protocol', () {
        expect(source.config['protocol'], equals('websocket'));
        expect(source.config['url'], equals('ws://localhost:8080'));
        expect(source.isActive, isFalse);
      });

      // Note: We avoid calling initialize() for websocket in tests to prevent
      // real network connections and keep tests deterministic.

      test('subscribe throws when not initialized', () async {
        await expectLater(
          source.subscribe('test/topic'),
          throwsA(isA<StateError>()),
        );
      });

      test('publish throws when not initialized', () async {
        await expectLater(
          source.publish('test/topic', {'data': 'test'}),
          throwsA(isA<StateError>()),
        );
      });
    });

    group('MQTT Protocol', () {
      setUp(() {
        config = RealtimeConfig(
          url: 'mqtt://localhost:1883',
          protocol: 'mqtt',
          connectionTimeout: Duration(seconds: 10),
          heartbeatInterval: Duration(seconds: 30),
          maxReconnectAttempts: 3,
          reconnectInterval: Duration(seconds: 5),
          enableHeartbeat: false,
        );

        source = RealtimeSource(
          realtimeConfig: config,
          name: 'mqtt_realtime',
          sourceType: SourceType.realtime,
          url: 'mqtt://localhost:1883',
          privacyLevel: PrivacyLevel.public,
          maxBufferSize: 500,
        );
      });

      test('initializes with MQTT protocol', () {
        expect(source.config['protocol'], equals('mqtt'));
        expect(source.config['url'], equals('mqtt://localhost:1883'));
      });

      test('initializes MQTT successfully', () async {
        await source.initialize();
        expect(source.isActive, isTrue);
      });

      test('subscribes on MQTT and reflects in stats', () async {
        await source.initialize();
        await source.subscribe('mqtt/test');
        final stats = await source.getStats();
        expect(stats['is_subscribed'], isTrue);
        expect(
          (stats['subscribed_topics'] as List).contains('mqtt/test'),
          isTrue,
        );
      });
    });

    group('Redis Protocol', () {
      setUp(() {
        config = RealtimeConfig(
          url: 'redis://localhost:6379',
          protocol: 'redis',
          connectionTimeout: Duration(seconds: 15),
          heartbeatInterval: Duration(seconds: 60),
          maxReconnectAttempts: 5,
          reconnectInterval: Duration(seconds: 2),
          enableHeartbeat: true,
        );

        source = RealtimeSource(
          realtimeConfig: config,
          name: 'redis_realtime',
          sourceType: SourceType.realtime,
          url: 'redis://localhost:6379',
          privacyLevel: PrivacyLevel.restricted,
          maxBufferSize: 2000,
        );
      });

      test('initializes with Redis protocol', () {
        expect(source.config['protocol'], equals('redis'));
        expect(source.config['url'], equals('redis://localhost:6379'));
      });

      test('initializes Redis successfully', () async {
        await source.initialize();
        expect(source.isActive, isTrue);
      });

      test('subscribes and publishes on Redis after initialization', () async {
        await source.initialize();
        await source.subscribe('redis:channel');
        await expectLater(
          source.publish('redis:channel', {'key': 'value'}),
          completes,
        );
        final stats = await source.getStats();
        expect(stats['is_subscribed'], isTrue);
      });
    });

    group('RealtimeMessage', () {
      test('creates and serializes message', () {
        final message = RealtimeMessage(
          id: 'test-1',
          topic: 'test/topic',
          data: {'content': 'test content'},
          timestamp: DateTime.now(),
          metadata: {'source': 'test'},
          sourceId: 'test-source',
        );

        expect(message.id, equals('test-1'));
        expect(message.topic, equals('test/topic'));
        expect(message.data, containsPair('content', 'test content'));
        expect(message.metadata, containsPair('source', 'test'));
        expect(message.sourceId, equals('test-source'));

        final json = message.toJson();
        expect(json, containsPair('id', 'test-1'));
        expect(json, containsPair('topic', 'test/topic'));
        expect(json, containsPair('source_id', 'test-source'));
      });

      test('deserializes from JSON', () {
        final json = {
          'id': 'json-1',
          'topic': 'json/topic',
          'data': {'key': 'value'},
          'timestamp': '2023-01-01T12:00:00.000Z',
          'metadata': {'type': 'json'},
          'source_id': 'json-source',
        };

        final message = RealtimeMessage.fromJson(json);
        expect(message.id, equals('json-1'));
        expect(message.topic, equals('json/topic'));
        expect(message.data, containsPair('key', 'value'));
        expect(message.sourceId, equals('json-source'));
      });
    });

    group('RealtimeConfig', () {
      test('creates configuration with defaults', () {
        final config = RealtimeConfig(url: 'ws://test', protocol: 'websocket');

        expect(config.url, equals('ws://test'));
        expect(config.protocol, equals('websocket'));
        expect(config.connectionTimeout, equals(Duration(seconds: 30)));
        expect(config.maxReconnectAttempts, equals(5));
        expect(config.enableHeartbeat, isTrue);
      });

      test('serializes to JSON', () {
        final config = RealtimeConfig(
          url: 'ws://test',
          protocol: 'websocket',
          connectionTimeout: Duration(seconds: 15),
          maxReconnectAttempts: 3,
          enableHeartbeat: false,
        );

        final json = config.toJson();
        expect(json, containsPair('url', 'ws://test'));
        expect(json, containsPair('protocol', 'websocket'));
        expect(json, containsPair('connection_timeout', 15000));
        expect(json, containsPair('max_reconnect_attempts', 3));
        expect(json, containsPair('enable_heartbeat', false));
      });
    });

    group('Statistics and Health', () {
      test('provides comprehensive stats', () async {
        final stats = await source.getStats();

        expect(stats, containsPair('protocol', 'websocket'));
        expect(stats, containsPair('url', 'ws://localhost:8080'));
        expect(stats, containsPair('is_initialized', false));
        expect(stats, containsPair('is_connected', false));
        expect(stats, containsPair('is_subscribed', false));
        expect(stats, containsPair('message_buffer_size', 0));
        expect(stats, containsPair('max_buffer_size', 1000));
        expect(stats, contains('topic_message_counts'));
        expect(stats, contains('last_message_times'));
      });
    });

    group('Configuration', () {
      test('provides configuration details', () {
        final configMap = source.getConfiguration();

        expect(configMap, isA<Map<String, dynamic>>());
        expect(configMap, containsPair('protocol', 'websocket'));
        expect(configMap, containsPair('connection_timeout', 10000));
        expect(configMap, containsPair('heartbeat_interval', 30000));
        expect(configMap, containsPair('max_reconnect_attempts', 3));
        expect(configMap, containsPair('reconnect_interval', 5000));
        expect(configMap, containsPair('enable_heartbeat', true));
      });
    });

    group('Error Handling', () {
      test('handles unsupported protocol', () {
        expect(
          () => RealtimeSource(
            realtimeConfig: RealtimeConfig(
              url: 'unknown://test',
              protocol: 'unsupported',
            ),
            name: 'error_test',
            sourceType: SourceType.realtime,
            url: 'unknown://test',
            privacyLevel: PrivacyLevel.public,
          ),
          throwsArgumentError,
        );
      });

      test('handles getChunks when not initialized', () async {
        final chunks = await source.getChunks(query: 'test query');
        expect(chunks, isEmpty);
      });
    });

    group('Lifecycle', () {
      test('handles refresh', () async {
        await source.refresh();
        // Should complete without error
        expect(source.isActive, isFalse);
      });

      test('handles updateMetadata', () {
        final src = RealtimeSource(
          realtimeConfig: config,
          name: 'meta_src',
          sourceType: SourceType.realtime,
          url: config.url,
          privacyLevel: PrivacyLevel.public,
          metadata: {},
        );
        src.updateMetadata({'new': 'data'});
        expect(src.metadata, containsPair('new', 'data'));
        src.close();
      });

      test('handles close', () {
        source.close();
        // Should complete without error
        expect(source.isActive, isFalse);
      });
    });
  });
}
