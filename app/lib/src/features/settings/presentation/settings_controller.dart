import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/chat_history_storage.dart';
import '../../settings/data/settings_storage.dart';

class SettingsState {
  final String hapticsLevel;
  final String visionPipelineMode;
  final bool isSmartContextEnabled;
  final int maxContextTokens;

  SettingsState({
    required this.hapticsLevel,
    required this.visionPipelineMode,
    required this.isSmartContextEnabled,
    required this.maxContextTokens,
  });

  SettingsState copyWith({
    String? hapticsLevel,
    String? visionPipelineMode,
    bool? isSmartContextEnabled,
    int? maxContextTokens,
  }) {
    return SettingsState(
      hapticsLevel: hapticsLevel ?? this.hapticsLevel,
      visionPipelineMode: visionPipelineMode ?? this.visionPipelineMode,
      isSmartContextEnabled:
          isSmartContextEnabled ?? this.isSmartContextEnabled,
      maxContextTokens: maxContextTokens ?? this.maxContextTokens,
    );
  }
}

class SettingsController extends Notifier<SettingsState> {
  late final SettingsStorage _settingsStorage;
  late final ChatHistoryStorage _chatHistoryStorage;

  @override
  SettingsState build() {
    _settingsStorage = ref.watch(settingsStorageProvider);
    _chatHistoryStorage = ref.watch(chatHistoryStorageProvider);

    return SettingsState(
      hapticsLevel: _settingsStorage.getHapticsLevel(),
      visionPipelineMode: _settingsStorage.getVisionPipelineMode(),
      isSmartContextEnabled: _settingsStorage.getSmartContextEnabled(),
      maxContextTokens: _settingsStorage.getMaxContextTokens(),
    );
  }

  Future<void> setHapticsLevel(String level) async {
    await _settingsStorage.setHapticsLevel(level);
    state = state.copyWith(hapticsLevel: level);
  }

  Future<void> setVisionPipelineMode(String mode) async {
    await _settingsStorage.setVisionPipelineMode(mode);
    state = state.copyWith(visionPipelineMode: mode);
  }

  Future<void> toggleSmartContext(bool enabled) async {
    await _settingsStorage.setSmartContextEnabled(enabled);
    state = state.copyWith(isSmartContextEnabled: enabled);
  }

  Future<void> setMaxContextTokens(int tokens) async {
    await _settingsStorage.setMaxContextTokens(tokens);
    state = state.copyWith(maxContextTokens: tokens);
  }

  Future<void> clearAllData() async {
    await _chatHistoryStorage.clearHistory();
    await _settingsStorage.clearSettings();

    // Refresh state from storage (which should be defaults now)
    state = SettingsState(
      hapticsLevel: _settingsStorage.getHapticsLevel(),
      visionPipelineMode: _settingsStorage.getVisionPipelineMode(),
      isSmartContextEnabled: _settingsStorage.getSmartContextEnabled(),
      maxContextTokens: _settingsStorage.getMaxContextTokens(),
    );
  }
}

final settingsControllerProvider =
    NotifierProvider<SettingsController, SettingsState>(() {
      return SettingsController();
    });
