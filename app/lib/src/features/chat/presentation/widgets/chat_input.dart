import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/file_service.dart';

class ChatInput extends ConsumerStatefulWidget {
  final Function(String, String?) onSubmitted;
  final bool isLoading;

  const ChatInput({
    super.key,
    required this.onSubmitted,
    this.isLoading = false,
  });

  @override
  ConsumerState<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends ConsumerState<ChatInput> {
  final _controller = TextEditingController();
  File? _selectedImage;

  void _handleSubmit() {
    if ((_controller.text.trim().isEmpty && _selectedImage == null) ||
        widget.isLoading)
      return;

    widget.onSubmitted(_controller.text, _selectedImage?.path);
    _controller.clear();
    setState(() => _selectedImage = null);
  }

  Future<void> _pickImage() async {
    final fileService = ref.read(fileServiceProvider);
    final image = await fileService.pickImage();
    if (image != null) {
      setState(() => _selectedImage = image);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: const BoxDecoration(
        color: AppColors.background,
        // No top border for cleaner look
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_selectedImage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12, left: 4),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _selectedImage!,
                      height: 80,
                      width: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedImage = null),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.x,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.accent.withOpacity(0.3)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: _pickImage,
                  icon: const Icon(LucideIcons.plus),
                  color: AppColors.secondary,
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: GoogleFonts.inter(
                      color: AppColors.primary,
                      fontSize: 15,
                    ),
                    maxLines: 5,
                    minLines: 1,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _handleSubmit(),
                    decoration: InputDecoration(
                      hintText: 'Ask anything...',
                      hintStyle: GoogleFonts.inter(
                        color: AppColors.secondary.withOpacity(0.7),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 10,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _handleSubmit,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 4, right: 4),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.isLoading
                          ? AppColors.surface
                          : AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: widget.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.secondary,
                            ),
                          )
                        : const Icon(
                            LucideIcons.arrowUp,
                            color: AppColors.background,
                            size: 20,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
