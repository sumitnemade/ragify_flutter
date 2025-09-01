import 'package:flutter_test/flutter_test.dart';
import 'package:ragify_flutter/src/sources/api_source.dart';
import 'package:ragify_flutter/src/sources/base_data_source.dart';
import 'package:ragify_flutter/src/models/context_chunk.dart';
import 'package:ragify_flutter/src/models/relevance_score.dart';
import 'package:ragify_flutter/src/models/context_source.dart';
import 'package:ragify_flutter/src/models/privacy_level.dart';
import 'package:ragify_flutter/src/exceptions/ragify_exceptions.dart';
import 'package:http/http.dart' as http;

void main() {
  group('APISource Coverage Tests', () {
    late APISource source;
    late http.Client mockHttpClient;

    setUp(() {
      mockHttpClient = _MockHttpClient();
      source = APISource(
        name: 'coverage_test_api',
        baseUrl: 'https://api.example.com',
        httpClient: mockHttpClient,
        config: {
          'api_version': 'v2',
          'language': 'en',
          'custom_headers': {'X-Custom': 'value'},
        },
        metadata: {'test': 'data'},
        authHeaders: {'Authorization': 'Bearer token'},
        timeout: Duration(seconds: 30),
        rateLimit: RateLimitConfig(
          minInterval: Duration(milliseconds: 50),
          maxRequestsPerMinute: 120,
          cacheTtl: Duration(minutes: 10),
          maxCacheSize: 200,
        ),
        adaptiveTimeout: AdaptiveTimeoutConfig(
          baseTimeout: Duration(seconds: 20),
          maxTimeout: Duration(seconds: 60),
          minTimeout: Duration(seconds: 10),
          slowNetworkMultiplier: 1.5,
          fastNetworkMultiplier: 0.7,
          networkQualityThreshold: 500,
          enabled: true,
        ),
      );
    });

    group('Request Building Coverage', () {
      test('covers getChunks with all optional parameters', () async {
        // This will trigger _buildAPIRequest with all parameters (lines 175, 179, 184, 188)
        final chunks = await source.getChunks(
          query: 'test query',
          userId: 'user123',
          sessionId: 'session456',
          maxChunks: 5,
          minRelevance: 0.8,
        );

        expect(chunks, isA<List<ContextChunk>>());
      });

      test('covers getChunks without optional parameters', () async {
        // This will trigger _buildAPIRequest with minimal parameters
        final chunks = await source.getChunks(query: 'simple query');

        expect(chunks, isA<List<ContextChunk>>());
      });

      test('covers configuration with partial config', () async {
        final partialSource = APISource(
          name: 'partial_config',
          baseUrl: 'https://api.example.com',
          config: {'api_version': 'v1'},
          httpClient: mockHttpClient,
        );

        final chunks = await partialSource.getChunks(query: 'test');
        expect(chunks, isA<List<ContextChunk>>());
      });
    });

    group('HTTP Request Coverage', () {
      test('covers custom headers from config', () async {
        final customSource = APISource(
          name: 'custom_headers',
          baseUrl: 'https://api.example.com',
          config: {
            'custom_headers': {
              'X-API-Key': 'secret123',
              'X-Version': '1.0',
            },
          },
          httpClient: mockHttpClient,
        );

        // This will trigger the custom headers logic (lines 208, 209)
        final chunks = await customSource.getChunks(query: 'test');
        expect(customSource.getConfiguration()['custom_headers'], isA<Map>());
      });

      test('covers adaptive timeout calculation', () async {
        final adaptiveSource = APISource(
          name: 'adaptive_timeout',
          baseUrl: 'https://api.example.com',
          adaptiveTimeout: AdaptiveTimeoutConfig(
            baseTimeout: Duration(seconds: 10),
            maxTimeout: Duration(seconds: 30),
            minTimeout: Duration(seconds: 5),
            slowNetworkMultiplier: 2.0,
            fastNetworkMultiplier: 0.5,
            networkQualityThreshold: 1000,
            enabled: true,
          ),
          httpClient: mockHttpClient,
        );

        await adaptiveSource.getChunks(query: 'test');
        
        // Test slow network timeout calculation (line 548)
        final slowTimeout = adaptiveSource.adaptiveTimeout.calculateTimeout(
          Duration(milliseconds: 1500), // Above threshold
        );
        expect(slowTimeout.inSeconds, 20); // 10 * 2.0

        // Test fast network timeout calculation  
        final fastTimeout = adaptiveSource.adaptiveTimeout.calculateTimeout(
          Duration(milliseconds: 400), // Below threshold/2
        );
        expect(fastTimeout.inSeconds, 5); // 10 * 0.5

        // Test normal network timeout
        final normalTimeout = adaptiveSource.adaptiveTimeout.calculateTimeout(
          Duration(milliseconds: 600), // Between threshold/2 and threshold
        );
        expect(normalTimeout.inSeconds, 10); // base timeout
      });

      test('covers adaptive timeout disabled', () async {
        final disabledSource = APISource(
          name: 'disabled_adaptive',
          baseUrl: 'https://api.example.com',
          adaptiveTimeout: AdaptiveTimeoutConfig(enabled: false),
          httpClient: mockHttpClient,
        );

        await disabledSource.getChunks(query: 'test');
        
        final timeout = disabledSource.adaptiveTimeout.calculateTimeout(
          Duration(milliseconds: 1500),
        );
        expect(timeout.inSeconds, 30); // base timeout when disabled
      });

      test('covers adaptive timeout with null response time', () async {
        final timeout = source.adaptiveTimeout.calculateTimeout(null);
        expect(timeout.inSeconds, 20); // base timeout when no response time
      });
    });

    group('Response Processing Coverage', () {
      test('covers metadata extraction from response', () async {
        final mockClient = _MockHttpClientWithMetadata();
        final metadataSource = APISource(
          name: 'metadata_test',
          baseUrl: 'https://api.example.com',
          httpClient: mockClient,
        );

        // This will trigger metadata processing (lines 299, 300, 301)
        final chunks = await metadataSource.getChunks(query: 'test query');

        expect(chunks, hasLength(1));
        expect(chunks.first.metadata['author'], 'Test Author');
        expect(chunks.first.tags, containsAll(['api', 'external', 'Technology', 'Article']));
      });

      test('covers empty metadata handling', () async {
        final chunks = await source.getChunks(query: 'test query');

        expect(chunks, hasLength(1));
        expect(chunks.first.tags, containsAll(['api', 'external']));
      });
    });

    group('Cache Management Coverage', () {
      test('covers cache operations', () async {
        // Fill cache to trigger size limit logic (lines 372, 373)
        for (int i = 0; i < 250; i++) {
          await source.getChunks(query: 'query_$i');
        }
        
        // Test cache behavior
        final stats = await source.getStats();
        expect(stats['cache_size'], isA<int>());
      });
    });

    group('Rate Limiting Coverage', () {
      test('covers rate limit checking with wait time', () async {
        final rateLimitSource = APISource(
          name: 'rate_limit_test',
          baseUrl: 'https://api.example.com',
          rateLimit: RateLimitConfig(
            minInterval: Duration(milliseconds: 100),
          ),
          httpClient: mockHttpClient,
        );

        // Make rapid requests to trigger rate limiting
        await rateLimitSource.getChunks(query: 'first');
        
        final stopwatch = Stopwatch()..start();
        await rateLimitSource.getChunks(query: 'second');
        stopwatch.stop();
        
        // Should have some delay due to rate limiting
        expect(stopwatch.elapsed.inMilliseconds, greaterThan(50));
      });
    });

    group('Source Management Coverage', () {
      test('covers refresh functionality', () async {
        await source.getChunks(query: 'cache this');
        
        await source.refresh();
        
        // Refresh should work without error
        expect(source.isActive, isTrue);
      });

      test('covers metadata update', () async {
        final initialMetadata = Map<String, dynamic>.from(source.metadata);
        
        await source.updateMetadata({'new_key': 'new_value', 'count': 42});
        
        expect(source.metadata, containsPair('new_key', 'new_value'));
        expect(source.metadata, containsPair('count', 42));
        // Check that all initial metadata keys are still present
        for (final entry in initialMetadata.entries) {
          expect(source.metadata, containsPair(entry.key, entry.value));
        }
      });

      test('covers configuration update', () async {
        final initialConfig = Map<String, dynamic>.from(source.getConfiguration());
        
        await source.updateConfiguration({'new_setting': 'new_value'});
        
        expect(source.getConfiguration(), containsPair('new_setting', 'new_value'));
        // Check that all initial config keys are still present
        for (final entry in initialConfig.entries) {
          expect(source.getConfiguration(), containsPair(entry.key, entry.value));
        }
      });

      test('covers source status when offline', () async {
        // Close source to make it offline
        await source.close();
        
        final status = await source.getStatus();
        expect(status, SourceStatus.offline);
      });

      test('covers source status when unhealthy', () async {
        final unhealthySource = APISource(
          name: 'unhealthy',
          baseUrl: 'https://api.example.com',
          httpClient: _MockUnhealthyHttpClient(),
        );
        
        final status = await unhealthySource.getStatus();
        expect(status, SourceStatus.unhealthy);
      });
    });

    group('Configuration Classes Coverage', () {
      test('covers RateLimitConfig with custom values', () {
        final config = RateLimitConfig(
          minInterval: Duration(milliseconds: 200),
          maxRequestsPerMinute: 30,
          cacheTtl: Duration(minutes: 15),
          maxCacheSize: 50,
        );

        expect(config.minInterval.inMilliseconds, 200);
        expect(config.maxRequestsPerMinute, 30);
        expect(config.cacheTtl.inMinutes, 15);
        expect(config.maxCacheSize, 50);
      });

      test('covers RateLimitConfig with default values', () {
        final config = RateLimitConfig();

        expect(config.minInterval.inMilliseconds, 100);
        expect(config.maxRequestsPerMinute, 60);
        expect(config.cacheTtl.inMinutes, 5);
        expect(config.maxCacheSize, 100);
      });

      test('covers AdaptiveTimeoutConfig with custom values', () {
        final config = AdaptiveTimeoutConfig(
          baseTimeout: Duration(seconds: 15),
          maxTimeout: Duration(seconds: 45),
          minTimeout: Duration(seconds: 8),
          slowNetworkMultiplier: 1.8,
          fastNetworkMultiplier: 0.6,
          networkQualityThreshold: 800,
          enabled: false,
        );

        expect(config.baseTimeout.inSeconds, 15);
        expect(config.maxTimeout.inSeconds, 45);
        expect(config.minTimeout.inSeconds, 8);
        expect(config.slowNetworkMultiplier, 1.8);
        expect(config.fastNetworkMultiplier, 0.6);
        expect(config.networkQualityThreshold, 800);
        expect(config.enabled, false);
      });

      test('covers AdaptiveTimeoutConfig with default values', () {
        final config = AdaptiveTimeoutConfig();

        expect(config.baseTimeout.inSeconds, 30);
        expect(config.maxTimeout.inSeconds, 120);
        expect(config.minTimeout.inSeconds, 5);
        expect(config.slowNetworkMultiplier, 2.0);
        expect(config.fastNetworkMultiplier, 0.8);
        expect(config.networkQualityThreshold, 1000);
        expect(config.enabled, true);
      });

      test('covers CachedResponse creation and access', () {
        final data = {'test': 'value'};
        final timestamp = DateTime.now();
        
        final cached = CachedResponse(data: data, timestamp: timestamp);
        
        expect(cached.data, data);
        expect(cached.timestamp, timestamp);
      });
    });
  });
}

class _MockHttpClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = http.Response(
      '{"results": [{"content": "Test content", "score": 0.95}]}',
      200,
      headers: {'content-type': 'application/json'},
    );
    
    return http.StreamedResponse(
      Stream.value(response.body.codeUnits),
      response.statusCode,
      headers: response.headers,
    );
  }
}

class _MockHttpClientWithMetadata extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = http.Response(
      '{"results": [{"content": "Test content", "score": 0.95, "metadata": {"author": "Test Author"}, "category": "Technology", "type": "Article"}]}',
      200,
      headers: {'content-type': 'application/json'},
    );
    
    return http.StreamedResponse(
      Stream.value(response.body.codeUnits),
      response.statusCode,
      headers: response.headers,
    );
  }
}

class _MockUnhealthyHttpClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    throw Exception('Connection failed');
  }
}