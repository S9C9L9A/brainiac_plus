# 🤖 BrainiacPlus - Multi-Agent System

Sistema di agenti specializzati per la manutenzione del progetto BrainiacPlus.

> **Versione**: 2.0.0 | **Data**: 2026-03-07

---

## 📁 Struttura Agenti

```
.github/agents/
├── README.md                   → Questa guida
├── AI_VISION.md               → Vision e constraints del progetto
├── EXAMPLE_USAGE.md           → Esempi di utilizzo
│
├── orchestrator.agent.md      → 🎯 Coordinatore centrale
│
├── ai_assistant.agent.md      → 🤖 AI Chat & Code Generation
├── automation.agent.md        → ⚡ Task Automation
├── dashboard.agent.md         → 📊 System Monitoring
├── terminal.agent.md          → 🖥️ Shell Emulator
├── packages.agent.md          → 📦 Package Manager
├── settings.agent.md          → ⚙️ App Settings
├── file_manager.agent.md      → 📂 File Browser
├── onboarding.agent.md        → 🎯 Setup Wizard
├── activity.agent.md          → 🕐 Activity Tracking
│
├── core.agent.md              → ⚙️ Core Services
├── backend.agent.md           → 🔧 Go REST API
├── testing.agent.md           → 🧪 Test Suite
├── docs.agent.md              → 📚 Documentation
│
└── UpdateRecords/             → Change logs
```

---

## 🗂️ Domain Routing Table

| Agent | Dominio | Path Consentiti |
|-------|---------|-----------------|
| `orchestrator` | Coordination | Routing only, no files |
| `ai_assistant` | AI/Ollama | `lib/features/ai_assistant/`, `lib/core/services/ollama_*` |
| `automation` | Task Scheduler | `lib/features/automation/`, `lib/core/services/automation_*` |
| `dashboard` | Monitoring | `lib/features/dashboard/` |
| `terminal` | Shell | `lib/features/terminal/` |
| `packages` | APT/Snap | `lib/features/packages/` |
| `settings` | Config | `lib/features/settings/` |
| `file_manager` | Files | `lib/features/file_manager/` |
| `onboarding` | Setup | `lib/features/onboarding/` |
| `activity` | History | `lib/features/activity/` |
| `core` | Platform | `lib/core/` |
| `backend` | REST API | `go_backend/` |
| `testing` | Tests | `test/` |
| `docs` | Docs | `docs/` |

---

## 🔄 Workflow

```
┌─────────────────────────────────────────────┐
│              USER REQUEST                    │
└─────────────────────┬───────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────┐
│           ORCHESTRATOR AGENT                 │
│                                              │
│  1. Analizza la richiesta                   │
│  2. Identifica domini coinvolti             │
│  3. Verifica constraints (AI_VISION)        │
│  4. Seleziona sub-agent appropriato         │
│  5. Delega con path constraints             │
└─────────────────────┬───────────────────────┘
                      │
        ┌─────────────┼─────────────┐
        ▼             ▼             ▼
  ┌──────────┐  ┌──────────┐  ┌──────────┐
  │ Agent A  │  │ Agent B  │  │ Agent C  │
  │ (domain) │  │ (domain) │  │ (domain) │
  └──────────┘  └──────────┘  └──────────┘
```

---

## ✨ Vantaggi

- ✅ **Separation of Concerns**: Ogni agente ha responsabilità chiare
- ✅ **Path Isolation**: Agenti lavorano solo nei loro domini
- ✅ **Conflict Prevention**: Orchestrator previene modifiche conflittuali
- ✅ **Safety**: File bloccati richiedono approval esplicito
- ✅ **Traceability**: Ogni modifica è tracciabile all'agente

---

## 🚫 File Bloccati

Questi file richiedono **approvazione esplicita** per essere modificati:

```
pubspec.yaml           # Dipendenze Flutter
lib/main.dart          # Entry point
go_backend/.env        # Secrets
android/app/build.gradle.kts  # Build config
```

---

## 📝 Esempi Uso

### Single Domain
```
User: "Aggiungi colori ANSI al terminal"
Orchestrator → Seleziona terminal.agent
Terminal Agent → Modifica lib/features/terminal/
Result → Colori ANSI implementati
```

### Multi-Domain
```
User: "Crea un widget che mostra metriche CPU nella dashboard AI"
Orchestrator → Identifica: dashboard + ai_assistant
Orchestrator → Split task:
  1. dashboard.agent → Crea widget metrica
  2. ai_assistant.agent → Integra in AI panel
Result → Widget integrato in entrambi i domini
```

### Con File Bloccato
```
User: "Aggiungi una nuova dipendenza"
Orchestrator → Richiede modifica a pubspec.yaml (BLOCCATO)
Orchestrator → ⚠️ Chiede conferma esplicita
User → "Sì, procedi"
Orchestrator → Modifica approvata
```

---

## 📚 Documentazione Aggiuntiva

- **Vision**: `AI_VISION.md`
- **Root Instructions**: `/CLAUDE.md`
- **Architecture**: `/docs/architecture/SYSTEM_ARCHITECTURE.md`
- **Examples**: `EXAMPLE_USAGE.md`