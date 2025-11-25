import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';

class ResponsePreferenceSection extends StatelessWidget {
  final TextEditingController systemPromptController;
  final List<String> presets;
  final String selectedStyle;
  final ValueChanged<String> onPresetSelected;
  final ValueChanged<String> onPromptChanged;
  final VoidCallback? onHapticFeedback;

  const ResponsePreferenceSection({
    super.key,
    required this.systemPromptController,
    required this.presets,
    required this.selectedStyle,
    required this.onPresetSelected,
    required this.onPromptChanged,
    this.onHapticFeedback,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: systemPromptController,
            maxLines: 4,
            style: GoogleFonts.inter(
              color: AppColors.primary,
              fontSize: 14,
              height: 1.5,
            ),
            decoration: InputDecoration(
              hintText: 'Enter system instructions...',
              hintStyle: GoogleFonts.inter(
                color: AppColors.secondary.withValues(alpha: 0.5),
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: onPromptChanged,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: presets.map((preset) {
              final isSelected = selectedStyle == preset;
              return ChoiceChip(
                label: Text(
                  preset,
                  style: GoogleFonts.inter(
                    color: isSelected ? AppColors.background : AppColors.primary,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  if (!selected) return;
                  onHapticFeedback?.call();
                  onPresetSelected(preset);
                },
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.secondary.withValues(alpha: 0.2),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

