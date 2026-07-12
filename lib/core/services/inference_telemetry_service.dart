import 'dart:async';
import 'dart:io';

/// Live throughput of the local inference server, read from the llama.cpp
/// Prometheus endpoint (`/metrics`). This is what makes the assistant aware of
/// its *own* speed — generation tok/s, queue depth — the same numbers the
/// Grafana "LLM Locale — R9700" dashboard plots, surfaced inside the app so it
/// no longer needs an external tab to know how fast it is thinking.
class InferenceTelemetry {
  /// Prompt (ingest) throughput, tokens/second.
  final double? promptTokensPerSecond;

  /// Generation throughput, tokens/second — the number a user actually feels.
  final double? predictedTokensPerSecond;

  /// Requests currently decoding.
  final int? requestsProcessing;

  /// Requests queued because every slot is busy.
  final int? requestsDeferred;

  const InferenceTelemetry({
    this.promptTokensPerSecond,
    this.predictedTokensPerSecond,
    this.requestsProcessing,
    this.requestsDeferred,
  });

  /// True when the server reported at least one usable throughput value.
  bool get hasData =>
      promptTokensPerSecond != null || predictedTokensPerSecond != null;

  /// Whether the server is actively working on or queuing requests.
  bool get isBusy =>
      (requestsProcessing ?? 0) > 0 || (requestsDeferred ?? 0) > 0;
}

/// Reads and parses the local LLM's Prometheus metrics.
///
/// The endpoint is injectable (and the HTTP call is a typedef) so the parser —
/// the only part with real logic — is unit tested without a live server, and
/// a test can point [fetch] at any host.
typedef MetricsFetcher = Future<String> Function(Uri url);

class InferenceTelemetryService {
  /// Where the llama.cpp server exposes `/metrics`. Defaults to the local
  /// inference server on :8080 (the R9700 llama.cpp instance).
  final Uri metricsUrl;
  final MetricsFetcher _fetch;
  final Duration timeout;

  InferenceTelemetryService({
    Uri? metricsUrl,
    MetricsFetcher? fetcher,
    this.timeout = const Duration(seconds: 3),
  }) : metricsUrl = metricsUrl ?? Uri.parse('http://localhost:8080/metrics'),
       _fetch = fetcher ?? _httpGet;

  /// Fetches and parses current telemetry, or null when the server is
  /// unreachable / not exposing metrics — the UI then simply hides the badge.
  Future<InferenceTelemetry?> read() async {
    try {
      final body = await _fetch(metricsUrl).timeout(timeout);
      final t = parse(body);
      return t.hasData || t.requestsProcessing != null ? t : null;
    } catch (_) {
      return null;
    }
  }

  /// Parses the Prometheus text exposition format for the llama.cpp metrics we
  /// care about. Comment lines (`# HELP`/`# TYPE`) and unrelated series are
  /// ignored; a malformed value leaves that field null rather than throwing.
  static InferenceTelemetry parse(String text) {
    double? prompt, predicted;
    int? processing, deferred;

    for (final raw in text.split('\n')) {
      final line = raw.trim();
      if (line.isEmpty || line.startsWith('#')) continue;
      // "metric_name value" — the metric name may contain a ':' (llamacpp:…).
      final sp = line.indexOf(RegExp(r'\s'));
      if (sp <= 0) continue;
      final name = line.substring(0, sp);
      final value = line.substring(sp + 1).trim();
      switch (name) {
        case 'llamacpp:prompt_tokens_seconds':
          prompt = double.tryParse(value);
        case 'llamacpp:predicted_tokens_seconds':
          predicted = double.tryParse(value);
        case 'llamacpp:requests_processing':
          processing = double.tryParse(value)?.round();
        case 'llamacpp:requests_deferred':
          deferred = double.tryParse(value)?.round();
      }
    }

    return InferenceTelemetry(
      promptTokensPerSecond: prompt,
      predictedTokensPerSecond: predicted,
      requestsProcessing: processing,
      requestsDeferred: deferred,
    );
  }

  static Future<String> _httpGet(Uri url) async {
    final client = HttpClient();
    try {
      final req = await client.getUrl(url);
      final resp = await req.close();
      if (resp.statusCode != 200) {
        throw HttpException('HTTP ${resp.statusCode}', uri: url);
      }
      final buf = StringBuffer();
      await for (final chunk in resp.transform(
        const SystemEncoding().decoder,
      )) {
        buf.write(chunk);
      }
      return buf.toString();
    } finally {
      client.close(force: true);
    }
  }
}
