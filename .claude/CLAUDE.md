---
title: "BrainiacPlus — Istruzioni di sessione (Cowork Senior Agent)"
description: "Contratto operativo unificato: regole specifiche del progetto BrainiacPlus + protocollo Cowork Senior Agent. Singolo punto di verità per Claude Code e qualsiasi AI agent."
version: 3.0.1
last_updated: 2026-07-10
project_version: 2.0.0
language: italiano (termini tecnici, comandi e identificatori in inglese)
applies_to: "Repository BrainiacPlus + sessioni Cowork che lavorano su questo progetto"
companion_skill: "cowork-senior-agent (caricato come plugin, vedi §22)"
---

# BrainiacPlus — Istruzioni di sessione

> **Regola zero**: se un'istruzione in questo file contraddice una richiesta utente, **segnalalo** e chiedi conferma con `AskUserQuestion`. **Non improvvisare.**

Questo file è il **singolo contratto operativo** che Claude legge a ogni sessione su questo repository. Sostituisce e unifica i precedenti `CLAUDE.md` (root progetto v2.0 + `.claude/CLAUDE.md` v2.1 Cowork Senior Agent).

---

## 1. Bootstrap di sessione (obbligatorio)

All'avvio di ogni sessione, in ordine:

1. **Leggi questo `CLAUDE.md`** integralmente.
2. **Verifica skill `cowork-senior-agent`** caricato (vedi §22). Se sì, è il riferimento operativo per task tecnici complessi.
3. **Leggi/aggiorna `memory/`** se presente (skill `productivity:memory-management`).
4. **Leggi `TASKS.md`** se presente (skill `productivity:task-management`).
5. Richiesta **non banale** (>1 step, output durevole, codice, ricerca, file) → crea **TodoList** con `TaskCreate`, **sempre con uno step finale di verifica**.
6. Richiesta **sotto-specificata** → `AskUserQuestion` PRIMA di partire (audience, formato, scope, deadline, vincoli).

Eccezione: domande puramente conversazionali o factual brevi → risposta diretta, niente todolist.

---

## 2. Principi operativi non negoziabili

1. **Ragionamento DIM1/DIM2/DIM3** per ogni task tecnico medio/complesso (vedi §13). Documenta il ragionamento, non solo il risultato.
2. **Micro-change mindset**: una responsabilità per modifica/PR. Niente refactor globali non richiesti.
3. **Safety first**: modifiche solo nei percorsi consentiti (§8). Mai toccare segreti, build artifact, certificati, configurazioni piattaforma senza approvazione.
4. **QA prima di consegnare**: format → analyze/lint → test (+ coverage se critico). Nessun output senza gate verde (§12).
5. **Tracciabilità totale**: ogni azione lascia traccia (TodoList, log, citation, file di output).
6. **HID quando serve** (§14): se serve decisione umana, fermati e chiedi.
7. **Niente fabbricazione**: se non sai una versione, un endpoint, un nome → cercalo o chiedi. Mai inventare.

---

## 3. Prompt contract (sempre attivo)

Per ogni richiesta in questo repo:

1. **Conferma allineamento** con [`.github/agents/AI_VISION.md`](.github/agents/AI_VISION.md).
2. **Scegli il domain agent** dalla tabella in §6.
3. **Dichiara i path consentiti** prima di editare.
4. **Cambio multi-dominio** → split o richiedi approvazione.
5. **File locked** (§7) → richiede richiesta esplicita dell'utente.

---

## 4. Progetto in un paragrafo

BrainiacPlus è un'app Flutter multi-piattaforma (Linux primary, Android secondary, v2.0.0) backed by una REST API Go su `localhost:8080`. Funzionalità: social-media automation (Facebook + Instagram via Graph API), system monitoring (CPU/RAM/disk), terminal & file manager embedded, package management, task scheduling, AI assistant powered by Ollama locale su `localhost:11434`.

---

## 5. Tech stack

**Frontend**
- Flutter 3.10+, Dart 3.x
- State: Riverpod 2.x — *nota*: `provider` è ancora in `pubspec` (legacy, candidato a rimozione, vedi §20).
- Icons: Lucide via `lib/core/theme/app_icons.dart`
- DB: sqflite (+ ffi for desktop)
- UI: Glassmorphism via `lib/core/theme/`

**Backend**
- Gin HTTP framework
- JWT auth
- Facebook + Instagram Graph API integrations
- Default port: `8080`

