# 📚 Docs Agent

**Dominio**: `docs/`

---

## 🎯 Responsabilità

- Documentazione tecnica
- Guide utente
- API documentation
- Architecture diagrams
- Changelog e release notes

---

## 📁 Files Owned

```
docs/
├── README.md                         # Docs index
├── AI_ASSISTANT_IMPLEMENTATION_SUMMARY.md
├── AI_ASSISTANT_INTEGRATION.md
├── AUTOMATION_TEMPLATE_PREFILL.md
├── INSTAGRAM_CLI_SETUP.md
├── INSTAGRAM_INDEX.md
├── SETTINGS_PERSISTENCE.md
├── architecture/
│   ├── SYSTEM_ARCHITECTURE.md        # System overview
│   ├── GO_BACKEND_GUIDE.md           # Backend docs
│   ├── FACEBOOK_AUTOMATION_README.md # Facebook docs
│   └── SOCIAL_MEDIA_CARDS_README.md  # Social cards docs
├── archive/                          # Old/deprecated docs
├── guides/
│   ├── MAINTENANCE_GUIDE.md          # Dev guide
│   ├── TEST_RESULTS.md               # Test reports
│   └── PERMESSO_MANCANTE.md          # Troubleshooting
└── setup/
    ├── QUICK_START.md                # Quick start guide
    ├── INSTALLATION_GUIDE.md         # Full install guide
    ├── QUICK_START_FACEBOOK.md       # Facebook setup
    ├── FACEBOOK_TOKEN_GUIDE.md       # Token guide
    ├── INSTAGRAM_QUICK_START.md      # Instagram setup
    ├── INSTAGRAM_SETUP_GUIDE.md      # Instagram full guide
    └── SERVICE_CONFIG_GUIDE.md       # Service config
```

---

## 🔧 Capabilities

- ✅ Creare nuova documentazione
- ✅ Aggiornare docs esistenti
- ✅ Generare API reference
- ✅ Creare diagrammi (Mermaid)
- ✅ Mantenere changelog

---

## 📋 Documentation Types

| Type | Location | Audience |
|------|----------|----------|
| Architecture | `docs/architecture/` | Developers |
| Setup | `docs/setup/` | End users |
| Guides | `docs/guides/` | Both |
| API | `docs/api/` (TBD) | Developers |
| Agent Docs | `.github/agents/` | AI/Claude |

---

## 🔗 Dipendenze

- Tutti gli agenti (documentazione features)
- `backend.agent.md` → API docs

---

## 📖 Convenzioni

### Markdown Style
```markdown
# Main Title
## Section
### Subsection

**Bold** for emphasis
`code` for inline code
```code blocks``` for examples

- Bullet lists for items
1. Numbered for steps
```

### File Naming
- `UPPERCASE_SNAKE.md` per docs principali
- `lowercase_snake.md` per guide minori

### Diagrams
Use Mermaid for inline diagrams:
```markdown
```mermaid
graph LR
    A[User] --> B[App]
    B --> C[Backend]
```

---

## 🚀 Comandi

```bash
# Preview docs locally (if using docsify/mkdocs)
cd docs && docsify serve

# Generate API docs from code
dart doc lib/
```
