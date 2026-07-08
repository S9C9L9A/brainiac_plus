#!/usr/bin/env bash
# local-llm.sh — gestione dell'LLM locale stabile di BrainiacPlus.
#
# Backend: container Docker `llamacpp` (ghcr.io/ggml-org/llama.cpp:server-rocm)
# che serve Mistral-Small-24B su GPU AMD R9700 (gfx1201) via API OpenAI-compatibile
# su http://localhost:8080/v1.
#
# NOTA: NON usare ds4/DwarfStar su questa scheda discreta gfx1201 — congela il PC
# (vedi memoria di sessione). Questo stack llama.cpp è il path stabile.
#
# Uso: ./scripts/local-llm.sh {start|stop|status|test|ask "prompt"}
#   - `test` e `ask` accendono il modello da soli se è spento.
set -euo pipefail

CONTAINER="llamacpp"
BASE="http://localhost:8080"

_health() { curl -s --max-time 5 "$BASE/health" 2>/dev/null || true; }
_is_up()  { [ "$(_health)" = '{"status":"ok"}' ]; }

# Avvia il container e attende che il modello sia caricato.
# A freddo (dopo uno stop) il modello da ~14 GB va riletto da disco: può volerci
# qualche minuto; a caldo (page cache) sono pochi secondi. Deadline 5 min.
_start_and_wait() {
  docker start "$CONTAINER" >/dev/null
  echo -n "⏳ Attendo il caricamento del modello (a freddo può richiedere alcuni minuti)"
  local deadline=$((SECONDS + 300))
  while [ "$SECONDS" -lt "$deadline" ]; do
    if _is_up; then echo " ✓ pronto"; return 0; fi
    echo -n "."; curl -s --max-time 3 "$BASE/health" >/dev/null 2>&1 || true
  done
  echo " ✗ timeout dopo 5 min (controlla: docker logs $CONTAINER)"; return 1
}

# Garantisce che l'endpoint sia raggiungibile; se spento, lo avvia.
_ensure_up() {
  if _is_up; then return 0; fi
  echo "⚠ modello spento — lo avvio…"
  _start_and_wait
}

# Manda un prompt alla chat API e stampa la risposta, gestendo output vuoto/non-JSON.
_chat() {
  local prompt="$1" max="${2:-512}" body resp
  body="$(python3 -c 'import json,sys; print(json.dumps({"messages":[{"role":"user","content":sys.argv[1]}],"max_tokens":int(sys.argv[2]),"temperature":0.3}))' "$prompt" "$max")"
  resp="$(curl -s --max-time 120 "$BASE/v1/chat/completions" -H "Content-Type: application/json" -d "$body" 2>/dev/null || true)"
  if [ -z "$resp" ]; then
    echo "✗ nessuna risposta dall'endpoint ($BASE). Il modello è acceso? Prova: $0 start"; return 1
  fi
  echo "$resp" | python3 -c '
import sys, json
raw = sys.stdin.read()
try:
    d = json.loads(raw)
except json.JSONDecodeError:
    print("✗ risposta non valida dal server:"); print(raw[:500]); sys.exit(1)
if "choices" in d:
    print(d["choices"][0]["message"]["content"])
else:
    print("✗ errore dal server:", json.dumps(d)[:500])
    sys.exit(1)
'
}

case "${1:-status}" in
  start)
    echo "▶ Avvio container $CONTAINER…"; _start_and_wait ;;
  stop)
    echo "⏹ Fermo $CONTAINER (libera GPU + porta 8080)…"
    docker stop "$CONTAINER" >/dev/null && echo "✓ fermato (riavvia con: $0 start)" ;;
  status)
    echo "== Container =="
    docker ps --filter "name=$CONTAINER" --format '{{.Names}} | {{.Status}} | {{.Ports}}' || true
    echo "== Health =="
    h="$(_health)"; echo "${h:-(spento — avvialo con: $0 start)}"
    echo "== VRAM GPU[0] =="
    rocm-smi --showmeminfo vram 2>/dev/null | grep "GPU\[0\]" | grep -i "Used Memory" || echo "(rocm-smi non disponibile)" ;;
  test)
    _ensure_up
    echo "== Modello caricato =="
    curl -s --max-time 10 "$BASE/v1/models" | python3 -c 'import sys,json; print(" •", json.load(sys.stdin)["data"][0]["id"])' 2>/dev/null || echo "(impossibile leggere /v1/models)"
    echo "== Prova di inferenza =="
    echo -n " risposta: "; _chat "Rispondi in una parola: capitale d'Italia?" 20 ;;
  ask)
    shift; prompt="${*:?uso: $0 ask \"la tua domanda\"}"
    _ensure_up
    _chat "$prompt" 2048 ;;
  *)
    echo "Uso: $0 {start|stop|status|test|ask \"prompt\"}"; exit 2 ;;
esac
