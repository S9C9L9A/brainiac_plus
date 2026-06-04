# scripts/

Helper scripts for testing, demos, the terminal dashboard, and GPU tuning.
Most assume the Go backend on `localhost:8080` and (where relevant) Ollama on `:11434`.

## Test & demo scripts

| Script | Purpose |
|---|---|
| `test_automazioni_complete.sh` | End-to-end automation flow test |
| `test_facebook_automation.sh` | Facebook publishing smoke test |
| `test_facebook_interactive.sh` | Interactive Facebook flow (prompts user) |
| `test_instagram_integration.sh` | Instagram Graph API integration test |
| `demo_automation_scheduler.sh` | Demo of the task scheduler |

```bash
./scripts/test_automazioni_complete.sh
```

Make sure they're executable: `chmod +x scripts/*.sh`.

## Terminal dashboard (Python, needs `rich`)

| Script | Purpose |
|---|---|
| `brainiac-dashboard.py` | **Recommended / stable** — glassmorphism terminal dashboard: live metrics, GPU, tasks, launcher, logs |
| `brainiac-dashboard-v2.py` | Experimental 16:9 layout with chat panel |
| `brainiac-dashboard-arcade.py` | Retro ASCII "arcade" edition |
| `brainiac-dashboard-arcade-pro.py` | Arcade Pro with playable mini-games |
| `launch-dashboard` | Launcher wrapper — auto-installs `rich`, sets GPU env, then starts the stable dashboard |

```bash
./scripts/launch-dashboard          # easiest entry point
# or directly:
python3 scripts/brainiac-dashboard.py
```

See [`docs/DASHBOARD_GUIDE.md`](../docs/DASHBOARD_GUIDE.md) for shortcuts and config.

## GPU / ROCm (Radeon AI PRO R9700)

| Script | Purpose |
|---|---|
| `start-with-gpu.sh` | Full GPU-optimized launcher: configures ROCm env, verifies Ollama + model, pre-warms VRAM, then launches app or backend |
| `monitor-gpu.sh` | Real-time `rocm-smi` monitor (usage, VRAM, temperature) |

```bash
./scripts/start-with-gpu.sh         # configure + launch
./scripts/monitor-gpu.sh            # watch GPU in a second terminal
```

See [`docs/GPU_OPTIMIZATION.md`](../docs/GPU_OPTIMIZATION.md) for the full tuning guide.
