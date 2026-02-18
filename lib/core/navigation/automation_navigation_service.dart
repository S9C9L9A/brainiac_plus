import 'package:flutter/material.dart';

/// Global navigation service for Automation tabs.
class AutomationNavigationService {
  static final AutomationNavigationService _instance =
      AutomationNavigationService._internal();
  factory AutomationNavigationService() => _instance;
  AutomationNavigationService._internal();

  Function(int tabIndex)? _onTabChange;
  int? _pendingTabIndex;

  void registerTabChangeHandler(Function(int tabIndex) handler) {
    _onTabChange = handler;
    if (_pendingTabIndex != null) {
      final index = _pendingTabIndex!;
      _pendingTabIndex = null;
      handler(index);
    }
  }

  void clearHandler() {
    _onTabChange = null;
  }

  void navigateToTab(BuildContext context, int tabIndex) {
    if (_onTabChange != null) {
      _onTabChange!(tabIndex);
    } else {
      _pendingTabIndex = tabIndex;
    }
  }

  static const int tabActive = 0;
  static const int tabTemplates = 1;
  static const int tabCreate = 2;
  static const int tabMarketplace = 3;
}
