# 🧠 BrainiacPlus - Claude Code Instructions

> **Data Aggiornamento**: 2026-03-07
> **Versione**: 2.0.0

Questo file definisce le istruzioni per Claude Code e gli agenti AI che lavorano su questo progetto.

---

## 🎯 Progetto in Sintesi

**BrainiacPlus** è un'app Flutter multi-piattaforma (Linux/Android) per:
- Automazione social media (Facebook, Instagram, YouTube)
- System monitoring e gestione risorse
- AI Assistant con auto-modifica via Ollama
- Terminal emulator e file manager integrati

---

## ✅ PROMPT CONTRACT (SEMPRE ATTIVO)

Per **ogni** richiesta in questo progetto:

1. **Conferma allineamento** alla AI_VISION in `.github/agents/AI_VISION.md`
2. **Seleziona l'agente** appropriato dal Domain Routing Table
3. **Dichiara i path** consentiti prima di modificare file
4. **Se multi-dominio**, dividi le task o chiedi approvazione
5. **Non modificare** file bloccati senza richiesta esplicita

---

## 🚫 FILE BLOCCATI (Richiesta Esplicita Necessaria)

```
pubspec.yaml          # Dipendenze Flutter
lib/main.dart         # Entry point app
go_backend/.env       # Secrets e credenziali
android/app/build.gradle.kts  # Configurazione Android
```

---

## 🗂️ DOMAIN ROUTING TABLE

| Dominio | Agente | Path Consentiti |
|---------|--------|-----------------|
| AI/Ollama | `ai_assistant` | `lib/features/ai_assistant/`, `lib/core/services/ollama_*` |
| Dashboard | `dashboard` | `lib/features/dashboard/` |
| Terminal | `terminal` | `lib/features/terminal/` |
| Packages | `packages` | `lib/features/packages/` |
| Automation | `automation` | `lib/features/automation/` |
| Settings | `settings` | `lib/features/settings/` |
| File Manager | `file_manager` | `lib/features/file_manager/` |
| Onboarding | `onboarding` | `lib/features/onboarding/` |
| Activity | `activity` | `lib/features/activity/` |
| Core/Platform | `core` | `lib/core/` |
| Backend Go | `backend` | `go_backend/` |
| Testing | `testing` | `test/` |
| Docs | `docs` | `docs/` |

---

## 📁 STRUTTURA PROGETTO

```
brainiac_plus/
├── lib/
│   ├── main.dart                 # Entry point (BLOCCATO)
│   ├── core/                     # Servizi condivisi
│   │   ├── database/             # SQLite layer
│   │   ├── platform/             # Linux/Android services
│   │   ├── services/             # Business logic services
│   │   ├── theme/                # Design system
│   │   └── providers/            # Riverpod providers globali
│   ├── features/                 # Feature modules
│   │   ├── ai_assistant/         # 🤖 AI Chat & Code Gen
│   │   ├── automation/           # ⚡ Task automation
│   │   ├── dashboard/            # 📊 System metrics
│   │   ├── file_manager/         # 📂 File browser
│   │   ├── onboarding/           # 🎯 Setup wizard
│   │   ├── packages/             # 📦 APT/Snap manager
│   │   ├── settings/             # ⚙️ App settings
│   │   └── terminal/             # 🖥️ Shell emulator
│   ├── routes/                   # Navigation config
│   └── shared/                   # Shared widgets
├── go_backend/                   # Go REST API
│   ├── main.go                   # Server entry
│   ├── routes/                   # HTTP handlers
│   ├── services/                 # Business logic
│   └── models/                   # Data structures
├── test/                         # Test suite
├── docs/                         # Documentation
└── .github/agents/               # Agent definitions
```

---

## 🧩 TECH STACK

### Frontend (Flutter)
- **State Management**: Riverpod 2.x
- **Icons**: Lucide Icons via `lib/core/theme/app_icons.dart`
- **UI**: Glassmorphism design system
- **Database**: SQLite via sqflite
- **Platform**: Linux primary, Android secondary

### Backend (Go)
- **Framework**: Gin HTTP
- **APIs**: Facebook Graph, Instagram Graph, Ollama
- **Auth**: JWT tokens
- **Port**: localhost:8080

### AI Integration
- **Model Server**: Ollama (localhost:11434)
- **Models**: CodeLlama 7B, Llama2, Mistral
- **Purpose**: Code generation, self-modification

---

## 🔧 COMANDI SVILUPPO

```bash
# Avvia app Flutter
flutter run -d linux

# Avvia backend Go
cd go_backend && go run main.go

# Test
flutter test

# Analisi codice
flutter analyze
```

---

## 📋 CONVENZIONI CODICE

### Dart/Flutter
```dart
// File naming: snake_case
// Classes: PascalCase
// Functions/variables: camelCase
// Constants: lowerCamelCase

// State: Riverpod providers
final myProvider = StateNotifierProvider<MyNotifier, MyState>((ref) => ...);

// Widgets: StatelessWidget preferito
class MyWidget extends ConsumerWidget { ... }

// Theme: usa sempre AppTheme
Container(
  decoration: GlassmorphismDecoration.card(),
  child: ...
)

// Icons: usa sempre AppIcons
Icon(AppIcons.settings)
```

### Go
```go
// Package naming: lowercase
// Public functions: PascalCase
// Private functions: camelCase
// Error handling: sempre gestito

func HandleRequest(c *gin.Context) {
    if err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }
}
```

---

## 🤖 AGENTI DISPONIBILI

Vedi `.github/agents/README.md` per la documentazione completa.

| Agente | Descrizione |
|--------|-------------|
| `orchestrator` | Coordina routing tra agenti |
| `ai_assistant` | AI chat e code generation |
| `core` | Design system e platform services |
| `dashboard` | System monitoring UI |
| `terminal` | Shell emulator |
| `packages` | Package manager |
| `automation` | Task scheduler |
| `settings` | App configuration |
| `file_manager` | File browser |
| `backend` | Go REST API |
| `testing` | Test suite |
| `docs` | Documentation |

---

## ⚠️ SAFETY CONSTRAINTS

### AI PUÒ:
- ✅ Generare nuovi widget/screens
- ✅ Creare automation tasks
- ✅ Modificare UI esistente (con preview)
- ✅ Aggiungere features in sandbox

### AI NON PUÒ:
- ❌ Modificare core files senza approval
- ❌ Eseguire comandi distruttivi
- ❌ Accedere a credentials/secrets
- ❌ Modificare security settings
- ❌ Pushare codice senza review

---

## 📚 DOCUMENTAZIONE

- **Vision**: `.github/agents/AI_VISION.md`
- **Architecture**: `docs/architecture/SYSTEM_ARCHITECTURE.md`
- **Setup**: `docs/setup/QUICK_START.md`
- **Agents**: `.github/agents/README.md`
