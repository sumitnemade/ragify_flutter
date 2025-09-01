import 'package:flutter_test/flutter_test.dart';
import 'package:ragify_flutter/src/utils/privacy_utils.dart';
import 'package:ragify_flutter/src/models/privacy_level.dart';

void main() {
  group('PrivacyUtils Tests', () {
    group('Privacy Level Requirements Tests', () {
      test('should check encryption requirements', () {
        expect(PrivacyUtils.requiresEncryption(PrivacyLevel.public), isFalse);
        expect(PrivacyUtils.requiresEncryption(PrivacyLevel.private), isTrue);
        expect(
          PrivacyUtils.requiresEncryption(PrivacyLevel.enterprise),
          isTrue,
        );
        expect(
          PrivacyUtils.requiresEncryption(PrivacyLevel.restricted),
          isTrue,
        );
      });

      test('should check audit logging requirements', () {
        expect(PrivacyUtils.requiresAuditLogging(PrivacyLevel.public), isFalse);
        expect(
          PrivacyUtils.requiresAuditLogging(PrivacyLevel.private),
          isFalse,
        );
        expect(
          PrivacyUtils.requiresAuditLogging(PrivacyLevel.enterprise),
          isTrue,
        );
        expect(
          PrivacyUtils.requiresAuditLogging(PrivacyLevel.restricted),
          isTrue,
        );
      });

      test('should check user consent requirements', () {
        expect(PrivacyUtils.requiresUserConsent(PrivacyLevel.public), isFalse);
        expect(PrivacyUtils.requiresUserConsent(PrivacyLevel.private), isTrue);
        expect(
          PrivacyUtils.requiresUserConsent(PrivacyLevel.enterprise),
          isTrue,
        );
        expect(
          PrivacyUtils.requiresUserConsent(PrivacyLevel.restricted),
          isTrue,
        );
      });
    });

    group('Minimum User Level Tests', () {
      test('should return correct minimum user level for each data level', () {
        expect(
          PrivacyUtils.getMinimumUserLevel(PrivacyLevel.public),
          equals(PrivacyLevel.public),
        );
        expect(
          PrivacyUtils.getMinimumUserLevel(PrivacyLevel.private),
          equals(PrivacyLevel.private),
        );
        expect(
          PrivacyUtils.getMinimumUserLevel(PrivacyLevel.enterprise),
          equals(PrivacyLevel.enterprise),
        );
        expect(
          PrivacyUtils.getMinimumUserLevel(PrivacyLevel.restricted),
          equals(PrivacyLevel.restricted),
        );
      });
    });

    group('Privacy Level Description Tests', () {
      test('should return correct descriptions for each level', () {
        expect(
          PrivacyUtils.getPrivacyLevelDescription(PrivacyLevel.public),
          contains('Public - Accessible to anyone'),
        );
        expect(
          PrivacyUtils.getPrivacyLevelDescription(PrivacyLevel.private),
          contains('Private - Requires user authentication'),
        );
        expect(
          PrivacyUtils.getPrivacyLevelDescription(PrivacyLevel.enterprise),
          contains(
            'Enterprise - Requires enterprise authentication and audit logging',
          ),
        );
        expect(
          PrivacyUtils.getPrivacyLevelDescription(PrivacyLevel.restricted),
          contains(
            'Restricted - Requires special authorization and full audit trail',
          ),
        );
      });
    });

    group('Privacy Level Icon Tests', () {
      test('should return correct icons for each level', () {
        expect(
          PrivacyUtils.getPrivacyLevelIcon(PrivacyLevel.public),
          equals('🌐'),
        );
        expect(
          PrivacyUtils.getPrivacyLevelIcon(PrivacyLevel.private),
          equals('🔒'),
        );
        expect(
          PrivacyUtils.getPrivacyLevelIcon(PrivacyLevel.enterprise),
          equals('🏢'),
        );
        expect(
          PrivacyUtils.getPrivacyLevelIcon(PrivacyLevel.restricted),
          equals('🚫'),
        );
      });
    });

    group('Required Consent Types Tests', () {
      test('should return correct consent types for each level', () {
        expect(
          PrivacyUtils.getRequiredConsentTypes(PrivacyLevel.public),
          isEmpty,
        );

        final privateConsents = PrivacyUtils.getRequiredConsentTypes(
          PrivacyLevel.private,
        );
        expect(privateConsents, contains('data_access'));
        expect(privateConsents, contains('data_processing'));
        expect(privateConsents.length, equals(2));

        final enterpriseConsents = PrivacyUtils.getRequiredConsentTypes(
          PrivacyLevel.enterprise,
        );
        expect(enterpriseConsents, contains('data_access'));
        expect(enterpriseConsents, contains('data_processing'));
        expect(enterpriseConsents, contains('data_sharing'));
        expect(enterpriseConsents, contains('audit_logging'));
        expect(enterpriseConsents.length, equals(4));

        final restrictedConsents = PrivacyUtils.getRequiredConsentTypes(
          PrivacyLevel.restricted,
        );
        expect(restrictedConsents, contains('data_access'));
        expect(restrictedConsents, contains('data_processing'));
        expect(restrictedConsents, contains('data_sharing'));
        expect(restrictedConsents, contains('audit_logging'));
        expect(restrictedConsents, contains('special_authorization'));
        expect(restrictedConsents.length, equals(5));
      });
    });

    group('Data Operations Tests', () {
      test('should check data export permissions', () {
        expect(PrivacyUtils.allowsDataExport(PrivacyLevel.public), isFalse);
        expect(PrivacyUtils.allowsDataExport(PrivacyLevel.private), isTrue);
        expect(PrivacyUtils.allowsDataExport(PrivacyLevel.enterprise), isTrue);
        expect(PrivacyUtils.allowsDataExport(PrivacyLevel.restricted), isTrue);
      });

      test('should check data deletion permissions', () {
        expect(PrivacyUtils.allowsDataDeletion(PrivacyLevel.public), isFalse);
        expect(PrivacyUtils.allowsDataDeletion(PrivacyLevel.private), isTrue);
        expect(
          PrivacyUtils.allowsDataDeletion(PrivacyLevel.enterprise),
          isTrue,
        );
        expect(
          PrivacyUtils.allowsDataDeletion(PrivacyLevel.restricted),
          isTrue,
        );
      });
    });

    group('Data Retention Tests', () {
      test('should return correct retention requirements for public level', () {
        final requirements = PrivacyUtils.getDataRetentionRequirements(
          PrivacyLevel.public,
        );
        expect(requirements['retention_period'], equals('indefinite'));
        expect(requirements['backup_required'], isFalse);
        expect(requirements['archival_required'], isFalse);
      });

      test(
        'should return correct retention requirements for private level',
        () {
          final requirements = PrivacyUtils.getDataRetentionRequirements(
            PrivacyLevel.private,
          );
          expect(requirements['retention_period'], equals('7_years'));
          expect(requirements['backup_required'], isTrue);
          expect(requirements['archival_required'], isFalse);
        },
      );

      test(
        'should return correct retention requirements for enterprise level',
        () {
          final requirements = PrivacyUtils.getDataRetentionRequirements(
            PrivacyLevel.enterprise,
          );
          expect(requirements['retention_period'], equals('10_years'));
          expect(requirements['backup_required'], isTrue);
          expect(requirements['archival_required'], isTrue);
        },
      );

      test(
        'should return correct retention requirements for restricted level',
        () {
          final requirements = PrivacyUtils.getDataRetentionRequirements(
            PrivacyLevel.restricted,
          );
          expect(requirements['retention_period'], equals('indefinite'));
          expect(requirements['backup_required'], isTrue);
          expect(requirements['archival_required'], isTrue);
        },
      );
    });

    group('Data Anonymization Tests', () {
      test('should check anonymization requirements', () {
        expect(
          PrivacyUtils.requiresAnonymization(PrivacyLevel.public),
          isFalse,
        );
        expect(
          PrivacyUtils.requiresAnonymization(PrivacyLevel.private),
          isFalse,
        );
        expect(
          PrivacyUtils.requiresAnonymization(PrivacyLevel.enterprise),
          isTrue,
        );
        expect(
          PrivacyUtils.requiresAnonymization(PrivacyLevel.restricted),
          isTrue,
        );
      });
    });

    group('Compliance Framework Tests', () {
      test('should return correct compliance frameworks for each level', () {
        expect(
          PrivacyUtils.getComplianceFrameworks(PrivacyLevel.public),
          isEmpty,
        );

        final privateFrameworks = PrivacyUtils.getComplianceFrameworks(
          PrivacyLevel.private,
        );
        expect(privateFrameworks, contains('GDPR'));
        expect(privateFrameworks.length, equals(1));

        final enterpriseFrameworks = PrivacyUtils.getComplianceFrameworks(
          PrivacyLevel.enterprise,
        );
        expect(enterpriseFrameworks, contains('GDPR'));
        expect(enterpriseFrameworks, contains('CCPA'));
        expect(enterpriseFrameworks, contains('SOX'));
        expect(enterpriseFrameworks.length, equals(3));

        final restrictedFrameworks = PrivacyUtils.getComplianceFrameworks(
          PrivacyLevel.restricted,
        );
        expect(restrictedFrameworks, contains('GDPR'));
        expect(restrictedFrameworks, contains('CCPA'));
        expect(restrictedFrameworks, contains('SOX'));
        expect(restrictedFrameworks, contains('HIPAA'));
        expect(restrictedFrameworks, contains('FERPA'));
        expect(restrictedFrameworks.length, equals(5));
      });
    });

    group('Utility Method Tests', () {
      test('should handle basic privacy level operations', () {
        // Test that methods handle basic operations without errors
        expect(
          () => PrivacyUtils.getMostRestrictive([
            PrivacyLevel.public,
            PrivacyLevel.private,
          ]),
          returnsNormally,
        );
        expect(
          () => PrivacyUtils.getLeastRestrictive([
            PrivacyLevel.public,
            PrivacyLevel.private,
          ]),
          returnsNormally,
        );
        expect(
          () => PrivacyUtils.isValidPrivacyTransition(
            PrivacyLevel.public,
            PrivacyLevel.private,
          ),
          returnsNormally,
        );
        expect(
          () => PrivacyUtils.canShareWithUser(
            PrivacyLevel.public,
            PrivacyLevel.public,
            PrivacyLevel.public,
          ),
          returnsNormally,
        );
      });
    });
  });
}
