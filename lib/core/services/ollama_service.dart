import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';

/// Service for interacting with an OpenAI-compatible local LLM server.
///
/// Despite the historical name, this talks the OpenAI Chat Completions API
/// (`/v1/chat/completions`, `/v1/models`), NOT Ollama's native `/api/*`
/// protocol. This one code path works against:
///   - llama.cpp server (`--host ... /v1`) — the default local backend
///   - LiteLLM proxy
///   - Ollama's own OpenAI-compatible endpoint (`/v1`)
///
/// The base URL is configurable (settings / Android LAN IP). Default points at
/// the local llama.cpp container on :8080.
class OllamaService {
  final Dio _dio;
  final String baseUrl;
  final String model;

  OllamaService({String? baseUrl, String? model})
    : baseUrl = _normalizeBaseUrl(baseUrl ?? 'http://localhost:8080'),
      model = (model == null || model.trim().isEmpty) ? 'local-model' : model,
      _dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 120),
        ),
      );

  static String _normalizeBaseUrl(String value) {
    var trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'http://localhost:8080';
    }
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      trimmed = 'http://$trimmed';
    }
    trimmed = trimmed.replaceAll(RegExp(r'/+$'), '');
    // Accept URLs typed with or without an /v1 or /api suffix.
    trimmed = trimmed.replaceAll(RegExp(r'/v1$'), '');
    return trimmed.replaceAll(RegExp(r'/api/?$'), '');
  }

  bool _isNotFound(DioException e) => e.response?.statusCode == 404;

  /// Generate text from a single prompt (non-streaming).
  Future<String> generateCode(
    String prompt, {
    double temperature = 0.7,
    int maxTokens = 2000,
  }) async {
    return chat(
      [ChatMessage.user(prompt)],
      temperature: temperature,
      maxTokens: maxTokens,
    );
  }

  /// Chat completion (non-streaming) via OpenAI /v1/chat/completions.
  Future<String> chat(
    List<ChatMessage> messages, {
    double temperature = 0.7,
    int? maxTokens,
  }) async {
    try {
      final response = await _dio.post(
        '$baseUrl/v1/chat/completions',
        data: {
          'model': model,
          'messages': messages.map((m) => m.toJson()).toList(),
          'stream': false,
          'temperature': temperature,
          'max_tokens': ?maxTokens,
        },
      );

      final content = _extractContent(response.data);
      if (content == null) {
        throw OllamaException(
          'Invalid response format from chat completions API',
        );
      }
      return content;
    } on DioException catch (e) {
      throw _mapDioError(e, 'chat');
    } catch (e) {
      if (e is OllamaException) rethrow;
      throw OllamaException('Failed to chat: $e');
    }
  }

  /// Stream a chat completion via OpenAI Server-Sent Events.
  Stream<String> chatStream(
    List<ChatMessage> messages, {
    double temperature = 0.7,
    int? maxTokens,
  }) async* {
    try {
      final response = await _dio.post(
        '$baseUrl/v1/chat/completions',
        data: {
          'model': model,
          'messages': messages.map((m) => m.toJson()).toList(),
          'stream': true,
          'temperature': temperature,
          'max_tokens': ?maxTokens,
        },
        options: Options(responseType: ResponseType.stream),
      );

      final stream = response.data.stream;
      var buffer = '';
      await for (final chunk in stream) {
        buffer += utf8.decode(chunk as List<int>, allowMalformed: true);
        // SSE events are line-delimited; process only complete lines and keep
        // any partial trailing line in the buffer for the next chunk.
        int newlineIndex;
        while ((newlineIndex = buffer.indexOf('\n')) >= 0) {
          final line = buffer.substring(0, newlineIndex).trim();
          buffer = buffer.substring(newlineIndex + 1);
          if (line.isEmpty || !line.startsWith('data:')) continue;
          final payload = line.substring(5).trim();
          if (payload == '[DONE]') return;
          try {
            final json = jsonDecode(payload);
            final delta = json['choices']?[0]?['delta']?['content'];
            if (delta is String && delta.isNotEmpty) {
              yield delta;
            }
          } catch (_) {
            // Skip a malformed SSE chunk rather than aborting the stream.
          }
        }
      }
    } on DioException catch (e) {
      throw _mapDioError(e, 'stream chat');
    } catch (e) {
      if (e is OllamaException) rethrow;
      throw OllamaException('Failed to stream chat: $e');
    }
  }

  /// Extract the assistant text from a chat-completions response body.
  String? _extractContent(dynamic data) {
    if (data is! Map) return null;
    final choices = data['choices'];
    if (choices is! List || choices.isEmpty) return null;
    final message = choices.first['message'];
    if (message is! Map) return null;
    final content = message['content'];
    return content is String ? content : null;
  }

  OllamaException _mapDioError(DioException e, String op) {
    if (_isNotFound(e)) {
      return OllamaException(
        'LLM endpoint not found at $baseUrl/v1/chat/completions. '
        'Verify the base URL and that the server is running.',
      );
    }
    if (e.error is SocketException) {
      return OllamaException(
        'Cannot reach the LLM server at $baseUrl. Is it running?',
      );
    }
    return OllamaException('Failed to $op: $e');
  }

  /// Check if the LLM server is reachable.
  Future<bool> isAvailable() async {
    try {
      final response = await _dio.get('$baseUrl/v1/models');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// List available model ids.
  Future<List<String>> listModels() async {
    try {
      final response = await _dio.get('$baseUrl/v1/models');
      final data = response.data['data'] as List;
      return data.map((m) => m['id'] as String).toList();
    } catch (e) {
      throw OllamaException('Failed to list models: $e');
    }
  }

  /// List available models with detailed info.
  Future<List<OllamaModel>> listModelsDetailed() async {
    try {
      final response = await _dio.get('$baseUrl/v1/models');
      final data = response.data['data'] as List;
      return data
          .map((m) => OllamaModel.fromOpenAiJson(m as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw OllamaException('Failed to list models: $e');
    }
  }
}

/// Model info from an OpenAI-compatible `/v1/models` entry.
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

  /// Parse an OpenAI `/v1/models` entry (`{id, created, meta:{size}}`).
  factory OllamaModel.fromOpenAiJson(Map<String, dynamic> json) {
    final meta = json['meta'];
    final created = json['created'];
    return OllamaModel(
      name: json['id'] as String? ?? 'unknown',
      sizeBytes: (meta is Map ? meta['size'] as int? : null) ?? 0,
      modifiedAt: created is int
          ? DateTime.fromMillisecondsSinceEpoch(created * 1000)
          : DateTime.now(),
      digest: null,
    );
  }
}

/// Chat message model (OpenAI shape: role + content).
class ChatMessage {
  final String role; // 'system', 'user', 'assistant'
  final String content;

  ChatMessage({required this.role, required this.content});

  Map<String, dynamic> toJson() => {'role': role, 'content': content};

  factory ChatMessage.system(String content) =>
      ChatMessage(role: 'system', content: content);

  factory ChatMessage.user(String content) =>
      ChatMessage(role: 'user', content: content);

  factory ChatMessage.assistant(String content) =>
      ChatMessage(role: 'assistant', content: content);
}

/// Custom exception for local LLM errors.
class OllamaException implements Exception {
  final String message;
  OllamaException(this.message);

  @override
  String toString() => 'OllamaException: $message';
}
