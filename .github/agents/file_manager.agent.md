# 📂 File Manager Agent

**Dominio**: `lib/features/file_manager/`

---

## 🎯 Responsabilità

- Navigazione filesystem
- Operazioni CRUD su file/cartelle
- Preview file (immagini, testo, code)
- Search e filtering
- Bookmarks e recent locations

---

## 📁 Files Owned

```
lib/features/file_manager/
├── file_manager_screen.dart          # Main screen
├── controllers/
│   ├── file_manager_controller.dart  # State management
│   ├── file_operations_controller.dart # CRUD operations
│   └── clipboard_controller.dart     # Copy/cut/paste
└── widgets/
    ├── file_list_item.dart           # File/folder row
    ├── path_breadcrumb.dart          # Path navigation
    ├── file_preview.dart             # Preview panel
    ├── context_menu.dart             # Right-click menu
    └── search_bar.dart               # Search widget
```

---

## 🔧 Capabilities

- ✅ Browse directories
- ✅ Create/rename/delete files e folders
- ✅ Copy/cut/paste con clipboard
- ✅ File preview (images, text, markdown)
- ✅ Sort by name/date/size/type
- ✅ Hidden files toggle
- ✅ Bookmarks management
- ✅ Drag & drop support

---

## 📋 Supported Previews

| Extension | Preview Type |
|-----------|--------------|
| `.png`, `.jpg`, `.gif`, `.webp` | Image viewer |
| `.txt`, `.md`, `.json`, `.yaml` | Text viewer |
| `.dart`, `.go`, `.py`, `.js` | Syntax highlighted |
| `.pdf` | PDF viewer (Linux) |
| Others | Icon + metadata |

---

## 🔗 Dipendenze

- `core.agent.md` → Platform file services
- `terminal.agent.md` → Open terminal in directory

---

## 📖 Esempio Uso

```dart
// Navigate to directory
ref.read(fileManagerControllerProvider.notifier)
    .navigateTo('/home/user/Documents');

// Create new folder
ref.read(fileOperationsProvider.notifier)
    .createDirectory('New Folder');

// Delete file
ref.read(fileOperationsProvider.notifier)
    .delete('/path/to/file.txt');
```

---

## 🎨 UI Layout

```
┌────────────────────────────────────────────┐
│ 📂 /home/user/Documents          [🔍] [⚙️] │
├──────────────────────┬─────────────────────┤
│ 📁 Bookmarks         │ Name      Size  Date│
│ ├─ Home              │ ─────────────────── │
│ ├─ Documents         │ 📁 Projects   --    │
│ ├─ Downloads         │ 📁 Images     --    │
│ └─ Pictures          │ 📄 notes.md   2KB   │
│                      │ 📄 config.json 1KB  │
│ 📁 Recent            │                     │
│ ├─ /tmp              │                     │
│ └─ /var/log          │                     │
└──────────────────────┴─────────────────────┘
```
