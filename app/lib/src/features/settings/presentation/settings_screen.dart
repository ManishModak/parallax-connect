import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/haptics_helper.dart';
import '../../../core/storage/chat_archive_storage.dart';
import 'settings_controller.dart';
import 'widgets/about_card.dart';
import 'widgets/clear_history_confirmation_dialog.dart';
import 'widgets/context_slider.dart';
import 'widgets/haptics_selector.dart';
import 'widgets/response_preference_section.dart';
import 'widgets/section_header.dart';
import 'widgets/smart_context_switch.dart';
import 'widgets/vision_option_tile.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _systemPromptController;

  @override
  void initState() {
    super.initState();
    _systemPromptController = TextEditingController(
      text: ref.read(settingsControllerProvider).systemPrompt,
    );
  }

  @override
  void dispose() {
    _systemPromptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
    final hapticsHelper = ref.read(hapticsHelperProvider);
    const presets = [
      'Concise',
      'Formal',
      'Casual',
      'Detailed',
      'Humorous',
      'Neutral',
      'Custom',
    ];

    ref.listen(settingsControllerProvider, (previous, next) {
      if (previous?.systemPrompt != next.systemPrompt &&
          _systemPromptController.text != next.systemPrompt) {
        _systemPromptController.text = next.systemPrompt;
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.secondary),
          onPressed: () {
            hapticsHelper.triggerHaptics();
            context.pop();
          },
        ),
        title: Text(
          'Settings (BETA)',
          style: GoogleFonts.inter(color: AppColors.primary),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionHeader(title: 'App Settings'),
          const SizedBox(height: 16),
          HapticsSelector(
            currentLevel: state.hapticsLevel,
            onLevelSelected: controller.setHapticsLevel,
            onHapticFeedback: hapticsHelper.triggerHaptics,
          ),
          const SizedBox(height: 32),

          const SectionHeader(title: 'Response Preference'),
          const SizedBox(height: 16),
          ResponsePreferenceSection(
            systemPromptController: _systemPromptController,
            presets: presets,
            selectedStyle: state.responseStyle,
            onPresetSelected: controller.setResponseStyle,
            onPromptChanged: controller.setSystemPrompt,
            onHapticFeedback: hapticsHelper.triggerHaptics,
          ),
          const SizedBox(height: 32),

          const SectionHeader(title: 'Vision Pipeline'),
          const SizedBox(height: 8),
          Text(
            'Choose how images/documents are processed',
            style: GoogleFonts.inter(color: AppColors.secondary, fontSize: 14),
          ),
          const SizedBox(height: 16),
          VisionOptionTile(
            title: 'Edge OCR (Recommended)',
            description:
                'Extracts text on-phone. Fastest. Works with all models. Best for standard documents and quick text extraction.',
            techNote: 'Uses Google ML Kit',
            value: 'edge',
            groupValue: state.visionPipelineMode,
            onChanged: (val) {
              if (val == null) return;
              hapticsHelper.triggerHaptics();
              controller.setVisionPipelineMode(val);
            },
          ),
          const SizedBox(height: 12),
          VisionOptionTile(
            title: 'Full Multimodal (Experimental)',
            description:
                'Sends raw image to server. Requires Llama 3.2 Vision. Best for complex diagrams, handwriting, or when OCR fails. Note: Requires server with >16GB VRAM.',
            value: 'multimodal',
            groupValue: state.visionPipelineMode,
            onChanged: (val) {
              if (val == null) return;
              hapticsHelper.triggerHaptics();
              controller.setVisionPipelineMode(val);
            },
          ),
          const SizedBox(height: 32),

          const SectionHeader(title: 'Document Strategy'),
          const SizedBox(height: 16),
          SmartContextSwitch(
            value: state.isSmartContextEnabled,
            onChanged: (val) {
              hapticsHelper.triggerHaptics();
              controller.toggleSmartContext(val);
            },
          ),
          const SizedBox(height: 24),
          ContextSlider(
            value: state.maxContextTokens,
            onChanged: (val) {
              hapticsHelper.triggerHaptics();
              controller.setMaxContextTokens(val.toInt());
            },
          ),
          const SizedBox(height: 32),

          const SectionHeader(title: 'Data & Storage'),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.secondary.withValues(alpha: 0.1),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (dialogContext) => ClearHistoryConfirmationDialog(
                      onClear: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          await ref
                              .read(chatArchiveStorageProvider)
                              .clearAllSessions();
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                'All chat history cleared',
                                style: GoogleFonts.inter(
                                  color: AppColors.primary,
                                ),
                              ),
                              backgroundColor: AppColors.surface,
                            ),
                          );
                        } catch (e) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                'Failed to clear history',
                                style: GoogleFonts.inter(
                                  color: AppColors.error,
                                ),
                              ),
                              backgroundColor: AppColors.surface,
                            ),
                          );
                        }
                      },
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          LucideIcons.trash2,
                          color: AppColors.error,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Clear Chat History',
                              style: GoogleFonts.inter(
                                color: AppColors.error,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Delete all archived chat sessions',
                              style: GoogleFonts.inter(
                                color: AppColors.secondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        LucideIcons.chevronRight,
                        color: AppColors.secondary.withValues(alpha: 0.5),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          const SectionHeader(title: 'About Parallax Connect'),
          const SizedBox(height: 16),
          const AboutCard(),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'v1.0',
              style: GoogleFonts.inter(
                color: AppColors.secondary.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
