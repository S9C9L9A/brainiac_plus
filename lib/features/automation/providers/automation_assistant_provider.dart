import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/automation_assistant_service.dart';

/// Provider for AutomationAssistantService
final automationAssistantServiceProvider = Provider<AutomationAssistantService>((ref) {
  return AutomationAssistantService();
});
