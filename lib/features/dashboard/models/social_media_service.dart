/// Modello per i servizi social media configurati
class SocialMediaService {
  final String id;
  final SocialPlatform platform;
  final String name;
  final String? pageId;
  final String? accessToken;
  final bool isConfigured;
  final bool isActive;
  final DateTime? lastSync;
  final SocialMediaMetrics? metrics;

  const SocialMediaService({
    required this.id,
    required this.platform,
    required this.name,
    this.pageId,
    this.accessToken,
    this.isConfigured = false,
    this.isActive = false,
    this.lastSync,
    this.metrics,
  });

  SocialMediaService copyWith({
    String? id,
    SocialPlatform? platform,
    String? name,
    String? pageId,
    String? accessToken,
    bool? isConfigured,
    bool? isActive,
    DateTime? lastSync,
    SocialMediaMetrics? metrics,
  }) {
    return SocialMediaService(
      id: id ?? this.id,
      platform: platform ?? this.platform,
      name: name ?? this.name,
      pageId: pageId ?? this.pageId,
      accessToken: accessToken ?? this.accessToken,
      isConfigured: isConfigured ?? this.isConfigured,
      isActive: isActive ?? this.isActive,
      lastSync: lastSync ?? this.lastSync,
      metrics: metrics ?? this.metrics,
    );
  }

  factory SocialMediaService.fromJson(Map<String, dynamic> json) {
    return SocialMediaService(
      id: json['id'] as String,
      platform: SocialPlatform.values.firstWhere(
        (e) => e.name == json['platform'],
        orElse: () => SocialPlatform.other,
      ),
      name: json['name'] as String,
      pageId: json['page_id'] as String?,
      accessToken: json['access_token'] as String?,
      isConfigured: json['is_configured'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? false,
      lastSync: json['last_sync'] != null 
          ? DateTime.parse(json['last_sync'] as String)
          : null,
      metrics: json['metrics'] != null
          ? SocialMediaMetrics.fromJson(json['metrics'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'platform': platform.name,
      'name': name,
      'page_id': pageId,
      'access_token': accessToken,
      'is_configured': isConfigured,
      'is_active': isActive,
      'last_sync': lastSync?.toIso8601String(),
      'metrics': metrics?.toJson(),
    };
  }
}

/// Metriche del servizio social
class SocialMediaMetrics {
  final int followers;
  final int posts;
  final int engagement;
  final int likes;
  final int comments;
  final int shares;
  final double engagementRate;
  final Map<String, dynamic>? extra;

  const SocialMediaMetrics({
    this.followers = 0,
    this.posts = 0,
    this.engagement = 0,
    this.likes = 0,
    this.comments = 0,
    this.shares = 0,
    this.engagementRate = 0.0,
    this.extra,
  });

  factory SocialMediaMetrics.fromJson(Map<String, dynamic> json) {
    return SocialMediaMetrics(
      followers: json['followers'] as int? ?? 0,
      posts: json['posts'] as int? ?? 0,
      engagement: json['engagement'] as int? ?? 0,
      likes: json['likes'] as int? ?? 0,
      comments: json['comments'] as int? ?? 0,
      shares: json['shares'] as int? ?? 0,
      engagementRate: (json['engagement_rate'] as num?)?.toDouble() ?? 0.0,
      extra: json['extra'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'followers': followers,
      'posts': posts,
      'engagement': engagement,
      'likes': likes,
      'comments': comments,
      'shares': shares,
      'engagement_rate': engagementRate,
      'extra': extra,
    };
  }
}

/// Piattaforme social supportate
enum SocialPlatform {
  facebook,
  instagram,
  youtube,
  twitter,
  linkedin,
  tiktok,
  telegram,
  whatsapp,
  other,
}

extension SocialPlatformExtension on SocialPlatform {
  String get displayName {
    switch (this) {
      case SocialPlatform.facebook:
        return 'Facebook';
      case SocialPlatform.instagram:
        return 'Instagram';
      case SocialPlatform.youtube:
        return 'YouTube';
      case SocialPlatform.twitter:
        return 'Twitter/X';
      case SocialPlatform.linkedin:
        return 'LinkedIn';
      case SocialPlatform.tiktok:
        return 'TikTok';
      case SocialPlatform.telegram:
        return 'Telegram';
      case SocialPlatform.whatsapp:
        return 'WhatsApp';
      case SocialPlatform.other:
        return 'Other';
    }
  }

  String get iconEmoji {
    switch (this) {
      case SocialPlatform.facebook:
        return '📘';
      case SocialPlatform.instagram:
        return '📸';
      case SocialPlatform.youtube:
        return '📹';
      case SocialPlatform.twitter:
        return '🐦';
      case SocialPlatform.linkedin:
        return '💼';
      case SocialPlatform.tiktok:
        return '🎵';
      case SocialPlatform.telegram:
        return '✈️';
      case SocialPlatform.whatsapp:
        return '💬';
      case SocialPlatform.other:
        return '📱';
    }
  }

  List<int> get brandColors {
    switch (this) {
      case SocialPlatform.facebook:
        return [0xFF1877F2, 0xFF0D5DBF]; // Facebook blue
      case SocialPlatform.instagram:
        return [0xFFE1306C, 0xFFFF6B35]; // Instagram gradient
      case SocialPlatform.youtube:
        return [0xFFFF0000, 0xFFCC0000]; // YouTube red
      case SocialPlatform.twitter:
        return [0xFF1DA1F2, 0xFF0D8BD9]; // Twitter blue
      case SocialPlatform.linkedin:
        return [0xFF0A66C2, 0xFF004182]; // LinkedIn blue
      case SocialPlatform.tiktok:
        return [0xFF000000, 0xFF00F2EA]; // TikTok black/cyan
      case SocialPlatform.telegram:
        return [0xFF0088CC, 0xFF006699]; // Telegram blue
      case SocialPlatform.whatsapp:
        return [0xFF25D366, 0xFF128C7E]; // WhatsApp green
      case SocialPlatform.other:
        return [0xFF9C27B0, 0xFF673AB7]; // Purple gradient
    }
  }
}
