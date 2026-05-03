# ⚙️ Settings Agent

**Dominio**: `lib/features/settings/`

---

## 🎯 Responsabilità

- Gestione preferenze utente
- Configurazione servizi social (OAuth tokens)
- Theme selection (dark/light/system)
- Ollama/AI model configuration
- App behavior settings
- Data export/import

---

## 📁 Files Owned

```
lib/features/settings/
├── controllers/
│   ├── settings_controller.dart      # Main settings state
│   ├── theme_controller.dart         # Theme management
│   └── oauth_controller.dart         # OAuth flow handling
├── examples/
│   └── settings_examples.dart        # Usage examples
├── models/
│   ├── app_settings.dart             # Settings model
│   ├── service_credentials.dart      # OAuth credentials
│   └── ai_config.dart                # AI/Ollama config
├── providers/
│   ├── settings_providers.dart       # Riverpod providers
│   └── ai_settings_providers.dart    # AI-specific providers
├── screens/
│   ├── settings_screen.dart          # Main settings UI
│   ├── ai_services_tab.dart          # AI configuration tab
│   ├── social_accounts_screen.dart   # Social media accounts
│   └── advanced_settings_screen.dart # Advanced options
├── services/
│   ├── settings_service.dart         # Settings persistence
│   └── oauth_service.dart            # OAuth handling
└── widgets/
    ├── settings_tile.dart            # Reusable setting tile
    ├── theme_selector.dart           # Theme picker widget
    └── credential_form.dart          # Credential input form
```

---

## 🔧 Capabilities

- ✅ Persistenza settings (SharedPreferences/SQLite)
- ✅ OAuth flow per Facebook, Instagram, YouTube
- ✅ Gestione tokens e refresh automatico
- ✅ Theme switching con hot-reload
- ✅ Configurazione Ollama endpoint e modello
- ✅ Export/Import settings JSON

---

## 📋 Settings Categories

| Category | Keys | Storage |
|----------|------|---------|
| General | `theme`, `language`, `autoStart` | SharedPreferences |
| Social | `fb_token`, `ig_token`, `yt_token` | SecureStorage |
| AI | `ollama_url`, `model_name`, `temperature` | SharedPreferences |
| Advanced | `debug_mode`, `log_level`, `cache_size` | SharedPreferences |

---

## 🔗 Dipendenze

- `core.agent.md` → Database, SecureStorage
- `backend.agent.md` → API per OAuth callback
- `onboarding.agent.md` → Initial setup flow

---

## 🛡️ Security Notes

- **Tokens**: Sempre in `flutter_secure_storage`
- **Secrets**: Mai loggati o esposti in UI
- **OAuth**: Refresh automatico prima di scadenza

---

## 📖 Esempio Uso

```dart
// Leggi setting
final theme = ref.watch(themeSettingProvider);

// Aggiorna setting
ref.read(settingsControllerProvider.notifier).setTheme(ThemeMode.dark);

// OAuth flow
final token = await ref.read(oauthControllerProvider.notifier)
    .authenticateFacebook();
```
