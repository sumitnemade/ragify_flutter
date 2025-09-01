import 'package:flutter_test/flutter_test.dart';
import 'package:ragify_flutter/src/models/privacy_level.dart';
import 'package:ragify_flutter/src/utils/privacy_utils.dart';

void main() {
  group('PrivacyUtils Tests', () {
    group('Privacy Level Access Tests', () {
      test('should allow access to same privacy level', () {
        final result = PrivacyUtils.isPrivacyLevelAllowed(
          PrivacyLevel.public,
          PrivacyLevel.public,
        );
        expect(result, isTrue);
      });

      test('should allow access to less restrictive level', () {
        final result = PrivacyUtils.isPrivacyLevelAllowed(
          PrivacyLevel.public,
          PrivacyLevel.private,
        );
        expect(result, isTrue);
      });

      test('should deny access to more restrictive level', () {
        final result = PrivacyUtils.isPrivacyLevelAllowed(
          PrivacyLevel.private,
          PrivacyLevel.public,
        );
        expect(result, isFalse);
      });

      test('should allow enterprise user to access private data', () {
        final result = PrivacyUtils.isPrivacyLevelAllowed(
          PrivacyLevel.private,
          PrivacyLevel.enterprise,
        );
        expect(result, isTrue);
      });

      test('should allow restricted user to access all levels', () {
        final result = PrivacyUtils.isPrivacyLevelAllowed(
          PrivacyLevel.public,
          PrivacyLevel.restricted,
        );
        expect(result, isTrue);
      });
    });

    group('Most Restrictive Level Tests', () {
      test('should find most restrictive level from list', () {
        final levels = [
          PrivacyLevel.public,
          PrivacyLevel.private,
          PrivacyLevel.enterprise,
        ];
        final mostRestrictive = PrivacyUtils.getMostRestrictive(levels);
        expect(mostRestrictive, equals(PrivacyLevel.public));
      });

      test('should handle single level', () {
        final levels = [PrivacyLevel.private];
        final mostRestrictive = PrivacyUtils.getMostRestrictive(levels);
        expect(mostRestrictive, equals(PrivacyLevel.private));
      });

      test('should handle empty list', () {
        final mostRestrictive = PrivacyUtils.getMostRestrictive([]);
        expect(mostRestrictive, equals(PrivacyLevel.restricted));
      });

      test('should handle all levels', () {
        final levels = [
          PrivacyLevel.restricted,
          PrivacyLevel.enterprise,
          PrivacyLevel.private,
          PrivacyLevel.public,
        ];
        final mostRestrictive = PrivacyUtils.getMostRestrictive(levels);
        expect(mostRestrictive, equals(PrivacyLevel.public));
      });
    });

    group('Least Restrictive Level Tests', () {
      test('should find least restrictive level from list', () {
        final levels = [
          PrivacyLevel.public,
          PrivacyLevel.private,
          PrivacyLevel.enterprise,
        ];
        final leastRestrictive = PrivacyUtils.getLeastRestrictive(levels);
        expect(leastRestrictive, equals(PrivacyLevel.enterprise));
      });

      test('should handle single level', () {
        final levels = [PrivacyLevel.private];
        final leastRestrictive = PrivacyUtils.getLeastRestrictive(levels);
        expect(leastRestrictive, equals(PrivacyLevel.private));
      });

      test('should handle empty list', () {
        final leastRestrictive = PrivacyUtils.getLeastRestrictive([]);
        expect(leastRestrictive, equals(PrivacyLevel.public));
      });

      test('should handle all levels', () {
        final levels = [
          PrivacyLevel.restricted,
          PrivacyLevel.enterprise,
          PrivacyLevel.private,
          PrivacyLevel.public,
        ];
        final leastRestrictive = PrivacyUtils.getLeastRestrictive(levels);
        expect(leastRestrictive, equals(PrivacyLevel.restricted));
      });
    });

    group('Encryption Requirements Tests', () {
      test('should require encryption for private level', () {
        final result = PrivacyUtils.requiresEncryption(PrivacyLevel.private);
        expect(result, isTrue);
      });

      test('should require encryption for enterprise level', () {
        final result = PrivacyUtils.requiresEncryption(PrivacyLevel.enterprise);
        expect(result, isTrue);
      });

      test('should require encryption for restricted level', () {
        final result = PrivacyUtils.requiresEncryption(PrivacyLevel.restricted);
        expect(result, isTrue);
      });

      test('should not require encryption for public level', () {
        final result = PrivacyUtils.requiresEncryption(PrivacyLevel.public);
        expect(result, isFalse);
      });
    });

    group('Audit Logging Requirements Tests', () {
      test('should require audit logging for enterprise level', () {
        final result = PrivacyUtils.requiresAuditLogging(PrivacyLevel.enterprise);
        expect(result, isTrue);
      });

      test('should require audit logging for restricted level', () {
        final result = PrivacyUtils.requiresAuditLogging(PrivacyLevel.restricted);
        expect(result, isTrue);
      });

      test('should not require audit logging for public level', () {
        final result = PrivacyUtils.requiresAuditLogging(PrivacyLevel.public);
        expect(result, isFalse);
      });

      test('should not require audit logging for private level', () {
        final result = PrivacyUtils.requiresAuditLogging(PrivacyLevel.private);
        expect(result, isFalse);
      });
    });

    group('User Consent Requirements Tests', () {
      test('should require user consent for private level', () {
        final result = PrivacyUtils.requiresUserConsent(PrivacyLevel.private);
        expect(result, isTrue);
      });

      test('should require user consent for enterprise level', () {
        final result = PrivacyUtils.requiresUserConsent(PrivacyLevel.enterprise);
        expect(result, isTrue);
      });

      test('should require user consent for restricted level', () {
        final result = PrivacyUtils.requiresUserConsent(PrivacyLevel.restricted);
        expect(result, isTrue);
      });

      test('should not require user consent for public level', () {
        final result = PrivacyUtils.requiresUserConsent(PrivacyLevel.public);
        expect(result, isFalse);
      });
    });

    group('Minimum User Level Tests', () {
      test('should return public for public data level', () {
        final result = PrivacyUtils.getMinimumUserLevel(PrivacyLevel.public);
        expect(result, equals(PrivacyLevel.public));
      });

      test('should return private for private data level', () {
        final result = PrivacyUtils.getMinimumUserLevel(PrivacyLevel.private);
        expect(result, equals(PrivacyLevel.private));
      });

      test('should return enterprise for enterprise data level', () {
        final result = PrivacyUtils.getMinimumUserLevel(PrivacyLevel.enterprise);
        expect(result, equals(PrivacyLevel.enterprise));
      });

      test('should return restricted for restricted data level', () {
        final result = PrivacyUtils.getMinimumUserLevel(PrivacyLevel.restricted);
        expect(result, equals(PrivacyLevel.restricted));
      });
    });

    group('Privacy Transition Validation Tests', () {
      test('should allow same level transition', () {
        final result = PrivacyUtils.isValidPrivacyTransition(
          PrivacyLevel.private,
          PrivacyLevel.private,
        );
        expect(result, isTrue);
      });

      test('should allow increase in privacy (decrease in index)', () {
        final result = PrivacyUtils.isValidPrivacyTransition(
          PrivacyLevel.private,
          PrivacyLevel.public,
        );
        expect(result, isTrue);
      });

      test('should allow increase to enterprise level', () {
        final result = PrivacyUtils.isValidPrivacyTransition(
          PrivacyLevel.enterprise,
          PrivacyLevel.private,
        );
        expect(result, isTrue);
      });

      test('should allow increase to restricted level', () {
        final result = PrivacyUtils.isValidPrivacyTransition(
          PrivacyLevel.enterprise,
          PrivacyLevel.public,
        );
        expect(result, isTrue);
      });

      test('should deny decrease in privacy (increase in index)', () {
        final result = PrivacyUtils.isValidPrivacyTransition(
          PrivacyLevel.public,
          PrivacyLevel.private,
        );
        expect(result, isFalse);
      });

      test('should deny decrease from enterprise to private', () {
        final result = PrivacyUtils.isValidPrivacyTransition(
          PrivacyLevel.private,
          PrivacyLevel.enterprise,
        );
        expect(result, isFalse);
      });
    });

    group('Privacy Level Description Tests', () {
      test('should return description for public level', () {
        final result = PrivacyUtils.getPrivacyLevelDescription(PrivacyLevel.public);
        expect(result, contains('Public'));
        expect(result, contains('Accessible to anyone'));
      });

      test('should return description for private level', () {
        final result = PrivacyUtils.getPrivacyLevelDescription(PrivacyLevel.private);
        expect(result, contains('Private'));
        expect(result, contains('Requires user authentication'));
      });

      test('should return description for enterprise level', () {
        final result = PrivacyUtils.getPrivacyLevelDescription(PrivacyLevel.enterprise);
        expect(result, contains('Enterprise'));
        expect(result, contains('Requires enterprise authentication'));
        expect(result, contains('audit logging'));
      });

      test('should return description for restricted level', () {
        final result = PrivacyUtils.getPrivacyLevelDescription(PrivacyLevel.restricted);
        expect(result, contains('Restricted'));
        expect(result, contains('Requires special authorization'));
        expect(result, contains('full audit trail'));
      });
    });

    group('Privacy Level Icon Tests', () {
      test('should return icon for public level', () {
        final result = PrivacyUtils.getPrivacyLevelIcon(PrivacyLevel.public);
        expect(result, equals('🌐'));
      });

      test('should return icon for private level', () {
        final result = PrivacyUtils.getPrivacyLevelIcon(PrivacyLevel.private);
        expect(result, equals('🔒'));
      });

      test('should return icon for enterprise level', () {
        final result = PrivacyUtils.getPrivacyLevelIcon(PrivacyLevel.enterprise);
        expect(result, equals('🏢'));
      });

      test('should return icon for restricted level', () {
        final result = PrivacyUtils.getPrivacyLevelIcon(PrivacyLevel.restricted);
        expect(result, equals('🚫'));
      });
    });

    group('Data Sharing Tests', () {
      test('should allow sharing when both users have access', () {
        final result = PrivacyUtils.canShareWithUser(
          PrivacyLevel.private,
          PrivacyLevel.enterprise,
          PrivacyLevel.enterprise,
        );
        expect(result, isTrue);
      });

      test('should deny sharing when source user lacks access', () {
        final result = PrivacyUtils.canShareWithUser(
          PrivacyLevel.enterprise,
          PrivacyLevel.private,
          PrivacyLevel.enterprise,
        );
        expect(result, isFalse);
      });

      test('should deny sharing when target user lacks access', () {
        final result = PrivacyUtils.canShareWithUser(
          PrivacyLevel.enterprise,
          PrivacyLevel.enterprise,
          PrivacyLevel.private,
        );
        expect(result, isFalse);
      });

      test('should allow public data sharing', () {
        final result = PrivacyUtils.canShareWithUser(
          PrivacyLevel.public,
          PrivacyLevel.public,
          PrivacyLevel.public,
        );
        expect(result, isTrue);
      });

      test('should allow restricted user to share with enterprise user', () {
        final result = PrivacyUtils.canShareWithUser(
          PrivacyLevel.private,
          PrivacyLevel.restricted,
          PrivacyLevel.enterprise,
        );
        expect(result, isTrue);
      });
    });

    group('Required Consent Types Tests', () {
      test('should return no consent types for public level', () {
        final result = PrivacyUtils.getRequiredConsentTypes(PrivacyLevel.public);
        expect(result, isEmpty);
      });

      test('should return basic consent types for private level', () {
        final result = PrivacyUtils.getRequiredConsentTypes(PrivacyLevel.private);
        expect(result, contains('data_access'));
        expect(result, contains('data_processing'));
        expect(result.length, equals(2));
      });

      test('should return extended consent types for enterprise level', () {
        final result = PrivacyUtils.getRequiredConsentTypes(PrivacyLevel.enterprise);
        expect(result, contains('data_access'));
        expect(result, contains('data_processing'));
        expect(result, contains('data_sharing'));
        expect(result, contains('audit_logging'));
        expect(result.length, equals(4));
      });

      test('should return all consent types for restricted level', () {
        final result = PrivacyUtils.getRequiredConsentTypes(PrivacyLevel.restricted);
        expect(result, contains('data_access'));
        expect(result, contains('data_processing'));
        expect(result, contains('data_sharing'));
        expect(result, contains('audit_logging'));
        expect(result, contains('special_authorization'));
        expect(result.length, equals(5));
      });
    });

    group('Data Export Tests', () {
      test('should allow data export for private level', () {
        final result = PrivacyUtils.allowsDataExport(PrivacyLevel.private);
        expect(result, isTrue);
      });

      test('should allow data export for enterprise level', () {
        final result = PrivacyUtils.allowsDataExport(PrivacyLevel.enterprise);
        expect(result, isTrue);
      });

      test('should allow data export for restricted level', () {
        final result = PrivacyUtils.allowsDataExport(PrivacyLevel.restricted);
        expect(result, isTrue);
      });

      test('should not allow data export for public level', () {
        final result = PrivacyUtils.allowsDataExport(PrivacyLevel.public);
        expect(result, isFalse);
      });
    });

    group('Data Deletion Tests', () {
      test('should allow data deletion for private level', () {
        final result = PrivacyUtils.allowsDataDeletion(PrivacyLevel.private);
        expect(result, isTrue);
      });

      test('should allow data deletion for enterprise level', () {
        final result = PrivacyUtils.allowsDataDeletion(PrivacyLevel.enterprise);
        expect(result, isTrue);
      });

      test('should allow data deletion for restricted level', () {
        final result = PrivacyUtils.allowsDataDeletion(PrivacyLevel.restricted);
        expect(result, isTrue);
      });

      test('should not allow data deletion for public level', () {
        final result = PrivacyUtils.allowsDataDeletion(PrivacyLevel.public);
        expect(result, isFalse);
      });
    });

    group('Data Retention Requirements Tests', () {
      test('should return retention requirements for public level', () {
        final result = PrivacyUtils.getDataRetentionRequirements(PrivacyLevel.public);
        expect(result['retention_period'], equals('indefinite'));
        expect(result['backup_required'], isFalse);
        expect(result['archival_required'], isFalse);
      });

      test('should return retention requirements for private level', () {
        final result = PrivacyUtils.getDataRetentionRequirements(PrivacyLevel.private);
        expect(result['retention_period'], equals('7_years'));
        expect(result['backup_required'], isTrue);
        expect(result['archival_required'], isFalse);
      });

      test('should return retention requirements for enterprise level', () {
        final result = PrivacyUtils.getDataRetentionRequirements(PrivacyLevel.enterprise);
        expect(result['retention_period'], equals('10_years'));
        expect(result['backup_required'], isTrue);
        expect(result['archival_required'], isTrue);
      });

      test('should return retention requirements for restricted level', () {
        final result = PrivacyUtils.getDataRetentionRequirements(PrivacyLevel.restricted);
        expect(result['retention_period'], equals('indefinite'));
        expect(result['backup_required'], isTrue);
        expect(result['archival_required'], isTrue);
      });
    });

    group('Data Anonymization Tests', () {
      test('should require anonymization for enterprise level', () {
        final result = PrivacyUtils.requiresAnonymization(PrivacyLevel.enterprise);
        expect(result, isTrue);
      });

      test('should require anonymization for restricted level', () {
        final result = PrivacyUtils.requiresAnonymization(PrivacyLevel.restricted);
        expect(result, isTrue);
      });

      test('should not require anonymization for public level', () {
        final result = PrivacyUtils.requiresAnonymization(PrivacyLevel.public);
        expect(result, isFalse);
      });

      test('should not require anonymization for private level', () {
        final result = PrivacyUtils.requiresAnonymization(PrivacyLevel.private);
        expect(result, isFalse);
      });
    });

    group('Compliance Frameworks Tests', () {
      test('should return no frameworks for public level', () {
        final result = PrivacyUtils.getComplianceFrameworks(PrivacyLevel.public);
        expect(result, isEmpty);
      });

      test('should return GDPR for private level', () {
        final result = PrivacyUtils.getComplianceFrameworks(PrivacyLevel.private);
        expect(result, contains('GDPR'));
        expect(result.length, equals(1));
      });

      test('should return multiple frameworks for enterprise level', () {
        final result = PrivacyUtils.getComplianceFrameworks(PrivacyLevel.enterprise);
        expect(result, contains('GDPR'));
        expect(result, contains('CCPA'));
        expect(result, contains('SOX'));
        expect(result.length, equals(3));
      });

      test('should return all frameworks for restricted level', () {
        final result = PrivacyUtils.getComplianceFrameworks(PrivacyLevel.restricted);
        expect(result, contains('GDPR'));
        expect(result, contains('CCPA'));
        expect(result, contains('SOX'));
        expect(result, contains('HIPAA'));
        expect(result, contains('FERPA'));
        expect(result.length, equals(5));
      });
    });

    group('Edge Cases Tests', () {
      test('should handle boundary privacy levels', () {
        // Test the most restrictive level
        final mostRestrictive = PrivacyUtils.getMostRestrictive([
          PrivacyLevel.public,
          PrivacyLevel.restricted,
        ]);
        expect(mostRestrictive, equals(PrivacyLevel.public));

        // Test the least restrictive level
        final leastRestrictive = PrivacyUtils.getLeastRestrictive([
          PrivacyLevel.public,
          PrivacyLevel.restricted,
        ]);
        expect(leastRestrictive, equals(PrivacyLevel.restricted));
      });

      test('should handle all privacy level combinations', () {
        final allLevels = [
          PrivacyLevel.public,
          PrivacyLevel.private,
          PrivacyLevel.enterprise,
          PrivacyLevel.restricted,
        ];

        // Test that all levels can be processed
        for (final level in allLevels) {
          expect(PrivacyUtils.requiresEncryption(level), isA<bool>());
          expect(PrivacyUtils.requiresAuditLogging(level), isA<bool>());
          expect(PrivacyUtils.requiresUserConsent(level), isA<bool>());
          expect(PrivacyUtils.allowsDataExport(level), isA<bool>());
          expect(PrivacyUtils.allowsDataDeletion(level), isA<bool>());
          expect(PrivacyUtils.requiresAnonymization(level), isA<bool>());
          expect(PrivacyUtils.getPrivacyLevelDescription(level), isA<String>());
          expect(PrivacyUtils.getPrivacyLevelIcon(level), isA<String>());
          expect(PrivacyUtils.getRequiredConsentTypes(level), isA<List<String>>());
          expect(PrivacyUtils.getDataRetentionRequirements(level), isA<Map<String, dynamic>>());
          expect(PrivacyUtils.getComplianceFrameworks(level), isA<List<String>>());
        }
      });
    });
  });
}
