# AI Assistant Agent

## Domain
Responsible for the AI chat UI, multi-agent orchestration pipeline, and code generation workflow.

## Responsibilities
- Chat interface with natural language understanding
- Multi-agent verification pipeline (safety, code review, test, action, coordinator)
- Code generation from user requests
- Safety validation (locked files, dangerous commands, credential detection)
- AI suggestions panel
- Quick actions processing

## Files Owned

```
lib/features/ai_assistant/
├── screens/
│   └── ai_chat_screen.dart              # Main chat interface
├── controllers/
│   └── ai_chat_controller.dart          # Chat state management
├── models/
│   ├── agent_task.dart                  # Shared pipeline data model
│   ├── agent_profile.dart               # Agent domain descriptor
│   ├── agent_response.dart              # Parsed LLM response
│   ├── ai_message.dart                  # Chat message model
│   ├── ai_suggestion.dart               # Suggestion model
│   └── code_change.dart                 # Code modification model
├── widgets/
│   └── chat/
│       ├── ai_chat_panel.dart           # Chat panel widget
│       ├── chat_input_bar.dart          # Chat input component
│       └── message_bubble.dart          # Chat bubbles
└── services/
    ├── ai_orchestrator_service.dart     # Entry point: route() and runPipeline()
    ├── agent_coordinator.dart           # Stage 5: aggregates verdict + summary
    ├── agent_registry.dart              # Domain-agent registry
    ├── agent_response_parser.dart       # Extracts code blocks + file paths
    ├── ai_guardrails_service.dart       # File-path filtering per domain
    ├── safety_agent.dart                # Stage 1: locked files, dangerous ops
    ├── code_review_agent.dart           # Stage 2: code smells, secrets
    ├── test_agent.dart                  # Stage 3: coverage recommendations
    └── action_agent.dart                # Stage 4: maps intent to in-app actions

lib/core/services/
├── ollama_service.dart                  # Ollama HTTP API client
└── automation_assistant_service.dart    # Automation-specific prompts
```

## Technical Stack
- **AI Model**: `mistral-medium-3.5:latest` (default); any Ollama-compatible model
- **API**: HTTP REST (`localhost:11434`)
- **State**: Riverpod
- **Endpoints**: `POST /api/generate`, `POST /api/chat`

## Architecture

### Multi-Agent Pipeline

```
User Input
    ↓
AiOrchestratorService.runPipeline()
    ↓
Stage 1 — SafetyAgent         (locked files, dangerous commands, credential patterns)
    ↓
Stage 2 — CodeReviewAgent     (code smells, hardcoded secrets, async safety)
    ↓
Stage 3 — TestAgent           (coverage recommendations, critical code detection)
    ↓
Stage 4 — ActionAgent         (maps keywords to in-app AgentActions)
    ↓
Stage 5 — AgentCoordinator    (sets verdict: ok | warning | blocked; builds summary)
    ↓
AgentTask (final) — .verdict + .summary + .suggestedActions
```

### route() vs runPipeline()

- `route(userContent)` — returns `RoutingDecision` (agent + system prompt). No pipeline run.
- `runPipeline(userContent, {codeSnippet, referencedFiles})` — returns finalized `AgentTask`.

### Safety Constraints
- Locked files (`pubspec.yaml`, `lib/main.dart`, `go_backend/.env`, `android/app/build.gradle.kts`) produce blocked verdict
- Dangerous shell patterns (`rm -rf`, `git push --force`, `DROP TABLE`, …) produce blocked verdict
- Credential patterns (`.env`, `.pem`, `.key`, `secrets/`) in referenced files produce blocked verdict

## API Endpoints (Ollama)

```
POST /api/generate
POST /api/chat
```

Default timeouts: 30 s connect, 120 s receive.

## Development Status
- [x] Phase 1: Ollama Service (`ollama_service.dart`)
- [x] Phase 2: Chat Interface (`ai_chat_screen.dart`, `ai_chat_controller.dart`)
- [x] Phase 3: Multi-agent pipeline (`agent_coordinator.dart` + 4 specialist agents)
- [ ] Phase 4: Approval Workflow (diff preview + user confirm)
- [ ] Phase 5: Self-Modification (hot reload + git auto-commit)
