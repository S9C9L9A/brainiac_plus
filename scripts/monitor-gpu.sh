#!/bin/bash
# GPU Monitor for Radeon AI PRO R9700
# Shows real-time GPU usage, temperature, and memory

watch -n 1 '
echo "═══════════════════════════════════════════════════════════════"
echo "          Radeon AI PRO R9700 - Real-time Monitor"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# Get basic GPU info
rocminfo 2>/dev/null | grep -E "Marketing Name:|gfx1201" | head -2

echo ""
echo "GPU Usage:"
rocm-smi --showuse 2>/dev/null || echo "rocm-smi not available"

echo ""
echo "GPU Memory:"
rocm-smi --showmeminfo 2>/dev/null || echo "rocm-smi not available"

echo ""
echo "Temperature:"
rocm-smi --showtemp 2>/dev/null || echo "rocm-smi not available"

echo ""
echo "Ollama Process:"
ps aux | grep -E "[o]llama serve" || echo "Ollama not running"

echo ""
echo "Current Model in Memory:"
curl -s http://localhost:11434/api/status 2>/dev/null | grep -o "\"model\":\"[^\"]*\"" || echo "No model loaded"

echo ""
echo "Press Ctrl+C to exit | Refreshing every 1 second..."
'
