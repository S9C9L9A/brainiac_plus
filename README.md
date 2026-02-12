# 🧠 BrainiacPlus v2.0

**Cross-Platform System Assistant for Linux Desktop & Android**

A powerful, AI-powered system management tool built with Flutter, featuring a stunning Glassmorphism UI inspired by iOS 17 and Nothing OS aesthetics.

---

## ✨ Features

### Core Features
- 📦 **Package Manager**: Manage system packages (apt, snap, flatpak on Linux; APK on Android)
- 🖥️ **System Monitor**: Real-time CPU, RAM, Disk, and Battery monitoring
- 📁 **File Manager**: Dual-pane file browser with root access support
- 💻 **Terminal**: Integrated shell with command history
- ⚙️ **Task Automation**: Schedule tasks, create macros, conditional triggers
- 🤖 **AI Assistant**: Ollama-powered command suggestions and error explanations

### Platform Support
- ✅ Linux Desktop (via Flutter Desktop)
- ✅ Android (no root + optional root mode)
- 🔄 Cross-device sync via Supabase (optional)

---

## 🚀 Quick Start

### Run on Linux
```bash
cd ~/brainiac_plus
flutter pub get
flutter run -d linux
```

### Build for Android
```bash
flutter build apk --debug
```

---

## 📁 Project Structure

```
brainiac_plus/
├── lib/
│   ├── core/theme/         # Glassmorphism design system ✅
│   ├── features/           # Feature modules
│   └── shared/             # Reusable components
├── go_backend/             # Go REST API ✅
└── test/                   # Tests
```

---

## 🗺️ Roadmap

### ✅ Completed
- [x] Project setup
- [x] Design system (Glassmorphism + iOS 17 + Nothing OS)
- [x] Basic UI structure

### 🔄 In Progress (Alpha Week 1)
- [ ] System monitor (CPU, RAM, Disk)
- [ ] File manager
- [ ] Shell execution
- [ ] SQLite database

### 📅 Coming Soon (Beta)
- [ ] Android support
- [ ] Package manager
- [ ] Task automation
- [ ] AI integration (Ollama)

---

**Built with ❤️ by Codebase S.R.L.**
