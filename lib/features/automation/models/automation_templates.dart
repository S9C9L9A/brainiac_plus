import 'automation.dart';
import 'automation_enums.dart';

/// Automation template library with pre-configured automations
class AutomationTemplates {
  static final List<Automation> templates = [
    // ===== SOCIAL MEDIA =====
    _createTemplate(
      id: 'tmpl_instagram_daily_post',
      name: 'Daily Instagram Post',
      description: 'Automatically post to Instagram daily with AI-generated content',
      category: AutomationCategory.socialMedia,
      service: ServiceProvider.instagram,
      cronSchedule: '0 18 * * *', // 6 PM daily
      tags: ['instagram', 'ai', 'content', 'daily'],
    ),

    _createTemplate(
      id: 'tmpl_instagram_story',
      name: 'Instagram Story Automation',
      description: 'Post engaging stories multiple times per day',
      category: AutomationCategory.socialMedia,
      service: ServiceProvider.instagram,
      cronSchedule: '0 9,15,21 * * *', // 9 AM, 3 PM, 9 PM
      tags: ['instagram', 'story', 'engagement'],
    ),

    _createTemplate(
      id: 'tmpl_twitter_thread',
      name: 'Twitter Thread Publisher',
      description: 'Create and publish Twitter threads from blog posts',
      category: AutomationCategory.socialMedia,
      service: ServiceProvider.twitter,
      tags: ['twitter', 'thread', 'content'],
    ),

    _createTemplate(
      id: 'tmpl_linkedin_article',
      name: 'LinkedIn Article Sync',
      description: 'Automatically post professional content to LinkedIn',
      category: AutomationCategory.socialMedia,
      service: ServiceProvider.linkedin,
      cronSchedule: '0 10 * * 1,3,5', // Mon, Wed, Fri at 10 AM
      tags: ['linkedin', 'article', 'professional'],
    ),

    _createTemplate(
      id: 'tmpl_cross_post',
      name: 'Cross-Platform Posting',
      description: 'Post the same content to Instagram, Facebook, Twitter, and LinkedIn',
      category: AutomationCategory.socialMedia,
      service: ServiceProvider.custom,
      tags: ['cross-post', 'multi-platform'],
    ),

    // ===== PRODUCTIVITY =====
    _createTemplate(
      id: 'tmpl_gmail_to_notion',
      name: 'Gmail to Notion',
      description: 'Save important emails to Notion database',
      category: AutomationCategory.productivity,
      service: ServiceProvider.google,
      tags: ['gmail', 'notion', 'email', 'organization'],
    ),

    _createTemplate(
      id: 'tmpl_calendar_sync',
      name: 'Calendar Event Creator',
      description: 'Create Google Calendar events from emails or tasks',
      category: AutomationCategory.productivity,
      service: ServiceProvider.google,
      tags: ['calendar', 'scheduling', 'productivity'],
    ),

    _createTemplate(
      id: 'tmpl_task_reminder',
      name: 'Smart Task Reminders',
      description: 'Get reminders for upcoming tasks and deadlines',
      category: AutomationCategory.productivity,
      service: ServiceProvider.notion,
      cronSchedule: '0 8 * * *', // 8 AM daily
      tags: ['tasks', 'reminders', 'productivity'],
    ),

    _createTemplate(
      id: 'tmpl_file_backup',
      name: 'Auto File Backup to Drive',
      description: 'Automatically backup files to Google Drive',
      category: AutomationCategory.productivity,
      service: ServiceProvider.google,
      cronSchedule: '0 2 * * *', // 2 AM daily
      tags: ['backup', 'drive', 'files'],
    ),

    // ===== COMMUNICATION =====
    _createTemplate(
      id: 'tmpl_slack_digest',
      name: 'Daily Slack Digest',
      description: 'Get a summary of important Slack messages',
      category: AutomationCategory.communication,
      service: ServiceProvider.slack,
      cronSchedule: '0 17 * * 1-5', // 5 PM weekdays
      tags: ['slack', 'digest', 'summary'],
    ),

    _createTemplate(
      id: 'tmpl_auto_reply',
      name: 'Auto-reply Manager',
      description: 'Send automatic replies to emails and messages',
      category: AutomationCategory.communication,
      service: ServiceProvider.google,
      tags: ['email', 'auto-reply', 'communication'],
    ),

    _createTemplate(
      id: 'tmpl_telegram_alerts',
      name: 'Telegram Alert System',
      description: 'Get notifications for important events via Telegram',
      category: AutomationCategory.communication,
      service: ServiceProvider.telegram,
      tags: ['telegram', 'alerts', 'notifications'],
    ),

    // ===== DATA SYNC =====
    _createTemplate(
      id: 'tmpl_sheets_logger',
      name: 'Google Sheets Logger',
      description: 'Log data automatically to Google Sheets',
      category: AutomationCategory.dataSync,
      service: ServiceProvider.google,
      tags: ['sheets', 'logging', 'data'],
    ),

    _createTemplate(
      id: 'tmpl_notion_database_sync',
      name: 'Notion Database Sync',
      description: 'Sync data between multiple Notion databases',
      category: AutomationCategory.dataSync,
      service: ServiceProvider.notion,
      cronSchedule: '*/30 * * * *', // Every 30 minutes
      tags: ['notion', 'sync', 'database'],
    ),

    _createTemplate(
      id: 'tmpl_csv_import',
      name: 'CSV Auto-import',
      description: 'Import CSV files automatically to database',
      category: AutomationCategory.dataSync,
      service: ServiceProvider.custom,
      tags: ['csv', 'import', 'data'],
    ),

    // ===== MONITORING =====
    _createTemplate(
      id: 'tmpl_website_monitor',
      name: 'Website Uptime Monitor',
      description: 'Monitor website uptime and get alerts',
      category: AutomationCategory.monitoring,
      service: ServiceProvider.custom,
      cronSchedule: '*/5 * * * *', // Every 5 minutes
      tags: ['monitoring', 'uptime', 'alerts'],
    ),

    _createTemplate(
      id: 'tmpl_social_stats',
      name: 'Social Media Stats Tracker',
      description: 'Track follower growth and engagement metrics',
      category: AutomationCategory.monitoring,
      service: ServiceProvider.custom,
      cronSchedule: '0 0 * * *', // Midnight daily
      tags: ['analytics', 'social-media', 'stats'],
    ),

    // ===== REPORTING =====
    _createTemplate(
      id: 'tmpl_weekly_report',
      name: 'Weekly Summary Report',
      description: 'Generate and email weekly activity report',
      category: AutomationCategory.reporting,
      service: ServiceProvider.google,
      cronSchedule: '0 9 * * 1', // Monday 9 AM
      tags: ['report', 'weekly', 'summary'],
    ),

    _createTemplate(
      id: 'tmpl_analytics_dashboard',
      name: 'Analytics Dashboard Update',
      description: 'Update analytics dashboard with latest data',
      category: AutomationCategory.reporting,
      service: ServiceProvider.google,
      cronSchedule: '0 */6 * * *', // Every 6 hours
      tags: ['analytics', 'dashboard', 'reporting'],
    ),

    // ===== MARKETING =====
    _createTemplate(
      id: 'tmpl_email_campaign',
      name: 'Automated Email Campaign',
      description: 'Send scheduled marketing emails',
      category: AutomationCategory.marketing,
      service: ServiceProvider.google,
      tags: ['email', 'marketing', 'campaign'],
    ),

    _createTemplate(
      id: 'tmpl_content_curation',
      name: 'Content Curation Bot',
      description: 'Find and share relevant content automatically',
      category: AutomationCategory.marketing,
      service: ServiceProvider.custom,
      cronSchedule: '0 10,16 * * *', // 10 AM and 4 PM
      tags: ['content', 'curation', 'marketing'],
    ),

    // ===== DEVELOPMENT =====
    _createTemplate(
      id: 'tmpl_github_backup',
      name: 'GitHub Repo Backup',
      description: 'Backup GitHub repositories automatically',
      category: AutomationCategory.development,
      service: ServiceProvider.github,
      cronSchedule: '0 3 * * 0', // Sunday 3 AM
      tags: ['github', 'backup', 'development'],
    ),

    _createTemplate(
      id: 'tmpl_deploy_notify',
      name: 'Deployment Notifications',
      description: 'Get notified about deployments and builds',
      category: AutomationCategory.development,
      service: ServiceProvider.github,
      tags: ['deployment', 'notifications', 'ci-cd'],
    ),
  ];

  static Automation _createTemplate({
    required String id,
    required String name,
    required String description,
    required AutomationCategory category,
    required ServiceProvider service,
    String? cronSchedule,
    List<String> tags = const [],
  }) {
    return Automation(
      id: id,
      name: name,
      description: description,
      category: category,
      service: service,
      preferredMode: AutomationMode.hybrid,
      triggerType: cronSchedule != null ? TriggerType.scheduled : TriggerType.manual,
      status: AutomationStatus.idle,
      cronSchedule: cronSchedule,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isTemplate: true,
      tags: tags,
    );
  }

  static List<Automation> getByCategory(AutomationCategory category) {
    return templates.where((t) => t.category == category).toList();
  }

  static List<Automation> getByService(ServiceProvider service) {
    return templates.where((t) => t.service == service).toList();
  }

  static List<Automation> searchTemplates(String query) {
    final lowerQuery = query.toLowerCase();
    return templates.where((t) {
      return t.name.toLowerCase().contains(lowerQuery) ||
          t.description.toLowerCase().contains(lowerQuery) ||
          t.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  static Automation? getTemplateById(String id) {
    try {
      return templates.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }
}
