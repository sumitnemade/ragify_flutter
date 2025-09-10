import '../platform/cross_platform_service_locator.dart';
import '../platform/platform_detector.dart';

import '../cache/cache_manager.dart';
import '../privacy/privacy_manager.dart';
import '../security/security_manager.dart';
import '../sources/database_source.dart';
import '../engines/intelligent_context_fusion_engine.dart';
import '../engines/context_storage_engine.dart';
import '../engines/context_updates_engine.dart';
import '../storage/vector_database.dart';
import '../models/context_source.dart';
import '../utils/ragify_logger.dart';

/// Main RAGify service locator that integrates cross-platform capabilities
class RAGifyServiceLocator {
  static RAGifyServiceLocator? _instance;

  RAGifyServiceLocator._();

  /// Logger instance
  final RAGifyLogger logger = const RAGifyLogger.disabled();

  /// Get the singleton instance
  static RAGifyServiceLocator get instance {
    _instance ??= RAGifyServiceLocator._();
    return _instance!;
  }

  /// Cross-platform service locator
  CrossPlatformServiceLocator get platform =>
      CrossPlatformServiceLocator.instance;

  /// Get the current platform name
  String get platformName => platform.platformName;

  /// Check if a specific feature is supported on the current platform
  bool supportsFeature(PlatformFeature feature) {
    return platform.supportsFeature(feature);
  }

  /// Get platform capabilities summary
  Map<String, dynamic> getPlatformCapabilities() {
    return platform.getPlatformCapabilities();
  }

  // Core RAGify Services with Platform Awareness

  /// Cache Manager (platform-optimized)
  CacheManager get cacheManager {
    // Use platform-appropriate storage for caching
    return _createPlatformAwareCacheManager();
  }

  /// Privacy Manager (platform-optimized)
  PrivacyManager get privacyManager {
    return _createPlatformAwarePrivacyManager();
  }

  /// Security Manager (platform-optimized)
  SecurityManager get securityManager {
    return _createPlatformAwareSecurityManager();
  }

  /// Database Source (platform-optimized)
  DatabaseSource get databaseSource {
    return _createPlatformAwareDatabaseSource();
  }

  /// Intelligent Context Fusion Engine (platform-optimized)
  IntelligentContextFusionEngine get fusionEngine {
    return _createPlatformAwareFusionEngine();
  }

  /// Context Storage Engine (platform-optimized)
  ContextStorageEngine get storageEngine {
    return _createPlatformAwareStorageEngine();
  }

  /// Context Updates Engine (platform-optimized)
  ContextUpdatesEngine get updatesEngine {
    return _createPlatformAwareUpdatesEngine();
  }

  /// Vector Database (platform-optimized)
  VectorDatabase get vectorDatabase {
    return _createPlatformAwareVectorDatabase();
  }

  // Platform-Aware Service Creation

  CacheManager _createPlatformAwareCacheManager() {
    // Create cache manager with platform-appropriate configuration
    final cacheManager = CacheManager();

    // Note: CacheManager doesn't have a configure method, so we'll use the default
    // In a real implementation, you might want to add configuration methods
    return cacheManager;
  }

  PrivacyManager _createPlatformAwarePrivacyManager() {
    final privacyManager = PrivacyManager();

    // Note: PrivacyManager doesn't have a configure method, so we'll use the default
    // In a real implementation, you might want to add configuration methods
    return privacyManager;
  }

  SecurityManager _createPlatformAwareSecurityManager() {
    final securityManager = SecurityManager();

    // Note: SecurityManager doesn't have a configure method, so we'll use the default
    // In a real implementation, you might want to add configuration methods
    return securityManager;
  }

  DatabaseSource _createPlatformAwareDatabaseSource() {
    // Create database source with platform-appropriate configuration
    // For now, we'll use a default configuration
    final databaseConfig = DatabaseConfig(
      host: 'localhost',
      port: 5432,
      database: 'ragify_db',
      username: 'ragify_user',
      password: 'ragify_password',
    );

    final databaseSource = DatabaseSource(
      name: 'platform_database',
      sourceType: SourceType.database,
      databaseConfig: databaseConfig,
      databaseType: 'postgresql',
      cacheManager: cacheManager,
    );

    // Note: DatabaseSource doesn't have platform-specific configure methods yet
    // In a real implementation, you might want to add these methods
    return databaseSource;
  }

