# 🖥️ Terminal Agent

**Dominio**: `lib/features/terminal/`

---

## 🎯 Responsabilità

- Shell command execution
- Command history (↑/↓ navigation)
- Autocomplete (50+ commands)
- Process control (Ctrl+C, Ctrl+Z)
- Real-time output streaming
- ANSI color support

---

## 📁 Files Owned

```
lib/features/terminal/
├── terminal_screen.dart              # Main terminal UI
├── controllers/
│   ├── terminal_controller.dart      # Terminal state
│   ├── history_controller.dart       # Command history
│   └── process_controller.dart       # Process management
├── providers/
│   └── terminal_providers.dart       # Riverpod providers
└── widgets/
    ├── terminal_output.dart          # Output display
    ├── command_input.dart            # Input field
    ├── command_suggestions.dart      # Autocomplete dropdown
    └── ansi_text.dart                # ANSI color parser
```

### Related Core Services
```
lib/core/platform/
└── shell_service.dart                # Shell execution
```

---

## 🔧 Capabilities

- ✅ Aggiungere/modificare comandi autocomplete
- ✅ Migliorare UI terminal
- ✅ Implementare ANSI colors (8/16/256/TrueColor)
- ✅ Tab completion per paths
- ✅ Sessioni multiple (tabs)
- ✅ Split terminals (horizontal/vertical)
- ✅ Custom shell profiles

---

## 📋 Autocomplete Commands

```dart
const commands = [
  // File operations
  'ls', 'cd', 'pwd', 'mkdir', 'rm', 'cp', 'mv', 'cat', 'touch',
  // Package management
  'apt', 'apt-get', 'snap', 'flatpak', 'dpkg',
  // System
  'systemctl', 'journalctl', 'top', 'htop', 'ps', 'kill',
  // Network
  'ping', 'curl', 'wget', 'ssh', 'netstat',
  // Development
  'flutter', 'dart', 'go', 'git', 'make', 'npm',
  // BrainiacPlus specific
  'brainiac', 'ollama',
];
```

---

## 🔗 Dipendenze

- `core.agent.md` → `ShellService`
- `file_manager.agent.md` → "Open terminal here"

---

## 📖 Esempio Uso

```dart
// Execute command
ref.read(terminalControllerProvider.notifier)
    .execute('ls -la /home');

// Get history
final history = ref.watch(commandHistoryProvider);

// Autocomplete
final suggestions = ref.watch(
  autocompleteSuggestionsProvider('apt inst')
);
```

---

## 🎨 UI Layout

```
┌────────────────────────────────────────────┐
│ 🖥️ Terminal                    [+] [⚙️] [×]│
├────────────────────────────────────────────┤
│ user@brainiac:~$ ls -la                    │
│ total 48                                   │
│ drwxr-xr-x  5 user user 4096 Mar  7 10:00 .│
│ drwxr-xr-x 23 user user 4096 Mar  7 09:30 ..│
│ -rw-r--r--  1 user user  220 Mar  7 09:30 .bash│
│ drwxr-xr-x  8 user user 4096 Mar  7 10:00 brainiac│
│                                            │
│ user@brainiac:~$ █                         │
│                  ┌──────────────────┐      │
│                  │ flutter          │      │
│                  │ flutter run      │      │
│                  │ flutter build    │      │
│                  └──────────────────┘      │
└────────────────────────────────────────────┘
```

---

## 🛡️ Safety

- Commands run in user context (no sudo without password)
- Dangerous commands show confirmation dialog
- Output size limited to prevent memory issues
- Process timeout configurable
