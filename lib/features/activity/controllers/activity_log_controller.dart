import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/activity_entry.dart';

/// App-wide activity log: features report what they did (terminal commands,
/// package operations, AI queries, …) and the Recent Activity screen renders
/// it. In-memory and session-scoped; newest entries first.
class ActivityLogController extends StateNotifier<List<ActivityEntry>> {
  static const maxEntries = 200;

  ActivityLogController() : super(const []);

  void log(ActivityEntry entry) {
    state = [entry, ...state].take(maxEntries).toList();
  }

  void clear() {
    state = const [];
  }
}

final activityLogProvider =
    StateNotifierProvider<ActivityLogController, List<ActivityEntry>>((ref) {
      return ActivityLogController();
    });
