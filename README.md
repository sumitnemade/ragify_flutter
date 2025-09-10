# 🚀 RAGify Flutter

[![Pub Version](https://img.shields.io/pub/v/ragify_flutter.svg)](https://pub.dev/packages/ragify_flutter)
[![License: BSD 3-Clause](https://img.shields.io/badge/License-BSD%203--Clause-blue.svg)]

**Intelligent Context Orchestration Framework for Flutter - Smart Context for LLM-Powered Applications**

A Flutter package that combines data from multiple sources (documents, APIs, databases, real-time) and provides intelligent context management. Built specifically for **LLM-powered Flutter applications** that need to retrieve and manage contextual information from various data sources.

## 🎯 Why RAGify Flutter?

Building AI-powered Flutter apps is challenging because:
- **Multiple data sources** need to be combined intelligently
- **Context management** requires efficient data retrieval and processing
- **Cross-platform compatibility** needs to work on all Flutter platforms
- **Performance** must be optimized for mobile and web
- **Easy integration** with existing Flutter applications

RAGify Flutter provides a unified framework for context management and data source integration.

## 🌟 What You Get

### **Core Capabilities**
- **Multi-Source Data Integration** - Connect to documents, APIs, databases, and real-time sources
- **Context Management** - Organize and retrieve contextual information efficiently
- **Privacy Management** - Configurable privacy levels for different data sources
- **Concurrent Processing** - Process multiple sources simultaneously for better performance
- **Relevance Scoring** - Basic relevance assessment for context chunks

### **Flutter-Specific Features**
- **Cross-Platform Support** - Works on iOS, Android, Web, and Desktop
- **Async/Await Support** - Full async support for non-blocking operations
- **State Management Integration** - Works with Provider, Bloc, Riverpod, and other state management solutions
- **Performance Optimized** - Efficient memory usage and processing

## 🚀 Quick Start

### **1. Add Dependency**

```yaml
dependencies:
  ragify_flutter: ^0.0.5
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

The package includes a comprehensive example application:

- **Basic Usage** - Complete example with all data source types (API, Document, Database)
- **Database Testing** - SQLite, PostgreSQL, MySQL, and MongoDB integration examples
- **Real-time Features** - WebSocket and real-time data source examples

Run the example:
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

```

## 🔒 Privacy & Security

- **Privacy Levels**: Configurable privacy levels for different data sources
- **Basic Encryption**: Support for data encryption (implementation in progress)
- **Access Control**: Basic access control mechanisms
- **Logging**: Comprehensive logging for debugging and monitoring
- **Data Protection**: Basic data protection features

## 🚀 Performance

- **Response Time**: Optimized for reasonable query response times
- **Concurrent Processing**: Async processing for better performance
- **Memory Efficient**: Basic caching and chunking mechanisms
- **Cross-Platform**: Works across all Flutter platforms

## 🔌 Data Sources

- **Documents**: PDF, DOCX, TXT, HTML, CSV, JSON, YAML, XML, INI, DOC
- **APIs**: REST APIs with GET/POST support and query inclusion
- **Databases**: SQLite, PostgreSQL, MySQL, MongoDB
- **Real-time**: WebSocket support (basic implementation)

## 🤝 Contributing

We welcome contributions! This is an active project with ongoing development.

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
