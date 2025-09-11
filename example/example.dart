import 'package:flutter/cupertino.dart' show debugPrint;
import 'package:ragify_flutter/ragify_flutter.dart';

/// Example demonstrating basic usage of RAGify Flutter
///
/// This example shows how to:
/// 1. Initialize RAGify with configuration
/// 2. Add data sources
/// 3. Query for context
/// 4. Handle responses
void main() async {
  debugPrint('🚀 RAGify Flutter Example');
  debugPrint('========================\n');

  try {
    // 1. Initialize RAGify with configuration
    debugPrint('📋 Initializing RAGify...');
    final ragify = RAGify(
      config: RagifyConfig(
        vectorDbUrl: 'memory://',
        privacyLevel: PrivacyLevel.public,
        enableCaching: true,
        maxContextSize: 10000,
      ),
      enableLogging: true,
    );

    // Initialize RAGify
    await ragify.initialize();

    // 2. Add data sources
    debugPrint('📚 Adding data sources...');

    // Add a document source
    ragify.addDataSource(
      DocumentSource(name: 'Documentation', documentPath: 'assets/docs/'),
    );

    // Add a database source (simplified for example)
    // Note: In a real app, you'd need proper database configuration
    // ragify.addDatabaseSource(DatabaseSource(...));

    debugPrint('✅ Data sources added successfully!\n');

    // 3. Query for context
    debugPrint('🔍 Querying for context...');
    final query = 'How do I implement authentication in Flutter?';
    debugPrint('Query: "$query"\n');

    final response = await ragify.getContext(
      query: query,
      maxChunks: 5,
      minRelevance: 0.7,
    );

    // 4. Handle response
    debugPrint('📄 Context Response:');
    debugPrint('===================');
    debugPrint('Total chunks found: ${response.chunks.length}');
    debugPrint('Processing time: ${response.processingTimeMs ?? 0}ms');
    debugPrint('Response ID: ${response.id}');
    debugPrint('Privacy level: ${response.privacyLevel.value}\n');

    for (int i = 0; i < response.chunks.length; i++) {
      final chunk = response.chunks[i];
      debugPrint('Chunk ${i + 1}:');
      debugPrint(
        '  Content: ${chunk.content.length > 100 ? '${chunk.content.substring(0, 100)}...' : chunk.content}',
      );
      debugPrint('  Relevance: ${chunk.relevanceScore?.score ?? 0.0}');
      debugPrint('  Source: ${chunk.source.name}');
      debugPrint('  Metadata: ${chunk.metadata}');
      debugPrint('');
    }

    // 5. Search for similar chunks
    debugPrint('🔍 Searching for similar chunks...');
    final similarChunks = await ragify.searchSimilarChunks(
      query,
      3,
      minSimilarity: 0.5,
    );

    debugPrint('Similar chunks found: ${similarChunks.length}');
    for (int i = 0; i < similarChunks.length; i++) {
      final chunk = similarChunks[i];
      debugPrint(
        '  ${i + 1}. ${chunk.content.substring(0, 50)}... (score: ${chunk.relevanceScore?.score ?? 0.0})',
      );
    }

    debugPrint('\n✅ Example completed successfully!');
  } catch (e) {
    debugPrint('❌ Error: $e');
    debugPrint('\nPlease ensure you have:');
    debugPrint('1. Properly configured your data sources');
    debugPrint('2. Added the required dependencies');
    debugPrint('3. Set up proper file paths for document sources');
  }
}

/// Example of advanced usage with custom scoring and fusion
Future<void> advancedExample() async {
  debugPrint('\n🔬 Advanced RAGify Example');
  debugPrint('==========================\n');

  final ragify = RAGify(
    config: RagifyConfig(
      vectorDbUrl: 'memory://',
      privacyLevel: PrivacyLevel.public,
      enableCaching: true,
      maxContextSize: 20000,
      defaultRelevanceThreshold: 0.8,
    ),
    enableLogging: true,
  );

  await ragify.initialize();

  // Add multiple sources with different configurations
  ragify.addDataSource(
    DocumentSource(
      name: 'Technical Docs',
      documentPath: 'docs/technical/',
      chunkSize: 512,
      chunkOverlap: 50,
    ),
  );

  // Query with advanced parameters
  final response = await ragify.getContext(
    query: 'What are the best practices for Flutter state management?',
    maxChunks: 10,
    minRelevance: 0.8,
    privacyLevel: PrivacyLevel.public,
  );

  debugPrint(
    'Advanced query completed with ${response.chunks.length} relevant chunks',
  );

  // Demonstrate advanced fusion
  final fusedChunks = await ragify.performAdvancedFusion(
    chunks: response.chunks,
    query: 'What are the best practices for Flutter state management?',
    userId: 'example_user',
  );

  debugPrint('After advanced fusion: ${fusedChunks.length} optimized chunks');
}
