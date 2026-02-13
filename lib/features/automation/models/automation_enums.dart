/// Execution mode for automation
enum AutomationMode {
  api,      // Use official APIs
  browser,  // Browser automation (Linux/Windows/macOS only)
  app,      // App automation via ADB/Intents (Android only)
  hybrid,   // Try API first, fallback to browser/app
}

/// Automation execution status
enum AutomationStatus {
  idle,
  running,
  paused,
  completed,
  failed,
  scheduled,
}

/// Service provider type
enum ServiceProvider {
  instagram,
  facebook,
  twitter,
  linkedin,
  google,
  notion,
  github,
  slack,
  discord,
  telegram,
  tiktok,
  youtube,
  custom,
}

/// Automation trigger type
enum TriggerType {
  manual,     // User-initiated
  scheduled,  // Time-based (cron)
  event,      // Event-driven (webhook, file change, etc.)
  condition,  // Condition-based (if X then Y)
}

/// Automation category
enum AutomationCategory {
  socialMedia,
  productivity,
  communication,
  dataSync,
  monitoring,
  reporting,
  marketing,
  development,
  custom,
}

extension AutomationModeExtension on AutomationMode {
  String get label {
    switch (this) {
      case AutomationMode.api:
        return 'API';
      case AutomationMode.browser:
        return 'Browser';
      case AutomationMode.app:
        return 'App';
      case AutomationMode.hybrid:
        return 'Hybrid';
    }
  }

  String get icon {
    switch (this) {
      case AutomationMode.api:
        return '🔌';
      case AutomationMode.browser:
        return '🌐';
      case AutomationMode.app:
        return '📱';
      case AutomationMode.hybrid:
        return '⚡';
    }
  }
}

extension AutomationStatusExtension on AutomationStatus {
  String get label {
    switch (this) {
      case AutomationStatus.idle:
        return 'Idle';
      case AutomationStatus.running:
        return 'Running';
      case AutomationStatus.paused:
        return 'Paused';
      case AutomationStatus.completed:
        return 'Completed';
      case AutomationStatus.failed:
        return 'Failed';
      case AutomationStatus.scheduled:
        return 'Scheduled';
    }
  }

  String get icon {
    switch (this) {
      case AutomationStatus.idle:
        return '⚪';
      case AutomationStatus.running:
        return '🟢';
      case AutomationStatus.paused:
        return '🟡';
      case AutomationStatus.completed:
        return '✅';
      case AutomationStatus.failed:
        return '🔴';
      case AutomationStatus.scheduled:
        return '⏰';
    }
  }
}

extension ServiceProviderExtension on ServiceProvider {
  String get label {
    switch (this) {
      case ServiceProvider.instagram:
        return 'Instagram';
      case ServiceProvider.facebook:
        return 'Facebook';
      case ServiceProvider.twitter:
        return 'Twitter';
      case ServiceProvider.linkedin:
        return 'LinkedIn';
      case ServiceProvider.google:
        return 'Google';
      case ServiceProvider.notion:
        return 'Notion';
      case ServiceProvider.github:
        return 'GitHub';
      case ServiceProvider.slack:
        return 'Slack';
      case ServiceProvider.discord:
        return 'Discord';
      case ServiceProvider.telegram:
        return 'Telegram';
      case ServiceProvider.tiktok:
        return 'TikTok';
      case ServiceProvider.youtube:
        return 'YouTube';
      case ServiceProvider.custom:
        return 'Custom';
    }
  }

  String get icon {
    switch (this) {
      case ServiceProvider.instagram:
        return '📸';
      case ServiceProvider.facebook:
        return '👥';
      case ServiceProvider.twitter:
        return '🐦';
      case ServiceProvider.linkedin:
        return '💼';
      case ServiceProvider.google:
        return '🔍';
      case ServiceProvider.notion:
        return '📝';
      case ServiceProvider.github:
        return '🐙';
      case ServiceProvider.slack:
        return '💬';
      case ServiceProvider.discord:
        return '🎮';
      case ServiceProvider.telegram:
        return '✈️';
      case ServiceProvider.tiktok:
        return '🎵';
      case ServiceProvider.youtube:
        return '▶️';
      case ServiceProvider.custom:
        return '⚙️';
    }
  }

  bool get supportsAPI {
    switch (this) {
      case ServiceProvider.instagram:
      case ServiceProvider.facebook:
      case ServiceProvider.twitter:
      case ServiceProvider.google:
      case ServiceProvider.notion:
      case ServiceProvider.github:
      case ServiceProvider.slack:
      case ServiceProvider.youtube:
        return true;
      default:
        return false;
    }
  }

  bool get supportsBrowser {
    return true; // All services support browser automation
  }
}

extension AutomationCategoryExtension on AutomationCategory {
  String get label {
    switch (this) {
      case AutomationCategory.socialMedia:
        return 'Social Media';
      case AutomationCategory.productivity:
        return 'Productivity';
      case AutomationCategory.communication:
        return 'Communication';
      case AutomationCategory.dataSync:
        return 'Data Sync';
      case AutomationCategory.monitoring:
        return 'Monitoring';
      case AutomationCategory.reporting:
        return 'Reporting';
      case AutomationCategory.marketing:
        return 'Marketing';
      case AutomationCategory.development:
        return 'Development';
      case AutomationCategory.custom:
        return 'Custom';
    }
  }

  String get icon {
    switch (this) {
      case AutomationCategory.socialMedia:
        return '📱';
      case AutomationCategory.productivity:
        return '✅';
      case AutomationCategory.communication:
        return '💬';
      case AutomationCategory.dataSync:
        return '🔄';
      case AutomationCategory.monitoring:
        return '📊';
      case AutomationCategory.reporting:
        return '📈';
      case AutomationCategory.marketing:
        return '📣';
      case AutomationCategory.development:
        return '💻';
      case AutomationCategory.custom:
        return '⚙️';
    }
  }
}
