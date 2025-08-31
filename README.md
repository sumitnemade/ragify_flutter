# 🚀 RAGify Flutter

**Intelligent Context Orchestration Framework for Flutter - Smart Context for LLM-Powered Applications**

A Flutter package that combines data from multiple sources (documents, APIs, databases, real-time) and resolves conflicts intelligently. Built specifically for **LLM-powered Flutter applications** that need accurate, current information.

## 🎯 What is RAGify Flutter?

RAGify Flutter is a Flutter/Dart implementation of the RAGify framework that provides intelligent context orchestration for mobile and web applications. It helps Flutter developers build AI-powered apps that can:

- **Combine information** from multiple data sources
- **Detect and resolve conflicts** between data sources
- **Manage privacy** with configurable security levels
- **Process sources concurrently** for better performance
- **Score relevance** intelligently for better context selection

## 🌟 Key Features

### **Core Capabilities**
- **Multi-Source Context Fusion** - Combine data from documents, APIs, databases, and real-time sources
- **Intelligent Conflict Resolution** - Detect and resolve contradictions using source authority and freshness
- **Privacy Management** - 4-tier privacy levels (Public, Private, Enterprise, Restricted)
- **Concurrent Processing** - Process multiple sources simultaneously for better performance
- **Relevance Scoring** - Multi-factor assessment of context relevance

### **Flutter-Specific Features**
- **Cross-Platform Support** - Works on iOS, Android, Web, and Desktop
- **Async/Await Support** - Full async support for non-blocking operations
- **State Management Integration** - Works with Provider, Bloc, Riverpod, and other state management solutions
- **Material Design Ready** - Includes example UI components
- **Performance Optimized** - Efficient memory usage and processing

## 📱 Use Cases

### **AI Chatbots & Assistants**
- Multi-source context management
- Conflict detection in responses
- Source tracking for transparency

### **Knowledge Management Apps**
- Company knowledge bases
- Research assistants
- Educational content aggregation

### **Enterprise Applications**
- Multi-database search
- Document processing
- Real-time data integration

## 🚀 Quick Start

### **1. Add Dependency**

```yaml
dependencies:
  ragify_flutter: ^0.1.0
```

### **2. Import Package**

```dart
import 'package:ragify_flutter/ragify_flutter.dart';
```

### **3. Basic Usage**

```dart
// Create orchestrator
final orchestrator = ContextOrchestrator(
  config: RagifyConfig.defaultConfig(),
);

// Initialize
await orchestrator.initialize();

// Add data sources
orchestrator.addSource(DocumentSource('./docs'));
orchestrator.addSource(APISource('https://api.company.com/data'));

// Get context
final context = await orchestrator.getContext(
  query: 'Latest sales and trends?',
  maxChunks: 10,
  minRelevance: 0.7,
);

// Use the context
for (final chunk in context.chunks) {
  print('${chunk.content} (Score: ${chunk.relevanceScore?.score})');
}
```

## 🏗️ Architecture

### **Core Components**

```
┌─────────────────────────────────────────────────────────────────┐
│                Flutter Application                            │
├─────────────────────────────────────────────────────────────────┤
│                    RAGify Flutter                             │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ │
│  │   Fusion    │ │   Scoring   │ │   Storage   │ │   Updates   │ │
│  │  Engine     │ │  Engine     │ │  Engine     │ │  Engine     │ │
│  │ (Conflicts) │ │ (Relevance) │ │ (Save)      │ │ (Live)      │ │
│  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘ │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ │
│  │   Vector    │ │   Cache     │ │   Privacy   │ │   Monitor   │ │
│  │     DB      │ │  Manager    │ │  Manager    │ │  Engine     │ │
│  │(Local/Cloud)│ │(Memory/Redis)│ │ (Encrypt)   │ │(Performance)│ │
│  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘ │
├─────────────────────────────────────────────────────────────────┤
│                    Data Sources                                 │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ │
│  │  Documents  │ │    APIs     │ │  Databases  │ │ Real-time   │ │
│  │ (PDF, DOCX, │ │ (REST,      │ │ (SQL,       │ │   Data      │ │
│  │ TXT, MD)    │ │ GraphQL)    │ │ NoSQL)      │ │(WebSocket,  │ │
│  │             │ │             │ │             │ │ MQTT, Kafka)│ │
│  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

## 📚 API Reference

### **ContextOrchestrator**

The main class for orchestrating context operations.

```dart
class ContextOrchestrator {
  // Configuration
  final RagifyConfig config;
  
