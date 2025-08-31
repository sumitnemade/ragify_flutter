import 'package:flutter_test/flutter_test.dart';
import 'package:ragify_flutter/src/security/security_manager.dart';

void main() {
  group('SecurityManager Tests', () {
    late SecurityManager securityManager;

    setUp(() {
      securityManager = SecurityManager();
    });

    tearDown(() {
      securityManager.close();
    });

    group('Initialization', () {
      test('should initialize successfully', () async {
        await securityManager.initialize();
        expect(securityManager.currentSecurityLevel, SecurityLevel.medium);
      });

      test('should not initialize twice', () async {
        await securityManager.initialize();
        await securityManager.initialize(); // Should not throw
      });
    });

    group('Encryption', () {
      setUp(() async {
        await securityManager.initialize();
      });

      test('should encrypt and decrypt AES-256 data', () async {
        const testData = 'Hello, World!';

        final encrypted = await securityManager.encryptData(
          testData,
          EncryptionAlgorithm.aes256,
        );

        expect(encrypted, isNot(equals(testData)));
        expect(encrypted, startsWith('aes256:'));

        final decrypted = await securityManager.decryptData(
          encrypted,
          EncryptionAlgorithm.aes256,
        );

        expect(decrypted, equals(testData));
      });

      test('should encrypt and decrypt ChaCha20 data', () async {
        const testData = 'Test data for ChaCha20';

        final encrypted = await securityManager.encryptData(
          testData,
          EncryptionAlgorithm.chacha20,
        );

        expect(encrypted, isNot(equals(testData)));
        expect(encrypted, startsWith('chacha20:'));

        final decrypted = await securityManager.decryptData(
          encrypted,
          EncryptionAlgorithm.chacha20,
        );

        expect(decrypted, equals(testData));
      });

      test('should throw error for unimplemented algorithms', () async {
        const testData = 'Test data';

        expect(
          () => securityManager.encryptData(
            testData,
            EncryptionAlgorithm.rsa2048,
          ),
          throwsA(isA<UnimplementedError>()),
        );

        expect(
          () =>
              securityManager.encryptData(testData, EncryptionAlgorithm.hybrid),
          throwsA(isA<UnimplementedError>()),
        );
      });
    });

    group('Encryption - Not Initialized', () {
      test('should throw error when not initialized', () async {
        const testData = 'Test data';

        expect(
          () =>
              securityManager.encryptData(testData, EncryptionAlgorithm.aes256),
          throwsA(isA<StateError>()),
        );
      });
    });

    group('User Roles and Permissions', () {
      setUp(() async {
        await securityManager.initialize();
      });

      test('should set and get user roles', () {
        const userId = 'user123';
        const role = UserRole.admin;

        securityManager.setUserRole(userId, role);
        expect(securityManager.getUserRole(userId), equals(role));
      });

      test('should return guest role for unknown users', () {
        const userId = 'unknown_user';
        expect(securityManager.getUserRole(userId), equals(UserRole.guest));
      });

      test('should check permissions correctly', () {
        const userId = 'user123';
        securityManager.setUserRole(userId, UserRole.user);

        // User should have permission for user operations
        expect(
          securityManager.checkPermission(
            userId,
            'read_personal',
            SecurityLevel.medium,
          ),
          isTrue,
        );

        // User should not have permission for admin operations
        expect(
          securityManager.checkPermission(
            userId,
            'system_config',
            SecurityLevel.high,
          ),
          isFalse,
        );
      });

      test('should check security levels correctly', () {
        const userId = 'admin123';
        securityManager.setUserRole(userId, UserRole.admin);

        // Admin should have permission for medium level operations
        expect(
          securityManager.checkPermission(
            userId,
            'read_personal',
            SecurityLevel.medium,
          ),
          isTrue,
        );

        // Admin should have permission for high level operations
        expect(
          securityManager.checkPermission(
            userId,
            'system_config',
            SecurityLevel.high,
          ),
          isTrue,
        );

        // Admin should not have permission for critical level operations
        expect(
          securityManager.checkPermission(
            userId,
            'security_config',
            SecurityLevel.critical,
          ),
          isFalse,
        );
      });
    });

    group('Security Policies', () {
      setUp(() async {
        await securityManager.initialize();
      });

      test('should add security policy', () {
        final policy = SecurityPolicy.create(
          name: 'Test Policy',
          description: 'Test security policy',
          minimumLevel: SecurityLevel.high,
          allowedRoles: [UserRole.admin, UserRole.security],
          allowedOperations: ['test_operation'],
        );

        securityManager.addSecurityPolicy(policy);

        // Policy should be accessible through permission checking
        securityManager.setUserRole('admin123', UserRole.admin);
        expect(
          securityManager.checkPermission(
            'admin123',
            'test_operation',
            SecurityLevel.high,
          ),
          isTrue,
        );
      });

      test('should update security policy', () {
        final policy = SecurityPolicy.create(
          name: 'Test Policy',
          description: 'Test security policy',
          minimumLevel: SecurityLevel.medium,
          allowedRoles: [UserRole.user],
          allowedOperations: ['test_operation'],
        );

        securityManager.addSecurityPolicy(policy);

        // Update policy to require higher security level
        final updatedPolicy = SecurityPolicy.create(
          name: 'Updated Test Policy',
          description: 'Updated test security policy',
          minimumLevel: SecurityLevel.high,
          allowedRoles: [UserRole.admin],
          allowedOperations: ['test_operation'],
        );

        securityManager.updateSecurityPolicy(policy.id, updatedPolicy);

        // User should no longer have permission
        securityManager.setUserRole('user123', UserRole.user);
        expect(
          securityManager.checkPermission(
            'user123',
            'test_operation',
            SecurityLevel.medium,
          ),
          isFalse,
        );
      });

      test('should remove security policy', () {
        final policy = SecurityPolicy.create(
          name: 'Test Policy',
          description: 'Test security policy',
          minimumLevel: SecurityLevel.medium,
          allowedRoles: [UserRole.user],
          allowedOperations: ['test_operation'],
        );

        securityManager.addSecurityPolicy(policy);
        securityManager.setUserRole('user123', UserRole.user);

        // User should have permission initially
        expect(
          securityManager.checkPermission(
            'user123',
            'test_operation',
            SecurityLevel.medium,
          ),
          isTrue,
        );

        // Remove policy
        securityManager.removeSecurityPolicy(policy.id);

        // User should no longer have permission
        expect(
          securityManager.checkPermission(
            'user123',
            'test_operation',
            SecurityLevel.medium,
          ),
          isFalse,
        );
      });
    });

    group('Threat Detection', () {
      setUp(() async {
        await securityManager.initialize();
      });

      test('should detect SQL injection threats', () {
        const maliciousData =
            'SELECT * FROM users WHERE id = 1 UNION SELECT password FROM users';
        expect(securityManager.detectThreats(maliciousData), isTrue);
      });

      test('should detect XSS threats', () {
        const maliciousData = '<script>alert("XSS")</script>';
        expect(securityManager.detectThreats(maliciousData), isTrue);
      });

      test('should detect command injection threats', () {
        const maliciousData = 'cat /etc/passwd';
        expect(securityManager.detectThreats(maliciousData), isTrue);
      });

      test('should detect path traversal threats', () {
        const maliciousData = '../../../etc/passwd';
        expect(securityManager.detectThreats(maliciousData), isTrue);
      });

      test('should detect suspicious file extensions', () {
        const maliciousData = 'file.php';
        expect(securityManager.detectThreats(maliciousData), isTrue);
      });

      test('should not detect threats in safe data', () {
        const safeData = 'This is safe data with no threats';
        expect(securityManager.detectThreats(safeData), isFalse);
      });
    });

    group('Security Events and Monitoring', () {
      setUp(() async {
        await securityManager.initialize();
      });

      test('should log security events', () {
        final initialEventCount = securityManager.getSecurityEvents().length;

        // Trigger an event by setting a user role
        securityManager.setUserRole('user123', UserRole.admin);

        final events = securityManager.getSecurityEvents();
        expect(events.length, greaterThan(initialEventCount));

        // Should have a user role changed event
        final roleChangeEvent = events.firstWhere(
          (e) => e.eventType == 'user_role_changed',
        );
        expect(roleChangeEvent.description, contains('user123'));
        expect(roleChangeEvent.description, contains('admin'));
      });

      test('should filter security events by level', () {
        // Trigger some events
        securityManager.setUserRole('user123', UserRole.admin);
        securityManager.setUserRole('admin123', UserRole.security);

        final highLevelEvents = securityManager.getSecurityEvents(
          level: SecurityLevel.high,
        );
        expect(
          highLevelEvents.every(
            (e) => e.level.index >= SecurityLevel.high.index,
          ),
          isTrue,
        );
      });

      test('should filter security events by type', () {
        // Trigger some events
        securityManager.setUserRole('user123', UserRole.admin);

        final roleChangeEvents = securityManager.getSecurityEvents(
          eventType: 'user_role_changed',
        );
        expect(
          roleChangeEvents.every((e) => e.eventType == 'user_role_changed'),
          isTrue,
        );
      });

      test('should filter security events by user', () {
        const userId = 'user123';
        securityManager.setUserRole(userId, UserRole.admin);

        final userEvents = securityManager.getSecurityEvents(userId: userId);
        expect(userEvents.every((e) => e.userId == userId), isTrue);
      });

      test('should provide security statistics', () {
        // Trigger some events
        securityManager.setUserRole('user123', UserRole.admin);
        securityManager.setUserRole('admin123', UserRole.security);

        final stats = securityManager.getSecurityStats();

        expect(stats['total_events'], greaterThan(0));
        expect(stats['total_users'], equals(2));
        expect(stats['total_policies'], greaterThan(0));
        expect(stats['current_security_level'], equals('medium'));
        expect(stats['monitoring_enabled'], isTrue);
      });
    });

    group('Security Level Management', () {
      setUp(() async {
        await securityManager.initialize();
      });

      test('should set and get security level', () {
        expect(
          securityManager.currentSecurityLevel,
          equals(SecurityLevel.medium),
        );

        securityManager.setSecurityLevel(SecurityLevel.high);
        expect(
          securityManager.currentSecurityLevel,
          equals(SecurityLevel.high),
        );

        securityManager.setSecurityLevel(SecurityLevel.critical);
        expect(
          securityManager.currentSecurityLevel,
          equals(SecurityLevel.critical),
        );
      });

      test('should log security level changes', () {
        final initialEventCount = securityManager.getSecurityEvents().length;

        securityManager.setSecurityLevel(SecurityLevel.high);

        final events = securityManager.getSecurityEvents();
        expect(events.length, greaterThan(initialEventCount));

        final levelChangeEvent = events.firstWhere(
          (e) => e.eventType == 'security_level_changed',
        );
        expect(levelChangeEvent.description, contains('medium'));
        expect(levelChangeEvent.description, contains('high'));
      });
    });

    group('Key Management', () {
      setUp(() async {
        await securityManager.initialize();
      });

      test('should rotate encryption keys', () async {
        const testData = 'Test data for key rotation';

        // Encrypt with current keys
        final encrypted1 = await securityManager.encryptData(
          testData,
          EncryptionAlgorithm.aes256,
        );

        // Rotate keys
        await securityManager.rotateEncryptionKeys();

        // Encrypt with new keys
        final encrypted2 = await securityManager.encryptData(
          testData,
          EncryptionAlgorithm.aes256,
        );

        // Both should decrypt correctly
        final decrypted1 = await securityManager.decryptData(
          encrypted1,
          EncryptionAlgorithm.aes256,
        );
        final decrypted2 = await securityManager.decryptData(
          encrypted2,
          EncryptionAlgorithm.aes256,
        );

        expect(decrypted1, equals(testData));
        expect(decrypted2, equals(testData));
      });
    });

    group('Stream and Real-time Monitoring', () {
      setUp(() async {
        await securityManager.initialize();
      });

      test('should emit security events to stream', () async {
        final events = <SecurityEvent>[];
        final subscription = securityManager.securityEventsStream.listen(
          events.add,
        );

        // Trigger an event
        securityManager.setUserRole('user123', UserRole.admin);

        // Wait for event to be processed
        await Future.delayed(const Duration(milliseconds: 100));

        expect(events.length, greaterThan(0));
        expect(events.any((e) => e.eventType == 'user_role_changed'), isTrue);

        subscription.cancel();
      });
    });
  });
}
