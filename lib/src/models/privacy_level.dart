import 'package:json_annotation/json_annotation.dart';

/// Privacy levels for context storage and operations
@JsonEnum()
enum PrivacyLevel {
  /// Public data - no restrictions
  public,

  /// Private data - user-specific restrictions
  private,

  /// Enterprise data - organization-level restrictions
  enterprise,

  /// Restricted data - highest security level
  restricted;

  /// Convert to string representation
  String get value {
    switch (this) {
      case PrivacyLevel.public:
        return 'public';
      case PrivacyLevel.private:
        return 'private';
      case PrivacyLevel.enterprise:
        return 'enterprise';
      case PrivacyLevel.restricted:
        return 'restricted';
    }
  }

  /// Create from string representation
  static PrivacyLevel fromString(String value) {
    switch (value.toLowerCase()) {
      case 'public':
        return PrivacyLevel.public;
      case 'private':
        return PrivacyLevel.private;
      case 'enterprise':
        return PrivacyLevel.enterprise;
      case 'restricted':
        return PrivacyLevel.restricted;
      default:
        throw ArgumentError('Invalid privacy level: $value');
    }
  }
}
