# BrainiacPlus — Claude Code Instructions

> **Last updated**: 2026-05-03
> **Project version**: 2.0.0

Rules and context for Claude Code (and any AI agent) working on this repo.

---

## Project in one paragraph

BrainiacPlus is a multi-platform Flutter app (Linux primary, Android secondary, v2.0.0)
backed by a Go REST API on `localhost:8080`. It does social-media automation
(Facebook + Instagram via Graph API), system monitoring (CPU/RAM/disk), an
embedded terminal & file manager, package management, task scheduling, and an
AI assistant powered by a local Ollama server on `localhost:11434`.

---

## Prompt contract (always on)

For every request in this repo:

1. **Confirm alignment** with [`.github/agents/AI_VISION.md`](.github/agents/AI_VISION.md).
2. **Pick the domain agent** from the routing table below.
3. **State allowed paths** before editing.
4. **Multi-domain change** → split or ask approval.
5. **Locked files** → require explicit user request.

---

## 🔒 Locked files (explicit request required)

| File | Why |
|---|---|
| `pubspec.yaml` | Flutter dependencies — version drift breaks the lockfile |
| `lib/main.dart` | App entry point |
| `go_backend/.env` | Secrets — never commit. Now in `.gitignore`. |
| `android/app/build.gradle.kts` | Android build config |

---

## Domain routing

| Domain | Agent | Allowed paths |
|---|---|---|
| AI / Ollama | `ai_assistant` | `lib/features/ai_assistant/`, `lib/core/services/ollama_*` |
| Dashboard | `dashboard` | `lib/features/dashboard/` |
| Terminal | `terminal` | `lib/features/terminal/` |
| Packages | `packages` | `lib/features/packages/` |
| Automation | `automation` | `lib/features/automation/` |
| Settings | `settings` | `lib/features/settings/` |
| File Manager | `file_manager` | `lib/features/file_manager/` |
| Onboarding | `onboarding` | `lib/features/onboarding/` |
| Activity | `activity` | `lib/features/activity/` |
| Core / Platform | `core` | `lib/core/` |
| Backend (Go) | `backend` | `go_backend/` |
| Testing | `testing` | `test/` |
| Docs | `docs` | `docs/` |

Agent definitions live in [`.github/agents/`](.github/agents/).

---

## Project structure

```
brainiac_plus/
├── lib/                       # Flutter app (Dart)
│   ├── main.dart              # 🔒 entry point
│   ├── core/                  # Shared infra
│   │   ├── database/          # SQLite layer
│   │   ├── debug/
│   │   ├── navigation/
│   │   ├── network/           # HTTP / API client
│   │   ├── platform/          # Linux/Android-specific
│   │   ├── providers/         # Global Riverpod providers
│   │   ├── services/          # Business services (Ollama, scheduler, …)
│   │   ├── theme/             # Glassmorphism design system
│   │   └── utils/
│   ├── features/              # One folder per domain
│   │   ├── activity/
│   │   ├── ai_assistant/      # 🤖 chat + code generation
│   │   ├── automation/        # ⚡ task scheduler & macros
│   │   ├── dashboard/         # 📊 metrics
│   │   ├── file_manager/      # 📂 dual-pane browser
│   │   ├── onboarding/        # 🎯 setup wizard
│   │   ├── packages/          # 📦 apt/snap/flatpak
│   │   ├── settings/          # ⚙️
│   │   └── terminal/          # 🖥️ xterm.dart
│   └── routes/                # Navigation
├── go_backend/                # Go REST API (Gin + JWT)
│   ├── main.go                # entry
│   ├── routes/                # HTTP handlers
│   ├── services/              # Business logic
│   └── models/                # Data structures
├── test/                      # Dart unit / widget tests
├── tool/                      # Dart CLI tools (instagram_cli_runner, litellm)
├── scripts/                   # Shell scripts (test runners, demos)
├── docs/                      # Documentation (see docs/README.md)
├── android/  linux/           # Platform-specific Flutter builds
└── .github/agents/            # Multi-agent definitions
```

