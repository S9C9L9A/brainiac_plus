import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/extended_settings.dart';
import '../services/extended_settings_storage.dart';

final extendedSettingsStorageProvider = Provider<ExtendedSettingsStorage>(
  (ref) => ExtendedSettingsStorage(),
);

final extendedSettingsProvider =
    StateNotifierProvider<ExtendedSettingsController, ExtendedAppSettings>(
  (ref) => ExtendedSettingsController(ref.read(extendedSettingsStorageProvider)),
);

class ExtendedSettingsController extends StateNotifier<ExtendedAppSettings> {
  ExtendedSettingsController(this._storage) : super(const ExtendedAppSettings()) {
    _load();
  }

  final ExtendedSettingsStorage _storage;
  bool _loaded = false;

  bool get isLoaded => _loaded;

  Future<void> _load() async {
    final stored = await _storage.load();
    if (stored != null) {
      state = stored;
    }
    _loaded = true;
  }

  Future<void> setSettings(ExtendedAppSettings settings) async {
    state = settings;
    await _storage.save(settings);
  }

  Future<void> clear() async {
    state = const ExtendedAppSettings();
    await _storage.clear();
  }
}