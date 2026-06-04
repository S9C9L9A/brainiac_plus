import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

class ErrorEntry {
  final Object error;
  final StackTrace? stackTrace;
  final DateTime timestamp;
  final String context;

  const ErrorEntry({
    required this.error,
    required this.stackTrace,
    required this.timestamp,
    required this.context,
  });
}

class ErrorReporter {
  ErrorReporter._();

  static final ErrorReporter instance = ErrorReporter._();

  /// Maximum number of entries kept in [errors].
  static const int maxEntries = 50;

  final ValueNotifier<List<ErrorEntry>> errors =
      ValueNotifier<List<ErrorEntry>>(<ErrorEntry>[]);

  // Pending entries not yet published to [errors].
  final List<ErrorEntry> _buffer = <ErrorEntry>[];

  // True while [errors.value] is being assigned. A listener that throws during
  // notification (e.g. a ValueListenableBuilder calling markNeedsBuild during a
  // build) would route back here through FlutterError.onError; without this
  // guard each such error would be reported again, recursing infinitely and
  // freezing the UI.
  bool _isPublishing = false;
  bool _flushScheduled = false;

  void report(Object error, StackTrace? stackTrace, {String context = 'app'}) {
    // Drop errors raised while we are publishing a batch: they are caused by a
    // listener of [errors] and reporting them would recurse without end.
    if (_isPublishing) return;

    _buffer.add(
      ErrorEntry(
        error: error,
        stackTrace: stackTrace,
        timestamp: DateTime.now(),
        context: context,
      ),
    );

    _scheduleFlush();
  }

  void _scheduleFlush() {
    if (_flushScheduled) return;
    _flushScheduled = true;

    // notifyListeners() must not fire while a frame is being built/laid
    // out/painted, otherwise a listening widget throws "markNeedsBuild called
    // during build". Defer to after the current frame when one is in flight.
    final binding = SchedulerBinding.instance;
    final phase = binding.schedulerPhase;
    final inFrame = phase != SchedulerPhase.idle &&
        phase != SchedulerPhase.postFrameCallbacks;

    if (inFrame) {
      binding.addPostFrameCallback((_) => _flush());
    } else {
      _flush();
    }
  }

  void _flush() {
    _flushScheduled = false;
    if (_buffer.isEmpty) return;

    final next = List<ErrorEntry>.from(errors.value)..addAll(_buffer);
    _buffer.clear();
    if (next.length > maxEntries) {
      next.removeRange(0, next.length - maxEntries);
    }

    _isPublishing = true;
    try {
      errors.value = next;
    } finally {
      _isPublishing = false;
    }
  }

  void clear() {
    _buffer.clear();
    errors.value = <ErrorEntry>[];
  }
}

Future<Future<T>?> runWithErrorReporting<T>(Future<T> Function() body) async {
  return runZonedGuarded(body, (error, stackTrace) {
    ErrorReporter.instance.report(error, stackTrace, context: 'zone');
  });
}
