# 🚀 RAGify Flutter - Complete API Reference

> **A comprehensive guide to all APIs provided by the RAGify Flutter package**

---

## 📚 Table of Contents

- [Main RAGify Class APIs](#-main-ragify-class-apis)
- [Context Orchestrator APIs](#-context-orchestrator-apis)
- [Data Source APIs](#-data-source-apis)
- [Utility & Helper APIs](#-utility--helper-apis)
- [Data Models & Enums](#-data-models--enums)
- [Key Features Summary](#-key-features-summary)
- [Usage Examples](#-usage-examples)

---

## 🎯 Main RAGify Class APIs

The main `RAGify` class provides a unified interface for all RAGify functionality.

### 🔧 Core Operations

#### **Constructor**
```dart
RAGify({
  RagifyConfig? config,
  Logger? logger,
  bool isTestMode = false,
})
```

**Parameters:**
- `config`: Configuration object for RAGify instance
- `logger`: Logger instance for debugging and monitoring
- `isTestMode`: Enable test mode to skip platform-specific initializations

#### **Lifecycle Management**
```dart
// Initialize RAGify and all components
Future<void> initialize()

// Close RAGify and clean up resources
Future<void> close()

// Check if RAGify is healthy
Future<bool> isHealthy()
```

#### **Context Retrieval (Primary API)**
```dart
Future<ContextResponse> getContext({
  required String query,
  String? userId,
  String? sessionId,
  int? maxTokens,
  int? maxChunks,
  double? minRelevance,
  PrivacyLevel? privacyLevel,
  bool includeMetadata = true,
  List<String>? sources,
  List<String>? excludeSources,
  bool useCache = true,
  bool useVectorSearch = true,
})
```

**Parameters:**
- `query`: The search query to find relevant context
- `userId`: Optional user ID for personalization
- `sessionId`: Optional session ID for continuity
- `maxTokens`: Maximum tokens in the response
- `maxChunks`: Maximum number of context chunks to return
- `minRelevance`: Minimum relevance threshold (0.0 to 1.0)
- `privacyLevel`: Privacy level for the request
- `includeMetadata`: Whether to include metadata in response
- `sources`: List of specific sources to query
- `excludeSources`: List of sources to exclude
- `useCache`: Whether to use caching
- `useVectorSearch`: Whether to use vector similarity search

### 📊 Data Source Management

#### **General Data Sources**
```dart
// Add a data source to RAGify
void addDataSource(BaseDataSource source)

// Remove a data source by name
void removeDataSource(String sourceName)
```

#### **Database Sources**
```dart
// Add a database source
void addDatabaseSource(DatabaseSource source)

// Get all database sources
List<DatabaseSource> getDatabaseSources()

// Get database source by name
DatabaseSource? getDatabaseSource(String name)

// Remove database source by name
void removeDatabaseSource(String name)
```

### 🔍 Vector Operations

#### **Vector Storage**
```dart
// Store context chunks in the vector database
Future<void> storeChunks(List<ContextChunk> chunks)
```

#### **Vector Search**
```dart
// Search for similar chunks using vector similarity
Future<List<ContextChunk>> searchSimilarChunks(
  String query,
  int maxResults, {
  double minSimilarity = 0.7,
  PrivacyLevel? privacyLevel,
  String? userId,
})
```

**Parameters:**
- `query`: Search query for similarity
- `maxResults`: Maximum number of results to return
- `minSimilarity`: Minimum similarity score (0.0 to 1.0)
- `privacyLevel`: Privacy level for the search
- `userId`: User ID for access control

#### **Embedding Generation**
```dart
// Generate embedding for text content (internal)
Future<List<double>> _generateEmbedding(String text)

// Generate simple embedding using hash-based approach (internal)
List<double> _generateSimpleEmbedding(String text)
```

### 📈 Statistics & Monitoring

#### **Component Statistics**
```dart
// Get cache manager statistics
Map<String, dynamic> getCacheStats()

// Get privacy manager statistics
Map<String, dynamic> getPrivacyStats()

// Get security manager statistics
Map<String, dynamic> getSecurityStats()

// Get vector database statistics
Map<String, dynamic> getVectorDatabaseStats()

// Get advanced scoring engine statistics
Map<String, dynamic> getAdvancedScoringStats()

// Get advanced fusion engine statistics
Map<String, dynamic> getAdvancedFusionStats()

// Get database source statistics
Map<String, dynamic> getDatabaseStats()

// Get overall RAGify statistics
Map<String, dynamic> getStats()
```

#### **Platform Information**
```dart
// Get comprehensive platform information
Map<String, dynamic> getPlatformInfo()

// Check if a specific platform feature is supported
bool supportsPlatformFeature(PlatformFeature feature)

// Get platform-specific recommendations
Map<String, String> getPlatformRecommendations()

// Get platform-optimized configuration
Map<String, dynamic> getPlatformOptimizedConfig()

// Get comprehensive platform status and health
Map<String, dynamic> getPlatformStatus()
```

#### **Platform Capability Checks**
```dart
// Check if current platform supports hardware acceleration
bool get supportsHardwareAcceleration

// Check if current platform supports advanced features
bool get supportsAdvancedFeatures

// Check if current platform supports persistent storage
bool get supportsPersistentStorage
```

### 🧠 Advanced AI Features

#### **Scoring Engine**
```dart
// Get the advanced scoring engine instance
AdvancedScoringEngine get advancedScoringEngine

// Calculate advanced relevance score for a context chunk
Future<RelevanceScore> calculateAdvancedScore(
  ContextChunk chunk,
  String query, {
  String? userId,
  Map<String, dynamic>? context,
})
```

**Parameters:**
- `chunk`: Context chunk to score
- `query`: Query for relevance calculation
- `userId`: User ID for personalization
- `context`: Additional context for scoring

#### **Fusion Engine**
```dart
// Get the advanced fusion engine instance
AdvancedFusionEngine get advancedFusionEngine

// Perform advanced fusion on context chunks
Future<List<ContextChunk>> performAdvancedFusion({
  required List<ContextChunk> chunks,
  required String query,
  String? userId,
  Map<String, dynamic>? context,
  List<String>? enabledStrategies,
})
```

**Parameters:**
- `chunks`: List of context chunks to fuse
- `query`: Query for fusion strategy selection
- `userId`: User ID for personalization
- `context`: Additional context for fusion
- `enabledStrategies`: List of enabled fusion strategies

#### **User Personalization**
```dart
// Update user profile for personalization
void updateUserProfile(String userId, {
  String? topic,
  String? source,
  String? contentType,
  String? query,
  double interactionScore = 1.0,
})

// Get user profile for personalization
UserProfile? getUserProfile(String userId)
```

**Parameters:**
- `userId`: Unique user identifier
- `topic`: Topic of interest
- `source`: Data source preference
- `contentType`: Preferred content type
- `query`: Query pattern
- `interactionScore`: Interaction strength (0.0 to 1.0)

### 🗄️ Database Operations

#### **Bulk Database Operations**
```dart
// Store context chunks in all database sources
Future<void> storeChunksInDatabases(List<ContextChunk> chunks)

// Get context chunks from all database sources
Future<List<ContextChunk>> getChunksFromDatabases({
  String? query,
  Map<String, dynamic>? filters,
  int? limit,
  int? offset,
})
```

**Parameters:**
- `chunks`: List of context chunks to store
- `query`: Optional query filter
- `filters`: Additional filtering criteria
- `limit`: Maximum number of results
- `offset`: Pagination offset

### 🔓 Access to Internal Components
```dart
// Get the context orchestrator (for advanced usage)
ContextOrchestrator get orchestrator

// Get the cache manager (for advanced usage)
CacheManager get cacheManager

// Get the privacy manager (for advanced usage)
PrivacyManager get privacyManager

// Get the security manager (for advanced usage)
SecurityManager get securityManager

// Get the vector database (for advanced usage)
VectorDatabase get vectorDatabase
```

---

## 🎭 Context Orchestrator APIs

The `ContextOrchestrator` manages data sources and coordinates context retrieval.

### 🔧 Core Operations
```dart
// Initialize the orchestrator
Future<void> initialize()

// Close the orchestrator and clean up resources
Future<void> close()

// Check if the orchestrator is healthy
Future<bool> isHealthy()
```

### 📚 Data Source Management
```dart
// Add a data source to the orchestrator
void addSource(BaseDataSource source)

// Remove a data source by name
void removeSource(String sourceName)

// Get a data source by name
BaseDataSource? getSource(String sourceName)

// List all registered data source names
List<String> get sourceNames
```

### 🔍 Context Retrieval
```dart
// Get intelligent context for a query
Future<ContextResponse> getContext({
  required String query,
  String? userId,
  String? sessionId,
  int? maxTokens,
  int? maxChunks,
  double? minRelevance,
  PrivacyLevel? privacyLevel,
  bool includeMetadata = true,
  List<String>? sources,
  List<String>? excludeSources,
})
```

### ⚡ Parallel Processing Configuration
```dart
// Set parallel processing configuration
void setParallelProcessingConfig(ParallelProcessingConfig config)
```

---

## 📡 Data Source APIs

### 🔌 BaseDataSource Interface

All data sources implement the `BaseDataSource` interface.

#### **Core Properties**
```dart
// Name of the data source
String get name

// Type of data source
SourceType get sourceType

// Source configuration
Map<String, dynamic> get config

// Source metadata
Map<String, dynamic> get metadata

// Whether the source is currently active
bool get isActive

// Source object representation
ContextSource get source
```

#### **Core Operations**
```dart
// Get context chunks from this data source
Future<List<ContextChunk>> getChunks({
  required String query,
  int? maxChunks,
  double minRelevance = 0.0,
  String? userId,
  String? sessionId,
})

// Refresh the data source
Future<void> refresh()

// Close the data source and clean up resources
Future<void> close()
```

#### **Monitoring & Configuration**
```dart
// Get statistics about the data source
Future<Map<String, dynamic>> getStats()

// Check if the source is healthy and accessible
Future<bool> isHealthy()

// Get the source's current status
Future<SourceStatus> getStatus()

// Update the source's metadata
Future<void> updateMetadata(Map<String, dynamic> metadata)

// Get the source's configuration
Map<String, dynamic> getConfiguration()

// Update the source's configuration
Future<void> updateConfiguration(Map<String, dynamic> config)
```

### 📄 Document Source

Specialized data source for processing document files.

```dart
class DocumentSource implements BaseDataSource {
  // Constructor
  DocumentSource({
    required String name,
    required String documentPath,
    Logger? logger,
    Map<String, dynamic>? config,
    Map<String, dynamic>? metadata,
    int chunkSize = 1000,
    int chunkOverlap = 200,
    bool includeMetadata = true,
  })
  
  // Additional properties
  final Set<String> supportedExtensions
  final int chunkSize
  final int chunkOverlap
  final bool includeMetadata
}
```

**Supported File Types:**
- `.txt` - Plain text files
- `.md` - Markdown files
- `.json` - JSON files
- `.pdf` - PDF files (placeholder)
- `.docx` - Word documents (placeholder)

### 🌐 API Source

Specialized data source for external API integration.

```dart
class APISource implements BaseDataSource {
  // Constructor
  APISource({
    required String name,
    required String baseUrl,
    required Map<String, String> headers,
    Logger? logger,
    Map<String, dynamic>? config,
    Map<String, dynamic>? metadata,
    Duration timeout = const Duration(seconds: 30),
  })
  
  // Additional properties
  final String baseUrl
  final Map<String, String> headers
  final Duration timeout
}
```

### 🗃️ Database Source

Specialized data source for database integration.

```dart
class DatabaseSource implements BaseDataSource {
  // Constructor
  DatabaseSource({
    required String name,
    required DatabaseConfig databaseConfig,
    required String tableName,
    required List<String> columns,
    Logger? logger,
    Map<String, dynamic>? metadata,
  })
  
  // Additional properties
  final DatabaseConfig databaseConfig
  final String tableName
  final List<String> columns
  final String databaseType
  
  // Database-specific operations
  Future<void> storeChunks(List<ContextChunk> chunks)
  Future<List<ContextChunk>> fetchData({
    String? query,
    Map<String, dynamic>? filters,
    int? limit,
    int? offset,
  })
}
```

**Supported Database Types:**
- SQLite
- PostgreSQL
- MySQL
- MongoDB

---

## 🛠️ Utility & Helper APIs

### 🌍 Platform Detection

Utility class for detecting platform capabilities.

```dart
class PlatformDetector {
  // Get current platform name
  static String get platformName
  
  // Platform type checks
  static bool get isWeb
  static bool get isMobile
  static bool get isDesktop
  static bool get isFuchsia
  
  // Check if platform supports specific feature
  static bool supportsFeature(PlatformFeature feature)
}
```

### ⚙️ Configuration Management

Configuration class for RAGify instances.

```dart
class RagifyConfig {
  // Constructor
  RagifyConfig({
    int maxContextSize = 10000,
    int cacheTtl = 3600,
    bool enableCaching = true,
    String? cacheUrl,
    String? vectorDbUrl,
    PrivacyLevel privacyLevel = PrivacyLevel.private,
    int sourceTimeout = 30,
  })
  
  // Properties
  final int maxContextSize
  final int cacheTtl
  final bool enableCaching
  final String? cacheUrl
  final String? vectorDbUrl
  final PrivacyLevel privacyLevel
  final int sourceTimeout
  
  // Methods
  Map<String, dynamic> toJson()
  static RagifyConfig defaultConfig()
}
```

---

## 📋 Data Models & Enums

### 🔧 Core Models

#### **ContextResponse**
```dart
class ContextResponse {
  final String id
  final String query
  final List<ContextChunk> chunks
  final String? userId
  final String? sessionId
  final int maxTokens
  final PrivacyLevel privacyLevel
  final Map<String, dynamic> metadata
  final DateTime createdAt
  final int? processingTimeMs
  
  // Methods
  Map<String, dynamic> toJson()
  static ContextResponse fromJson(Map<String, dynamic> json)
  ContextResponse copyWith({...})
}
```

#### **ContextChunk**
```dart
class ContextChunk {
  final String id
  final String content
  final ContextSource source
  final Map<String, dynamic> metadata
  final RelevanceScore? relevanceScore
  final int tokenCount
  final List<String> tags
  final DateTime createdAt
  final DateTime updatedAt
  
  // Methods
  Map<String, dynamic> toJson()
  static ContextChunk fromJson(Map<String, dynamic> json)
  ContextChunk copyWith({...})
}
```

#### **ContextSource**
```dart
class ContextSource {
  final String name
  final SourceType sourceType
  final String? url
  final Map<String, dynamic> metadata
  final PrivacyLevel privacyLevel
  final double authorityScore
  final double freshnessScore
  final DateTime? lastUpdated
  final bool isActive
  
  // Methods
  Map<String, dynamic> toJson()
  static ContextSource fromJson(Map<String, dynamic> json)
  ContextSource copyWith({...})
}
```

#### **RelevanceScore**
```dart
class RelevanceScore {
  final double score
  final double threshold
  final Map<String, dynamic> metadata
  
  // Methods
  bool isAboveThreshold(double threshold)
  Map<String, dynamic> toJson()
  static RelevanceScore fromJson(Map<String, dynamic> json)
}
```

#### **UserProfile**
```dart
class UserProfile {
  final String userId
  final Map<String, double> topicPreferences
  final Map<String, double> sourcePreferences
  final Map<String, double> contentTypePreferences
  final Map<String, double> queryPatterns
  final DateTime lastUpdated
  
  // Methods
  Map<String, dynamic> toJson()
  static UserProfile fromJson(Map<String, dynamic> json)
}
```

#### **VectorData**
```dart
class VectorData {
  final String id
  final String chunkId
  final List<double> embedding
  final Map<String, dynamic> metadata
  
  // Methods
  Map<String, dynamic> toJson()
  static VectorData fromJson(Map<String, dynamic> json)
}
```

### 🔤 Enums

#### **SourceType**
```dart
enum SourceType {
  document,    // Document files (PDF, DOCX, TXT, MD)
  api,         // External API endpoints
  database,    // Database connections
  vector,      // Vector similarity search
  custom       // Custom implementations
}
```

#### **PrivacyLevel**
```dart
enum PrivacyLevel {
  public,      // Publicly accessible
  private,     // Private to user
  enterprise,  // Enterprise-level security
  restricted   // Highly restricted access
}
```

#### **SourceStatus**
```dart
enum SourceStatus {
  healthy,     // Source is healthy and working normally
  degraded,    // Source has some issues but is still functional
  unhealthy,   // Source is not working properly
  offline,     // Source is offline or unavailable
  unknown      // Source status is unknown
}
```

#### **PlatformFeature**
```dart
enum PlatformFeature {
  sqlite,              // SQLite database support
  fileSystem,          // File system access
  sharedPreferences,   // Shared preferences storage
  webStorage,          // Web storage (IndexedDB, localStorage)
  aiModelApis,         // AI Model API support
  vectorOperations,    // Vector operations support
  realTimeCommunication, // Real-time communication support
  encryption           // Encryption support
}
```

#### **SecurityLevel**
```dart
enum SecurityLevel {
  low,        // Basic security
  medium,     // Standard security
  high,       // Enhanced security
  enterprise  // Enterprise-grade security
}
```

---

## 🎯 Key Features Summary

### 🔄 Core Capabilities
- **Context Retrieval**: Intelligent query processing with multiple data sources
- **Vector Search**: Semantic similarity search with embeddings
- **Caching**: Multi-level caching for performance optimization
- **Privacy Controls**: Granular privacy level management
- **Security**: Encryption and access control features

### 🌐 Cross-Platform Support
- **Web**: IndexedDB, localStorage, TensorFlow.js optimizations
- **Mobile**: SQLite, TensorFlow Lite, hardware acceleration
- **Desktop**: File system, TensorFlow Lite, parallel processing
- **Fuchsia**: Fallback implementations

### 🤖 AI/ML Features
- **Advanced Scoring**: Intelligent relevance assessment
- **Context Fusion**: Smart conflict resolution and merging
- **User Personalization**: Learning from user interactions
- **Embedding Generation**: Text-to-vector conversion

### 📊 Monitoring & Analytics
- **Comprehensive Statistics**: All component metrics
- **Health Checks**: System status monitoring
- **Performance Metrics**: Response times and throughput
- **Error Tracking**: Detailed error logging and recovery

---

## 💡 Usage Examples

### 🚀 Basic Setup
```dart
import 'package:ragify_flutter/ragify_flutter.dart';

void main() async {
  // Create RAGify instance
  final ragify = RAGify(
    config: RagifyConfig(
      maxContextSize: 15000,
      cacheTtl: 7200,
      enableCaching: true,
    ),
  );
  
  // Initialize
  await ragify.initialize();
  
  // Add data sources
  final documentSource = DocumentSource(
    name: 'my_documents',
    documentPath: '/path/to/documents',
  );
  ragify.addDataSource(documentSource);
  
  // Get context
  final response = await ragify.getContext(
    query: 'What is machine learning?',
    maxChunks: 5,
    minRelevance: 0.7,
  );
  
  print('Found ${response.chunks.length} relevant chunks');
}
```

### 🔍 Advanced Usage
```dart
// Vector similarity search
final similarChunks = await ragify.searchSimilarChunks(
  'artificial intelligence',
  10,
  minSimilarity: 0.8,
);

// Advanced scoring
final score = await ragify.calculateAdvancedScore(
  chunk,
  'machine learning applications',
  userId: 'user123',
);

// Advanced fusion
final fusedChunks = await ragify.performAdvancedFusion(
  chunks: allChunks,
  query: 'AI in healthcare',
  userId: 'user123',
  enabledStrategies: ['semantic', 'temporal'],
);

// User personalization
ragify.updateUserProfile(
  'user123',
  topic: 'machine learning',
  source: 'research_papers',
  contentType: 'academic',
  interactionScore: 0.9,
);
```

### 📊 Monitoring
```dart
// Get comprehensive statistics
final stats = ragify.getStats();
print('Cache hit rate: ${stats['cache']['hit_rate']}');

// Check platform capabilities
final platformInfo = ragify.getPlatformInfo();
print('Platform: ${platformInfo['platform']}');
print('Supports AI APIs: ${ragify.supportsPlatformFeature(PlatformFeature.aiModelApis)}');

// Health check
final isHealthy = await ragify.isHealthy();
print('System healthy: $isHealthy');
```

---

## 📚 Additional Resources

- **GitHub Repository**: [RAGify Flutter](https://github.com/ragify/ragify_flutter)
- **Documentation**: [API Documentation](https://ragify.dev/flutter)
- **Examples**: [Code Examples](https://ragify.dev/flutter/examples)
- **Community**: [Discord Server](https://discord.gg/ragify)

---

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

*Generated on: ${new Date().toISOString()}*
*RAGify Flutter Version: 1.0.0*
