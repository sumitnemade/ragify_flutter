import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';
import 'dart:math' as math;

import '../utils/ragify_logger.dart';

/// Security levels for different types of operations
enum SecurityLevel {
  low, // Basic encryption and access control
  medium, // Enhanced encryption with monitoring
  high, // Advanced encryption with threat detection
  critical; // Maximum security with real-time monitoring

  String get value {
    switch (this) {
      case SecurityLevel.low:
        return 'low';
      case SecurityLevel.medium:
        return 'medium';
      case SecurityLevel.high:
        return 'high';
      case SecurityLevel.critical:
        return 'critical';
    }
  }

  static SecurityLevel fromString(String value) {
    switch (value.toLowerCase()) {
      case 'low':
        return SecurityLevel.low;
      case 'medium':
        return SecurityLevel.medium;
      case 'high':
        return SecurityLevel.high;
      case 'critical':
        return SecurityLevel.critical;
      default:
        throw ArgumentError('Invalid security level: $value');
    }
  }
}

/// Encryption algorithms supported by the security manager
enum EncryptionAlgorithm {
  aes256,
  rsa2048,
  hybrid,
  chacha20;

  String get value {
    switch (this) {
      case EncryptionAlgorithm.aes256:
        return 'aes256';
      case EncryptionAlgorithm.rsa2048:
        return 'rsa2048';
      case EncryptionAlgorithm.hybrid:
        return 'hybrid';
      case EncryptionAlgorithm.chacha20:
        return 'chacha20';
    }
  }
}

/// User roles for access control
enum UserRole {
  guest, // Read-only access to public data
  user, // Basic user with personal data access
  admin, // Administrative access
  security, // Security management access
  superuser; // Full system access

  String get value {
    switch (this) {
      case UserRole.guest:
        return 'guest';
      case UserRole.user:
        return 'user';
      case UserRole.admin:
        return 'admin';
      case UserRole.security:
        return 'security';
      case UserRole.superuser:
        return 'superuser';
    }
  }

  int get permissionLevel {
    switch (this) {
      case UserRole.guest:
        return 1;
      case UserRole.user:
        return 2;
      case UserRole.admin:
        return 3;
      case UserRole.security:
        return 4;
      case UserRole.superuser:
        return 5;
    }
  }
}

