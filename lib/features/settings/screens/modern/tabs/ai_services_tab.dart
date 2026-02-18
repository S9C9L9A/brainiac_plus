import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../../../../core/theme/colors.dart';
import '../../../../../core/theme/glassmorphism.dart';
import '../../../../../routes/app_routes.dart';
import '../../../../automation/models/automation_enums.dart';
import '../../../../dashboard/dashboard_screen.dart';
import '../../../providers/extended_settings_provider.dart';
import '../../../models/extended_settings.dart';
import '../../../../../core/services/local_ai_installer.dart';

/// AI Services Tab
class AIServicesTab extends ConsumerStatefulWidget {
  const AIServicesTab({super.key});

  @override
  ConsumerState<AIServicesTab> createState() => _AIServicesTabState();
}

class _AIServicesTabState extends ConsumerState<AIServicesTab> {
  final _installer = const LocalAiInstaller();
  final _modelController = TextEditingController();
  final _modelsPathController = TextEditingController();
  bool _isInstalling = false;
  bool _isDownloading = false;
  String? _log;

  @override
  void dispose() {
    _modelController.dispose();
    _modelsPathController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = ref.read(extendedSettingsProvider);

    if (_modelController.text.isEmpty) {
      _modelController.text =
          settings.ollamaModelName ?? 'llama3.1:8b';
    }

    if (_modelsPathController.text.isEmpty) {
      final baseDir = Directory.current.path;
      _modelsPathController.text =
          settings.ollamaModelsPath ?? '$baseDir/ai_models/ollama';
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(extendedSettingsProvider);
    final isLinux = defaultTargetPlatform == TargetPlatform.linux;
    final isAndroid = defaultTargetPlatform == TargetPlatform.android;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, kBottomNavHeight),
      children: _buildPlatformCards(
        context: context,
        settings: settings,
        isLinux: isLinux,
        isAndroid: isAndroid,
      ),
    );
  }

  List<Widget> _buildPlatformCards({
    required BuildContext context,
    required ExtendedAppSettings settings,
    required bool isLinux,
    required bool isAndroid,
  }) {
    final cards = <Widget>[];

    cards.add(
      _buildAIServiceCard(
        context: context,
        title: 'OpenAI',
        icon: '🤖',
        description: isAndroid
            ? 'API key required for mobile'
            : 'Cloud models via API key',
        isConnected: settings.hasOpenAIKey,
        gradient: [const Color(0xFF10A37F), const Color(0xFF1A7F64)],
        actionLabel: settings.hasOpenAIKey ? 'Edit' : 'Setup',
      ),
    );
    cards.add(const SizedBox(height: 12));

    cards.add(
      _buildAIServiceCard(
        context: context,
        title: 'Higgsfield',
        icon: '🎬',
        description: isAndroid
            ? 'API key required for mobile'
            : 'AI video generation via API',
        isConnected: settings.hasHiggsfieldKey,
        gradient: [Colors.purple, Colors.blue],
        actionLabel: settings.hasHiggsfieldKey ? 'Edit' : 'Setup',
      ),
    );

    if (isLinux) {
      cards.add(const SizedBox(height: 16));
      cards.add(_buildLocalLinuxSetup(settings));
    }

    if (isAndroid) {
      cards.add(const SizedBox(height: 16));
      cards.add(
        GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: const [
                Icon(Icons.info_outline, color: Colors.white70, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'On Android use API keys; local model downloads are not supported.',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_log != null && _log!.trim().isNotEmpty) {
      cards.add(const SizedBox(height: 16));
      cards.add(_buildLogPanel());
    }

    return cards;
  }

  Widget _buildLocalLinuxSetup(ExtendedAppSettings settings) {
    final isConfigured = settings.hasOllamaEndpoint &&
        settings.hasOllamaModelName &&
        settings.hasOllamaModelsPath;

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Local AI (Ollama)',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isConfigured
                  ? 'Local runtime configured'
                  : 'Install locally and download a model into this project',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Models directory',
              controller: _modelsPathController,
              hintText: '/path/to/project/ai_models/ollama',
            ),
            const SizedBox(height: 12),
            _buildTextField(
              label: 'Model name',
              controller: _modelController,
              hintText: 'llama3.1:8b',
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _isInstalling ? null : _installOllama,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.systemBlue,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(_isInstalling ? 'Installing...' : 'Install'),
                ),
                OutlinedButton(
                  onPressed: _isInstalling
                      ? null
                      : () => _installOllama(
                            method: LocalAiInstallMethod.snap,
                          ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Install via snap'),
                ),
                ElevatedButton(
                  onPressed: _isDownloading ? null : _downloadModel,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.systemGreen,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(_isDownloading ? 'Downloading...' : 'Download model'),
                ),
                OutlinedButton(
                  onPressed: _saveLocalConfig,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save config'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isConfigured
                        ? AppColors.systemGreen
                        : Colors.white38,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isConfigured ? 'Configured' : 'Not configured',
                  style: TextStyle(
                    color: isConfigured
                        ? AppColors.systemGreen
                        : Colors.white60,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.08),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogPanel() {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Installer log',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            SelectableText(
              _log ?? '',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _installOllama({
    LocalAiInstallMethod method = LocalAiInstallMethod.script,
  }) async {
    setState(() {
      _isInstalling = true;
      _log = 'Installing Ollama...';
    });

    final result = await _installer.installOllama(method: method);

    setState(() {
      _isInstalling = false;
      _log = result.output.isEmpty
          ? 'Ollama install finished with code ${result.exitCode}.'
          : result.output;
    });
  }

  Future<void> _downloadModel() async {
    final model = _modelController.text.trim();
    final path = _modelsPathController.text.trim();

    if (model.isEmpty || path.isEmpty) {
      setState(() {
        _log = 'Model name and models directory are required.';
      });
      return;
    }

    setState(() {
      _isDownloading = true;
      _log = 'Downloading model $model to $path...';
    });

    await Directory(path).create(recursive: true);
    final result = await _installer.pullModel(model: model, modelsDir: path);

    setState(() {
      _isDownloading = false;
      _log = result.output.isEmpty
          ? 'Model download finished with code ${result.exitCode}.'
          : result.output;
    });
  }

  void _saveLocalConfig() {
    final model = _modelController.text.trim();
    final path = _modelsPathController.text.trim();

    ref.read(extendedSettingsProvider.notifier).setSettings(
          ref.read(extendedSettingsProvider).copyWith(
                ollamaEndpoint: 'http://localhost:11434',
                ollamaModelName: model.isEmpty ? null : model,
                ollamaModelsPath: path.isEmpty ? null : path,
              ),
        );

    setState(() {
      _log = 'Local AI configuration saved.';
    });
  }

  Widget _buildAIServiceCard({
    required BuildContext context,
    required String title,
    required String icon,
    required String description,
    required bool isConnected,
    required List<Color> gradient,
    required String actionLabel,
  }) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(icon, style: const TextStyle(fontSize: 32)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isConnected
                              ? AppColors.systemGreen
                              : Colors.white38,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isConnected ? 'Configured' : 'Not configured',
                        style: TextStyle(
                          color: isConnected
                              ? AppColors.systemGreen
                              : Colors.white60,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                AppRoutes.navigateTo(
                  context,
                  AppRoutes.serviceConfig,
                  arguments: ServiceProvider.custom,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isConnected
                    ? Colors.white.withValues(alpha: 0.2)
                    : AppColors.systemBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}