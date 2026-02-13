import '../ollama_service.dart';
import '../../../features/automation/models/automation.dart';
import '../../../features/automation/models/automation_enums.dart';

/// Service to help create automations using Ollama AI
class AutomationAssistantService {
  final OllamaService _ollama;

  AutomationAssistantService({String? model})
      : _ollama = OllamaService(model: model ?? 'codellama:7b');

  /// Generate automation suggestions based on user description
  Future<AutomationSuggestion> suggestAutomation(String userDescription) async {
    final prompt = _buildSuggestionPrompt(userDescription);
    
    final response = await _ollama.generateCode(
      prompt,
      temperature: 0.3, // Lower temperature for more focused suggestions
    );

    return _parseAutomationSuggestion(response, userDescription);
  }

  /// Generate configuration options for an automation
  Future<Map<String, dynamic>> suggestConfig(Automation automation) async {
    final prompt = _buildConfigPrompt(automation);
    
    final response = await _ollama.generateCode(
      prompt,
      temperature: 0.5,
    );

    return _parseConfigSuggestion(response);
  }

  /// Interactive chat to refine automation
  Stream<String> chatAboutAutomation(
    List<ChatMessage> conversationHistory,
    String userMessage,
  ) async* {
    final systemPrompt = ChatMessage.system('''
You are an automation assistant for BrainiacPlus, a cross-platform automation app.
Help users create, configure, and optimize their automations.

Available automation categories:
- Social Media (Instagram, Facebook, Twitter, LinkedIn, TikTok, YouTube)
- Productivity (Notion, Google, File Management)
- Communication (Slack, Discord, Telegram)
- Development (GitHub, CI/CD)

Available automation modes:
- API: Use official service APIs (fast, reliable)
- Browser: Browser automation (flexible, works for any site)
- App: Android app automation via ADB (mobile-specific)
- Hybrid: Try API first, fallback to browser/app

Provide clear, concise suggestions. Format your responses as structured JSON when suggesting automations.
''');

    final messages = [
      systemPrompt,
      ...conversationHistory,
      ChatMessage.user(userMessage),
    ];

    yield* _ollama.chatStream(messages);
  }

  /// Suggest cron schedule based on natural language
  Future<String?> suggestCronSchedule(String naturalLanguage) async {
    final prompt = '''
Convert this natural language time description to a cron expression:
"$naturalLanguage"

Examples:
- "every day at 9am" → "0 9 * * *"
- "every monday at 2:30pm" → "30 14 * * 1"
- "every hour" → "0 * * * *"
- "twice a day" → "0 9,18 * * *"

Only respond with the cron expression, nothing else.
Cron format: minute hour day month weekday
''';

    final response = await _ollama.generateCode(prompt, temperature: 0.1);
    
    // Extract cron expression from response
    final cronPattern = RegExp(r'[\d\*\/\-\,]+ [\d\*\/\-\,]+ [\d\*\/\-\,]+ [\d\*\/\-\,]+ [\d\*\/\-\,]+');
    final match = cronPattern.firstMatch(response);
    
    return match?.group(0);
  }

  /// Suggest best automation mode for a given task
  Future<AutomationMode> suggestMode(
    ServiceProvider service,
    String taskDescription,
  ) async {
    final hasAPI = service.supportsAPI;
    
    final prompt = '''
Given this automation task: "$taskDescription"
Service: ${service.label}
Has Official API: $hasAPI

Suggest the best execution mode:
- API: Fast and reliable, but limited to what API supports
- Browser: Flexible, can do anything a human can do in browser
- Hybrid: Try API first, fallback to browser if needed

Respond with ONLY one word: API, BROWSER, or HYBRID
''';

    final response = await _ollama.generateCode(prompt, temperature: 0.2);
    
    final normalized = response.trim().toUpperCase();
    
    if (normalized.contains('BROWSER')) return AutomationMode.browser;
    if (normalized.contains('API')) return AutomationMode.api;
    return AutomationMode.hybrid;
  }

  /// Build prompt for automation suggestion
  String _buildSuggestionPrompt(String userDescription) {
    return '''
Analyze this automation request and suggest the best configuration:
"$userDescription"

Based on this request, suggest:
1. Best automation category (socialMedia, productivity, communication, development)
2. Best service provider (instagram, facebook, google, notion, github, etc.)
3. Recommended execution mode (api, browser, hybrid)
4. Suggested trigger type (manual, scheduled, event, condition)

Respond in this exact JSON format:
{
  "category": "category_name",
  "service": "service_name",
  "mode": "execution_mode",
  "trigger": "trigger_type",
  "name": "suggested automation name",
  "description": "what this automation does",
  "confidence": 0.85
}
''';
  }

