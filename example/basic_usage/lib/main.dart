import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
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
  String _selectedHttpMethod = 'GET';
  bool _appendQueryEndpoint = false;
  bool _useCustomRequest = false;
  bool _includeQuery = false;
  bool _includeTimestamp = false;
  bool _includeUserId = false;
  bool _includeSessionId = false;
  final TextEditingController _requestTemplateController =
      TextEditingController();

  // Data Source Context testing
  final TextEditingController _dataSourceQueryController =
      TextEditingController();
  String _dataSourceContextResponse = '';

  // Document Sources
  final TextEditingController _documentPathController = TextEditingController();
  final TextEditingController _documentUrlController = TextEditingController();
  final TextEditingController _documentQueryController =
      TextEditingController();
  final List<String> _documentSourceNames = [];
  bool _isLoadingDocument = false;
  String _documentContextResponse = '';
  int _chunkSize = 1000;
  bool _enableMetadata = true;
  String _documentSourceType = 'url'; // 'url' or 'local'
  PlatformFile? _selectedFile;
  bool _isLoadingDataSourceContext = false;

  /// Holds the last fetched document chunks for rendering in UI
  List<ContextChunk> _documentChunks = [];

  // Database testing variables
  String _selectedDatabaseType = 'postgresql';
  final TextEditingController _dbHostController = TextEditingController(
    text: '192.168.1.16', // Use host machine IP for mobile emulator
  );
  final TextEditingController _dbPortController = TextEditingController(
    text: '5432',
  );
  final TextEditingController _dbNameController = TextEditingController(
    text: 'test_db',
  );
  final TextEditingController _dbUsernameController = TextEditingController(
    text: 'test_user',
  );
  final TextEditingController _dbPasswordController = TextEditingController(
    text: 'test_pass',
  );
  final TextEditingController _dbQueryController = TextEditingController();
  final TextEditingController _dbQueryParamsController = TextEditingController(
    text: '%john%',
  );
  bool _isTestingDatabase = false;
  String _databaseTestResult = '';
  List<ContextChunk> _databaseChunks = [];

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _initializeRAGify();
    _updateDefaultQuery();
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
      _ragify = RAGify(enableLogging: true);

      // Initialize all components
      await _ragify.initialize();

      // Add sample data source
      final documentSource = DocumentSource(
        name: 'sample_documents',
        documentPath: '/sample_docs',
        ragifyLogger: _ragify.logger,
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
            Tab(icon: Icon(Icons.description), text: 'Documents'),
            Tab(icon: Icon(Icons.storage), text: 'Database'),
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
          // Document Sources Tab
          _buildDocumentSourcesTab(),
          // Database Tab
          _buildDatabaseTab(),
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
        // Parse custom request template if provided
        Map<String, dynamic>? requestTemplate;
        if (_useCustomRequest && _requestTemplateController.text.isNotEmpty) {
          try {
            requestTemplate = Map<String, dynamic>.from(
              jsonDecode(_requestTemplateController.text),
            );
          } catch (e) {
            _logs.add('❌ Error: Invalid JSON in request template: $e');
            setState(() {});
            return;
          }
        }

        final dataSource = APISource(
          name: name,
          baseUrl: url,
          httpMethod: _selectedHttpMethod,
          authHeaders: {'Content-Type': 'application/json'},
          config: {
            'append_query_endpoint': _appendQueryEndpoint,
            'use_custom_request': _useCustomRequest,
            if (requestTemplate != null) 'request_template': requestTemplate,
            if (!_useCustomRequest) ...{
              'include_query': _includeQuery,
              'include_timestamp': _includeTimestamp,
              'include_user_id': _includeUserId,
              'include_session_id': _includeSessionId,
            },
          },
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

      _logs.add('✅ Added data source: $name ($_selectedHttpMethod)');
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
                      hintText:
                          'e.g., https://jsonplaceholder.typicode.com/posts',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // HTTP Method Selection
                  DropdownButtonFormField<String>(
                    value: _selectedHttpMethod,
                    decoration: const InputDecoration(
                      labelText: 'HTTP Method',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'GET', child: Text('GET')),
                      DropdownMenuItem(value: 'POST', child: Text('POST')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedHttpMethod = value ?? 'GET';
                        // Update URL based on method
                        if (_selectedHttpMethod == 'POST') {
                          _dataSourceUrlController.text =
                              'https://httpbin.org/post';
                        } else {
                          _dataSourceUrlController.text =
                              'https://jsonplaceholder.typicode.com/posts';
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Advanced Options
                  CheckboxListTile(
                    title: const Text('Append /query endpoint'),
                    subtitle: const Text(
                      'Only for query-based APIs that need /query suffix',
                    ),
                    value: _appendQueryEndpoint,
                    onChanged: (value) {
                      setState(() {
                        _appendQueryEndpoint = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  CheckboxListTile(
                    title: const Text('Use custom request template'),
                    subtitle: const Text('Full control over API request body'),
                    value: _useCustomRequest,
                    onChanged: (value) {
                      setState(() {
                        _useCustomRequest = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  if (!_useCustomRequest) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Optional fields (only added if enabled):',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    CheckboxListTile(
                      title: const Text('Include query field'),
                      subtitle: const Text('Add "query" field to request'),
                      value: _includeQuery,
                      onChanged: (value) {
                        setState(() {
                          _includeQuery = value ?? false;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    CheckboxListTile(
                      title: const Text('Include timestamp field'),
                      subtitle: const Text('Add "timestamp" field to request'),
                      value: _includeTimestamp,
                      onChanged: (value) {
                        setState(() {
                          _includeTimestamp = value ?? false;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    CheckboxListTile(
                      title: const Text('Include user_id field'),
                      subtitle: const Text('Add "user_id" field to request'),
                      value: _includeUserId,
                      onChanged: (value) {
                        setState(() {
                          _includeUserId = value ?? false;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    CheckboxListTile(
                      title: const Text('Include session_id field'),
                      subtitle: const Text('Add "session_id" field to request'),
                      value: _includeSessionId,
                      onChanged: (value) {
                        setState(() {
                          _includeSessionId = value ?? false;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ],
                  if (_useCustomRequest) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: _requestTemplateController,
                      decoration: const InputDecoration(
                        labelText: 'Request Template (JSON)',
                        hintText: '{"search": "{{query}}", "limit": 10}',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Use {{query}} as placeholder for the search query',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            _requestTemplateController.text =
                                '{"search": "{{query}}", "limit": 10}';
                          },
                          child: const Text('Simple Search'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            _requestTemplateController.text =
                                '{"query": "{{query}}", "filters": {"type": "all"}}';
                          },
                          child: const Text('With Filters'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            _requestTemplateController.text =
                                '{"text": "{{query}}", "max_results": 5}';
                          },
                          child: const Text('Custom Fields'),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Quick URL Presets
                  Text(
                    'Quick Presets:',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectedHttpMethod = 'GET';
                            _dataSourceUrlController.text =
                                'https://jsonplaceholder.typicode.com/posts';
                          });
                        },
                        child: const Text('JSONPlaceholder (GET)'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectedHttpMethod = 'POST';
                            _dataSourceUrlController.text =
                                'https://httpbin.org/post';
                          });
                        },
                        child: const Text('HTTPBin (POST)'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectedHttpMethod = 'POST';
                            _dataSourceUrlController.text =
                                'https://reqres.in/api/users';
                          });
                        },
                        child: const Text('ReqRes (POST)'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectedHttpMethod = 'POST';
                            _dataSourceUrlController.text =
                                'https://api.example.com/search';
                          });
                        },
                        child: const Text('Custom Query API'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• JSONPlaceholder: Returns sample blog posts (GET)\n'
                    '• HTTPBin: Echoes back your request data (POST)\n'
                    '• ReqRes: User management API (POST)\n'
                    '• Custom Query API: Example for query-based APIs',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Text(
                      '💡 Note: Most APIs use the base URL directly. Only query-based APIs need /query endpoint (configured automatically).',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.blue[800]),
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

  Widget _buildDocumentSourcesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Document Sources Management
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Document Sources Management',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),

                  // Add Document Source
                  Text(
                    'Add Document Source:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),

                  // Document Source Type Selection
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Web URL'),
                          subtitle: const Text('HTTP/HTTPS document'),
                          value: 'url',
                          groupValue: _documentSourceType,
                          onChanged: (value) {
                            setState(() {
                              _documentSourceType = value!;
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Local File'),
                          subtitle: const Text('File upload (web limited)'),
                          value: 'local',
                          groupValue: _documentSourceType,
                          onChanged: (value) {
                            setState(() {
                              _documentSourceType = value!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Document Input based on type
                  if (_documentSourceType == 'url') ...[
                    TextField(
                      controller: _documentUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Document URL',
                        hintText: 'https://example.com/document.pdf',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.link),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'DocumentSource will download and process the document from the URL',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.blue[700],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ] else ...[
                    // File picker section
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _documentPathController,
                            decoration: const InputDecoration(
                              labelText: 'Selected File',
                              hintText: 'No file selected',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.folder),
                            ),
                            readOnly: true,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _pickFile,
                          icon: const Icon(Icons.file_upload),
                          label: const Text('Pick File'),
                        ),
                      ],
                    ),
                    if (_selectedFile != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          border: Border.all(color: Colors.green[200]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green[600],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedFile!.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${(_selectedFile!.size / 1024).toStringAsFixed(1)} KB',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _selectedFile = null;
                                  _documentPathController.clear();
                                });
                              },
                              icon: const Icon(Icons.close, size: 20),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'Select a document file from your device to add as a source.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.blue[700],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Document Configuration
                  Text(
                    'Document Configuration:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: 'Chunk Size',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            _chunkSize = int.tryParse(value) ?? 1000;
                          },
                          controller: TextEditingController(
                            text: _chunkSize.toString(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: CheckboxListTile(
                          title: const Text('Enable Metadata'),
                          value: _enableMetadata,
                          onChanged: (value) {
                            setState(() {
                              _enableMetadata = value ?? true;
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Quick Presets
                  Text(
                    'Quick Presets:',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (_documentSourceType == 'url') ...[
                        ElevatedButton(
                          onPressed: () {
                            _documentUrlController.text =
                                'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf';
                          },
                          child: const Text('Sample PDF URL'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            _documentUrlController.text =
                                'https://raw.githubusercontent.com/microsoft/vscode/main/README.md';
                          },
                          child: const Text('Sample Markdown URL'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            _documentUrlController.text =
                                'https://www.gutenberg.org/files/1342/1342-0.txt';
                          },
                          child: const Text('Sample Text URL'),
                        ),
                      ] else ...[
                        ElevatedButton.icon(
                          onPressed: _pickFile,
                          icon: const Icon(Icons.file_upload),
                          label: const Text('Pick PDF File'),
                        ),
                        ElevatedButton.icon(
                          onPressed: _pickFile,
                          icon: const Icon(Icons.file_upload),
                          label: const Text('Pick Text File'),
                        ),
                        ElevatedButton.icon(
                          onPressed: _pickFile,
                          icon: const Icon(Icons.file_upload),
                          label: const Text('Pick Any File'),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),

                  ElevatedButton(
                    onPressed: _addDocumentSource,
                    child: _isLoadingDocument
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Add Document Source'),
                  ),
                  const SizedBox(height: 16),

                  // Document Sources List
                  Text(
                    'Active Document Sources:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (_documentSourceNames.isEmpty)
                    const Text('No document sources added yet')
                  else
                    ..._documentSourceNames.map(
                      (name) => Card(
                        child: ListTile(
                          leading: Icon(
                            _documentSourceType == 'url'
                                ? Icons.link
                                : Icons.description,
                          ),
                          title: Text(name),
                          subtitle: Text(
                            _documentSourceType == 'url'
                                ? 'Web URL Document'
                                : 'Local File Document',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _removeDocumentSource(name),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Document Context Testing
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Test Document Context',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _documentQueryController,
                    decoration: const InputDecoration(
                      labelText: 'Search Query',
                      hintText: 'Enter search query for document sources',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _getDocumentContext,
                          child: _isLoadingDocument
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Get Context from Documents'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _clearDocumentCache,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Clear Cache'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (_documentContextResponse.isNotEmpty) ...[
                    Text(
                      'Document Context Response:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: Text(
                        _documentContextResponse,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_documentChunks.isNotEmpty) ...[
                      Text(
                        'Top Chunks (${_documentChunks.length}):',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      ..._documentChunks.map(
                        (chunk) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  chunk.source.name,
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  chunk.content,
                                  maxLines: 10,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Relevance: ${chunk.relevanceScore?.score.toStringAsFixed(3) ?? 'N/A'}',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                    if (chunk.tags.isNotEmpty)
                                      Text(
                                        'Tags: ${chunk.tags.join(', ')}',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Document Source Logs
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Document Source Logs',
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

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'txt', 'md', 'docx', 'doc'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() {
          _selectedFile = file;
          _documentPathController.text = file.name;
        });

        _logs.add('📁 File selected: ${file.name}');
        _logs.add('📊 File size: ${(file.size / 1024).toStringAsFixed(1)} KB');
        _logs.add('📄 File extension: ${file.extension}');
      }
    } catch (e) {
      _logs.add('❌ Error picking file: $e');
    }
  }

  Future<void> _addDocumentSource() async {
    String path;
    String sourceType;

    if (_documentSourceType == 'url') {
      path = _documentUrlController.text.trim();
      sourceType = 'Web URL';
      if (path.isEmpty) {
        _logs.add('❌ Error: Document URL cannot be empty');
        setState(() {});
        return;
      }
    } else {
      if (_selectedFile == null) {
        _logs.add('❌ Error: Please select a file first');
        setState(() {});
        return;
      }
      path = _selectedFile!.path ?? _selectedFile!.name;
      sourceType = 'Local File';
    }

    setState(() {
      _isLoadingDocument = true;
    });

    try {
      final name = 'Document_${_documentSourceNames.length + 1}';

      // Create DocumentSource
      final documentSource = DocumentSource(
        name: name,
        documentPath: path,
        config: {
          'chunkSize': _chunkSize,
          'enableMetadata': _enableMetadata,
          'supportedFormats': ['pdf', 'txt', 'md', 'docx'],
          'sourceType': _documentSourceType,
        },
      );

      _ragify.addDataSource(documentSource);
      _documentSourceNames.add(name);

      _logs.add('✅ Added document source: $name');
      _logs.add('📁 $sourceType: $path');
      _logs.add('📊 Chunk size: $_chunkSize');
      _logs.add('🔍 Metadata enabled: $_enableMetadata');
      _logs.add('🌐 Source type: $_documentSourceType');

      // Clear the appropriate controller and file
      if (_documentSourceType == 'url') {
        _documentUrlController.clear();
      } else {
        _documentPathController.clear();
        _selectedFile = null;
      }
    } catch (e) {
      _logs.add('❌ Error adding document source: $e');
    } finally {
      setState(() {
        _isLoadingDocument = false;
      });
    }
  }

  void _removeDocumentSource(String name) {
    try {
      _ragify.removeDataSource(name);
      _documentSourceNames.remove(name);
      _logs.add('🗑️ Removed document source: $name');
    } catch (e) {
      _logs.add('❌ Error removing document source: $e');
    }
    setState(() {});
  }

  Future<void> _getDocumentContext() async {
    if (!_isInitialized) return;

    final query = _documentQueryController.text.trim();
    if (query.isEmpty) {
      _logs.add('❌ Error: Query cannot be empty');
      setState(() {});
      return;
    }

    if (_documentSourceNames.isEmpty) {
      _logs.add('❌ Error: No document sources available');
      setState(() {});
      return;
    }

    setState(() {
      _isLoadingDocument = true;
      _documentContextResponse = '';
    });

    try {
      _logs.add('📄 Getting context from document sources...');
      _logs.add('🔍 Query: $query');
      _logs.add('📚 Available sources: ${_documentSourceNames.join(', ')}');

      // Get context using RAGify's getContext method
      final response = await _ragify.getContext(
        query: query,
        maxChunks: 5,
        minRelevance: 0.1,
        useCache: false,
        userId: 'test_user',
        sessionId: 'test_session',
        privacyLevel: PrivacyLevel.public,
      );

      setState(() {
        _documentContextResponse = response.toString();
        _documentChunks = response.chunks;
      });

      _logs.add('✅ Document context retrieved successfully');
      _logs.add('📊 Found ${response.chunks.length} relevant chunks');

      for (int i = 0; i < response.chunks.length; i++) {
        final chunk = response.chunks[i];
        _logs.add('📄 Chunk ${i + 1}: ${chunk.content.substring(0, 50)}...');
        _logs.add(
          '📊 Relevance: ${chunk.relevanceScore?.score.toStringAsFixed(3) ?? 'N/A'}',
        );
        _logs.add('📁 Source: ${chunk.source.name}');
      }
    } catch (e) {
      _logs.add('❌ Error getting document context: $e');
      setState(() {
        _documentContextResponse = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoadingDocument = false;
      });
    }
  }

  /// Clear document cache to force reprocessing
  Future<void> _clearDocumentCache() async {
    if (!_isInitialized) return;

    try {
      _logs.add('🗑️ Clearing document cache...');

      // Clear cache for all document sources
      for (final sourceName in _documentSourceNames) {
        final source = _ragify.getDataSource(sourceName);
        if (source is DocumentSource) {
          source.clearCache();
        }
      }

      // Clear the response display
      setState(() {
        _documentContextResponse = '';
        _documentChunks = [];
      });

      _logs.add('✅ Document cache cleared successfully');
      _logs.add('🔄 Next search will process documents fresh');
    } catch (e) {
      _logs.add('❌ Error clearing document cache: $e');
    }
  }

  /// Build the Database testing tab
  Widget _buildDatabaseTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Database Source Testing',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Database Type Selection
          const Text(
            'Database Type:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          DropdownButton<String>(
            value: _selectedDatabaseType,
            isExpanded: true,
            items: const [
              DropdownMenuItem(value: 'sqlite', child: Text('SQLite')),
              DropdownMenuItem(value: 'postgresql', child: Text('PostgreSQL')),
              DropdownMenuItem(value: 'mysql', child: Text('MySQL')),
              DropdownMenuItem(value: 'mongodb', child: Text('MongoDB')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedDatabaseType = value!;
                // Update default port and database name based on database type
                switch (value) {
                  case 'postgresql':
                    _dbHostController.text =
                        '192.168.1.16'; // Use host machine IP for mobile
                    _dbPortController.text = '5432';
                    _dbNameController.text = 'test_db';
                    break;
                  case 'mysql':
                    _dbHostController.text =
                        '192.168.1.16'; // Use host machine IP for mobile
                    _dbPortController.text = '3306';
                    _dbNameController.text = 'test_db';
                    break;
                  case 'mongodb':
                    _dbHostController.text =
                        '192.168.1.16'; // Use host machine IP for mobile
                    _dbPortController.text = '27017';
                    _dbNameController.text = 'test_db';
                    break;
                  case 'sqlite':
                    _dbHostController.text =
                        'localhost'; // SQLite doesn't need network
                    _dbPortController.text = '';
                    _dbNameController.text = 'assets/test.db';
                    break;
                }
                // Update default query syntax based on database type
                _updateDefaultQuery();
              });
            },
          ),
          const SizedBox(height: 16),

          // SQLite Assets Database Note
          if (_selectedDatabaseType == 'sqlite') ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📁 Assets Database Ready!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'The app includes a pre-loaded SQLite database with sample data:\n'
                    '• 8 users with departments and salaries\n'
                    '• 8 products with categories and prices\n'
                    '• 9 orders with user-product relationships\n'
                    '• Ready-to-test queries and parameters',
                    style: TextStyle(fontSize: 12, color: Colors.blue),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Connection Configuration
          const Text(
            'Connection Configuration:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),

          if (_selectedDatabaseType != 'sqlite') ...[
            TextField(
              controller: _dbHostController,
              decoration: const InputDecoration(
                labelText: 'Host',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _dbPortController,
              decoration: const InputDecoration(
                labelText: 'Port',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
          ],

          TextField(
            controller: _dbNameController,
            decoration: const InputDecoration(
              labelText: 'Database Name/Path',
              hintText: 'assets/test.db for SQLite',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),

          if (_selectedDatabaseType != 'sqlite') ...[
            TextField(
              controller: _dbUsernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _dbPasswordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
          ],

          // Query Configuration
          const Text(
            'Query Configuration:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),

          TextField(
            controller: _dbQueryController,
            decoration: const InputDecoration(
              labelText: 'SQL Query',
              border: OutlineInputBorder(),
              hintText: 'SELECT * FROM table WHERE column = ?',
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 8),

          TextField(
            controller: _dbQueryParamsController,
            decoration: const InputDecoration(
              labelText: 'Query Parameters (comma-separated)',
              border: OutlineInputBorder(),
              hintText: 'value1, value2, value3',
            ),
          ),
          const SizedBox(height: 16),

          // Sample Query Buttons (only for SQLite)
          if (_selectedDatabaseType == 'sqlite') ...[
            const Text(
              'Sample Queries:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () {
                    if (_selectedDatabaseType == 'mongodb') {
                      _setSampleQuery(
                        '{"name": {"\$regex": ?, "\$options": "i"}}',
                        'john',
                      );
                    } else {
                      _setSampleQuery(
                        'SELECT * FROM users WHERE name ${_selectedDatabaseType == 'postgresql' ? 'ILIKE' : 'LIKE'} ${_getParameterPlaceholder(0)}',
                        '%john%',
                      );
                    }
                  },
                  child: const Text('Find John'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_selectedDatabaseType == 'mongodb') {
                      _setSampleQuery('{"department": ?}', 'Engineering');
                    } else {
                      _setSampleQuery(
                        'SELECT * FROM users WHERE department = ${_getParameterPlaceholder(0)}',
                        'Engineering',
                      );
                    }
                  },
                  child: const Text('Engineering Users'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_selectedDatabaseType == 'mongodb') {
                      _setSampleQuery('{"category": ?}', 'Electronics');
                    } else {
                      _setSampleQuery(
                        'SELECT * FROM products WHERE category = ${_getParameterPlaceholder(0)}',
                        'Electronics',
                      );
                    }
                  },
                  child: const Text('Electronics'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_selectedDatabaseType == 'mongodb') {
                      _setSampleQuery('{"status": ?}', 'completed');
                    } else {
                      _setSampleQuery(
                        'SELECT * FROM orders WHERE status = ${_getParameterPlaceholder(0)}',
                        'completed',
                      );
                    }
                  },
                  child: const Text('Completed Orders'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_selectedDatabaseType == 'mongodb') {
                      _setSampleQuery('{"status": ?}', 'completed');
                    } else {
                      _setSampleQuery(
                        'SELECT u.name, p.name, o.quantity, o.total_amount FROM orders o JOIN users u ON o.user_id = u.id JOIN products p ON o.product_id = p.id WHERE o.status = ${_getParameterPlaceholder(0)}',
                        'completed',
                      );
                    }
                  },
                  child: const Text('Order Details'),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Test Database Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isTestingDatabase
                  ? null
                  : () {
                      // Debug: Button pressed! _isTestingDatabase: $_isTestingDatabase
                      _testDatabaseConnection();
                    },
              child: _isTestingDatabase
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Testing Database...'),
                      ],
                    )
                  : const Text('Test Database Connection'),
            ),
          ),
          const SizedBox(height: 16),

          // Database Test Results
          if (_databaseTestResult.isNotEmpty) ...[
            const Text(
              'Test Results:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _databaseTestResult.contains('✅')
                    ? Colors.green.shade50
                    : Colors.red.shade50,
                border: Border.all(
                  color: _databaseTestResult.contains('✅')
                      ? Colors.green.shade300
                      : Colors.red.shade300,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _databaseTestResult,
                style: TextStyle(
                  color: _databaseTestResult.contains('✅')
                      ? Colors.green.shade800
                      : Colors.red.shade800,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Database Chunks Display
          if (_databaseChunks.isNotEmpty) ...[
            const Text(
              'Retrieved Data:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            ..._databaseChunks.map(
              (chunk) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Source: ${chunk.source.name}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text('Content: ${chunk.content}'),
                      if (chunk.metadata.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Metadata: ${chunk.metadata}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                      if (chunk.relevanceScore != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Relevance: ${chunk.relevanceScore!.score.toStringAsFixed(3)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Help Text
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Database Testing Help:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  '• SQLite: Uses assets/test.db by default (no host/port needed)',
                ),
                const Text('• PostgreSQL: Default port 5432'),
                const Text('• MySQL: Default port 3306'),
                const Text('• MongoDB: Default port 27017'),
                const Text('• Use ? placeholders for parameterized queries'),
                const Text('• Separate multiple parameters with commas'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Copy assets database to writable location
  Future<String> _copyAssetsDatabase(String assetsPath) async {
    try {
      // Get the documents directory
      final documentsDir = await getApplicationDocumentsDirectory();
      final dbName = assetsPath.split('/').last;
      final dbPath = '${documentsDir.path}/$dbName';

      // Check if database already exists
      final dbFile = File(dbPath);
      if (await dbFile.exists()) {
        _logs.add('📁 Database already exists at $dbPath');
        return dbPath;
      }

      // Copy from assets
      final data = await rootBundle.load(assetsPath);
      final bytes = data.buffer.asUint8List();
      await dbFile.writeAsBytes(bytes);

      _logs.add('📁 Copied assets database from $assetsPath to $dbPath');
      return dbPath;
    } catch (e) {
      _logs.add('❌ Failed to copy assets database: $e');
      // Fallback to original path
      return assetsPath;
    }
  }

  /// Test database connection and query
  /// Helper method to get the correct parameter placeholder based on database type
  String _getParameterPlaceholder(int index) {
    if (_selectedDatabaseType == 'sqlite') {
      return '?';
    } else if (_selectedDatabaseType == 'postgresql') {
      return '\$${index + 1}';
    } else if (_selectedDatabaseType == 'mysql') {
      return '?';
    } else if (_selectedDatabaseType == 'mongodb') {
      return '?';
    }
    return '?';
  }

  /// Helper method to set a sample query with correct syntax
  void _setSampleQuery(String query, String params) {
    _dbQueryController.text = query;
    _dbQueryParamsController.text = params;
  }

  /// Update the default query based on selected database type
  void _updateDefaultQuery() {
    if (_selectedDatabaseType == 'postgresql') {
      _dbQueryController.text = 'SELECT * FROM users WHERE name ILIKE \$1';
    } else if (_selectedDatabaseType == 'sqlite') {
      _dbQueryController.text = 'SELECT * FROM users WHERE name LIKE ?';
    } else if (_selectedDatabaseType == 'mysql') {
      _dbQueryController.text = 'SELECT * FROM users WHERE name LIKE ?';
    } else if (_selectedDatabaseType == 'mongodb') {
      _dbQueryController.text =
          '{"name": {"\$regex": "john", "\$options": "i"}}';
    }
  }

  Future<void> _testDatabaseConnection() async {
    // Debug: _testDatabaseConnection() method called
    _logs.add('🚀 _testDatabaseConnection() called');

    if (!_isInitialized) {
      _logs.add('❌ RAGify not initialized');
      setState(() {
        _databaseTestResult = '❌ RAGify not initialized';
      });
      return;
    }

    _logs.add('✅ RAGify is initialized, starting database test');

    setState(() {
      _isTestingDatabase = true;
      _databaseTestResult = '';
      _databaseChunks = [];
    });

    try {
      _logs.add(
        '🔌 Testing ${_selectedDatabaseType.toUpperCase()} database connection...',
      );

      // Handle assets database for SQLite
      String databasePath = _dbNameController.text;
      if (_selectedDatabaseType == 'sqlite' &&
          databasePath.startsWith('assets/')) {
        try {
          _logs.add('📁 Copying assets database...');
          databasePath = await _copyAssetsDatabase(databasePath);
          _logs.add('📁 Copied assets database to: $databasePath');
        } catch (e) {
          _logs.add('❌ Failed to copy assets database: $e');
          rethrow;
        }
      }

      // Create database configuration
      final dbConfig = DatabaseConfig(
        host: _selectedDatabaseType == 'sqlite'
            ? 'localhost'
            : _dbHostController.text,
        port: _selectedDatabaseType == 'sqlite'
            ? 0
            : int.tryParse(_dbPortController.text) ?? 5432,
        database: databasePath,
        username: _selectedDatabaseType == 'sqlite'
            ? 'user'
            : _dbUsernameController.text,
        password: _selectedDatabaseType == 'sqlite'
            ? 'pass'
            : _dbPasswordController.text,
        maxConnections: 5,
        connectionTimeout: const Duration(seconds: 10),
        queryTimeout: const Duration(seconds: 30),
      );

      // Create database source
      final dbSource = DatabaseSource(
        name: 'Test Database',
        sourceType: SourceType.database,
        databaseConfig: dbConfig,
        databaseType: _selectedDatabaseType,
        cacheManager: CacheManager(logger: _ragify.logger),
        logger: _ragify.logger,
      );

      // Add source to RAGify
      _ragify.addDataSource(dbSource);
      _logs.add('✅ Database source added successfully');

      // Initialize database source first
      _logs.add('🔧 Initializing database source...');
      try {
        await dbSource.initialize();
        _logs.add('✅ Database source initialized successfully');
      } catch (e) {
        _logs.add('❌ Database source initialization failed: $e');
        rethrow;
      }

      // Handle parameter substitution based on database type
      String finalQuery = _dbQueryController.text;
      if (_dbQueryParamsController.text.isNotEmpty) {
        final params = _dbQueryParamsController.text
            .split(',')
            .map((param) => param.trim())
            .where((param) => param.isNotEmpty)
            .toList();

        if (_selectedDatabaseType == 'sqlite') {
          // SQLite uses ? placeholders
          for (int i = 0; i < params.length; i++) {
            finalQuery = finalQuery.replaceFirst('?', "'${params[i]}'");
          }
        } else if (_selectedDatabaseType == 'postgresql') {
          // PostgreSQL uses $1, $2, $3... placeholders
          for (int i = 0; i < params.length; i++) {
            finalQuery = finalQuery.replaceFirst(
              '\$${i + 1}',
              "'${params[i]}'",
            );
          }
        } else if (_selectedDatabaseType == 'mysql') {
          // MySQL uses ? placeholders (same as SQLite)
          for (int i = 0; i < params.length; i++) {
            finalQuery = finalQuery.replaceFirst('?', "'${params[i]}'");
          }
        } else if (_selectedDatabaseType == 'mongodb') {
          // MongoDB uses JSON queries - replace placeholders with actual values
          for (int i = 0; i < params.length; i++) {
            finalQuery = finalQuery.replaceFirst('?', '"${params[i]}"');
          }
        }
      }

      _logs.add('🔍 Executing query: $finalQuery');
      _logs.add('📊 Database path: $databasePath');

      // Test query execution
      _logs.add('🚀 Calling dbSource.getChunks()...');
      final chunks = await dbSource.getChunks(
        query: finalQuery,
        maxChunks: 10,
        minRelevance: 0.1,
      );
      _logs.add('✅ dbSource.getChunks() completed');

      _logs.add('📈 Query returned ${chunks.length} chunks');

      setState(() {
        _databaseChunks = chunks;
        _databaseTestResult =
            '✅ Database connection successful! Retrieved ${chunks.length} chunks.';
      });

      _logs.add('✅ Database query executed successfully');
      _logs.add('📊 Retrieved ${chunks.length} data chunks');
    } catch (e) {
      setState(() {
        _databaseTestResult = '❌ Database connection failed: $e';
      });
      _logs.add('❌ Database test failed: $e');
    } finally {
      setState(() {
        _isTestingDatabase = false;
      });
    }
  }
}
