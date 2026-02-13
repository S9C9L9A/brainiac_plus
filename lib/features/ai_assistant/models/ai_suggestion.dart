/// AI suggestion for dashboard quick actions
class AiSuggestion {
  final String id;
  final String title;
  final String description;
  final AiSuggestionCategory category;
  final String prompt;
  final bool isBookmarked;

  AiSuggestion({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.prompt,
    this.isBookmarked = false,
  });

  AiSuggestion copyWith({
    String? id,
    String? title,
    String? description,
    AiSuggestionCategory? category,
    String? prompt,
    bool? isBookmarked,
  }) {
    return AiSuggestion(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      prompt: prompt ?? this.prompt,
      isBookmarked: isBookmarked ?? this.isBookmarked,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'category': category.name,
        'prompt': prompt,
        'isBookmarked': isBookmarked,
      };

  factory AiSuggestion.fromJson(Map<String, dynamic> json) => AiSuggestion(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        category: AiSuggestionCategory.values.byName(json['category'] as String),
        prompt: json['prompt'] as String,
        isBookmarked: json['isBookmarked'] as bool? ?? false,
      );
}

/// Suggestion categories
enum AiSuggestionCategory {
  optimization, // Performance improvements
  feature, // New feature suggestions
  cleanup, // Code cleanup/refactoring
  automation, // Automation tasks
  monitoring, // System monitoring
}

/// Extension for AiSuggestionCategory
extension AiSuggestionCategoryX on AiSuggestionCategory {
  String get label {
    switch (this) {
      case AiSuggestionCategory.optimization:
        return 'Optimization';
      case AiSuggestionCategory.feature:
        return 'Feature';
      case AiSuggestionCategory.cleanup:
        return 'Cleanup';
      case AiSuggestionCategory.automation:
        return 'Automation';
      case AiSuggestionCategory.monitoring:
        return 'Monitoring';
    }
  }
}

/// Predefined suggestions
final List<AiSuggestion> defaultSuggestions = [
  AiSuggestion(
    id: '1',
    title: 'Network Monitor',
    description: 'Add real-time network speed monitoring',
    category: AiSuggestionCategory.feature,
    prompt: 'Add a network monitor widget to the dashboard showing real-time upload/download speed',
  ),
  AiSuggestion(
    id: '2',
    title: 'Battery Monitor',
    description: 'Monitor battery health and usage',
    category: AiSuggestionCategory.monitoring,
    prompt: 'Add battery monitoring with health status and power consumption tracking',
  ),
  AiSuggestion(
    id: '3',
    title: 'Auto Cleanup',
    description: 'Automated disk cleanup task',
    category: AiSuggestionCategory.automation,
    prompt: 'Create an automated task to clean temp files and package cache weekly',
  ),
  AiSuggestion(
    id: '4',
    title: 'GPU Monitoring',
    description: 'Track GPU usage and temperature',
    category: AiSuggestionCategory.feature,
    prompt: 'Add GPU monitoring showing usage, temperature, and memory',
  ),
];
