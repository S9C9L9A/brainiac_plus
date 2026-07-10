import '../../../routes/app_routes.dart';
import '../models/agent_task.dart';

/// Resolves [AgentAction]s produced by the Action Agent into app navigation.
///
/// Keeps the pipeline decoupled from Flutter navigation: agents emit abstract
/// action ids, this class owns the id → route table. Actions without a route
/// (e.g. refresh_metrics, which mutates state instead of navigating) return
/// null and are simply not offered as navigation chips.
class AgentActionExecutor {
  static const _routes = <String, String>{
    'open_dashboard': AppRoutes.dashboard,
    'show_cpu': AppRoutes.cpuDetail,
    'show_ram': AppRoutes.ramDetail,
    'open_terminal': AppRoutes.terminal,
    'open_packages': AppRoutes.packages,
    'open_automation': AppRoutes.automation,
    'new_task': AppRoutes.automationCreate,
    'new_backup_task': AppRoutes.automationCreate,
    'open_file_manager': AppRoutes.fileManager,
    'open_settings': AppRoutes.settings,
    'open_ai_settings': AppRoutes.settingsAI,
    'open_chat': AppRoutes.aiChat,
    'open_instagram': AppRoutes.automation,
    'open_facebook': AppRoutes.automation,
  };

  /// Route for [action], or null when it does not map to a screen.
  String? routeFor(AgentAction action) => _routes[action.id];

  bool isNavigable(AgentAction action) => _routes.containsKey(action.id);
}
