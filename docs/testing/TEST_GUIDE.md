# BrainiacPlus — Guida di test & catalogo verifiche

**Data:** 2026-07-08 · **Branch:** `gpu-detection-and-doc-checkup` · **Flutter:** 3.44.0 (stable) · **Piattaforma:** Linux (Wayland)

Questa guida cataloga le verifiche **automatiche** eseguite (riproducibili da chiunque) e
fornisce una **checklist manuale** per il test interattivo della GUI, con particolare
attenzione all'integrazione dell'LLM locale (Fase-1).

---

## 1. Ambiente

| | |
|---|---|
| Flutter | 3.44.0 stable (engine 4c525dac5e) |
| Sessione grafica | Wayland (`WAYLAND_DISPLAY=wayland-0`) |
| Build deps Linux | clang ✓, cmake ✓, ninja ✓, pkg-config ✓, gtk+-3.0 ✓ |
| LLM locale | container `llamacpp` (Mistral-Small-24B) su `http://localhost:8080/v1` — gestito da `scripts/local-llm.sh` |

---

## 2. Verifiche automatiche — ESITO ✅

Tutte eseguite il 2026-07-08. **Tutto verde.**

| Gate | Comando | Esito |
|---|---|---|
| **Static analysis** | `flutter analyze` | **0 errori** (20 warning + 248 info = debito lint preesistente: deprecazioni `withOpacity`, import inutilizzati — non bloccanti) |
| **Test suite** | `flutter test` | **120 / 120 test passati** |
| **Test servizio LLM** | `flutter test test/core/services/ollama_service_test.dart` | **10 / 10** (default, normalizzazione URL, ChatMessage, eccezioni) |
| **Build integrazione** | `flutter build linux --debug` | **✓ Built** `build/linux/x64/debug/bundle/brainiac_plus` |
| **Avvio runtime** | `./build/linux/x64/debug/bundle/brainiac_plus` | **✓ Parte e gira** — Dart VM service attivo, nessun crash (solo warning cosmetico "cursor theme") |
| **Protocollo LLM** | `curl localhost:8080/v1/chat/completions` (streaming + non) | **✓ Combacia** col parser SSE di `OllamaService` |

### Come rieseguire
```bash
cd ~/BrainiacPlus
flutter pub get
flutter analyze
flutter test
flutter build linux --debug
./build/linux/x64/debug/bundle/brainiac_plus   # avvio manuale
```

---

## 3. Checklist test manuale (GUI interattiva)

> Prerequisito AI: `./scripts/local-llm.sh start` (LLM locale su :8080).
> Avvio app: `flutter run -d linux` (oppure il binario buildato).

Spunta ogni voce mentre clicchi. **Focus Fase-1 = chat AI.**

### 3.1 Avvio & navigazione
- [ ] L'app si apre senza schermata d'errore
- [ ] La dashboard mostra le metriche (CPU/RAM/disk)
- [ ] La barra/menu di navigazione raggiunge tutte le sezioni

### 3.2 AI Assistant (integrazione LLM locale — Fase-1) ⭐
- [ ] Aprire **AI Assistant**
- [ ] Con `local-llm.sh` **spento** → inviando un messaggio compare l'errore corretto:
      *"Local LLM server not available … Start it with: ./scripts/local-llm.sh start"* (endpoint :8080)
- [ ] Con `local-llm.sh` **acceso** → inviare "ciao, chi sei?" → arriva una **risposta reale**
- [ ] Verificare la **risposta in streaming** (il testo appare progressivo)
- [ ] In **Impostazioni → AI** l'endpoint di default è `http://localhost:8080` (non più :11434)
- [ ] (Android) impostare l'endpoint su `http://<IP-LAN-del-PC>:8080` e verificare la chat

### 3.3 Altre sezioni (smoke test)
- [ ] **Automation** — creare un task; verificare che compaia (persistenza SQLite locale)
- [ ] **Terminal** — eseguire un comando (es. `ls`)
- [ ] **File Manager** — navigare tra cartelle
- [ ] **Packages** — la lista si carica
- [ ] **Settings** — aprire ogni tab senza crash (in particolare **AI Services**)
- [ ] **Onboarding** — il wizard scorre (se raggiungibile)

### 3.4 Regressioni note da controllare
- [ ] Il dropdown modello AI (Settings → AI) si apre senza assertion (fix recenti)
- [ ] Nessun freeze della UI (ErrorReporter — vedi commit `fea3538`)

---

## 4. Registrazione video del test

⚠️ **Nota tecnica:** su questa sessione Wayland non è stato possibile registrare lo
schermo in automatico (nessun tool tipo `wf-recorder`/`grim` installato e privilegi sudo
non disponibili in sessione; `ffmpeg x11grab` cattura solo schermo nero perché non vede
le finestre native Wayland). Il video va quindi registrato manualmente.

**Modo più semplice (GNOME, nessuna installazione):**
1. Avvia l'app e `local-llm.sh start`.
2. Premi **`Ctrl` + `Alt` + `Shift` + `R`** per avviare la registrazione schermo di GNOME.
3. Esegui la checklist della sezione 3 (soprattutto 3.2, la chat AI).
4. Premi di nuovo **`Ctrl` + `Alt` + `Shift` + `R`** per fermare.
5. Il video è in **`~/Videos/`** (`Screencast_*.webm`).

**In alternativa** (recorder dedicato, richiede installazione):
```bash
sudo apt install -y wf-recorder
wf-recorder -f ~/Videos/brainiac-test.mp4        # Ctrl+C per fermare
```

Salva i video in `~/Videos/brainiac-tests/` e aggiungi qui sotto il riferimento:

| Video | Cosa mostra | Data |
|---|---|---|
| _(da registrare)_ | Checklist §3.2 chat AI | — |

---

## 5. Limiti noti di questa tornata di test
- **Video GUI**: non automatizzabile in questa sessione (Wayland + no sudo + no automazione input). Registrazione manuale come sopra.
- **Test interattivi**: eseguiti come *checklist* (§3), non automatizzati end-to-end.
  Per automatizzarli servirebbe un `integration_test` con i servizi (DB/rete) mockati.
