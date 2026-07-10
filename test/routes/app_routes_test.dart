import 'package:brainiac_plus/routes/app_routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every route referenced by chat actions is registered', () {
    final routes = AppRoutes.getRoutes();

    // Routes the AgentActionExecutor navigates to — an unregistered one
    // makes the suggested-action chip crash the Navigator.
    const referenced = [
      AppRoutes.dashboard,
      AppRoutes.cpuDetail,
      AppRoutes.ramDetail,
      AppRoutes.diskDetail,
      AppRoutes.gpuDetail,
      AppRoutes.terminal,
      AppRoutes.packages,
      AppRoutes.automation,
      AppRoutes.automationCreate,
      AppRoutes.fileManager,
      AppRoutes.settings,
      AppRoutes.settingsAI,
      AppRoutes.aiChat,
    ];

    for (final route in referenced) {
      expect(routes.containsKey(route), isTrue, reason: route);
    }
  });
}
