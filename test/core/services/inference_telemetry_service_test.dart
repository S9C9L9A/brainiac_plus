import 'dart:io';

import 'package:brainiac_plus/core/services/inference_telemetry_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InferenceTelemetryService.parse', () {
    // A trimmed sample in the exact llama.cpp /metrics exposition format.
    const sample = '''
# HELP llamacpp:prompt_tokens_seconds Average prompt throughput in tokens/s.
# TYPE llamacpp:prompt_tokens_seconds gauge
llamacpp:prompt_tokens_seconds 939.302
# TYPE llamacpp:predicted_tokens_seconds gauge
llamacpp:predicted_tokens_seconds 34.3328
llamacpp:requests_processing 2
llamacpp:requests_deferred 0
llamacpp:kv_cache_usage_ratio 0.12
''';

    test('reads the four throughput/queue metrics', () {
      final t = InferenceTelemetryService.parse(sample);
      expect(t.promptTokensPerSecond, closeTo(939.302, 0.001));
      expect(t.predictedTokensPerSecond, closeTo(34.3328, 0.001));
      expect(t.requestsProcessing, 2);
      expect(t.requestsDeferred, 0);
      expect(t.hasData, isTrue);
      expect(t.isBusy, isTrue); // 2 processing
    });

    test('ignores comments and unrelated series without throwing', () {
      final t = InferenceTelemetryService.parse(
        '# a comment\nnode_cpu_seconds_total 5\ngarbage line here\n',
      );
      expect(t.hasData, isFalse);
      expect(t.requestsProcessing, isNull);
    });

    test('malformed values leave the field null, not an exception', () {
      final t = InferenceTelemetryService.parse(
        'llamacpp:predicted_tokens_seconds not_a_number\n',
      );
      expect(t.predictedTokensPerSecond, isNull);
    });

    test('idle server: zero processing/deferred is not busy', () {
      final t = InferenceTelemetryService.parse(
        'llamacpp:predicted_tokens_seconds 40\n'
        'llamacpp:requests_processing 0\n'
        'llamacpp:requests_deferred 0\n',
      );
      expect(t.isBusy, isFalse);
      expect(t.hasData, isTrue);
    });
  });

  group('InferenceTelemetryService.read', () {
    test('returns parsed telemetry from the injected fetcher', () async {
      final service = InferenceTelemetryService(
        fetcher: (_) async => 'llamacpp:predicted_tokens_seconds 34.3\n',
      );
      final t = await service.read();
      expect(t, isNotNull);
      expect(t!.predictedTokensPerSecond, closeTo(34.3, 0.01));
    });

    test('returns null when the server is unreachable', () async {
      final service = InferenceTelemetryService(
        fetcher: (_) async => throw const SocketException('refused'),
      );
      expect(await service.read(), isNull);
    });

    test('returns null when metrics carry nothing we recognise', () async {
      final service = InferenceTelemetryService(
        fetcher: (_) async => '# nothing useful\nother_metric 1\n',
      );
      expect(await service.read(), isNull);
    });
  });
}
