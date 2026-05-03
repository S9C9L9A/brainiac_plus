# 🔧 Ollama Integration Agent

**Ruolo**: Gestione del layer di integrazione con Ollama API e model management.

> Separato da `ai_assistant.agent.md` che si occupa della UI/UX.

---

## 🎯 Responsabilità

- Client HTTP Ollama (`ollama_service.dart`)
- Gestione modelli (lista, download, switch)
- Hardware detection per model recommendations
- Configurazione endpoint e parametri di generazione
- Gestione errori connessione e fallback

---

## 📁 File Owned

```
lib/core/services/
├── ollama_service.dart              # HTTP client Ollama API
├── model_suggestions_service.dart   # Model recommendations per hardware
├── hardware_detection_service.dart  # CPU/RAM detection
├── local_ai_installer.dart          # Ollama install helper

lib/core/providers/
└── ai_settings_providers.dart       # Riverpod providers per Ollama
```

---

## 🤖 Modelli Locali Installati

| Modello | Dimensione | Uso consigliato |
|---------|-----------|-----------------|
| `qwen2.5-coder:14b` | 9.0 GB | **Default** — coding, generazione codice Flutter |
| `codellama:13b` | 7.4 GB | Backup — code completion, refactoring |

---

## 🔌 Ollama API Endpoints

```
Base URL: http://localhost:11434

POST /api/generate    # Generazione non-streaming
POST /api/chat        # Chat (streaming e non)
GET  /api/tags        # Lista modelli installati
GET  /api/version     # Health check
```

---

## 🔄 LiteLLM Proxy (Claude Code)

Per usare i modelli locali con Claude Code CLI:

```bash
# Avvia proxy (porta 4000)
./tool/start_litellm_proxy.sh --background

# Configura Claude Code
export ANTHROPIC_BASE_URL=http://localhost:4000
export ANTHROPIC_API_KEY=sk-brainiac-local
claude
```

Config: `tool/litellm_config.yaml`

---

## 🧩 Provider Architecture

```dart
// Modelli installati su Ollama in esecuzione
final ollamaAvailableModelsProvider =
    FutureProvider.family<List<OllamaModel>, String>((ref, baseUrl) async {
  final service = OllamaService(baseUrl: baseUrl);
  return service.listModelsDetailed();
});

// Modelli raccomandati per hardware
final recommendedModelsProvider = FutureProvider<List<OllamaModelInfo>>(...)

// Service con model/endpoint da settings
final ollamaServiceProvider = Provider<OllamaService>((ref) {
  final settings = ref.watch(extendedSettingsProvider);
  return OllamaService(
    baseUrl: settings.ollamaEndpoint,
    model: settings.ollamaModelName,  // default: qwen2.5-coder:14b
  );
});
```

---

## ⚠️ Regole

- Non modificare `lib/features/ai_assistant/` (dominio di `ai_assistant` agent)
- Non modificare `pubspec.yaml`
- Tutti i cambiamenti al service layer richiedono aggiornamento test in `test/`
