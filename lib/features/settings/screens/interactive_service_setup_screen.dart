import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import '../../../core/services/instagram_cli_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/glassmorphism.dart';
import '../../automation/models/automation_enums.dart';
import '../../settings/models/extended_settings.dart';
import '../../settings/providers/extended_settings_provider.dart';

/// Interactive wizard-style service configuration screen
/// with step-by-step guidance and live validation
class InteractiveServiceSetupScreen extends ConsumerStatefulWidget {
  final ServiceProvider serviceType;

  const InteractiveServiceSetupScreen({
    super.key,
    required this.serviceType,
  });

  @override
  ConsumerState<InteractiveServiceSetupScreen> createState() =>
      _InteractiveServiceSetupScreenState();
}

class _InteractiveServiceSetupScreenState
    extends ConsumerState<InteractiveServiceSetupScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentStep = 0;
  bool _isLoading = false;
  bool _isTesting = false;
  bool _testPassed = false;

  // Form controllers
  final _apiKeyController = TextEditingController();
  final _apiSecretController = TextEditingController();
  final _webhookController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Validation states
  bool _apiKeyValid = false;
  bool _apiSecretValid = false;

  final _instagramCli = InstagramCliService();
  bool _isCheckingCli = false;
  bool _isLinuxCliAvailable = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() => _currentStep = _tabController.index);
    });

    if (Platform.isLinux && widget.serviceType == ServiceProvider.instagram) {
      _checkInstagramCli();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _apiKeyController.dispose();
    _apiSecretController.dispose();
    _webhookController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = _getServiceColors();

    return Scaffold(
      body: Container(
        decoration: AppTheme.backgroundGradient(isDark),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(colors),
              _buildProgressIndicator(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildWelcomeStep(),
                    _buildCredentialsStep(),
                    _buildTestConnectionStep(),
                    _buildCompletionStep(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== HEADER =====

  Widget _buildHeader(List<Color> colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const FaIcon(FontAwesomeIcons.xmark, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Setup ${widget.serviceType.label}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Step ${_currentStep + 1} of 4',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          _buildHelpButton(),
        ],
      ),
    );
  }

  Widget _buildHelpButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        onPressed: _showHelpDialog,
        icon: const FaIcon(
          FontAwesomeIcons.circleQuestion,
          color: Colors.white,
          size: 20,
        ),
        tooltip: 'Need help?',
      ),
    );
  }

  // ===== PROGRESS INDICATOR =====

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: List.generate(4, (index) {
          final isCompleted = index < _currentStep;
          final isCurrent = index == _currentStep;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 4,
                    decoration: BoxDecoration(
                      color: isCompleted || isCurrent
                          ? AppColors.primary
                          : Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (index < 3) const SizedBox(width: 8),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ===== STEP 1: WELCOME =====

  Widget _buildWelcomeStep() {
    final config = _getServiceConfig();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepIcon(FontAwesomeIcons.handshake, Colors.blue),
          const SizedBox(height: 24),
          const Text(
            'Welcome to Setup!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Let\'s configure ${widget.serviceType.label} in just a few steps.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          _buildInfoCard(
            'What you\'ll need:',
            [
              config['requirement1'] ?? 'API Key from ${widget.serviceType.label}',
              config['requirement2'] ?? 'API Secret (if applicable)',
              config['requirement3'] ?? 'About 5 minutes',
            ],
            FontAwesomeIcons.listCheck,
            Colors.green,
          ),
          const SizedBox(height: 20),
          _buildInfoCard(
            'What you\'ll get:',
            [
              config['benefit1'] ?? 'Automated posting to ${widget.serviceType.label}',
              config['benefit2'] ?? 'Real-time analytics and insights',
              config['benefit3'] ?? 'Scheduled content management',
            ],
            FontAwesomeIcons.rocket,
            Colors.purple,
          ),
          const SizedBox(height: 32),
          _buildStepButtons(
            onNext: () => _nextStep(),
            showBack: false,
          ),
        ],
      ),
    );
  }

  // ===== STEP 2: CREDENTIALS =====

  Widget _buildCredentialsStep() {
    final config = _getServiceConfig();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepIcon(FontAwesomeIcons.key, Colors.orange),
            const SizedBox(height: 24),
            const Text(
              'Enter Your Credentials',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'We need your API credentials to connect to ${widget.serviceType.label}.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            
            // How to get credentials
            _buildHowToCard(config),
            
            const SizedBox(height: 24),
            
            // API Key field
            _buildCredentialField(
              controller: _apiKeyController,
              label: config['apiKeyLabel'] ?? 'API Key',
              hint: config['apiKeyHint'] ?? 'Enter your API key',
              icon: FontAwesomeIcons.key,
              onChanged: (value) {
                setState(() {
                  _apiKeyValid = value.isNotEmpty && value.length >= 10;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'API Key is required';
                }
                if (value.length < 10) {
                  return 'API Key seems to short';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 20),
            
            // API Secret field (if needed)
            if (config['requiresSecret'] == true) ...[
              _buildCredentialField(
                controller: _apiSecretController,
                label: config['apiSecretLabel'] ?? 'API Secret',
                hint: config['apiSecretHint'] ?? 'Enter your API secret',
                icon: FontAwesomeIcons.shieldHalved,
                obscureText: true,
                onChanged: (value) {
                  setState(() {
                    _apiSecretValid = value.isNotEmpty && value.length >= 10;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'API Secret is required';
                  }
                  return null;
                },
              ),
            ],
            
            const SizedBox(height: 32),
            _buildStepButtons(
              onNext: () {
                if (_formKey.currentState!.validate()) {
                  _nextStep();
                }
              },
              onBack: () => _previousStep(),
              nextEnabled: _apiKeyValid && 
                  (config['requiresSecret'] != true || _apiSecretValid),
            ),
          ],
        ),
      ),
    );
  }

  // ===== STEP 3: TEST CONNECTION =====

  Widget _buildTestConnectionStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepIcon(
            _testPassed ? FontAwesomeIcons.circleCheck : FontAwesomeIcons.vial,
            _testPassed ? Colors.green : Colors.blue,
          ),
          const SizedBox(height: 24),
          Text(
            _testPassed ? 'Connection Successful!' : 'Test Your Connection',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _testPassed
                ? 'Great! Your credentials are working perfectly.'
                : 'Let\'s verify that your credentials are correct.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          
          if (!_testPassed) ...[
            _buildTestCard(),
          ] else ...[
            _buildSuccessCard(),
          ],
          
          const SizedBox(height: 32),

          if (Platform.isLinux && widget.serviceType == ServiceProvider.instagram)
            _buildInstagramCliTools(),

          const SizedBox(height: 32),
          _buildStepButtons(
            onNext: _testPassed ? () => _nextStep() : null,
            onBack: () => _previousStep(),
            nextEnabled: _testPassed,
          ),
        ],
      ),
    );
  }

  // ===== STEP 4: COMPLETION =====

  Widget _buildCompletionStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepIcon(FontAwesomeIcons.trophy, Colors.amber),
          const SizedBox(height: 24),
          const Text(
            'All Set!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${widget.serviceType.label} is now configured and ready to use.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          
          _buildCompletionSummary(),
          
          const SizedBox(height: 24),
          
          _buildNextStepsCard(),
          
          const SizedBox(height: 32),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleComplete,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppColors.systemGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Complete Setup',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        FaIcon(FontAwesomeIcons.check, size: 16),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ===== HELPER WIDGETS =====

  Widget _buildStepIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.3), color.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: FaIcon(
        icon,
        color: color,
        size: 40,
      ),
    );
  }

  Widget _buildInfoCard(
    String title,
    List<String> items,
    IconData icon,
    Color color,
  ) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: FaIcon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildHowToCard(Map<String, dynamic> config) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withOpacity(0.2),
            Colors.purple.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FaIcon(
                FontAwesomeIcons.lightbulb,
                color: Colors.amber,
                size: 20,
              ),
              const SizedBox(width: 12),
              const Text(
                'How to get your credentials',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            config['howToGetCredentials'] ?? 
            '1. Go to ${widget.serviceType.label} Developer Portal\n'
            '2. Create a new app or select existing one\n'
            '3. Copy the API Key and Secret\n'
            '4. Paste them below',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _openDocumentation(config['docsUrl']),
            icon: const FaIcon(FontAwesomeIcons.arrowUpRightFromSquare, size: 14),
            label: const Text('Open Documentation'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue[300],
              side: BorderSide(color: Colors.blue.withOpacity(0.5)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCredentialField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    required Function(String) onChanged,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      onChanged: onChanged,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: FaIcon(icon, color: Colors.white70, size: 18),
        suffixIcon: IconButton(
          icon: const FaIcon(FontAwesomeIcons.paste, size: 16),
          onPressed: () async {
            final data = await Clipboard.getData('text/plain');
            if (data != null) {
              controller.text = data.text ?? '';
              onChanged(controller.text);
            }
          },
          tooltip: 'Paste from clipboard',
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }

  Widget _buildTestCard() {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            if (_isTesting) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              const Text(
                'Testing connection...',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ] else ...[
              const FaIcon(
                FontAwesomeIcons.plug,
                color: Colors.white70,
                size: 48,
              ),
              const SizedBox(height: 20),
              const Text(
                'Ready to test',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Click below to verify your credentials',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _testConnection,
                icon: const FaIcon(FontAwesomeIcons.play, size: 16),
                label: const Text('Test Connection'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  backgroundColor: AppColors.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessCard() {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const FaIcon(
                FontAwesomeIcons.circleCheck,
                color: Colors.green,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Connection Successful!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your ${widget.serviceType.label} credentials are valid',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionSummary() {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                FaIcon(
                  FontAwesomeIcons.circleInfo,
                  color: Colors.blue,
                  size: 20,
                ),
                SizedBox(width: 12),
                Text(
                  'Configuration Summary',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSummaryItem(
              'Service',
              widget.serviceType.label,
              FontAwesomeIcons.server,
            ),
            const SizedBox(height: 12),
            _buildSummaryItem(
              'Status',
              'Ready to use',
              FontAwesomeIcons.circleCheck,
            ),
            const SizedBox(height: 12),
            _buildSummaryItem(
              'API Key',
              _maskApiKey(_apiKeyController.text),
              FontAwesomeIcons.key,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Row(
      children: [
        FaIcon(icon, color: Colors.white60, size: 16),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildNextStepsCard() {
    return _buildInfoCard(
      'Next Steps',
      [
        'Go to Automation to create your first task',
        'Check Analytics for insights',
        'Customize your posting schedule',
      ],
      FontAwesomeIcons.route,
      Colors.purple,
    );
  }

  Widget _buildStepButtons({
    VoidCallback? onNext,
    VoidCallback? onBack,
    bool showBack = true,
    bool nextEnabled = true,
  }) {
    return Row(
      children: [
        if (showBack) ...[
          Expanded(
            child: OutlinedButton(
              onPressed: onBack,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Colors.white30),
              ),
              child: const Text('Back'),
            ),
          ),
          const SizedBox(width: 16),
        ],
        Expanded(
          flex: showBack ? 1 : 2,
          child: ElevatedButton(
            onPressed: nextEnabled ? onNext : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppColors.primary,
            ),
            child: Text(_currentStep == 3 ? 'Complete' : 'Next'),
          ),
        ),
      ],
    );
  }

  // ===== HELPER METHODS =====

  List<Color> _getServiceColors() {
    switch (widget.serviceType) {
      case ServiceProvider.facebook:
        return [const Color(0xFF1877F2), const Color(0xFF0C66D0)];
      case ServiceProvider.instagram:
        return [const Color(0xFFF58529), const Color(0xFFDD2A7B)];
      case ServiceProvider.twitter:
        return [const Color(0xFF1DA1F2), const Color(0xFF0C85D0)];
      case ServiceProvider.linkedin:
        return [const Color(0xFF0077B5), const Color(0xFF00669C)];
      case ServiceProvider.github:
        return [const Color(0xFF24292E), const Color(0xFF1B1F23)];
      default:
        return [AppColors.primary, AppColors.primary.withOpacity(0.7)];
    }
  }

  Map<String, dynamic> _getServiceConfig() {
    // Service-specific configurations
    final configs = {
      ServiceProvider.facebook: {
        'requirement1': 'Facebook App ID',
        'requirement2': 'Facebook App Secret',
        'requirement3': 'Page Access Token',
        'benefit1': 'Post to your Facebook page automatically',
        'benefit2': 'Track engagement and insights',
        'benefit3': 'Schedule posts in advance',
        'apiKeyLabel': 'App ID',
        'apiKeyHint': 'Enter your Facebook App ID',
        'apiSecretLabel': 'App Secret',
        'apiSecretHint': 'Enter your Facebook App Secret',
        'requiresSecret': true,
        'docsUrl': 'https://developers.facebook.com/docs/pages/access-tokens',
        'howToGetCredentials':
            '1. Visit https://developers.facebook.com\n'
            '2. Create a new app or select existing\n'
            '3. Go to Settings → Basic\n'
            '4. Copy App ID and App Secret\n'
            '5. Get Page Access Token from Graph API Explorer',
      },
      ServiceProvider.instagram: {
        'requirement1': 'Instagram Business Account',
        'requirement2': 'Facebook Page linked to Instagram',
        'requirement3': 'Access Token',
        'benefit1': 'Post images and videos automatically',
        'benefit2': 'Monitor follower growth',
        'benefit3': 'Analyze post performance',
        'apiKeyLabel': 'Access Token',
        'apiKeyHint': 'Enter your Instagram Access Token',
        'requiresSecret': false,
        'docsUrl': 'https://developers.facebook.com/docs/instagram-api',
        'howToGetCredentials':
            '1. Convert Instagram to Business Account\n'
            '2. Link to a Facebook Page\n'
            '3. Visit Facebook Graph API Explorer\n'
            '4. Generate token with instagram_basic permissions\n'
            '5. Copy the Access Token',
      },
      // Add more services...
    };

    return configs[widget.serviceType] ?? {
      'requirement1': 'API Key',
      'requirement2': 'API Secret (if needed)',
      'requirement3': 'Valid account credentials',
      'benefit1': 'Automate your workflows',
      'benefit2': 'Save time and effort',
      'benefit3': 'Track your metrics',
      'apiKeyLabel': 'API Key',
      'apiKeyHint': 'Enter your API key',
      'requiresSecret': true,
      'docsUrl': null,
      'howToGetCredentials': 'Check the service documentation for details',
    };
  }

  void _nextStep() {
    if (_currentStep < 3) {
      _tabController.animateTo(_currentStep + 1);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _tabController.animateTo(_currentStep - 1);
    }
  }

  Future<void> _testConnection() async {
    setState(() => _isTesting = true);

    // Simulate API test
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isTesting = false;
        _testPassed = true;
      });
    }
  }

    Future<void> _handleComplete() async {
    setState(() => _isLoading = true);

    final apiKey = _apiKeyController.text.trim();
    final apiSecret = _apiSecretController.text.trim();
    final settings = ref.read(extendedSettingsProvider);
    final updated = _updateSettings(settings, widget.serviceType, apiKey, apiSecret);
    ref.read(extendedSettingsProvider.notifier).setSettings(updated);

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${widget.serviceType.label} configured successfully!',
          ),
          backgroundColor: AppColors.systemGreen,
        ),
      );
      Navigator.pop(context, true);
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

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            FaIcon(FontAwesomeIcons.circleQuestion, color: Colors.blue),
            SizedBox(width: 12),
            Text('Need Help?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Having trouble? Here are some resources:'),
            const SizedBox(height: 16),
            _buildHelpOption(
              'View Documentation',
              'Read our detailed setup guide',
              FontAwesomeIcons.book,
              () {
                // Open docs
              },
            ),
            _buildHelpOption(
              'Watch Tutorial',
              'Step-by-step video guide',
              FontAwesomeIcons.youtube,
              () {
                // Open video
              },
            ),
            _buildHelpOption(
              'Contact Support',
              'Get help from our team',
              FontAwesomeIcons.headset,
              () {
                // Open support
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpOption(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: FaIcon(icon, color: AppColors.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  Future<void> _openDocumentation(String? url) async {
    if (url != null) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  String _maskApiKey(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'Not set';
    final visible = trimmed.length >= 8 ? 8 : trimmed.length;
    return '${trimmed.substring(0, visible)}...';
  }

  Widget _buildInstagramCliTools() {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                FaIcon(
                  FontAwesomeIcons.terminal,
                  color: Colors.white70,
                  size: 18,
                ),
                SizedBox(width: 10),
                Text(
                  'Instagram CLI (Linux only)',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _isCheckingCli
                  ? 'Checking instagram-cli availability...'
                  : _isLinuxCliAvailable
                      ? 'instagram-cli is available on this system.'
                      : 'instagram-cli not found. Install it to use CLI tools.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                OutlinedButton.icon(
                  onPressed: _isCheckingCli ? null : _checkInstagramCli,
                  icon: const FaIcon(FontAwesomeIcons.circleCheck, size: 14),
                  label: const Text('Check CLI'),
                ),
                OutlinedButton.icon(
                  onPressed: _isLinuxCliAvailable
                      ? () => _runInstagramCli(['auth', 'whoami'])
                      : null,
                  icon: const FaIcon(FontAwesomeIcons.user, size: 14),
                  label: const Text('Whoami'),
                ),
                OutlinedButton.icon(
                  onPressed: _isLinuxCliAvailable
                      ? () => _runInstagramCli(['feed'])
                      : null,
                  icon: const FaIcon(FontAwesomeIcons.newspaper, size: 14),
                  label: const Text('Feed'),
                ),
                OutlinedButton.icon(
                  onPressed: _isLinuxCliAvailable
                      ? () => _runInstagramCli(['stories'])
                      : null,
                  icon: const FaIcon(FontAwesomeIcons.bolt, size: 14),
                  label: const Text('Stories'),
                ),
                OutlinedButton.icon(
                  onPressed: _isLinuxCliAvailable
                      ? () => _runInstagramCli(['notify'])
                      : null,
                  icon: const FaIcon(FontAwesomeIcons.bell, size: 14),
                  label: const Text('Notify'),
                ),
                OutlinedButton.icon(
                  onPressed: _isLinuxCliAvailable
                      ? () => _runInstagramCli(['config'])
                      : null,
                  icon: const FaIcon(FontAwesomeIcons.gear, size: 14),
                  label: const Text('Config'),
                ),
                OutlinedButton.icon(
                  onPressed: _isLinuxCliAvailable
                      ? () => _runInstagramCli(['auth', 'logout'])
                      : null,
                  icon: const FaIcon(FontAwesomeIcons.rightFromBracket, size: 14),
                  label: const Text('Logout'),
                ),
                OutlinedButton.icon(
                  onPressed: _isLinuxCliAvailable
                      ? _promptSwitchInstagramUser
                      : null,
                  icon: const FaIcon(FontAwesomeIcons.userGear, size: 14),
                  label: const Text('Switch User'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkInstagramCli() async {
    setState(() => _isCheckingCli = true);
    final available = await _instagramCli.isAvailable();
    if (mounted) {
      setState(() {
        _isCheckingCli = false;
        _isLinuxCliAvailable = available;
      });
    }
  }

  Future<void> _runInstagramCli(List<String> args) async {
    final result = await _instagramCli.runRaw(args);
    if (!mounted) return;

    final title = 'instagram-cli ${args.join(' ')}';
    final body = result.success
        ? (result.stdout.isNotEmpty ? result.stdout : 'Command completed.')
        : (result.stderr.isNotEmpty ? result.stderr : 'Command failed.');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(body),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _promptSwitchInstagramUser() async {
    final controller = TextEditingController();
    final username = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Switch Instagram User'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Username',
            hintText: 'e.g. your_handle',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Switch'),
          ),
        ],
      ),
    );

    if (username != null && username.isNotEmpty) {
      await _runInstagramCli(['auth', 'switch', username]);
    }
  }
}
