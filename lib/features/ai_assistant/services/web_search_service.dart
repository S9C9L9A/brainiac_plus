import 'dart:convert';
import 'dart:io';

/// One web search hit fed back to the agent so it can decide what to `fetch`
/// and read in full.
class SearchResult {
  final String title;
  final String url;
  final String snippet;

  const SearchResult({
    required this.title,
    required this.url,
    this.snippet = '',
  });
}

/// Gives the agent a way to *find* pages, not just fetch known ones — the
/// missing half of "more internet". Uses only keyless endpoints so it works on
/// a fresh machine with no API keys:
///
/// - DuckDuckGo Instant Answer (definitions / abstracts), and
/// - Wikipedia opensearch (encyclopedic results with real URLs).
///
/// The two HTTP calls are injectable and the response parsers are pure, so the
/// merge/dedupe — the only real logic — is unit tested against captured JSON
/// without hitting the network. The agent typically searches, then `fetch`es
/// the most promising result URL.
typedef JsonFetcher = Future<String> Function(Uri url);

class WebSearchService {
  final JsonFetcher _fetch;
  final Duration timeout;

  WebSearchService({
    JsonFetcher? fetcher,
    this.timeout = const Duration(seconds: 12),
  }) : _fetch = fetcher ?? _httpGetJson;

  /// Runs [query] across the providers and returns merged results, best first,
  /// capped at [limit]. Never throws: a provider that errors contributes
  /// nothing rather than failing the whole search.
  Future<List<SearchResult>> search(String query, {int limit = 6}) async {
    final q = query.trim();
    if (q.isEmpty) return const [];

    final results = <SearchResult>[];

    try {
      final ddg = await _fetch(
        Uri.parse(
          'https://api.duckduckgo.com/?q=${Uri.encodeQueryComponent(q)}'
          '&format=json&no_html=1&no_redirect=1',
        ),
      ).timeout(timeout);
      results.addAll(parseDuckDuckGo(ddg));
    } catch (_) {
      // provider unavailable — fall through to the next
    }

    try {
      final wiki = await _fetch(
        Uri.parse(
          'https://en.wikipedia.org/w/api.php?action=opensearch'
          '&search=${Uri.encodeQueryComponent(q)}&limit=$limit&format=json',
        ),
      ).timeout(timeout);
      results.addAll(parseWikipediaOpenSearch(wiki));
    } catch (_) {
      // provider unavailable
    }

    return _dedupeByUrl(results).take(limit).toList();
  }

  /// Parses DuckDuckGo's Instant Answer JSON: the top-level Abstract (when the
  /// query has a direct answer) plus any RelatedTopics that carry a URL.
  static List<SearchResult> parseDuckDuckGo(String jsonText) {
    final out = <SearchResult>[];
    Object? decoded;
    try {
      decoded = jsonDecode(jsonText);
    } catch (_) {
      return out;
    }
    if (decoded is! Map) return out;

    final abstractUrl = decoded['AbstractURL']?.toString() ?? '';
    final abstractText = decoded['AbstractText']?.toString() ?? '';
    final heading = decoded['Heading']?.toString() ?? '';
    if (abstractUrl.isNotEmpty && abstractText.isNotEmpty) {
      out.add(
        SearchResult(
          title: heading.isNotEmpty ? heading : abstractUrl,
          url: abstractUrl,
          snippet: abstractText,
        ),
      );
    }

    final related = decoded['RelatedTopics'];
    if (related is List) {
      for (final t in related) {
        if (t is! Map) continue;
        final url = t['FirstURL']?.toString() ?? '';
        final text = t['Text']?.toString() ?? '';
        if (url.isNotEmpty && text.isNotEmpty) {
          out.add(SearchResult(title: text, url: url, snippet: text));
        }
      }
    }
    return out;
  }

  /// Parses Wikipedia's opensearch response, the shape
  /// `[query, [titles…], [descriptions…], [urls…]]`.
  static List<SearchResult> parseWikipediaOpenSearch(String jsonText) {
    final out = <SearchResult>[];
    Object? decoded;
    try {
      decoded = jsonDecode(jsonText);
    } catch (_) {
      return out;
    }
    if (decoded is! List || decoded.length < 4) return out;
    final titles = decoded[1];
    final descriptions = decoded[2];
    final urls = decoded[3];
    if (titles is! List || urls is! List) return out;
    for (var i = 0; i < titles.length && i < urls.length; i++) {
      final title = titles[i]?.toString() ?? '';
      final url = urls[i]?.toString() ?? '';
      final desc = (descriptions is List && i < descriptions.length)
          ? descriptions[i]?.toString() ?? ''
          : '';
      if (url.isNotEmpty) {
        out.add(SearchResult(title: title, url: url, snippet: desc));
      }
    }
    return out;
  }

  static List<SearchResult> _dedupeByUrl(List<SearchResult> results) {
    final seen = <String>{};
    final out = <SearchResult>[];
    for (final r in results) {
      if (seen.add(r.url)) out.add(r);
    }
    return out;
  }

  static Future<String> _httpGetJson(Uri url) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 12)
      ..userAgent = 'BrainiacPlus/1.0';
    try {
      final req = await client.getUrl(url);
      final resp = await req.close();
      if (resp.statusCode != 200) {
        throw HttpException('HTTP ${resp.statusCode}', uri: url);
      }
      return await resp.transform(utf8.decoder).join();
    } finally {
      client.close(force: true);
    }
  }
}
