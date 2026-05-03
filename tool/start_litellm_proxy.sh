#!/usr/bin/env bash
# Avvia il proxy LiteLLM per usare modelli Ollama locali con Claude Code
# Uso: ./tool/start_litellm_proxy.sh [--background]
#
# Dopo l'avvio, configura Claude Code con:
#   export ANTHROPIC_BASE_URL=http://localhost:4000
#   export ANTHROPIC_API_KEY=sk-brainiac-local
# oppure aggiungi queste righe al tuo ~/.bashrc o ~/.zshrc

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="$SCRIPT_DIR/litellm_config.yaml"
LOG_FILE="$SCRIPT_DIR/litellm.log"
PID_FILE="$SCRIPT_DIR/litellm.pid"

# Verifica Ollama in esecuzione
if ! curl -s http://localhost:11434/api/version > /dev/null 2>&1; then
  echo "⚠️  Ollama non è in esecuzione. Avvia Ollama prima di continuare."
  echo "   Comando: ollama serve"
  exit 1
fi

# Verifica modelli installati
echo "📦 Modelli Ollama disponibili:"
ollama list

# Avvia proxy
if [[ "$1" == "--background" ]]; then
  echo ""
  echo "🚀 Avvio proxy LiteLLM in background (porta 4000)..."
  nohup litellm --config "$CONFIG" > "$LOG_FILE" 2>&1 &
  echo $! > "$PID_FILE"
  sleep 2
  if curl -s http://localhost:4000/health > /dev/null 2>&1; then
    echo "✅ Proxy LiteLLM avviato (PID: $(cat $PID_FILE))"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📋 Configura Claude Code (aggiungi a ~/.bashrc o esegui):"
    echo "   export ANTHROPIC_BASE_URL=http://localhost:4000"
    echo "   export ANTHROPIC_API_KEY=sk-brainiac-local"
    echo "   claude"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "🛑 Per fermare:  kill \$(cat $PID_FILE)"
  else
    echo "❌ Proxy non risponde. Controlla $LOG_FILE"
    exit 1
  fi
else
  echo ""
  echo "🚀 Avvio proxy LiteLLM in foreground (porta 4000)..."
  echo "   Premi Ctrl+C per fermare"
  echo ""
  litellm --config "$CONFIG"
fi
