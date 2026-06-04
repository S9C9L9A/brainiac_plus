# BrainiacPlus

> Cross-platform system assistant for Linux desktop and Android, with social media automation and local AI.

[![Flutter](https://img.shields.io/badge/Flutter-3.10%2B-02569B?logo=flutter)](https://flutter.dev)
[![Go](https://img.shields.io/badge/Go-1.21%2B-00ADD8?logo=go)](https://go.dev)
[![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20Android-lightgrey)]()

---

## What it does

| Module | Purpose |
|---|---|
| **Dashboard** | Real-time CPU / RAM / disk / battery metrics |
| **Automation** | Schedule tasks, macros, conditional triggers |
| **AI Assistant** | Chat + code generation via local Ollama |
| **Social** | Facebook & Instagram publishing via Graph API |
| **Packages** | apt / snap / flatpak (Linux), APK (Android) |
| **Terminal** | Embedded shell with history (xterm.dart) |
| **File Manager** | Dual-pane browser, optional root mode |

---

## Quick start

### Prerequisites
- Flutter SDK ≥ 3.10 ([install](https://docs.flutter.dev/get-started/install/linux))
- Go ≥ 1.21 (`sudo apt install golang-go`)
- Ollama for AI features (`curl -fsSL https://ollama.com/install.sh | sh`)

### Run

```bash
# 1. Backend
cd go_backend
cp .env.example .env          # fill in your secrets
go mod tidy
go run .                      # listens on :8080

# 2. Frontend (new terminal)
flutter pub get
flutter run -d linux          # or -d <android-device-id>
```

### Verify
```bash
curl http://localhost:8080/health
```

---

## Architecture

```
┌─────────────────────┐    HTTP     ┌──────────────────┐
│  Flutter App        │◄───────────►│  Go Backend      │
│  (Linux / Android)  │  :8080      │  (Gin + JWT)     │
└─────────┬───────────┘             └────────┬─────────┘
          │                                  │
          │ local                            │ Graph API
          ▼                                  ▼
    ┌──────────┐                  ┌────────────────────┐
    │  Ollama  │                  │ Facebook /         │
    │  :11434  │                  │ Instagram          │
    └──────────┘                  └────────────────────┘
```

Full diagram: [`docs/architecture/SYSTEM_ARCHITECTURE.md`](docs/architecture/SYSTEM_ARCHITECTURE.md)

---

## Project layout

```
brainiac_plus/
├── lib/                       # Flutter app (Dart)
│   ├── core/                  # Shared services (db, theme, network, platform)
│   ├── features/              # Feature modules (one folder per domain)
│   │   ├── ai_assistant/
│   │   ├── automation/
│   │   ├── dashboard/
│   │   ├── file_manager/
│   │   ├── onboarding/
│   │   ├── packages/
│   │   ├── settings/
│   │   └── terminal/
│   └── routes/                # Navigation
├── go_backend/                # Go REST API
│   ├── main.go
│   ├── routes/                # HTTP handlers
│   ├── services/              # Business logic (Facebook, JWT, …)
│   └── models/                # Data structures
├── test/                      # Dart unit / widget tests
├── scripts/                   # Shell scripts (test runners, demos)
├── docs/                      # Documentation
│   ├── architecture/          # System design
│   ├── setup/                 # Setup guides
│   └── guides/                # Operations / maintenance
├── android/  linux/  tool/    # Platform-specific & Dart CLI tools
└── .github/agents/            # AI agent definitions (multi-agent routing)
```

---

## Tech stack

**Frontend**
- Flutter 3.10 · Dart 3.x
- State: [Riverpod 2.x](https://riverpod.dev/)
- DB: [sqflite](https://pub.dev/packages/sqflite) (+ ffi for desktop)
- UI: glassmorphism design system, Lucide icons
- Charts: [fl_chart](https://pub.dev/packages/fl_chart)
- Terminal: [xterm](https://pub.dev/packages/xterm)

**Backend**
- [Gin](https://gin-gonic.com/) HTTP framework
- JWT auth
- Facebook & Instagram Graph API integrations

**AI**
- [Ollama](https://ollama.com/) local model server (default `localhost:11434`)
- Default model: `mistral-medium-3.5:latest` (see [GPU optimization](docs/GPU_OPTIMIZATION.md)); also tested with CodeLlama, Llama2, Mistral 7B

---

## Common commands

```bash
flutter run -d linux           # dev with hot reload
flutter test                   # run tests
flutter analyze                # lint
flutter build linux            # release build
flutter build apk              # Android release

cd go_backend && go run .      # dev backend
cd go_backend && go test ./... # backend tests
cd go_backend && go build      # production binary
```

---

## Documentation

- [Setup → Quick Start](docs/setup/QUICK_START.md)
- [Architecture overview](docs/architecture/SYSTEM_ARCHITECTURE.md)
- [Go backend guide](docs/architecture/GO_BACKEND_GUIDE.md)
- [Maintenance](docs/guides/MAINTENANCE_GUIDE.md)
- [AI agents (multi-agent dev workflow)](.github/agents/README.md)
- [Claude Code instructions](.claude/CLAUDE.md)
- [Terminal dashboard guide](docs/DASHBOARD_GUIDE.md)
- [GPU / ROCm optimization](docs/GPU_OPTIMIZATION.md)

---

## Security

- **Never commit `.env`** — it's in `.gitignore`. Use `go_backend/.env.example` as template.
- Rotate any token / secret if accidentally pushed.
- Issues: please email rather than open a public ticket.

---

## License

Proprietary — Codebase S.R.L.
