import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';

/// Service for interacting with Ollama API
class OllamaService {
  final Dio _dio;
  final String baseUrl;
  final String model;

  OllamaService({
    String? baseUrl,
    String? model,
  })  : baseUrl = _normalizeBaseUrl(baseUrl ?? 'http://localhost:11434'),
        model = model ?? 'qwen2.5-coder:14b',
        _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 120),
        ));

  static String _normalizeBaseUrl(String value) {
    var trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'http://localhost:11434';
    }
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      trimmed = 'http://$trimmed';
    }
    trimmed = trimmed.replaceAll(RegExp(r'/+$'), '');
    return trimmed.replaceAll(RegExp(r'/api/?$'), '');
  }

  bool _isNotFound(DioException e) => e.response?.statusCode == 404;

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
    } on DioException catch (e) {
      if (_isNotFound(e)) {
        throw OllamaException(
          'Ollama endpoint not found at $baseUrl/api/generate. '
          'Verify the base URL and that the Ollama server is running.',
        );
      }
      if (e.error is SocketException) {
        throw OllamaException(
          'Cannot reach Ollama at $baseUrl. Is the server running?',
        );
      }
      throw OllamaException('Failed to generate code: $e');
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
    } on DioException catch (e) {
      if (_isNotFound(e)) {
        try {
          return await _generateFromMessages(messages, temperature: temperature);
        } catch (fallbackError) {
          throw OllamaException(
            'Ollama chat endpoint not available. Check base URL and server. '
            'Fallback failed: $fallbackError',
          );
        }
      }
      if (e.error is SocketException) {
        throw OllamaException(
          'Cannot reach Ollama at $baseUrl. Is the server running?',
        );
      }
      throw OllamaException('Failed to chat: $e');
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
    } on DioException catch (e) {
      if (_isNotFound(e)) {
        try {
          final fallback = await _generateFromMessages(messages, temperature: temperature);
          yield fallback;
          return;
        } catch (fallbackError) {
          throw OllamaException(
            'Ollama chat stream endpoint not available. '
            'Check base URL and server. Fallback failed: $fallbackError',
          );
        }
      }
      if (e.error is SocketException) {
        throw OllamaException(
          'Cannot reach Ollama at $baseUrl. Is the server running?',
        );
      }
      throw OllamaException('Failed to stream chat: $e');
    } catch (e) {
      throw OllamaException('Failed to stream chat: $e');
    }
  }

  Future<String> _generateFromMessages(
    List<ChatMessage> messages, {
    double temperature = 0.7,
  }) async {
    final prompt = _buildPromptFromMessages(messages);
    return generateCode(prompt, temperature: temperature);
  }

  String _buildPromptFromMessages(List<ChatMessage> messages) {
    final buffer = StringBuffer();
    for (final message in messages) {
      buffer.writeln('${message.role.toUpperCase()}: ${message.content}');
    }
    buffer.writeln('ASSISTANT:');
    return buffer.toString();
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

  /// List available models with detailed info
  Future<List<OllamaModel>> listModelsDetailed() async {
    try {
      final response = await _dio.get('$baseUrl/api/tags');
      final models = response.data['models'] as List;
      return models
          .map((m) => OllamaModel.fromJson(m as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw OllamaException('Failed to list models: $e');
    }
  }
}

/// Model info from Ollama
class OllamaModel {
  final String name;
  final int sizeBytes;
  final DateTime modifiedAt;
  final String? digest;

  OllamaModel({
    required this.name,
    required this.sizeBytes,
    required this.modifiedAt,
    this.digest,
  });

  /// Get human readable size
  String get sizeFormatted {
    const kb = 1024;
    const mb = kb * 1024;
    const gb = mb * 1024;

    if (sizeBytes >= gb) {
      return '${(sizeBytes / gb).toStringAsFixed(2)} GB';
    } else if (sizeBytes >= mb) {
      return '${(sizeBytes / mb).toStringAsFixed(2)} MB';
    } else if (sizeBytes >= kb) {
      return '${(sizeBytes / kb).toStringAsFixed(2)} KB';
    } else {
      return '$sizeBytes B';
    }
  }

  /// Get size in MB
  int get sizeMB => (sizeBytes / (1024 * 1024)).round();

  factory OllamaModel.fromJson(Map<String, dynamic> json) {
    return OllamaModel(
      name: json['name'] as String,
      sizeBytes: json['size'] as int? ?? 0,
      modifiedAt: DateTime.tryParse(json['modified_at'] as String? ?? '') ??
          DateTime.now(),
      digest: json['digest'] as String?,
    );
  }

  @override
  String toString() => '$name (${sizeFormatted})';
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