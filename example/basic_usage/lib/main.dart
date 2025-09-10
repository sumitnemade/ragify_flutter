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

class _RAGifyBasicUsagePageState extends State<RAGifyBasicUsagePage>
    with TickerProviderStateMixin {
  late RAGify _ragify;
  bool _isInitialized = false;
  String _status = 'Not initialized';
  final List<String> _logs = [];
  final TextEditingController _queryController = TextEditingController();
  List<ContextChunk> _searchResults = [];

  // Context testing - simplified to essentials
  final TextEditingController _contextQueryController = TextEditingController();
  final TextEditingController _contextPromptController =
      TextEditingController();
  final TextEditingController _maxChunksController = TextEditingController(
    text: '3',
  );
  final TextEditingController _minRelevanceController = TextEditingController(
    text: '0.1',
  );
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _sessionIdController = TextEditingController();
  String _contextResponse = '';
  bool _isLoadingContext = false;
  PrivacyLevel _privacyLevel = PrivacyLevel.public;
  bool _useCache = false;

  // Data Source management
  final TextEditingController _dataSourceNameController =
      TextEditingController();
  final TextEditingController _dataSourceUrlController =
      TextEditingController();
  final List<String> _dataSourceNames = [];
  bool _isLoadingDataSource = false;

  // Data Source Context testing
  final TextEditingController _dataSourceQueryController =
      TextEditingController();
  String _dataSourceContextResponse = '';
  bool _isLoadingDataSourceContext = false;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeRAGify();
  }

  @override
  void dispose() {
    _ragify.close();
    _queryController.dispose();
    _contextQueryController.dispose();
    _contextPromptController.dispose();
    _maxChunksController.dispose();
    _minRelevanceController.dispose();
    _userIdController.dispose();
    _sessionIdController.dispose();
    _dataSourceNameController.dispose();
    _dataSourceUrlController.dispose();
    _dataSourceQueryController.dispose();
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
      await _ragify.initialize();

      // Add sample data source
      final documentSource = DocumentSource(
        name: 'sample_documents',
        documentPath: '/sample_docs',
      );
      _ragify.addDataSource(documentSource);

      // Add sample content
      await _addSampleContent();

      // Clear cache to ensure fresh results
      // Note: Cache clearing is handled internally by RAGify

      setState(() {
        _isInitialized = true;
        _status = 'Ready';
        _logs.add('✅ RAGify initialized successfully!');
        _logs.add('📊 Added sample data source');
        _logs.add('🗑️ Cache cleared for fresh results');
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
        _logs.add('❌ Initialization failed: $e');
      });
    }
  }

  Future<void> _addSampleContent() async {
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

      // Store chunks using RAGify's built-in method that generates proper embeddings
      await _ragify.storeChunks(sampleChunks);

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
    if (!_isInitialized) return;

    final query = _queryController.text.trim();
    if (query.isEmpty) return;

    try {
      setState(() {
        _logs.add('🔍 Searching for: $query');
      });

      // Perform vector search
      final results = await _ragify.searchSimilarChunks(query, 5);

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

  Future<void> _getContext() async {
    if (!_isInitialized) return;

    final query = _contextQueryController.text.trim();
    final prompt = _contextPromptController.text.trim();

    if (query.isEmpty) return;

    try {
      setState(() {
        _isLoadingContext = true;
        _contextResponse = '';
        _logs.add('🧠 Getting context for: $query');
      });

      // Get context using RAGify's simplified getContext method
      _logs.add('🔍 Searching for: "$query"');
      _logs.add('📊 Query length: ${query.length} characters');

      // Parse essential parameters from UI
      final userId = _userIdController.text.trim().isEmpty
          ? null
          : _userIdController.text.trim();
      final sessionId = _sessionIdController.text.trim().isEmpty
          ? null
          : _sessionIdController.text.trim();
      final maxChunks = int.tryParse(_maxChunksController.text) ?? 3;
      final minRelevance = double.tryParse(_minRelevanceController.text) ?? 0.1;

      _logs.add(
        '⚙️ Essential Parameters: maxChunks=$maxChunks, minRelevance=$minRelevance, useCache=$_useCache',
      );
      _logs.add('⚙️ Privacy: $_privacyLevel');
      if (userId != null) _logs.add('👤 User ID: $userId');
      if (sessionId != null) _logs.add('🔗 Session ID: $sessionId');

      final contextResponse = await _ragify.getContext(
        query: query,
        maxChunks: maxChunks,
        minRelevance: minRelevance,
        useCache: _useCache,
        userId: userId,
        sessionId: sessionId,
        privacyLevel: _privacyLevel,
      );

      _logs.add('📋 Found ${contextResponse.chunks.length} chunks');

      // Generate a simple response from the chunks
      String response = '';
      if (contextResponse.chunks.isNotEmpty) {
        response = 'Based on the available information:\n\n';
        for (int i = 0; i < contextResponse.chunks.length; i++) {
          final chunk = contextResponse.chunks[i];
          response += '${i + 1}. ${chunk.content}\n';
          response += '   Source: ${chunk.source.name}\n';
          response +=
              '   Relevance: ${chunk.relevanceScore?.score.toStringAsFixed(3) ?? 'N/A'}\n\n';
        }

        if (prompt.isNotEmpty) {
          response += 'Custom prompt: $prompt\n\n';
        }

        response += 'Total chunks found: ${contextResponse.chunks.length}';
      } else {
        response = 'No relevant context found for your query.';
      }

      setState(() {
        _contextResponse = response;
        _isLoadingContext = false;
        _logs.add('✅ Context generated successfully');
        _logs.add('📊 Found ${contextResponse.chunks.length} relevant chunks');
      });
    } catch (e) {
      setState(() {
        _isLoadingContext = false;
        _contextResponse = 'Error: $e';
        _logs.add('❌ Context generation failed: $e');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('RAGify Basic Usage'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.search), text: 'Search'),
            Tab(icon: Icon(Icons.psychology), text: 'Context'),
            Tab(icon: Icon(Icons.storage), text: 'Data Sources'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Search Tab
          _buildSearchTab(),
          // Context Tab
          _buildContextTab(),
          // Data Sources Tab
          _buildDataSourcesTab(),
        ],
      ),
    );
  }

  Widget _buildSearchTab() {
    return Padding(
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

          // Results and Logs Section - Use Expanded to prevent overflow
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                              'Score: ${result.relevanceScore?.score.toStringAsFixed(3) ?? 'N/A'}',
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
                  Expanded(
                    flex: _searchResults.isNotEmpty ? 1 : 3,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          final log =
                              _logs[_logs.length -
                                  1 -
                                  index]; // Show newest first
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              log,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(fontFamily: 'monospace'),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContextTab() {
    return Padding(
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

          // Expanded scrollable content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Essential Parameters Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Essential Parameters',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),

                          // Query
                          Text(
                            'Query *',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          TextField(
                            controller: _contextQueryController,
                            decoration: const InputDecoration(
                              hintText: 'What would you like to know about?',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 12),

                          // Search Parameters
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Max Chunks',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleSmall,
                                    ),
                                    const SizedBox(height: 4),
                                    TextField(
                                      controller: _maxChunksController,
                                      decoration: const InputDecoration(
                                        hintText: '3',
                                        border: OutlineInputBorder(),
                                      ),
                                      keyboardType: TextInputType.number,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Min Relevance',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleSmall,
                                    ),
                                    const SizedBox(height: 4),
                                    TextField(
                                      controller: _minRelevanceController,
                                      decoration: const InputDecoration(
                                        hintText: '0.1',
                                        border: OutlineInputBorder(),
                                      ),
                                      keyboardType: TextInputType.number,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Privacy Level
                          Text(
                            'Privacy Level',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          DropdownButtonFormField<PrivacyLevel>(
                            value: _privacyLevel,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                            items: PrivacyLevel.values.map((level) {
                              return DropdownMenuItem(
                                value: level,
                                child: Text(level.toString().split('.').last),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _privacyLevel = value;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Enterprise Features Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Enterprise Features (Optional)',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),

                          Text(
                            'User ID',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          TextField(
                            controller: _userIdController,
                            decoration: const InputDecoration(
                              hintText: 'user123',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),

                          Text(
                            'Session ID',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          TextField(
                            controller: _sessionIdController,
                            decoration: const InputDecoration(
                              hintText: 'session456',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Options Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Options',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),

                          CheckboxListTile(
                            title: const Text('Use Cache'),
                            subtitle: const Text(
                              'Use cached results if available',
                            ),
                            value: _useCache,
                            onChanged: (value) {
                              setState(() {
                                _useCache = value ?? false;
                              });
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Custom Prompt Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Custom Prompt (Optional)',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _contextPromptController,
                            decoration: const InputDecoration(
                              hintText: 'Customize how the AI responds...',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Get Context Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isInitialized && !_isLoadingContext
                          ? _getContext
                          : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoadingContext
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text('Generating Context...'),
                              ],
                            )
                          : const Text(
                              'Get Context',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Context Response Section
                  if (_contextResponse.isNotEmpty) ...[
                    Text(
                      'AI Response',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          _contextResponse,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Logs Section
                  if (_logs.isNotEmpty) ...[
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
                              _logs[_logs.length -
                                  1 -
                                  index]; // Show newest first
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              log,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(fontFamily: 'monospace'),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addDataSource() async {
    final name = _dataSourceNameController.text.trim();
    final url = _dataSourceUrlController.text.trim();

    if (name.isEmpty || url.isEmpty) {
      _logs.add('❌ Error: Both name and URL are required');
      setState(() {});
      return;
    }

    if (_dataSourceNames.contains(name)) {
      _logs.add('❌ Error: Data source "$name" already exists');
      setState(() {});
      return;
    }

    setState(() {
      _isLoadingDataSource = true;
    });

    try {
      // Create super powerful API data source for HTTP URLs
      if (url.startsWith('http://') || url.startsWith('https://')) {
        final dataSource = APISource(
          name: name,
          baseUrl: url,
          httpMethod: 'GET',
          authHeaders: {'Content-Type': 'application/json'},
        );
        _ragify.addDataSource(dataSource);
      } else {
        _logs.add('❌ Error: Only HTTP/HTTPS URLs are supported');
        setState(() {});
        return;
      }

      setState(() {
        _dataSourceNames.add(name);
        _dataSourceNameController.clear();
        _dataSourceUrlController.clear();
      });

      _logs.add('✅ Added data source: $name');
    } catch (e) {
      _logs.add('❌ Error adding data source: $e');
    } finally {
      setState(() {
        _isLoadingDataSource = false;
      });
    }
  }

  void _removeDataSource(String name) {
    try {
      _ragify.removeDataSource(name);

      setState(() {
        _dataSourceNames.remove(name);
      });

      _logs.add('✅ Removed data source: $name');
    } catch (e) {
      _logs.add('❌ Error removing data source: $e');
    }
  }

  Future<void> _getDataSourceContext() async {
    final query = _dataSourceQueryController.text.trim();

    if (query.isEmpty) {
      _logs.add('❌ Error: Query is required');
      setState(() {});
      return;
    }

    if (_dataSourceNames.isEmpty) {
      _logs.add('❌ Error: No data sources available. Add a data source first.');
      setState(() {});
      return;
    }

    setState(() {
      _isLoadingDataSourceContext = true;
    });

    try {
      _logs.add('🔍 Getting context from data sources for query: "$query"');

      final response = await _ragify.getContext(
        query: query,
        maxChunks: 10,
        minRelevance: 0.1,
        useCache: false,
        userId: 'test_user',
        sessionId: 'test_session',
        privacyLevel: PrivacyLevel.public,
      );

      setState(() {
        _dataSourceContextResponse = response.chunks
            .map(
              (chunk) =>
                  'Source: ${chunk.source.name}\n'
                  'Content: ${chunk.content}\n'
                  'Relevance: ${chunk.relevanceScore?.score.toStringAsFixed(3) ?? 'N/A'}\n'
                  '---',
            )
            .join('\n\n');
      });

      _logs.add(
        '✅ Retrieved ${response.chunks.length} context chunks from data sources',
      );
    } catch (e) {
      _logs.add('❌ Error getting context from data sources: $e');
      setState(() {
        _dataSourceContextResponse = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoadingDataSourceContext = false;
      });
    }
  }

  Widget _buildDataSourcesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Data Source Management',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),

          // Add Data Source Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add Data Source',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _dataSourceNameController,
                    decoration: const InputDecoration(
                      labelText: 'Data Source Name',
                      hintText: 'e.g., my_database',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _dataSourceUrlController,
                    decoration: const InputDecoration(
                      labelText: 'Data Source URL',
                      hintText: 'e.g., sqlite://path/to/database.db',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isLoadingDataSource ? null : _addDataSource,
                    child: _isLoadingDataSource
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Add Data Source'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Current Data Sources Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Data Sources (${_dataSourceNames.length})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  if (_dataSourceNames.isEmpty)
                    const Text(
                      'No data sources added yet.',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    )
                  else
                    ..._dataSourceNames.map(
                      (name) => Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: const Icon(Icons.storage),
                          title: Text(name),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeDataSource(name),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Get Context from Data Sources Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Get Context from Data Sources',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _dataSourceQueryController,
                    decoration: const InputDecoration(
                      labelText: 'Query',
                      hintText: 'e.g., test query',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isLoadingDataSourceContext
                        ? null
                        : _getDataSourceContext,
                    child: _isLoadingDataSourceContext
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Get Context'),
                  ),
                  if (_dataSourceContextResponse.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Context Response:',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _dataSourceContextResponse,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Logs Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Data Source Logs',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
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
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            _logs[_logs.length - 1 - index],
                            // Show newest first
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(fontFamily: 'monospace'),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
