/// Dashboard customization preferences
class DashboardLayout {
  final List<String> visibleCards;
  final Map<String, int> cardOrder;
  final bool compactMetrics;
  final bool showQuickActions;
  final bool showRecentActivity;

  const DashboardLayout({
    this.visibleCards = const [
      'metrics',
      'quick_actions',
      'ai_assistant',
      'automation',
      'recent_activity',
    ],
    this.cardOrder = const {
      'metrics': 0,
      'quick_actions': 1,
      'ai_assistant': 2,
      'automation': 3,
      'recent_activity': 4,
    },
    this.compactMetrics = true,
    this.showQuickActions = true,
    this.showRecentActivity = true,
  });

  DashboardLayout copyWith({
    List<String>? visibleCards,
    Map<String, int>? cardOrder,
    bool? compactMetrics,
    bool? showQuickActions,
    bool? showRecentActivity,
  }) {
    return DashboardLayout(
      visibleCards: visibleCards ?? this.visibleCards,
      cardOrder: cardOrder ?? this.cardOrder,
      compactMetrics: compactMetrics ?? this.compactMetrics,
      showQuickActions: showQuickActions ?? this.showQuickActions,
      showRecentActivity: showRecentActivity ?? this.showRecentActivity,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'visibleCards': visibleCards,
      'cardOrder': cardOrder,
      'compactMetrics': compactMetrics,
      'showQuickActions': showQuickActions,
      'showRecentActivity': showRecentActivity,
    };
  }

  factory DashboardLayout.fromJson(Map<String, dynamic> json) {
    return DashboardLayout(
      visibleCards: List<String>.from(json['visibleCards'] ?? []),
      cardOrder: Map<String, int>.from(json['cardOrder'] ?? {}),
      compactMetrics: json['compactMetrics'] ?? true,
      showQuickActions: json['showQuickActions'] ?? true,
      showRecentActivity: json['showRecentActivity'] ?? true,
    );
  }
}
