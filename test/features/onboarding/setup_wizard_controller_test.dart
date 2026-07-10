import 'package:brainiac_plus/features/onboarding/controllers/setup_wizard_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('setup completion persists across controller instances', () async {
    final first = SetupWizardController();
    expect(await first.checkSetupCompleted(), isFalse);

    await first.markSetupCompleted();

    final second = SetupWizardController();
    expect(await second.checkSetupCompleted(), isTrue);
  });

  test('service connection flags persist and are restored', () async {
    final first = SetupWizardController();
    first.updateServiceStatus(
      'facebook',
      true,
      credentials: {'token': 'secret'},
    );
    // Let the async persistence write settle.
    await Future<void>.delayed(Duration.zero);

    final second = SetupWizardController();
    await second.checkSetupCompleted();

    final restored = second.state.services['facebook']!;
    expect(restored.isConnected, isTrue);
    // Credentials are intentionally NOT persisted (no secrets on disk).
    expect(restored.credentials, isNull);
  });

  test('resetSetup clears completion and service flags', () async {
    final controller = SetupWizardController();
    await controller.markSetupCompleted();
    controller.updateServiceStatus('instagram', true);
    await Future<void>.delayed(Duration.zero);

    await controller.resetSetup();

    final fresh = SetupWizardController();
    expect(await fresh.checkSetupCompleted(), isFalse);
    expect(fresh.state.services['instagram']!.isConnected, isFalse);
  });

  test('step navigation clamps at both ends', () {
    final controller = SetupWizardController();
    expect(controller.state.currentStep, 0);

    controller.previousStep();
    expect(controller.state.currentStep, 0);

    for (var i = 0; i < 10; i++) {
      controller.nextStep();
    }
    expect(controller.state.currentStep, controller.state.totalSteps - 1);
  });

  test('connectedServicesCount reflects live status', () {
    final controller = SetupWizardController();
    expect(controller.state.hasAnyServiceConnected, isFalse);

    controller.updateServiceStatus('facebook', true);
    controller.updateServiceStatus('instagram', true);
    controller.updateServiceStatus('facebook', false);

    expect(controller.state.connectedServicesCount, 1);
  });
}
