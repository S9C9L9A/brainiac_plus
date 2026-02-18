# 🔧 Build Instructions

## Problema Corrente: Linker Not Found

Flutter cerca `ld.lld` o `ld` in `/usr/lib/llvm-18/bin` ma il sistema ha il linker in `/usr/bin/ld`.

### Soluzioni Possibili:

#### Soluzione 1: Symlink (Veloce)
```bash
sudo mkdir -p /usr/lib/llvm-18/bin
sudo ln -s /usr/bin/ld /usr/lib/llvm-18/bin/ld
```

#### Soluzione 2: Installare LLVM 18
```bash
sudo apt update
sudo apt install llvm-18 lld-18
```

#### Soluzione 3: Flutter Clean
```bash
cd ~/brainiac_plus
flutter clean
flutter pub get
flutter run -d linux
```

---

## Test Alternativo: Android

Se hai un dispositivo Android connesso:
```bash
flutter devices
flutter run -d <android_device_id>
```

---

## Verifica Codice Implementato

Anche senza build, il codice è completo:

### ✅ System Monitor Completato
- `lib/core/platform/linux_platform.dart` - Linux system integration
- `lib/features/dashboard/dashboard_screen.dart` - Dashboard UI
- `lib/features/dashboard/controllers/resource_controller.dart` - State management
- `lib/features/dashboard/widgets/metric_card.dart` - Metric widgets

### Features Implementate:
1. **CPU Monitor** - Lettura /proc/stat
2. **RAM Monitor** - Lettura /proc/meminfo  
3. **Disk Monitor** - Comando df
4. **Real-time Updates** - Refresh ogni 2 secondi
5. **Glassmorphism UI** - Cards con effetto vetro
6. **Responsive Layout** - Desktop (3 col) / Mobile (stack)

---

## Prossimi Step

### 1. Risolvi Build Issue
Prova una delle soluzioni sopra

### 2. Test Dashboard
```bash
flutter run -d linux
```

### 3. Continua Sviluppo
- File Manager
- Terminal Integration  
- Package Manager

