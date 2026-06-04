# BrainiacPlus Terminal Dashboard — Glassmorphism Edition

Interactive terminal suite for GPU monitoring, task tracking, and quick launches.

## Quick Start

```bash
cd ~/BrainiacPlus
./scripts/launch-dashboard
```

Or directly:
```bash
python3 scripts/brainiac-dashboard.py
```

## Features

### 1. 📊 GPU Monitor
Real-time monitoring of:
- **GPU Usage** — GPU% utilization (rocm-smi)
- **GPU Memory** — VRAM consumption
- **Temperature** — GPU thermal status
- **CPU Usage** — System CPU%
- **RAM Usage** — System RAM usage

Updates every 0.5 seconds. Based on your Radeon R9700 with 32GB VRAM.

### 2. 📋 Task Tracker
View, create, and manage tasks from terminal.
- Reads from `~/.claude/tasks.json`
- Filter by status: pending, in_progress, completed
- Quick task creation

### 3. 🚀 Quick Launcher
One-button launch of:
- **Flutter** (hot-reload dev mode)
- **Go Backend** (localhost:8080)
- **Ollama** (localhost:11434)
- **Both** (Flutter + Go in parallel)

Automatically loads GPU environment via `~/.bashrc.ollama-gpu`.

### 4. 📜 Log Viewer
Tail logs from:
- Ollama inference logs
- Go backend (stderr/stdout)
- Flutter console output
- Filter by log level / keyword

### 5. 🎨 Color Picker
Customize theme colors in real-time:
- **primary** — main UI color (default: cyan)
- **accent** — highlights (default: magenta)
- **success** — positive indicators (default: green)
- **warning** — caution (default: yellow)
- **error** — errors (default: red)

Changes persist in `~/.brainiac/dashboard-config.json`.

### 6. 🧠 Mascot
Claude mascot (emoji) displays at top. Interactive.

## Glassmorphism Design

- **Transparent panels** — semi-transparent borders with color tinting
- **Soft borders** — heavy box-drawing characters (╔═╗║╝╚╣)
- **Accent colors** — cyan/magenta primary palette
- **Spacing** — generous padding for readability
- **Animations** — smooth updates every 0.5-2 seconds

## Requirements

```bash
python3 >= 3.8
rich >= 13.0.0
rocm-smi (for GPU monitoring)
curl (for Ollama status)
```

Auto-install via `launch-dashboard`.

## Configuration

**Location:** `~/.brainiac/dashboard-config.json`

**Example:**
```json
{
  "primary": "cyan",
  "accent": "magenta",
  "success": "green",
  "warning": "yellow",
  "error": "red",
  "bg": "black",
  "border_style": "heavy"
}
```

## Shortcuts

| Key | Action |
|-----|--------|
| `1` | GPU Monitor |
| `2` | Task Tracker |
| `3` | Quick Launcher |
| `4` | Log Viewer |
| `c` | Color Picker |
| `q` | Quit |
| `Ctrl+C` | Emergency exit |

## Troubleshooting

### "rocm-smi not found"
ROCm not installed or not in PATH. Verify:
```bash
ls /opt/rocm/bin/rocm-smi
```

### "Rich module not found"
Install with:
```bash
pip3 install rich
```

### Dashboard slow/laggy
Reduce refresh rate in `brainiac-dashboard.py` (change `refresh_per_second` from 2 to 1).

### Colors not persisting
Check `~/.brainiac/` permissions:
```bash
ls -la ~/.brainiac/dashboard-config.json
```

## Future Enhancements

- [ ] Task creation/editing from dashboard
- [ ] Log viewer with live tailing
- [ ] System alerts (high temp, OOM)
- [ ] GPU workload history (charts)
- [ ] Customizable layout per monitor

## Development

Script path: `scripts/brainiac-dashboard.py`

To test changes:
```bash
python3 scripts/brainiac-dashboard.py
```

To debug:
```bash
python3 -m pdb scripts/brainiac-dashboard.py
```

---

**Created:** 2026-05-09  
**Status:** MVP (core screens functional)  
**Next:** Task tracker + log viewer + advanced features
