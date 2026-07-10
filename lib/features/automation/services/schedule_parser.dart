/// Deterministic natural-language → cron parser for common Italian and
/// English schedule phrasings.
///
/// Used by AutomationAssistantService before falling back to the LLM: local
/// parsing is instant, works with Ollama offline, and cannot hallucinate.
/// [isValidCron] additionally guards whatever the LLM fallback returns.
class ScheduleParser {
  static const _weekdays = <String, int>{
    // Cron: 0 = Sunday.
    'domenica': 0, 'sunday': 0,
    'lunedì': 1, 'lunedi': 1, 'monday': 1,
    'martedì': 2, 'martedi': 2, 'tuesday': 2,
    'mercoledì': 3, 'mercoledi': 3, 'wednesday': 3,
    'giovedì': 4, 'giovedi': 4, 'thursday': 4,
    'venerdì': 5, 'venerdi': 5, 'friday': 5,
    'sabato': 6, 'saturday': 6,
  };

  /// Hour used when a daily/weekly phrase carries no explicit time.
  static const _defaultHour = 9;

  /// Parses [text] into a 5-field cron expression, or null when the phrasing
  /// is not one of the supported deterministic patterns.
  String? tryParse(String text) {
    final input = text.trim().toLowerCase();
    if (input.isEmpty) return null;

    // "ogni 5 minuti" / "every 15 minutes"
    var m = RegExp(r'(?:ogni|every)\s+(\d{1,2})\s+min').firstMatch(input);
    if (m != null) {
      final n = int.parse(m.group(1)!);
      if (n >= 1 && n <= 59) return '*/$n * * * *';
    }

    // "ogni 2 ore" / "every 6 hours"
    m = RegExp(
      r'(?:ogni|every)\s+(\d{1,2})\s+(?:ore|hours?)',
    ).firstMatch(input);
    if (m != null) {
      final n = int.parse(m.group(1)!);
      if (n >= 1 && n <= 23) return '0 */$n * * *';
    }

    if (RegExp(r'ogni ora|every hour|oraria').hasMatch(input)) {
      return '0 * * * *';
    }
    if (RegExp(r'ogni minuto|every minute').hasMatch(input)) {
      return '* * * * *';
    }
    if (RegExp(r'due volte al giorno|twice a day').hasMatch(input)) {
      return '0 9,18 * * *';
    }

    // "ogni lunedì [alle 14:30]" / "every monday [at 2:30pm]"
    final weekdayPattern = RegExp(
      '(?:ogni|every)\\s+(${_weekdays.keys.join('|')})',
    );
    m = weekdayPattern.firstMatch(input);
    if (m != null) {
      final day = _weekdays[m.group(1)!]!;
      final time = _parseTime(input) ?? (hour: _defaultHour, minute: 0);
      return '${time.minute} ${time.hour} * * $day';
    }

    // "ogni giorno [alle 21:30]" / "tutti i giorni ..." / "every day at 9am"
    if (RegExp(r'ogni giorno|tutti i giorni|every day|daily').hasMatch(input)) {
      final time = _parseTime(input) ?? (hour: _defaultHour, minute: 0);
      return '${time.minute} ${time.hour} * * *';
    }

    return null;
  }

  /// Extracts a time following "alle"/"at": 24h ("21:30", "9") or am/pm
  /// ("2:30pm"). Returns null when absent or out of range.
  ({int hour, int minute})? _parseTime(String input) {
    final m = RegExp(
      r'(?:alle|at)\s+(\d{1,2})(?:[:.](\d{2}))?\s*(am|pm)?',
    ).firstMatch(input);
    if (m == null) return null;

    var hour = int.parse(m.group(1)!);
    final minute = m.group(2) != null ? int.parse(m.group(2)!) : 0;
    final meridiem = m.group(3);

    if (meridiem == 'pm' && hour < 12) hour += 12;
    if (meridiem == 'am' && hour == 12) hour = 0;

    if (hour > 23 || minute > 59) return null;
    return (hour: hour, minute: minute);
  }

  /// Validates a standard 5-field cron expression
  /// (minute hour day month weekday), including numeric ranges.
  static bool isValidCron(String expr) {
    final fields = expr.trim().split(RegExp(r'\s+'));
    if (fields.length != 5) return false;

    const bounds = <({int min, int max})>[
      (min: 0, max: 59), // minute
      (min: 0, max: 23), // hour
      (min: 1, max: 31), // day of month
      (min: 1, max: 12), // month
      (min: 0, max: 7), // weekday (7 = Sunday, like 0)
    ];

    for (var i = 0; i < 5; i++) {
      if (!_isValidField(fields[i], bounds[i].min, bounds[i].max)) {
        return false;
      }
    }
    return true;
  }

  static bool _isValidField(String field, int min, int max) {
    for (final part in field.split(',')) {
      if (part.isEmpty) return false;
      if (part == '*') continue;

      // */N step
      final step = RegExp(r'^\*/(\d+)$').firstMatch(part);
      if (step != null) {
        final n = int.parse(step.group(1)!);
        if (n < 1 || n > max) return false;
        continue;
      }

      // N or N-M
      final range = RegExp(r'^(\d+)(?:-(\d+))?$').firstMatch(part);
      if (range == null) return false;
      final lo = int.parse(range.group(1)!);
      final hi = range.group(2) != null ? int.parse(range.group(2)!) : lo;
      if (lo < min || hi > max || lo > hi) return false;
    }
    return true;
  }
}
