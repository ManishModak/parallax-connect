import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ChatHistoryStorage {
  static const _boxName = 'chat_history';

  final Box _box;

  ChatHistoryStorage(this._box);

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_boxName);
  }

  Future<void> saveMessage(Map<String, dynamic> message) async {
    await _box.add(message);
  }

  List<Map<String, dynamic>> getHistory() {
    // Fix type casting issue - explicitly convert each item
    return _box.values
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<void> clearHistory() async {
    await _box.clear();
  }
}

final chatHistoryStorageProvider = Provider<ChatHistoryStorage>((ref) {
  final box = Hive.box('chat_history');
  return ChatHistoryStorage(box);
});
