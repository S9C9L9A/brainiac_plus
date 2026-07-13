# BrainiacPlus — Backlog

Backlog durevole. Le priorità immediate vivono nella TodoList di sessione; qui restano
le idee e i follow-up che sopravvivono tra le sessioni.

## Backend / modelli locali

- [ ] **Valutare Colibri (GLM-5.2 744B) come backend opzionale** — motore in C puro
  (`github.com/JustVugg/colibri`) che streamma gli esperti da SSD per girare un MoE 744B
  su ~25 GB RAM. **Non ora**: nessun supporto AMD/ROCm → CPU-bound e lento (~0,3 tok/s)
  sulla R9700, contro i ~34 tok/s del setup attuale (Mistral-24B). Ha un'API
  OpenAI-compatibile (`coli serve`), quindi in futuro si potrebbe agganciare come backend
  alternativo *solo* per sperimentare GLM-5.2, accettando la lentezza. Precondizione per
  rivalutare: comparsa di un backend ROCm o un test cronometrato reale sulla macchina.
  Vedi memoria `colibri-glm52-engine`.

## Chat assistant — follow-up ("e molto altro")

- [x] Storia della chat separata per progetto (ogni progetto ha il suo file di
  persistenza; la chat globale è a parte).
- [x] Drag & drop di file direttamente nella chat (oltre al menu ＋).
- [ ] Incolla-immagine dagli appunti nel composer.
- [ ] Supporto a un modello multimodale (es. LLaVA/Llama-Vision su Ollama) per vera
  analisi degli screenshot allegati (oggi l'immagine è solo un path referenziabile).

## Agente / knowledge graph

- [ ] Agenti in background (esecuzione asincrona di task lunghi).
- [ ] Sync del knowledge graph verso graphify / NotebookLM.
- [ ] Orchestrazione multi-agente (più agenti specializzati che collaborano).
