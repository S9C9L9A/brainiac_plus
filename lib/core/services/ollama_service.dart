import 'dart:convert';
import 'package:dio/dio.dart';

/// Service for interacting with Ollama API
class OllamaService {
  final Dio _dio;
  final String baseUrl;
  final String model;

  OllamaService({
    String? baseUrl,
    String? model,
  })  : baseUrl = baseUrl ?? 'http://localhost:11434',
        model = model ?? 'codellama:7b',
        _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 120),
        ));

  /// Generate code from a prompt (non-streaming)
  Future<String> generateCode(String prompt, {
    double temperature = 0.7,
    int maxTokens = 2000,
  }) async {
    try {
      final response = await _dio.post(
        '$baseUrl/api/generate',
        data: {
          'model': model,
          'prompt': prompt,
          'stream': false,
          'options': {
            'temperature': temperature,
            'num_predict': maxTokens,
          },
        },
      );

      return response.data['response'] as String;
    } catch (e) {
      throw OllamaException('Failed to generate code: $e');
    }
  }

  /// Chat completion (non-streaming)
  Future<String> chat(List<ChatMessage> messages, {
    double temperature = 0.7,
  }) async {
    try {
      final response = await _dio.post(
        '$baseUrl/api/chat',
        data: {
          'model': model,
          'messages': messages.map((m) => m.toJson()).toList(),
          'stream': false,
          'options': {
            'temperature': temperature,
          },
        },
      );

      final data = response.data;
      if (data is! Map || data['message'] == null || data['message']['content'] == null) {
        throw OllamaException('Invalid response format from Ollama chat API');
      }
      return data['message']['content'] as String;
    } catch (e) {
      throw OllamaException('Failed to chat: $e');
    }
  }

  /// Stream chat completion
  Stream<String> chatStream(List<ChatMessage> messages, {
    double temperature = 0.7,
  }) async* {
    try {
      final response = await _dio.post(
        '$baseUrl/api/chat',
        data: {
          'model': model,
          'messages': messages.map((m) => m.toJson()).toList(),
          'stream': true,
          'options': {
            'temperature': temperature,
          },
        },
        options: Options(
          responseType: ResponseType.stream,
        ),
      );

      final stream = response.data.stream;
      await for (final chunk in stream) {
        final lines = utf8.decode(chunk).split('\n');
        for (final line in lines) {
          if (line.trim().isEmpty) continue;
          try {
            final json = jsonDecode(line);
            if (json['message']?['content'] != null) {
              yield json['message']['content'] as String;
            }
          } catch (_) {
            // Skip malformed JSON
          }
        }
      }
    } catch (e) {
      throw OllamaException('Failed to stream chat: $e');
    }
  }

  /// Check if Ollama is available
  Future<bool> isAvailable() async {
    try {
      final response = await _dio.get('$baseUrl/api/version');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// List available models
  Future<List<String>> listModels() async {
    try {
      final response = await _dio.get('$baseUrl/api/tags');
      final models = response.data['models'] as List;
      return models.map((m) => m['name'] as String).toList();
    } catch (e) {
      throw OllamaException('Failed to list models: $e');
    }
  }
}

/// Chat message model for Ollama API
class ChatMessage {
  final String role; // 'system', 'user', 'assistant'
  final String content;

  ChatMessage({
    required this.role,
    required this.content,
  });

  Map<String, dynamic> toJson() => {
        'role': role,
        'content': content,
      };

  factory ChatMessage.system(String content) => ChatMessage(
        role: 'system',
        content: content,
      );

  factory ChatMessage.user(String content) => ChatMessage(
        role: 'user',
        content: content,
      );

  factory ChatMessage.assistant(String content) => ChatMessage(
        role: 'assistant',
        content: content,
      );
}

/// Custom exception for Ollama errors
class OllamaException implements Exception {
  final String message;
  OllamaException(this.message);

  @override
  String toString() => 'OllamaException: $message';
}
