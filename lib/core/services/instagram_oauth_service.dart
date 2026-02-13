import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';

/// Instagram OAuth Service
/// Handles Instagram Basic Display API authentication flow
class InstagramOAuthService {
  final String clientId;
  final String clientSecret;
  final String redirectUri;
  final Dio _dio;

  InstagramOAuthService({
    required this.clientId,
    required this.clientSecret,
    this.redirectUri = 'brainiacplus://oauth/instagram',
  }) : _dio = Dio();

  /// Step 1: Open Instagram authorization URL in browser
  Future<void> authorize() async {
    final authUrl = Uri.https(
      'api.instagram.com',
      '/oauth/authorize',
      {
        'client_id': clientId,
        'redirect_uri': redirectUri,
        'scope': 'user_profile,user_media',
        'response_type': 'code',
      },
    );

    if (await canLaunchUrl(authUrl)) {
      await launchUrl(authUrl, mode: LaunchMode.externalApplication);
    } else {
      throw OAuthException('Could not launch Instagram auth URL');
    }
  }

  /// Step 2: Exchange authorization code for access token
  Future<InstagramTokenResponse> exchangeCodeForToken(String code) async {
    try {
      final response = await _dio.post(
        'https://api.instagram.com/oauth/access_token',
        data: {
          'client_id': clientId,
          'client_secret': clientSecret,
          'grant_type': 'authorization_code',
          'redirect_uri': redirectUri,
          'code': code,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );

      return InstagramTokenResponse.fromJson(response.data);
    } catch (e) {
      throw OAuthException('Failed to exchange code for token: $e');
    }
  }

  /// Step 3: Exchange short-lived token for long-lived token (60 days)
  Future<LongLivedTokenResponse> getLongLivedToken(String shortLivedToken) async {
    try {
      final response = await _dio.get(
        'https://graph.instagram.com/access_token',
        queryParameters: {
          'grant_type': 'ig_exchange_token',
          'client_secret': clientSecret,
          'access_token': shortLivedToken,
        },
      );

      return LongLivedTokenResponse.fromJson(response.data);
    } catch (e) {
      throw OAuthException('Failed to get long-lived token: $e');
    }
  }

  /// Refresh long-lived token (before expiry)
  Future<LongLivedTokenResponse> refreshToken(String token) async {
    try {
      final response = await _dio.get(
        'https://graph.instagram.com/refresh_access_token',
        queryParameters: {
          'grant_type': 'ig_refresh_token',
          'access_token': token,
        },
      );

      return LongLivedTokenResponse.fromJson(response.data);
    } catch (e) {
      throw OAuthException('Failed to refresh token: $e');
    }
  }

  /// Get user profile info
  Future<InstagramProfile> getUserProfile(String accessToken) async {
    try {
      final response = await _dio.get(
        'https://graph.instagram.com/me',
        queryParameters: {
          'fields': 'id,username,account_type,media_count',
          'access_token': accessToken,
        },
      );

      return InstagramProfile.fromJson(response.data);
    } catch (e) {
      throw OAuthException('Failed to get user profile: $e');
    }
  }
}

/// Token response from Instagram
class InstagramTokenResponse {
  final String accessToken;
  final String userId;

  InstagramTokenResponse({
    required this.accessToken,
    required this.userId,
  });

  factory InstagramTokenResponse.fromJson(Map<String, dynamic> json) {
    return InstagramTokenResponse(
      accessToken: json['access_token'] as String,
      userId: json['user_id'].toString(),
    );
  }
}

/// Long-lived token response
class LongLivedTokenResponse {
  final String accessToken;
  final String tokenType;
  final int expiresIn; // seconds

  LongLivedTokenResponse({
    required this.accessToken,
    required this.tokenType,
    required this.expiresIn,
  });

  factory LongLivedTokenResponse.fromJson(Map<String, dynamic> json) {
    return LongLivedTokenResponse(
      accessToken: json['access_token'] as String,
      tokenType: json['token_type'] as String,
      expiresIn: json['expires_in'] as int,
    );
  }

  DateTime get expiryDate => DateTime.now().add(Duration(seconds: expiresIn));
}

/// Instagram profile
class InstagramProfile {
  final String id;
  final String username;
  final String accountType;
  final int mediaCount;

  InstagramProfile({
    required this.id,
    required this.username,
    required this.accountType,
    required this.mediaCount,
  });

  factory InstagramProfile.fromJson(Map<String, dynamic> json) {
    return InstagramProfile(
      id: json['id'].toString(),
      username: json['username'] as String,
      accountType: json['account_type'] as String? ?? 'PERSONAL',
      mediaCount: json['media_count'] as int? ?? 0,
    );
  }
}

/// OAuth exception
class OAuthException implements Exception {
  final String message;
  OAuthException(this.message);

  @override
  String toString() => 'OAuthException: $message';
}
