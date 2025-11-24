import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../chat_controller.dart';

class ChatDrawer extends ConsumerWidget {
  const ChatDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      backgroundColor: AppColors.background,
      child: Column(
        children: [
          // Header / New Chat
          Container(
            padding: const EdgeInsets.fromLTRB(16, 60, 16, 20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.secondary.withOpacity(0.2)),
              ),
            ),
            child: Column(
              children: [
                SvgPicture.asset(
                  'assets/images/logo.svg',
                  width: 40,
                  height: 40,
                  colorFilter: const ColorFilter.mode(
                    AppColors.primary,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ref.read(chatControllerProvider.notifier).startNewChat();
                      Navigator.pop(context); // Close drawer
                    },
                    icon: const Icon(LucideIcons.plus, size: 20),
                    label: Text(
                      'New Chat',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.background,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // History List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Recent Chats',
                  style: GoogleFonts.inter(
                    color: AppColors.secondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                // Placeholder for history items
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
              ],
            ),
          ),

          // Footer
          Padding(
            padding: const EdgeInsets.all(16),
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
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
          Navigator.pop(context);
        },
      ),
    );
  }
}
