# 📦 Packages Agent

**Dominio**: `lib/features/packages/`

---

## 🎯 Responsabilità

- Package management (APT, Snap, Flatpak)
- Install/Remove operations
- Search & filter packages
- Update/Upgrade system
- Package info e dependencies

---

## 📁 Files Owned

```
lib/features/packages/
├── packages_screen.dart              # Main packages UI
├── controllers/
│   ├── package_controller.dart       # Package state
│   ├── search_controller.dart        # Search functionality
│   └── install_controller.dart       # Install operations
├── models/
│   ├── package_info.dart             # Package model
│   └── package_source.dart           # APT/Snap/Flatpak enum
├── providers/
│   └── packages_providers.dart       # Riverpod providers
└── widgets/
    ├── package_card.dart             # Package list item
    ├── package_details.dart          # Detail view
    ├── source_filter.dart            # Source selector
    └── install_progress.dart         # Install progress UI
```

### Related Core Services
```
lib/core/platform/
└── package_service.dart              # Package operations
```

---

## 🔧 Capabilities

- ✅ Aggiungere supporto Flatpak
- ✅ Dependency resolution display
- ✅ Bulk operations (multi-install)
- ✅ Package recommendations
- ✅ Update notifications
- ✅ Repository management

---

## 📋 Package Sources

| Source | Command | Supported |
|--------|---------|-----------|
| APT | `apt-get` | ✅ Full |
| Snap | `snap` | ✅ Full |
| Flatpak | `flatpak` | 🔄 Partial |
| AppImage | Direct | ⏳ Planned |

---

## 🔗 Dipendenze

- `core.agent.md` → `PackageService`, `ShellService`
- `terminal.agent.md` → Package commands

---

## 📖 Esempio Uso

```dart
// Search packages
final results = ref.watch(
  packageSearchProvider('firefox')
);

// Install package
await ref.read(installControllerProvider.notifier)
    .install('firefox', source: PackageSource.apt);

// Get installed packages
final installed = ref.watch(installedPackagesProvider);

// Update all
await ref.read(packageControllerProvider.notifier)
    .upgradeAll();
```

---

## 🎨 UI Layout

```
┌────────────────────────────────────────────┐
│ 📦 Packages                    [🔄] [⚙️]   │
├────────────────────────────────────────────┤
│ 🔍 Search packages...                      │
│ [APT ▼] [Snap ▼] [Flatpak ▼] [Installed ▼]│
├────────────────────────────────────────────┤
│ ┌────────────────────────────────────────┐ │
│ │ 🦊 Firefox                   [Install] │ │
│ │ Mozilla Firefox web browser            │ │
│ │ APT • v125.0 • 80MB                    │ │
│ └────────────────────────────────────────┘ │
│ ┌────────────────────────────────────────┐ │
│ │ 💻 Visual Studio Code        [Remove]  │ │
│ │ Code editing. Redefined.               │ │
│ │ Snap • v1.87 • 300MB • Installed      │ │
│ └────────────────────────────────────────┘ │
└────────────────────────────────────────────┘
```

---

## 🛡️ Safety

- Install/Remove require polkit authentication
- Large downloads show confirmation
- Dependencies displayed before install
- No auto-remove of dependencies
