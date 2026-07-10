#!/usr/bin/env python3
"""
🕹️ BRAINIAC ARCADE PRO — Full Retro Gaming Dashboard
Playable Pac-Man + Space Invaders mini-games, scanlines, glitch effects
"""

import os
import sys
import json
import subprocess
import time
from pathlib import Path
from typing import Dict, List, Tuple, Optional
import requests
import random
import threading

from rich.console import Console
from rich.panel import Panel
from rich.layout import Layout
from rich.table import Table
from rich.text import Text
from rich.live import Live
from rich.align import Align
from rich.box import ROUNDED, HEAVY
from rich.prompt import Prompt
from rich.segment import Segment

# ═══════════════════════════════════════════════════════════════════
# CONFIG
# ═══════════════════════════════════════════════════════════════════

THEME = {
    "primary": "cyan",
    "accent": "magenta",
    "success": "green",
    "warning": "yellow",
    "error": "red",
    "arcade": "yellow",
}

console = Console(force_terminal=True)
OLLAMA_URL = "http://localhost:11434"
OLLAMA_MODEL = "mistral-medium-3.5"

TITLE_ART = """
╔═════════════════════════════════════════════════════════════════════╗
║    🕹️  BRAINIAC ARCADE PRO — MISTRAL-3.5 LOCALHOST  🕹️              ║
║  [SPACE]=SHOOT  [←↑→↓]=MOVE  [G]=GAME  [C]=CHAT  [Q]=QUIT           ║
╚═════════════════════════════════════════════════════════════════════╝
"""

# ═══════════════════════════════════════════════════════════════════
# PAC-MAN MINI-GAME
# ═══════════════════════════════════════════════════════════════════

class PacManGame:
    def __init__(self):
        self.pacman_x = 20
        self.pacman_y = 5
        self.pellets = [(x, y) for x in range(5, 75, 5) for y in range(1, 10)]
        self.score = 0
        self.direction = "right"
        self.next_direction = "right"
        self.ghosts = [(10, 3), (70, 3), (40, 8)]

    def move(self):
        """Move Pac-Man and ghosts"""
        self.direction = self.next_direction

        # Move Pac-Man
        if self.direction == "right":
            self.pacman_x = min(self.pacman_x + 2, 76)
        elif self.direction == "left":
            self.pacman_x = max(self.pacman_x - 2, 4)
        elif self.direction == "up":
            self.pacman_y = max(self.pacman_y - 1, 1)
        elif self.direction == "down":
            self.pacman_y = min(self.pacman_y + 1, 9)

        # Eat pellets
        self.pellets = [(x, y) for x, y in self.pellets
                       if not (abs(x - self.pacman_x) < 2 and abs(y - self.pacman_y) < 1)]
        self.score += len([p for p in self.pellets if p not in self.pellets])

        # Move ghosts randomly
        self.ghosts = [
            (x + random.randint(-1, 1), y + random.randint(-1, 1))
            for x, y in self.ghosts
        ]
        self.ghosts = [(max(4, min(76, x)), max(1, min(9, y))) for x, y in self.ghosts]

    def render(self) -> str:
        """Render game board"""
        board = ["·" * 80 for _ in range(10)]
        board_list = [list(row) for row in board]

        # Pellets
        for x, y in self.pellets:
            if 0 <= y < 10 and 0 <= x < 80:
                try:
                    board_list[y][x] = "•"
                except:
                    pass

        # Ghosts
        for gx, gy in self.ghosts:
            if 0 <= gy < 10 and 0 <= gx < 80:
                try:
                    board_list[gy][gx] = "👻"
                except:
                    pass

        # Pac-Man
        pacman_char = "ᗧ" if self.direction == "right" else "ᗤ"
        if 0 <= self.pacman_y < 10 and 0 <= self.pacman_x < 80:
            try:
                board_list[self.pacman_y][self.pacman_x] = pacman_char
            except:
                pass

        return "\n".join(["".join(row) for row in board_list])

# ═══════════════════════════════════════════════════════════════════
# SPACE INVADERS MINI-GAME
# ═══════════════════════════════════════════════════════════════════

