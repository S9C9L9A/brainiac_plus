/// Social Media Automation Task Model
/// Extends AutomatedTask for Instagram content generation and publishing
class SocialMediaTask {
  final int? id;
  final String name;
  final bool enabled;
  final String schedule; // cron syntax
  
  // Content Generation Settings
  final ContentType contentType;
  final String contentPrompt;
  final String contentStyle; // realistic, artistic, cinematic, etc.
  final int? videoDuration; // For video content (seconds)
  
  // Instagram Settings
  final String caption;
  final List<String> hashtags;
  final bool autoGenerateCaption;
  final String? locationId;
  
  // Publishing Settings
  final PublishPlatform platform;
  final bool publishImmediately;
  final DateTime? scheduledTime;
  
  // Status
  final DateTime? lastRun;
  final DateTime createdAt;
  final TaskStatus status;
  final String? lastError;

  SocialMediaTask({
    this.id,
    required this.name,
    this.enabled = true,
    required this.schedule,
    required this.contentType,
    required this.contentPrompt,
    this.contentStyle = 'realistic',
    this.videoDuration,
    this.caption = '',
    this.hashtags = const [],
    this.autoGenerateCaption = true,
    this.locationId,
    this.platform = PublishPlatform.instagram,
    this.publishImmediately = true,
    this.scheduledTime,
    this.lastRun,
    DateTime? createdAt,
    this.status = TaskStatus.pending,
    this.lastError,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'enabled': enabled ? 1 : 0,
      'schedule': schedule,
      'content_type': contentType.name,
      'content_prompt': contentPrompt,
      'content_style': contentStyle,
      'video_duration': videoDuration,
      'caption': caption,
      'hashtags': hashtags.join(','),
      'auto_generate_caption': autoGenerateCaption ? 1 : 0,
      'location_id': locationId,
      'platform': platform.name,
      'publish_immediately': publishImmediately ? 1 : 0,
      'scheduled_time': scheduledTime?.toIso8601String(),
      'last_run': lastRun?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'status': status.name,
      'last_error': lastError,
    };
  }

  factory SocialMediaTask.fromMap(Map<String, dynamic> map) {
    return SocialMediaTask(
      id: map['id'] as int?,
      name: map['name'] as String,
      enabled: map['enabled'] == 1,
      schedule: map['schedule'] as String,
      contentType: ContentType.values.byName(map['content_type'] as String),
      contentPrompt: map['content_prompt'] as String,
      contentStyle: map['content_style'] as String? ?? 'realistic',
      videoDuration: map['video_duration'] as int?,
      caption: map['caption'] as String? ?? '',
      hashtags: (map['hashtags'] as String?)?.isEmpty ?? true
          ? []
          : (map['hashtags'] as String).split(','),
      autoGenerateCaption: map['auto_generate_caption'] == 1,
      locationId: map['location_id'] as String?,
      platform: PublishPlatform.values.byName(map['platform'] as String),
      publishImmediately: map['publish_immediately'] == 1,
      scheduledTime: map['scheduled_time'] != null
          ? DateTime.parse(map['scheduled_time'] as String)
          : null,
      lastRun: map['last_run'] != null
          ? DateTime.parse(map['last_run'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      status: TaskStatus.values.byName(map['status'] as String? ?? 'pending'),
      lastError: map['last_error'] as String?,
    );
  }

  SocialMediaTask copyWith({
    int? id,
    String? name,
    bool? enabled,
    String? schedule,
    ContentType? contentType,
    String? contentPrompt,
    String? contentStyle,
    int? videoDuration,
    String? caption,
    List<String>? hashtags,
    bool? autoGenerateCaption,
    String? locationId,
    PublishPlatform? platform,
    bool? publishImmediately,
    DateTime? scheduledTime,
    DateTime? lastRun,
    DateTime? createdAt,
    TaskStatus? status,
    String? lastError,
  }) {
    return SocialMediaTask(
      id: id ?? this.id,
      name: name ?? this.name,
      enabled: enabled ?? this.enabled,
      schedule: schedule ?? this.schedule,
      contentType: contentType ?? this.contentType,
      contentPrompt: contentPrompt ?? this.contentPrompt,
      contentStyle: contentStyle ?? this.contentStyle,
      videoDuration: videoDuration ?? this.videoDuration,
      caption: caption ?? this.caption,
      hashtags: hashtags ?? this.hashtags,
      autoGenerateCaption: autoGenerateCaption ?? this.autoGenerateCaption,
      locationId: locationId ?? this.locationId,
      platform: platform ?? this.platform,
      publishImmediately: publishImmediately ?? this.publishImmediately,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      lastRun: lastRun ?? this.lastRun,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      lastError: lastError ?? this.lastError,
    );
  }
}

/// Content type enum
enum ContentType {
  photo, // Single photo
  video, // Video/Reel
  carousel, // Multiple photos
}

/// Publish platform enum
enum PublishPlatform {
  instagram,
  facebook,
  tiktok, // Future support
  youtube, // Future support
}

/// Task status enum
enum TaskStatus {
  pending, // Waiting to run
  generating, // Generating content with AI
  uploading, // Uploading to platform
  completed, // Successfully published
  failed, // Failed to complete
}

/// Extension for ContentType
extension ContentTypeX on ContentType {
  String get label {
    switch (this) {
      case ContentType.photo:
        return 'Photo';
      case ContentType.video:
        return 'Video/Reel';
      case ContentType.carousel:
        return 'Carousel';
    }
  }

  String get icon {
    switch (this) {
      case ContentType.photo:
        return '📸';
      case ContentType.video:
        return '🎥';
      case ContentType.carousel:
        return '🖼️';
    }
  }
}

/// Extension for PublishPlatform
extension PublishPlatformX on PublishPlatform {
  String get label {
    switch (this) {
      case PublishPlatform.instagram:
        return 'Instagram';
      case PublishPlatform.facebook:
        return 'Facebook';
      case PublishPlatform.tiktok:
        return 'TikTok';
      case PublishPlatform.youtube:
        return 'YouTube';
    }
  }

  String get icon {
    switch (this) {
      case PublishPlatform.instagram:
        return '📷';
      case PublishPlatform.facebook:
        return '👥';
      case PublishPlatform.tiktok:
        return '🎵';
      case PublishPlatform.youtube:
        return '▶️';
    }
  }
}

/// Extension for TaskStatus
extension TaskStatusX on TaskStatus {
  String get label {
    switch (this) {
      case TaskStatus.pending:
        return 'Pending';
      case TaskStatus.generating:
        return 'Generating...';
      case TaskStatus.uploading:
        return 'Uploading...';
      case TaskStatus.completed:
        return 'Completed';
      case TaskStatus.failed:
        return 'Failed';
    }
  }

  bool get isRunning =>
      this == TaskStatus.generating || this == TaskStatus.uploading;
}