**AI**
- Ollama on `localhost:11434`
- Tested: CodeLlama 7B, Llama2, Mistral
- Use case: code generation, self-modification, automation suggestions

---

## 6. Project structure & domain routing

```
brainiac_plus/
├── lib/                       # Flutter app (Dart)
│   ├── main.dart              # 🔒 entry point
│   ├── core/                  # Shared infra
│   │   ├── database/          # SQLite layer
│   │   ├── debug/
│   │   ├── navigation/
│   │   ├── network/           # HTTP / API client
│   │   ├── platform/          # Linux/Android-specific
│   │   ├── providers/         # Global Riverpod providers
│   │   ├── services/          # Business services (Ollama, scheduler, …)
│   │   ├── theme/             # Glassmorphism design system
│   │   └── utils/
│   ├── features/              # One folder per domain
│   │   ├── activity/
│   │   ├── ai_assistant/      # 🤖 chat + code generation
│   │   ├── automation/        # ⚡ task scheduler & macros
│   │   ├── dashboard/         # 📊 metrics
│   │   ├── file_manager/      # 📂 dual-pane browser
│   │   ├── onboarding/        # 🎯 setup wizard
│   │   ├── packages/          # 📦 apt/snap/flatpak
│   │   ├── settings/          # ⚙️
│   │   └── terminal/          # 🖥️ xterm.dart
│   └── routes/                # Navigation
├── go_backend/                # Go REST API (Gin + JWT)
│   ├── main.go                # entry
│   ├── routes/                # HTTP handlers
│   ├── services/              # Business logic
│   └── models/                # Data structures
├── test/                      # Dart unit / widget tests
├── tool/                      # Dart CLI tools (instagram_cli_runner, litellm)
├── scripts/                   # Shell scripts (test runners, demos)
├── docs/                      # Documentation (see docs/README.md)
├── android/  linux/           # Platform-specific Flutter builds
├── .github/agents/            # Multi-agent definitions
└── .claude/CLAUDE.md          # This file
```

**Domain routing** — scegli l'agente PRIMA di editare:

| Domain | Agent | Allowed paths |
|---|---|---|
| AI / Ollama | `ai_assistant` | `lib/features/ai_assistant/`, `lib/core/services/ollama_*` |
| Dashboard | `dashboard` | `lib/features/dashboard/` |
| Terminal | `terminal` | `lib/features/terminal/` |
| Packages | `packages` | `lib/features/packages/` |
| Automation | `automation` | `lib/features/automation/` |
| Settings | `settings` | `lib/features/settings/` |
| File Manager | `file_manager` | `lib/features/file_manager/` |
| Onboarding | `onboarding` | `lib/features/onboarding/` |
| Activity | `activity` | `lib/features/activity/` |
| Core / Platform | `core` | `lib/core/` |
| Backend (Go) | `backend` | `go_backend/` |
| Testing | `testing` | `test/` |
| Docs | `docs` | `docs/` |

Definizioni complete degli agenti in [`.github/agents/`](.github/agents/).

---

## 7. 🔒 Locked files (richiesta esplicita richiesta)

| File | Perché |
|---|---|
| `pubspec.yaml` | Flutter dependencies — version drift rompe il lockfile |
| `lib/main.dart` | App entry point |
| `go_backend/.env` | Secrets — never commit. Già in `.gitignore`. |
| `android/app/build.gradle.kts` | Android build config |

---

## 8. Percorsi consentiti / vietati

**Consentiti senza approvazione** (compatibili con il domain routing in §6):
- Sorgenti: `lib/`, `go_backend/`, `tool/`, `scripts/`
- Test: `test/`, `tests/`, `__tests__/`
- Documentazione: `docs/`, `README*`, `CHANGELOG*`
- Config dev/agent: `.github/agents/`, `.claude/` (eccetto questo file), `.cursor/`, `.continue/`, `.autopilot/`, `instructions/`
- Output Cowork: cartella `outputs/` o workspace selezionato dall'utente

**Vietati senza approvazione esplicita (HID obbligatorio, §14)**:
- File **locked** (§7).
- Segreti / credenziali: `.env*`, `secrets/`, `*.key`, `*.pem`, `key.properties`.
- Artefatti di build: `build/`, `dist/`, `out/`, `target/`, `node_modules/`, `.dart_tool/`.
- Configurazioni piattaforma native fuori dal domain routing: `android/app/build.gradle.kts`, `ios/`, `Pods/`, codice firmato.
- Certificati, profili di provisioning, file di store.
- File di sistema utente fuori dalla cartella di lavoro.

