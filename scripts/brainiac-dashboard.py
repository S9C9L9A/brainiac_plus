#!/usr/bin/env python3
"""
BrainiacPlus Terminal Dashboard — Glassmorphism Edition
Interactive suite: GPU monitor, task tracker, launcher, log viewer
"""

import os
import sys
import json
import subprocess
import time
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Optional
import threading

from rich.console import Console
from rich.panel import Panel
from rich.layout import Layout
from rich.table import Table
from rich.text import Text
from rich.live import Live
from rich.align import Align
from rich.progress import Progress, SpinnerColumn, TextColumn
from rich.prompt import Prompt, Confirm
from rich.columns import Columns
from rich.box import HEAVY

# Config
CONFIG_DIR = Path.home() / ".brainiac"
CONFIG_FILE = CONFIG_DIR / "dashboard-config.json"
CONFIG_DIR.mkdir(exist_ok=True)

# Default theme (glassmorphism)
DEFAULT_THEME = {
    "primary": "cyan",
    "accent": "magenta",
    "success": "green",
    "warning": "yellow",
    "error": "red",
    "bg": "black",
}

console = Console(force_terminal=True)

# ═══════════════════════════════════════════════════════════════════
# CONFIG MANAGEMENT
# ═══════════════════════════════════════════════════════════════════

def load_config() -> Dict:
    if CONFIG_FILE.exists():
        with open(CONFIG_FILE) as f:
            return json.load(f)
    return DEFAULT_THEME.copy()

def save_config(config: Dict):
    with open(CONFIG_FILE, 'w') as f:
        json.dump(config, f, indent=2)

theme = load_config()

# ═══════════════════════════════════════════════════════════════════
# SYSTEM METRICS
# ═══════════════════════════════════════════════════════════════════

def get_gpu_status() -> Dict:
    try:
        # GPU usage
        result = subprocess.run(
            ["rocm-smi", "--showuse"],
            capture_output=True,
            text=True,
            timeout=2
        )
        gpu_line = [l for l in result.stdout.split('\n') if 'GPU' in l and '%' in l]
        gpu_usage = gpu_line[0].split('%')[0].strip().split()[-1] if gpu_line else "0"

        # GPU memory
        result = subprocess.run(
            ["rocm-smi", "--showmeminfo"],
            capture_output=True,
            text=True,
            timeout=2
        )
        mem_line = [l for l in result.stdout.split('\n') if 'Total' in l]
        gpu_mem = mem_line[0].split()[-2] if mem_line else "0"

        # Temperature
        result = subprocess.run(
            ["rocm-smi", "--showtemp"],
            capture_output=True,
            text=True,
            timeout=2
        )
        temp_line = [l for l in result.stdout.split('\n') if '°C' in l]
        gpu_temp = temp_line[0].split('°')[0].strip().split()[-1] if temp_line else "0"

        return {
            "usage": f"{gpu_usage}%",
            "memory": f"{gpu_mem}MB",
            "temp": f"{gpu_temp}°C"
        }
    except Exception as e:
        return {"usage": "—", "memory": "—", "temp": "—", "error": str(e)}

def get_ollama_status() -> Dict:
    try:
        result = subprocess.run(
            ["curl", "-s", "http://localhost:11434/api/tags"],
            capture_output=True,
            text=True,
            timeout=2
        )
        if result.returncode == 0:
            import json as jsonlib
            data = jsonlib.loads(result.stdout)
            models = [m['name'] for m in data.get('models', [])]
            return {"status": "✓ Running", "models": models}
        return {"status": "✗ Not responding", "models": []}
    except Exception as e:
        return {"status": f"✗ Error", "models": [], "error": str(e)}

def get_cpu_ram() -> Dict:
    try:
        result = subprocess.run(
            ["free", "-h"],
            capture_output=True,
            text=True,
            timeout=2
        )
        mem_line = [l for l in result.stdout.split('\n') if l.startswith('Mem:')][0]
        parts = mem_line.split()
        return {
            "cpu": subprocess.run(["top", "-bn1"], capture_output=True, text=True, timeout=1).stdout.split('\n')[2].split()[-3] + "%",
            "ram": f"{parts[2]}/{parts[1]}"
        }
    except:
        return {"cpu": "—", "ram": "—"}

# ═══════════════════════════════════════════════════════════════════
# UI COMPONENTS
# ═══════════════════════════════════════════════════════════════════

