# AI Assistant Agent 🤖

## Domain
Responsible for the AI chat UI, code generation workflow, and self-modification UX.

> Ollama API integration is handled by `ollama_integration.agent.md`.

## Responsibilities
- Chat interface with natural language understanding
- Code generation from user requests
- Approval workflow with diff preview
- Hot reload and git auto-commit
- Safety validation and sandbox testing
- Rollback mechanisms
- AI suggestions panel
- Quick actions processing

## Files Owned
```
lib/features/ai_assistant/
├── screens/
│   ├── ai_chat_screen.dart          # Main chat interface
│   ├── code_preview_screen.dart     # Diff preview & approval
│   └── ai_suggestions_panel.dart    # Dashboard suggestions
├── controllers/
│   ├── ai_chat_controller.dart      # Chat state management
│   ├── code_generation_controller.dart  # Code gen logic
│   └── approval_workflow_controller.dart # Approval flow
├── models/
│   ├── chat_message.dart            # Chat message model
│   ├── code_change.dart             # Code modification model
│   └── ai_suggestion.dart           # Suggestion model
├── widgets/
│   ├── chat_input_bar.dart          # Chat input component
│   ├── message_bubble.dart          # Chat bubbles
│   ├── diff_viewer.dart             # Code diff display
│   └── quick_action_button.dart     # Quick action tiles
└── services/
    └── (uses core/services/ollama_service.dart)

lib/core/services/
├── ollama_service.dart              # Ollama HTTP API client
├── code_generator_service.dart      # Template-based code gen
├── git_service.dart                 # Git operations
└── safety_validator_service.dart    # Code safety checks
```

## Technical Stack
- **AI Model**: CodeLlama 7B via Ollama
- **API**: HTTP REST (localhost:11434)
- **State**: Riverpod
- **Git**: Process.run for git commands
- **Hot Reload**: flutter/material hot reload APIs
- **Diff**: diff_match_patch package

## Architecture
### Level 3/4 Self-Modification Flow
```
User Request (NL)
    ↓
CodeLlama generates code
    ↓
Template validation
    ↓
Safety checks (sandbox)
    ↓
Show diff preview to user
    ↓
User approves/rejects
    ↓ (approved)
Apply changes to files
    ↓
Hot reload app
    ↓
Git auto-commit
    ↓
Success feedback
```

### Safety Constraints
- ❌ No modifications to: main.dart, pubspec.yaml (without approval)
- ❌ No file deletions (only edits/creates)
- ✅ All changes require user approval
- ✅ Git-based rollback always available
- ✅ Sandbox validation before preview

## API Endpoints (Ollama)
```dart
POST /api/generate
{
  "model": "qwen2.5-coder:14b"  // or codellama:13b,
  "prompt": "...",
  "stream": false,
  "temperature": 0.7
}

POST /api/chat
{
  "model": "qwen2.5-coder:14b"  // or codellama:13b,
  "messages": [...],
  "stream": true
}
```

## Code Generation Templates
```dart
// Feature Creation Template
"Create a new Flutter screen named {name} with:
- Riverpod state management
- Glassmorphism UI matching app theme
- Lucide icons from app_icons.dart
- Standard error handling
Output ONLY valid Dart code, no explanations."

// Bug Fix Template
"Fix this Dart code:
{code}
Error: {error}
Output ONLY the corrected code."

// Refactoring Template
"Refactor this Dart code to {goal}:
{code}
Maintain all functionality. Output ONLY code."
```

## Integration Points
- **Dashboard**: Hybrid UI with chat bar + suggestions panel
- **Navigation**: AI Assistant as main tab
- **Theme**: Uses app_theme.dart glassmorphism
- **Icons**: Uses app_icons.dart Lucide icons
- **Git**: Auto-commits to 'ai-generated' branch

## Success Metrics
- Response time < 10s for code generation
- 95%+ code validity rate (compiles without errors)
- Zero unauthorized file modifications
- 100% rollback success rate
- User satisfaction with suggestions

## Example Usage
```dart
// User types in chat:
"Add a network monitor to the dashboard showing upload/download speed"

// AI generates:
// 1. lib/features/dashboard/widgets/network_monitor_card.dart
// 2. Modifies lib/features/dashboard/dashboard_screen.dart
// 3. Shows diff preview
// 4. User approves
// 5. Files updated, hot reload, git commit
```

## Development Status
- [ ] Phase 1: Ollama Service
- [ ] Phase 2: Chat Interface
- [ ] Phase 3: Code Generation
- [ ] Phase 4: Approval Workflow
- [ ] Phase 5: Self-Modification