> Nota: `android/` e `linux/` come cartelle sono accessibili in lettura per il routing, ma le **modifiche** ai file di build/firma richiedono HID.

Se la richiesta tocca un percorso vietato → `AskUserQuestion` per conferma esplicita prima di procedere.

---

## 9. Dev commands

```bash
# Frontend
flutter pub get
flutter run -d linux           # hot-reload dev loop (preferred)
flutter test
flutter analyze

# Backend
cd go_backend
cp .env.example .env           # one-time, fill in secrets
go mod tidy
go run .                       # listens on :8080
go test ./...

# Smoke test
curl http://localhost:8080/health
```

---

## 10. Code conventions

### Dart / Flutter
```dart
// Files: snake_case
// Classes: PascalCase
// Functions/vars: camelCase
// Constants: lowerCamelCase

// State via Riverpod
final myProvider = StateNotifierProvider<MyNotifier, MyState>((ref) => ...);

// Prefer ConsumerWidget for stateful UI
class MyWidget extends ConsumerWidget { ... }

// Always use the design system
Container(decoration: GlassmorphismDecoration.card(), child: ...);
Icon(AppIcons.settings);
```

### Go
```go
// packages: lowercase
// Public funcs: PascalCase, private: camelCase
// Always handle errors

func HandleRequest(c *gin.Context) {
    if err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }
}
```

---

## 11. Trigger di skill (mappa decisionale)

Al ricevere un task, scegli lo skill PRIMA di scrivere codice o documenti. Più skill possono coesistere (es. `engineering:documentation` + `anthropic-skills:docx`).

| Tipo richiesta | Skill da invocare |
|---|---|
| Creare/modificare `.docx`, lettere, report Word | `anthropic-skills:docx` |
| Creare/modificare `.pptx`, slide, deck | `anthropic-skills:pptx` |
| Creare/leggere/manipolare PDF, form, merge/split | `anthropic-skills:pdf` |
| Creare/modificare `.xlsx`, modelli finanziari, tabelle | `anthropic-skills:xlsx` |
| Poster, design statico PNG/PDF artistico | `anthropic-skills:canvas-design` |
| Generative art, p5.js, particle systems | `anthropic-skills:algorithmic-art` |
| Branding Anthropic, look-and-feel ufficiale | `anthropic-skills:brand-guidelines` |
| Artifact HTML/React complesso multi-componente | `anthropic-skills:web-artifacts-builder` |
| Code review (PR, diff, sicurezza, performance) | `engineering:code-review` |
| Debugging strutturato (errore, regression) | `engineering:debug` |
| ADR, scelta tra tecnologie, design decision | `engineering:architecture` |
| System design, API, data model, service boundaries | `engineering:system-design` |
| Strategia/piano di test | `engineering:testing-strategy` |
| README, runbook, onboarding, API docs | `engineering:documentation` |
| Incident in corso o postmortem | `engineering:incident-response` |
| Standup giornaliero | `engineering:standup` |
| Pre-deploy checklist | `engineering:deploy-checklist` |
| Tech debt audit | `engineering:tech-debt` |
| Critique design / Figma / mockup | `design:design-critique` |
| WCAG / accessibilità | `design:accessibility-review` |
| Microcopy, error messages, empty states | `design:ux-copy` |
| Audit/estensione design system | `design:design-system` |
| Spec di handoff dev | `design:design-handoff` |
| Piano/sintesi user research | `design:user-research`, `design:research-synthesis` |
| Task scheduling ricorrente | `anthropic-skills:schedule` |
| Creare/modificare uno skill | `anthropic-skills:skill-creator` |
| **Operazione tecnica avanzata Cowork senior** | **`cowork-senior-agent`** (vedi §22) |

Regola: **leggi `SKILL.md` dello skill prima di iniziare il lavoro**.

---

## 12. Gate di qualità (QA) prima di "fatto"

Adatta i comandi al linguaggio, ma applica sempre i tre gate:

| Gate | Obiettivo | BrainiacPlus | Generici |
|---|---|---|---|
| **Format** | Stile uniforme | `dart format`, `gofmt` | `prettier`, `black`, `rustfmt` |
| **Static analysis** | Zero warning critici | `dart analyze`, `go vet` | `eslint`, `mypy`, `tsc --noEmit`, `clippy` |
| **Test + coverage** | Verde, copertura adeguata | `flutter test --coverage`, `go test ./...` | `pytest --cov`, `npm test` |

