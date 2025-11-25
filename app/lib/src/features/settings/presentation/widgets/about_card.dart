import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';

class AboutCard extends StatelessWidget {
  const AboutCard({super.key});

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
          Text(
            'Parallax Connect is designed to run on Commodity Edge Hardware. We optimized the app so that any standard smartphone from the last 4 years can act as an intelligent input node. We utilize the Neural Engine (NPU) found in modern mobile chipsets to handle the vision pipeline, ensuring the heavy GPU on the server is reserved strictly for reasoning.',
            style: GoogleFonts.inter(
              color: AppColors.secondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          const _RequirementSection(
            title: 'Client Requirements:',
            items: [
              'Android 10+ / iOS 14+ (Recommended)',
              '4GB RAM minimum, 6GB+ recommended',
              '12MP camera with autofocus for OCR',
            ],
          ),
          const SizedBox(height: 12),
          const _RequirementSection(
            title: 'Server Requirements:',
            items: [
              'Parallax-compatible node (Tested on RTX 4060)',
            ],
          ),
        ],
      ),
    );
  }
}

class _RequirementSection extends StatelessWidget {
  final String title;
  final List<String> items;

  const _RequirementSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            color: AppColors.primaryMildVariant,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 4),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(left: 8, top: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item,
                    style: GoogleFonts.inter(
                      color: AppColors.secondary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

