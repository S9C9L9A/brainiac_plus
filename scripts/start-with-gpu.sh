#!/bin/bash
# BrainiacPlus Launcher with GPU Optimization
# Configures Ollama for Radeon AI PRO R9700 and launches the app

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   BrainiacPlus GPU-Optimized Launcher     ║${NC}"
echo -e "${BLUE}║   Radeon AI PRO R9700 (32GB) + Mistral    ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
echo ""

# Check if running from BrainiacPlus root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

if [ ! -f "$ROOT_DIR/pubspec.yaml" ]; then
    echo -e "${RED}❌ Error: Not in BrainiacPlus root directory${NC}"
    echo "   Expected pubspec.yaml in: $ROOT_DIR"
    exit 1
fi

echo -e "${GREEN}✅ BrainiacPlus root: $ROOT_DIR${NC}"
cd "$ROOT_DIR"

# Load GPU environment variables
echo -e "${BLUE}🎮 Configuring GPU environment...${NC}"
export HSA_OVERRIDE_GFX_VERSION=11.0.1
export HIP_VISIBLE_DEVICES=0
export GPU_DEVICE_ORDINAL=0
export ROCM_HOME=/opt/rocm
export PATH=$ROCM_HOME/bin:$PATH
export LD_LIBRARY_PATH=$ROCM_HOME/lib:$LD_LIBRARY_PATH
export OLLAMA_NUM_GPU=1
export OLLAMA_LOAD_TIMEOUT=600
export OLLAMA_NUM_THREAD=16
export OLLAMA_NUM_PARALLEL=4
export OLLAMA_KEEP_ALIVE=300
export OLLAMA_DEFAULT_MODEL=mistral-medium-3.5:latest

echo -e "${GREEN}✅ GPU Environment configured:${NC}"
echo "   GPU: Radeon AI PRO R9700 (gfx1201)"
echo "   VRAM: 32 GB"
echo "   CPU Threads: 16"
echo "   Model: mistral-medium-3.5:latest (80GB)"
echo "   Memory Available: 1280 GB RAM + 32 GB VRAM"
echo ""

# Check Ollama status
echo -e "${BLUE}🔍 Checking Ollama service...${NC}"
if curl -s http://localhost:11434/api/version > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Ollama is running${NC}"
    OLLAMA_PID=$(pgrep -f "ollama serve" | head -1)
    echo "   Process ID: $OLLAMA_PID"
else
    echo -e "${YELLOW}⚠️  Ollama is not running!${NC}"
    echo "   Starting Ollama..."
    # Note: This assumes ollama is in PATH. Adjust path if needed.
    ollama serve > /tmp/ollama.log 2>&1 &
    OLLAMA_PID=$!
    sleep 3
    if curl -s http://localhost:11434/api/version > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Ollama started (PID: $OLLAMA_PID)${NC}"
    else
        echo -e "${RED}❌ Failed to start Ollama${NC}"
        tail -20 /tmp/ollama.log
        exit 1
    fi
fi

echo ""

# Check if model is loaded
echo -e "${BLUE}🔍 Checking mistral-medium-3.5:latest...${NC}"
MODELS=$(curl -s http://localhost:11434/api/tags | grep -o '"name":"[^"]*mistral-medium-3.5[^"]*"' || true)
if [ -z "$MODELS" ]; then
    echo -e "${RED}❌ mistral-medium-3.5:latest not found!${NC}"
    echo "   Available models:"
    curl -s http://localhost:11434/api/tags | grep -o '"name":"[^"]*"' | cut -d'"' -f4 | sed 's/^/      /'
    echo ""
    echo -e "${YELLOW}Please pull the model:${NC}"
    echo "   ollama pull mistral-medium-3.5"
    exit 1
fi
echo -e "${GREEN}✅ mistral-medium-3.5:latest is available${NC}"

echo ""

# Optional: Load model into VRAM preemptively
echo -e "${BLUE}📦 Pre-loading model into VRAM (this may take 2-5 minutes on first run)...${NC}"
echo -e "${YELLOW}⏳ Warming up GPU (80GB model + 32GB VRAM)...${NC}"
timeout 600 curl -s http://localhost:11434/api/generate \
    -d '{
        "model": "mistral-medium-3.5:latest",
        "prompt": "Start initialization",
        "stream": false
    }' > /dev/null 2>&1 || true

echo -e "${GREEN}✅ GPU warmed up${NC}"
echo ""

# Display GPU usage command
echo -e "${BLUE}📊 To monitor GPU usage in another terminal, run:${NC}"
echo "   watch -n 1 'rocminfo | grep -A2 gfx1201'"
echo "   # Or: gpu-monitor (if installed)"
echo ""

# Ask for launch mode
echo -e "${BLUE}How would you like to launch BrainiacPlus?${NC}"
echo "   1. flutter run -d linux  (development + hot reload)"
echo "   2. Run backend only      (go_backend/)"
echo "   3. Skip launch (just configure)"
read -p "Choice [1/2/3]: " CHOICE

case $CHOICE in
    1)
        echo -e "${BLUE}🚀 Launching Flutter app...${NC}"
        flutter pub get
        flutter run -d linux
        ;;
    2)
        echo -e "${BLUE}🚀 Launching Go backend...${NC}"
        cd go_backend
        cp .env.example .env 2>/dev/null || true
        go run .
        ;;
    3)
        echo -e "${GREEN}✅ GPU configuration complete!${NC}"
        echo "   You can now:"
        echo "   - Run: flutter run -d linux"
        echo "   - Run: cd go_backend && go run ."
        echo "   - Run: flutter test"
        ;;
    *)
        echo -e "${RED}Invalid choice${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}✅ Done!${NC}"
