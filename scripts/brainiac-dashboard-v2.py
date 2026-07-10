#!/usr/bin/env python3
"""
BrainiacPlus Dashboard v2 — 16:9 Layout with Chat + Monitoring
Layout: Chat (12x6) | Task+News (4x6) | ChatBar (1-2x16) | Monitoring (bottom)
"""

import os
import sys
import json
import subprocess
import time
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Optional
import requests

from rich.console import Console
from rich.panel import Panel
from rich.layout import Layout
from rich.table import Table
from rich.text import Text
from rich.live import Live
from rich.align import Align
from rich.box import ROUNDED, HEAVY
from rich.prompt import Prompt
from rich.spinner import Spinner

# Config
CONFIG_DIR = Path.home() / ".brainiac"
CONFIG_FILE = CONFIG_DIR / "dashboard-config.json"
CONFIG_DIR.mkdir(exist_ok=True)

DEFAULT_THEME = {
    "primary": "cyan",
    "accent": "magenta",
    "success": "green",
    "warning": "yellow",
    "error": "red",
    "bg": "black",
}

console = Console(force_terminal=True)
theme = json.load(open(CONFIG_FILE)) if CONFIG_FILE.exists() else DEFAULT_THEME

# ═══════════════════════════════════════════════════════════════════
# STATE MANAGEMENT
# ═══════════════════════════════════════════════════════════════════

class DashboardState:
    def __init__(self):
        self.chat_history: List[Dict] = []
        self.current_input = ""
        self.active_bottom_tab = "cpu"  # cpu, ram, tasks
        self.active_right_tab = "tasks"  # tasks, news
        self.tasks = self._load_tasks()
        self.monitoring_data = {}

    def _load_tasks(self) -> List[Dict]:
        tasks_file = Path.home() / ".claude" / "tasks.json"
        if tasks_file.exists():
            try:
                return json.load(open(tasks_file))
            except:
                return []
        return []

    def get_next_tasks(self, limit: int = 3) -> List[Dict]:
        """Get pending/in_progress tasks (next 3)"""
        active = [t for t in self.tasks if t.get('status') in ['pending', 'in_progress']]
        return active[:limit]

state = DashboardState()

# ═══════════════════════════════════════════════════════════════════
# OLLAMA INTEGRATION
# ═══════════════════════════════════════════════════════════════════

OLLAMA_URL = "http://localhost:11434"
OLLAMA_MODEL = "mistral-medium-3.5"

def chat_with_ollama(message: str) -> str:
    """Send message to Ollama, get response"""
    try:
        response = requests.post(
            f"{OLLAMA_URL}/api/chat",
            json={
                "model": OLLAMA_MODEL,
                "messages": [{"role": "user", "content": message}],
                "stream": False
            },
            timeout=30
        )
        if response.status_code == 200:
            data = response.json()
            return data.get("message", {}).get("content", "No response")
        return "❌ Ollama error"
    except requests.exceptions.ConnectionError:
        return "❌ Ollama not running (localhost:11434)"
    except Exception as e:
        return f"❌ Error: {str(e)}"

# ═══════════════════════════════════════════════════════════════════
# SYSTEM METRICS
# ═══════════════════════════════════════════════════════════════════

def get_metrics() -> Dict:
    """Get CPU, RAM, GPU, Temp"""
    try:
        result = subprocess.run(["free", "-h"], capture_output=True, text=True, timeout=1)
        mem_line = [l for l in result.stdout.split('\n') if l.startswith('Mem:')][0]
        parts = mem_line.split()

        result = subprocess.run(["top", "-bn1"], capture_output=True, text=True, timeout=1)
        cpu = result.stdout.split('\n')[2].split()[-3] if result.stdout else "—"

        return {
            "cpu": cpu,
            "ram": f"{parts[2]}/{parts[1]}",
            "gpu": "92%",  # placeholder
            "temp": "72°C"
        }
    except:
        return {"cpu": "—", "ram": "—", "gpu": "—", "temp": "—"}

# ═══════════════════════════════════════════════════════════════════
# UI COMPONENTS
# ═══════════════════════════════════════════════════════════════════

def create_chat_panel() -> Panel:
    """Chat history panel (top-left, 12x6)"""
    chat_text = "\n".join([
        f"[{theme['primary']}]You:[/{theme['primary']}] {msg.get('user', '')}"
        if msg.get('role') == 'user'
        else f"[{theme['accent']}]Claude:[/{theme['accent']}] {msg.get('content', '')[:60]}..."
        for msg in state.chat_history[-5:]  # Last 5 messages
    ]) or "[dim]Start chatting...[/dim]"

    return Panel(
        chat_text,
        title="[bold]💬 Chat with Claude[/bold]",
        box=HEAVY,
        height=13
    )

def create_task_panel() -> Panel:
    """Next 3 tasks panel (top-right, 4x6)"""
    tasks = state.get_next_tasks(3)
    if not tasks:
        content = "[dim]No active tasks[/dim]"
    else:
        content = "\n".join([
            f"[{theme['success']}]✓[/{theme['success']}] {t.get('subject', '?')[:30]}"
            for t in tasks
        ])

    return Panel(
        content,
        title="[bold]📋 Next Tasks[/bold]",
        box=HEAVY,
        height=13
    )

