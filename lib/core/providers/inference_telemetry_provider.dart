import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/inference_telemetry_service.dart';

/// Service reading the local LLM's `/metrics`. Overridable in tests.
final inferenceTelemetryServiceProvider = Provider<InferenceTelemetryService>(
  (ref) => InferenceTelemetryService(),
);

/// Polls the inference server every 3 s for live throughput. State is null
/// when the server is unreachable or exposes no metrics, so any UI can simply
/// hide its telemetry badge instead of showing a broken value.
///
/// [pollInterval] can be set to null to disable polling entirely — used by
/// widget tests so the embedded chat doesn't leave a pending timer.
class InferenceTelemetryNotifier extends StateNotifier<InferenceTelemetry?> {
  final InferenceTelemetryService _service;
  Timer? _timer;

  InferenceTelemetryNotifier(
    this._service, {
    Duration? pollInterval = const Duration(seconds: 3),
  }) : super(null) {
    if (pollInterval != null) {
      _load();
      _timer = Timer.periodic(pollInterval, (_) => _load());
    }
  }

  Future<void> _load() async {
    final t = await _service.read();
    if (mounted) state = t;
  }

  Future<void> refresh() => _load();

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final inferenceTelemetryProvider =
    StateNotifierProvider<InferenceTelemetryNotifier, InferenceTelemetry?>(
      (ref) => InferenceTelemetryNotifier(
        ref.watch(inferenceTelemetryServiceProvider),
      ),
    );
