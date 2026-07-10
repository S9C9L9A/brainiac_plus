/// Category of a logged activity, used for icon and color coding.
enum ActivityType { terminal, file, ai, automation, settings, packages }

/// One event in the app-wide activity log.
class ActivityEntry {
  final ActivityType type;
  final String title;
  final String description;
  final DateTime timestamp;

  const ActivityEntry({
    required this.type,
    required this.title,
    required this.description,
    required this.timestamp,
  });
}
