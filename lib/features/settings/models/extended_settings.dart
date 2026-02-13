import '../../automation/models/automation_enums.dart';

/// Extended settings model with multi-service support
class ExtendedAppSettings {
  // AI Services
  final String? higgsfieldApiKey;
  final String? openaiApiKey;
  final String? ollamaEndpoint;
  
  // Social Media - Instagram
  final String? instagramAccessToken;
  final String? instagramUserId;
  final String? instagramUsername;
  final DateTime? instagramTokenExpiry;
  
  // Social Media - Facebook
  final String? facebookAccessToken;
  final String? facebookUserId;
  final DateTime? facebookTokenExpiry;
  
  // Social Media - Twitter/X
  final String? twitterApiKey;
  final String? twitterApiSecret;
  final String? twitterAccessToken;
  final String? twitterAccessSecret;
  
  // Social Media - TikTok
  final String? tiktokAccessToken;
  final DateTime? tiktokTokenExpiry;
  
  // Social Media - LinkedIn
  final String? linkedinAccessToken;
  final DateTime? linkedinTokenExpiry;
  
  // Social Media - YouTube
  final String? youtubeApiKey;
  final String? youtubeAccessToken;
  
  // Productivity - Notion
  final String? notionApiKey;
  final String? notionWorkspaceId;
  
  // Productivity - Google
  final String? googleAccessToken;
  final String? googleRefreshToken;
  final DateTime? googleTokenExpiry;
  
  // Communication - Slack
  final String? slackBotToken;
  final String? slackWorkspaceId;
  
  // Communication - Discord
  final String? discordBotToken;
  final String? discordServerId;
  
  // Communication - Telegram
  final String? telegramBotToken;
  final String? telegramChatId;
  
  // Development - GitHub
  final String? githubAccessToken;
  final String? githubUsername;
  
  // Preferences
  final bool notificationsEnabled;
  final bool autoRefreshMetrics;
  final int refreshInterval;
  final String theme;
  final bool automationEnabled;
  final bool retryFailedTasks;
  final int maxRetries;

  const ExtendedAppSettings({
    this.higgsfieldApiKey,
    this.openaiApiKey,
    this.ollamaEndpoint,
    this.instagramAccessToken,
    this.instagramUserId,
    this.instagramUsername,
    this.instagramTokenExpiry,
    this.facebookAccessToken,
    this.facebookUserId,
    this.facebookTokenExpiry,
    this.twitterApiKey,
    this.twitterApiSecret,
    this.twitterAccessToken,
    this.twitterAccessSecret,
    this.tiktokAccessToken,
    this.tiktokTokenExpiry,
    this.linkedinAccessToken,
    this.linkedinTokenExpiry,
    this.youtubeApiKey,
    this.youtubeAccessToken,
    this.notionApiKey,
    this.notionWorkspaceId,
    this.googleAccessToken,
    this.googleRefreshToken,
    this.googleTokenExpiry,
    this.slackBotToken,
    this.slackWorkspaceId,
    this.discordBotToken,
    this.discordServerId,
    this.telegramBotToken,
    this.telegramChatId,
    this.githubAccessToken,
    this.githubUsername,
    this.notificationsEnabled = true,
    this.autoRefreshMetrics = true,
    this.refreshInterval = 5,
    this.theme = 'system',
    this.automationEnabled = true,
    this.retryFailedTasks = true,
    this.maxRetries = 3,
  });

  /// Check if a specific service is configured
  bool isServiceConfigured(ServiceProvider service) {
    switch (service) {
      case ServiceProvider.instagram:
        return instagramAccessToken != null && instagramUserId != null;
      case ServiceProvider.facebook:
        return facebookAccessToken != null && facebookUserId != null;
      case ServiceProvider.twitter:
        return twitterApiKey != null && twitterApiSecret != null;
      case ServiceProvider.tiktok:
        return tiktokAccessToken != null;
      case ServiceProvider.linkedin:
        return linkedinAccessToken != null;
      case ServiceProvider.youtube:
        return youtubeApiKey != null || youtubeAccessToken != null;
      case ServiceProvider.notion:
        return notionApiKey != null;
      case ServiceProvider.google:
        return googleAccessToken != null;
      case ServiceProvider.slack:
        return slackBotToken != null;
      case ServiceProvider.discord:
        return discordBotToken != null;
      case ServiceProvider.telegram:
        return telegramBotToken != null;
      case ServiceProvider.github:
        return githubAccessToken != null;
      case ServiceProvider.custom:
        return true; // Custom always available
    }
  }

  /// Get all configured services
  List<ServiceProvider> get configuredServices {
    return ServiceProvider.values
        .where((service) => isServiceConfigured(service))
        .toList();
  }

  /// Get services that need configuration
  List<ServiceProvider> get unconfiguredServices {
    return ServiceProvider.values
        .where((service) => !isServiceConfigured(service) && service != ServiceProvider.custom)
        .toList();
  }

  /// Check if service has API support and is configured
  bool canUseAPI(ServiceProvider service) {
    return service.supportsAPI && isServiceConfigured(service);
  }

  /// Helper getters
  bool get hasHiggsfieldKey => higgsfieldApiKey != null && higgsfieldApiKey!.isNotEmpty;
  bool get hasOpenAIKey => openaiApiKey != null && openaiApiKey!.isNotEmpty;
  bool get hasOllamaEndpoint => ollamaEndpoint != null && ollamaEndpoint!.isNotEmpty;
  
