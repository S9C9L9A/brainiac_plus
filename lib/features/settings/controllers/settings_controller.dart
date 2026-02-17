import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/app_settings.dart';

/// Provider for secure storage
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

/// Provider for settings controller
final settingsControllerProvider =
    StateNotifierProvider<SettingsController, AppSettings>((ref) {
  return SettingsController(ref.watch(secureStorageProvider));
});

/// Settings Controller
class SettingsController extends StateNotifier<AppSettings> {
  final FlutterSecureStorage _storage;

  SettingsController(this._storage) : super(AppSettings()) {
    _loadSettings();
  }

  /// Load settings from secure storage
  Future<void> _loadSettings() async {
    try {
      final higgsfieldKey = await _storage.read(key: 'higgsfield_api_key');
      final openaiKey = await _storage.read(key: 'openai_api_key');
      final instaToken = await _storage.read(key: 'instagram_access_token');
      final instaUserId = await _storage.read(key: 'instagram_user_id');
      final instaUsername = await _storage.read(key: 'instagram_username');
      final instaExpiry = await _storage.read(key: 'instagram_token_expiry');

      final notificationsStr = await _storage.read(key: 'notifications_enabled');
      final autoRefreshStr = await _storage.read(key: 'auto_refresh_metrics');
      final refreshIntervalStr = await _storage.read(key: 'refresh_interval');
      final theme = await _storage.read(key: 'theme');
      final automationStr = await _storage.read(key: 'automation_enabled');
      final retryStr = await _storage.read(key: 'retry_failed_tasks');
      final maxRetriesStr = await _storage.read(key: 'max_retries');

      state = AppSettings(
        higgsfieldApiKey: higgsfieldKey,
        openaiApiKey: openaiKey,
        instagramAccessToken: instaToken,
        instagramUserId: instaUserId,
        instagramUsername: instaUsername,
        instagramTokenExpiry: instaExpiry != null 
            ? DateTime.parse(instaExpiry) 
            : null,
        notificationsEnabled: notificationsStr == 'true',
        autoRefreshMetrics: autoRefreshStr != 'false',
        refreshInterval: int.tryParse(refreshIntervalStr ?? '5') ?? 5,
        theme: theme ?? 'system',
        automationEnabled: automationStr != 'false',
        retryFailedTasks: retryStr != 'false',
        maxRetries: int.tryParse(maxRetriesStr ?? '3') ?? 3,
      );
    } catch (e) {
      // If loading fails, keep default settings
      debugPrint('Error loading settings: $e');
    }
  }

  /// Save Higgsfield API key
  Future<void> saveHiggsfieldKey(String key) async {
    await _storage.write(key: 'higgsfield_api_key', value: key);
    state = state.copyWith(higgsfieldApiKey: key);
  }

  /// Save OpenAI API key
  Future<void> saveOpenAIKey(String key) async {
    await _storage.write(key: 'openai_api_key', value: key);
    state = state.copyWith(openaiApiKey: key);
  }

  /// Save Instagram credentials
  Future<void> saveInstagramAuth({
    required String accessToken,
    required String userId,
    required String username,
    required DateTime expiresAt,
  }) async {
    await _storage.write(key: 'instagram_access_token', value: accessToken);
    await _storage.write(key: 'instagram_user_id', value: userId);
    await _storage.write(key: 'instagram_username', value: username);
    await _storage.write(key: 'instagram_token_expiry', value: expiresAt.toIso8601String());

    state = state.copyWith(
      instagramAccessToken: accessToken,
      instagramUserId: userId,
      instagramUsername: username,
      instagramTokenExpiry: expiresAt,
    );
  }

  /// Disconnect Instagram
  Future<void> disconnectInstagram() async {
    await _storage.delete(key: 'instagram_access_token');
    await _storage.delete(key: 'instagram_user_id');
    await _storage.delete(key: 'instagram_username');
    await _storage.delete(key: 'instagram_token_expiry');

    state = state.copyWith(
      instagramAccessToken: null,
      instagramUserId: null,
      instagramUsername: null,
      instagramTokenExpiry: null,
    );
  }

  /// Toggle notifications
  Future<void> toggleNotifications(bool enabled) async {
    await _storage.write(key: 'notifications_enabled', value: enabled.toString());
    state = state.copyWith(notificationsEnabled: enabled);
  }

  /// Toggle auto-refresh metrics
  Future<void> toggleAutoRefresh(bool enabled) async {
    await _storage.write(key: 'auto_refresh_metrics', value: enabled.toString());
    state = state.copyWith(autoRefreshMetrics: enabled);
  }

  /// Set refresh interval
  Future<void> setRefreshInterval(int seconds) async {
    await _storage.write(key: 'refresh_interval', value: seconds.toString());
    state = state.copyWith(refreshInterval: seconds);
  }

  /// Set theme
  Future<void> setTheme(String theme) async {
    await _storage.write(key: 'theme', value: theme);
    state = state.copyWith(theme: theme);
  }

  /// Toggle automation
  Future<void> toggleAutomation(bool enabled) async {
    await _storage.write(key: 'automation_enabled', value: enabled.toString());
    state = state.copyWith(automationEnabled: enabled);
  }

  /// Toggle retry failed tasks
  Future<void> toggleRetry(bool enabled) async {
    await _storage.write(key: 'retry_failed_tasks', value: enabled.toString());
    state = state.copyWith(retryFailedTasks: enabled);
  }

  /// Set max retries
  Future<void> setMaxRetries(int retries) async {
    await _storage.write(key: 'max_retries', value: retries.toString());
    state = state.copyWith(maxRetries: retries);
  }

  /// Clear all settings
  Future<void> clearAll() async {
    await _storage.deleteAll();
    state = AppSettings();
  }
}