def mascot_header() -> str:
    return "🧠 BrainiacPlus Dashboard"

def create_gpu_panel() -> Panel:
    gpu = get_gpu_status()
    cpu_ram = get_cpu_ram()

    content = f"""
[{theme['primary']}]GPU Usage:[/{theme['primary']}]     {gpu.get('usage', '—')}
[{theme['primary']}]GPU Memory:[/{theme['primary']}]    {gpu.get('memory', '—')}
[{theme['primary']}]Temperature:[/{theme['primary']}]   {gpu.get('temp', '—')}
[{theme['primary']}]CPU Usage:[/{theme['primary']}]     {cpu_ram.get('cpu', '—')}
[{theme['primary']}]RAM Usage:[/{theme['primary']}]     {cpu_ram.get('ram', '—')}
    """
    return Panel(
        content.strip(),
        title="[bold]📊 GPU Monitor[/bold]",
        box=HEAVY,
        style=f"bold {theme['primary']}"
    )

def create_ollama_panel() -> Panel:
    ollama = get_ollama_status()
    models_str = "\n".join([f"  • {m}" for m in ollama.get('models', [])]) or "  (no models)"

    content = f"""
[{theme['accent']}]Status:[/{theme['accent']}] {ollama.get('status', '—')}
[{theme['accent']}]Models:[/{theme['accent']}]
{models_str}
    """
    return Panel(
        content.strip(),
        title="[bold]🤖 Ollama[/bold]",
        box=HEAVY,
        style=f"bold {theme['accent']}"
    )

def create_menu() -> str:
    menu = f"""
[bold {theme['primary']}]MENU[/bold {theme['primary']}]
  [1] GPU Monitor
  [2] Task Tracker
  [3] Quick Launcher
  [4] Log Viewer
  [c] Color Picker
  [q] Quit
    """
    return menu

# ═══════════════════════════════════════════════════════════════════
# MAIN DASHBOARD
# ═══════════════════════════════════════════════════════════════════

def main_dashboard():
    while True:
        console.clear()

        # Header
        header = Text(mascot_header(), style=f"bold {theme['primary']} on {theme['bg']}")
        console.print(Align.center(header))
        console.print()

        # Panels
        gpu_panel = create_gpu_panel()
        ollama_panel = create_ollama_panel()

        console.print(Columns([gpu_panel, ollama_panel]))
        console.print()

        # Menu
        console.print(create_menu())

        choice = Prompt.ask(f"\n[{theme['accent']}]Select[/{theme['accent']}]", choices=["1", "2", "3", "4", "c", "q"])

        if choice == "1":
            monitor_gpu()
        elif choice == "2":
            task_tracker()
        elif choice == "3":
            quick_launcher()
        elif choice == "4":
            log_viewer()
        elif choice == "c":
            color_picker()
        elif choice == "q":
            console.print("[bold red]Goodbye![/bold red]")
            sys.exit(0)

def monitor_gpu():
    """GPU monitoring screen"""
    console.clear()
    console.print(Panel(
        create_gpu_panel().render(console.legacy_windows),
        title="[bold]GPU Monitor[/bold]",
        expand=False
    ))

    try:
        with Live(refresh_per_second=2) as live:
            for _ in range(10):  # 5 second cycle
                gpu = get_gpu_status()
                cpu_ram = get_cpu_ram()

                table = Table(title="GPU Stats", box=HEAVY)
                table.add_column("Metric", style=theme['primary'])
                table.add_column("Value", style=theme['accent'])

                table.add_row("GPU Usage", gpu.get('usage', '—'))
                table.add_row("GPU Memory", gpu.get('memory', '—'))
                table.add_row("Temperature", gpu.get('temp', '—'))
                table.add_row("CPU", cpu_ram.get('cpu', '—'))
                table.add_row("RAM", cpu_ram.get('ram', '—'))

                live.update(table)
                time.sleep(0.5)
    except KeyboardInterrupt:
        pass

    Prompt.ask(f"\n[{theme['accent']}]Press Enter to return[/{theme['accent']}]")

