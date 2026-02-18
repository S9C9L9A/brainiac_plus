# Settings Persistence

Settings are stored locally using SharedPreferences.

## What is stored

- All fields in `ExtendedAppSettings`
- Tokens and API keys are stored as plain strings in local app storage

## Where the logic lives

- Storage: `lib/features/settings/services/extended_settings_storage.dart`
- Provider: `lib/features/settings/providers/extended_settings_provider.dart`
- Model: `lib/features/settings/models/extended_settings.dart`

## Notes

- If you need encrypted storage, migrate sensitive fields to `flutter_secure_storage`.
- Clearing settings can be done via `ExtendedSettingsController.clear()`.
