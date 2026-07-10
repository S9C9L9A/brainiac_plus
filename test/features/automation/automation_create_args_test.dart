import 'package:brainiac_plus/features/automation/services/automation_create_args.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AutomationCreateArgs.from', () {
    test('extracts a valid cron from route arguments', () {
      final args = AutomationCreateArgs.from(const {'cron': '0 9 * * *'});
      expect(args.cron, '0 9 * * *');
    });

    test('rejects invalid cron expressions', () {
      expect(
        AutomationCreateArgs.from(const {'cron': '99 99 * * *'}).cron,
        isNull,
      );
      expect(AutomationCreateArgs.from(const {'cron': 'garbage'}).cron, isNull);
    });

    test('tolerates null, non-map and missing-key arguments', () {
      expect(AutomationCreateArgs.from(null).cron, isNull);
      expect(AutomationCreateArgs.from(42).cron, isNull);
      expect(AutomationCreateArgs.from(const {'other': 'x'}).cron, isNull);
      expect(AutomationCreateArgs.from(const {'cron': 123}).cron, isNull);
    });
  });
}
