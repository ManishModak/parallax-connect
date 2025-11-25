import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';

class HapticsSelector extends StatelessWidget {
  final String currentLevel;
  final ValueChanged<String> onLevelSelected;
  final VoidCallback? onHapticFeedback;

  const HapticsSelector({
    super.key,
    required this.currentLevel,
    required this.onLevelSelected,
    this.onHapticFeedback,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          _HapticOption(
            label: 'None',
            value: 'none',
            icon: LucideIcons.smartphone,
            isSelected: currentLevel == 'none',
            onTap: _handleSelection,
          ),
          _divider(),
          _HapticOption(
            label: 'Min',
            value: 'min',
            icon: LucideIcons.vibrate,
            isSelected: currentLevel == 'min',
            onTap: _handleSelection,
          ),
          _divider(),
          _HapticOption(
            label: 'Max',
            value: 'max',
            icon: LucideIcons.waves,
            isSelected: currentLevel == 'max',
            onTap: _handleSelection,
          ),
        ],
      ),
    );
  }

  Widget _divider() =>
      Container(width: 1, color: AppColors.secondary.withValues(alpha: 0.1));

  void _handleSelection(String value) {
    if (value == currentLevel) return;
    onHapticFeedback?.call();
    onLevelSelected(value);
  }
}

class _HapticOption extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isSelected;
  final ValueChanged<String> onTap;

  const _HapticOption({
    required this.label,
    required this.value,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(value),
        child: Container(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? AppColors.primary : AppColors.secondary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: isSelected ? AppColors.primary : AppColors.secondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

