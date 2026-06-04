# GPU Optimization Guide — Radeon AI PRO R9700

## Hardware Specs
- **GPU**: AMD Radeon AI PRO R9700 (gfx1201)
- **GPU VRAM**: 32 GB
- **CPU**: AMD Ryzen 9 9950X3D (16-core)
- **System RAM**: 1,280 GB
- **Model**: mistral-medium-3.5:latest (80 GB, Q4_K_M quantization)

---

## Configuration Overview

### 1. Environment Variables (Auto-loaded)
File: `~/.bashrc.ollama-gpu`

Key variables:
```bash
export HSA_OVERRIDE_GFX_VERSION=11.0.1      # Force gfx1201 support
export HIP_VISIBLE_DEVICES=0                 # Use GPU 0
export ROCM_HOME=/opt/rocm                   # ROCm path
export OLLAMA_NUM_GPU=1                      # Use 1 GPU
export OLLAMA_NUM_THREAD=16                  # All CPU cores
export OLLAMA_KEEP_ALIVE=300                 # Keep model 5 min
```

Automatically sourced in `~/.bashrc`.

### 2. Model Configuration
- **Default Model**: `mistral-medium-3.5:latest`
- **Model Size**: 80 GB (unquantized) / ~26 GB (Q4_K_M)
- **Quantization**: Q4_K_M (4-bit)
- **Context Window**: 32K tokens
- **Max Tokens Output**: 2,000 default

**Why Mistral Medium 3.5?**
- High-quality reasoning
- Excellent for code generation & AI assistant tasks
- Q4_K_M quantization balances quality vs. speed
- Fits partially in 32GB VRAM with offloading to system RAM

### 3. Layer Offloading (GPU vs CPU)
With 32 GB VRAM + mistral-medium-3.5:
- ~16 layers loaded in GPU VRAM
- Remaining layers offload to system RAM (CPU inference, slower)
- Expected throughput: **10–30 tokens/sec** (depending on batch size)

To maximize GPU load:
- Increase `OLLAMA_NUM_PARALLEL` (currently 4)
- Or use larger batch sizes in applications

---

## Quick Start

### Option A: Auto-Configured Launcher
```bash
cd ~/BrainiacPlus
./scripts/start-with-gpu.sh
```
This script:
1. ✅ Configures GPU environment
2. ✅ Checks Ollama & model status
3. ✅ Pre-warms GPU (2–5 minutes)
4. ✅ Launches app or backend

### Option B: Manual Setup
```bash
# Load GPU config
source ~/.bashrc.ollama-gpu

# Start Ollama (if not running)
ollama serve &

# Start BrainiacPlus
cd ~/BrainiacPlus
flutter run -d linux
```

### Option C: Backend Only
```bash
cd ~/BrainiacPlus/go_backend
cp .env.example .env
go run .
# Ollama accessible at http://localhost:11434
```

---

## Monitoring GPU Usage

### Real-time Monitor (Built-in)
```bash
./scripts/monitor-gpu.sh
```

### Manual Commands
```bash
# GPU info
rocminfo | grep gfx1201

# GPU usage
rocm-smi --showuse

# Memory usage
rocm-smi --showmeminfo

# Temperature
rocm-smi --showtemp

# Ollama process
pgrep -f "ollama serve"
```

### Expected Metrics (with active inference)
| Metric | Expected Range |
|--------|----------------|
| GPU Load | 80–100% |
| GPU Memory | 28–32 GB |
| Temp | 60–80°C |
| CPU Usage | 40–60% (inference) |

---

## Performance Tuning

### 1. Maximize GPU Utilization (90–100%)
```bash
# Increase parallel inferences
export OLLAMA_NUM_PARALLEL=8          # Default 4, max depends on VRAM

# Reduce context window if needed (faster inference)
# In code: use num_ctx parameter in inference calls
```

### 2. Faster Response Time
```bash
# Keep model in VRAM longer (faster subsequent calls)
export OLLAMA_KEEP_ALIVE=600          # 10 min instead of 5

# Increase num_threads if CPU-bound
export OLLAMA_NUM_THREAD=16            # Already at max (16-core CPU)
```

### 3. Longer Context Support
```bash
# mistral-medium-3.5 supports 32K tokens
# To use full context in inference:
# - In OllamaService calls, pass num_ctx=32000
# - Requires more VRAM (context stored in memory)
```

### 4. Custom Per-Model Settings
In `lib/features/settings/screens/modern/tabs/ai_services_tab.dart`:
- You can set `num_gpu_layers` per model (higher = more GPU, less CPU)
- Current: Auto (Ollama decides)

---

## Troubleshooting

### GPU Not Detected
```bash
# Verify GPU is visible
rocminfo | grep -A2 gfx1201

# Check ROCm installation
ls /opt/rocm/bin/rocminfo
```

### Ollama Crashes on Model Load
```bash
# Check logs
tail -f /tmp/ollama.log

# Verify VRAM isn't full
rocm-smi --showmeminfo

# Try smaller model temporarily
ollama run mistral:7b
```

### Slow Inference (<5 tokens/sec)
- Check GPU load: `rocm-smi --showuse`
- If GPU load is low, inference may be CPU-bound
- Solution: Reduce context window or increase `num_gpu_layers`

### Temperature Too High (>85°C)
- Reduce `OLLAMA_NUM_PARALLEL` to lower GPU power
- Check GPU cooling / airflow
- Normal under load: 70–80°C is fine

---

## Files Modified

### Model Defaults
- `lib/core/services/ollama_service.dart` → `mistral-medium-3.5:latest`
- `lib/core/services/automation_assistant_service.dart` → same
- `lib/features/settings/screens/modern/tabs/ai_services_tab.dart` → same
- `tool/litellm_config.yaml` → `ollama/mistral-medium-3.5:latest`

### GPU Configuration
- `~/.bashrc.ollama-gpu` → GPU env vars (auto-sourced)
- `scripts/start-with-gpu.sh` → Full launcher with checks
- `scripts/monitor-gpu.sh` → Real-time GPU monitor

---

## Recommendations

✅ **Do:**
- Monitor GPU temp on first run (should stabilize ~70°C)
- Use the launcher script `./scripts/start-with-gpu.sh`
- Keep Ollama running as a background service
- Run inference tasks in parallel to maximize GPU

❌ **Don't:**
- Run multiple large models simultaneously (will OOM)
- Disable GPU offloading (hurts performance significantly)
- Ignore high temps (>85°C consistently) — check cooling

---

## References
- Ollama Docs: https://ollama.com
- ROCm AMD: https://rocmdocs.amd.com/
- Mistral Medium: https://huggingface.co/mistralai/Mistral-Medium-3.5

---

**Last Updated**: 2026-05-09  
**GPU Model**: Radeon AI PRO R9700  
**ROCm Version**: 7.2.2  
**Ollama Version**: 0.22.1  