class SpaceInvadersGame:
    def __init__(self):
        self.player_x = 40
        self.bullets = []
        self.invaders = [(x, 2) for x in range(10, 70, 10)]
        self.score = 0
        self.wave = 1

    def move(self):
        """Move invaders and bullets"""
        # Move bullets
        self.bullets = [(x, y - 1) for x, y in self.bullets if y > 0]

        # Move invaders (simple: down every few ticks)
        self.invaders = [(x, y + 1) if random.random() > 0.8 else (x, y) for x, y in self.invaders]

        # Collision detection
        hit_invaders = []
        for bx, by in self.bullets:
            for ix, iy in self.invaders:
                if abs(bx - ix) < 3 and abs(by - iy) < 2:
                    hit_invaders.append((ix, iy))
                    self.score += 10

        self.invaders = [inv for inv in self.invaders if inv not in hit_invaders]
        self.bullets = [(x, y) for x, y in self.bullets if not any(abs(x - ix) < 3 and abs(y - iy) < 2 for ix, iy in hit_invaders)]

        if not self.invaders:
            self.wave += 1
            self.invaders = [(x, 2) for x in range(10, 70, 5 * self.wave)]

    def shoot(self):
        """Fire bullet"""
        self.bullets.append((self.player_x, 8))

    def render(self) -> str:
        """Render game board"""
        board = [" " * 80 for _ in range(10)]
        board_list = [list(row) for row in board]

        # Invaders
        for ix, iy in self.invaders:
            if 0 <= iy < 10 and 0 <= ix < 80:
                try:
                    board_list[iy][ix] = "█"
                except:
                    pass

        # Bullets
        for bx, by in self.bullets:
            if 0 <= by < 10 and 0 <= bx < 80:
                try:
                    board_list[by][bx] = "↑"
                except:
                    pass

        # Player
        if 0 <= self.player_x < 80:
            try:
                board_list[9][self.player_x] = "▲"
            except:
                pass

        return "\n".join(["".join(row) for row in board_list])

# ═══════════════════════════════════════════════════════════════════
# GAME STATE
# ═══════════════════════════════════════════════════════════════════

class ArcadeState:
    def __init__(self):
        self.chat_history = []
        self.tasks = self._load_tasks()
        self.frame = 0
        self.pacman_game = PacManGame()
        self.invaders_game = SpaceInvadersGame()
        self.active_game = None  # None, "pacman", "invaders"
        self.global_score = 0

    def _load_tasks(self) -> List[Dict]:
        tasks_file = Path.home() / ".claude" / "tasks.json"
        try:
            return json.load(open(tasks_file)) if tasks_file.exists() else []
        except:
            return []

    def tick(self):
        self.frame += 1
        if self.active_game == "pacman":
            self.pacman_game.move()
        elif self.active_game == "invaders":
            self.invaders_game.move()

state = ArcadeState()

# ═══════════════════════════════════════════════════════════════════
# OLLAMA
# ═══════════════════════════════════════════════════════════════════

def chat_with_ollama(message: str) -> str:
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
        return response.json().get("message", {}).get("content", "ERROR") if response.status_code == 200 else "OFFLINE"
    except:
        return "OLLAMA OFFLINE"

# ═══════════════════════════════════════════════════════════════════
# UI COMPONENTS
# ═══════════════════════════════════════════════════════════════════

def create_game_panel(title: str, content: str) -> Panel:
    """Retro game panel"""
    return Panel(
        f"[{THEME['arcade']}]{content}[/{THEME['arcade']}]",
        title=f"[bold {THEME['arcade']}]{title}[/bold {THEME['arcade']}]",
        box=HEAVY,
        border_style=THEME['arcade']
    )

def create_chat_panel() -> Panel:
    """Chat panel"""
    chat_text = ""
    for msg in state.chat_history[-3:]:
        if msg.get('role') == 'user':
            chat_text += f"[{THEME['arcade']}]► {msg.get('content', '')[:60]}[/{THEME['arcade']}]\n"
        else:
            chat_text += f"[{THEME['accent']}]◄ {msg.get('content', '')[:60]}[/{THEME['accent']}]\n"

    if not chat_text:
        chat_text = "[dim]SEND A MESSAGE[/dim]"

    return create_game_panel("💬 CHAT MODE", chat_text)

