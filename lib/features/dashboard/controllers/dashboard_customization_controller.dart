import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/dashboard_layout.dart';

/// State for dashboard customization
class DashboardCustomizationState {
  final DashboardLayout layout;
  final bool isEditMode;
  final bool isLoading;

  const DashboardCustomizationState({
    required this.layout,
    this.isEditMode = false,
    this.isLoading = false,
  });

  DashboardCustomizationState copyWith({
    DashboardLayout? layout,
    bool? isEditMode,
    bool? isLoading,
  }) {
    return DashboardCustomizationState(
      layout: layout ?? this.layout,
      isEditMode: isEditMode ?? this.isEditMode,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Controller for dashboard customization
class DashboardCustomizationController
    extends StateNotifier<DashboardCustomizationState> {
  static const String _storageKey = 'dashboard_layout';

  DashboardCustomizationController()
      : super(const DashboardCustomizationState(
          layout: DashboardLayout(),
        )) {
    _loadLayout();
  }

  /// Load layout from SharedPreferences
  Future<void> _loadLayout() async {
    state = state.copyWith(isLoading: true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final layoutJson = prefs.getString(_storageKey);

      if (layoutJson != null) {
        final json = jsonDecode(layoutJson) as Map<String, dynamic>;
        final layout = DashboardLayout.fromJson(json);
        state = state.copyWith(layout: layout, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      debugPrint('Error loading dashboard layout: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  /// Save layout to SharedPreferences
  Future<void> _saveLayout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final layoutJson = jsonEncode(state.layout.toJson());
      await prefs.setString(_storageKey, layoutJson);
    } catch (e) {
      debugPrint('Error saving dashboard layout: $e');
    }
  }

  /// Toggle edit mode
  void toggleEditMode() {
    state = state.copyWith(isEditMode: !state.isEditMode);
  }

  /// Toggle card visibility
  Future<void> toggleCardVisibility(String cardId) async {
    final visibleCards = List<String>.from(state.layout.visibleCards);
    
    if (visibleCards.contains(cardId)) {
      visibleCards.remove(cardId);
    } else {
      visibleCards.add(cardId);
    }

    state = state.copyWith(
      layout: state.layout.copyWith(visibleCards: visibleCards),
    );
    
    await _saveLayout();
  }

  /// Reorder cards
  Future<void> reorderCard(String cardId, int newPosition) async {
    final cardOrder = Map<String, int>.from(state.layout.cardOrder);
    
    // Update positions
    final oldPosition = cardOrder[cardId] ?? 0;
    
    // Shift other cards
    cardOrder.forEach((key, value) {
      if (key == cardId) {
        cardOrder[key] = newPosition;
      } else if (oldPosition < newPosition) {
        // Moving down
        if (value > oldPosition && value <= newPosition) {
          cardOrder[key] = value - 1;
        }
      } else {
        // Moving up
        if (value >= newPosition && value < oldPosition) {
          cardOrder[key] = value + 1;
        }
      }
    });

    state = state.copyWith(
      layout: state.layout.copyWith(cardOrder: cardOrder),
    );
    
    await _saveLayout();
  }

  /// Toggle compact metrics mode
  Future<void> toggleCompactMetrics() async {
    state = state.copyWith(
      layout: state.layout.copyWith(
        compactMetrics: !state.layout.compactMetrics,
      ),
    );
    await _saveLayout();
  }

  /// Toggle quick actions visibility
  Future<void> toggleQuickActions() async {
    state = state.copyWith(
      layout: state.layout.copyWith(
        showQuickActions: !state.layout.showQuickActions,
      ),
    );
    await _saveLayout();
  }

  /// Toggle recent activity visibility
  Future<void> toggleRecentActivity() async {
    state = state.copyWith(
      layout: state.layout.copyWith(
        showRecentActivity: !state.layout.showRecentActivity,
      ),
    );
    await _saveLayout();
  }

  /// Reset to default layout
  Future<void> resetToDefault() async {
    state = state.copyWith(layout: const DashboardLayout());
    await _saveLayout();
  }
}

/// Provider for dashboard customization
final dashboardCustomizationProvider =
    StateNotifierProvider<DashboardCustomizationController,
        DashboardCustomizationState>((ref) {
  return DashboardCustomizationController();
});
