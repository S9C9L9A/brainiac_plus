#!/usr/bin/env python3
"""
🕹️ BrainiacPlus ARCADE EDITION — Retro Pac-Man/Space Invaders Style
ASCII animations, scanlines, glitch effects, and 8-bit vibes
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
import random

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
from rich.segment import Segment

# Config
CONFIG_DIR = Path.home() / ".brainiac"
CONFIG_FILE = CONFIG_DIR / "dashboard-config.json"
CONFIG_DIR.mkdir(exist_ok=True)

THEME = {
    "primary": "cyan",
    "accent": "magenta",
    "success": "green",
    "warning": "yellow",
    "error": "red",
    "bg": "black",
    "arcade": "yellow"  # Retro arcade yellow
}

console = Console(force_terminal=True)

# ═══════════════════════════════════════════════════════════════════
# ASCII ART & ANIMATIONS
# ═══════════════════════════════════════════════════════════════════

# Pac-Man animation frames
PACMAN_FRAMES = [
    "ᗧ··· ···ᗧ",
    "·ᗧ·· ··ᗧ·",
    "··ᗧ· ·ᗧ··",
    "···ᗧ ᗧ···",
]

# Space Invaders enemies
INVADERS = [
    [
        " ▀▄ ▄▀ ",
        "▄▀   ▀▄",
    ],
    [
        "  ◈◈  ",
        "  ◈◈  ",
    ]
]

# Terminal scanlines (retro CRT effect)
SCANLINES = "━" * 80

# Title art
TITLE_ART = """
╔═══════════════════════════════════════════════════════════════════╗
║  🕹️  BRAINIAC ARCADE EDITION — MISTRAL-MEDIUM-3.5 LOCALHOST  🕹️  ║
║     PAC-MAN CHAT MODE • SPACE INVADERS TASK TRACKER              ║
╚═══════════════════════════════════════════════════════════════════╝
"""

# ═══════════════════════════════════════════════════════════════════
# STATE & CONFIG
# ═══════════════════════════════════════════════════════════════════

class ArcadeState:
    def __init__(self):
        self.chat_history = []
        self.tasks = self._load_tasks()
        self.frame_counter = 0
        self.invader_pos = 0
        self.pacman_frame = 0
        self.glitch_active = False

    def _load_tasks(self) -> List[Dict]:
        tasks_file = Path.home() / ".claude" / "tasks.json"
        if tasks_file.exists():
            try:
                return json.load(open(tasks_file))
            except:
                return []
        return []

    def get_next_tasks(self, limit: int = 3) -> List[Dict]:
        active = [t for t in self.tasks if t.get('status') in ['pending', 'in_progress']]
        return active[:limit]

    def tick(self):
        """Increment animation frame counter"""
        self.frame_counter += 1
        self.pacman_frame = (self.frame_counter // 2) % len(PACMAN_FRAMES)
        self.invader_pos = (self.frame_counter // 3) % 40

state = ArcadeState()

OLLAMA_URL = "http://localhost:11434"
OLLAMA_MODEL = "mistral-medium-3.5"

def chat_with_ollama(message: str) -> str:
    """Chat with local Ollama"""
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
            return response.json().get("message", {}).get("content", "ERROR")
        return "CONNECTION ERROR"
    except requests.exceptions.ConnectionError:
        return "OLLAMA OFFLINE"
    except Exception as e:
        return f"ERROR: {str(e)[:30]}"

# ═══════════════════════════════════════════════════════════════════
# ANIMATED COMPONENTS
# ═══════════════════════════════════════════════════════════════════

def create_pacman_border() -> str:
    """Animated Pac-Man eating dots"""
    frame = PACMAN_FRAMES[state.pacman_frame]
    return f"[{THEME['arcade']}]{frame}[/{THEME['arcade']}]"

def create_invader_animation() -> str:
    """Animated Space Invaders enemy"""
    invader = INVADERS[state.frame_counter % len(INVADERS)]
    spaces = " " * state.invader_pos
    return f"[{THEME['arcade']}]{spaces}{invader[0]}[/{THEME['arcade']}]"

def create_glitch_text(text: str) -> str:
    """Random glitch effect on text"""
    if random.random() < 0.1:
        chars = list(text)
        if len(chars) > 2:
            i = random.randint(0, len(chars) - 1)
            chars[i] = "█"
            text = "".join(chars)
    return text

def create_scanline() -> str:
    """CRT scanline effect"""
    return f"[dim]{SCANLINES}[/dim]"

def create_animated_panel(title: str, content: str, emoji: str = "🕹️") -> Panel:
    """Panel with animated border and glitch effect"""
    state.tick()
    glitchy_title = create_glitch_text(f"[bold]{emoji} {title}[/bold]")

    return Panel(
        content,
        title=glitchy_title,
        box=HEAVY,
        border_style=THEME['arcade'],
        style=f"bold {THEME['primary']}"
    )

# ═══════════════════════════════════════════════════════════════════
# UI COMPONENTS
# ═══════════════════════════════════════════════════════════════════

def create_chat_panel() -> Panel:
    """Animated chat panel with Pac-Man"""
    state.tick()

    # Build chat display
    chat_text = ""
    for msg in state.chat_history[-4:]:  # Last 4 messages
        if msg.get('role') == 'user':
            chat_text += f"[{THEME['arcade']}]► YOU:[/{THEME['arcade']}] {msg.get('content', '')[:50]}\n"
        else:
            content = msg.get('content', '')[:50]
            chat_text += f"[{THEME['accent']}]◄ AI:[/{THEME['accent']}]  {content}\n"

    if not chat_text:
        chat_text = f"[dim]{create_pacman_border()} START TALKING[/dim]"

    return create_animated_panel("CHAT MODE", chat_text, "💬")

def create_task_invaders() -> Panel:
    """Tasks displayed as Space Invaders"""
    state.tick()
    tasks = state.get_next_tasks(3)

    invader_line = create_invader_animation()
    task_text = invader_line + "\n"

    for i, task in enumerate(tasks):
        status = "►" if task.get('status') == 'in_progress' else "○"
        subject = task.get('subject', '?')[:25]
        task_text += f"[{THEME['success']}]{status}[/{THEME['success']}] {subject}\n"

    if not tasks:
        task_text = "[dim]NO ACTIVE TASKS[/dim]"

    return create_animated_panel("TASK INVADERS", task_text, "👾")

def create_cpu_arcade() -> Panel:
    """CPU monitor with retro style"""
    state.tick()
    try:
        result = subprocess.run(["top", "-bn1"], capture_output=True, text=True, timeout=1)
        cpu = result.stdout.split('\n')[2].split()[-3] if result.stdout else "50"
        # Clean up the CPU value
        cpu_num = int(float(cpu.rstrip('%').split(',')[0]))
    except:
        cpu = "50"
        cpu_num = 50

    cpu_bar = "▓" * (cpu_num // 10) + "░" * (10 - (cpu_num // 10))
    content = f"[{THEME['arcade']}]{cpu_bar} {cpu}[/{THEME['arcade']}]"

    return create_animated_panel("CPU GAUGE", content, "⚙️")

def create_ram_arcade() -> Panel:
    """RAM monitor"""
    state.tick()
    try:
        result = subprocess.run(["free", "-h"], capture_output=True, text=True, timeout=1)
        mem_line = [l for l in result.stdout.split('\n') if l.startswith('Mem:')][0]
        parts = mem_line.split()
        ram_display = f"{parts[2]}/{parts[1]}"
    except:
        ram_display = "??/128Gi"

    return create_animated_panel("RAM STACK", f"[{THEME['success']}]{ram_display}[/{THEME['success']}]", "🧠")

def create_score_board() -> Panel:
    """Game-style scoreboard"""
    state.tick()
    pending = len([t for t in state.tasks if t.get('status') == 'pending'])
    in_progress = len([t for t in state.tasks if t.get('status') == 'in_progress'])
    completed = len([t for t in state.tasks if t.get('status') == 'completed'])

    score_text = f"""
