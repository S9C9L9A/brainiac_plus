import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/onboarding/screens/setup_wizard_screen.dart';
import 'routes/route_generator.dart';
import 'core/debug/error_reporter.dart';
import 'core/debug/error_overlay.dart';

void main() {
  runWithErrorReporting(() async {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      ErrorReporter.instance.report(
        details.exception,
        details.stack,
        context: 'flutter',
      );
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      ErrorReporter.instance.report(error, stack, context: 'platform');
      return true;
    };

    runApp(
      const ProviderScope(
        child: BrainiacPlusApp(),
      ),
    );
  });
}

class BrainiacPlusApp extends ConsumerStatefulWidget {
  const BrainiacPlusApp({super.key});

  @override
  ConsumerState<BrainiacPlusApp> createState() => _BrainiacPlusAppState();
}

class _BrainiacPlusAppState extends ConsumerState<BrainiacPlusApp> {
  bool _isSetupComplete = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkSetupStatus();
  }

  Future<void> _checkSetupStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isComplete = prefs.getBool('setup_completed') ?? false;
    setState(() {
      _isSetupComplete = isComplete;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return MaterialApp(
      title: 'BrainiacPlus',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();
        return ErrorOverlay(child: child);
      },

      // Start with setup wizard if not completed, otherwise go to home
      home: _isSetupComplete ? const DashboardScreen() : const SetupWizardScreen(),

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