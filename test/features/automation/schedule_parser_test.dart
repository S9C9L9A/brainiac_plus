import 'package:brainiac_plus/features/automation/services/schedule_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final parser = ScheduleParser();

  group('ScheduleParser.tryParse — intervals', () {
    test('every N minutes (it/en)', () {
      expect(parser.tryParse('ogni 5 minuti'), '*/5 * * * *');
      expect(parser.tryParse('every 15 minutes'), '*/15 * * * *');
    });

    test('every N hours (it/en)', () {
      expect(parser.tryParse('ogni 2 ore'), '0 */2 * * *');
      expect(parser.tryParse('every 6 hours'), '0 */6 * * *');
    });

    test('every hour / every minute (it/en)', () {
      expect(parser.tryParse('ogni ora'), '0 * * * *');
      expect(parser.tryParse('every hour'), '0 * * * *');
      expect(parser.tryParse('ogni minuto'), '* * * * *');
      expect(parser.tryParse('every minute'), '* * * * *');
    });
  });

  group('ScheduleParser.tryParse — daily', () {
    test('daily with 24h time (it/en)', () {
      expect(parser.tryParse('ogni giorno alle 9'), '0 9 * * *');
      expect(parser.tryParse('tutti i giorni alle 21:30'), '30 21 * * *');
      expect(parser.tryParse('every day at 18:45'), '45 18 * * *');
    });

    test('daily with am/pm time', () {
      expect(parser.tryParse('every day at 9am'), '0 9 * * *');
      expect(parser.tryParse('every day at 2:30pm'), '30 14 * * *');
      expect(parser.tryParse('every day at 12am'), '0 0 * * *');
      expect(parser.tryParse('every day at 12pm'), '0 12 * * *');
    });

    test('daily without a time defaults to 09:00', () {
      expect(parser.tryParse('ogni giorno'), '0 9 * * *');
      expect(parser.tryParse('every day'), '0 9 * * *');
    });

    test('twice a day (it/en)', () {
      expect(parser.tryParse('due volte al giorno'), '0 9,18 * * *');
      expect(parser.tryParse('twice a day'), '0 9,18 * * *');
    });
  });

  group('ScheduleParser.tryParse — weekdays', () {
    test('weekday with time (it/en)', () {
      expect(parser.tryParse('ogni lunedì alle 14:30'), '30 14 * * 1');
      expect(parser.tryParse('every monday at 2:30pm'), '30 14 * * 1');
      expect(parser.tryParse('ogni venerdì alle 8'), '0 8 * * 5');
    });

    test('weekday without time defaults to 09:00', () {
      expect(parser.tryParse('ogni domenica'), '0 9 * * 0');
      expect(parser.tryParse('every saturday'), '0 9 * * 6');
    });
  });

  group('ScheduleParser.tryParse — no match', () {
    test('returns null for free text it cannot handle', () {
      expect(parser.tryParse('quando ne ho voglia'), isNull);
      expect(parser.tryParse('on the third blue moon'), isNull);
      expect(parser.tryParse(''), isNull);
    });
  });

  group('ScheduleParser.isValidCron', () {
    test('accepts well-formed 5-field expressions', () {
      expect(ScheduleParser.isValidCron('0 9 * * *'), isTrue);
      expect(ScheduleParser.isValidCron('30 14 * * 1'), isTrue);
      expect(ScheduleParser.isValidCron('*/5 * * * *'), isTrue);
      expect(ScheduleParser.isValidCron('0 9,18 * * *'), isTrue);
      expect(ScheduleParser.isValidCron('0 0 1 1 *'), isTrue);
      expect(ScheduleParser.isValidCron('0 8-18 * * 1-5'), isTrue);
    });

    test('rejects malformed or out-of-range expressions', () {
      expect(ScheduleParser.isValidCron('0 9 * *'), isFalse); // 4 fields
      expect(ScheduleParser.isValidCron('60 * * * *'), isFalse); // minute 60
      expect(ScheduleParser.isValidCron('* 24 * * *'), isFalse); // hour 24
      expect(ScheduleParser.isValidCron('* * 0 * *'), isFalse); // day 0
      expect(ScheduleParser.isValidCron('* * * 13 *'), isFalse); // month 13
      expect(ScheduleParser.isValidCron('* * * * 8'), isFalse); // weekday 8
      expect(ScheduleParser.isValidCron('a b c d e'), isFalse);
      expect(ScheduleParser.isValidCron(''), isFalse);
    });
  });
}
