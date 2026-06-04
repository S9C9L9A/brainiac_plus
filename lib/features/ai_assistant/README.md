# AI Assistant

This feature module contains the AI assistant UI and the multi-agent orchestration pipeline.

---

## Structure

```
lib/features/ai_assistant/
├── controllers/
│   └── ai_chat_controller.dart      # Chat state management (Riverpod)
├── models/
│   ├── agent_task.dart              # Shared pipeline data model
│   ├── agent_response.dart          # Parsed LLM response
│   ├── agent_profile.dart           # Agent domain descriptor
│   ├── ai_message.dart              # Chat message model
│   ├── ai_suggestion.dart           # Suggestion model
│   └── code_change.dart             # Code modification model
├── services/
│   ├── ai_orchestrator_service.dart # Entry point: route() and runPipeline()
│   ├── agent_coordinator.dart       # Runs 5-stage pipeline, sets verdict+summary
│   ├── agent_registry.dart          # Domain-agent registry
│   ├── agent_response_parser.dart   # Extracts code blocks + file paths
│   ├── ai_guardrails_service.dart   # File-path filtering per domain
│   ├── safety_agent.dart            # Stage 1 — locked files, dangerous ops
│   ├── code_review_agent.dart       # Stage 2 — code smells, secrets
│   ├── test_agent.dart              # Stage 3 — coverage recommendations
│   └── action_agent.dart            # Stage 4 — maps intent to in-app actions
├── screens/                         # Chat UI screens
└── widgets/                         # Chat UI components
```

---

## Multi-Agent Pipeline

`AiOrchestratorService.runPipeline()` runs user input through five agents in sequence:

1. **SafetyAgent** — blocks dangerous operations (locked files, `rm -rf`, credentials)
2. **CodeReviewAgent** — flags code smells, hardcoded secrets, async without try/catch
3. **TestAgent** — recommends test coverage (≥90% for auth/DB/payment code)
4. **ActionAgent** — maps intent keywords to in-app actions (open terminal, run package manager, etc.)
5. **AgentCoordinator** — aggregates all findings, sets `verdict` (`ok` / `warning` / `blocked`) and builds `summary`

The result is a finalized `AgentTask` with `.verdict` and `.summary`.

---

## AgentTask model

```dart
class AgentTask {
  final String userInput;
  final String intent;               // 'feature' | 'bugfix' | 'refactor'
  final String? codeSnippet;
  final List<String> referencedFiles;
  final List<AgentFinding> findings;
  final List<AgentAction> suggestedActions;
  final AgentVerdict verdict;        // ok | warning | blocked
  final String summary;
}
```

`AgentTask` is immutable. Each stage returns a new instance via `.copyWith()`.

---

## route() vs runPipeline()

| Method | Returns | Use when |
|---|---|---|
| `route(userContent)` | `RoutingDecision` — agent + system prompt | You only need to know which domain agent handles the request |
| `runPipeline(userContent, ...)` | `AgentTask` — verdict + findings + actions | You want full safety, review, and action analysis |

---

## Usage example

```dart
final orchestrator = AiOrchestratorService(
  registry: AgentRegistry(),
  guardrails: AiGuardrailsService(),
);

// Route only (no pipeline analysis)
final decision = orchestrator.route('Open the terminal');
// decision.agent.name, decision.systemPrompt, decision.intent

// Full pipeline
final task = orchestrator.runPipeline(
  'Fix the login bug',
  codeSnippet: dartCode,
  referencedFiles: ['lib/core/services/auth_service.dart'],
);
// task.verdict  → AgentVerdict.warning
// task.summary  → human-readable pipeline report
// task.suggestedActions → list of AgentAction
```

---

## Run tests

```bash
flutter test test/features/ai_assistant/
```
