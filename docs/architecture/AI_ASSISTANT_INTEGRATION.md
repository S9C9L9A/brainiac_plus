# AI Assistant Integration

BrainiacPlus ships a local AI assistant backed by Ollama. User messages pass through a 5-stage multi-agent verification pipeline before a response is returned.

**Last Updated:** 2026-06-04

---

## Components

| File | Role |
|---|---|
| `lib/core/services/ollama_service.dart` | HTTP client for Ollama (`/api/generate`, `/api/chat`) |
| `lib/core/services/automation_assistant_service.dart` | Automation-specific prompts; wraps `OllamaService` |
| `lib/features/ai_assistant/services/ai_orchestrator_service.dart` | Entry point: `.route()` and `.runPipeline()` |
| `lib/features/ai_assistant/services/agent_registry.dart` | Domain-agent registry (keyword matching, allowed paths) |
| `lib/features/ai_assistant/services/ai_guardrails_service.dart` | File-path filtering per agent domain |
| `lib/features/ai_assistant/services/agent_coordinator.dart` | Runs the 5-stage pipeline, sets final verdict + summary |
| `lib/features/ai_assistant/services/safety_agent.dart` | Stage 1 — locked files, dangerous commands, secrets |
| `lib/features/ai_assistant/services/code_review_agent.dart` | Stage 2 — code smells, hardcoded secrets, async safety |
| `lib/features/ai_assistant/services/test_agent.dart` | Stage 3 — coverage recommendations |
| `lib/features/ai_assistant/services/action_agent.dart` | Stage 4 — maps intent to in-app actions |
| `lib/features/ai_assistant/models/agent_task.dart` | Shared data model flowing through the pipeline |
| `lib/features/ai_assistant/models/agent_response.dart` | Parsed LLM response (code blocks, file hints) |
| `lib/features/ai_assistant/models/agent_profile.dart` | Agent domain descriptor |
| `lib/features/ai_assistant/services/agent_response_parser.dart` | Extracts code blocks and file paths from raw LLM text |

---

## Default model

`OllamaService` defaults to **`mistral-medium-3.5:latest`** (configurable via constructor).
Any Ollama-compatible model works; pull with `ollama pull <model>`.
For ROCm / Radeon AI PRO R9700 tuning see [`../GPU_OPTIMIZATION.md`](../GPU_OPTIMIZATION.md).

---

## Multi-Agent Pipeline

`AiOrchestratorService.runPipeline()` creates an `AgentTask` and hands it to `AgentCoordinator.run()`, which executes five stages in order:

```
User input
    │
    ▼
┌─────────────────────────────────────────────────────────┐
│ Stage 1 — SafetyAgent                                   │
│  Checks: locked files, dangerous shell commands,        │
│  credential patterns in code snippet.                   │
│  Severity: error (→ blocked verdict if triggered)       │
└──────────────────────────┬──────────────────────────────┘
                           ▼
┌─────────────────────────────────────────────────────────┐
│ Stage 2 — CodeReviewAgent                              │
│  Checks: print/debugPrint, TODO/FIXME, empty catches,  │
│  dynamic types, hardcoded secrets, async without try.   │
│  Severity: error (secrets) or warning (smells)          │
└──────────────────────────┬──────────────────────────────┘
                           ▼
┌─────────────────────────────────────────────────────────┐
│ Stage 3 — TestAgent                                     │
│  Checks: critical code areas (auth/DB/payments →        │
│  ≥90% coverage), public method count, async/stream.    │
│  Severity: warning (critical) or info                   │
└──────────────────────────┬──────────────────────────────┘
                           ▼
┌─────────────────────────────────────────────────────────┐
│ Stage 4 — ActionAgent                                   │
│  Maps keywords in user input to in-app AgentActions     │
│  (e.g. "terminal" → open_terminal, "install" →         │
│  open_packages). Adds info finding listing actions.     │
└──────────────────────────┬──────────────────────────────┘
                           ▼
┌─────────────────────────────────────────────────────────┐
│ Stage 5 — AgentCoordinator (finalize)                   │
│  Aggregates all findings. Sets verdict:                 │
│    blocked  — any error finding                         │
│    warning  — warnings only                             │
│    ok       — no findings above info                    │
│  Builds human-readable summary string.                  │
└──────────────────────────┬──────────────────────────────┘
                           ▼
                    AgentTask (final)
                    .verdict + .summary
```

### Agent inputs / outputs

| Agent | Reads from AgentTask | Writes to AgentTask |
|---|---|---|
| SafetyAgent | `referencedFiles`, `userInput`, `codeSnippet` | Adds `AgentFinding` (error) |
| CodeReviewAgent | `codeSnippet` | Adds `AgentFinding` (error/warning) |
| TestAgent | `codeSnippet`, `intent` | Adds `AgentFinding` (warning/info) |
| ActionAgent | `userInput` | Adds `AgentFinding` (info) + `AgentAction` list |
| AgentCoordinator | all findings | Sets `verdict`, `summary` |

---

## AgentTask model

Defined in `lib/features/ai_assistant/models/agent_task.dart`.

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

enum AgentVerdict { ok, warning, blocked }
enum FindingSeverity { info, warning, error }
```

`AgentTask` is immutable; each stage returns a new instance via `.copyWith()`.

---

## AiOrchestratorService API

```dart
// Single-agent routing (returns routing metadata only, no pipeline)
RoutingDecision route(String userContent)

// Full 5-stage pipeline (returns finalized AgentTask)
AgentTask runPipeline(String userContent, {
  String? codeSnippet,
  List<String>? referencedFiles,
})
```

Use `route()` when you only need to know which domain agent owns the request (e.g. to build a system prompt for a direct Ollama call). Use `runPipeline()` when you want the full safety + review + action analysis.

### Usage example

```dart
final orchestrator = AiOrchestratorService(
  registry: AgentRegistry(),
  guardrails: AiGuardrailsService(),
);

// Run full pipeline
final task = orchestrator.runPipeline(
  'Fix the login bug in auth_service.dart',
  codeSnippet: dartCode,
  referencedFiles: ['lib/core/services/auth_service.dart'],
);

print(task.verdict);  // AgentVerdict.warning (or .blocked / .ok)
print(task.summary);  // Human-readable pipeline report
```

---

## OllamaService

`lib/core/services/ollama_service.dart` — direct HTTP client for Ollama.

```dart
OllamaService({String? baseUrl, String? model})
// Defaults: baseUrl = 'http://localhost:11434', model = 'mistral-medium-3.5:latest'

Future<String> generateCode(String prompt, {double temperature, int maxTokens})
Future<String> chat(List<ChatMessage> messages, {double temperature})
Stream<String> chatStream(List<ChatMessage> messages, {double temperature})
Future<bool> isAvailable()
Future<List<String>> listModels()
Future<List<OllamaModel>> listModelsDetailed()
```

Timeouts: 30 s connect, 120 s receive. Throws `OllamaException` on connection errors or 404.

---

## Ollama setup

```bash
# Install
curl -fsSL https://ollama.com/install.sh | sh

# Pull the default model
ollama pull mistral-medium-3.5

# Start server (default port 11434)
ollama serve

# Verify
curl http://localhost:11434/api/version
```

---

## Error handling

| Condition | Behaviour |
|---|---|
| Ollama not running | `OllamaException` — "Cannot reach Ollama at …" |
| Model not found (404) | `OllamaException` — endpoint not found message |
| Parse failure | Falls back to conservative defaults |
| SafetyAgent blocks | `AgentVerdict.blocked` + error finding in summary |
