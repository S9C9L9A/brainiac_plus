import 'package:brainiac_plus/features/activity/controllers/activity_log_controller.dart';
import 'package:brainiac_plus/features/activity/models/activity_entry.dart';
import 'package:brainiac_plus/features/activity/recent_activity_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class SeededActivityLog extends ActivityLogController {
  SeededActivityLog(List<ActivityEntry> entries) {
    for (final e in entries.reversed) {
      log(e);
    }
  }
}

Widget host(List<ActivityEntry> entries) {
  return ProviderScope(
    overrides: [
      activityLogProvider.overrideWith((ref) => SeededActivityLog(entries)),
    ],
    child: const MaterialApp(home: RecentActivityScreen()),
  );
}

void main() {
  testWidgets('renders real log entries', (tester) async {
    await tester.pumpWidget(
      host([
        ActivityEntry(
          type: ActivityType.terminal,
          title: 'Command executed',
          description: 'ls -la',
          timestamp: DateTime.now(),
        ),
        ActivityEntry(
          type: ActivityType.packages,
          title: 'Package installed',
          description: 'htop',
          timestamp: DateTime.now(),
        ),
      ]),
    );

    expect(find.text('Command executed'), findsOneWidget);
    expect(find.text('ls -la'), findsOneWidget);
    expect(find.text('Package installed'), findsOneWidget);
  });

  testWidgets('shows an empty state when nothing was logged', (tester) async {
    await tester.pumpWidget(host(const []));

    expect(find.textContaining('No activity'), findsOneWidget);
  });
}
