import 'package:flutter_test/flutter_test.dart';
import 'package:ragify_flutter/src/sources/realtime_source.dart';
import 'package:ragify_flutter/src/models/context_source.dart';
import 'package:ragify_flutter/src/models/privacy_level.dart';

void main() {
  group('RealtimeSource Tests', () {
    late RealtimeSource realtimeSource;
    late RealtimeConfig config;

    setUp(() {
      config = const RealtimeConfig(
        url: 'ws://localhost:8080',
        protocol: 'websocket',
      );

      realtimeSource = RealtimeSource(
        realtimeConfig: config,
        name: 'test_realtime',
        sourceType: SourceType.realtime,
        url: 'ws://localhost:8080',
        privacyLevel: PrivacyLevel.public,
      );
    });

    tearDown(() async {
      await realtimeSource.close();
    });

    test('should create RealtimeSource instance', () {
      expect(realtimeSource, isNotNull);
      expect(realtimeSource.name, equals('test_realtime'));
      expect(realtimeSource.sourceType, equals(SourceType.realtime));
      expect(realtimeSource.url, equals('ws://localhost:8080'));
    });

    test('should have correct configuration', () {
      final sourceConfig = realtimeSource.config;
      expect(sourceConfig['protocol'], equals('websocket'));
      expect(sourceConfig['url'], equals('ws://localhost:8080'));
    });

    test('should have correct metadata', () {
      final metadata = realtimeSource.metadata;
      expect(metadata, isA<Map<String, dynamic>>());
    });

    test('should not be initialized initially', () {
      expect(realtimeSource.isActive, isFalse);
    });

    test('should get empty chunks when not initialized', () async {
      final chunks = await realtimeSource.getChunks(query: 'test');
      expect(chunks, isEmpty);
    });

    test('should get stats', () async {
      final stats = await realtimeSource.getStats();
      expect(stats['protocol'], equals('websocket'));
      expect(stats['is_initialized'], isFalse);
    });

    test('should not be healthy when not initialized', () async {
      final isHealthy = await realtimeSource.isHealthy();
      expect(isHealthy, isFalse);
    });

    test('should have offline status when not initialized', () async {
      final status = await realtimeSource.getStatus();
      expect(status.value, equals('offline'));
    });

    test('should create RealtimeMessage from JSON', () {
      final json = {
        'id': 'test_id',
        'topic': 'test_topic',
        'data': {'message': 'test message'},
        'timestamp': '2024-01-01T00:00:00.000Z',
        'metadata': {'key': 'value'},
        'source_id': 'test_source',
      };

      final message = RealtimeMessage.fromJson(json);
      expect(message.id, equals('test_id'));
      expect(message.topic, equals('test_topic'));
      expect(message.data['message'], equals('test message'));
      expect(message.metadata['key'], equals('value'));
      expect(message.sourceId, equals('test_source'));
    });

    test('should convert RealtimeMessage to JSON', () {
      final message = RealtimeMessage(
        id: 'test_id',
        topic: 'test_topic',
        data: {'message': 'test message'},
        timestamp: DateTime(2024, 1, 1),
        metadata: {'key': 'value'},
        sourceId: 'test_source',
      );

      final json = message.toJson();
      expect(json['id'], equals('test_id'));
      expect(json['topic'], equals('test_topic'));
      expect(json['data']['message'], equals('test message'));
      expect(json['metadata']['key'], equals('value'));
      expect(json['source_id'], equals('test_source'));
    });

    test('should create RealtimeConfig with defaults', () {
      const config = RealtimeConfig(
        url: 'ws://localhost:8080',
        protocol: 'websocket',
      );

      expect(config.url, equals('ws://localhost:8080'));
      expect(config.protocol, equals('websocket'));
      expect(config.connectionTimeout.inSeconds, equals(30));
      expect(config.reconnectInterval.inSeconds, equals(5));
      expect(config.maxReconnectAttempts, equals(5));
      expect(config.enableHeartbeat, isTrue);
      expect(config.heartbeatInterval.inSeconds, equals(30));
    });

    test('should create RealtimeConfig with custom values', () {
      const config = RealtimeConfig(
        url: 'ws://localhost:8080',
        protocol: 'websocket',
        connectionTimeout: Duration(seconds: 60),
        reconnectInterval: Duration(seconds: 10),
        maxReconnectAttempts: 10,
        enableHeartbeat: false,
        heartbeatInterval: Duration(seconds: 60),
      );

      expect(config.connectionTimeout.inSeconds, equals(60));
      expect(config.reconnectInterval.inSeconds, equals(10));
      expect(config.maxReconnectAttempts, equals(10));
      expect(config.enableHeartbeat, isFalse);
      expect(config.heartbeatInterval.inSeconds, equals(60));
    });

    test('should convert RealtimeConfig to JSON', () {
      const config = RealtimeConfig(
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
}
