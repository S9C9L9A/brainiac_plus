# AI Assistant Integration in BrainiacPlus

## Overview

BrainiacPlus now integrates a local LLM (Llama via Ollama) as a tool directly in the automation creation interface. This allows users to describe their automation needs in natural language and have the AI suggest the appropriate configuration.

## Features

### 🤖 Natural Language Automation Creation

Users can describe what they want to automate in plain English (or any natural language), and the AI will:
- Suggest the best automation category (Social Media, Productivity, Communication, etc.)
- Recommend the appropriate service provider (Instagram, GitHub, Slack, etc.)
- Determine the optimal execution mode (API, Browser, Hybrid)
- Suggest trigger type (Manual, Scheduled, Event-based)
- Generate a descriptive name and description

### ✨ Smart Form Auto-fill

The AI assistant automatically populates the automation creation form with intelligent suggestions:
- **Name**: Descriptive automation name
- **Description**: Clear explanation of what the automation does
- **Category**: Best-fit category based on the task
- **Service**: Recommended service provider
- **Mode**: Optimal execution mode
- **Trigger**: Suggested trigger type

### 📊 Confidence Scoring

Each AI suggestion includes a confidence score (0.0 to 1.0):
- **High confidence (≥0.7)**: Green indicator, auto-advances to next step
- **Low confidence (<0.7)**: Orange indicator, requires user review

## Architecture

### Components

1. **OllamaService** (`lib/core/services/ollama_service.dart`)
   - HTTP API client for Ollama
   - Handles code generation and chat completion
   - Supports both streaming and non-streaming modes

2. **AutomationAssistantService** (`lib/core/services/automation_assistant_service.dart`)
   - Wrapper around OllamaService
   - Specialized prompts for automation tasks
   - Parses AI responses into structured data

3. **AutomationAssistantProvider** (`lib/features/automation/providers/automation_assistant_provider.dart`)
   - Riverpod provider for dependency injection
   - Makes AutomationAssistantService available throughout the app

4. **CreateAutomationTab** (`lib/features/automation/screens/create_automation_tab.dart`)
   - UI integration of AI assistant
   - "AI Assist" button in Basic Information step
   - Dialog for natural language input
   - Form auto-fill logic

### Data Flow

```
User Input (Natural Language)
    ↓
AI Assistant Dialog
    ↓
AutomationAssistantService.suggestAutomation()
    ↓
OllamaService.generateCode()
    ↓
Ollama API (Local LLM)
    ↓
Parse JSON Response
    ↓
AutomationSuggestion Object
    ↓
Auto-fill Form Fields
```

## Usage

### For Users

1. Navigate to the **Automation** section
2. Click **Create** tab
3. In the **Basic Information** step, click the **AI Assist** button
4. Enter your automation description in natural language:
   - Example: "Post to Instagram every day at 9am"
   - Example: "Send a Slack message when I receive an email"
   - Example: "Backup my Notion database to Google Drive weekly"
5. Click **Generate**
6. Review the AI suggestions (confidence score shown)
7. Modify if needed and proceed to next steps

### For Developers

#### Using the AutomationAssistantService

```dart
// Get the service from Riverpod
final assistantService = ref.read(automationAssistantServiceProvider);

// Get automation suggestion
final suggestion = await assistantService.suggestAutomation(
  "Post a tweet every morning at 8am"
);

// Access suggestion properties
print(suggestion.name);          // "Morning Tweet Automation"
print(suggestion.category);      // AutomationCategory.socialMedia
print(suggestion.service);       // ServiceProvider.twitter
print(suggestion.mode);          // AutomationMode.api
print(suggestion.trigger);       // TriggerType.scheduled
print(suggestion.confidence);    // 0.85
print(suggestion.isHighConfidence); // true

// Convert to Automation object
final automation = suggestion.toAutomation();
```

#### Other Available Methods

```dart
// Suggest configuration for existing automation
final config = await assistantService.suggestConfig(automation);

// Interactive chat about automation
final stream = assistantService.chatAboutAutomation(
  conversationHistory,
  userMessage,
);

// Convert natural language to cron schedule
final cronSchedule = await assistantService.suggestCronSchedule(
  "every day at 9am"
); // Returns "0 9 * * *"

// Suggest best automation mode
final mode = await assistantService.suggestMode(
  ServiceProvider.instagram,
  "post a photo with caption",
);
```

