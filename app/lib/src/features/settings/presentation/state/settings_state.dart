class SettingsState {
  final String hapticsLevel;
  final String visionPipelineMode;
  final bool isSmartContextEnabled;
  final int maxContextTokens;
  final String systemPrompt;
  final String responseStyle;

  SettingsState({
    required this.hapticsLevel,
    required this.visionPipelineMode,
    required this.isSmartContextEnabled,
    required this.maxContextTokens,
    required this.systemPrompt,
    required this.responseStyle,
  });

  SettingsState copyWith({
    String? hapticsLevel,
    String? visionPipelineMode,
    bool? isSmartContextEnabled,
    int? maxContextTokens,
    String? systemPrompt,
    String? responseStyle,
  }) {
    return SettingsState(
      hapticsLevel: hapticsLevel ?? this.hapticsLevel,
      visionPipelineMode: visionPipelineMode ?? this.visionPipelineMode,
      isSmartContextEnabled:
          isSmartContextEnabled ?? this.isSmartContextEnabled,
      maxContextTokens: maxContextTokens ?? this.maxContextTokens,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      responseStyle: responseStyle ?? this.responseStyle,
    );
  }
}