def create_news_panel() -> Panel:
    """AI News panel (top-right alternative)"""
    news = [
        "🤖 Claude 4.X: New vision capabilities",
        "🚀 Ollama: Local inference improvements",
        "📈 RAG: Better retrieval-augmented generation"
    ]
    content = "\n".join([f"• {n}" for n in news])

    return Panel(
        content,
        title="[bold]📰 AI News[/bold]",
        box=HEAVY,
        height=13
    )

def create_chat_input() -> str:
    """Chat input bar"""
    return f"\n[{theme['accent']}]Type your message:[/{theme['accent']}]"

def create_cpu_panel() -> Panel:
    """CPU Monitor"""
    metrics = get_metrics()
    content = f"""
[{theme['primary']}]CPU Usage:[/{theme['primary']}]     {metrics['cpu']}
[{theme['primary']}]Temperature:[/{theme['primary']}]   {metrics['temp']}
    """
    return Panel(content.strip(), title="[bold]⚙️ CPU[/bold]", box=ROUNDED, height=6)

def create_ram_panel() -> Panel:
    """RAM Monitor"""
    metrics = get_metrics()
    content = f"[{theme['success']}]{metrics['ram']}[/{theme['success']}]"
    return Panel(content, title="[bold]🧠 RAM[/bold]", box=ROUNDED, height=6)

def create_task_report() -> Panel:
    """Task report with sub-tabs"""
    pending = [t for t in state.tasks if t.get('status') == 'pending']
    in_progress = [t for t in state.tasks if t.get('status') == 'in_progress']
    completed = [t for t in state.tasks if t.get('status') == 'completed']

    content = f"""
[{theme['primary']}]Pending:[/{theme['primary']}]       {len(pending)} tasks
[{theme['accent']}]In Progress:[/{theme['accent']}]    {len(in_progress)} tasks
[{theme['success']}]Completed:[/{theme['success']}]     {len(completed)} tasks
    """
    return Panel(content.strip(), title="[bold]📊 Task Report[/bold]", box=ROUNDED, height=6)

# ═══════════════════════════════════════════════════════════════════
# MAIN LAYOUT
# ═══════════════════════════════════════════════════════════════════

def create_layout() -> Layout:
    """Create 16:9 responsive layout"""
    layout = Layout()

    # Main vertical split: top section, input bar, bottom monitoring
    layout.split(
        Layout(name="top", size=13),
        Layout(name="input", size=3),
        Layout(name="bottom", size=6)
    )

    # Top: Chat (left) + Task/News (right) — 3:1 ratio
    layout["top"].split_row(
        Layout(name="chat", ratio=3),
        Layout(name="right", ratio=1)
    )
    layout["chat"].update(create_chat_panel())

    # Right: Tab switcher for Tasks/News
    right_panel = (create_task_panel() if state.active_right_tab == "tasks"
                   else create_news_panel())
    layout["right"].update(right_panel)

    # Input bar
    layout["input"].update(
        Panel(
            "[dim]Type message and press Enter...[/dim]",
            box=ROUNDED,
            style=f"bold {theme['accent']}"
        )
    )

    # Bottom: Monitoring tabs (CPU, RAM, Task Report)
    layout["bottom"].split_row(
        Layout(name="cpu", ratio=1),
        Layout(name="ram", ratio=1),
        Layout(name="tasks", ratio=2)
    )
    layout["cpu"].update(create_cpu_panel())
    layout["ram"].update(create_ram_panel())
    layout["tasks"].update(create_task_report())

    return layout

# ═══════════════════════════════════════════════════════════════════
# MAIN LOOP
# ═══════════════════════════════════════════════════════════════════

def main():
    console.clear()
    console.print(f"[{theme['primary']}]🧠 BrainiacPlus Dashboard v2[/{theme['primary']}]")
    console.print(f"[dim]Chat model: {OLLAMA_MODEL} @ {OLLAMA_URL}[/dim]\n")

    while True:
        try:
            layout = create_layout()
            console.print(layout)

            # Input handling
            user_input = Prompt.ask(
                f"\n[{theme['accent']}]You[/{theme['accent']}]"
            ).strip()

            if user_input.lower() == 'q':
                console.print("[bold red]Goodbye![/bold red]")
                sys.exit(0)

            if not user_input:
                console.clear()
                continue

            # Send to Ollama
            state.chat_history.append({"role": "user", "content": user_input})
            console.clear()
            console.print(f"\n[{theme['accent']}]⏳ Thinking...{' ' * 50}[/{theme['accent']}]")

            response = chat_with_ollama(user_input)
            state.chat_history.append({"role": "assistant", "content": response})

            console.clear()

        except KeyboardInterrupt:
            console.print("\n[bold red]Interrupted[/bold red]")
            sys.exit(0)
        except Exception as e:
            console.print(f"[red]Error: {e}[/red]")
            break

if __name__ == "__main__":
    main()
