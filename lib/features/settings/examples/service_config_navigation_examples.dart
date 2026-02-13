/// Navigation Usage Examples for Service Configuration
/// 
/// This file demonstrates how to navigate to the service configuration screen
/// from various places in the application.

import 'package:flutter/material.dart';
import '../../../routes/app_routes.dart';
import '../../automation/models/automation_enums.dart';

class ServiceConfigNavigationExamples {
  /// Example 1: Navigate from Settings screen - Social Media Service
  /// Called when user taps on Instagram, Facebook, Twitter card
  static void navigateToServiceConfig_SocialMedia(
    BuildContext context,
    ServiceProvider service,
  ) {
    AppRoutes.navigateTo(
      context,
      AppRoutes.serviceConfig,
      arguments: service,
    );
    // Result: Navigates to ServiceConfigScreen with Instagram/Facebook/Twitter config
  }

  /// Example 2: Navigate to AI Service Configuration
  /// Called when user taps "Setup" or "Edit" for OpenAI, Higgsfield, Ollama
  static void navigateToServiceConfig_AIService(BuildContext context) {
    AppRoutes.navigateTo(
      context,
      AppRoutes.serviceConfig,
      arguments: ServiceProvider.custom, // AI services use custom provider
    );
    // Result: Navigates to ServiceConfigScreen with custom AI service config
  }

  /// Example 3: Navigate with response handling
  /// Called when you want to wait for configuration result
  static Future<bool?> navigateToServiceConfigWithResult(
    BuildContext context,
    ServiceProvider service,
  ) async {
    final result = await AppRoutes.navigateTo<bool>(
      context,
      AppRoutes.serviceConfig,
      arguments: service,
    );
    
    if (result == true) {
      print('Service configured successfully: $service');
      // Update UI, refresh data, etc.
    }
    
    return result;
  }

  /// Example 4: Navigate to GitHub configuration
  static void configureGitHub(BuildContext context) {
    AppRoutes.navigateTo(
      context,
      AppRoutes.serviceConfig,
      arguments: ServiceProvider.github,
    );
    // Result: Shows GitHub-specific help text and branding
  }

  /// Example 5: Navigate to Slack configuration
  static void configureSlack(BuildContext context) {
    AppRoutes.navigateTo(
      context,
      AppRoutes.serviceConfig,
      arguments: ServiceProvider.slack,
    );
    // Result: Shows Slack-specific help text and branding
  }

  /// Example 6: Navigate to Notion configuration
  static void configureNotion(BuildContext context) {
    AppRoutes.navigateTo(
      context,
      AppRoutes.serviceConfig,
      arguments: ServiceProvider.notion,
    );
    // Result: Shows Notion-specific help text and branding
  }

  /// Example 7: Navigate from automation flow
  /// When creating/editing automation, user needs to configure required service
  static void configureServiceForAutomation(
    BuildContext context,
    ServiceProvider requiredService,
  ) {
    AppRoutes.navigateTo(
      context,
      AppRoutes.serviceConfig,
      arguments: requiredService,
    );
    // Result: User configures service, then returns to automation setup
  }

  /// Example 8: Navigate with inline error handling
  static void navigateToServiceConfigSafe(
    BuildContext context,
    ServiceProvider? service,
  ) {
    if (service == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Service type is required')),
      );
      return;
    }

    try {
      AppRoutes.navigateTo(
        context,
        AppRoutes.serviceConfig,
        arguments: service,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Navigation error: $e')),
      );
    }
  }
}

/// Usage in Widget
class ServiceConfigurationExample extends StatelessWidget {
  const ServiceConfigurationExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Configuration Examples'),
      ),
      body: ListView(
        children: [
          // Example 1: Service card tap handler
          ListTile(
            title: const Text('Configure Instagram'),
            onTap: () => ServiceConfigNavigationExamples
                .navigateToServiceConfig_SocialMedia(
              context,
              ServiceProvider.instagram,
            ),
          ),

          // Example 2: AI service setup
          ListTile(
            title: const Text('Setup OpenAI'),
            onTap: () =>
                ServiceConfigNavigationExamples.navigateToServiceConfig_AIService(
              context,
            ),
          ),

          // Example 3: With result handling
          ListTile(
            title: const Text('Configure GitHub (with result)'),
            onTap: () async {
              final result = await ServiceConfigNavigationExamples
                  .navigateToServiceConfigWithResult(
                context,
                ServiceProvider.github,
              );
              if (result == true) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('GitHub configured successfully!'),
                    ),
                  );
                }
              }
            },
          ),

          // Example 4: Multiple services
          ListTile(
            title: const Text('Configure Slack'),
            onTap: () =>
                ServiceConfigNavigationExamples.configureSlack(context),
          ),
          ListTile(
            title: const Text('Configure Notion'),
            onTap: () =>
                ServiceConfigNavigationExamples.configureNotion(context),
          ),

          // Example 5: Safe navigation with null check
          ListTile(
            title: const Text('Safe Navigation'),
            onTap: () =>
                ServiceConfigNavigationExamples.navigateToServiceConfigSafe(
              context,
              ServiceProvider.twitter,
            ),
          ),
        ],
      ),
    );
  }
}

/// Integration pattern for automation setup
class AutomationSetupIntegrationExample extends StatefulWidget {
  const AutomationSetupIntegrationExample({super.key});

  @override
  State<AutomationSetupIntegrationExample> createState() =>
      _AutomationSetupIntegrationExampleState();
}

class _AutomationSetupIntegrationExampleState
    extends State<AutomationSetupIntegrationExample> {
  ServiceProvider? _selectedService;
  bool _serviceConfigured = false;

  void _setupRequiredService() async {
    // Get the required service for this automation
    final requiredService = ServiceProvider.github;

    // Navigate to configuration
    final configured = await AppRoutes.navigateTo<bool>(
      context,
      AppRoutes.serviceConfig,
      arguments: requiredService,
    );

    if (configured == true) {
      setState(() {
        _selectedService = requiredService;
        _serviceConfigured = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Automation'),
      ),
      body: Column(
        children: [
          Text('Required Service: ${_selectedService?.label ?? "None"}'),
          if (_serviceConfigured)
            const Text('✅ Service configured')
          else
            ElevatedButton(
              onPressed: _setupRequiredService,
              child: const Text('Setup Service'),
            ),
        ],
      ),
    );
  }
}