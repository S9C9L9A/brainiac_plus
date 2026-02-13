import 'dart:io';
import 'package:dio/dio.dart';

/// Service for Instagram Graph API
/// Handles authentication and content publishing
class InstagramService {
  final Dio _dio;
  final String accessToken;
  final String userId;

  InstagramService({
    required this.accessToken,
    required this.userId,
  }) : _dio = Dio(BaseOptions(
          baseUrl: 'https://graph.instagram.com/v18.0',
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(minutes: 5),
        ));

  /// Upload a photo to Instagram
  Future<String> uploadPhoto({
    required File imageFile,
    required String caption,
    String? location,
  }) async {
    try {
      // Step 1: Create media container
      final containerResponse = await _dio.post(
        '/$userId/media',
        data: {
          'image_url': await _uploadToTemporaryStorage(imageFile),
          'caption': caption,
          if (location != null) 'location_id': location,
          'access_token': accessToken,
        },
      );

      final containerId = containerResponse.data['id'] as String;

      // Step 2: Publish the container
      final publishResponse = await _dio.post(
        '/$userId/media_publish',
        data: {
          'creation_id': containerId,
          'access_token': accessToken,
        },
      );

      return publishResponse.data['id'] as String;
    } catch (e) {
      throw InstagramException('Failed to upload photo: $e');
    }
  }

  /// Upload a video/Reel to Instagram
  Future<String> uploadVideo({
    required File videoFile,
    required String caption,
    bool isReel = true,
    File? coverImage,
  }) async {
    try {
      // Step 1: Create video container
      final containerResponse = await _dio.post(
        '/$userId/media',
        data: {
          'media_type': isReel ? 'REELS' : 'VIDEO',
          'video_url': await _uploadToTemporaryStorage(videoFile),
          'caption': caption,
          if (coverImage != null)
            'thumb_offset': 0, // or provide custom thumbnail
          'access_token': accessToken,
        },
      );

      final containerId = containerResponse.data['id'] as String;

      // Step 2: Wait for video processing
      await _waitForVideoProcessing(containerId);

      // Step 3: Publish the container
      final publishResponse = await _dio.post(
        '/$userId/media_publish',
        data: {
          'creation_id': containerId,
          'access_token': accessToken,
        },
      );

      return publishResponse.data['id'] as String;
    } catch (e) {
      throw InstagramException('Failed to upload video: $e');
    }
  }

  /// Upload a carousel (multiple photos)
  Future<String> uploadCarousel({
    required List<File> images,
    required String caption,
  }) async {
    try {
      // Step 1: Create containers for each image
      final containerIds = <String>[];
      for (final image in images) {
        final response = await _dio.post(
          '/$userId/media',
          data: {
            'is_carousel_item': true,
            'image_url': await _uploadToTemporaryStorage(image),
            'access_token': accessToken,
          },
        );
        containerIds.add(response.data['id'] as String);
      }

      // Step 2: Create carousel container
      final carouselResponse = await _dio.post(
        '/$userId/media',
        data: {
          'media_type': 'CAROUSEL',
          'children': containerIds.join(','),
          'caption': caption,
          'access_token': accessToken,
        },
      );

      final carouselId = carouselResponse.data['id'] as String;

      // Step 3: Publish the carousel
      final publishResponse = await _dio.post(
        '/$userId/media_publish',
        data: {
          'creation_id': carouselId,
          'access_token': accessToken,
        },
      );

      return publishResponse.data['id'] as String;
    } catch (e) {
      throw InstagramException('Failed to upload carousel: $e');
    }
  }

  /// Get media insights (analytics)
  Future<MediaInsights> getMediaInsights(String mediaId) async {
    try {
      final response = await _dio.get(
        '/$mediaId/insights',
        queryParameters: {
          'metric': 'engagement,impressions,reach,saved',
          'access_token': accessToken,
        },
      );

      return MediaInsights.fromJson(response.data);
    } catch (e) {
      throw InstagramException('Failed to get insights: $e');
    }
  }

  /// Get user profile info
  Future<InstagramProfile> getProfile() async {
    try {
      final response = await _dio.get(
        '/$userId',
        queryParameters: {
          'fields': 'id,username,account_type,media_count,followers_count',
          'access_token': accessToken,
        },
      );

      return InstagramProfile.fromJson(response.data);
    } catch (e) {
      throw InstagramException('Failed to get profile: $e');
    }
  }

  /// Wait for video processing to complete
  Future<void> _waitForVideoProcessing(String containerId) async {
    var attempts = 0;
    const maxAttempts = 60; // 5 minutes max (5s intervals)

    while (attempts < maxAttempts) {
      final response = await _dio.get(
        '/$containerId',
        queryParameters: {
          'fields': 'status_code',
          'access_token': accessToken,
        },
      );

      final statusCode = response.data['status_code'] as String;
      if (statusCode == 'FINISHED') {
        return;
      } else if (statusCode == 'ERROR') {
        throw InstagramException('Video processing failed');
      }

      await Future.delayed(const Duration(seconds: 5));
      attempts++;
    }

    throw InstagramException('Video processing timeout');
  }

  /// Upload file to temporary storage (placeholder)
  /// In production, use your own CDN or Instagram's direct upload
  Future<String> _uploadToTemporaryStorage(File file) async {
    // TODO: Implement actual file upload to accessible URL
    // This could be AWS S3, Cloudinary, or any CDN
    // For now, return a placeholder
    throw UnimplementedError(
      'File upload to CDN not implemented. '
      'Please implement _uploadToTemporaryStorage method.',
    );
  }
}

/// Instagram profile model
class InstagramProfile {
  final String id;
  final String username;
  final String accountType;
  final int mediaCount;
  final int followersCount;

  InstagramProfile({
    required this.id,
    required this.username,
    required this.accountType,
    required this.mediaCount,
    required this.followersCount,
  });

  factory InstagramProfile.fromJson(Map<String, dynamic> json) {
    return InstagramProfile(
      id: json['id'] as String,
      username: json['username'] as String,
      accountType: json['account_type'] as String,
      mediaCount: json['media_count'] as int,
      followersCount: json['followers_count'] as int? ?? 0,
    );
  }
}

/// Media insights model
class MediaInsights {
  final int engagement;
  final int impressions;
  final int reach;
  final int saved;

  MediaInsights({
    required this.engagement,
    required this.impressions,
    required this.reach,
    required this.saved,
  });

  factory MediaInsights.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as List;
    final metrics = <String, int>{};

    for (final item in data) {
      final name = item['name'] as String;
      final values = item['values'] as List;
      if (values.isNotEmpty) {
        metrics[name] = values[0]['value'] as int;
      }
    }

    return MediaInsights(
      engagement: metrics['engagement'] ?? 0,
      impressions: metrics['impressions'] ?? 0,
      reach: metrics['reach'] ?? 0,
      saved: metrics['saved'] ?? 0,
    );
  }
}

/// Custom exception for Instagram errors
class InstagramException implements Exception {
  final String message;
  InstagramException(this.message);

  @override
  String toString() => 'InstagramException: $message';
}
