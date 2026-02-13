import 'package:flutter/material.dart';
import 'app_routes.dart';

/// Advanced route generator with parameter support and error handling
class RouteGenerator {
  RouteGenerator._();

  /// Generate route with parameters support
  static Route<dynamic>? generateRoute(RouteSettings settings) {
    final args = settings.arguments;

    // Get base routes
    final routes = AppRoutes.getRoutes();

    // Check if route exists in base routes
    if (routes.containsKey(settings.name)) {
      return MaterialPageRoute(
        builder: routes[settings.name]!,
        settings: settings,
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
        appBar: AppBar(
          title: const Text('Error'),
          backgroundColor: Colors.red,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 80,
              ),
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
              const Icon(
                Icons.construction,
                color: Colors.orange,
                size: 80,
              ),
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

  void _logNavigation(String action, Route<dynamic> route, Route<dynamic>? previousRoute) {
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

  const FileManagerArguments({
    this.initialPath,
    this.showHidden = false,
  });
}

class AutomationEditArguments {
  final String automationId;

  const AutomationEditArguments({
    required this.automationId,
  });
}

