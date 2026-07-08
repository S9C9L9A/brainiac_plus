# ADR-0001: Ruolo del backend per BrainiacPlus (Go, Supabase, o niente)

**Status:** Accepted — **Option A** (2026-07-08)
**Date:** 2026-07-08
**Deciders:** Owner (cm.999club)

> **Decisione (2026-07-08):** no sync cross-device. Architettura minimale:
> **SQLite locale** (dati) + **llama.cpp** (AI, :8080) + **mini-proxy Go solo per
> Facebook/Instagram su :8090**. **Niente Supabase.** Il Go viene ridotto al solo proxy Meta.

> **Nota di revisione:** la prima stesura assumeva che lo stack Supabase in esecuzione
> fosse di BrainiacPlus. **Falso**: quei container hanno label progetto `MAIN_CLUB`
> (il progetto 999-club, `~/999-club-adk`). BrainiacPlus **non ha** un progetto Supabase
> (solo la dipendenza `supabase_flutter` nel pubspec, non inizializzata). Questa ADR è
> corretta di conseguenza.

## Context

BrainiacPlus: Flutter (Linux + Android), **single-user, local-first**.

Stato verificato nel codice:
- **Persistenza locale già presente e usata**: `sqflite` + `sqflite_common_ffi` +
  `shared_preferences`; `lib/core/database/automation_database.dart` e
  `automation_repository.dart` salvano task/automazioni **in SQLite locale**.
- **AI**: integrata e diretta a llama.cpp su `:8080` (non passa da alcun backend).
- **Backend Go** (`go_backend/`, 590 righe): scaffolding incompleto —
  JWT gen/extract sono TODO (`routes/facebook.go:55,68`), nessuna connessione DB reale
  (`DATABASE_URL` in `.env` ma niente `sql.Open`), `/api/sync` = `// TODO: Supabase`
  (`main.go:139`), `/api/ollama/*` ormai bypassato dall'app.
  Suoi **unici consumatori reali** nell'app = le feature **Facebook/Instagram**
  (`social_media_controller.dart`, `facebook_login_screen.dart`,
  `facebook_automation_*`), tutte hardcoded a `:8080`.
- **Supabase**: nessun progetto per BrainiacPlus; lo stack attivo è di `MAIN_CLUB`.
- **Conflitto porta `:8080`**: le feature Facebook (Go) e l'AI (llama.cpp) la vogliono
  entrambe. Conflitto reale interno all'app.

Forze: single-user, local-first, minimizzare superficie operativa, tenere i **segreti Meta
lato server** (non possono stare nel client Flutter). Dato che si usano **Linux e Android**,
il tema **sync cross-device** è il vero discriminante.

## Decision

**Non serve un backend applicativo generale.** I dati sono già locali (SQLite) e l'AI è
locale (llama.cpp). L'**unico bisogno genuinamente server-side è il proxy Facebook/Instagram**
(segreti + OAuth token exchange + posting schedulato).

Proposta:
1. **Dati/task** → restano in **SQLite locale** (già così). Nessun backend.
2. **AI** → llama.cpp su `:8080` (fatto).
3. **Facebook/Instagram** → **restringere** il Go al solo proxy Meta e **spostarlo da `:8080`**
   (es. `:8090`) per liberare `:8080` all'AI. Aggiornare i ~5 file che hardcodano `:8080`
   per il backend social (meglio: renderlo un setting).
4. **Supabase** → **solo se** vuoi **sync cross-device Linux↔Android** (o auth cloud). In tal
   caso: progetto Supabase **dedicato** a BrainiacPlus (non quello di 999-club). Altrimenti
   **non introdurlo** ora.

## Options Considered

### Option A: Nessun backend generale — SQLite locale + Go ridotto al proxy Meta — **Recommended**
| Dimension | Assessment |
|-----------|------------|
| Complexity | Low (usa ciò che c'è già) |
| Cost | ~0 (nessun nuovo servizio) |
| Scalability | Adeguata a single-user local-first |
| Team familiarity | Alta (SQLite già usato, Go già scritto) |

**Pros:** minima superficie; dati già locali; risolve il conflitto `:8080`; il proxy Meta
(unico vero bisogno server) resta piccolo e isolato.
**Cons:** nessun sync cross-device; mantieni un piccolo servizio Go.

### Option B: Consolidare su Supabase (progetto dedicato per BrainiacPlus)
| Dimension | Assessment |
|-----------|------------|
| Complexity | Med–High (init progetto, schema, RLS, riscrivere data layer) |
| Cost | Nuovo stack locale (11 container) **oppure** progetto cloud |
| Scalability | Alta; **abilita sync cross-device + realtime** |
| Team familiarity | Media (dipendenza presente ma mai usata) |

**Pros:** sync Linux↔Android, auth gestita, Edge Function per Meta, Realtime per "seguire le
operazioni".
**Cons:** **non è già in esecuzione per BrainiacPlus** (la premessa "gratis" era errata);
stand-up di un altro stack pesante o dipendenza cloud; migrazione del data layer da SQLite;
sovradimensionato se non serve il sync.

### Option C: Completare il backend Go come monolite
**Pros:** un linguaggio, controllo totale.
**Cons:** reimplementi auth/DB/sync già risolti altrove; duplica SQLite locale;
più codice custom da mantenere per zero beneficio single-user.

## Trade-off Analysis

Il discriminante reale è **il sync cross-device**, non "Go vs Supabase":
- **Se NON ti serve il sync** (un device per volta): Option A vince nettamente — dati locali
  in SQLite (già così), AI locale, e solo un mini-proxy Meta lato server. Supabase sarebbe
  sovraingegnerizzazione.
- **Se ti serve il sync Linux↔Android** (task/stato condivisi tra i due): allora un backend
  condiviso ha senso, e **Supabase (progetto dedicato)** è la scelta giusta — Go resterebbe
  comunque da completare a mano e duplicherebbe ciò che Supabase dà pronto.

In entrambi i casi **tenere/espandere il Go come backend generale non è la scelta migliore**:
o è superfluo (Option A) o è inferiore a Supabase (Option B). Il Go sopravvive, se mai, solo
come piccolo proxy Meta.

## Consequences

- **Più facile (A):** meno servizi, conflitto porta risolto, si sfrutta SQLite esistente.
- **Più difficile (A):** niente sync; il proxy Meta va comunque finito (oggi è TODO).
- **Se B:** abiliti sync/realtime ma paghi setup + manutenzione di uno stack dedicato.
- **Da rivedere:** gestione segreti Meta; se in futuro servisse multi-device, rivalutare B.

## Action Items

1. [ ] **Rispondere alla domanda chiave: serve sync cross-device Linux↔Android?** (decide A vs B)
2. [ ] (A) Restringere `go_backend` al solo proxy Facebook/Instagram e spostarlo su `:8090`;
       rendere l'URL del backend social un setting; rimuovere `/api/ollama/*` e `/api/tasks`.
3. [ ] (A) llama.cpp resta su `:8080`; nessuno spostamento container.
4. [ ] (B, solo se sync) `supabase init` progetto dedicato BrainiacPlus; schema task; RLS;
       cablare `supabase_flutter`; Edge Function `facebook-post`; dismettere il Go.
5. [ ] In entrambi i casi: finire il flusso Meta (oggi JWT/OAuth sono TODO nel Go).

> Cambiamento strategico: separato dal commit della Fase-1 (integrazione LLM, già fatta).
