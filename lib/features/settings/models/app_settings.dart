/// App Settings Model
class AppSettings {
  // API Keys
  final String? higgsfieldApiKey;
  final String? openaiApiKey;
  
  // Instagram
  final String? instagramAccessToken;
  final String? instagramUserId;
  final String? instagramUsername;
  final DateTime? instagramTokenExpiry;
  
  // Preferences
  final bool notificationsEnabled;
  final bool autoRefreshMetrics;
  final int refreshInterval; // seconds
  final String theme; // 'dark', 'light', 'system'
  
  // Automation
  final bool automationEnabled;
  final bool retryFailedTasks;
  final int maxRetries;

  AppSettings({
    this.higgsfieldApiKey,
    this.openaiApiKey,
    this.instagramAccessToken,
    this.instagramUserId,
    this.instagramUsername,
    this.instagramTokenExpiry,
    this.notificationsEnabled = true,
    this.autoRefreshMetrics = true,
    this.refreshInterval = 5,
    this.theme = 'system',
    this.automationEnabled = true,
    this.retryFailedTasks = true,
    this.maxRetries = 3,
  });

  Map<String, dynamic> toMap() {
    return {
      'higgsfield_api_key': higgsfieldApiKey,
      'openai_api_key': openaiApiKey,
      'instagram_access_token': instagramAccessToken,
      'instagram_user_id': instagramUserId,
      'instagram_username': instagramUsername,
      'instagram_token_expiry': instagramTokenExpiry?.toIso8601String(),
      'notifications_enabled': notificationsEnabled ? 1 : 0,
      'auto_refresh_metrics': autoRefreshMetrics ? 1 : 0,
      'refresh_interval': refreshInterval,
      'theme': theme,
      'automation_enabled': automationEnabled ? 1 : 0,
      'retry_failed_tasks': retryFailedTasks ? 1 : 0,
      'max_retries': maxRetries,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      higgsfieldApiKey: map['higgsfield_api_key'] as String?,
      openaiApiKey: map['openai_api_key'] as String?,
      instagramAccessToken: map['instagram_access_token'] as String?,
      instagramUserId: map['instagram_user_id'] as String?,
      instagramUsername: map['instagram_username'] as String?,
      instagramTokenExpiry: map['instagram_token_expiry'] != null
          ? DateTime.parse(map['instagram_token_expiry'] as String)
          : null,
      notificationsEnabled: map['notifications_enabled'] == 1,
      autoRefreshMetrics: map['auto_refresh_metrics'] == 1,
      refreshInterval: map['refresh_interval'] as int? ?? 5,
      theme: map['theme'] as String? ?? 'system',
      automationEnabled: map['automation_enabled'] == 1,
      retryFailedTasks: map['retry_failed_tasks'] == 1,
      maxRetries: map['max_retries'] as int? ?? 3,
    );
  }

  AppSettings copyWith({
    String? higgsfieldApiKey,
    String? openaiApiKey,
    String? instagramAccessToken,
    String? instagramUserId,
    String? instagramUsername,
    DateTime? instagramTokenExpiry,
    bool? notificationsEnabled,
    bool? autoRefreshMetrics,
    int? refreshInterval,
    String? theme,
    bool? automationEnabled,
    bool? retryFailedTasks,
    int? maxRetries,
  }) {
    return AppSettings(
      higgsfieldApiKey: higgsfieldApiKey ?? this.higgsfieldApiKey,
      openaiApiKey: openaiApiKey ?? this.openaiApiKey,
      instagramAccessToken: instagramAccessToken ?? this.instagramAccessToken,
      instagramUserId: instagramUserId ?? this.instagramUserId,
      instagramUsername: instagramUsername ?? this.instagramUsername,
      instagramTokenExpiry: instagramTokenExpiry ?? this.instagramTokenExpiry,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      autoRefreshMetrics: autoRefreshMetrics ?? this.autoRefreshMetrics,
      refreshInterval: refreshInterval ?? this.refreshInterval,
      theme: theme ?? this.theme,
      automationEnabled: automationEnabled ?? this.automationEnabled,
      retryFailedTasks: retryFailedTasks ?? this.retryFailedTasks,
      maxRetries: maxRetries ?? this.maxRetries,
    );
  }

  // Helper methods
  bool get hasHiggsfieldKey => higgsfieldApiKey != null && higgsfieldApiKey!.isNotEmpty;
  bool get hasInstagramAuth => instagramAccessToken != null && instagramUserId != null;
  bool get isInstagramTokenExpired => 
      instagramTokenExpiry != null && DateTime.now().isAfter(instagramTokenExpiry!);
  bool get needsInstagramRefresh => 
      hasInstagramAuth && (isInstagramTokenExpired || instagramTokenExpiry == null);
}
