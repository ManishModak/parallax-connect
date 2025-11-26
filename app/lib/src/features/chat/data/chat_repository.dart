import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/networking/dio_provider.dart';
import '../../../core/storage/config_storage.dart';
import '../../../core/utils/logger.dart';
import 'models/chat_message.dart';

class ChatRepository {
  final Dio _dio;
  final ConfigStorage _configStorage;

  ChatRepository(this._dio, this._configStorage);

  Map<String, String>? _buildPasswordHeader() {
    final password = _configStorage.getPassword();
    if (password == null || password.isEmpty) {
      return null;
    }
    return {'x-password': password};
  }

  /// Test connection to the server
  Future<bool> testConnection() async {
    final baseUrl = _configStorage.getBaseUrl();
    if (baseUrl == null) return false;

    try {
      final response = await _dio.get(
        '$baseUrl/',
        options: Options(
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
          headers: _buildPasswordHeader(),
        ),
      );

      return response.statusCode == 200 && response.data['status'] == 'online';
    } catch (e) {
      logger.e('Connection test failed', error: e);
      return false;
    }
  }

  /// Generate text response from AI
  ///
  /// [prompt] - The current user message
  /// [systemPrompt] - Optional system instructions
  /// [history] - Optional conversation history for multi-turn chat
  Future<String> generateText(
    String prompt, {
    String? systemPrompt,
    List<ChatMessage>? history,
  }) async {
    final baseUrl = _configStorage.getBaseUrl();
    if (baseUrl == null) throw Exception('No Base URL configured');

    try {
      final data = <String, dynamic>{'prompt': prompt};

      if (systemPrompt != null && systemPrompt.isNotEmpty) {
        data['system_prompt'] = systemPrompt;
      }

      // Include conversation history for multi-turn chat
      if (history != null && history.isNotEmpty) {
        data['messages'] = [
          ...history.map(
            (m) => {
              'role': m.isUser ? 'user' : 'assistant',
              'content': m.text,
            },
          ),
          // Add current prompt as the last user message
          {'role': 'user', 'content': prompt},
        ];
      }

      final response = await _dio.post(
        '$baseUrl/chat',
        data: data,
        options: Options(headers: _buildPasswordHeader()),
      );

      return response.data['response'] as String;
    } catch (e) {
      logger.e('Error generating text', error: e);
      rethrow;
    }
  }

  Future<String> analyzeImage(String prompt, String imageBase64) async {
    final baseUrl = _configStorage.getBaseUrl();
    if (baseUrl == null) throw Exception('No Base URL configured');

    try {
      final response = await _dio.post(
        '$baseUrl/vision',
        data: {'prompt': prompt, 'image': imageBase64},
        options: Options(headers: _buildPasswordHeader()),
      );

      return response.data['response'] as String;
    } catch (e) {
      logger.e('Error analyzing image', error: e);
      rethrow;
    }
  }
}

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final configStorage = ref.watch(configStorageProvider);
  return ChatRepository(dio, configStorage);
});
