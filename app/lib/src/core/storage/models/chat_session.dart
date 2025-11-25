class ChatSession {
  final String id;
  final String title;
  final List<Map<String, dynamic>> messages;
  final DateTime timestamp;
  final int messageCount;

  const ChatSession({
    required this.id,
    required this.title,
    required this.messages,
    required this.timestamp,
    required this.messageCount,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'messages': messages,
      'timestamp': timestamp.toIso8601String(),
      'messageCount': messageCount,
    };
  }

  factory ChatSession.fromMap(Map<String, dynamic> map) {
    return ChatSession(
      id: map['id'] as String,
      title: map['title'] as String,
      messages: List<Map<String, dynamic>>.from(
        (map['messages'] as List).map(
          (e) => Map<String, dynamic>.from(e as Map),
        ),
      ),
      timestamp: DateTime.parse(map['timestamp'] as String),
      messageCount: map['messageCount'] as int,
    );
  }
}

