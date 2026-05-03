# 🕐 Activity Agent

**Dominio**: `lib/features/activity/`

---

## 🎯 Responsabilità

- Tracciamento attività recenti
- History delle operazioni
- Activity feed e timeline
- Notifications center
- Usage analytics (locale)

---

## 📁 Files Owned

```
lib/features/activity/
├── recent_activity_screen.dart       # Main activity screen
├── controllers/
│   └── activity_controller.dart      # Activity state
├── models/
│   ├── activity_item.dart            # Activity model
│   └── activity_filter.dart          # Filter options
├── providers/
│   └── activity_providers.dart       # Riverpod providers
└── widgets/
    ├── activity_card.dart            # Activity item widget
    ├── activity_timeline.dart        # Timeline view
    └── filter_chips.dart             # Filter UI
```

---

## 🔧 Capabilities

- ✅ Log tutte le operazioni app
- ✅ Filter per tipo (automation, file, terminal, etc.)
- ✅ Search activity history
- ✅ Clear history (selective/all)
- ✅ Export activity log
- ✅ Real-time activity feed

---

## 📋 Activity Types

| Type | Icon | Source |
|------|------|--------|
| `automation_run` | ⚡ | Automation engine |
| `social_post` | 📱 | Social media service |
| `file_operation` | 📂 | File manager |
| `terminal_command` | 🖥️ | Terminal |
| `ai_generation` | 🤖 | AI Assistant |
| `settings_change` | ⚙️ | Settings |
| `error` | ❌ | Any source |

---

## 🔗 Dipendenze

- `core.agent.md` → Database per persistence
- `automation.agent.md` → Automation events
- `ai_assistant.agent.md` → AI generation events

---

## 📖 Esempio Uso

```dart
// Log activity
ref.read(activityControllerProvider.notifier).log(
  ActivityItem(
    type: ActivityType.automationRun,
    title: 'Instagram Post Published',
    description: 'Photo posted to @myaccount',
    timestamp: DateTime.now(),
  ),
);

// Get recent activities
final activities = ref.watch(recentActivitiesProvider);

// Filter by type
final automationOnly = ref.watch(
  filteredActivitiesProvider(ActivityType.automationRun)
);
```

---

## 🗄️ Storage

Activities stored in SQLite:
```sql
CREATE TABLE activities (
  id INTEGER PRIMARY KEY,
  type TEXT NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  metadata TEXT,  -- JSON
  timestamp INTEGER NOT NULL,
  read INTEGER DEFAULT 0
);
```

Max retention: 30 days (configurable in settings)
