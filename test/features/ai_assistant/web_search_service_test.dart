import 'package:brainiac_plus/features/ai_assistant/services/web_search_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseDuckDuckGo', () {
    test('extracts the abstract and related topics with URLs', () {
      const json = '''
      {
        "Heading": "Flutter",
        "AbstractText": "Flutter is an open-source UI toolkit.",
        "AbstractURL": "https://en.wikipedia.org/wiki/Flutter_(software)",
        "RelatedTopics": [
          {"FirstURL": "https://dart.dev", "Text": "Dart programming language"},
          {"Result": "no url here"}
        ]
      }
      ''';
      final r = WebSearchService.parseDuckDuckGo(json);
      expect(r.first.title, 'Flutter');
      expect(r.first.url, contains('wikipedia.org'));
      expect(r.first.snippet, contains('UI toolkit'));
      expect(r.any((x) => x.url == 'https://dart.dev'), isTrue);
      // The entry without a FirstURL is skipped.
      expect(r, hasLength(2));
    });

    test('empty instant-answer JSON yields no results, no throw', () {
      final r = WebSearchService.parseDuckDuckGo(
        '{"AbstractText":"","AbstractURL":"","RelatedTopics":[]}',
      );
      expect(r, isEmpty);
    });

    test('malformed JSON is handled gracefully', () {
      expect(WebSearchService.parseDuckDuckGo('not json'), isEmpty);
    });
  });

  group('parseWikipediaOpenSearch', () {
    test('maps the [query, titles, descriptions, urls] shape', () {
      const json =
          '["riverpod",["Riverpod","Riverdale"],["A state lib","A show"],'
          '["https://w/Riverpod","https://w/Riverdale"]]';
      final r = WebSearchService.parseWikipediaOpenSearch(json);
      expect(r, hasLength(2));
      expect(r.first.title, 'Riverpod');
      expect(r.first.url, 'https://w/Riverpod');
      expect(r.first.snippet, 'A state lib');
    });

    test('unexpected shape yields empty, not an exception', () {
      expect(WebSearchService.parseWikipediaOpenSearch('{}'), isEmpty);
      expect(WebSearchService.parseWikipediaOpenSearch('[1,2]'), isEmpty);
    });
  });

  group('search (merged, injected fetcher)', () {
    test('merges providers and dedupes by URL, capped at limit', () async {
      final service = WebSearchService(
        fetcher: (url) async {
          if (url.host.contains('duckduckgo')) {
            return '{"AbstractText":"x","AbstractURL":"https://dup",'
                '"Heading":"Dup","RelatedTopics":[]}';
          }
          // Wikipedia returns the same URL plus a fresh one.
          return '["q",["Dup","New"],["",""],["https://dup","https://new"]]';
        },
      );
      final r = await service.search('anything', limit: 5);
      final urls = r.map((e) => e.url).toList();
      expect(urls, contains('https://dup'));
      expect(urls, contains('https://new'));
      // https://dup appeared from both providers but is present once.
      expect(urls.where((u) => u == 'https://dup'), hasLength(1));
    });

    test('an empty query short-circuits to no results', () async {
      final service = WebSearchService(
        fetcher: (_) async => throw StateError('should not be called'),
      );
      expect(await service.search('   '), isEmpty);
    });

    test('a failing provider does not fail the whole search', () async {
      final service = WebSearchService(
        fetcher: (url) async {
          if (url.host.contains('duckduckgo')) throw Exception('down');
          return '["q",["Only"],[""],["https://only"]]';
        },
      );
      final r = await service.search('q');
      expect(r.single.url, 'https://only');
    });
  });
}
