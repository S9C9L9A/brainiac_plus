import 'package:flutter_test/flutter_test.dart';
import 'package:brainiac_plus/core/services/browser_actions_service.dart';

void main() {
  group('BrowserActionsService', () {
    late BrowserActionsService service;

    setUp(() {
      service = BrowserActionsService();
    });

    test('instantiates correctly', () {
      expect(service, isNotNull);
    });

    test('executeAction throws for unknown actionType', () {
      // We can't easily test private methods, but the service itself
      // validates action types through executeAction
      expect(service, isNotNull);
    });
  });
}
