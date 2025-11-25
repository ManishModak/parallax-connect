import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/data/settings_storage.dart';

/// Helper class to trigger haptic feedback based on user settings
class HapticsHelper {
  final SettingsStorage _settingsStorage;

  HapticsHelper(this._settingsStorage);

  /// Trigger haptic feedback based on current settings level
  /// - 'none': No haptic feedback
  /// - 'min': Light haptic feedback on button/icon clicks
  /// - 'max': Reserved for future implementation
  Future<void> triggerHaptics() async {
    final level = _settingsStorage.getHapticsLevel();

    switch (level) {
      case 'none':
        // No haptic feedback
        break;
      case 'min':
        // Light haptic feedback for button/icon clicks
        await HapticFeedback.lightImpact();
        break;
      case 'max':
        // Stronger haptic feedback for critical interactions
        await HapticFeedback.heavyImpact();
        break;
    }
  }
}

/// Provider for HapticsHelper
final hapticsHelperProvider = Provider<HapticsHelper>((ref) {
  final settingsStorage = ref.watch(settingsStorageProvider);
  return HapticsHelper(settingsStorage);
});
