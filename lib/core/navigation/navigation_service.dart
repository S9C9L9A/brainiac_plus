import 'package:flutter/material.dart';

/// Global navigation service to handle dashboard tab changes
/// without creating duplicate navigation stacks
class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  /// Callback to change dashboard tab from anywhere in the app
  /// This is set by DashboardScreen
  Function(int tabIndex)? onTabChange;

  /// Navigate to a specific tab in the dashboard
  /// If called from outside the dashboard, it will pop until reaching the dashboard
  void navigateToTab(BuildContext context, int tabIndex) {
    if (onTabChange != null) {
      // Close any open bottom sheets or dialogs first
      Navigator.of(context).popUntil((route) => route.isFirst);
      // Change to the requested tab
      onTabChange!(tabIndex);
    }
  }

  /// Tab indices for easy reference
  static const int tabDashboard = 0;
  static const int tabTerminal = 1;
  static const int tabAutomation = 2;
  static const int tabFiles = 3;
  static const int tabSettings = 4;
}
