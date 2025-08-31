import '../models/privacy_level.dart';

/// Utility functions for privacy operations
class PrivacyUtils {
  /// Check if a requested privacy level is allowed for a given user
  static bool isPrivacyLevelAllowed(
    PrivacyLevel requestedLevel,
    PrivacyLevel userLevel,
  ) {
    return requestedLevel.index >= userLevel.index;
  }

  /// Get the most restrictive privacy level from a list
  static PrivacyLevel getMostRestrictive(List<PrivacyLevel> levels) {
    if (levels.isEmpty) return PrivacyLevel.restricted;

    PrivacyLevel mostRestrictive = levels.first;
    for (final level in levels) {
      if (level.index < mostRestrictive.index) {
        mostRestrictive = level;
      }
    }

    return mostRestrictive;
  }

  /// Get the least restrictive privacy level from a list
  static PrivacyLevel getLeastRestrictive(List<PrivacyLevel> levels) {
    if (levels.isEmpty) return PrivacyLevel.public;

    PrivacyLevel leastRestrictive = levels.first;
    for (final level in levels) {
      if (level.index > leastRestrictive.index) {
        leastRestrictive = level;
      }
    }

    return leastRestrictive;
  }

  /// Check if a privacy level requires encryption
  static bool requiresEncryption(PrivacyLevel level) {
    return level.index >= PrivacyLevel.private.index;
  }

  /// Check if a privacy level requires audit logging
  static bool requiresAuditLogging(PrivacyLevel level) {
    return level.index >= PrivacyLevel.enterprise.index;
  }

  /// Check if a privacy level requires user consent
  static bool requiresUserConsent(PrivacyLevel level) {
    return level.index >= PrivacyLevel.private.index;
  }

  /// Get the minimum user level required to access a privacy level
  static PrivacyLevel getMinimumUserLevel(PrivacyLevel dataLevel) {
    switch (dataLevel) {
      case PrivacyLevel.public:
        return PrivacyLevel.public;
      case PrivacyLevel.private:
        return PrivacyLevel.private;
      case PrivacyLevel.enterprise:
        return PrivacyLevel.enterprise;
      case PrivacyLevel.restricted:
        return PrivacyLevel.restricted;
    }
  }

  /// Validate privacy level transitions
  static bool isValidPrivacyTransition(
    PrivacyLevel fromLevel,
    PrivacyLevel toLevel,
  ) {
    // Can only increase privacy (decrease index) or stay the same
    return toLevel.index <= fromLevel.index;
  }

  /// Get privacy level description
  static String getPrivacyLevelDescription(PrivacyLevel level) {
    switch (level) {
      case PrivacyLevel.public:
        return 'Public - Accessible to anyone';
      case PrivacyLevel.private:
        return 'Private - Requires user authentication';
      case PrivacyLevel.enterprise:
        return 'Enterprise - Requires enterprise authentication and audit logging';
      case PrivacyLevel.restricted:
        return 'Restricted - Requires special authorization and full audit trail';
    }
  }

  /// Get privacy level icon/emoji
  static String getPrivacyLevelIcon(PrivacyLevel level) {
    switch (level) {
      case PrivacyLevel.public:
        return '🌐';
      case PrivacyLevel.private:
        return '🔒';
      case PrivacyLevel.enterprise:
        return '🏢';
      case PrivacyLevel.restricted:
        return '🚫';
    }
  }

  /// Check if data can be shared with another user
  static bool canShareWithUser(
    PrivacyLevel dataLevel,
    PrivacyLevel userLevel,
    PrivacyLevel targetUserLevel,
  ) {
    // Check if user can access the data
    if (!isPrivacyLevelAllowed(dataLevel, userLevel)) {
      return false;
    }

    // Check if target user can access the data
    if (!isPrivacyLevelAllowed(dataLevel, targetUserLevel)) {
      return false;
    }

    return true;
  }

  /// Get required consent types for a privacy level
  static List<String> getRequiredConsentTypes(PrivacyLevel level) {
    switch (level) {
      case PrivacyLevel.public:
        return [];
      case PrivacyLevel.private:
        return ['data_access', 'data_processing'];
      case PrivacyLevel.enterprise:
        return [
          'data_access',
          'data_processing',
          'data_sharing',
          'audit_logging',
        ];
      case PrivacyLevel.restricted:
        return [
          'data_access',
          'data_processing',
          'data_sharing',
          'audit_logging',
          'special_authorization',
        ];
    }
  }

  /// Check if a privacy level allows data export
  static bool allowsDataExport(PrivacyLevel level) {
    return level.index >= PrivacyLevel.private.index;
  }

  /// Check if a privacy level allows data deletion
  static bool allowsDataDeletion(PrivacyLevel level) {
    return level.index >= PrivacyLevel.private.index;
  }

  /// Get data retention requirements for a privacy level
  static Map<String, dynamic> getDataRetentionRequirements(PrivacyLevel level) {
    switch (level) {
      case PrivacyLevel.public:
        return {
          'retention_period': 'indefinite',
          'backup_required': false,
          'archival_required': false,
        };
      case PrivacyLevel.private:
        return {
          'retention_period': '7_years',
          'backup_required': true,
          'archival_required': false,
        };
      case PrivacyLevel.enterprise:
        return {
          'retention_period': '10_years',
          'backup_required': true,
          'archival_required': true,
        };
      case PrivacyLevel.restricted:
        return {
          'retention_period': 'indefinite',
          'backup_required': true,
          'archival_required': true,
        };
    }
  }

  /// Check if privacy level requires data anonymization
  static bool requiresAnonymization(PrivacyLevel level) {
    return level.index >= PrivacyLevel.enterprise.index;
  }

  /// Get privacy compliance frameworks for a level
  static List<String> getComplianceFrameworks(PrivacyLevel level) {
    switch (level) {
      case PrivacyLevel.public:
        return [];
      case PrivacyLevel.private:
        return ['GDPR'];
      case PrivacyLevel.enterprise:
        return ['GDPR', 'CCPA', 'SOX'];
      case PrivacyLevel.restricted:
        return ['GDPR', 'CCPA', 'SOX', 'HIPAA', 'FERPA'];
    }
  }
}
