# ⚙️ Core Agent

**Dominio**: `lib/core/`

---

## 🎯 Responsabilità

- Design system (theme, glassmorphism)
- Database layer (SQLite)
- Platform services (Linux/Android)
- Shared utilities e helpers
- Global providers
- Network/API client

---

## 📁 Files Owned

```
lib/core/
├── database/
│   └── automation_database.dart      # SQLite operations
├── debug/
│   └── debug_utils.dart              # Debug helpers
├── navigation/
│   └── app_router.dart               # Navigation config
├── network/
│   └── api_client.dart               # HTTP client
├── platform/
│   ├── linux_platform.dart           # Linux services
│   ├── shell_service.dart            # Shell execution
│   └── package_service.dart          # Package management
├── providers/
│   └── global_providers.dart         # Shared providers
├── services/
│   ├── automation_assistant_service.dart
│   ├── automation_engine.dart
│   ├── browser_actions_service.dart
│   ├── browser_action_templates.dart
│   ├── hardware_detection_service.dart
│   ├── higgsfield_service.dart
│   ├── instagram_cli_service.dart
│   ├── instagram_oauth_service.dart
│   ├── instagram_service.dart
│   ├── local_ai_installer.dart
│   ├── model_suggestions_service.dart
│   ├── ollama_service.dart
│   ├── system_metrics_service.dart
│   ├── task_scheduler.dart
│   └── task_scheduler_service.dart
├── theme/
│   ├── app_theme.dart                # Theme definition
│   ├── colors.dart                   # Color palette
│   ├── glassmorphism.dart            # Glass effects
│   └── app_icons.dart                # Lucide icons
└── utils/
    └── helpers.dart                  # Utility functions
```

---

## 🔧 Capabilities

- ✅ Migliorare design system (colori, effetti)
- ✅ Ottimizzare database queries
- ✅ Aggiungere platform services
- ✅ Logging, analytics, caching
- ✅ Gestire system metrics
- ✅ Network layer e API client

---

## 📋 Services Overview

| Service | Description | Used By |
|---------|-------------|---------|
| `ollama_service` | Ollama API client | AI Assistant |
| `system_metrics_service` | CPU/RAM/Disk metrics | Dashboard |
| `automation_engine` | Task execution | Automation |
| `shell_service` | Command execution | Terminal |
| `instagram_service` | Instagram API | Automation |

---

## 🔗 Dipendenze

- Nessuna (è la base per tutti gli altri agenti)

---

## 📖 Esempio Uso

```dart
// Theme
Container(
  decoration: GlassmorphismDecoration.card(),
  child: Text('Hello', style: AppTheme.bodyLarge),
)

// Icons
Icon(AppIcons.dashboard, color: AppColors.primary)

// Database
final db = ref.read(databaseProvider);
await db.insertAutomation(task);

// System metrics
final metrics = await ref.read(systemMetricsServiceProvider).loadMetrics();
print('CPU: ${metrics.cpuUsagePercent}%');
```

---

## 🎨 Design System

### Colors
```dart
AppColors.primary      // Main accent color
AppColors.background   // App background
AppColors.surface      // Card surfaces
AppColors.text         // Primary text
AppColors.textMuted    // Secondary text
```

### Glassmorphism
```dart
GlassmorphismDecoration.card()      // Standard card
GlassmorphismDecoration.panel()     // Side panels
GlassmorphismDecoration.dialog()    // Dialogs
```

### Icons (Lucide)
```dart
AppIcons.dashboard
AppIcons.terminal
AppIcons.settings
AppIcons.automation
// ... 100+ icons disponibili
```
