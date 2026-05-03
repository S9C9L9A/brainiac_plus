# 📊 Dashboard Agent

**Dominio**: `lib/features/dashboard/`

---

## 🎯 Responsabilità

- Real-time system monitoring
- CPU, RAM, Disk, Network metrics
- Performance visualization
- Quick actions navigation
- System health alerts

---

## 📁 Files Owned

```
lib/features/dashboard/
├── dashboard_screen.dart             # Main dashboard UI
├── controllers/
│   ├── resource_controller.dart      # Resource state
│   └── metrics_controller.dart       # Metrics polling
├── providers/
│   ├── dashboard_providers.dart      # Riverpod providers
│   └── system_metrics_provider.dart  # Metrics provider
└── widgets/
    ├── metric_card.dart              # Single metric card
    ├── compact_metrics_card.dart     # Compact metrics view
    ├── quick_action_grid.dart        # Navigation grid
    ├── cpu_gauge.dart                # CPU visualization
    ├── memory_bar.dart               # RAM bar chart
    └── disk_usage_chart.dart         # Disk pie chart
```

---

## 🔧 Capabilities

- ✅ Aggiungere nuove metriche (Network speed, Temperature)
- ✅ Grafici storici (ultime 24h)
- ✅ Alerting su soglie
- ✅ Widget personalizzabili
- ✅ Refresh rate configurabile
- ✅ Export metrics data

---

## 📋 Metrics Tracked

| Metric | Source | Refresh |
|--------|--------|---------|
| CPU Usage | `/proc/stat` | 2s |
| Memory | `/proc/meminfo` | 2s |
| Disk | `df` command | 30s |
| Network | `/proc/net/dev` | 2s |
| GPU (opt) | `nvidia-smi` | 5s |

---

## 🔗 Dipendenze

- `core.agent.md` → `SystemMetricsService`, Theme

---

## 📖 Esempio Uso

```dart
// Watch metrics
final metrics = ref.watch(systemMetricsProvider);

// Display
MetricCard(
  title: 'CPU',
  value: '${metrics.cpuUsagePercent.toStringAsFixed(1)}%',
  icon: AppIcons.cpu,
  color: AppColors.cpuColor,
);

// Historical data
final history = ref.watch(metricsHistoryProvider);
LineChart(data: history.cpuHistory);
```

---

## 🎨 UI Layout

```
┌────────────────────────────────────────────┐
│ 📊 Dashboard                          [⚙️] │
├────────────────────────────────────────────┤
│ ┌─────────┐ ┌─────────┐ ┌─────────┐       │
│ │ CPU     │ │ RAM     │ │ Disk    │       │
│ │  45%    │ │  60%    │ │  75%    │       │
│ │ ▓▓▓▓░░░░│ │ ▓▓▓▓▓▓░░│ │ ▓▓▓▓▓▓▓░│       │
│ └─────────┘ └─────────┘ └─────────┘       │
│                                            │
│ 📈 Performance History                     │
│ ┌────────────────────────────────────────┐│
│ │                    ╱╲                  ││
│ │        ╱╲      ╱╲╱  ╲                 ││
│ │    ╱╲╱  ╲╱╲╱╲╱      ╲╱╲              ││
│ └────────────────────────────────────────┘│
│                                            │
│ ⚡ Quick Actions                           │
│ ┌────┐ ┌────┐ ┌────┐ ┌────┐              │
│ │ 🖥️ │ │ 📦 │ │ ⚡ │ │ 📂 │              │
│ └────┘ └────┘ └────┘ └────┘              │
└────────────────────────────────────────────┘
```
