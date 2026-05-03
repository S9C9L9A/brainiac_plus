# 🎯 Orchestrator Agent

**Ruolo**: Coordinatore centrale del sistema multi-agent

---

## 🎯 Responsabilità

1. **Routing delle Richieste**: Analizza ogni richiesta e la inoltra all'agente appropriato
2. **Conflict Resolution**: Gestisce richieste che coinvolgono più domini
3. **Dependency Tracking**: Monitora dipendenze cross-agent
4. **Quality Gate**: Verifica che le modifiche rispettino i vincoli del progetto

---

## 🔄 Workflow di Routing

```
┌─────────────────────────────────────────────────────────┐
│                    USER REQUEST                          │
└─────────────────────────┬───────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│              ORCHESTRATOR AGENT                          │
│                                                          │
│  1. Parse request intent                                │
│  2. Identify affected domains                           │
│  3. Check for conflicts with AI_VISION                  │
│  4. Select appropriate sub-agent(s)                     │
│  5. Delegate task with constraints                      │
└─────────────────────────┬───────────────────────────────┘
                          │
          ┌───────────────┼───────────────┐
          ▼               ▼               ▼
    ┌──────────┐    ┌──────────┐    ┌──────────┐
    │ Agent A  │    │ Agent B  │    │ Agent C  │
    └──────────┘    └──────────┘    └──────────┘
```

---

## 📋 Decision Matrix

| Intent Keywords | Primary Agent | Secondary Agent |
|-----------------|---------------|-----------------|
| chat, AI, ollama, genera codice | `ai_assistant` | `core` |
| CPU, RAM, metriche, monitor | `dashboard` | `core` |
| shell, comando, terminale | `terminal` | `core` |
| pacchetto, installa, apt, snap | `packages` | `core` |
| automazione, scheduler, task | `automation` | `dashboard` |
| impostazioni, config, tema | `settings` | `core` |
| file, cartella, browse | `file_manager` | `core` |
| wizard, setup, onboarding | `onboarding` | `settings` |
| API, backend, endpoint | `backend` | `core` |
| test, unit, integration | `testing` | - |
| docs, guida, readme | `docs` | - |
| theme, design, glassmorphism | `core` | `dashboard` |
| database, sqlite, storage | `core` | - |
| platform, linux, android | `core` | - |

---

## 🚦 Conflict Resolution Rules

### Single Domain
```
IF request affects only 1 domain:
  → Delegate directly to domain agent
  → No approval needed
```

### Multi-Domain (Low Risk)
```
IF request affects 2+ domains AND no blocked files:
  → Split into sub-tasks
  → Execute sequentially
  → Aggregate results
```

### Multi-Domain (High Risk)
```
IF request affects blocked files OR security-sensitive:
  → Halt and request explicit user approval
  → Show impact analysis
  → Proceed only with confirmation
```

---

## 📁 Non possiede File Propri

L'Orchestrator non modifica file direttamente. Delega sempre ai sub-agents.

---

## 🔗 Dipendenze

- Tutti gli altri agenti (delegation)
- `AI_VISION.md` (constraints)
- `CLAUDE.md` (root instructions)

---

## 📊 Monitoring Points

Traccia per ogni richiesta:
- Agent selezionato
- Path modificati
- Tempo di esecuzione
- Eventuali errori/rollback

---

## 🛡️ Safety Checks

Prima di delegare, verifica:
1. ✅ Richiesta allineata a AI_VISION
2. ✅ Nessun file bloccato coinvolto (o approval esplicito)
3. ✅ Agent selezionato ha permessi sui path
4. ✅ Nessun conflitto con task in corso
