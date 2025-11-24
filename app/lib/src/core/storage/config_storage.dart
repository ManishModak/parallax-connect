import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConfigStorage {
  static const _keyBaseUrl = 'base_url';
  static const _keyIsLocal = 'is_local';
  static const _keyPassword = 'password';

  final SharedPreferences _prefs;

  ConfigStorage(this._prefs);

  Future<void> saveConfig({
    required String baseUrl,
    required bool isLocal,
    String? password,
  }) async {
    await _prefs.setString(_keyBaseUrl, baseUrl);
    await _prefs.setBool(_keyIsLocal, isLocal);
    if (password != null && password.isNotEmpty) {
      await _prefs.setString(_keyPassword, password);
    } else {
      await _prefs.remove(_keyPassword);
    }
  }

  String? getBaseUrl() {
    return _prefs.getString(_keyBaseUrl);
  }

  bool getIsLocal() {
    return _prefs.getBool(_keyIsLocal) ?? false;
  }

  String? getPassword() {
    return _prefs.getString(_keyPassword);
  }

  bool hasConfig() {
    return _prefs.containsKey(_keyBaseUrl);
  }
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

final configStorageProvider = Provider<ConfigStorage>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ConfigStorage(prefs);
});
