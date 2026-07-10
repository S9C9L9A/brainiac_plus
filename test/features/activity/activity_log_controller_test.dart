import 'package:brainiac_plus/features/activity/controllers/activity_log_controller.dart';
import 'package:brainiac_plus/features/activity/models/activity_entry.dart';
import 'package:flutter_test/flutter_test.dart';

ActivityEntry entry(String title, {int minute = 0}) => ActivityEntry(
  type: ActivityType.terminal,
  title: title,
  description: 'desc',
  timestamp: DateTime(2026, 7, 10, 12, minute),
);

void main() {
  test('log prepends entries newest-first', () {
    final controller = ActivityLogController();

    controller.log(entry('first', minute: 1));
    controller.log(entry('second', minute: 2));

    expect(controller.state.map((e) => e.title), ['second', 'first']);
  });

  test('log caps the history at maxEntries', () {
    final controller = ActivityLogController();

    for (var i = 0; i < ActivityLogController.maxEntries + 50; i++) {
      controller.log(entry('e$i'));
    }

    expect(controller.state.length, ActivityLogController.maxEntries);
    // The newest entry survives, the oldest were dropped.
    expect(
      controller.state.first.title,
      'e${ActivityLogController.maxEntries + 49}',
    );
  });

  test('clear empties the log', () {
    final controller = ActivityLogController();
    controller.log(entry('x'));

    controller.clear();

    expect(controller.state, isEmpty);
  });
}
