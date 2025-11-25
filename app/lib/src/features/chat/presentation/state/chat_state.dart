import '../../data/models/chat_message.dart';

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;
  final bool isPrivateMode;

  ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.isPrivateMode = false,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
    bool? isPrivateMode,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isPrivateMode: isPrivateMode ?? this.isPrivateMode,
    );
  }
}

