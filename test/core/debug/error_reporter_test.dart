import 'package:flutter_test/flutter_test.dart';
import 'package:brainiac_plus/core/debug/error_reporter.dart';

void main() {
  // SchedulerBinding.instance must exist for the deferred-flush logic.
  TestWidgetsFlutterBinding.ensureInitialized();

  final reporter = ErrorReporter.instance;

  setUp(() => reporter.clear());

  test('a reported error is published to the notifier', () {
    reporter.report(Exception('boom'), StackTrace.current, context: 'test');

    expect(reporter.errors.value, hasLength(1));
    expect(reporter.errors.value.single.context, 'test');
  });

  test('does not recurse when a listener re-reports during notification', () {
    // Reproduces the freeze: a listener throwing/reporting during publish
    // used to route back through report() and recurse without end.
    var notifications = 0;
    void listener() {
      notifications++;
      // Simulate the error-overlay throwing during build, which the global
      // FlutterError.onError handler turns into another report() call.
      reporter.report(Exception('reentrant'), null, context: 'reentrant');
    }

    reporter.errors.addListener(listener);
    addTearDown(() => reporter.errors.removeListener(listener));

    // Must return promptly instead of hanging.
    reporter.report(Exception('first'), null, context: 'first');

    // The re-entrant report is dropped, so the listener fires exactly once
    // and the loop terminates.
    expect(notifications, 1);
    expect(reporter.errors.value, hasLength(1));
    expect(reporter.errors.value.single.context, 'first');
  });

  test('keeps at most maxEntries entries', () {
    for (var i = 0; i < ErrorReporter.maxEntries + 10; i++) {
      reporter.report(Exception('e$i'), null);
    }

    expect(reporter.errors.value, hasLength(ErrorReporter.maxEntries));
    // Oldest entries are trimmed; the last one survives.
    expect(
      (reporter.errors.value.last.error).toString(),
      contains('e${ErrorReporter.maxEntries + 9}'),
    );
  });

  test('clear empties both the buffer and the notifier', () {
    reporter.report(Exception('x'), null);
    expect(reporter.errors.value, isNotEmpty);

    reporter.clear();
    expect(reporter.errors.value, isEmpty);
  });
}
