# 🤖 BrainiacPlus - Multi-Agent System

Sistema di agenti specializzati per la manutenzione del progetto.

## 📁 Struttura Agenti

```
.agents/
├── README.md                  → Questa guida
├── terminal_agent.md          → Gestisce features/terminal/
├── dashboard_agent.md         → Gestisce features/dashboard/
├── packages_agent.md          → Gestisce features/packages/
├── file_manager_agent.md      → Gestisce features/file_manager/
├── automation_agent.md        → Gestisce features/automation/
├── ai_assistant_agent.md      → Gestisce features/ai_assistant/
└── core_agent.md              → Gestisce core/ (platform, database, theme)
```

## 🔄 Workflow

1. **User** → Richiesta al **Main Agent** (CLI)
2. **Main Agent** → Delega al **Sub-Agent** appropriato
3. **Sub-Agent** → Lavora nel suo dominio
4. **Main Agent** → Risponde all'utente

## ✨ Vantaggi

- ✅ **Divide et Impera**: Ogni agente conosce il suo dominio
- ✅ **Manutenzione**: Codice isolato e organizzato
- ✅ **Parallelismo**: Agenti lavorano in parallelo
- ✅ **Expertise**: Specializzazione per area

## 📝 Esempio Uso

```
User: "Aggiungi colori ANSI al terminal"
Main Agent → task(terminal_agent, "Implementa ANSI colors")
Terminal Agent → Modifica features/terminal/
Main Agent → Conferma completamento
```