---

## Tech stack

**Frontend**
- Flutter 3.10+, Dart 3.x
- State: Riverpod 2.x — **note**: `provider` package is also in `pubspec` (legacy, candidate for removal)
- Icons: Lucide via `lib/core/theme/app_icons.dart`
- DB: sqflite (+ ffi for desktop)
- UI: Glassmorphism via `lib/core/theme/`

**Backend**
- Gin HTTP framework
- JWT auth
- Facebook + Instagram Graph API integrations
- Default port: `8080`

**AI**
- Ollama on `localhost:11434`
- Tested: CodeLlama 7B, Llama2, Mistral
- Use case: code generation, self-modification, automation suggestions

---

## Dev commands

```bash
# Frontend
flutter pub get
flutter run -d linux           # hot-reload dev loop (preferred)
flutter test
flutter analyze

# Backend
cd go_backend
cp .env.example .env           # one-time, fill in secrets
go mod tidy
go run .                       # listens on :8080
go test ./...

# Smoke test
curl http://localhost:8080/health
```

---

## Code conventions

### Dart / Flutter
```dart
// Files: snake_case
// Classes: PascalCase
// Functions/vars: camelCase
// Constants: lowerCamelCase

// State via Riverpod
final myProvider = StateNotifierProvider<MyNotifier, MyState>((ref) => ...);

// Prefer ConsumerWidget for stateful UI
class MyWidget extends ConsumerWidget { ... }

// Always use the design system
Container(decoration: GlassmorphismDecoration.card(), child: ...);
Icon(AppIcons.settings);
```

### Go
```go
// packages: lowercase
// Public funcs: PascalCase, private: camelCase
// Always handle errors

func HandleRequest(c *gin.Context) {
    if err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }
}
```

---

## ⚠️ Known code-health flags

For future sessions, candidates for refactor (none auto-fixed — they need
running tests to be safe):

- **Two task schedulers**: `lib/core/services/task_scheduler.dart` and
  `task_scheduler_service.dart`. Likely a duplicate; consolidate into one.
- **Three Instagram services**: `instagram_service.dart`, `instagram_oauth_service.dart`,
  `instagram_cli_service.dart` in `lib/core/services/`. Verify if separation
  is intentional (OAuth vs CLI vs API), otherwise merge.
- **Dual state libs**: `pubspec.yaml` ships both `flutter_riverpod` and `provider`.
  Pick one (prefer Riverpod) and remove the other after migrating consumers.
- **Deep nesting**: `lib/features/settings/screens/modern/tabs/` is one level
  too deep — flatten when next touching settings.
- **Routes barrel unused**: `lib/routes/routes.dart` re-exports the others but
  no file imports the barrel. Either adopt it everywhere or delete it.

---

## Safety constraints

### AI may
- ✅ Generate new widgets / screens
- ✅ Create automation tasks
- ✅ Modify existing UI (with preview)
- ✅ Add features in sandbox

### AI must NOT
- ❌ Modify locked files without explicit approval
- ❌ Run destructive shell commands without approval
- ❌ Read or write secrets / credentials
- ❌ Modify security settings
- ❌ Push code without review
- ❌ Force-push or rewrite git history without explicit approval

---

## Documentation map

- **Vision**: [`.github/agents/AI_VISION.md`](.github/agents/AI_VISION.md)
- **Docs index**: [`docs/README.md`](docs/README.md)
- **Architecture**: [`docs/architecture/SYSTEM_ARCHITECTURE.md`](docs/architecture/SYSTEM_ARCHITECTURE.md)
- **Setup**: [`docs/setup/QUICK_START.md`](docs/setup/QUICK_START.md)
- **Agents**: [`.github/agents/README.md`](.github/agents/README.md)
- **README**: [`README.md`](README.md)
