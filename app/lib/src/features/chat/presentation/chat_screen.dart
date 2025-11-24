import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import 'chat_controller.dart';
import 'widgets/chat_message_bubble.dart';
import 'widgets/chat_input_area.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatControllerProvider);
    final chatController = ref.read(chatControllerProvider.notifier);

    // Auto-scroll to bottom when new messages arrive
    ref.listen(chatControllerProvider, (previous, next) {
      if (next.messages.length > (previous?.messages.length ?? 0)) {
        Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset(
            'assets/icons/drawer.svg',
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(AppColors.secondary, BlendMode.srcIn),
          ),
          onPressed: () => context.push(AppRoutes.history),
        ),
        title: Text(
          'Parallax Connect',
          style: GoogleFonts.inter(
            color: AppColors.primaryMildVariant,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: SvgPicture.asset(
              'assets/icons/new_chat.svg',
              width: 22,
              height: 22,
              colorFilter: ColorFilter.mode(
                AppColors.secondary,
                BlendMode.srcIn,
              ),
            ),
            tooltip: 'Start New Chat',
            onPressed: () => chatController.startNewChat(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: chatState.messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          LucideIcons.messageSquare,
                          size: 48,
                          color: AppColors.accent,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Start a conversation',
                          style: GoogleFonts.inter(
                            color: AppColors.secondary,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final message = chatState.messages[index];
                            return ChatMessageBubble(message: message);
                          }, childCount: chatState.messages.length),
                        ),
                      ),
                      if (chatState.isLoading)
                        const SliverToBoxAdapter(
                          child: ChatMessageBubble(isShimmer: true),
                        ),
                    ],
                  ),
          ),
          if (chatState.error != null)
            Container(
              padding: const EdgeInsets.all(8),
              color: AppColors.error.withOpacity(0.1),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.alertCircle,
                    color: AppColors.error,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      chatState.error!,
                      style: GoogleFonts.inter(
                        color: AppColors.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ChatInputArea(
            isLoading: chatState.isLoading,
            onSubmitted: (text, attachmentPaths) {
              ref
                  .read(chatControllerProvider.notifier)
                  .sendMessage(text, attachmentPaths: attachmentPaths);
            },
            onCameraTap: () async {
              final picker = ImagePicker();
              final XFile? image = await picker.pickImage(
                source: ImageSource.camera,
              );
              return image?.path;
            },
            onGalleryTap: () async {
              final picker = ImagePicker();
              final List<XFile> images = await picker.pickMultipleMedia();
              return images.map((img) => img.path).toList();
            },
            onFileTap: () async {
              final result = await FilePicker.platform.pickFiles(
                allowMultiple: true,
              );
              if (result != null) {
                return result.files
                    .where((file) => file.path != null)
                    .map((file) => file.path!)
                    .toList();
              }
              return [];
            },
          ),
        ],
      ),
    );
  }
}
