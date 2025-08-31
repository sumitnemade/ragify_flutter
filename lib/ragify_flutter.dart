// Intelligent Context Orchestration Framework for Flutter
//
// A framework for managing context from multiple data sources with conflict resolution,
// built specifically for LLM-powered Flutter applications.
//
// This file exports the complete RAGify Flutter API for easy integration.

// ============================================================================
// MAIN RAGIFY CLASS - Start here for most use cases
// ============================================================================
export 'src/ragify.dart';

// ============================================================================
// CORE CONFIGURATION AND ORCHESTRATION
// ============================================================================
export 'src/core/ragify_config.dart';
export 'src/core/context_orchestrator.dart';

// ============================================================================
// DATA MODELS - Core data structures used throughout the framework
// ============================================================================
export 'src/models/context_chunk.dart';
export 'src/models/context_request.dart';
export 'src/models/context_response.dart';
export 'src/models/context_source.dart';
export 'src/models/relevance_score.dart';
export 'src/models/privacy_level.dart';

// ============================================================================
// ENUMS - Constants and types used throughout the framework
// ============================================================================
// Source types and status
export 'src/models/context_source.dart' show SourceType;
export 'src/models/privacy_level.dart' show PrivacyLevel;
export 'src/sources/base_data_source.dart' show SourceStatus;

// Security enums
export 'src/security/security_manager.dart'
    show SecurityLevel, EncryptionAlgorithm, UserRole;

// Update types
export 'src/engines/context_updates_engine.dart' show UpdateType;

// ============================================================================
// ABSTRACT CLASSES AND INTERFACES - For extending and implementing
// ============================================================================
export 'src/sources/base_data_source.dart';
export 'src/sources/realtime_source.dart' show RealtimeConnection;

// ============================================================================
// DATA SOURCES - Connect to various data providers
// ============================================================================
export 'src/sources/document_source.dart';
export 'src/sources/api_source.dart';
export 'src/sources/database_source.dart';
export 'src/sources/realtime_source.dart';

// Database connection pools
export 'src/sources/database_source.dart'
    show DatabaseConfig, DatabaseConnectionPool;

// Realtime connection implementations
export 'src/sources/realtime_source.dart'
    show
        RealtimeConfig,
        RealtimeMessage,
        WebSocketConnection,
        MQTTConnection,
        RedisConnection;

// API source configurations
export 'src/sources/api_source.dart' show RateLimitConfig, CachedResponse;

// ============================================================================
// STORAGE AND CACHING - Data persistence and performance
// ============================================================================
export 'src/storage/vector_database.dart';
export 'src/cache/cache_manager.dart';

// Vector database data structures
export 'src/storage/vector_database.dart' show VectorData, SearchResult;

// Cache management
export 'src/cache/cache_manager.dart' show CacheEntry, CacheStats;

// ============================================================================
// ADVANCED SCORING ENGINE - Intelligent content ranking and personalization
// ============================================================================
export 'src/scoring/advanced_scoring_engine.dart';

// Scoring engine components
export 'src/scoring/advanced_scoring_engine.dart'
    show
        ScoringAlgorithmConfig,
        UserProfile,
        TemporalDecayFunction,
        SemanticSimilarityScorer,
        MultiAlgorithmScorer;

// ============================================================================
// ADVANCED FUSION ENGINE - Intelligent context combination and conflict resolution
// ============================================================================
export 'src/fusion/advanced_fusion_engine.dart';

// Fusion engine components
export 'src/fusion/advanced_fusion_engine.dart'
    show
        FusionStrategyConfig,
        SemanticGroup,
        ConflictResolutionResult,
        QualityAssessment;

// ============================================================================
// CORE ENGINES - Fundamental processing engines
// ============================================================================
export 'src/engines/context_scoring_engine.dart';
export 'src/engines/context_storage_engine.dart';
export 'src/engines/intelligent_context_fusion_engine.dart';
export 'src/engines/context_updates_engine.dart';

// Context update structures
export 'src/engines/context_updates_engine.dart' show ContextUpdate;

// ============================================================================
// PRIVACY AND SECURITY - Enterprise-grade data protection
// ============================================================================
export 'src/privacy/privacy_manager.dart';
export 'src/security/security_manager.dart';

// Security structures
export 'src/security/security_manager.dart' show SecurityPolicy, SecurityEvent;

// ============================================================================
// UTILITIES - Helper classes and functions
// ============================================================================
export 'src/utils/context_utils.dart';
export 'src/utils/embedding_utils.dart';
export 'src/utils/privacy_utils.dart';

// ============================================================================
// EXCEPTIONS - Error handling and debugging
// ============================================================================
export 'src/exceptions/ragify_exceptions.dart';

// ============================================================================
// QUICK START - Common import patterns for developers
// ============================================================================

// For basic usage, import just the main class:
// import 'package:ragify_flutter/ragify_flutter.dart';
// final ragify = RAGify();

// For advanced usage with specific components:
// import 'package:ragify_flutter/ragify_flutter.dart';
// final scoringEngine = AdvancedScoringEngine(...);
// final fusionEngine = AdvancedFusionEngine(...);

// For custom data sources:
// import 'package:ragify_flutter/ragify_flutter.dart';
// class MyDataSource extends BaseDataSource { ... }

// ============================================================================
// API COMPLETENESS CHECK
// ============================================================================
// This export file provides access to:
// ✅ Main RAGify class for easy integration
// ✅ All data models and structures
// ✅ All data source implementations
// ✅ All processing engines
// ✅ All utility classes
// ✅ All exception types
// ✅ All configuration options
// ✅ All enums and constants
// ✅ All abstract classes for extension
//
// Flutter developers can now access the complete RAGify API
// with a single import statement!