def task_tracker():
    """Task tracking screen"""
    console.clear()

    tasks_file = Path.home() / ".claude" / "tasks.json"
    tasks = []

    if tasks_file.exists():
        try:
            import json as jsonlib
            with open(tasks_file) as f:
                tasks = jsonlib.load(f)
        except:
            pass

    if not tasks:
        console.print(Panel(
            "[yellow]No tasks yet.[/yellow]\nCreate tasks with TaskCreate in Claude Code.",
            title="📋 Task Tracker",
            box=HEAVY
        ))
    else:
        # Build table
        table = Table(title="Tasks", box=HEAVY)
        table.add_column("ID", style=theme['primary'])
        table.add_column("Subject", style=theme['accent'])
        table.add_column("Status", style=theme['success'])

        status_emoji = {
            "pending": "⏳",
            "in_progress": "▶️",
            "completed": "✅"
        }

        for task in tasks:
            status = task.get('status', 'pending')
            emoji = status_emoji.get(status, '•')
            table.add_row(
                task.get('id', '?'),
                task.get('subject', '(no title)'),
                f"{emoji} {status}"
            )

        console.print(table)

    Prompt.ask(f"\n[{theme['accent']}]Press Enter to return[/{theme['accent']}]")

def quick_launcher():
    """Quick launcher screen"""
    console.clear()
    console.print(Panel(
        """[bold]Quick Launch[/bold]
[1] Flutter (hot-reload)
[2] Go Backend
[3] Ollama
[4] Both (Flutter + Go)
        """,
        title="🚀 Launcher",
        box=HEAVY
    ))

    choice = Prompt.ask(f"\n[{theme['accent']}]Select[/{theme['accent']}]", choices=["1", "2", "3", "4"])

    if choice == "1":
        console.print("[cyan]Starting Flutter...[/cyan]")
        os.system("cd ~/BrainiacPlus && flutter run -d linux &")
    elif choice == "2":
        console.print("[cyan]Starting Go backend...[/cyan]")
        os.system("cd ~/BrainiacPlus/go_backend && go run . &")
    elif choice == "3":
        console.print("[cyan]Starting Ollama...[/cyan]")
        os.system("ollama serve &")
    elif choice == "4":
        console.print("[cyan]Starting both...[/cyan]")
        os.system("cd ~/BrainiacPlus && flutter run -d linux & cd ~/BrainiacPlus/go_backend && go run . &")

    time.sleep(2)

def log_viewer():
    """Log viewer screen"""
    console.clear()
    console.print(Panel(
        """[bold]Log Viewer[/bold]
[1] Ollama logs
[2] Go backend logs
[3] Flutter logs
[0] Back
        """,
        title="📜 Logs",
        box=HEAVY
    ))

    choice = Prompt.ask(f"\n[{theme['accent']}]Select[/{theme['accent']}]", choices=["0", "1", "2", "3"])

    if choice == "0":
        return

    log_files = {
        "1": "/tmp/ollama.log",
        "2": os.path.expanduser("~/.brainiac/go_backend.log"),
        "3": os.path.expanduser("~/.brainiac/flutter.log")
    }

    log_file = log_files.get(choice)
    if not log_file or not os.path.exists(log_file):
        console.print(f"[red]❌ Log file not found: {log_file}[/red]")
        time.sleep(2)
        return

    console.clear()
    console.print(f"[{theme['accent']}]Tail {log_file} (last 20 lines):[/{theme['accent']}]")
    os.system(f"tail -n 20 {log_file}")

    Prompt.ask(f"\n[{theme['accent']}]Press Enter to return[/{theme['accent']}]")

def color_picker():
    """Color picker modal"""
    console.clear()
    console.print(Panel(
        """[bold]Color Picker[/bold]
Available colors: red, blue, green, yellow, magenta, cyan, white

Current theme:
[cyan]primary: [/cyan]{primary}
[cyan]accent: [/cyan]{accent}
[cyan]success: [/cyan]{success}
        """.format(**theme),
        title="🎨 Colors",
        box=HEAVY
    ))

    key = Prompt.ask("Color to change", choices=["primary", "accent", "success", "warning", "error"])
    color = Prompt.ask("New color", choices=["red", "blue", "green", "yellow", "magenta", "cyan", "white"])

    theme[key] = color
    save_config(theme)
    console.print(f"[green]✓ Theme updated![/green]")
    time.sleep(1)

# ═══════════════════════════════════════════════════════════════════
# ENTRY
# ═══════════════════════════════════════════════════════════════════

if __name__ == "__main__":
    try:
        main_dashboard()
    except KeyboardInterrupt:
        console.print("\n[bold red]Interrupted[/bold red]")
        sys.exit(0)
