import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import '../models/extended_settings.dart';

class ExtendedSettingsStorage {
  static const String _storageKey = 'extended_app_settings';

  Future<ExtendedAppSettings?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return ExtendedAppSettings.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(ExtendedAppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(settings.toJson());
    await prefs.setString(_storageKey, raw);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
