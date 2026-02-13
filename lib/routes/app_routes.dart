import 'package:flutter/material.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/dashboard/screens/cpu_detail_screen.dart';
import '../features/dashboard/screens/ram_detail_screen.dart';
import '../features/dashboard/screens/disk_detail_screen.dart';
import '../features/terminal/terminal_screen.dart';
import '../features/automation/automation_screen.dart';
import '../features/file_manager/file_manager_screen.dart';
import '../features/packages/packages_screen.dart';
import '../features/ai_assistant/screens/ai_chat_screen.dart';
import '../features/settings/screens/settings_screen.dart';

/// App routes configuration with named routes and navigation utilities
class AppRoutes {
  AppRoutes._(); // Private constructor to prevent instantiation

  // ========== MAIN ROUTES ==========

  /// Dashboard - Main screen
  static const String home = '/';
  static const String dashboard = '/dashboard';

  // ========== FEATURE ROUTES ==========

  /// Terminal screen
  static const String terminal = '/terminal';

  /// Automation screen
  static const String automation = '/automation';

  /// File Manager screen
  static const String fileManager = '/file-manager';

  /// Packages screen
  static const String packages = '/packages';

  /// AI Assistant screen
  static const String aiChat = '/ai-chat';

  /// Settings screen
  static const String settings = '/settings';

  // ========== DETAIL ROUTES ==========

  /// CPU detail screen
  static const String cpuDetail = '/cpu-detail';

  /// RAM detail screen
  static const String ramDetail = '/ram-detail';

  /// Disk detail screen
  static const String diskDetail = '/disk-detail';

  // ========== FUTURE ROUTES (Placeholder) ==========

  /// Automation create/edit
  static const String automationCreate = '/automation/create';
  static const String automationEdit = '/automation/edit';

  /// File Manager with path parameter
  static const String fileManagerPath = '/file-manager/path';

  /// Settings sub-pages
  static const String settingsApiKeys = '/settings/api-keys';
  static const String settingsAutomation = '/settings/automation';
  static const String settingsAppearance = '/settings/appearance';
  
  /// Service configuration
  static const String serviceConfig = '/service-config';

  /// About & Help
  static const String about = '/about';
  static const String help = '/help';

  // ========== ROUTE GENERATION ==========

  /// Get all app routes map
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      // Main
      home: (context) => const DashboardScreen(),
      dashboard: (context) => const DashboardScreen(),

      // Features
      terminal: (context) => const TerminalScreen(),
      automation: (context) => const AutomationScreen(),
      fileManager: (context) => const FileManagerScreen(),
      packages: (context) => const PackagesScreen(),
      aiChat: (context) => const AiChatScreen(),
      settings: (context) => const SettingsScreen(),

      // Details
      cpuDetail: (context) => const CpuDetailScreen(),
      ramDetail: (context) => const RamDetailScreen(),
      diskDetail: (context) => const DiskDetailScreen(),
    };
  }

  // ========== NAVIGATION HELPERS ==========

  /// Navigate to route by name
  static Future<T?> navigateTo<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.pushNamed<T>(
      context,
      routeName,
      arguments: arguments,
    );
  }

  /// Navigate to route and remove all previous routes
  static Future<T?> navigateAndRemoveUntil<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.pushNamedAndRemoveUntil<T>(
      context,
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  /// Replace current route with new route
  static Future<T?> replaceWith<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.pushReplacementNamed<T, Object?>(
      context,
      routeName,
      arguments: arguments,
    );
  }

  /// Go back
  static void goBack(BuildContext context, [Object? result]) {
    Navigator.pop(context, result);
  }

  /// Check if can go back
  static bool canGoBack(BuildContext context) {
    return Navigator.canPop(context);
  }

  // ========== ROUTE TRANSITIONS ==========

  /// Custom page route with slide transition
  static Route<T> slideRoute<T>(Widget page, {RouteSettings? settings}) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  /// Custom page route with fade transition
  static Route<T> fadeRoute<T>(Widget page, {RouteSettings? settings}) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }

  /// Custom page route with scale transition
  static Route<T> scaleRoute<T>(Widget page, {RouteSettings? settings}) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const curve = Curves.easeInOut;
        var tween = Tween(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: curve),
        );

        return ScaleTransition(
          scale: animation.drive(tween),
          child: child,
        );
      },
    );
  }
}

/// Route information class for advanced routing
class RouteInfo {
  final String name;
  final String title;
  final IconData? icon;
  final String? description;

  const RouteInfo({
    required this.name,
    required this.title,
    this.icon,
    this.description,
  });
}

/// Collection of all app routes with metadata
class AppRoutesList {
  AppRoutesList._();

  static const List<RouteInfo> mainRoutes = [
    RouteInfo(
      name: AppRoutes.dashboard,
      title: 'Dashboard',
      description: 'System monitoring and overview',
    ),
    RouteInfo(
      name: AppRoutes.terminal,
      title: 'Terminal',
      description: 'Command line interface',
    ),
    RouteInfo(
      name: AppRoutes.automation,
      title: 'Automation',
      description: 'Automated tasks and workflows',
    ),
    RouteInfo(
      name: AppRoutes.fileManager,
      title: 'Files',
      description: 'File system browser',
    ),
    RouteInfo(
      name: AppRoutes.packages,
      title: 'Packages',
      description: 'Package management',
    ),
    RouteInfo(
      name: AppRoutes.aiChat,
      title: 'AI Assistant',
      description: 'Chat with AI assistant',
    ),
    RouteInfo(
      name: AppRoutes.settings,
      title: 'Settings',
      description: 'App configuration',
    ),
  ];

  static const List<RouteInfo> detailRoutes = [
    RouteInfo(
      name: AppRoutes.cpuDetail,
      title: 'CPU Details',
      description: 'CPU usage and processes',
    ),
    RouteInfo(
      name: AppRoutes.ramDetail,
      title: 'RAM Details',
      description: 'Memory usage and processes',
    ),
    RouteInfo(
      name: AppRoutes.diskDetail,
      title: 'Disk Details',
      description: 'Storage usage and partitions',
    ),
  ];
}

