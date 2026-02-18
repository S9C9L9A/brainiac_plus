import 'dart:async';

import 'package:flutter/foundation.dart';

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

  final ValueNotifier<List<ErrorEntry>> errors =
      ValueNotifier<List<ErrorEntry>>(<ErrorEntry>[]);

  void report(Object error, StackTrace? stackTrace, {String context = 'app'}) {
    final entry = ErrorEntry(
      error: error,
      stackTrace: stackTrace,
      timestamp: DateTime.now(),
      context: context,
    );

    final current = List<ErrorEntry>.from(errors.value);
    current.add(entry);
    if (current.length > 50) {
      current.removeRange(0, current.length - 50);
    }
    errors.value = current;
  }

  void clear() {
    errors.value = <ErrorEntry>[];
  }
}

Future<Future<T>?> runWithErrorReporting<T>(Future<T> Function() body) async {
  return runZonedGuarded(body, (error, stackTrace) {
    ErrorReporter.instance.report(error, stackTrace, context: 'zone');
  });
}
