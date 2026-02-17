import 'package:dio/dio.dart';

/// Service for Higgsfield AI content generation
/// Higgsfield generates AI-powered photos and videos
class HiggsfieldService {
  final Dio _dio;
  final String apiKey;
  final String baseUrl;

  HiggsfieldService({
    required this.apiKey,
    String? baseUrl,
  })  : baseUrl = baseUrl ?? 'https://api.higgsfield.ai/v1',
        _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(minutes: 5), // Video generation can take time
        ));

  /// Generate an image from text prompt
  Future<GeneratedContent> generateImage({
    required String prompt,
    String style = 'realistic',
    String aspectRatio = '1:1', // Instagram square
    int quality = 80,
  }) async {
    try {
      final response = await _dio.post(
        '$baseUrl/generate/image',
        data: {
          'prompt': prompt,
          'style': style,
          'aspect_ratio': aspectRatio,
          'quality': quality,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        ),
      );

      return GeneratedContent.fromJson(response.data);
    } catch (e) {
      throw HiggsfieldException('Failed to generate image: $e');
    }
  }

  /// Generate a video from text prompt
  Future<GeneratedContent> generateVideo({
    required String prompt,
    int duration = 15, // seconds (Instagram Reels max 90s)
    String style = 'cinematic',
    String aspectRatio = '9:16', // Reels vertical
    int quality = 80,
  }) async {
    try {
      final response = await _dio.post(
        '$baseUrl/generate/video',
        data: {
          'prompt': prompt,
          'duration': duration,
          'style': style,
          'aspect_ratio': aspectRatio,
          'quality': quality,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        ),
      );

      return GeneratedContent.fromJson(response.data);
    } catch (e) {
      throw HiggsfieldException('Failed to generate video: $e');
    }
  }

  /// Check generation status (for async generation)
  Future<GeneratedContent> getGenerationStatus(String jobId) async {
    try {
      final response = await _dio.get(
        '$baseUrl/jobs/$jobId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
          },
        ),
      );

      return GeneratedContent.fromJson(response.data);
    } catch (e) {
      throw HiggsfieldException('Failed to get generation status: $e');
    }
  }

  /// Download generated content
  Future<List<int>> downloadContent(String url) async {
    try {
      final response = await _dio.get<List<int>>(
        url,
        options: Options(
          responseType: ResponseType.bytes,
        ),
      );

      if (response.data == null) {
        throw HiggsfieldException('No data received when downloading content');
      }
      return response.data!;
    } catch (e) {
      throw HiggsfieldException('Failed to download content: $e');
    }
  }

  /// Generate caption using AI
  Future<String> generateCaption({
    required String contentDescription,
    String tone = 'engaging',
    int maxLength = 2200, // Instagram caption max
    List<String>? hashtags,
  }) async {
    try {
      final response = await _dio.post(
        '$baseUrl/generate/caption',
        data: {
          'description': contentDescription,
          'tone': tone,
          'max_length': maxLength,
          'hashtags': hashtags,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        ),
      );

      return response.data['caption'] as String;
    } catch (e) {
      throw HiggsfieldException('Failed to generate caption: $e');
    }
  }
}

/// Generated content model
class GeneratedContent {
  final String id;
  final String type; // 'image' or 'video'
  final String status; // 'processing', 'completed', 'failed'
  final String? url; // Download URL when completed
  final String? thumbnailUrl; // For videos
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  GeneratedContent({
    required this.id,
    required this.type,
    required this.status,
    this.url,
    this.thumbnailUrl,
    this.metadata,
    required this.createdAt,
  });

  factory GeneratedContent.fromJson(Map<String, dynamic> json) {
    return GeneratedContent(
      id: json['id'] as String,
      type: json['type'] as String,
      status: json['status'] as String,
      url: json['url'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  bool get isCompleted => status == 'completed';
  bool get isProcessing => status == 'processing';
  bool get isFailed => status == 'failed';
}

/// Custom exception for Higgsfield errors
class HiggsfieldException implements Exception {
  final String message;
  HiggsfieldException(this.message);

  @override
  String toString() => 'HiggsfieldException: $message';
}
