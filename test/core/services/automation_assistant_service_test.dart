import 'package:brainiac_plus/core/services/automation_assistant_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AutomationAssistantService.suggestCronSchedule', () {
    test(
      'resolves common phrasings locally, without any LLM round-trip',
      () async {
        // No Ollama server runs in tests: a non-null result proves the local
        // parser answered before the network path.
        final service = AutomationAssistantService();

        expect(
          await service.suggestCronSchedule('ogni giorno alle 7:15'),
          '15 7 * * *',
        );
        expect(
          await service.suggestCronSchedule('every monday at 9am'),
          '0 9 * * 1',
        );
      },
    );
  });
}
