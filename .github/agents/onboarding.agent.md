# 🎯 Onboarding Agent

**Dominio**: `lib/features/onboarding/`

---

## 🎯 Responsabilità

- Setup wizard per nuovi utenti
- Configurazione iniziale servizi
- Guided tour delle features
- Permission requests (Linux/Android)
- First-run experience

---

## 📁 Files Owned

```
lib/features/onboarding/
├── controllers/
│   └── onboarding_controller.dart    # Wizard state management
├── models/
│   ├── onboarding_step.dart          # Step model
│   └── setup_config.dart             # Initial config
├── screens/
│   ├── onboarding_screen.dart        # Main wizard screen
│   ├── welcome_screen.dart           # Welcome page
│   ├── service_setup_screen.dart     # Service configuration
│   └── completion_screen.dart        # Setup complete
└── widgets/
    ├── step_indicator.dart           # Progress indicator
    ├── service_card.dart             # Service setup card
    └── permission_request.dart       # Permission request UI
```

---

## 🔧 Capabilities

- ✅ Multi-step wizard con progress tracking
- ✅ Configurazione social media accounts
- ✅ Ollama detection e setup
- ✅ Permission handling (file access, notifications)
- ✅ Skip/Resume wizard functionality
- ✅ Onboarding completion persistence

---

## 📋 Wizard Steps

| Step | Title | Optional |
|------|-------|----------|
| 1 | Welcome | No |
| 2 | Theme Selection | Yes |
| 3 | Social Media Setup | Yes |
| 4 | AI/Ollama Setup | Yes |
| 5 | Permissions | No (Linux) |
| 6 | Completion | No |

---

## 🔗 Dipendenze

- `settings.agent.md` → Salvataggio configurazione
- `core.agent.md` → Platform services per permissions
- `ai_assistant.agent.md` → Ollama detection

---

## 📖 Esempio Uso

```dart
// Check if onboarding needed
final needsOnboarding = ref.watch(onboardingNeededProvider);

if (needsOnboarding) {
  Navigator.push(context, OnboardingScreen.route());
}

// Complete step
ref.read(onboardingControllerProvider.notifier).completeStep(2);

// Skip to end
ref.read(onboardingControllerProvider.notifier).skipOnboarding();
```

---

## 🎨 UI Guidelines

- Usa `PageView` per navigazione tra steps
- Animazioni smooth tra pagine
- Progress indicator sempre visibile
- Back button su ogni step (tranne welcome)
- "Skip" option per steps opzionali