  /// Build prompt for config suggestion
  String _buildConfigPrompt(Automation automation) {
    return '''
Suggest optimal configuration for this automation:
Name: ${automation.name}
Description: ${automation.description}
Service: ${automation.service.label}
Category: ${automation.category.label}

Provide configuration suggestions as key-value pairs.
''';
  }

  /// Parse automation suggestion from Ollama response
  AutomationSuggestion _parseAutomationSuggestion(
    String response,
    String originalDescription,
  ) {
    // Try to extract JSON from response
    final jsonPattern = RegExp(r'\{[^}]+\}', dotAll: true);
    final match = jsonPattern.firstMatch(response);
    
    if (match == null) {
      // Fallback to heuristics
      return _fallbackSuggestion(originalDescription);
    }

    try {
      // Parse JSON (simplified - in production use json.decode)
      final jsonText = match.group(0)!;
      
      return AutomationSuggestion(
        category: _extractCategory(jsonText),
        service: _extractService(jsonText),
        mode: _extractMode(jsonText),
        trigger: _extractTrigger(jsonText),
        name: _extractField(jsonText, 'name') ?? 'New Automation',
        description: _extractField(jsonText, 'description') ?? originalDescription,
        confidence: _extractConfidence(jsonText),
      );
    } catch (e) {
      return _fallbackSuggestion(originalDescription);
    }
  }

  /// Parse config suggestion
  Map<String, dynamic> _parseConfigSuggestion(String response) {
    final config = <String, dynamic>{};
    
    // Simple key:value parser
    final lines = response.split('\n');
    for (final line in lines) {
      if (line.contains(':')) {
        final parts = line.split(':');
        if (parts.length >= 2) {
          final key = parts[0].trim().replaceAll('"', '');
          final value = parts.sublist(1).join(':').trim().replaceAll('"', '');
          config[key] = value;
        }
      }
    }
    
    return config;
  }

  /// Fallback suggestion when AI parsing fails
  AutomationSuggestion _fallbackSuggestion(String description) {
    return AutomationSuggestion(
      category: AutomationCategory.custom,
      service: ServiceProvider.custom,
      mode: AutomationMode.hybrid,
      trigger: TriggerType.manual,
      name: 'New Automation',
      description: description,
      confidence: 0.3,
    );
  }

  // Helper extraction methods
  AutomationCategory _extractCategory(String json) {
    final categoryStr = _extractField(json, 'category');
    return AutomationCategory.values.firstWhere(
      (c) => c.name.toLowerCase() == categoryStr?.toLowerCase(),
      orElse: () => AutomationCategory.custom,
    );
  }

  ServiceProvider _extractService(String json) {
    final serviceStr = _extractField(json, 'service');
    return ServiceProvider.values.firstWhere(
      (s) => s.name.toLowerCase() == serviceStr?.toLowerCase(),
      orElse: () => ServiceProvider.custom,
    );
  }

  AutomationMode _extractMode(String json) {
    final modeStr = _extractField(json, 'mode');
    return AutomationMode.values.firstWhere(
      (m) => m.name.toLowerCase() == modeStr?.toLowerCase(),
      orElse: () => AutomationMode.hybrid,
    );
  }

  TriggerType _extractTrigger(String json) {
    final triggerStr = _extractField(json, 'trigger');
    return TriggerType.values.firstWhere(
      (t) => t.name.toLowerCase() == triggerStr?.toLowerCase(),
      orElse: () => TriggerType.manual,
    );
  }

  String? _extractField(String json, String field) {
    final pattern = RegExp('"$field":\\s*"([^"]+)"');
    final match = pattern.firstMatch(json);
    return match?.group(1);
  }

  double _extractConfidence(String json) {
    final confStr = _extractField(json, 'confidence');
    return double.tryParse(confStr ?? '0.5') ?? 0.5;
  }
}

/// Automation suggestion from AI
class AutomationSuggestion {
  final AutomationCategory category;
  final ServiceProvider service;
  final AutomationMode mode;
  final TriggerType trigger;
  final String name;
  final String description;
  final double confidence; // 0.0 to 1.0

  AutomationSuggestion({
    required this.category,
    required this.service,
    required this.mode,
    required this.trigger,
    required this.name,
    required this.description,
    required this.confidence,
  });

  /// Convert to Automation object
  Automation toAutomation() {
    return Automation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
      category: category,
      service: service,
      preferredMode: mode,
      triggerType: trigger,
      status: AutomationStatus.idle,
      config: {},
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isActive: true,
      isTemplate: false,
    );
  }

  /// Is suggestion high confidence?
  bool get isHighConfidence => confidence >= 0.7;
}
