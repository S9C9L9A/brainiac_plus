import 'schedule_parser.dart';

/// Typed view over the route arguments the chat's scheduling actions attach
/// when navigating to /automation/create. Tolerates any argument shape and
/// only exposes values that survive validation.
class AutomationCreateArgs {
  /// Pre-parsed cron expression to prefill, or null.
  final String? cron;

  const AutomationCreateArgs._({this.cron});

  factory AutomationCreateArgs.from(Object? routeArguments) {
    if (routeArguments is! Map) return const AutomationCreateArgs._();

    final cron = routeArguments['cron'];
    if (cron is String && ScheduleParser.isValidCron(cron)) {
      return AutomationCreateArgs._(cron: cron);
    }
    return const AutomationCreateArgs._();
  }
}
