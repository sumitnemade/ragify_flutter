import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:ragify_flutter/src/sources/api_source.dart';
import 'package:ragify_flutter/src/exceptions/ragify_exceptions.dart';

class _FakeHttpClient extends http.BaseClient {
  final Map<String, dynamic Function(http.BaseRequest request, String body)>
  _routes;
  _FakeHttpClient(this._routes);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final completer = Completer<http.StreamedResponse>();
    final uri = request.url.toString();
    final body = request is http.Request ? request.body : '';

    for (final entry in _routes.entries) {
      if (uri.contains(entry.key)) {
        final res = entry.value(request, body);
        final status = res['status'] as int? ?? 200;
        final data = jsonEncode(res['body'] ?? {});
        final stream = Stream<List<int>>.fromIterable([utf8.encode(data)]);
        completer.complete(
          http.StreamedResponse(
            stream,
            status,
            headers: {'content-type': 'application/json'},
          ),
        );
        return completer.future;
      }
    }

    // Default 404
    final stream = Stream<List<int>>.fromIterable([utf8.encode('{}')]);
    completer.complete(http.StreamedResponse(stream, 404));
    return completer.future;
  }
}

void main() {
  group('APISource Network Behavior', () {
    test(
      'getChunks success, caching, and maxChunks/minRelevance filtering',
      () async {
        final client = _FakeHttpClient({
          '/query': (req, body) {
            final request = jsonDecode(body) as Map<String, dynamic>;
            final query = request['query'] as String? ?? '';

            // Return results that match the query
            if (query.contains('query')) {
              return {
                'status': 200,
                'body': {
                  'results': [
                    {
                      'id': 'a',
                      'content': 'query result alpha',
                      'score': 0.9,
                      'category': 'cat',
                    },
                    {
                      'id': 'b',
                      'content': 'query result beta',
                      'score': 0.3,
                      'type': 'type',
                    },
                  ],
                },
              };
            } else {
              return {
                'status': 200,
                'body': {
                  'results': [
                    {
                      'id': 'c',
                      'content': 'other result',
                      'score': 0.5,
                      'category': 'other',
                    },
                  ],
                },
              };
            }
          },
        });

        final api = APISource(
          name: 'api',
          baseUrl: 'https://example.com',
          httpClient: client,
          rateLimit: const RateLimitConfig(
            minInterval: Duration(milliseconds: 1),
          ),
        );

        // First call hits network
        final chunks1 = await api.getChunks(
          query: 'query',
          maxChunks: 1,
          minRelevance: 0.2,
        );
        expect(chunks1.length, 1);
        expect(chunks1.first.metadata['api_source'], 'api');

        // Second call should use cache (same query)
        final chunks2 = await api.getChunks(query: 'query');
        expect(chunks2, isNotEmpty);

        // Stats should reflect active and cache size
        final stats = await api.getStats();
        expect(stats['name'], 'api');
        expect(stats['type'], 'api');
        expect(stats['base_url'], 'https://example.com');

        // Refresh clears cache and remains active
        await api.refresh();
        final chunks3 = await api.getChunks(query: 'query2');
        expect(chunks3, isNotEmpty);
      },
    );

    test(
      'error handling: 401, 429, 500 mapped to SourceConnectionException',
      () async {
        int step = 0;
        final client = _FakeHttpClient({
          '/query': (req, body) {
            step++;
            if (step == 1) {
              return {
                'status': 401,
                'body': {'error': 'unauthorized'},
              };
            }
            if (step == 2) {
              return {
                'status': 429,
                'body': {'error': 'rate'},
              };
            }
            return {
              'status': 500,
              'body': {'error': 'server'},
            };
          },
        });

        final api = APISource(
          name: 'api',
          baseUrl: 'https://example.com',
          httpClient: client,
        );

        expect(
          () => api.getChunks(query: 'x'),
          throwsA(isA<SourceConnectionException>()),
        );
        expect(
          () => api.getChunks(query: 'y'),
          throwsA(isA<SourceConnectionException>()),
        );
        expect(
          () => api.getChunks(query: 'z'),
          throwsA(isA<SourceConnectionException>()),
        );
      },
    );

    test('processAPIResponse handles malformed payload gracefully', () async {
      final client = _FakeHttpClient({
        '/query': (req, body) {
          // results is not a list -> triggers catch path in _processAPIResponse
          return {
            'status': 200,
            'body': {'results': 'oops'},
          };
        },
      });

      final api = APISource(
        name: 'api',
        baseUrl: 'https://example.com',
        httpClient: client,
      );
      final chunks = await api.getChunks(query: 'query');
      expect(chunks, isEmpty);
    });

    test('cache TTL expiration invalidates old entries', () async {
      int hits = 0;
      final client = _FakeHttpClient({
        '/query': (req, body) {
          hits++;
          return {
            'status': 200,
            'body': {
              'results': [
                {'id': 'x', 'content': 'query result', 'score': 0.5},
              ],
            },
          };
        },
      });

      final api = APISource(
        name: 'api',
        baseUrl: 'https://example.com',
        httpClient: client,
        rateLimit: const RateLimitConfig(cacheTtl: Duration(milliseconds: 0)),
      );

      await api.getChunks(query: 'query');
      await api.getChunks(query: 'query'); // cache expired -> hits again
      expect(hits, greaterThanOrEqualTo(2));
    });

    test('isHealthy true/false based on /health', () async {
      int step = 0;
      final client = _FakeHttpClient({
        '/health': (req, body) {
          step++;
          return step == 1
              ? {
                  'status': 200,
                  'body': {'ok': true},
                }
              : {
                  'status': 500,
                  'body': {'ok': false},
                };
        },
        '/query': (req, body) => {
          'status': 200,
          'body': {'results': []},
        },
      });

      final api = APISource(
        name: 'api',
        baseUrl: 'https://example.com',
        httpClient: client,
      );

      expect(await api.isHealthy(), isTrue);
      expect(await api.isHealthy(), isFalse);
    });
  });
}
