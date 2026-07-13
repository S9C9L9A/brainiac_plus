import 'package:flutter/material.dart';
import 'app_routes.dart';
import '../features/automation/models/automation_enums.dart';
import '../features/settings/screens/interactive_service_setup_screen.dart';
import '../features/dashboard/screens/social_media_detail_screen.dart';
import '../features/dashboard/models/social_media_service.dart';

/// Advanced route generator with parameter support and error handling
class RouteGenerator {
  RouteGenerator._();

  /// Tab screens that live inside the dashboard and have custom headers with
  /// no back button. When one is *pushed* as a standalone route (e.g. from a
  /// chat suggested-action), it must gain a way back — otherwise the user is
  /// stranded. We wrap these with a titled bar + back button. Detail screens
  /// (cpu/ram/disk/gpu) already provide their own back, so they're excluded.
  static const _needsBackWrap = <String, String>{
    AppRoutes.fileManager: 'File Manager',
    AppRoutes.terminal: 'Terminal',
    AppRoutes.packages: 'Packages',
    AppRoutes.automation: 'Automation',
    AppRoutes.settings: 'Settings',
    AppRoutes.settingsAI: 'AI Settings',
    AppRoutes.aiChat: 'Assistant',
  };

  /// Title to show on the wrapping back-bar for [name], or null when the route
  /// isn't a back-less tab (so it renders unwrapped). Exposed for tests.
  static String? backWrapTitle(String? name) => _needsBackWrap[name];

  /// Generate route with parameters support
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments;

    // Get base routes
    final routes = AppRoutes.getRoutes();

    // Check if route exists in base routes
    if (routes.containsKey(settings.name)) {
      final builder = routes[settings.name]!;
      final wrapTitle = backWrapTitle(settings.name);
      return MaterialPageRoute(
        settings: settings,
        builder: wrapTitle == null
            ? builder
            : (context) =>
                  _BackScaffold(title: wrapTitle, child: builder(context)),
      );
    }

    // Handle parametric routes
    switch (settings.name) {
      // File Manager with path parameter
      case AppRoutes.fileManagerPath:
        if (args is String) {
          // TODO: Create FileManagerScreen with initialPath parameter
          return MaterialPageRoute(
            builder: (context) => routes[AppRoutes.fileManager]!(context),
            settings: settings,
          );
        }
        return _errorRoute(settings);

      // Automation edit with ID parameter
      case AppRoutes.automationEdit:
        if (args is String) {
          // TODO: Create AutomationEditScreen with automationId parameter
          return MaterialPageRoute(
            builder: (context) => routes[AppRoutes.automation]!(context),
            settings: settings,
          );
        }
        return _errorRoute(settings);

      // Service configuration with ServiceProvider parameter
      // Uses interactive wizard for better UX
      case AppRoutes.serviceConfig:
        if (args is ServiceProvider) {
          return MaterialPageRoute(
            builder: (context) =>
                InteractiveServiceSetupScreen(serviceType: args),
            settings: settings,
          );
        }
        return _errorRoute(settings);

      // Social Media Detail with SocialMediaService parameter
      case AppRoutes.socialMediaDetail:
        if (args is SocialMediaService) {
          return MaterialPageRoute(
            builder: (context) => SocialMediaDetailScreen(service: args),
            settings: settings,
          );
        }
        return _errorRoute(settings);

      // Future routes placeholders
      case AppRoutes.automationCreate:
      case AppRoutes.settingsApiKeys:
      case AppRoutes.settingsAutomation:
      case AppRoutes.settingsAppearance:
      case AppRoutes.about:
      case AppRoutes.help:
        return _comingSoonRoute(settings);

      // 404 - Route not found
      default:
        return _errorRoute(settings);
    }
  }

  /// Error route for undefined routes
  static Route<dynamic> _errorRoute(RouteSettings settings) {
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(title: const Text('Error'), backgroundColor: Colors.red),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 80),
              const SizedBox(height: 20),
              Text(
                'Route not found',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 10),
              Text(
                'The route "${settings.name}" does not exist.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.home,
                  (route) => false,
                ),
                icon: const Icon(Icons.home),
                label: const Text('Go to Dashboard'),
              ),
            ],
          ),
        ),
      ),
      settings: settings,
    );
  }

  /// Coming soon route for planned features
  static Route<dynamic> _comingSoonRoute(RouteSettings settings) {
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: const Text('Coming Soon'),
          backgroundColor: Colors.orange,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.construction, color: Colors.orange, size: 80),
              const SizedBox(height: 20),
              Text(
                'Coming Soon',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 10),
              Text(
                'This feature is under development.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
      settings: settings,
    );
  }
}

/// Route observer for analytics and logging
class AppRouteObserver extends RouteObserver<PageRoute<dynamic>> {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _logNavigation('PUSH', route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _logNavigation('POP', route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _logNavigation('REPLACE', newRoute, oldRoute);
    }
  }

  void _logNavigation(
    String action,
    Route<dynamic> route,
    Route<dynamic>? previousRoute,
  ) {
    final routeName = route.settings.name ?? 'Unknown';
    final previousName = previousRoute?.settings.name ?? 'None';

    // TODO: Send to analytics service
    debugPrint('[$action] $previousName → $routeName');
  }
}

/// Route middleware for authentication, permissions, etc.
class RouteMiddleware {
  RouteMiddleware._();

  /// Check if user can access a route
  static bool canAccess(String routeName, {BuildContext? context}) {
    // TODO: Implement permission checks

    // Example: Some routes might require root access
    final restrictedRoutes = [
      AppRoutes.packages, // Might need sudo
      // Add more as needed
    ];

    if (restrictedRoutes.contains(routeName)) {
      // Check if user has permissions
      // For now, allow all
      return true;
    }

    return true;
  }

  /// Get redirect route if access is denied
  static String? getRedirectRoute(String routeName) {
    if (!canAccess(routeName)) {
      // Redirect to dashboard if denied
      return AppRoutes.dashboard;
    }
    return null;
  }
}

/// Route arguments helper classes
class FileManagerArguments {
  final String? initialPath;
  final bool showHidden;

  const FileManagerArguments({this.initialPath, this.showHidden = false});
}

class AutomationEditArguments {
  final String automationId;

  const AutomationEditArguments({required this.automationId});
}

/// Wraps a back-less tab screen in a titled bar with a back button so a pushed
/// route always has a way home.
class _BackScaffold extends StatelessWidget {
  final String title;
  final Widget child;

  const _BackScaffold({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(title),
        backgroundColor: const Color(0xFF0A121F),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: child,
    );
  }
}