**Soglie di copertura**:
- Codice critico (auth, pagamenti, sicurezza, calcoli finanziari, JWT, OAuth Instagram/Facebook): **≥ 90%**.
- Modifiche ordinarie: **≥ 80%**.
- Prototipi/POC: documentato come tale, soglia non bloccante.

**Output non-codice** (docx, pptx, pdf, xlsx): il "test" è la verifica finale (apertura/render, controllo struttura, cross-check fatti). **Non skippare la verifica.**

---

## 13. Formato risposta DIM1/DIM2/DIM3

Per ogni proposta tecnica > 5 righe di codice o decisione architetturale:

1. **DIM1 — Logica**: contratto input/output, edge case, comportamento atteso.
2. **DIM2 — Evidenza & best practice**: pattern/libreria/standard di riferimento, perché questa scelta.
3. **DIM3 — Probabilità, bias, mitigazioni**: stima `P(bug critico)`, rischi, contromisure (test, feature flag, rollback).
4. **Proposta micro-change**: file target, descrizione del diff, dimensione attesa.
5. **Test da aggiungere/aggiornare**: unit, integration, smoke, snapshot.
6. **Domande aperte**: cosa serve confermare prima/dopo.

Per task non-codice: DIM1 = obiettivo e vincoli, DIM2 = riferimenti/fonti, DIM3 = rischi (errori fattuali, bias, completezza).

Esempi e dettaglio: workflow `dim-analysis.md` dello skill `cowork-senior-agent` (§22).

---

## 14. Protocollo HID (Human-in-the-Loop)

Fermati e chiedi conferma quando:
- Richiesta ambigua su scope/audience/formato/deadline.
- Tocco di percorsi vietati (§8) o file locked (§7).
- Decisione tra alternative con trade-off rilevanti (dipendenza nuova, cambio architetturale, scelta UX).
- Servono credenziali/segreti.
- Risultato di test/QA ambiguo o fallisce in modo non banale.
- **Specifico BrainiacPlus**: cambio in `lib/main.dart`, `pubspec.yaml`, `go_backend/.env`, `android/app/build.gradle.kts`, o consolidamento di servizi duplicati (vedi §20).

**Strumento**: `AskUserQuestion` con 2-4 opzioni mutualmente esclusive (o multi-select se non lo sono). Etichetta `(Recommended)` in prima posizione se hai una preferenza motivata.

Mentre attendi: aggiorna la TodoList come `pending` con motivazione del blocco. Non procedere oltre lo step bloccato.

Dettaglio: workflow `hid-protocol.md` dello skill `cowork-senior-agent` (§22).

---

## 15. Tracciabilità & citazioni

- **TodoList**: `TaskCreate`/`TaskUpdate` per task con ≥3 step o output durevole. Sempre uno step finale di **verifica** (rilettura, run di test, screenshot, fact-check).
- **File di output**: salva in `outputs/` o nella cartella selezionata dall'utente. Linka con `computer://` (mai path interni `/sessions/...`).
- **Sources**: se hai usato file locali o tool MCP con contenuto linkabile, chiudi la risposta con sezione `Sources:` e link `[Titolo](URL)`.
- **Log azioni**: per task complessi multi-step, mantieni log strutturato (template `task-log-template.json` dello skill `cowork-senior-agent`, §22).

---

## 16. Stile, sicurezza, dipendenze

- **Commit semantici** in inglese: `feat:`, `fix:`, `refactor:`, `test:`, `docs:`, `chore:`, `perf:`. Messaggio = **cosa + perché**.
- **No `print` / `console.log` / `debugPrint` ridondanti** in produzione → logger centralizzato.
- **Niente segreti hardcoded** → `go_backend/.env.example` + config centralizzata. `.env*` in `.gitignore`.
- **Dipendenze**: pacchetti stabili e mantenuti (release < 6 mesi quando possibile). Audit periodico (`dart pub outdated`, `npm audit`, `pip-audit`, `cargo audit`). Nuove dipendenze richiedono giustificazione in DIM2.
- **Niente refactor opportunistici** in PR di feature: separa.

---

## 17. Workflow operativo standard (task tecnico)

```
1. Capisci la richiesta → AskUserQuestion se ambigua
2. TaskCreate (TodoList) con step + verifica finale
3. Identifica skill rilevanti → leggi i loro SKILL.md
4. Conferma domain routing (§6) e percorsi consentiti (§8)
5. DIM1/2/3 sulla soluzione
6. Implementa micro-change
7. QA: format → analyze → test (+ coverage se critico)
8. Output in outputs/ o cartella utente, link computer://
9. Verifica finale (lettura output, run, screenshot, fact-check)
10. Sources + breve riassunto operativo
```

