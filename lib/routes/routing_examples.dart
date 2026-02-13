import 'package:flutter/material.dart';
import '../routes/app_routes.dart';
import '../routes/navigation_constants.dart';
import '../routes/route_generator.dart';

/// Examples of how to use the routing system
class RoutingExamples {
  /// Example 1: Basic navigation
  static void basicNavigation(BuildContext context) {
    // Navigate to terminal
    AppRoutes.navigateTo(context, AppRoutes.terminal);

    // Navigate to AI chat
    AppRoutes.navigateTo(context, AppRoutes.aiChat);

    // Navigate to settings
    AppRoutes.navigateTo(context, AppRoutes.settings);
  }

  /// Example 2: Navigation with custom transition
  static void navigationWithTransition(BuildContext context) {
    // Slide transition
    Navigator.push(
      context,
      AppRoutes.slideRoute(const Placeholder()), // Replace with actual screen
    );

    // Fade transition
    Navigator.push(
      context,
      AppRoutes.fadeRoute(const Placeholder()),
    );

    // Scale transition
    Navigator.push(
      context,
      AppRoutes.scaleRoute(const Placeholder()),
    );
  }

  /// Example 3: Navigation with arguments
  static void navigationWithArguments(BuildContext context) {
    // File manager with initial path
    Navigator.pushNamed(
      context,
      AppRoutes.fileManagerPath,
      arguments: '/home/user/documents',
    );

    // Automation edit with ID
    Navigator.pushNamed(
      context,
      AppRoutes.automationEdit,
      arguments: AutomationEditArguments(automationId: 'auto-123'),
    );
  }

  /// Example 4: Stack manipulation
  static void stackManipulation(BuildContext context) {
    // Replace current route
    AppRoutes.replaceWith(context, AppRoutes.dashboard);

    // Clear stack and navigate to home
    AppRoutes.navigateAndRemoveUntil(context, AppRoutes.home);

    // Go back if possible
    if (AppRoutes.canGoBack(context)) {
      AppRoutes.goBack(context);
    }
  }

  /// Example 5: Route metadata usage
  static void routeMetadataExample() {
    // Get all bottom navigation routes
    final bottomNavRoutes = RoutesRegistry.bottomNavRoutes;

    // Get all drawer routes
    final drawerRoutes = RoutesRegistry.drawerRoutes;

    // Get specific route metadata
    final terminalMeta = RoutesRegistry.getByName('/terminal');
    if (terminalMeta != null) {
      print('Title: ${terminalMeta.title}');
      print('Category: ${terminalMeta.category}');
      print('Show in drawer: ${terminalMeta.showInDrawer}');
    }
  }

  /// Example 6: Feature flags
  static void featureFlagsExample(BuildContext context) {
    // Check if AI assistant is enabled
    if (NavigationConstants.isFeatureEnabled('ai_assistant')) {
      AppRoutes.navigateTo(context, AppRoutes.aiChat);
    } else {
      // Show "Coming Soon" message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AI Assistant coming soon!')),
      );
    }
  }

  /// Example 7: Deep linking
  static String? parseDeepLink(String deepLink) {
    return NavigationConstants.deepLinkPatterns[deepLink];
  }

  /// Example 8: Dynamic bottom navigation
  static Widget buildBottomNavigation({
    required int currentIndex,
    required Function(int) onTap,
  }) {
    final routes = RoutesRegistry.bottomNavRoutes;

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      items: routes.map((route) {
        return BottomNavigationBarItem(
          icon: const Icon(Icons.dashboard), // Replace with actual icon
          label: route.title,
        );
      }).toList(),
    );
  }

  /// Example 9: Building a navigation drawer
  static Widget buildNavigationDrawer(BuildContext context) {
    final routes = RoutesRegistry.drawerRoutes;

    return Drawer(
      child: ListView(
        children: [
          const DrawerHeader(
            child: Text('BrainiacPlus'),
          ),
          ...routes.map((route) {
            return ListTile(
              title: Text(route.title),
              onTap: () {
                Navigator.pop(context); // Close drawer
                AppRoutes.navigateTo(context, route.name);
              },
            );
          }),
        ],
      ),
    );
  }

  /// Example 10: Error handling
  static void errorHandlingExample(BuildContext context) {
    // Try to navigate to non-existent route
    // RouteGenerator will show error page
    Navigator.pushNamed(context, '/non-existent-route');

    // Try to navigate to coming soon feature
    // RouteGenerator will show coming soon page
    Navigator.pushNamed(context, AppRoutes.about);
  }
}

/// Widget demonstrating routing usage
class RoutingDemoScreen extends StatelessWidget {
  const RoutingDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Routing Demo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Basic navigation buttons
          ElevatedButton(
            onPressed: () => AppRoutes.navigateTo(context, AppRoutes.terminal),
            child: const Text('Go to Terminal'),
          ),
          const SizedBox(height: 8),

          ElevatedButton(
            onPressed: () => AppRoutes.navigateTo(context, AppRoutes.automation),
            child: const Text('Go to Automation'),
          ),
          const SizedBox(height: 8),

          ElevatedButton(
            onPressed: () => AppRoutes.navigateTo(context, AppRoutes.aiChat),
            child: const Text('Go to AI Chat'),
          ),
          const SizedBox(height: 16),

          // Advanced navigation
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                AppRoutes.slideRoute(const Placeholder()),
              );
            },
            child: const Text('Slide Transition Demo'),
          ),
          const SizedBox(height: 8),

          // Route with arguments
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(
                context,
                AppRoutes.fileManagerPath,
                arguments: '/home',
              );
            },
            child: const Text('File Manager with Path'),
          ),
          const SizedBox(height: 8),

          // Error demo
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/invalid-route'),
            child: const Text('Test 404 Page'),
          ),
          const SizedBox(height: 8),

          // Coming soon demo
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.about),
            child: const Text('Test Coming Soon Page'),
          ),
          const SizedBox(height: 16),

          // Route metadata display
          const Text('Bottom Navigation Routes:'),
          ...RoutesRegistry.bottomNavRoutes.map((route) {
            return ListTile(
              title: Text(route.title),
              subtitle: Text('Index: ${route.bottomNavIndex}'),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () => AppRoutes.navigateTo(context, route.name),
            );
          }),
        ],
      ),
    );
  }
}