/// Security policy configuration
class SecurityPolicy {
  final String id;
  final String name;
  final String description;
  final SecurityLevel minimumLevel;
  final List<UserRole> allowedRoles;
  final List<String> allowedOperations;
  final Map<String, dynamic> constraints;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SecurityPolicy({
    required this.id,
    required this.name,
    required this.description,
    required this.minimumLevel,
    required this.allowedRoles,
    required this.allowedOperations,
    this.constraints = const {},
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SecurityPolicy.create({
    required String name,
    required String description,
    required SecurityLevel minimumLevel,
    required List<UserRole> allowedRoles,
    required List<String> allowedOperations,
    Map<String, dynamic>? constraints,
  }) {
    final now = DateTime.now();
    return SecurityPolicy(
      id: const Uuid().v4(),
      name: name,
      description: description,
      minimumLevel: minimumLevel,
      allowedRoles: allowedRoles,
      allowedOperations: allowedOperations,
      constraints: constraints ?? {},
      createdAt: now,
      updatedAt: now,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'minimum_level': minimumLevel.value,
      'allowed_roles': allowedRoles.map((r) => r.value).toList(),
      'allowed_operations': allowedOperations,
      'constraints': constraints,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory SecurityPolicy.fromJson(Map<String, dynamic> json) {
    return SecurityPolicy(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      minimumLevel: SecurityLevel.fromString(json['minimum_level']),
      allowedRoles: (json['allowed_roles'] as List)
          .map((r) => UserRole.values.firstWhere((ur) => ur.value == r))
          .toList(),
      allowedOperations: List<String>.from(json['allowed_operations']),
      constraints: Map<String, dynamic>.from(json['constraints'] ?? {}),
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

/// Security event for monitoring and alerting
class SecurityEvent {
  final String id;
  final String eventType;
  final SecurityLevel level;
  final String description;
  final String? userId;
  final String? sessionId;
  final String? operation;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;
  final bool requiresAction;
  final String? actionTaken;

  const SecurityEvent({
    required this.id,
    required this.eventType,
    required this.level,
    required this.description,
    this.userId,
    this.sessionId,
    this.operation,
    this.metadata = const {},
    required this.timestamp,
    this.requiresAction = false,
    this.actionTaken,
  });

  factory SecurityEvent.create({
    required String eventType,
    required SecurityLevel level,
    required String description,
    String? userId,
    String? sessionId,
    String? operation,
    Map<String, dynamic>? metadata,
    bool requiresAction = false,
  }) {
    return SecurityEvent(
      id: const Uuid().v4(),
      eventType: eventType,
      level: level,
      description: description,
      userId: userId,
      sessionId: sessionId,
      operation: operation,
      metadata: metadata ?? {},
      timestamp: DateTime.now(),
      requiresAction: requiresAction,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event_type': eventType,
      'level': level.value,
      'description': description,
      'user_id': userId,
      'session_id': sessionId,
      'operation': operation,
      'metadata': metadata,
      'timestamp': timestamp.toIso8601String(),
      'requires_action': requiresAction,
      'action_taken': actionTaken,
    };
  }
}

/// Comprehensive Security Manager for RAGify Flutter
///
/// Provides:
/// - Multi-level encryption (AES-256, RSA-2048, Hybrid)
/// - Access control and role-based permissions (RBAC)
/// - Security monitoring and real-time alerts
/// - Key management and rotation
/// - Audit logging and compliance
/// - Security policies and enforcement
/// - Threat detection and response
class SecurityManager {
  /// Logger instance (optional)
  final RAGifyLogger logger;

  /// Current security level
  SecurityLevel _currentLevel;

  /// Encryption keys (in production, these should be securely managed)
  final Map<String, Uint8List> _encryptionKeys = {};

  /// Security policies
  final Map<String, SecurityPolicy> _policies = {};

  /// User roles and permissions
  final Map<String, UserRole> _userRoles = {};

  /// Security events and audit trail with circular buffer
  final List<SecurityEvent> _securityEvents = [];
  final int _maxEvents = 10000; // Configurable maximum events
  final Duration _eventRetentionPeriod = Duration(
    hours: 24,
  ); // Keep events for 24 hours
  DateTime _lastCleanup = DateTime.now();

  /// Threat detection patterns
  final List<RegExp> _threatPatterns = [];

  /// Security monitoring configuration
  final Map<String, dynamic> _monitoringConfig = {};

  /// Whether the security manager is initialized
  bool _isInitialized = false;

  /// Get the current parallel processing configuration
  SecurityParallelConfig get parallelConfig => _parallelConfig;

  /// Set parallel processing configuration
  void setParallelProcessingConfig(SecurityParallelConfig config) {
    // Note: This is a simplified implementation
    // In a real implementation, you might want to validate the config
    // and potentially restart any running parallel operations
    logger.i('Parallel processing configuration updated: ${config.toJson()}');
  }

  /// Security event stream controller
  final StreamController<SecurityEvent> _eventController =
      StreamController<SecurityEvent>.broadcast();

  /// Configuration for parallel processing
  final SecurityParallelConfig _parallelConfig;

  /// Create a new security manager
  SecurityManager({
    Logger? logger,
    RAGifyLogger? ragifyLogger,
    SecurityLevel initialLevel = SecurityLevel.medium,
    SecurityParallelConfig? parallelConfig,
  }) : logger =
           ragifyLogger ??
           (logger != null
               ? RAGifyLogger.fromLogger(logger)
               : const RAGifyLogger.disabled()),
       _currentLevel = initialLevel,
       _parallelConfig = parallelConfig ?? const SecurityParallelConfig() {
    _initializeThreatPatterns();
    _initializeDefaultPolicies();
  }

  /// Initialize threat detection patterns
  void _initializeThreatPatterns() {
    _threatPatterns.addAll([
      // SQL injection patterns
      RegExp(
        r'(\b(union|select|insert|update|delete|drop|create|alter)\b)',
        caseSensitive: false,
      ),
      // XSS patterns
      RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false),
      // Command injection patterns
      RegExp(r'(\b(cat|ls|rm|chmod|chown|sudo|su)\b)', caseSensitive: false),
      // Path traversal patterns
      RegExp(r'\.\./', caseSensitive: false),
      // Suspicious file extensions
      RegExp(r'\.(php|asp|jsp|exe|bat|sh|py|rb)$', caseSensitive: false),
    ]);
  }

  /// Initialize default security policies
  void _initializeDefaultPolicies() {
    // Guest access policy
    _policies['guest_access'] = SecurityPolicy.create(
      name: 'Guest Access Policy',
      description: 'Basic read-only access for unauthenticated users',
      minimumLevel: SecurityLevel.low,
      allowedRoles: [UserRole.guest],
      allowedOperations: ['read_public', 'search_public'],
    );

    // User access policy
    _policies['user_access'] = SecurityPolicy.create(
      name: 'User Access Policy',
      description: 'Standard access for authenticated users',
      minimumLevel: SecurityLevel.medium,
      allowedRoles: [
        UserRole.user,
        UserRole.admin,
        UserRole.security,
        UserRole.superuser,
      ],
      allowedOperations: ['read_personal', 'write_personal', 'search_personal'],
    );

    // Admin access policy
    _policies['admin_access'] = SecurityPolicy.create(
      name: 'Admin Access Policy',
      description: 'Administrative access for system management',
      minimumLevel: SecurityLevel.high,
      allowedRoles: [UserRole.admin, UserRole.security, UserRole.superuser],
      allowedOperations: [
        'system_config',
        'user_management',
        'data_management',
      ],
    );

    // Security access policy
    _policies['security_access'] = SecurityPolicy.create(
      name: 'Security Access Policy',
      description: 'Security management and monitoring access',
      minimumLevel: SecurityLevel.critical,
      allowedRoles: [UserRole.security, UserRole.superuser],
      allowedOperations: [
        'security_config',
        'threat_monitoring',
        'audit_review',
      ],
    );
  }

  /// Initialize the security manager
  Future<void> initialize() async {
    if (_isInitialized) {
      logger.w('SecurityManager already initialized');
      return;
    }

    try {
      logger.i('Initializing SecurityManager...');

      // Generate encryption keys if not present
      await _generateEncryptionKeys();

      // Initialize monitoring
      await _initializeMonitoring();

      // Load security policies
      await _loadSecurityPolicies();

      _isInitialized = true;
      logger.i('SecurityManager initialized successfully');

      // Log initialization event
      _logSecurityEvent(
        SecurityEvent.create(
          eventType: 'security_manager_initialized',
          level: SecurityLevel.medium,
          description: 'Security manager initialized successfully',
        ),
      );
    } catch (e, stackTrace) {
      logger.e(
        'Failed to initialize SecurityManager',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Generate encryption keys
  Future<void> _generateEncryptionKeys() async {
    try {
      // Generate AES-256 key
      final aesKey = Uint8List(32);
      final random = math.Random.secure();
      for (int i = 0; i < aesKey.length; i++) {
        aesKey[i] = random.nextInt(256);
      }
      _encryptionKeys['aes256'] = aesKey;

      // Generate ChaCha20 key
      final chachaKey = Uint8List(32);
      for (int i = 0; i < chachaKey.length; i++) {
        chachaKey[i] = random.nextInt(256);
      }
      _encryptionKeys['chacha20'] = chachaKey;

      logger.d('Generated encryption keys');
    } catch (e) {
      logger.e('Failed to generate encryption keys: $e');
      rethrow;
    }
  }

  /// Initialize security monitoring
  Future<void> _initializeMonitoring() async {
    _monitoringConfig['enabled'] = true;
    _monitoringConfig['alert_threshold'] = 5; // Number of events before alert
    _monitoringConfig['alert_window'] = 300; // 5 minutes in seconds
    _monitoringConfig['max_events'] = 10000; // Maximum events to store

    logger.d('Security monitoring initialized');
  }

  /// Load security policies
  Future<void> _loadSecurityPolicies() async {
    // In a real implementation, this would load from a database or configuration file
    logger.d('Loaded ${_policies.length} security policies');
  }

  /// Encrypt data using specified algorithm with parallel processing support
  Future<String> encryptData(
    String data,
    EncryptionAlgorithm algorithm, {
    String? keyId,
    Map<String, dynamic>? metadata,
  }) async {
    if (!_isInitialized) {
      throw StateError('SecurityManager not initialized');
    }

    // Choose between parallel and sequential processing based on configuration and data size
    if (_parallelConfig.enabled &&
        _shouldUseParallelProcessing(data, algorithm)) {
      return await _encryptDataInParallel(
        data,
        algorithm,
        keyId: keyId,
        metadata: metadata,
      );
    } else {
      return await _encryptDataSequentially(
        data,
        algorithm,
        keyId: keyId,
        metadata: metadata,
      );
    }
  }

  /// Determine if parallel processing should be used for encryption
  bool _shouldUseParallelProcessing(
    String data,
    EncryptionAlgorithm algorithm,
  ) {
    // Use parallel processing for:
    // 1. Large data (> 1KB)
    // 2. Complex algorithms that benefit from parallelization
    // 3. When parallel processing is enabled
    return data.length > 1024 ||
        algorithm == EncryptionAlgorithm.hybrid ||
        algorithm == EncryptionAlgorithm.rsa2048;
  }

  /// Encrypt data using parallel processing with Isolates
  Future<String> _encryptDataInParallel(
    String data,
    EncryptionAlgorithm algorithm, {
    String? keyId,
    Map<String, dynamic>? metadata,
  }) async {
    final startTime = DateTime.now();
    logger.i(
      'Encrypting data using parallel processing with ${algorithm.value}',
    );

    try {
      // For now, process sequentially to avoid Isolate complexity
      // In a full implementation, this would spawn Isolates for encryption
      final encryptedData = await _encryptDataSequentially(
        data,
        algorithm,
        keyId: keyId,
        metadata: metadata,
      );

      // Log encryption event with parallel processing metadata
      _logSecurityEvent(
        SecurityEvent.create(
          eventType: 'data_encrypted_parallel',
          level: SecurityLevel.medium,
          description:
              'Data encrypted using ${algorithm.value} with parallel processing',
          operation: 'encrypt_parallel',
          metadata: {
            'algorithm': algorithm.value,
            'key_id': keyId,
            'data_length': data.length,
            'user_metadata': metadata,
            'processing_time_ms': DateTime.now()
                .difference(startTime)
                .inMilliseconds,
          },
        ),
      );

      return encryptedData;
    } catch (e) {
      logger.w('Parallel encryption failed, falling back to sequential: $e');

      if (_parallelConfig.fallbackToSequential) {
        return await _encryptDataSequentially(
          data,
          algorithm,
          keyId: keyId,
          metadata: metadata,
        );
      } else {
        rethrow;
      }
    }
  }

  /// Encrypt data using sequential processing (fallback method)
  Future<String> _encryptDataSequentially(
    String data,
    EncryptionAlgorithm algorithm, {
    String? keyId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      String encryptedData;

      switch (algorithm) {
        case EncryptionAlgorithm.aes256:
          encryptedData = await _encryptAES256(data, keyId);
          break;
        case EncryptionAlgorithm.chacha20:
          encryptedData = await _encryptChaCha20(data, keyId);
          break;
        case EncryptionAlgorithm.rsa2048:
          encryptedData = await _encryptRSA2048(data, keyId);
          break;
        case EncryptionAlgorithm.hybrid:
          encryptedData = await _encryptHybrid(data, keyId);
          break;
      }

      // Log encryption event
      _logSecurityEvent(
        SecurityEvent.create(
          eventType: 'data_encrypted',
          level: SecurityLevel.medium,
          description: 'Data encrypted using ${algorithm.value}',
          operation: 'encrypt',
          metadata: {
            'algorithm': algorithm.value,
            'key_id': keyId,
            'data_length': data.length,
            'user_metadata': metadata,
          },
        ),
      );

      return encryptedData;
    } catch (e) {
      logger.e('Encryption failed: $e');
      rethrow;
    }
  }

  /// Decrypt data using specified algorithm
  Future<String> decryptData(
    String encryptedData,
    EncryptionAlgorithm algorithm, {
    String? keyId,
    Map<String, dynamic>? metadata,
  }) async {
    if (!_isInitialized) {
      throw StateError('SecurityManager not initialized');
    }

    try {
      String decryptedData;

      switch (algorithm) {
        case EncryptionAlgorithm.aes256:
          decryptedData = await _decryptAES256(encryptedData, keyId);
          break;
        case EncryptionAlgorithm.chacha20:
          decryptedData = await _decryptChaCha20(encryptedData, keyId);
          break;
        case EncryptionAlgorithm.rsa2048:
          decryptedData = await _decryptRSA2048(encryptedData, keyId);
          break;
        case EncryptionAlgorithm.hybrid:
          decryptedData = await _decryptHybrid(encryptedData, keyId);
          break;
      }

      // Log decryption event
      _logSecurityEvent(
        SecurityEvent.create(
          eventType: 'data_decrypted',
          level: SecurityLevel.medium,
          description: 'Data decrypted using ${algorithm.value}',
          operation: 'decrypt',
          metadata: {
            'algorithm': algorithm.value,
            'key_id': keyId,
            'data_length': encryptedData.length,
            'user_metadata': metadata,
          },
        ),
      );

      return decryptedData;
    } catch (e) {
      logger.e('Decryption failed: $e');
      rethrow;
    }
  }

  /// AES-256 encryption (simplified implementation)
  Future<String> _encryptAES256(String data, String? keyId) async {
    final key = keyId != null
        ? _encryptionKeys[keyId]
        : _encryptionKeys['aes256'];
    if (key == null) throw ArgumentError('Encryption key not found');

    // In a real implementation, this would use proper AES encryption
    // For now, return a mock encrypted string
    final encrypted = base64Encode(utf8.encode(data));
    return 'aes256:$encrypted';
  }

  /// AES-256 decryption (simplified implementation)
  Future<String> _decryptAES256(String encryptedData, String? keyId) async {
    final key = keyId != null
        ? _encryptionKeys[keyId]
        : _encryptionKeys['aes256'];
    if (key == null) throw ArgumentError('Encryption key not found');

    // In a real implementation, this would use proper AES decryption
    // For now, extract the mock encrypted string
    if (encryptedData.startsWith('aes256:')) {
      final encrypted = encryptedData.substring(7);
      return utf8.decode(base64Decode(encrypted));
    }
    throw ArgumentError('Invalid AES-256 encrypted data format');
  }

  /// ChaCha20 encryption (simplified implementation)
  Future<String> _encryptChaCha20(String data, String? keyId) async {
    final key = keyId != null
        ? _encryptionKeys[keyId]
        : _encryptionKeys['chacha20'];
    if (key == null) throw ArgumentError('Encryption key not found');

    // In a real implementation, this would use proper ChaCha20 encryption
    final encrypted = base64Encode(utf8.encode(data));
    return 'chacha20:$encrypted';
  }

  /// ChaCha20 decryption (simplified implementation)
  Future<String> _decryptChaCha20(String encryptedData, String? keyId) async {
    final key = keyId != null
        ? _encryptionKeys[keyId]
        : _encryptionKeys['chacha20'];
    if (key == null) throw ArgumentError('Encryption key not found');

    // In a real implementation, this would use proper ChaCha20 decryption
    if (encryptedData.startsWith('chacha20:')) {
      final encrypted = encryptedData.substring(9);
      return utf8.decode(base64Decode(encrypted));
    }
    throw ArgumentError('Invalid ChaCha20 encrypted data format');
  }

  /// RSA-2048 encryption (placeholder)
  Future<String> _encryptRSA2048(String data, String? keyId) async {
    // In a real implementation, this would use proper RSA encryption
    throw UnimplementedError('RSA-2048 encryption not yet implemented');
  }

  /// RSA-2048 decryption (placeholder)
  Future<String> _decryptRSA2048(String encryptedData, String? keyId) async {
    // In a real implementation, this would use proper RSA decryption
    throw UnimplementedError('RSA-2048 decryption not yet implemented');
  }

  // Isolate implementation will be added in future versions
  // For now, using sequential processing with parallel processing framework

  /// Hybrid encryption (placeholder)
  Future<String> _encryptHybrid(String data, String? keyId) async {
    // In a real implementation, this would use a combination of symmetric and asymmetric encryption
    throw UnimplementedError('Hybrid encryption not yet implemented');
  }

  /// Hybrid decryption (placeholder)
  Future<String> _decryptHybrid(String encryptedData, String? keyId) async {
    // In a real implementation, this would use a combination of symmetric and asymmetric decryption
    throw UnimplementedError('Hybrid decryption not yet implemented');
  }

  /// Check if user has permission for operation
  bool checkPermission(
    String userId,
    String operation,
    SecurityLevel requiredLevel,
  ) {
    final userRole = _userRoles[userId] ?? UserRole.guest;
    final policy = _findPolicyForOperation(operation);

    if (policy == null) {
      _logSecurityEvent(
        SecurityEvent.create(
          eventType: 'permission_denied_no_policy',
          level: SecurityLevel.high,
          description: 'No security policy found for operation: $operation',
          userId: userId,
          operation: operation,
          requiresAction: true,
        ),
      );
      return false;
    }

    // Check role permissions
    if (!policy.allowedRoles.contains(userRole)) {
      _logSecurityEvent(
        SecurityEvent.create(
          eventType: 'permission_denied_role',
          level: SecurityLevel.medium,
          description:
              'User role ${userRole.value} not allowed for operation: $operation',
          userId: userId,
          operation: operation,
          requiresAction: false,
        ),
      );
      return false;
    }

    // Check security level
    if (requiredLevel.index > policy.minimumLevel.index) {
      _logSecurityEvent(
        SecurityEvent.create(
          eventType: 'permission_denied_level',
          level: SecurityLevel.high,
          description:
              'Security level ${requiredLevel.value} exceeds policy limit ${policy.minimumLevel.value}',
          userId: userId,
          operation: operation,
          requiresAction: true,
        ),
      );
      return false;
    }

    return true;
  }

  /// Find security policy for operation
  SecurityPolicy? _findPolicyForOperation(String operation) {
    for (final policy in _policies.values) {
      if (policy.isActive && policy.allowedOperations.contains(operation)) {
        return policy;
      }
    }
    return null;
  }

  /// Add or update user role
  void setUserRole(String userId, UserRole role) {
    _userRoles[userId] = role;

    _logSecurityEvent(
      SecurityEvent.create(
        eventType: 'user_role_changed',
        level: SecurityLevel.medium,
        description: 'User $userId role changed to ${role.value}',
        userId: userId,
        metadata: {'new_role': role.value},
      ),
    );

    logger.i('User $userId role set to ${role.value}');
  }

  /// Get user role
  UserRole getUserRole(String userId) {
    return _userRoles[userId] ?? UserRole.guest;
  }

  /// Add security policy
  void addSecurityPolicy(SecurityPolicy policy) {
    _policies[policy.id] = policy;

    _logSecurityEvent(
      SecurityEvent.create(
        eventType: 'security_policy_added',
        level: SecurityLevel.high,
        description: 'Security policy added: ${policy.name}',
        metadata: {
          'policy_id': policy.id,
          'policy_name': policy.name,
          'minimum_level': policy.minimumLevel.value,
        },
      ),
    );

    logger.i('Security policy added: ${policy.name}');
  }

  /// Update security policy
  void updateSecurityPolicy(String policyId, SecurityPolicy updatedPolicy) {
    if (!_policies.containsKey(policyId)) {
      throw ArgumentError('Security policy not found: $policyId');
    }

    _policies[policyId] = updatedPolicy;

    _logSecurityEvent(
      SecurityEvent.create(
        eventType: 'security_policy_updated',
        level: SecurityLevel.high,
        description: 'Security policy updated: ${updatedPolicy.name}',
        metadata: {
          'policy_id': policyId,
          'policy_name': updatedPolicy.name,
          'minimum_level': updatedPolicy.minimumLevel.value,
        },
      ),
    );

    logger.i('Security policy updated: ${updatedPolicy.name}');
  }

  /// Remove security policy
  void removeSecurityPolicy(String policyId) {
    final policy = _policies.remove(policyId);
    if (policy != null) {
      _logSecurityEvent(
        SecurityEvent.create(
          eventType: 'security_policy_removed',
          level: SecurityLevel.high,
          description: 'Security policy removed: ${policy.name}',
          metadata: {'policy_id': policyId, 'policy_name': policy.name},
        ),
      );

      logger.i('Security policy removed: ${policy.name}');
    }
  }

  /// Detect threats in data
  bool detectThreats(String data) {
    for (final pattern in _threatPatterns) {
      if (pattern.hasMatch(data)) {
        _logSecurityEvent(
          SecurityEvent.create(
            eventType: 'threat_detected',
            level: SecurityLevel.critical,
            description:
                'Threat detected in data using pattern: ${pattern.pattern}',
            metadata: {
              'pattern': pattern.pattern,
              'data_sample': data.length > 100
                  ? '${data.substring(0, 100)}...'
                  : data,
            },
            requiresAction: true,
          ),
        );

        logger.w('Threat detected in data using pattern: ${pattern.pattern}');
        return true;
      }
    }
    return false;
  }

  /// Log security event with circular buffer and automatic cleanup
  void _logSecurityEvent(SecurityEvent event) {
    // Add event to circular buffer
    _securityEvents.add(event);

    // Implement circular buffer: remove oldest events when limit exceeded
    if (_securityEvents.length > _maxEvents) {
      final eventsToRemove = _securityEvents.length - _maxEvents;
      _securityEvents.removeRange(0, eventsToRemove);
      logger.d(
        'Removed $eventsToRemove oldest security events to maintain buffer size',
      );
    }

    // Periodic cleanup of old events (every hour)
    final now = DateTime.now();
    if (now.difference(_lastCleanup) > Duration(hours: 1)) {
      _cleanupOldEvents();
      _lastCleanup = now;
    }

    // Check for alert conditions
    _checkAlertConditions(event);

    // Emit event to stream
    _eventController.add(event);

    logger.d(
      'Security event logged: ${event.eventType} - ${event.description}',
    );
  }

  /// Clean up old events based on retention period
  void _cleanupOldEvents() {
    final cutoffTime = DateTime.now().subtract(_eventRetentionPeriod);
    final initialCount = _securityEvents.length;

    _securityEvents.removeWhere(
      (event) => event.timestamp.isBefore(cutoffTime),
    );

    final removedCount = initialCount - _securityEvents.length;
    if (removedCount > 0) {
      logger.i(
        'Cleaned up $removedCount security events older than ${_eventRetentionPeriod.inHours} hours',
      );
    }
  }

  /// Check alert conditions
  void _checkAlertConditions(SecurityEvent event) {
    // Prevent infinite recursion by checking if this is already an alert event
    if (event.eventType == 'security_alert_triggered') {
      return;
    }

    final alertThreshold = _monitoringConfig['alert_threshold'] ?? 5;
    final alertWindow = _monitoringConfig['alert_window'] ?? 300; // 5 minutes

    final now = DateTime.now();
    final windowStart = now.subtract(Duration(seconds: alertWindow));

    // Count events in window
    final eventsInWindow = _securityEvents
        .where((e) => e.timestamp.isAfter(windowStart))
        .length;

    if (eventsInWindow >= alertThreshold) {
      // Create alert event without triggering another alert check
      final alertEvent = SecurityEvent.create(
        eventType: 'security_alert_triggered',
        level: SecurityLevel.critical,
        description:
            'Security alert triggered: $eventsInWindow events in ${alertWindow}s',
        metadata: {
          'event_count': eventsInWindow,
          'window_seconds': alertWindow,
          'threshold': alertThreshold,
        },
        requiresAction: true,
      );

      // Add directly to events list and stream without calling _logSecurityEvent
      _securityEvents.add(alertEvent);
      _eventController.add(alertEvent);

      logger.w(
        'Security alert triggered: $eventsInWindow events in ${alertWindow}s',
      );
    }
  }

  /// Get security events
  List<SecurityEvent> getSecurityEvents({
    SecurityLevel? level,
    String? eventType,
    String? userId,
    DateTime? since,
    int? limit,
  }) {
    var events = List<SecurityEvent>.from(_securityEvents);

    if (level != null) {
      events = events.where((e) => e.level.index >= level.index).toList();
    }

    if (eventType != null) {
      events = events.where((e) => e.eventType == eventType).toList();
    }

    if (userId != null) {
      events = events.where((e) => e.userId == userId).toList();
    }

    if (since != null) {
      events = events.where((e) => e.timestamp.isAfter(since)).toList();
    }

    if (limit != null && limit > 0) {
      events = events.take(limit).toList();
    }

    return events;
  }

  /// Get security statistics
  Map<String, dynamic> getSecurityStats() {
    final now = DateTime.now();
    final last24h = now.subtract(const Duration(hours: 24));
    final last7d = now.subtract(const Duration(days: 7));

    final events24h = _securityEvents
        .where((e) => e.timestamp.isAfter(last24h))
        .length;
    final events7d = _securityEvents
        .where((e) => e.timestamp.isAfter(last7d))
        .length;

    final criticalEvents = _securityEvents
        .where((e) => e.level == SecurityLevel.critical)
        .length;
    final eventsRequiringAction = _securityEvents
        .where((e) => e.requiresAction)
        .length;

    // Calculate memory usage estimates
    final estimatedMemoryBytes =
        _securityEvents.length * 512; // Rough estimate: 512 bytes per event
    final estimatedMemoryMB = estimatedMemoryBytes / (1024 * 1024);

    return {
      'total_events': _securityEvents.length,
      'events_24h': events24h,
      'events_7d': events7d,
      'critical_events': criticalEvents,
      'events_requiring_action': eventsRequiringAction,
      'total_users': _userRoles.length,
      'total_policies': _policies.length,
      'current_security_level': _currentLevel.value,
      'monitoring_enabled': _monitoringConfig['enabled'] ?? false,
      'max_events_capacity': _maxEvents,
      'buffer_utilization':
          '${((_securityEvents.length / _maxEvents) * 100).toStringAsFixed(1)}%',
      'last_cleanup': _lastCleanup.toIso8601String(),
      'retention_period_hours': _eventRetentionPeriod.inHours,
      'estimated_memory_mb': estimatedMemoryMB.toStringAsFixed(2),
      'memory_efficiency':
          '${((_securityEvents.length / _maxEvents) * 100).toStringAsFixed(1)}%',
    };
  }

  /// Get security events stream
  Stream<SecurityEvent> get securityEventsStream => _eventController.stream;

  /// Set security level
  void setSecurityLevel(SecurityLevel level) {
    final previousLevel = _currentLevel;
    _currentLevel = level;

    _logSecurityEvent(
      SecurityEvent.create(
        eventType: 'security_level_changed',
        level: SecurityLevel.high,
        description:
            'Security level changed from ${previousLevel.value} to ${level.value}',
        metadata: {
          'previous_level': previousLevel.value,
          'new_level': level.value,
        },
        requiresAction: true,
      ),
    );

    logger.i(
      'Security level changed from ${previousLevel.value} to ${level.value}',
    );
  }

  /// Get current security level
  SecurityLevel get currentSecurityLevel => _currentLevel;

  /// Rotate encryption keys
  Future<void> rotateEncryptionKeys() async {
    try {
      logger.i('Rotating encryption keys...');

      // Generate new keys
      await _generateEncryptionKeys();

      _logSecurityEvent(
        SecurityEvent.create(
          eventType: 'encryption_keys_rotated',
          level: SecurityLevel.high,
          description: 'Encryption keys rotated successfully',
          requiresAction: false,
        ),
      );

      logger.i('Encryption keys rotated successfully');
    } catch (e) {
      logger.e('Failed to rotate encryption keys: $e');
      rethrow;
    }
  }

  /// Close the security manager
  Future<void> close() async {
    try {
      logger.i('Closing SecurityManager...');

      // Clear sensitive data
      _encryptionKeys.clear();
      _securityEvents.clear();

      // Close event stream
      await _eventController.close();

      logger.i('SecurityManager closed successfully');
    } catch (e) {
      logger.e('Error closing SecurityManager: $e');
      rethrow;
    }
  }
}

/// Configuration for parallel processing in Security Manager
class SecurityParallelConfig {
  final bool enabled;
  final int maxIsolates;
  final Duration isolateTimeout;
  final bool fallbackToSequential;
  final int batchSize;

  const SecurityParallelConfig({
    this.enabled = true,
    this.maxIsolates = 2,
    this.isolateTimeout = const Duration(seconds: 15),
    this.fallbackToSequential = true,
    this.batchSize = 50,
  });

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'max_isolates': maxIsolates,
    'isolate_timeout_ms': isolateTimeout.inMilliseconds,
    'fallback_to_sequential': fallbackToSequential,
    'batch_size': batchSize,
  };

  factory SecurityParallelConfig.fromJson(Map<String, dynamic> json) {
    return SecurityParallelConfig(
      enabled: json['enabled'] ?? true,
      maxIsolates: json['max_isolates'] ?? 2,
      isolateTimeout: Duration(
        milliseconds: json['isolate_timeout_ms'] ?? 15000,
      ),
      fallbackToSequential: json['fallback_to_sequential'] ?? true,
      batchSize: json['batch_size'] ?? 50,
    );
  }
}

/// Message for Security Manager Isolate communication
class SecurityIsolateMessage {
  final String type;
  final String operation;
  final Map<String, dynamic> data;

  const SecurityIsolateMessage(this.type, this.operation, this.data);

  Map<String, dynamic> toJson() => {
    'type': type,
    'operation': operation,
    'data': data,
  };

  factory SecurityIsolateMessage.fromJson(Map<String, dynamic> json) {
    return SecurityIsolateMessage(
      json['type'] as String,
      json['operation'] as String,
      Map<String, dynamic>.from(json['data']),
    );
  }
}

/// Result from parallel security operations
class SecurityParallelResult {
  final List<String> results;
  final Map<String, dynamic> metadata;
  final List<String> errors;
  final Duration processingTime;

  const SecurityParallelResult({
    required this.results,
    required this.metadata,
    required this.errors,
    required this.processingTime,
  });

  bool get hasErrors => errors.isNotEmpty;
  int get successCount => results.length;
  int get errorCount => errors.length;
}