---

## 18. Esempi end-to-end

### Esempio A — "Aggiungi test per `lib/core/services/ollama_service.dart`"
1. Domain: `core` (vedi §6). Skill: `engineering:testing-strategy` + `cowork-senior-agent`.
2. Todo: leggi servizio → mappa edge case (timeout, 503, payload malformato) → scrivi test → run → coverage → verifica.
3. DIM1: input/output del client Ollama, edge case (HTTP 503, JSON parsing, streaming response).
4. Micro-change: nuovo file `test/core/services/ollama_service_test.dart` isolato.
5. QA: `dart format`, `flutter analyze`, `flutter test --coverage` verdi, coverage del file ≥ 90% (è codice critico AI).
6. Output: file di test + log riassuntivo.
7. Verifica: rerun `flutter test`, output diff in PR.

### Esempio B — "Crea un report Word sull'andamento Q1"
1. Skill: `anthropic-skills:docx` + eventuale `engineering:documentation`.
2. AskUserQuestion: audience, lunghezza, dati di input, deadline.
3. Todo: outline → contenuti → revisione → export `.docx` → verifica.
4. Output `outputs/report-q1.docx`, link `computer://`.
5. Verifica: apri il file, controlla TOC, heading, numerazione.

### Esempio C — "Decidi tra Riverpod puro e Bloc per il flusso Automation"
1. Domain: `automation` + `core`. Skill: `engineering:architecture` (ADR) + `cowork-senior-agent`.
2. DIM1: requisiti (stream events, persistenza scheduler, testabilità).
3. DIM2: confronto Riverpod 2.x vs Bloc + riferimenti, già abbiamo Riverpod.
4. DIM3: rischi (migrazione codice esistente, learning curve, dual-state §20), mitigazioni.
5. Output: ADR markdown in `docs/architecture/adr/NNNN-state-management.md`.
6. HID: richiedi conferma sulla decisione finale prima di marcare l'ADR come "accepted".

### Esempio D — "Implementa endpoint Go `/automation/runs`"
1. Domain: `backend`. Path consentito: `go_backend/routes/`, `go_backend/services/`, `go_backend/models/`.
2. Skill: `engineering:system-design` + `cowork-senior-agent`.
3. DIM1: contratto REST (request/response, status codes, auth JWT obbligatoria).
4. Micro-change: handler in `routes/`, service in `services/`, model in `models/`, test in `go_backend/.../*_test.go`.
5. QA: `gofmt`, `go vet`, `go test ./...`. Smoke: `curl :8080/automation/runs` con JWT.
6. Output: codice + test + entry in `docs/api/`.

Workflow di dettaglio: vedi `workflows/` dello skill `cowork-senior-agent` (§22).

---

## 19. Cosa NON fare (red flags)

- ❌ Modificare file locked (§7) senza approvazione esplicita.
- ❌ Eseguire shell commands distruttivi senza approvazione (`rm -rf`, `git push --force`, drop DB).
- ❌ Leggere/scrivere segreti, credenziali, certificati.
- ❌ Modificare security settings, JWT signing keys, OAuth client secrets.
- ❌ Push code senza review, force-push, riscrivere git history senza approvazione.
- ❌ Refactor globali non richiesti / refactor opportunistici in PR di feature.
- ❌ Toccare `android/app/`, `ios/`, `Pods/`, store assets senza HID.
- ❌ Aggiungere dipendenze "alla moda" non valutate in DIM2.
- ❌ Saltare i gate QA "tanto è una piccola modifica".
- ❌ Scrivere documenti lunghi senza prima chiedere audience/scope.
- ❌ Inventare versioni, API, citazioni, fatti.
- ❌ Usare path interni Cowork (`/sessions/...`) nei link mostrati all'utente.
- ❌ Marcare task `completed` con test rossi o lavoro parziale.

### AI può
- ✅ Generare nuovi widget / screen.
- ✅ Creare automation tasks.
- ✅ Modificare UI esistente (con preview).
- ✅ Aggiungere feature in sandbox.

---

## 20. ⚠️ Known code-health flags

Candidati a refactor (non auto-fix; servono test verdi prima):

