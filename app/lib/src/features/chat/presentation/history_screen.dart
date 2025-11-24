import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import 'chat_controller.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.x, color: AppColors.secondary),
          onPressed: () => context.pop(),
        ),
        title: SvgPicture.asset(
          'assets/images/logo.svg',
          width: 32,
          height: 32,
          colorFilter: const ColorFilter.mode(
            AppColors.primary,
            BlendMode.srcIn,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.settings, color: AppColors.secondary),
            onPressed: () => context.push(AppRoutes.config),
          ),
        ],
      ),
      body: Column(
        children: [
          // New Chat Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  ref.read(chatControllerProvider.notifier).startNewChat();
                  context.pop();
                },
                icon: const Icon(LucideIcons.plus, size: 20),
                label: Text(
                  'New Chat',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.background,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ),

          // Recent Chats List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Text(
                  'Recent',
                  style: GoogleFonts.inter(
                    color: AppColors.secondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildHistoryItem(
                  context,
                  'Project Planning',
                  '2 mins ago',
                  true,
                ),
                _buildHistoryItem(
                  context,
                  'Flutter Architecture',
                  '1 hour ago',
                  false,
                ),
                _buildHistoryItem(context, 'Dart Streams', 'Yesterday', false),
                _buildHistoryItem(
                  context,
                  'AI Integration',
                  '2 days ago',
                  false,
                ),
                _buildHistoryItem(context, 'UI Design', '3 days ago', false),
              ],
            ),
          ),

          // Footer
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Parallax Connect v1.0',
              style: GoogleFonts.inter(
                color: AppColors.secondary.withOpacity(0.5),
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(
    BuildContext context,
    String title,
    String time,
    bool isActive,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isActive ? AppColors.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isActive
            ? Border.all(color: AppColors.accent.withOpacity(0.2))
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(
          LucideIcons.messageSquare,
          size: 18,
          color: isActive ? AppColors.primary : AppColors.secondary,
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(
            color: isActive ? AppColors.primary : AppColors.secondary,
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          time,
          style: GoogleFonts.inter(
            color: AppColors.secondary.withOpacity(0.7),
            fontSize: 10,
          ),
        ),
        onTap: () {
          // TODO: Load this chat session
          context.pop();
        },
      ),
    );
  }
}