  IntelligentContextFusionEngine _createPlatformAwareFusionEngine() {
    final fusionEngine = IntelligentContextFusionEngine();

    // Configure ML capabilities based on platform
    if (PlatformDetector.supportsFeature(PlatformFeature.aiModelApis)) {
      // All platforms: AI Model API support
      // Note: FusionEngine doesn't have a configure method yet
      // In a real implementation, you might want to add this
    } else if (PlatformDetector.supportsFeature(
      PlatformFeature.vectorOperations,
    )) {
      // Fallback: Local vector operations
      // Note: FusionEngine doesn't have a configure method yet
      // In a real implementation, you might want to add this
    } else {
      // Fallback: No ML support
      // Note: FusionEngine doesn't have a configure method yet
      // In a real implementation, you might want to add this
    }

    return fusionEngine;
  }

  ContextStorageEngine _createPlatformAwareStorageEngine() {
    final storageEngine = ContextStorageEngine();

    // Note: ContextStorageEngine doesn't have a configure method yet
    // In a real implementation, you might want to add platform-specific configuration
    return storageEngine;
  }

  ContextUpdatesEngine _createPlatformAwareUpdatesEngine() {
    final updatesEngine = ContextUpdatesEngine();

    // Note: ContextUpdatesEngine doesn't have a configure method yet
    // In a real implementation, you might want to add platform-specific configuration
    return updatesEngine;
  }

  VectorDatabase _createPlatformAwareVectorDatabase() {
    // Create vector database with platform-appropriate configuration
    final vectorDbUrl = PlatformDetector.isWeb
        ? 'memory://vector_db' // Web: Use memory storage
        : 'faiss://vector_db'; // Mobile/Desktop: Use FAISS

    final vectorDatabase = VectorDatabase(vectorDbUrl: vectorDbUrl);

    // Note: VectorDatabase doesn't have a configure method yet
    // In a real implementation, you might want to add platform-specific configuration
    return vectorDatabase;
  }

  /// Initialize all RAGify services with platform awareness
  Future<void> initialize() async {
    try {
      logger.i('🚀 Initializing RAGify with Cross-Platform Support');
      logger.i('Platform: $platformName');

      // Initialize cross-platform services first
      await platform.initialize();

      // Initialize core RAGify services that have initialize methods
      // Note: Most services are initialized in their constructors
      await vectorDatabase.initialize();

      logger.i('✅ RAGify initialized successfully on $platformName');

      // Log platform capabilities
      final capabilities = getPlatformCapabilities();
      logger.i('Platform Capabilities: ${capabilities['features']}');
    } catch (e) {
      logger.e('❌ Failed to initialize RAGify: $e');
      rethrow;
    }
  }

  /// Close all services
  Future<void> close() async {
    try {
      // Close services that have close methods
      await vectorDatabase.close();
      await platform.close();

      logger.i('✅ RAGify services closed successfully');
    } catch (e) {
      logger.e('❌ Failed to close RAGify services: $e');
    }
  }

  /// Reset all services (useful for testing)
  void reset() {
    platform.reset();
    _instance = null;
  }

  /// Get service health status
  Map<String, dynamic> getServiceHealth() {
    return {
      'platform': platformName,
      'services': {
        'cache': cacheManager.getStats().toJson(),
        'privacy': 'PrivacyManager (no status method)',
        'security': 'SecurityManager (no status method)',
        'database': databaseSource.getStats(),
        'fusion': 'IntelligentContextFusionEngine (no status method)',
        'storage': 'ContextStorageEngine (no status method)',
        'updates': 'ContextUpdatesEngine (no status method)',
        'vector': vectorDatabase.getStats(),
      },
      'platformCapabilities': getPlatformCapabilities(),
    };
  }
}