- **Two task schedulers**: `lib/core/services/task_scheduler.dart` + `task_scheduler_service.dart`. Probabile duplicato; consolidare.
- **Three Instagram services**: `instagram_service.dart`, `instagram_oauth_service.dart`, `instagram_cli_service.dart` in `lib/core/services/`. Verificare se la separazione (OAuth vs CLI vs API) è intenzionale, altrimenti merge.
- **Dual state libs**: `pubspec.yaml` ha sia `flutter_riverpod` che `provider`. Scegliere uno (preferenza Riverpod) e rimuovere l'altro dopo migrazione consumer.
- **Deep nesting**: `lib/features/settings/screens/modern/tabs/` è un livello troppo profondo — flatten al prossimo tocco di settings.
- **Routes barrel inutilizzato**: `lib/routes/routes.dart` ri-esporta gli altri ma nessun file lo importa. Adottare ovunque o eliminare.

Ognuno di questi richiede HID prima di partire (§14).

---

## 21. Documentation map

- **Vision**: [`.github/agents/AI_VISION.md`](.github/agents/AI_VISION.md)
- **Docs index**: [`docs/README.md`](docs/README.md)
- **Architecture**: [`docs/architecture/SYSTEM_ARCHITECTURE.md`](docs/architecture/SYSTEM_ARCHITECTURE.md)
- **Setup**: [`docs/setup/QUICK_START.md`](docs/setup/QUICK_START.md)
- **Agents**: [`.github/agents/README.md`](.github/agents/README.md)
- **README**: [`README.md`](README.md)

---

## 22. Skill companion `cowork-senior-agent`

Skill installato come plugin. Si **invoca per nome** (non serve specificare il path):

```
skill: cowork-senior-agent
```

**Path filesystem corrente del plugin** (per consultazione/edit manuale dei workflow):
```
~/.claude/plugins/marketplaces/claude-plugins-official/external_plugins/cowork-senior-agent/
```

> Nota: `marketplaces/claude-plugins-official/` è gestita dal client. Per resistere agli aggiornamenti del marketplace, sposta il plugin in `~/.claude/plugins/cowork-senior-agent/` (fuori da `marketplaces/`) o pubblicalo in un marketplace privato.

**File interni dello skill** (path relativi alla root del plugin):
- `SKILL.md` — entrypoint dello skill (caricato automaticamente).
- `workflows/micro-pr.md` — anatomia della micro-PR.
- `workflows/dim-analysis.md` — esempi DIM1/2/3 (codice + ricerca).
- `workflows/hid-protocol.md` — checklist e template HID.
- `templates/micro-pr-template.md` — template descrizione PR.
- `templates/task-log-template.json` — schema log task.

Se la struttura interna del plugin cambia, aggiornare questa sezione e fare bump di `version` nel front-matter.

---

## 23. Versioning & posizionamento di queste istruzioni

**Posizionamento canonico** (singolo punto di verità):
- ✅ `<root-progetto>/.claude/CLAUDE.md` — **questo file**, vince per il progetto BrainiacPlus. Vive accanto al resto della config Claude Code del progetto.
- 🟡 `~/.claude/CLAUDE.md` — opzionale, **solo per regole globali Cowork** che valgono su tutti i progetti (non duplicare regole di questo file lì).
- ❌ `<root-progetto>/CLAUDE.md` — **non più usato**: rimosso in v3.0.1. Non ricrearlo; se un tool lo richiede, usare un puntatore a questo file.

**Versioning**:
- Ogni cambio rilevante → bump `version` nel front-matter (semver-like) e commit dedicato `docs(claude-md): bump vX.Y.Z — <motivo>`.
- Lo skill `cowork-senior-agent` deve restare allineato a questo file. Se diverge, allineare prima di procedere.

**Changelog**
- **v3.0.1 (2026-07-10)** — Posizionamento canonico corretto: il file vive in `.claude/CLAUDE.md` (il root `CLAUDE.md` è stato rimosso dal repo); §23 allineata allo stato reale.
- **v3.0.0 (2026-05-06)** — Unificazione di `CLAUDE.md` (root, v2.0) + `.claude/CLAUDE.md` (Cowork v2.1) in un singolo file. Risolte sovrapposizioni di safety/forbidden paths. Esempi end-to-end specifici BrainiacPlus aggiunti. Sezione locked files integrata con il protocollo HID.
- v2.1 (Cowork) — Riferimenti skill `cowork-senior-agent` come plugin invocabile per nome.
- v2.0 (BrainiacPlus) — Domain routing, locked files, code-health flags.
