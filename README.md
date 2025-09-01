# 🚀 RAGify Flutter

[![Pub Version](https://img.shields.io/pub/v/ragify_flutter.svg)](https://pub.dev/packages/ragify_flutter)
[![License: BSD 3-Clause](https://img.shields.io/badge/License-BSD%203--Clause-blue.svg)]

**Intelligent Context Orchestration Framework for Flutter - Smart Context for LLM-Powered Applications**

A Flutter package that combines data from multiple sources (documents, APIs, databases, real-time) and resolves conflicts intelligently. Built specifically for **LLM-powered Flutter applications** that need accurate, current information.

## 🎯 Why RAGify Flutter?

Building AI-powered Flutter apps is challenging because:
- **Multiple data sources** need to be combined intelligently
- **Conflicting information** between sources must be resolved
- **Real-time updates** require efficient context management
- **Privacy and security** need to be built-in, not bolted-on
- **Performance** must be optimized for mobile and web

RAGify Flutter solves these problems with a unified, production-ready framework.

## 🌟 What You Get

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
- **Performance Optimized** - Efficient memory usage and processing

## 🚀 Quick Start

### **1. Add Dependency**

```yaml
dependencies:
  ragify_flutter: ^0.0.2
```

### **2. Import Package**

```dart
import 'package:ragify_flutter/ragify_flutter.dart';
```

### **3. Basic Usage**

```dart
// Create RAGify instance
final ragify = RAGify();

// Initialize
await ragify.initialize();

// Add data sources
ragify.addDataSource(DocumentSource(
  name: 'docs',
  documentPath: './documents',
));

// Get context
final context = await ragify.getContext(
  query: 'What are the latest features?',
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

## 📱 Examples

The package includes complete example applications:

- **Basic Usage** - Simple context retrieval
- **Advanced Features** - Complex integration patterns
- **Full Integration** - Complete application examples

Run examples:
```bash
cd example/basic_usage
flutter run
```

## 🔧 Configuration

```dart
final config = RagifyConfig(
  privacyLevel: PrivacyLevel.enterprise,
  maxContextSize: 50000,
  defaultRelevanceThreshold: 0.7,
  enableCaching: true,
  cacheTtl: 7200,
  conflictDetectionThreshold: 0.8,
  sourceTimeout: 60.0,
  maxConcurrentSources: 20,
);

final ragify = RAGify(config: config);
```

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Current coverage: 40.92%
```

## 🔒 Privacy & Security

- **4 Privacy Levels**: Public, Private, Enterprise, Restricted
- **Encryption**: AES-256, RSA-2048, ChaCha20 support
- **Access Control**: Role-based permissions (Guest to Superuser)
- **Audit Logging**: Complete operation tracking
- **Compliance**: GDPR, HIPAA, SOX ready

## 🚀 Performance

- **Response Time**: Optimized for <200ms typical queries
- **Concurrent Processing**: Multi-isolate parallel processing
- **Memory Efficient**: Intelligent caching and chunking
- **Cross-Platform**: Platform-specific optimizations

## 🔌 Data Sources

- **Documents**: PDF, DOCX, TXT, Markdown
- **APIs**: REST, GraphQL with rate limiting
- **Databases**: PostgreSQL, MySQL, MongoDB, SQLite
- **Real-time**: WebSocket, MQTT, Redis, Kafka

## 🤝 Contributing

We welcome contributions! See [Contributing Guide](CONTRIBUTING.md) for details.

```bash
# Development setup
git clone https://github.com/sumitnemade/ragify_flutter.git
cd ragify_flutter
flutter pub get
flutter test
```

## 📄 License

BSD 3-Clause License - see [LICENSE](LICENSE) file for details.

## 🔗 Related Projects

- **Python Version**: [RAGify Python](https://github.com/sumitnemade/ragify) - The original 

## 🆘 Support

- **Issues**: [GitHub Issues](https://github.com/sumitnemade/ragify_flutter/issues)
- **Discussions**: [GitHub Discussions](https://github.com/sumitnemade/ragify_flutter/discussions)

---

**Built with ❤️ for the Flutter community**
