import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/storage/config_storage.dart';

class SettingsStorage {
  static const _keyHapticsLevel = 'settings_haptics_level';
  static const _keyVisionPipelineMode = 'settings_vision_pipeline_mode';
  static const _keySmartContextEnabled = 'settings_smart_context_enabled';
  static const _keyMaxContextTokens = 'settings_max_context_tokens';
  static const _keySystemPrompt = 'settings_system_prompt';
  static const _keyResponseStyle = 'settings_response_style';

  final SharedPreferences _prefs;

  SettingsStorage(this._prefs);

  // Haptics Level
  // Values: 'none', 'min', 'max'
  Future<void> setHapticsLevel(String level) async {
    await _prefs.setString(_keyHapticsLevel, level);
  }

  String getHapticsLevel() {
    return _prefs.getString(_keyHapticsLevel) ?? 'min';
  }

  // Vision Pipeline Mode
  // Values: 'edge', 'multimodal'
  // TODO: Vision Pipeline integration - currently settings are stored but not used by the chat/vision processing pipeline
  Future<void> setVisionPipelineMode(String mode) async {
    await _prefs.setString(_keyVisionPipelineMode, mode);
  }

  /// Get vision pipeline mode
  /// TODO: Vision Pipeline integration - currently settings are stored but not used by the chat/vision processing pipeline
  String getVisionPipelineMode() {
    return _prefs.getString(_keyVisionPipelineMode) ?? 'edge';
  }

  // Smart Context Window
  // TODO: Document Strategy integration - Smart Context and Max Context settings need to be integrated with PDF/document processing
  Future<void> setSmartContextEnabled(bool enabled) async {
    await _prefs.setBool(_keySmartContextEnabled, enabled);
  }

  /// Get smart context enabled
  /// TODO: Document Strategy integration - Smart Context and Max Context settings need to be integrated with PDF/document processing
  bool getSmartContextEnabled() {
    return _prefs.getBool(_keySmartContextEnabled) ?? true;
  }

  // Max Context Injection
  // TODO: Document Strategy integration - Smart Context and Max Context settings need to be integrated with PDF/document processing
  Future<void> setMaxContextTokens(int tokens) async {
    await _prefs.setInt(_keyMaxContextTokens, tokens);
  }

  /// Get max context tokens
  /// TODO: Document Strategy integration - Smart Context and Max Context settings need to be integrated with PDF/document processing
  int getMaxContextTokens() {
    return _prefs.getInt(_keyMaxContextTokens) ?? 4096;
  }

  // System Prompt
  Future<void> setSystemPrompt(String prompt) async {
    await _prefs.setString(_keySystemPrompt, prompt);
  }

  String getSystemPrompt() {
    return _prefs.getString(_keySystemPrompt) ?? '';
  }

  // Response Style
  // Values: 'Concise', 'Formal', 'Casual', 'Detailed', 'Humorous', 'Neutral', 'Custom'
  Future<void> setResponseStyle(String style) async {
    await _prefs.setString(_keyResponseStyle, style);
  }

  String getResponseStyle() {
    return _prefs.getString(_keyResponseStyle) ?? 'Neutral';
  }

  // Clear all settings (reset to defaults)
  Future<void> clearSettings() async {
    await _prefs.remove(_keyHapticsLevel);
    await _prefs.remove(_keyVisionPipelineMode);
    await _prefs.remove(_keySmartContextEnabled);
    await _prefs.remove(_keyMaxContextTokens);
    await _prefs.remove(_keySystemPrompt);
    await _prefs.remove(_keyResponseStyle);
  }
}

final settingsStorageProvider = Provider<SettingsStorage>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SettingsStorage(prefs);
});