  bool get hasInstagramAuth => instagramAccessToken != null && instagramUserId != null;
  bool get hasFacebookAuth => facebookAccessToken != null && facebookUserId != null;
  bool get hasTwitterAuth => twitterApiKey != null && twitterApiSecret != null;
  bool get hasTikTokAuth => tiktokAccessToken != null;
  bool get hasLinkedInAuth => linkedinAccessToken != null;
  bool get hasYouTubeAuth => youtubeApiKey != null || youtubeAccessToken != null;
  bool get hasNotionKey => notionApiKey != null;
  bool get hasGoogleAuth => googleAccessToken != null;
  bool get hasSlackAuth => slackBotToken != null;
  bool get hasDiscordAuth => discordBotToken != null;
  bool get hasTelegramAuth => telegramBotToken != null;
  bool get hasGitHubAuth => githubAccessToken != null;

  ExtendedAppSettings copyWith({
    String? higgsfieldApiKey,
    String? openaiApiKey,
    String? ollamaEndpoint,
    String? instagramAccessToken,
    String? instagramUserId,
    String? instagramUsername,
    DateTime? instagramTokenExpiry,
    String? facebookAccessToken,
    String? facebookUserId,
    DateTime? facebookTokenExpiry,
    String? twitterApiKey,
    String? twitterApiSecret,
    String? twitterAccessToken,
    String? twitterAccessSecret,
    String? tiktokAccessToken,
    DateTime? tiktokTokenExpiry,
    String? linkedinAccessToken,
    DateTime? linkedinTokenExpiry,
    String? youtubeApiKey,
    String? youtubeAccessToken,
    String? notionApiKey,
    String? notionWorkspaceId,
    String? googleAccessToken,
    String? googleRefreshToken,
    DateTime? googleTokenExpiry,
    String? slackBotToken,
    String? slackWorkspaceId,
    String? discordBotToken,
    String? discordServerId,
    String? telegramBotToken,
    String? telegramChatId,
    String? githubAccessToken,
    String? githubUsername,
    bool? notificationsEnabled,
    bool? autoRefreshMetrics,
    int? refreshInterval,
    String? theme,
    bool? automationEnabled,
    bool? retryFailedTasks,
    int? maxRetries,
  }) {
    return ExtendedAppSettings(
      higgsfieldApiKey: higgsfieldApiKey ?? this.higgsfieldApiKey,
      openaiApiKey: openaiApiKey ?? this.openaiApiKey,
      ollamaEndpoint: ollamaEndpoint ?? this.ollamaEndpoint,
      instagramAccessToken: instagramAccessToken ?? this.instagramAccessToken,
      instagramUserId: instagramUserId ?? this.instagramUserId,
      instagramUsername: instagramUsername ?? this.instagramUsername,
      instagramTokenExpiry: instagramTokenExpiry ?? this.instagramTokenExpiry,
      facebookAccessToken: facebookAccessToken ?? this.facebookAccessToken,
      facebookUserId: facebookUserId ?? this.facebookUserId,
      facebookTokenExpiry: facebookTokenExpiry ?? this.facebookTokenExpiry,
      twitterApiKey: twitterApiKey ?? this.twitterApiKey,
      twitterApiSecret: twitterApiSecret ?? this.twitterApiSecret,
      twitterAccessToken: twitterAccessToken ?? this.twitterAccessToken,
      twitterAccessSecret: twitterAccessSecret ?? this.twitterAccessSecret,
      tiktokAccessToken: tiktokAccessToken ?? this.tiktokAccessToken,
      tiktokTokenExpiry: tiktokTokenExpiry ?? this.tiktokTokenExpiry,
      linkedinAccessToken: linkedinAccessToken ?? this.linkedinAccessToken,
      linkedinTokenExpiry: linkedinTokenExpiry ?? this.linkedinTokenExpiry,
      youtubeApiKey: youtubeApiKey ?? this.youtubeApiKey,
      youtubeAccessToken: youtubeAccessToken ?? this.youtubeAccessToken,
      notionApiKey: notionApiKey ?? this.notionApiKey,
      notionWorkspaceId: notionWorkspaceId ?? this.notionWorkspaceId,
      googleAccessToken: googleAccessToken ?? this.googleAccessToken,
      googleRefreshToken: googleRefreshToken ?? this.googleRefreshToken,
      googleTokenExpiry: googleTokenExpiry ?? this.googleTokenExpiry,
      slackBotToken: slackBotToken ?? this.slackBotToken,
      slackWorkspaceId: slackWorkspaceId ?? this.slackWorkspaceId,
      discordBotToken: discordBotToken ?? this.discordBotToken,
      discordServerId: discordServerId ?? this.discordServerId,
      telegramBotToken: telegramBotToken ?? this.telegramBotToken,
      telegramChatId: telegramChatId ?? this.telegramChatId,
      githubAccessToken: githubAccessToken ?? this.githubAccessToken,
      githubUsername: githubUsername ?? this.githubUsername,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      autoRefreshMetrics: autoRefreshMetrics ?? this.autoRefreshMetrics,
      refreshInterval: refreshInterval ?? this.refreshInterval,
      theme: theme ?? this.theme,
      automationEnabled: automationEnabled ?? this.automationEnabled,
      retryFailedTasks: retryFailedTasks ?? this.retryFailedTasks,
      maxRetries: maxRetries ?? this.maxRetries,
    );
  }
}
