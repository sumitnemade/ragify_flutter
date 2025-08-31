import 'package:flutter/material.dart';
import 'package:ragify_flutter/ragify_flutter.dart';

void main() {
  runApp(const RAGifyBasicUsageApp());
}

class RAGifyBasicUsageApp extends StatelessWidget {
  const RAGifyBasicUsageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RAGify Basic Usage',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const RAGifyBasicUsagePage(),
    );
  }
}

class RAGifyBasicUsagePage extends StatefulWidget {
  const RAGifyBasicUsagePage({super.key});

  @override
  State<RAGifyBasicUsagePage> createState() => _RAGifyBasicUsagePageState();
}

class _RAGifyBasicUsagePageState extends State<RAGifyBasicUsagePage> {
  RAGify? _ragify;
  bool _isInitialized = false;
  String _status = 'Not initialized';
  final List<String> _logs = [];
  final TextEditingController _queryController = TextEditingController();
  List<ContextChunk> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _initializeRAGify();
  }

  @override
  void dispose() {
    _ragify?.close();
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _initializeRAGify() async {
    try {
      setState(() {
        _status = 'Initializing...';
        _logs.add('🚀 Starting RAGify initialization...');
      });

      // Create RAGify instance
      _ragify = RAGify();

      // Initialize all components
      await _ragify!.initialize();

      // Add sample data source
      final documentSource = DocumentSource(
        name: 'sample_documents',
        documentPath: '/sample_docs',
      );
      _ragify!.addDataSource(documentSource);

      // Add sample content
      await _addSampleContent();

      setState(() {
        _isInitialized = true;
        _status = 'Ready';
        _logs.add('✅ RAGify initialized successfully!');
        _logs.add('📊 Added sample data source');
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
        _logs.add('❌ Initialization failed: $e');
      });
    }
  }

  Future<void> _addSampleContent() async {
    if (_ragify == null) return;

    try {
      // Create sample context chunks
      final sampleChunks = [
        ContextChunk(
          id: 'sample_001',
          content:
              'Flutter is Google\'s UI toolkit for building beautiful, natively compiled applications for mobile, web, and desktop from a single codebase.',
          source: ContextSource(
            name: 'flutter_docs',
            url: 'https://flutter.dev',
            authorityScore: 0.95,
            lastUpdated: DateTime.now(),
            sourceType: SourceType.document,
          ),
          tags: ['flutter', 'mobile', 'cross-platform', 'dart'],
          metadata: {'content_type': 'overview'},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        ContextChunk(
          id: 'sample_002',
          content:
              'Dart is a client-optimized language for fast apps on any platform. It is the foundation of Flutter.',
          source: ContextSource(
            name: 'dart_lang',
            url: 'https://dart.dev',
            authorityScore: 0.9,
            lastUpdated: DateTime.now(),
            sourceType: SourceType.document,
          ),
          tags: ['dart', 'programming', 'language', 'flutter'],
          metadata: {'content_type': 'documentation'},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      // Store in vector database
      for (final chunk in sampleChunks) {
        await _ragify!.vectorDatabase.addVectors([
          VectorData(
            id: chunk.id,
            chunkId: chunk.id,
            embedding: List.filled(384, 0.1), // Placeholder vector
            metadata: chunk.metadata,
          ),
        ]);
      }

      setState(() {
        _logs.add('📝 Added ${sampleChunks.length} sample context chunks');
      });
    } catch (e) {
      setState(() {
        _logs.add('❌ Failed to add sample content: $e');
      });
    }
  }

  Future<void> _performSearch() async {
    if (_ragify == null || !_isInitialized) return;

    final query = _queryController.text.trim();
    if (query.isEmpty) return;

    try {
      setState(() {
        _logs.add('🔍 Searching for: $query');
      });

      // Perform vector search
      final results = await _ragify!.searchSimilarChunks(query, 5);

      setState(() {
        _searchResults = results;
        _logs.add('✅ Search completed. Found ${results.length} results');
      });
    } catch (e) {
      setState(() {
        _logs.add('❌ Search failed: $e');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('RAGify Basic Usage'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status: $_status',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: _isInitialized ? Colors.green : Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Logs: ${_logs.length} entries'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Search Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Search Context',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _queryController,
                            decoration: const InputDecoration(
                              hintText: 'Enter your search query...',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _isInitialized ? _performSearch : null,
                          child: const Text('Search'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Results Section
            if (_searchResults.isNotEmpty) ...[
              Text(
                'Search Results (${_searchResults.length})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final result = _searchResults[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(
                          result.content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          'Source: ${result.source.name} | Tags: ${result.tags.join(', ')}',
                        ),
                        trailing: Text(
                          'Score: ${result.metadata['relevance_score']?.toStringAsFixed(3) ?? 'N/A'}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],

            // Logs Section
            if (_logs.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'System Logs',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    final log =
                        _logs[_logs.length - 1 - index]; // Show newest first
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        log,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
