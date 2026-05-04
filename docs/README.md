# BrainiacPlus — Documentation

Welcome. Pick the entry point that matches what you're trying to do.

---

## I want to run the app

→ [`setup/QUICK_START.md`](setup/QUICK_START.md) — install + first run (5 min)
→ [`setup/INSTALLATION_GUIDE.md`](setup/INSTALLATION_GUIDE.md) — full install (Linux / macOS / Windows)

## I want to connect a social account

| Service | Quick start | Full guide |
|---|---|---|
| Facebook | [`setup/QUICK_START_FACEBOOK.md`](setup/QUICK_START_FACEBOOK.md) | [`setup/FACEBOOK_TOKEN_GUIDE.md`](setup/FACEBOOK_TOKEN_GUIDE.md) |
| Instagram | [`setup/INSTAGRAM_QUICK_START.md`](setup/INSTAGRAM_QUICK_START.md) | [`setup/INSTAGRAM_SETUP_GUIDE.md`](setup/INSTAGRAM_SETUP_GUIDE.md) |
| Instagram (CLI) | [`setup/INSTAGRAM_CLI_SETUP.md`](setup/INSTAGRAM_CLI_SETUP.md) | — |
| Other (YouTube, Twitter, …) | [`setup/SERVICE_CONFIG_GUIDE.md`](setup/SERVICE_CONFIG_GUIDE.md) | — |

## I want to understand the system

- [`architecture/SYSTEM_ARCHITECTURE.md`](architecture/SYSTEM_ARCHITECTURE.md) — high-level design with diagrams
- [`architecture/GO_BACKEND_GUIDE.md`](architecture/GO_BACKEND_GUIDE.md) — backend internals
- [`architecture/AI_ASSISTANT_INTEGRATION.md`](architecture/AI_ASSISTANT_INTEGRATION.md) — Ollama integration
- [`architecture/FACEBOOK_AUTOMATION_README.md`](architecture/FACEBOOK_AUTOMATION_README.md) — Facebook automation flow
- [`architecture/SOCIAL_MEDIA_CARDS_README.md`](architecture/SOCIAL_MEDIA_CARDS_README.md) — social-media UI cards
- [`architecture/METRICS_REFACTOR.md`](architecture/METRICS_REFACTOR.md) — system-metrics provider design

## I want to maintain or operate it

- [`guides/MAINTENANCE_GUIDE.md`](guides/MAINTENANCE_GUIDE.md)
- [`guides/SERVICE_CONFIGURATION_COMPLETE_GUIDE.md`](guides/SERVICE_CONFIGURATION_COMPLETE_GUIDE.md)
- [`guides/SERVICE_SETUP_QUICK_REFERENCE.md`](guides/SERVICE_SETUP_QUICK_REFERENCE.md)

## Implementation notes (short technical references)

- [`AUTOMATION_TEMPLATE_PREFILL.md`](AUTOMATION_TEMPLATE_PREFILL.md) — how template pre-fill works in the Create Automation tab
- [`SETTINGS_PERSISTENCE.md`](SETTINGS_PERSISTENCE.md) — where settings are stored

---

## Layout

```
docs/
├── README.md              ← you are here
├── architecture/          ← system design
├── setup/                 ← user-facing setup & quick starts
├── guides/                ← operations / maintenance
└── *.md                   ← short implementation notes
```

For dev-workflow conventions and Claude Code rules see [`/CLAUDE.md`](../CLAUDE.md).
For multi-agent dev routing see [`.github/agents/README.md`](../.github/agents/README.md).