[{THEME['arcade']}]PENDING[/{THEME['arcade']}]......... {pending} ⊕
[{THEME['arcade']}]PROGRESS[/{THEME['arcade']}]......... {in_progress} ▶
[{THEME['arcade']}]COMPLETE[/{THEME['arcade']}]......... {completed} ✓
    """

    return create_animated_panel("SCORE BOARD", score_text.strip(), "🎮")

# ═══════════════════════════════════════════════════════════════════
# MAIN LAYOUT
# ═══════════════════════════════════════════════════════════════════

def create_arcade_layout() -> Layout:
    """16:9 arcade layout"""
    layout = Layout()

    layout.split(
        Layout(name="top", size=13),
        Layout(name="input", size=3),
        Layout(name="bottom", size=6)
    )

    # Top: Chat + Tasks Invaders
    layout["top"].split_row(
        Layout(name="chat", ratio=3),
        Layout(name="tasks", ratio=1)
    )
    layout["chat"].update(create_chat_panel())
    layout["tasks"].update(create_task_invaders())

    # Input bar
    layout["input"].update(
        Panel(
            "[dim]▌ ENTER MESSAGE (q=QUIT)[/dim]",
            box=ROUNDED,
            style=f"bold {THEME['accent']}"
        )
    )

    # Bottom: CPU, RAM, Scoreboard
    layout["bottom"].split_row(
        Layout(name="cpu", ratio=1),
        Layout(name="ram", ratio=1),
        Layout(name="score", ratio=2)
    )
    layout["cpu"].update(create_cpu_arcade())
    layout["ram"].update(create_ram_arcade())
    layout["score"].update(create_score_board())

    return layout

# ═══════════════════════════════════════════════════════════════════
# INTRO ANIMATION
# ═══════════════════════════════════════════════════════════════════

def show_arcade_intro():
    """Animated intro screen"""
    console.clear()
    console.print(TITLE_ART, style=f"bold {THEME['arcade']}")

    # Pac-Man animation
    for i in range(20):
        state.pacman_frame = i % len(PACMAN_FRAMES)
        frame = PACMAN_FRAMES[state.pacman_frame]
        console.print(f"[{THEME['arcade']}]{frame}[/{THEME['arcade']}]", end="\r")
        time.sleep(0.1)

    console.print("\n[bold green]✓ ARCADE MODE ACTIVATED[/bold green]")
    console.print("[dim]Connecting to Ollama...     [/dim]", end="")

    # Test connection
    try:
        response = requests.get(f"{OLLAMA_URL}/api/tags", timeout=2)
        if response.status_code == 200:
            console.print(f" [green]✓[/green]")
        else:
            console.print(f" [red]✗[/red]")
    except:
        console.print(f" [red]✗[/red]")

    time.sleep(1)
    console.clear()

# ═══════════════════════════════════════════════════════════════════
# MAIN LOOP
# ═══════════════════════════════════════════════════════════════════

def main():
    show_arcade_intro()

    while True:
        try:
            layout = create_arcade_layout()
            console.print(layout)

            user_input = Prompt.ask(
                f"\n[{THEME['arcade']}]► PLAYER[/{THEME['arcade']}]"
            ).strip()

            if user_input.lower() == 'q':
                console.print(f"\n[{THEME['arcade']}]GAME OVER[/{THEME['arcade']}]")
                time.sleep(1)
                sys.exit(0)

            if not user_input:
                console.clear()
                continue

            state.chat_history.append({"role": "user", "content": user_input})
            console.clear()
            console.print(f"\n[{THEME['accent']}]◄ AI THINKING...{' ' * 50}[/{THEME['accent']}]")

            response = chat_with_ollama(user_input)
            state.chat_history.append({"role": "assistant", "content": response})

            console.clear()

        except KeyboardInterrupt:
            console.print(f"\n[{THEME['arcade']}]INTERRUPTED[/{THEME['arcade']}]")
            sys.exit(0)
        except Exception as e:
            console.print(f"[red]⚠️ ERROR: {e}[/red]")
            break

if __name__ == "__main__":
    main()
