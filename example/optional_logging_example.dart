import 'package:ragify_flutter/ragify_flutter.dart';
import 'package:logger/logger.dart';

/// Example demonstrating optional logging in RAGify Flutter
///
/// This example shows three different ways to configure logging:
/// 1. With logging enabled (default)
/// 2. With logging disabled
/// 3. With custom logger configuration
void main() async {
  // ignore_for_file: avoid_print
  print('RAGify Flutter Optional Logging Examples\n');

  // Example 1: Default logging (enabled)
  print('1. RAGify with default logging (enabled):');
  final ragifyWithLogging = RAGify(
    enableLogging: true, // This is the default
  );
  await ragifyWithLogging.initialize();
  print('   - Logging is enabled, you will see log messages\n');

  // Example 2: Disabled logging
  print('2. RAGify with logging disabled:');
  final ragifyNoLogging = RAGify(
    enableLogging: false, // Completely disable logging
  );
  await ragifyNoLogging.initialize();
  print('   - Logging is disabled, no log messages will appear\n');

  // Example 3: Custom logger configuration
  print('3. RAGify with custom logger:');
  final customLogger = Logger(
    level: Level.warning, // Only show warnings and errors
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 3,
      lineLength: 50,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  final ragifyCustomLogging = RAGify(logger: customLogger, enableLogging: true);
  await ragifyCustomLogging.initialize();
  print('   - Custom logger configured with warning level\n');

  // Example 4: Using NullableLogger directly for advanced scenarios
  print('4. Advanced: Using NullableLogger directly:');

  // Create a logger that can be enabled/disabled at runtime
  final nullableLogger = RAGifyLogger.fromLogger(
    Logger(level: Level.info),
    enabled: true,
  );

  // You can now use this logger throughout your application
  nullableLogger.i('This message will be logged');

  // Create a disabled logger
  final disabledLogger = const RAGifyLogger.disabled();
  disabledLogger.i('This message will NOT be logged');

  print('   - NullableLogger provides fine-grained control\n');

  // Clean up
  await ragifyWithLogging.close();
  await ragifyNoLogging.close();
  await ragifyCustomLogging.close();

  print('Example completed! Check the console output to see the difference.');
}

/// Additional helper function showing how to create components with optional logging
void createComponentsWithOptionalLogging() {
  // All RAGify components now support optional logging

  // Document source with specific document
  final documentSource = DocumentSource(
    name: 'my_docs',
    documentPath:
        './documents/example.txt', // Fixed: use documentPath instead of directoryPath
  );

  // API source with custom configuration
  final apiSource = APISource(
    name: 'my_api',
    baseUrl: 'https://api.example.com',
    config: {
      'include_query': true,
      // Other API configurations...
    },
    // Logging configuration is handled at the RAGify level
  );

  // Use the sources to avoid unused variable warnings
  print('Document source: ${documentSource.name}');
  print('API source: ${apiSource.name}');
  print('Components created with inherited logging configuration');
}