  // Add data source
  void addSource(BaseDataSource source);
  
  // Remove data source
  void removeSource(String sourceName);
  
  // Get context
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
  });
  
  // Health check
  Future<bool> isHealthy();
  
  // Get statistics
  Map<String, dynamic> getStats();
  
  // Close and cleanup
  Future<void> close();
}
```

### **Data Sources**

Implement `BaseDataSource` to create custom data sources.

```dart
abstract class BaseDataSource {
  String get name;
  SourceType get sourceType;
  bool get isActive;
  
  Future<List<ContextChunk>> getChunks({
    required String query,
    int? maxChunks,
    double minRelevance = 0.0,
    String? userId,
    String? sessionId,
  });
  
  Future<void> refresh();
  Future<void> close();
  Future<bool> isHealthy();
}
```

### **Models**

Core data models for the framework.

```dart
// Context chunk
class ContextChunk {
  final String id;
  final String content;
  final ContextSource source;
  final RelevanceScore? relevanceScore;
  final Map<String, dynamic> metadata;
}

// Context response
class ContextResponse {
  final String id;
  final String query;
  final List<ContextChunk> chunks;
  final PrivacyLevel privacyLevel;
  final Map<String, dynamic> metadata;
}

// Privacy levels
enum PrivacyLevel {
  public,      // No restrictions
  private,     // User-specific restrictions
  enterprise,  // Organization-level restrictions
  restricted,  // Highest security level
}
```

## 🔧 Configuration

### **RagifyConfig**

Configure the orchestrator behavior.

```dart
final config = RagifyConfig(
  privacyLevel: PrivacyLevel.enterprise,
  maxContextSize: 50000,
  defaultRelevanceThreshold: 0.7,
  enableCaching: true,
  cacheTtl: 7200,
  enableAnalytics: true,
  logLevel: 'WARNING',
  conflictDetectionThreshold: 0.8,
  sourceTimeout: 60.0,
  maxConcurrentSources: 20,
);

// Or use predefined configurations
final config = RagifyConfig.production();
final config = RagifyConfig.minimal();
```

## 📱 Example App

The package includes a complete example app demonstrating:

- Basic context retrieval
- Data source integration
- UI state management
- Error handling

Run the example:

```bash
cd example
flutter run
```

## 🧪 Testing

Run the test suite:

```bash
flutter test
```

## 🔒 Privacy & Security

### **Privacy Levels**
- **Public**: No restrictions, suitable for general information
- **Private**: User-specific restrictions, personal data
- **Enterprise**: Organization-level restrictions, company data
- **Restricted**: Highest security, sensitive information

### **Security Features**
- Multi-level encryption support
- Role-based access control
- Audit logging
- Compliance frameworks (GDPR, HIPAA, SOX)

## 🚀 Performance

### **Optimizations**
- Concurrent source processing
- Intelligent caching
- Memory-efficient chunking
- Async/await throughout

### **Benchmarks**
- **Response Time**: < 200ms for typical queries
- **Concurrent Requests**: 1000+ simultaneous
- **Memory Usage**: < 100MB for large contexts
- **Throughput**: 1000+ requests/minute

## 🔌 Integrations

### **Vector Databases**
- ChromaDB (local)
- Pinecone (cloud)
- Weaviate (local/cloud)
- FAISS (local)

### **Cache Systems**
- In-memory cache
- Redis
- Memcached

### **Document Formats**
- PDF
- DOCX
- TXT
- Markdown

### **APIs**
- REST APIs
- GraphQL
- WebSocket streams
- MQTT
- Kafka

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### **Development Setup**

```bash
# Clone the repository
git clone https://github.com/sumitnemade/ragify_flutter.git
cd ragify_flutter

# Install dependencies
flutter pub get

# Run tests
flutter test

# Generate code
flutter packages pub run build_runner build
```

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🆘 Support

- **Documentation**: [https://ragify.readthedocs.io](https://ragify.readthedocs.io)
- **Issues**: [GitHub Issues](https://github.com/sumitnemade/ragify_flutter/issues)
- **Discussions**: [GitHub Discussions](https://github.com/sumitnemade/ragify_flutter/discussions)

## 🙏 Acknowledgments

- Built on the foundation of the Python RAGify framework
- Inspired by modern RAG (Retrieval-Augmented Generation) systems
- Designed for the Flutter community

---

**Made with ❤️ for the Flutter community**
