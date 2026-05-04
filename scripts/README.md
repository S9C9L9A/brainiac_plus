# scripts/

Shell scripts for testing and demos. All scripts assume the Go backend
is running on `localhost:8080` and (where relevant) Ollama on `:11434`.

| Script | Purpose |
|---|---|
| `test_automazioni_complete.sh` | End-to-end automation flow test |
| `test_facebook_automation.sh` | Facebook publishing smoke test |
| `test_facebook_interactive.sh` | Interactive Facebook flow (prompts user) |
| `test_instagram_integration.sh` | Instagram Graph API integration test |
| `demo_automation_scheduler.sh` | Demo of the task scheduler |

## Run

```bash
./scripts/test_automazioni_complete.sh
```

Make sure they're executable: `chmod +x scripts/*.sh`.
