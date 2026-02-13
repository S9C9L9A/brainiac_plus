/// BrainiacPlus Routing System
///
/// Complete routing solution with:
/// - Named routes with type safety
/// - Dynamic route generation
/// - Custom transitions
/// - Route observer for analytics
/// - Deep linking support
/// - Error handling
/// - Route middleware
/// - Feature flags
///
/// Usage:
/// ```dart
/// import 'package:brainiac_plus/routes/routes.dart';
///
/// // Navigate
/// AppRoutes.navigateTo(context, AppRoutes.terminal);
///
/// // With custom transition
/// Navigator.push(context, AppRoutes.slideRoute(MyScreen()));
///
/// // With arguments
/// Navigator.pushNamed(context, AppRoutes.fileManager, arguments: path);
/// ```

library routes;

// Core routing
export 'app_routes.dart';
export 'route_generator.dart';
export 'navigation_constants.dart';

// Examples (for reference/demo)
export 'routing_examples.dart';