## Requirements

### Local Ollama Installation

The AI assistant requires a local Ollama instance running:

1. **Install Ollama**: https://ollama.ai
2. **Download a model**:
   ```bash
   ollama pull codellama:7b
   ```
3. **Start Ollama server**:
   ```bash
   ollama serve
   ```
   Default: `http://localhost:11434`

### Supported Models

- `codellama:7b` (default, recommended)
- `llama2:7b`
- `mistral:7b`
- Any Ollama-compatible model

To use a different model, modify the provider:

```dart
final automationAssistantServiceProvider = Provider<AutomationAssistantService>((ref) {
  return AutomationAssistantService(model: 'mistral:7b');
});
```

## Error Handling

The integration includes comprehensive error handling:

- **Ollama not running**: Shows error message to start Ollama
- **Network timeout**: 30s connect, 120s receive timeouts
- **Parse failures**: Falls back to conservative defaults
- **Invalid responses**: Provides low-confidence fallback suggestions

## Future Enhancements

### Planned Features

1. **Multi-turn Conversation**: Chat-based automation refinement
2. **Template Learning**: AI learns from user's automation patterns
3. **Smart Scheduling**: AI suggests optimal run times based on usage
4. **Automation Optimization**: Suggests improvements to existing automations
5. **Natural Language Configuration**: AI fills in advanced config fields
6. **Voice Input**: Speak your automation requirements
7. **Multi-language Support**: Support for non-English languages

### Integration Opportunities

- **Code Generation**: Generate custom scripts for automations
- **Debugging Assistant**: Help troubleshoot failed automations
- **Performance Tuning**: Suggest optimizations for slow automations
- **Security Review**: Check automations for potential security issues

## Performance

- **Average Response Time**: 2-5 seconds (depends on model size)
- **Memory Usage**: ~4GB for CodeLlama 7B model
- **GPU Acceleration**: Supported via CUDA (NVIDIA) or Metal (Apple Silicon)
- **Offline Operation**: Fully functional without internet

## Privacy & Security

- **100% Local**: All AI processing happens on your machine
- **No Data Sent**: Nothing is transmitted to external servers
- **No Telemetry**: No usage tracking or analytics
- **Open Source Models**: Transparent model behavior

## Troubleshooting

### AI Assistant Button Not Working

1. Check Ollama is running: `curl http://localhost:11434/api/version`
2. Verify model is installed: `ollama list`
3. Check logs for connection errors

### Slow Response Times

1. Use a smaller model (7B instead of 13B/34B)
2. Enable GPU acceleration
3. Increase system resources
4. Check for competing processes

### Low Quality Suggestions

1. Be more specific in your description
2. Include examples in your prompt
3. Mention service names explicitly
4. Try different models

## Examples

### Example 1: Social Media Automation

**Input**: "Post my latest blog article to Twitter, LinkedIn, and Facebook every time I publish"

**AI Suggestion**:
- Name: "Multi-platform Blog Promotion"
- Category: Social Media
- Service: Custom (requires multi-service setup)
- Mode: Hybrid
- Trigger: Event
- Confidence: 0.72

### Example 2: Productivity Automation

**Input**: "Backup my Notion workspace to Google Drive every Sunday at 2am"

**AI Suggestion**:
- Name: "Weekly Notion Backup"
- Category: Productivity
- Service: Notion
- Mode: API
- Trigger: Scheduled
- Confidence: 0.88

### Example 3: Development Automation

**Input**: "Send me a Slack notification when someone opens a PR on my GitHub repo"

**AI Suggestion**:
- Name: "GitHub PR Slack Notifications"
- Category: Development
- Service: GitHub
- Mode: API
- Trigger: Event (Webhook)
- Confidence: 0.91

## Contributing

To contribute to the AI assistant integration:

1. Improve prompts in `AutomationAssistantService`
2. Enhance parsing logic for better accuracy
3. Add support for more automation patterns
4. Optimize response times
5. Add more examples and templates

## License

This feature is part of BrainiacPlus and follows the same license terms.

## Support

For issues or questions:
- GitHub Issues: https://github.com/GennaGcodebase/BrainiacPlus/issues
- Documentation: https://github.com/GennaGcodebase/BrainiacPlus/docs

---

**Last Updated**: 2026-02-18
**Version**: 1.0.0
