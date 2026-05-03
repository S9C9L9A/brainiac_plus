# 📖 Esempio Pratico: Sistema Multi-Agente

## Scenario: "Aggiungi supporto per colori ANSI nel Terminal"

### 🔄 Flusso di Lavoro

#### 1. User Request (TU)
```
"Voglio vedere i colori ANSI nell'output del terminal"
```

#### 2. Main Agent Analizza
- Identifica feature: **Terminal**
- Legge: `.agents/terminal.agent.md`
- Determina: serve modificare `terminal_output.dart`

#### 3. Delega a Terminal Agent
```dart
task(
  agent_type: "general-purpose",
  description: "Add ANSI color support",
  prompt: """
  SEI il Terminal Agent di BrainiacPlus.
  
  DOMINIO: lib/features/terminal/
  TASK: Aggiungi supporto per colori ANSI nell'output
  
  ISTRUZIONI:
  1. Leggi agents/terminal.agent.md per capire il tuo dominio
  2. Modifica widgets/terminal_output.dart
  3. Aggiungi parsing ANSI escape codes
  4. Testa con comandi colorati (ls --color, etc)
  5. Documenta le modifiche
  
  VINCOLI:
  - Modifica SOLO file in lib/features/terminal/
  - Mantieni compatibilità con codice esistente
  - Usa TextStyle per applicare colori
  """
)
```

#### 4. Terminal Agent Lavora
- Modifica `terminal_output.dart`
- Aggiunge parser ANSI codes
- Testa funzionalità
- Ritorna risultato

#### 5. Main Agent Verifica e Risponde
```
✅ Completato! Supporto ANSI colors aggiunto.
File modificati:
- lib/features/terminal/widgets/terminal_output.dart
- Aggiunti test: test/terminal/ansi_parser_test.dart
```

---

## Vantaggi vs Approccio Monolitico

### ❌ Approccio Attuale (Main Agent Solo)
```
User → Main Agent modifica tutto
- Deve conoscere TUTTA la codebase
- Rischio di modificare file non pertinenti
- Difficile manutenzione
```

### ✅ Approccio Multi-Agente
```
User → Main Agent → Delega a Terminal Agent
- Terminal Agent è ESPERTO nel suo dominio
- Modifica SOLO i file necessari
- Facile manutenzione e testing
- Possibile parallelismo
```

---

## Esempio Multi-Agente Parallelo

### Scenario: "Migliora UI di tutte le features"

```dart
// Esegui in parallelo:
task1 = task("terminal_agent", "Migliora terminal colors")
task2 = task("dashboard_agent", "Aggiungi grafici real-time")
task3 = task("packages_agent", "Migliora UI package list")

// Aspetta completamento
await Future.wait([task1, task2, task3])

// Risultato: 3 features migliorate in parallelo!
```

---

## Test del Sistema

Vuoi provarlo? Prova con:
```
"Terminal Agent: aggiungi ANSI colors support"
```

Il Main Agent leggerà terminal.agent.md e delegherà il lavoro!