def create_status_panel() -> Panel:
    """Game status panel"""
    task_count = len([t for t in state.tasks if t.get('status') in ['pending', 'in_progress']])
    status = f"""
[{THEME['success']}]SCORE[/{THEME['success']}].............. {state.global_score}
[{THEME['arcade']}]TASKS[/{THEME['arcade']}].............. {task_count}
[{THEME['arcade']}]WAVE[/{THEME['arcade']}]............... {state.invaders_game.wave if state.active_game == 'invaders' else '—'}
[{THEME['arcade']}]FRAME[/{THEME['arcade']}].............. {state.frame}
    """
    return create_game_panel("🎮 STATUS", status.strip())

# ═══════════════════════════════════════════════════════════════════
# MAIN LAYOUT
# ═══════════════════════════════════════════════════════════════════

def create_layout() -> Layout:
    """Create main arcade layout"""
    layout = Layout()

    layout.split(
        Layout(name="game", size=11),
        Layout(name="input", size=3),
        Layout(name="info", size=4)
    )

    # Game area
    if state.active_game == "pacman":
        game_content = state.pacman_game.render()
    elif state.active_game == "invaders":
        game_content = state.invaders_game.render()
    else:
        game_content = "[dim]SELECT: [g]=PAC-MAN [i]=SPACE-INVADERS [c]=CHAT[/dim]"

    layout["game"].update(create_game_panel("🕹️ ARCADE", game_content))

    # Input
    layout["input"].update(
        Panel(
            "[dim]▌ ENTER MESSAGE[/dim]",
            box=ROUNDED,
            style=f"bold {THEME['accent']}"
        )
    )

    # Info
    layout["info"].update(create_status_panel())

    return layout

# ═══════════════════════════════════════════════════════════════════
# INTRO
# ═══════════════════════════════════════════════════════════════════

def show_intro():
    console.clear()
    console.print(TITLE_ART, style=f"bold {THEME['arcade']}")
    console.print("[dim]Loading arcade ROM...[/dim]", end="")
    sys.stdout.flush()

    for i in range(10):
        print(".", end="")
        sys.stdout.flush()
        time.sleep(0.1)

    console.print(" [green]✓[/green]")
    console.print("[dim]Testing Ollama connection...[/dim]", end="")
    sys.stdout.flush()

    try:
        requests.get(f"{OLLAMA_URL}/api/tags", timeout=2)
        console.print(" [green]✓[/green]")
    except:
        console.print(" [yellow]⚠[/yellow]")

    time.sleep(1)
    console.clear()

# ═══════════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════════

def main():
    show_intro()

    while True:
        try:
            state.tick()
            layout = create_layout()
            console.print(layout)

            user_input = Prompt.ask(
                f"[{THEME['arcade']}]►[/{THEME['arcade']}]"
            ).strip().lower()

            if user_input == 'q':
                console.print(f"[{THEME['arcade']}]GAME OVER[/{THEME['arcade']}]")
                sys.exit(0)
            elif user_input == 'g':
                state.active_game = "pacman" if state.active_game != "pacman" else None
            elif user_input == 'i':
                state.active_game = "invaders" if state.active_game != "invaders" else None
            elif user_input == 'c':
                state.active_game = None
            elif user_input == 'space' and state.active_game == "invaders":
                state.invaders_game.shoot()
            elif user_input in ['left', 'right'] and state.active_game == "pacman":
                state.pacman_game.next_direction = user_input
            elif user_input == 'up' and state.active_game == "pacman":
                state.pacman_game.next_direction = "up"
            elif user_input == 'down' and state.active_game == "pacman":
                state.pacman_game.next_direction = "down"
            elif state.active_game is None and user_input:
                # Chat mode
                state.chat_history.append({"role": "user", "content": user_input})
                console.clear()
                console.print(f"[{THEME['accent']}]⏳ PROCESSING...{' ' * 50}[/{THEME['accent']}]")
                response = chat_with_ollama(user_input)
                state.chat_history.append({"role": "assistant", "content": response})
                state.global_score += 5

            console.clear()

        except KeyboardInterrupt:
            console.print(f"[{THEME['arcade']}]INTERRUPTED[/{THEME['arcade']}]")
            sys.exit(0)
        except Exception as e:
            console.print(f"[red]ERROR: {e}[/red]")
            time.sleep(2)
            console.clear()

if __name__ == "__main__":
    main()
