import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'routes/app_routes.dart';
import 'routes/route_generator.dart';

void main() {
  runApp(
    const ProviderScope(
      child: BrainiacPlusApp(),
    ),
  );
}

class BrainiacPlusApp extends StatelessWidget {
  const BrainiacPlusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BrainiacPlus',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,

      // Initial route
      initialRoute: AppRoutes.home,

      // Named routes (base routes)
      routes: AppRoutes.getRoutes(),

      // Advanced route generator for parametric routes and error handling
      onGenerateRoute: RouteGenerator.generateRoute,

      // Route observer for analytics and debugging
      navigatorObservers: [
        AppRouteObserver(),
      ],

      // Fallback for unknown routes
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const DashboardScreen(),
        );
      },
    );
  }
}


