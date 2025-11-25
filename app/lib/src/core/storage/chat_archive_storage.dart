import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../utils/logger.dart';
import 'models/chat_session.dart';

export 'models/chat_session.dart';

/// Storage service for archived chat sessions
class ChatArchiveStorage {
  static const String boxName = 'chat_archives';
  static const _uuid = Uuid();

  final Box _box;

  ChatArchiveStorage(this._box);

  static Future<void> init() async {
    await Hive.openBox(boxName);
    logger.storage('Chat archive storage initialized');
  }

  /// Archive the current chat session
  Future<String> archiveSession({
    required List<Map<String, dynamic>> messages,
    String? customTitle,
  }) async {
    try {
      if (messages.isEmpty) {
        logger.w('Attempted to archive empty session');
        throw ArgumentError('Cannot archive empty session');
      }

      // Generate session title from first user message or use timestamp
      final title = customTitle ?? _generateSessionTitle(messages);
      final sessionId = _uuid.v4();

      final session = ChatSession(
        id: sessionId,
        title: title,
        messages: messages,
        timestamp: DateTime.now(),
        messageCount: messages.length,
      );

      await _box.put(sessionId, session.toMap());
      logger.storage('Session archived: $title ($sessionId)');

      return sessionId;
    } catch (e) {
      logger.e('Failed to archive session: $e');
      rethrow;
    }
  }

  /// Get all archived sessions, sorted by timestamp (newest first)
  List<ChatSession> getArchivedSessions() {
    try {
      final sessions = _box.values
          .map(
            (item) =>
                ChatSession.fromMap(Map<String, dynamic>.from(item as Map)),
          )
          .toList();

      // Sort by timestamp, newest first
      sessions.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      logger.storage('Retrieved ${sessions.length} archived sessions');
      return sessions;
    } catch (e) {
      logger.e('Failed to get archived sessions: $e');
      return [];
    }
  }

  /// Get a specific session by ID
  ChatSession? getSessionById(String sessionId) {
    try {
      final data = _box.get(sessionId);
      if (data == null) return null;

      return ChatSession.fromMap(Map<String, dynamic>.from(data as Map));
    } catch (e) {
      logger.e('Failed to get session by ID: $e');
      return null;
    }
  }

  /// Delete an archived session
  Future<void> deleteSession(String sessionId) async {
    try {
      await _box.delete(sessionId);
      logger.storage('Deleted archived session: $sessionId');
    } catch (e) {
      logger.e('Failed to delete session: $e');
      rethrow;
    }
  }

  /// Search sessions by title or content
  List<ChatSession> searchSessions(String query) {
    try {
      if (query.trim().isEmpty) {
        return getArchivedSessions();
      }

      final lowerQuery = query.toLowerCase();
      final sessions = _box.values
          .map(
            (item) =>
                ChatSession.fromMap(Map<String, dynamic>.from(item as Map)),
          )
          .where((session) {
            // Search in title
            if (session.title.toLowerCase().contains(lowerQuery)) {
              return true;
            }

            // Search in message content
            for (final message in session.messages) {
              final content = (message['text'] as String? ?? '').toLowerCase();
              if (content.contains(lowerQuery)) {
                return true;
              }
            }

            return false;
          })
          .toList();

      // Sort by timestamp, newest first
      sessions.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      logger.storage('Found ${sessions.length} sessions for query: $query');
      return sessions;
    } catch (e) {
      logger.e('Failed to search sessions: $e');
      return [];
    }
  }

  /// Get count of archived sessions
  int getSessionCount() {
    return _box.length;
  }

  /// Clear all archived sessions
  Future<void> clearAllArchives() async {
    try {
      await _box.clear();
      logger.storage('All archived sessions cleared');
    } catch (e) {
      logger.e('Failed to clear archives: $e');
      rethrow;
    }
  }

  /// Generate a session title from messages
  String _generateSessionTitle(List<Map<String, dynamic>> messages) {
    // Find first user message
    final firstUserMessage = messages.firstWhere(
      (msg) => msg['isUser'] == true,
      orElse: () => {},
    );

    if (firstUserMessage.isNotEmpty) {
      final text = firstUserMessage['text'] as String;
      // Use first 50 characters or first line, whichever is shorter
      final firstLine = text.split('\n').first;
      final truncated = firstLine.length > 50
          ? '${firstLine.substring(0, 50)}...'
          : firstLine;
      return truncated;
    }

    // Fallback to timestamp-based title
    final now = DateTime.now();
    return 'Chat ${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }
}

final chatArchiveStorageProvider = Provider<ChatArchiveStorage>((ref) {
  final box = Hive.box(ChatArchiveStorage.boxName);
  return ChatArchiveStorage(box);
});
