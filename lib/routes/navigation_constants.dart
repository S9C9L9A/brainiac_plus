/// Navigation constants and utilities
class NavigationConstants {
  NavigationConstants._();

  // ========== TRANSITION DURATIONS ==========

  static const Duration defaultTransitionDuration = Duration(milliseconds: 300);
  static const Duration fastTransitionDuration = Duration(milliseconds: 200);
  static const Duration slowTransitionDuration = Duration(milliseconds: 500);

  // ========== ROUTE PATTERNS (for deep linking) ==========

  /// Deep link patterns for app
  static const Map<String, String> deepLinkPatterns = {
    'brainiacplus://dashboard': '/dashboard',
    'brainiacplus://terminal': '/terminal',
    'brainiacplus://automation': '/automation',
    'brainiacplus://files': '/file-manager',
    'brainiacplus://packages': '/packages',
    'brainiacplus://ai': '/ai-chat',
    'brainiacplus://settings': '/settings',
    'brainiacplus://cpu': '/cpu-detail',
    'brainiacplus://ram': '/ram-detail',
    'brainiacplus://disk': '/disk-detail',
  };

  // ========== BOTTOM NAVIGATION INDICES ==========

  static const int dashboardIndex = 0;
  static const int terminalIndex = 1;
  static const int automationIndex = 2;
  static const int filesIndex = 3;
  static const int settingsIndex = 4;

  // ========== FEATURE FLAGS ==========

  /// Enable/disable features (useful for beta testing)
  static const Map<String, bool> featureFlags = {
    'ai_assistant': true,
    'automation': true,
    'packages': true,
    'terminal': true,
    'file_manager': true,
    'system_monitor': true,
    'settings_api_keys': false, // Placeholder for future
    'settings_appearance': false, // Placeholder for future
    'about_page': false, // Placeholder for future
    'help_page': false, // Placeholder for future
  };

  /// Check if feature is enabled
  static bool isFeatureEnabled(String feature) {
    return featureFlags[feature] ?? false;
  }
}

/// Route categories for organization
enum RouteCategory {
  main,
  feature,
  detail,
  settings,
  help,
}

/// Route metadata
class RouteMetadata {
  final String name;
  final String title;
  final RouteCategory category;
  final bool requiresAuth;
  final bool showInDrawer;
  final int? bottomNavIndex;

  const RouteMetadata({
    required this.name,
    required this.title,
    required this.category,
    this.requiresAuth = false,
    this.showInDrawer = true,
    this.bottomNavIndex,
  });
}

/// All routes metadata registry
class RoutesRegistry {
  RoutesRegistry._();

  static const List<RouteMetadata> allRoutes = [
    // Main routes
    RouteMetadata(
      name: '/dashboard',
      title: 'Dashboard',
      category: RouteCategory.main,
      showInDrawer: true,
      bottomNavIndex: 0,
    ),

    // Feature routes
    RouteMetadata(
      name: '/terminal',
      title: 'Terminal',
      category: RouteCategory.feature,
      showInDrawer: true,
      bottomNavIndex: 1,
    ),
    RouteMetadata(
      name: '/automation',
      title: 'Automation',
      category: RouteCategory.feature,
      showInDrawer: true,
      bottomNavIndex: 2,
    ),
    RouteMetadata(
      name: '/file-manager',
      title: 'Files',
      category: RouteCategory.feature,
      showInDrawer: true,
      bottomNavIndex: 3,
    ),
    RouteMetadata(
      name: '/packages',
      title: 'Packages',
      category: RouteCategory.feature,
      showInDrawer: true,
    ),
    RouteMetadata(
      name: '/ai-chat',
      title: 'AI Assistant',
      category: RouteCategory.feature,
      showInDrawer: true,
    ),

    // Settings
    RouteMetadata(
      name: '/settings',
      title: 'Settings',
      category: RouteCategory.settings,
      showInDrawer: true,
      bottomNavIndex: 4,
    ),

    // Detail routes (not shown in drawer)
    RouteMetadata(
      name: '/cpu-detail',
      title: 'CPU Details',
      category: RouteCategory.detail,
      showInDrawer: false,
    ),
    RouteMetadata(
      name: '/ram-detail',
      title: 'RAM Details',
      category: RouteCategory.detail,
      showInDrawer: false,
    ),
    RouteMetadata(
      name: '/disk-detail',
      title: 'Disk Details',
      category: RouteCategory.detail,
      showInDrawer: false,
    ),
  ];

  /// Get routes for bottom navigation
  static List<RouteMetadata> get bottomNavRoutes {
    return allRoutes
        .where((route) => route.bottomNavIndex != null)
        .toList()
      ..sort((a, b) => a.bottomNavIndex!.compareTo(b.bottomNavIndex!));
  }

  /// Get routes for drawer
  static List<RouteMetadata> get drawerRoutes {
    return allRoutes.where((route) => route.showInDrawer).toList();
  }

  /// Get route metadata by name
  static RouteMetadata? getByName(String name) {
    try {
      return allRoutes.firstWhere((route) => route.name == name);
    } catch (e) {
      return null;
    }
  }
}

