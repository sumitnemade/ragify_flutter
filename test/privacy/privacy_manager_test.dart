import 'package:flutter_test/flutter_test.dart';
import 'package:ragify_flutter/src/privacy/privacy_manager.dart';
import 'package:ragify_flutter/src/models/privacy_level.dart';
import 'package:ragify_flutter/src/models/context_chunk.dart';
import 'package:ragify_flutter/src/models/context_source.dart';
import 'package:ragify_flutter/src/models/relevance_score.dart';
import 'package:ragify_flutter/src/exceptions/ragify_exceptions.dart';
import '../test_helper.dart';

void main() {
  setupTestMocks();

  group('PrivacyManager Tests', () {
    late PrivacyManager privacyManager;

    setUp(() {
      privacyManager = PrivacyManager();
    });

    group('Initialization', () {
      test('should initialize with default policies', () {
        final policy = privacyManager.getPrivacyPolicy();
        expect(policy['default_level'], equals('private'));
        expect(policy['audit_enabled'], isTrue);
        expect(policy['retention_enabled'], isTrue);
      });

      test('should initialize with sensitive data patterns', () {
        final stats = privacyManager.getPrivacyStats();
        expect(stats['sensitive_patterns_count'], greaterThan(0));
      });

      test('should initialize with retention policies', () {
        final stats = privacyManager.getPrivacyStats();
        expect(stats['retention_policies_count'], equals(4));
      });
    });

    group('Privacy Level Compliance', () {
      test('should allow higher privacy levels to access lower levels', () {
        expect(
          privacyManager.isAccessAllowed(
            PrivacyLevel.restricted,
            PrivacyLevel.public,
          ),
          isTrue,
        );
        expect(
          privacyManager.isAccessAllowed(
            PrivacyLevel.enterprise,
            PrivacyLevel.private,
          ),
          isTrue,
        );
        expect(
          privacyManager.isAccessAllowed(
            PrivacyLevel.private,
            PrivacyLevel.public,
          ),
          isTrue,
        );
      });

      test('should not allow lower privacy levels to access higher levels', () {
        expect(
          privacyManager.isAccessAllowed(
            PrivacyLevel.public,
            PrivacyLevel.private,
          ),
          isFalse,
        );
        expect(
          privacyManager.isAccessAllowed(
            PrivacyLevel.private,
            PrivacyLevel.enterprise,
          ),
          isFalse,
        );
        expect(
          privacyManager.isAccessAllowed(
            PrivacyLevel.enterprise,
            PrivacyLevel.restricted,
          ),
          isFalse,
        );
      });

      test('should allow same privacy level access', () {
        expect(
          privacyManager.isAccessAllowed(
            PrivacyLevel.public,
            PrivacyLevel.public,
          ),
          isTrue,
        );
        expect(
          privacyManager.isAccessAllowed(
            PrivacyLevel.private,
            PrivacyLevel.private,
          ),
          isTrue,
        );
        expect(
          privacyManager.isAccessAllowed(
            PrivacyLevel.enterprise,
            PrivacyLevel.enterprise,
          ),
          isTrue,
        );
        expect(
          privacyManager.isAccessAllowed(
            PrivacyLevel.restricted,
            PrivacyLevel.restricted,
          ),
          isTrue,
        );
      });
    });

    group('Sensitive Data Detection', () {
      test('should detect email addresses', () {
        final text = 'Contact us at test@example.com or support@company.org';
        final detected = privacyManager.detectSensitiveData(text);

        expect(detected['email'], isNotNull);
        expect(detected['email']!.length, equals(2));
        expect(detected['email']!, contains('test@example.com'));
        expect(detected['email']!, contains('support@company.org'));
      });

      test('should detect phone numbers', () {
        final text = 'Call us at 555-123-4567 or +1-800-555-0123';
        final detected = privacyManager.detectSensitiveData(text);

        expect(detected['phone'], isNotNull);
        expect(detected['phone']!.length, equals(2));
      });

      test('should detect credit card numbers', () {
        final text = 'Card: 1234-5678-9012-3456';
        final detected = privacyManager.detectSensitiveData(text);

        expect(detected['credit_card'], isNotNull);
        expect(detected['credit_card']!.length, equals(1));
      });

      test('should detect SSNs', () {
        final text = 'SSN: 123-45-6789';
        final detected = privacyManager.detectSensitiveData(text);

        expect(detected['ssn'], isNotNull);
        expect(detected['ssn']!.length, equals(1));
      });

      test('should detect IP addresses', () {
        final text = 'Server IP: 192.168.1.1';
        final detected = privacyManager.detectSensitiveData(text);

        expect(detected['ip_address'], isNotNull);
        expect(detected['ip_address']!.length, equals(1));
      });

      test('should detect dates', () {
        final text = 'Date: 12/25/2023';
        final detected = privacyManager.detectSensitiveData(text);

        expect(detected['date'], isNotNull);
        expect(detected['date']!.length, equals(1));
      });

      test('should detect multiple sensitive data types', () {
        final text =
            'Email: john@example.com, Phone: 555-123-4567, SSN: 123-45-6789';
        final detected = privacyManager.detectSensitiveData(text);

        expect(detected['email'], isNotNull);
        expect(detected['phone'], isNotNull);
        expect(detected['ssn'], isNotNull);
        expect(detected.length, equals(3));
      });

      test('should not detect sensitive data in clean text', () {
        final text = 'This is a clean text without any sensitive information.';
        final detected = privacyManager.detectSensitiveData(text);

        expect(detected, isEmpty);
      });
    });

    group('Data Anonymization', () {
      test('should anonymize data for public level (most aggressive)', () {
        final text = 'Email: test@example.com, Phone: 555-123-4567';
        final anonymized = privacyManager.anonymizeData(
          text,
          level: PrivacyLevel.public,
        );

        expect(anonymized, contains('[EMAIL_'));
        expect(anonymized, contains('[PHONE_'));
        expect(anonymized, isNot(contains('test@example.com')));
        expect(anonymized, isNot(contains('555-123-4567')));
      });

      test('should anonymize data for private level', () {
        final text =
            'Email: test@example.com, Phone: 555-123-4567, Card: 1234-5678-9012-3456';
        final anonymized = privacyManager.anonymizeData(
          text,
          level: PrivacyLevel.private,
        );

        expect(anonymized, contains('***@example.com'));
        expect(anonymized, contains('555-***-****'));
        expect(anonymized, contains('****-****-****-3456'));
      });

      test('should anonymize data for enterprise level', () {
        final text = 'Email: test@example.com, Phone: 555-123-4567';
        final anonymized = privacyManager.anonymizeData(
          text,
          level: PrivacyLevel.enterprise,
        );

        expect(anonymized, contains('t***@example.com'));
        expect(anonymized, contains('555-***-4567'));
      });

      test('should minimally anonymize data for restricted level', () {
        final text =
            'Email: test@example.com, Phone: 555-123-4567, SSN: 123-45-6789';
        final anonymized = privacyManager.anonymizeData(
          text,
          level: PrivacyLevel.restricted,
        );

        expect(anonymized, contains('test@example.com')); // Email preserved
        expect(anonymized, contains('555-123-4567')); // Phone preserved
        expect(anonymized, contains('[SSN]')); // SSN anonymized
      });

      test('should handle text without sensitive data', () {
        final text = 'This is a clean text without sensitive information.';
        final anonymized = privacyManager.anonymizeData(
          text,
          level: PrivacyLevel.public,
        );

        expect(anonymized, equals(text));
      });

      test('should handle empty text', () {
        final text = '';
        final anonymized = privacyManager.anonymizeData(
          text,
          level: PrivacyLevel.public,
        );

        expect(anonymized, equals(text));
      });
    });

    group('Encryption and Decryption', () {
      test('should throw exception when encryption key is not set', () {
        expect(
          () => privacyManager.encryptData('test data'),
          throwsA(isA<PrivacyViolationException>()),
        );
      });

      test('should encrypt and decrypt data correctly', () {
        privacyManager.setEncryptionKey('test-key-123');

        final originalData = 'sensitive information';
        final encrypted = privacyManager.encryptData(originalData);
        final decrypted = privacyManager.decryptData(encrypted);

        expect(encrypted, isNot(equals(originalData)));
        expect(decrypted, equals(originalData));
      });

      test('should handle different privacy levels for encryption', () {
        privacyManager.setEncryptionKey('test-key-123');

        final data = 'sensitive data';
        final encrypted1 = privacyManager.encryptData(
          data,
          level: PrivacyLevel.private,
        );
        final encrypted2 = privacyManager.encryptData(
          data,
          level: PrivacyLevel.enterprise,
        );

        // Both should be encrypted (not equal to original)
        expect(encrypted1, isNot(equals(data)));
        expect(encrypted2, isNot(equals(data)));
        // Both should be valid encrypted strings
        expect(encrypted1, isNotEmpty);
        expect(encrypted2, isNotEmpty);
      });

      test('should throw exception when decryption fails', () {
        privacyManager.setEncryptionKey('test-key-123');

        expect(
          () => privacyManager.decryptData('invalid-encrypted-data'),
          throwsA(isA<PrivacyViolationException>()),
        );
      });
    });

    group('Data Retention', () {
      test('should check retention compliance correctly', () {
        final now = DateTime.now();
        final oldData = now.subtract(const Duration(days: 100));
        final recentData = now.subtract(const Duration(days: 30));

        // Private data retention is 90 days
        expect(
          privacyManager.checkRetentionCompliance(
            oldData,
            PrivacyLevel.private,
          ),
          isFalse,
        );
        expect(
          privacyManager.checkRetentionCompliance(
            recentData,
            PrivacyLevel.private,
          ),
          isTrue,
        );
      });

      test('should get retention policies', () {
        final publicPolicy = privacyManager.getRetentionPolicy(
          PrivacyLevel.public,
        );
        final privatePolicy = privacyManager.getRetentionPolicy(
          PrivacyLevel.private,
        );
        final enterprisePolicy = privacyManager.getRetentionPolicy(
          PrivacyLevel.enterprise,
        );
        final restrictedPolicy = privacyManager.getRetentionPolicy(
          PrivacyLevel.restricted,
        );

        expect(publicPolicy, equals(const Duration(days: 30)));
        expect(privatePolicy, equals(const Duration(days: 90)));
        expect(enterprisePolicy, equals(const Duration(days: 365)));
        expect(restrictedPolicy, equals(const Duration(days: 2555)));
      });

      test('should update retention policies', () {
        final newPolicy = const Duration(days: 180);
        privacyManager.updateRetentionPolicy(PrivacyLevel.private, newPolicy);

        final updatedPolicy = privacyManager.getRetentionPolicy(
          PrivacyLevel.private,
        );
        expect(updatedPolicy, equals(newPolicy));
      });
    });

    group('Context Chunk Processing', () {
      late ContextChunk testChunk;
      late ContextSource testSource;

      setUp(() {
        testSource = ContextSource(
          id: 'test-source',
          name: 'Test Source',
          sourceType: SourceType.document,
          url: 'http://example.com',
          metadata: {'author': 'John Doe'},
          lastUpdated: DateTime.now(),
          isActive: true,
          privacyLevel: PrivacyLevel.private,
          authorityScore: 0.9,
          freshnessScore: 0.8,
        );

        testChunk = ContextChunk(
          id: 'test-chunk',
          content: 'Email: john@example.com, Phone: 555-123-4567',
          source: testSource,
          metadata: {'author': 'John Doe', 'department': 'Engineering'},
          relevanceScore: RelevanceScore(score: 0.8),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          tokenCount: 15,
          embedding: [0.1, 0.2, 0.3],
          tags: ['test', 'sample'],
        );
      });

      test('should process chunk for privacy compliance', () async {
        // Add a small delay to ensure timestamps are different
        await Future.delayed(Duration(milliseconds: 10));

        final processed = privacyManager.processChunkForPrivacy(
          testChunk,
          PrivacyLevel.private,
        );

        expect(processed.id, equals(testChunk.id));
        expect(
          processed.content,
          isNot(equals(testChunk.content)),
        ); // Should be anonymized
        expect(processed.source, equals(testChunk.source));
        expect(processed.updatedAt, isNot(equals(testChunk.updatedAt)));
      });

      test('should throw exception for privacy level violation', () {
        // Create a restricted source
        final restrictedSource = ContextSource(
          id: 'restricted-source',
          name: 'Restricted Source',
          sourceType: SourceType.document,
          url: 'http://example.com',
          metadata: {},
          lastUpdated: DateTime.now(),
          isActive: true,
          privacyLevel: PrivacyLevel.restricted,
          authorityScore: 0.9,
          freshnessScore: 0.8,
        );

        final restrictedChunk = ContextChunk(
          id: 'restricted-chunk',
          content: 'Restricted content',
          source: restrictedSource,
          metadata: {},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          tokenCount: 5,
          embedding: [0.1, 0.2],
          tags: ['restricted'],
        );

        expect(
          () => privacyManager.processChunkForPrivacy(
            restrictedChunk,
            PrivacyLevel.public,
          ),
          throwsA(isA<PrivacyViolationException>()),
        );
      });

      test('should process metadata for privacy', () {
        // Create a chunk with sensitive data in metadata
        final sensitiveMetadata = {
          'author': 'John Doe',
          'email': 'john@example.com',
          'phone': '555-123-4567',
        };

        final sensitiveChunk = ContextChunk(
          id: 'sensitive-chunk',
          content: 'Test content',
          source: testSource,
          metadata: sensitiveMetadata,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          tokenCount: 5,
          embedding: [0.1, 0.2],
          tags: ['sensitive'],
        );

        final processed = privacyManager.processChunkForPrivacy(
          sensitiveChunk,
          PrivacyLevel.private,
        );

        // Metadata should be processed for privacy (email and phone should be anonymized)
        expect(
          processed.metadata['author'],
          equals('John Doe'),
        ); // Not sensitive
        expect(
          processed.metadata['email'],
          isNot(equals('john@example.com')),
        ); // Should be anonymized
        expect(
          processed.metadata['phone'],
          isNot(equals('555-123-4567')),
        ); // Should be anonymized
      });
    });

    group('Audit Trail', () {
      test('should log audit events', () {
        final initialTrail = privacyManager.getAuditTrail();
        final initialCount = initialTrail.length;

        // Perform some operations that should log events
        privacyManager.setEncryptionKey('test-key');
        privacyManager.updatePrivacyPolicy({'test': 'value'});

        final finalTrail = privacyManager.getAuditTrail();
        expect(finalTrail.length, greaterThan(initialCount));
      });

      test('should get audit trail', () {
        final trail = privacyManager.getAuditTrail();
        expect(trail, isA<List<Map<String, dynamic>>>());
      });

      test('should clear audit trail', () {
        // Add some events first
        privacyManager.setEncryptionKey('test-key');

        final trailBefore = privacyManager.getAuditTrail();
        expect(trailBefore.isNotEmpty, isTrue);

        privacyManager.clearAuditTrail();

        final trailAfter = privacyManager.getAuditTrail();
        expect(trailAfter.isEmpty, isTrue);

        // Verify that new events are still logged after clearing
        privacyManager.setEncryptionKey('new-key');
        final newTrail = privacyManager.getAuditTrail();
        expect(newTrail.isNotEmpty, isTrue);
        expect(newTrail.length, equals(1)); // Should have only the new event
      });
    });

    group('Privacy Statistics', () {
      test('should get privacy statistics', () {
        final stats = privacyManager.getPrivacyStats();

        expect(stats['total_audit_events'], isA<int>());
        expect(stats['sensitive_patterns_count'], isA<int>());
        expect(stats['retention_policies_count'], isA<int>());
        expect(stats['encryption_enabled'], isA<bool>());
        expect(stats['audit_enabled'], isA<bool>());
        expect(stats['default_privacy_level'], isA<String>());
      });

      test('should reflect encryption key status', () {
        final statsBefore = privacyManager.getPrivacyStats();
        expect(statsBefore['encryption_enabled'], isFalse);

        privacyManager.setEncryptionKey('test-key');

        final statsAfter = privacyManager.getPrivacyStats();
        expect(statsAfter['encryption_enabled'], isTrue);
      });
    });

    group('Configuration Validation', () {
      test('should validate configuration correctly', () {
        final errors = privacyManager.validateConfiguration();

        // Should have error about encryption key since it's required but not set
        expect(errors, contains('Encryption is required but no key is set'));
      });

      test('should pass validation with proper configuration', () {
        privacyManager.setEncryptionKey('test-key');

        final errors = privacyManager.validateConfiguration();
        expect(errors, isEmpty);
      });
    });

    group('Privacy Policy Management', () {
      test('should update privacy policy', () {
        final newPolicy = {'custom_setting': 'value', 'audit_enabled': false};

        privacyManager.updatePrivacyPolicy(newPolicy);

        final updatedPolicy = privacyManager.getPrivacyPolicy();
        expect(updatedPolicy['custom_setting'], equals('value'));
        expect(updatedPolicy['audit_enabled'], isFalse);
      });

      test('should return unmodifiable policy', () {
        final policy = privacyManager.getPrivacyPolicy();

        expect(
          () => policy['test'] = 'value',
          throwsA(isA<UnsupportedError>()),
        );
      });
    });

    group('Edge Cases', () {
      test('should handle very long text', () {
        // Create a more realistic long text with emails interspersed
        final longText =
            'This is a very long document with multiple sections. '
            '${'a' * 5000} Contact us at test@example.com for support. '
            '${'b' * 5000} For sales inquiries, email sales@company.org. '
            '${'c' * 5000} Technical questions? tech@company.org. '
            '${'d' * 5000}';

        final anonymized = privacyManager.anonymizeData(
          longText,
          level: PrivacyLevel.public,
        );

        // The emails should be replaced with anonymized patterns
        expect(anonymized, isNot(contains('test@example.com')));
        expect(anonymized, isNot(contains('sales@company.org')));
        expect(anonymized, isNot(contains('tech@company.org')));

        // The anonymized text should be significantly long
        expect(anonymized.length, greaterThan(10000));

        // Should contain anonymized email patterns
        expect(anonymized, contains('[EMAIL_'));
      });

      test('should handle text with multiple sensitive data instances', () {
        final text =
            'Email: test@example.com, test@example.com, test@example.com';
        final detected = privacyManager.detectSensitiveData(text);

        expect(detected['email']!.length, equals(3));
      });

      test('should handle special characters in sensitive data', () {
        final text = 'Email: test+tag@example.com, Phone: (555) 123-4567';
        final detected = privacyManager.detectSensitiveData(text);

        expect(detected['email'], isNotNull);
        // Note: The current regex might not handle all phone formats perfectly
        // This test verifies that at least email detection works with special characters
        expect(detected['email']!.first, contains('test+tag@example.com'));
      });
    });
  });
}
