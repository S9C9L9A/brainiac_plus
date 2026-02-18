import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/glassmorphism.dart';
import '../../automation/models/automation_enums.dart';
import '../models/extended_settings.dart';
import '../providers/extended_settings_provider.dart';

/// Screen for configuring a specific service integration
class ServiceConfigScreen extends ConsumerStatefulWidget {
  final ServiceProvider serviceType;

  const ServiceConfigScreen({
    super.key,
    required this.serviceType,
  });

  @override
  ConsumerState<ServiceConfigScreen> createState() =>
      _ServiceConfigScreenState();
}

class _ServiceConfigScreenState extends ConsumerState<ServiceConfigScreen> {
  late TextEditingController _apiKeyController;
  late TextEditingController _apiSecretController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _apiKeyController = TextEditingController();
    _apiSecretController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = ref.read(extendedSettingsProvider);
      final values = _getExistingValues(settings, widget.serviceType);
      _apiKeyController.text = values.apiKey;
      _apiSecretController.text = values.apiSecret;
    });
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _apiSecretController.dispose();
    super.dispose();
  }

  void _handleSave() {
    setState(() => _isLoading = true);

    final apiKey = _apiKeyController.text.trim();
    final apiSecret = _apiSecretController.text.trim();

    final settings = ref.read(extendedSettingsProvider);
    final updated = _updateSettings(settings, widget.serviceType, apiKey, apiSecret);
    ref.read(extendedSettingsProvider.notifier).setSettings(updated);

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${widget.serviceType.label} configuration saved successfully!',
            ),
            backgroundColor: AppColors.systemGreen,
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.pop(context, true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: AppTheme.backgroundGradient(isDark),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildServiceInfo(),
                      const SizedBox(height: 24),
                      _buildConfigurationForm(),
                      const SizedBox(height: 24),
                      _buildActionButtons(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Configure ${widget.serviceType.label}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Set up your API credentials',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceInfo() {
    final colors = _getServiceColors();

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: colors),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                widget.serviceType.icon,
                style: const TextStyle(fontSize: 48),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.serviceType.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (widget.serviceType.supportsAPI)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.systemBlue.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'API Integration Available',
                        style: TextStyle(
                          color: AppColors.systemBlue,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigurationForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Credentials',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _apiKeyController,
          label: 'API Key',
          hint: 'Enter your API key',
          icon: Icons.vpn_key,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _apiSecretController,
          label: 'API Secret',
          hint: 'Enter your API secret',
          icon: Icons.lock,
          isSecret: true,
        ),
        const SizedBox(height: 24),
        _buildHelpSection(),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isSecret = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        GlassCard(
          child: TextField(
            controller: controller,
            obscureText: isSecret,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
              ),
              prefixIcon: Icon(
                icon,
                color: Colors.white.withValues(alpha: 0.6),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHelpSection() {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.help_outline,
                  color: AppColors.systemBlue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'How to get your credentials',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _getHelpText(),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(
                color: Colors.white,
                width: 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.systemBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : const Text('Save Configuration'),
          ),
        ),
      ],
    );
  }

  List<Color> _getServiceColors() {
    switch (widget.serviceType) {
      case ServiceProvider.instagram:
        return [const Color(0xFFE1306C), const Color(0xFFFD1D1D)];
      case ServiceProvider.facebook:
        return [const Color(0xFF1877F2), const Color(0xFF42B0FF)];
      case ServiceProvider.twitter:
        return [const Color(0xFF1DA1F2), const Color(0xFF0E71C8)];
      case ServiceProvider.linkedin:
        return [const Color(0xFF0077B5), const Color(0xFF00A0DC)];
      case ServiceProvider.youtube:
        return [const Color(0xFFFF0000), const Color(0xFFFF4444)];
      case ServiceProvider.tiktok:
        return [const Color(0xFF000000), const Color(0xFF00F2EA)];
      case ServiceProvider.notion:
        return [const Color(0xFF000000), const Color(0xFFFFFFFF)];
      case ServiceProvider.slack:
        return [const Color(0xFF4A154B), const Color(0xFFE01E5A)];
      case ServiceProvider.github:
        return [const Color(0xFF24292E), const Color(0xFF6E40C9)];
      case ServiceProvider.discord:
        return [const Color(0xFF5865F2), const Color(0xFF7289DA)];
      case ServiceProvider.telegram:
        return [const Color(0xFF0088cc), const Color(0xFF33A4DF)];
      case ServiceProvider.google:
        return [const Color(0xFF4285F4), const Color(0xFFEA4335)];
      default:
        return [Colors.purple, Colors.blue];
    }
  }

  String _getHelpText() {
    switch (widget.serviceType) {
      case ServiceProvider.github:
        return 'Visit github.com/settings/tokens to generate a personal access token. Select scopes based on your needs (repos, gists, etc.).';
      case ServiceProvider.slack:
        return 'Go to api.slack.com to create a new app. Create a bot token and add it here for authentication.';
      case ServiceProvider.notion:
        return 'Visit notion.so/my-integrations to create an integration. Copy the Internal Integration Token.';
      case ServiceProvider.twitter:
        return 'Access developer.twitter.com to create an app. Get your API key and secret from the Keys section.';
      case ServiceProvider.instagram:
        return 'Visit developers.facebook.com to create an app. Generate an Instagram Graph API token.';
      case ServiceProvider.facebook:
        return 'Visit developers.facebook.com to create an app. Get your Facebook Graph API token.';
      default:
        return 'Visit the ${widget.serviceType.label} developer portal to generate API credentials. Keep your secret safe!';
    }
  }

  _ServiceCredentials _getExistingValues(
    ExtendedAppSettings settings,
    ServiceProvider service,
  ) {
    switch (service) {
      case ServiceProvider.facebook:
        return _ServiceCredentials(
          apiKey: settings.facebookAccessToken ?? '',
          apiSecret: settings.facebookUserId ?? '',
        );
      case ServiceProvider.instagram:
        return _ServiceCredentials(
          apiKey: settings.instagramAccessToken ?? '',
          apiSecret: settings.instagramUserId ?? '',
        );
      case ServiceProvider.twitter:
        return _ServiceCredentials(
          apiKey: settings.twitterApiKey ?? '',
          apiSecret: settings.twitterApiSecret ?? '',
        );
      case ServiceProvider.tiktok:
        return _ServiceCredentials(
          apiKey: settings.tiktokAccessToken ?? '',
          apiSecret: '',
        );
      case ServiceProvider.linkedin:
        return _ServiceCredentials(
          apiKey: settings.linkedinAccessToken ?? '',
          apiSecret: '',
        );
      case ServiceProvider.youtube:
        return _ServiceCredentials(
          apiKey: settings.youtubeApiKey ?? '',
          apiSecret: settings.youtubeAccessToken ?? '',
        );
      case ServiceProvider.notion:
        return _ServiceCredentials(
          apiKey: settings.notionApiKey ?? '',
          apiSecret: settings.notionWorkspaceId ?? '',
        );
      case ServiceProvider.google:
        return _ServiceCredentials(
          apiKey: settings.googleAccessToken ?? '',
          apiSecret: settings.googleRefreshToken ?? '',
        );
      case ServiceProvider.slack:
        return _ServiceCredentials(
          apiKey: settings.slackBotToken ?? '',
          apiSecret: settings.slackWorkspaceId ?? '',
        );
      case ServiceProvider.discord:
        return _ServiceCredentials(
          apiKey: settings.discordBotToken ?? '',
          apiSecret: settings.discordServerId ?? '',
        );
      case ServiceProvider.telegram:
        return _ServiceCredentials(
          apiKey: settings.telegramBotToken ?? '',
          apiSecret: settings.telegramChatId ?? '',
        );
      case ServiceProvider.github:
        return _ServiceCredentials(
          apiKey: settings.githubAccessToken ?? '',
          apiSecret: settings.githubUsername ?? '',
        );
      case ServiceProvider.custom:
        return _ServiceCredentials(apiKey: '', apiSecret: '');
    }
  }

  ExtendedAppSettings _updateSettings(
    ExtendedAppSettings settings,
    ServiceProvider service,
    String apiKey,
    String apiSecret,
  ) {
    switch (service) {
      case ServiceProvider.facebook:
        return settings.copyWith(
          facebookAccessToken: apiKey,
          facebookUserId: apiSecret,
        );
      case ServiceProvider.instagram:
        return settings.copyWith(
          instagramAccessToken: apiKey,
          instagramUserId: apiSecret,
        );
      case ServiceProvider.twitter:
        return settings.copyWith(
          twitterApiKey: apiKey,
          twitterApiSecret: apiSecret,
        );
      case ServiceProvider.tiktok:
        return settings.copyWith(tiktokAccessToken: apiKey);
      case ServiceProvider.linkedin:
        return settings.copyWith(linkedinAccessToken: apiKey);
      case ServiceProvider.youtube:
        return settings.copyWith(
          youtubeApiKey: apiKey,
          youtubeAccessToken: apiSecret,
        );
      case ServiceProvider.notion:
        return settings.copyWith(
          notionApiKey: apiKey,
          notionWorkspaceId: apiSecret,
        );
      case ServiceProvider.google:
        return settings.copyWith(
          googleAccessToken: apiKey,
          googleRefreshToken: apiSecret,
        );
      case ServiceProvider.slack:
        return settings.copyWith(
          slackBotToken: apiKey,
          slackWorkspaceId: apiSecret,
        );
      case ServiceProvider.discord:
        return settings.copyWith(
          discordBotToken: apiKey,
          discordServerId: apiSecret,
        );
      case ServiceProvider.telegram:
        return settings.copyWith(
          telegramBotToken: apiKey,
          telegramChatId: apiSecret,
        );
      case ServiceProvider.github:
        return settings.copyWith(
          githubAccessToken: apiKey,
          githubUsername: apiSecret,
        );
      case ServiceProvider.custom:
        return settings;
    }
  }
}

class _ServiceCredentials {
  final String apiKey;
  final String apiSecret;

  const _ServiceCredentials({
    required this.apiKey,
    required this.apiSecret,
  });
}