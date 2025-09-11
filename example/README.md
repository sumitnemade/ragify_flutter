# RAGify Flutter Examples

This directory contains examples demonstrating how to use the RAGify Flutter package for intelligent context orchestration in Flutter applications.

## Quick Start Example

The `example.dart` file shows the basic usage of RAGify Flutter:

1. **Initialize RAGify** with your API configuration
2. **Add data sources** (documents, databases, APIs)
3. **Query for context** using natural language
4. **Generate AI responses** with retrieved context

## Advanced Example

The `advancedExample()` function demonstrates:

- Multiple data source configurations
- Custom scoring and filtering
- Privacy level management
- Advanced query parameters

## Full Flutter App Example

For a complete Flutter application example, see the `basic_usage/` directory which contains:

- A full Flutter app demonstrating RAGify integration
- Database setup scripts for multiple platforms
- Real-world usage patterns
- UI components for context management

## Getting Started

1. Add RAGify Flutter to your `pubspec.yaml`:
   ```yaml
   dependencies:
     ragify_flutter: ^0.0.5
   ```

2. Import the package:
   ```dart
   import 'package:ragify_flutter/ragify_flutter.dart';
   ```

3. Follow the examples in this directory to integrate RAGify into your app.

## Data Sources

RAGify Flutter supports multiple data source types:

- **Document Sources**: PDF, Markdown, Text files
- **Database Sources**: SQLite, PostgreSQL, MySQL, MongoDB
- **API Sources**: REST APIs, GraphQL endpoints
- **Real-time Sources**: WebSockets, Server-Sent Events

## Configuration

Configure RAGify with your preferred AI model and settings:

```dart
final ragify = RAGify(
   config: RagifyConfig(
      maxContextSize: 15000,
      cacheTtl: 7200,
      enableCaching: true,
   ),
);
```

## Learn More

- [Package Documentation](https://pub.dev/packages/ragify_flutter)
- [API Reference](https://pub.dev/documentation/ragify_flutter/latest/)
- [GitHub Repository](https://github.com/sumitnemade/ragify_flutter)
