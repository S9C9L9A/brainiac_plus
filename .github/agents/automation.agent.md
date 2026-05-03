# ⚡ Automation Agent

**Dominio**: `lib/features/automation/`

---

## 🎯 Responsabilità

- Task scheduling e gestione cron jobs
- Social media automation (Facebook, Instagram, YouTube)
- Browser automation actions
- Workflow builder e template system
- Execution engine e retry logic

---

## 📁 Files Owned

```
lib/features/automation/
├── automation_screen.dart           # Main UI screen
├── controllers/
│   ├── automation_controller.dart   # State management
│   └── workflow_controller.dart     # Workflow orchestration
├── models/
│   ├── automation_task.dart         # Task model
│   ├── automation_template.dart     # Template model
│   ├── workflow_step.dart           # Workflow step
│   └── schedule_config.dart         # Cron configuration
├── providers/
│   └── automation_providers.dart    # Riverpod providers
├── screens/
│   ├── automation_list_screen.dart  # Task list
│   ├── automation_edit_screen.dart  # Task editor
│   └── template_gallery_screen.dart # Template browser
├── services/
│   ├── automation_service.dart      # Core automation logic
│   └── template_service.dart        # Template management
└── widgets/
    ├── automation_card.dart         # Task card widget
    ├── schedule_picker.dart         # Cron schedule UI
    └── workflow_builder.dart        # Visual workflow editor
```

### Related Core Services
```
lib/core/services/
├── automation_assistant_service.dart  # AI-assisted automation
├── automation_engine.dart             # Execution engine
├── browser_actions_service.dart       # Browser automation
├── browser_action_templates.dart      # Action templates
├── task_scheduler.dart                # Cron scheduler
├── task_scheduler_service.dart        # Scheduler service
├── instagram_service.dart             # Instagram API
├── instagram_cli_service.dart         # Instagram CLI
└── higgsfield_service.dart            # Higgsfield integration
```

---

## 🔧 Capabilities

- ✅ Creare/modificare automation tasks
- ✅ Definire schedule (cron expressions)
- ✅ Gestire workflow multi-step
- ✅ Template gallery per azioni comuni
- ✅ Retry logic e error handling
- ✅ Logging e history delle esecuzioni

---

## 📋 Task Types Supportati

| Type | Description | Platform |
|------|-------------|----------|
| `social_post` | Pubblica su social media | Facebook, Instagram |
| `browser_action` | Automazione browser | Linux |
| `file_operation` | Operazioni su file | Linux |
| `shell_command` | Esegui comandi shell | Linux |
| `api_call` | Chiamata REST API | Cross-platform |
| `notification` | Invia notifica | Cross-platform |

---

## 🔗 Dipendenze

- `core.agent.md` → Database, Platform services
- `ai_assistant.agent.md` → AI-assisted task creation
- `settings.agent.md` → Social media credentials

---

## 📖 Esempio Uso

```dart
// Crea un task di post schedulato
final task = AutomationTask(
  name: 'Daily Instagram Post',
  type: TaskType.socialPost,
  schedule: '0 9 * * *', // Ogni giorno alle 9:00
  config: {
    'platform': 'instagram',
    'caption': 'Good morning! ☀️',
    'mediaPath': '/path/to/image.jpg',
  },
);
await automationService.createTask(task);
```
