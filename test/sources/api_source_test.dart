import 'package:flutter_test/flutter_test.dart';
import 'package:ragify_flutter/src/sources/api_source.dart';
import 'package:ragify_flutter/src/models/context_source.dart';
import 'package:ragify_flutter/src/models/privacy_level.dart';
import 'package:logger/logger.dart';

void main() {
  group('APISource Tests', () {
    late APISource apiSource;
    late Logger mockLogger;

    setUp(() {
      mockLogger = Logger();
      apiSource = APISource(
        name: 'Test API Source',
        baseUrl: 'https://api.example.com',
        logger: mockLogger,
        authHeaders: {'Authorization': 'Bearer token'},
        timeout: Duration(seconds: 30),
        rateLimit: RateLimitConfig(
          minInterval: Duration(milliseconds: 100),
          maxRequestsPerMinute: 100,
          cacheTtl: Duration(minutes: 5),
          maxCacheSize: 100,
        ),
        adaptiveTimeout: AdaptiveTimeoutConfig(
          baseTimeout: Duration(seconds: 30),
          maxTimeout: Duration(seconds: 120),
          minTimeout: Duration(seconds: 5),
          slowNetworkMultiplier: 2.0,
          fastNetworkMultiplier: 0.8,
          networkQualityThreshold: 1000,
          enabled: true,
        ),
      );
    });

    group('Constructor Tests', () {
      test('should create API source with default values', () {
        final source = APISource(
          name: 'Default API Source',
          baseUrl: 'https://default.api.com',
        );

        expect(source.name, equals('Default API Source'));
        expect(source.baseUrl, equals('https://default.api.com'));
        expect(source.sourceType, equals(SourceType.api));
        expect(source.authHeaders, isEmpty);
        expect(
          source.timeout,
          equals(Duration(seconds: 24)),
        ); // Actual default value
        expect(source.rateLimit.maxRequestsPerMinute, equals(60));
        expect(
          source.adaptiveTimeout.baseTimeout,
          equals(Duration(seconds: 30)),
        );
        expect(source.isActive, isTrue);
        expect(source.config, isEmpty);
        expect(source.metadata, isEmpty);
      });

      test('should create API source with custom values', () {
        final source = APISource(
          name: 'Custom API Source',
          baseUrl: 'https://custom.api.com',
          authHeaders: {'X-API-Key': 'custom-key'},
          timeout: Duration(seconds: 60),
          rateLimit: RateLimitConfig(
            minInterval: Duration(milliseconds: 200),
            maxRequestsPerMinute: 50,
            cacheTtl: Duration(minutes: 10),
            maxCacheSize: 50,
          ),
          adaptiveTimeout: AdaptiveTimeoutConfig(
            baseTimeout: Duration(seconds: 15),
            maxTimeout: Duration(seconds: 60),
            minTimeout: Duration(seconds: 3),
            slowNetworkMultiplier: 3.0,
            fastNetworkMultiplier: 0.5,
            networkQualityThreshold: 500,
            enabled: false,
          ),
          config: {'custom': 'config'},
          metadata: {'custom': 'metadata'},
        );

        expect(source.name, equals('Custom API Source'));
        expect(source.baseUrl, equals('https://custom.api.com'));
        expect(source.authHeaders, equals({'X-API-Key': 'custom-key'}));
        expect(source.timeout, equals(Duration(seconds: 60)));
        expect(source.rateLimit.maxRequestsPerMinute, equals(50));
        expect(
          source.adaptiveTimeout.baseTimeout,
          equals(Duration(seconds: 15)),
        );
        expect(
          source.adaptiveTimeout.maxTimeout,
          equals(Duration(seconds: 60)),
        );
        expect(source.adaptiveTimeout.slowNetworkMultiplier, equals(3.0));
        expect(source.config, equals({'custom': 'config'}));
        expect(source.metadata, equals({'custom': 'metadata'}));
      });

      test('should create context source correctly', () {
        final source = apiSource.source;

        expect(source.name, equals('Test API Source'));
        expect(source.sourceType, equals(SourceType.api));
        expect(source.url, equals('https://api.example.com'));
        expect(source.metadata, isEmpty);
        expect(source.privacyLevel, equals(PrivacyLevel.private));
        expect(source.authorityScore, equals(0.7));
        expect(source.freshnessScore, equals(1.0));
      });
    });

    group('Rate Limit Configuration Tests', () {
      test('should create RateLimitConfig with defaults', () {
        final config = RateLimitConfig();

        expect(config.minInterval, equals(Duration(milliseconds: 100)));
        expect(config.maxRequestsPerMinute, equals(60));
        expect(config.cacheTtl, equals(Duration(minutes: 5)));
        expect(config.maxCacheSize, equals(100));
      });

      test('should create RateLimitConfig with custom values', () {
        final config = RateLimitConfig(
          minInterval: Duration(milliseconds: 200),
          maxRequestsPerMinute: 50,
          cacheTtl: Duration(minutes: 10),
          maxCacheSize: 50,
        );

        expect(config.minInterval, equals(Duration(milliseconds: 200)));
        expect(config.maxRequestsPerMinute, equals(50));
        expect(config.cacheTtl, equals(Duration(minutes: 10)));
        expect(config.maxCacheSize, equals(50));
      });
    });

    group('Adaptive Timeout Configuration Tests', () {
      test('should create AdaptiveTimeoutConfig with defaults', () {
        final config = AdaptiveTimeoutConfig();

        expect(config.baseTimeout, equals(Duration(seconds: 30)));
        expect(config.maxTimeout, equals(Duration(seconds: 120)));
        expect(config.minTimeout, equals(Duration(seconds: 5)));
        expect(config.slowNetworkMultiplier, equals(2.0));
        expect(config.fastNetworkMultiplier, equals(0.8));
        expect(config.networkQualityThreshold, equals(1000));
        expect(config.enabled, isTrue);
      });

      test('should create AdaptiveTimeoutConfig with custom values', () {
        final config = AdaptiveTimeoutConfig(
          baseTimeout: Duration(seconds: 15),
          maxTimeout: Duration(seconds: 60),
          minTimeout: Duration(seconds: 3),
          slowNetworkMultiplier: 3.0,
          fastNetworkMultiplier: 0.5,
          networkQualityThreshold: 500,
          enabled: false,
        );

        expect(config.baseTimeout, equals(Duration(seconds: 15)));
        expect(config.maxTimeout, equals(Duration(seconds: 60)));
        expect(config.minTimeout, equals(Duration(seconds: 3)));
        expect(config.slowNetworkMultiplier, equals(3.0));
        expect(config.fastNetworkMultiplier, equals(0.5));
        expect(config.networkQualityThreshold, equals(500));
        expect(config.enabled, isFalse);
      });

      test('should calculate timeout for slow network', () {
        final config = AdaptiveTimeoutConfig(
          baseTimeout: Duration(seconds: 30),
          slowNetworkMultiplier: 2.0,
          networkQualityThreshold: 1000,
        );

        final slowNetworkTimeout = config.calculateTimeout(
          Duration(milliseconds: 1500),
        );
        expect(slowNetworkTimeout.inMilliseconds, equals(60000)); // 30s * 2.0
      });

      test('should calculate timeout for fast network', () {
        final config = AdaptiveTimeoutConfig(
          baseTimeout: Duration(seconds: 30),
          fastNetworkMultiplier: 0.8,
          networkQualityThreshold: 1000,
        );

        final fastNetworkTimeout = config.calculateTimeout(
          Duration(milliseconds: 400),
        );
        expect(fastNetworkTimeout.inMilliseconds, equals(24000)); // 30s * 0.8
      });

      test('should return base timeout when disabled', () {
        final config = AdaptiveTimeoutConfig(
          baseTimeout: Duration(seconds: 30),
          enabled: false,
        );

        final timeout = config.calculateTimeout(Duration(milliseconds: 1500));
        expect(timeout, equals(Duration(seconds: 30)));
      });

      test('should return base timeout when no last response time', () {
        final config = AdaptiveTimeoutConfig(
          baseTimeout: Duration(seconds: 30),
        );

        final timeout = config.calculateTimeout(null);
        expect(timeout, equals(Duration(seconds: 30)));
      });

      test('should clamp timeout to min/max bounds', () {
        final config = AdaptiveTimeoutConfig(
          baseTimeout: Duration(seconds: 30),
          minTimeout: Duration(seconds: 10),
          maxTimeout: Duration(seconds: 50),
          slowNetworkMultiplier: 3.0, // Would be 90s, but clamped to 50s
        );

        final timeout = config.calculateTimeout(Duration(milliseconds: 1500));
        expect(timeout, equals(Duration(seconds: 50))); // Clamped to max
      });
    });

    group('Cached Response Tests', () {
      test('should create CachedResponse with all fields', () {
        final response = CachedResponse(
          data: {'key': 'value'},
          timestamp: DateTime(2023, 1, 1),
        );

        expect(response.data, equals({'key': 'value'}));
        expect(response.timestamp, equals(DateTime(2023, 1, 1)));
      });

      test('should create CachedResponse with current timestamp', () {
        final before = DateTime.now();
        final response = CachedResponse(
          data: {'key': 'value'},
          timestamp: DateTime.now(),
        );
        final after = DateTime.now();

        expect(response.data, equals({'key': 'value'}));
        expect(
          response.timestamp.isAfter(before) ||
              response.timestamp.isAtSameMomentAs(before),
          isTrue,
        );
        expect(
          response.timestamp.isBefore(after) ||
              response.timestamp.isAtSameMomentAs(after),
          isTrue,
        );
      });
    });

    group('Error Handling Tests', () {
      test('should handle inactive source gracefully', () async {
        await apiSource.close();

        expect(
          () => apiSource.getChunks(query: 'test'),
          throwsA(isA<StateError>()),
        );
      });
    });

    group('Lifecycle Tests', () {
      test('should close successfully', () async {
        expect(() => apiSource.close(), returnsNormally);
        expect(apiSource.isActive, isFalse);
      });

      test('should get stats successfully', () async {
        final stats = await apiSource.getStats();
        expect(stats, isA<Map<String, dynamic>>());
        expect(stats['name'], equals('Test API Source'));
        expect(stats['type'], equals('api'));
        expect(stats['base_url'], equals('https://api.example.com'));
        expect(stats['auth_configured'], isTrue);
        expect(stats['is_active'], isTrue);
      });

      test('should get configuration successfully', () {
        final config = apiSource.getConfiguration();
        expect(config, isA<Map<String, dynamic>>());
      });

      test('should update configuration successfully', () async {
        expect(
          () => apiSource.updateConfiguration({'new': 'config'}),
          returnsNormally,
        );
      });
    });
  });
}
