import 'package:flutter/material.dart';
import 'package:ragify_flutter/ragify_flutter.dart';

void main() {
  runApp(const RAGifyAdvancedFeaturesApp());
}

class RAGifyAdvancedFeaturesApp extends StatelessWidget {
  const RAGifyAdvancedFeaturesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RAGify Advanced Features',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const RAGifyAdvancedFeaturesPage(),
    );
  }
}

class RAGifyAdvancedFeaturesPage extends StatefulWidget {
  const RAGifyAdvancedFeaturesPage({super.key});

  @override
  State<RAGifyAdvancedFeaturesPage> createState() =>
      _RAGifyAdvancedFeaturesPageState();
}

class _RAGifyAdvancedFeaturesPageState extends State<RAGifyAdvancedFeaturesPage>
    with SingleTickerProviderStateMixin {
  RAGify? _ragify;
  bool _isInitialized = false;
  String _status = 'Not initialized';
  final List<String> _logs = [];

  // Advanced Scoring
  final TextEditingController _scoringQueryController = TextEditingController();
  final TextEditingController _userIdController = TextEditingController();
  RelevanceScore? _lastScore;

  // Advanced Fusion
  final TextEditingController _fusionQueryController = TextEditingController();
  List<ContextChunk> _fusionResults = [];

  // Tab Controller
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _userIdController.text = 'user_123';
    _initializeRAGify();
  }

  @override
  void dispose() {
    _ragify?.close();
    _scoringQueryController.dispose();
    _userIdController.dispose();
    _fusionQueryController.dispose();
    _tabController.dispose();
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
        _logs.add('📊 Advanced Scoring Engine ready');
        _logs.add('🔗 Advanced Fusion Engine ready');
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
        ContextChunk(
          id: 'sample_003',
          content:
              'Flutter provides a rich set of pre-built widgets for building user interfaces.',
          source: ContextSource(
            name: 'flutter_widgets',
            url: 'https://flutter.dev/widgets',
            authorityScore: 0.85,
            lastUpdated: DateTime.now(),
            sourceType: SourceType.document,
          ),
          tags: ['flutter', 'widgets', 'ui', 'components'],
          metadata: {'content_type': 'tutorial'},
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

  Future<void> _performAdvancedScoring() async {
    if (_ragify == null || !_isInitialized) return;

    final query = _scoringQueryController.text.trim();
    final userId = _userIdController.text.trim();
    if (query.isEmpty) return;

    try {
      setState(() {
        _logs.add('🎯 Performing advanced scoring for: $query');
      });

      // Create a sample chunk for scoring
      final chunk = ContextChunk(
        id: 'test_chunk',
        content:
            'Flutter provides a rich set of pre-built widgets for building user interfaces.',
        source: ContextSource(
          name: 'test_source',
          url: 'https://example.com',
          authorityScore: 0.8,
          lastUpdated: DateTime.now(),
          sourceType: SourceType.document,
        ),
        tags: ['flutter', 'widgets'],
        metadata: {'content_type': 'tutorial'},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Calculate advanced score
      final score = await _ragify!.calculateAdvancedScore(
        chunk,
        query,
        userId: userId.isEmpty ? null : userId,
      );

      // Update user profile
      if (userId.isNotEmpty) {
        _ragify!.updateUserProfile(
          userId,
          topic: 'flutter',
          source: 'test_source',
          contentType: 'tutorial',
          query: query,
          interactionScore: 1.0,
        );
      }

      setState(() {
        _lastScore = score;
        _logs.add(
          '✅ Advanced scoring completed. Score: ${score.score.toStringAsFixed(3)}',
        );
        _logs.add(
          '📊 Confidence: ${(score.confidenceLevel * 100).toStringAsFixed(1)}%',
        );
      });
    } catch (e) {
      setState(() {
        _logs.add('❌ Advanced scoring failed: $e');
      });
    }
  }

  Future<void> _performAdvancedFusion() async {
    if (_ragify == null || !_isInitialized) return;

    final query = _fusionQueryController.text.trim();
    if (query.isEmpty) return;

    try {
      setState(() {
        _logs.add('🔗 Performing advanced fusion for: $query');
      });

      // Get sample chunks for fusion
      final chunks = [
        ContextChunk(
          id: 'fusion_001',
          content:
              'Flutter is Google\'s UI toolkit for building beautiful applications.',
          source: ContextSource(
            name: 'flutter_docs',
            url: 'https://flutter.dev',
            authorityScore: 0.95,
            lastUpdated: DateTime.now(),
            sourceType: SourceType.document,
          ),
          tags: ['flutter', 'ui', 'google'],
          metadata: {'content_type': 'overview'},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        ContextChunk(
          id: 'fusion_002',
          content: 'Flutter provides widgets for building user interfaces.',
          source: ContextSource(
            name: 'flutter_widgets',
            url: 'https://flutter.dev/widgets',
            authorityScore: 0.85,
            lastUpdated: DateTime.now(),
            sourceType: SourceType.document,
          ),
          tags: ['flutter', 'widgets', 'ui'],
          metadata: {'content_type': 'tutorial'},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      // Perform advanced fusion
      final results = await _ragify!.performAdvancedFusion(
        chunks: chunks,
        query: query,
        userId: _userIdController.text.isEmpty ? null : _userIdController.text,
      );

      setState(() {
        _fusionResults = results;
        _logs.add(
          '✅ Advanced fusion completed. Fused ${results.length} chunks',
        );
      });
    } catch (e) {
      setState(() {
        _logs.add('❌ Advanced fusion failed: $e');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('RAGify Advanced Features'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Status'),
            Tab(text: 'Advanced Scoring'),
            Tab(text: 'Advanced Fusion'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Status Tab
          _buildStatusTab(),

          // Advanced Scoring Tab
          _buildAdvancedScoringTab(),

          // Advanced Fusion Tab
          _buildAdvancedFusionTab(),
        ],
      ),
    );
  }

  Widget _buildStatusTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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

          if (_logs.isNotEmpty) ...[
            Text('System Logs', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    final log = _logs[_logs.length - 1 - index];
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
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAdvancedScoringTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Advanced Scoring',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _userIdController,
                    decoration: const InputDecoration(
                      labelText: 'User ID',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _scoringQueryController,
                          decoration: const InputDecoration(
                            labelText: 'Query for scoring',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _isInitialized
                            ? _performAdvancedScoring
                            : null,
                        child: const Text('Score'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          if (_lastScore != null) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Scoring Results',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text('Score: ${_lastScore!.score.toStringAsFixed(3)}'),
                    Text(
                      'Confidence: ${(_lastScore!.confidenceLevel * 100).toStringAsFixed(1)}%',
                    ),
                    if (_lastScore!.confidenceLower != null)
                      Text(
                        'Range: ${_lastScore!.confidenceLower!.toStringAsFixed(3)} - ${_lastScore!.confidenceUpper?.toStringAsFixed(3) ?? 'N/A'}',
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAdvancedFusionTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Advanced Fusion',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _fusionQueryController,
                          decoration: const InputDecoration(
                            labelText: 'Query for fusion',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _isInitialized
                            ? _performAdvancedFusion
                            : null,
                        child: const Text('Fuse'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          if (_fusionResults.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Fusion Results (${_fusionResults.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _fusionResults.length,
                itemBuilder: (context, index) {
                  final result = _fusionResults[index];
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
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
