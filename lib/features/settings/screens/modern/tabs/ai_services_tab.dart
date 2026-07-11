import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../../../../core/theme/colors.dart';
import '../../../../../core/theme/glassmorphism.dart';
import '../../../../../routes/app_routes.dart';
import '../../../../../core/providers/ai_settings_providers.dart';
import '../../../../../core/services/model_suggestions_service.dart';
import '../../../../automation/models/automation_enums.dart';
import '../../../../dashboard/dashboard_screen.dart';
import '../../../providers/extended_settings_provider.dart';
import '../../../models/extended_settings.dart';
import '../../../services/endpoint_validator.dart';
import '../../../services/model_catalog.dart';
import '../../../../../core/services/local_ai_installer.dart';
import '../../../../../core/services/ollama_service.dart';

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
  final _endpointController = TextEditingController();
  bool _isInstalling = false;
  bool _isDownloading = false;
  bool _isTesting = false;
  String? _log;

  @override
  void dispose() {
    _modelController.dispose();
    _modelsPathController.dispose();
    _endpointController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = ref.read(extendedSettingsProvider);

    if (_modelController.text.isEmpty) {
      _modelController.text =
          settings.ollamaModelName ?? 'mistral-medium-3.5:latest';
    }

    if (_endpointController.text.isEmpty) {
      _endpointController.text =
          settings.ollamaEndpoint ?? 'http://localhost:8080';
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

    final openAiCard = _buildAIServiceCard(
      context: context,
      title: 'OpenAI',
      icon: '🤖',
      description: isAndroid
          ? 'API key required for mobile'
          : 'Cloud models via API key',
      isConnected: settings.hasOpenAIKey,
      gradient: [const Color(0xFF10A37F), const Color(0xFF1A7F64)],
      actionLabel: settings.hasOpenAIKey ? 'Edit' : 'Setup',
    );
    final higgsfieldCard = _buildAIServiceCard(
      context: context,
      title: 'Higgsfield',
      icon: '🎬',
      description: isAndroid
          ? 'API key required for mobile'
          : 'AI video generation via API',
      isConnected: settings.hasHiggsfieldKey,
      gradient: [Colors.purple, Colors.blue],
      actionLabel: settings.hasHiggsfieldKey ? 'Edit' : 'Setup',
    );

    // Cloud services sit side by side on desktop widths.
    cards.add(
      LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 880) {
            return Column(
              children: [
                openAiCard,
                const SizedBox(height: 12),
                higgsfieldCard,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: openAiCard),
              const SizedBox(width: 16),
              Expanded(child: higgsfieldCard),
            ],
          );
        },
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
    final isConfigured =
        settings.hasOllamaEndpoint &&
        settings.hasOllamaModelName &&
        settings.hasOllamaModelsPath;

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: title on the left, configuration status always visible
            // on the right — the old bottom-of-card status dot was easy to
            // miss, leaving users with a chat that silently refused input.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
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
                      const SizedBox(height: 4),
                      Text(
                        isConfigured
                            ? 'Local runtime configured — the chat uses this model'
                            : 'Pick a model below to configure the assistant',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(isConfigured),
              ],
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 880;
                if (!isWide) return _buildSetupNarrow(settings);
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Connection + model choice: what you touch most often.
                    Expanded(flex: 5, child: _buildConfigColumn(settings)),
                    const SizedBox(width: 24),
                    // System context + one-time runtime setup actions.
                    Expanded(flex: 3, child: _buildSystemColumn()),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Narrow fallback: original stacked order.
  Widget _buildSetupNarrow(ExtendedAppSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHardwareDiagnostics(),
        const SizedBox(height: 16),
        _buildConfigColumn(settings),
        const SizedBox(height: 16),
        _sectionLabel('RUNTIME SETUP'),
        const SizedBox(height: 8),
        _buildRuntimeActions(),
      ],
    );
  }

  /// Left column on wide screens: endpoint + connection actions, then model.
  Widget _buildConfigColumn(ExtendedAppSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('CONNECTION'),
        const SizedBox(height: 8),
        _buildTextField(
          label: 'Endpoint',
          controller: _endpointController,
          hintText: 'http://localhost:8080',
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: _isTesting ? null : _testOllama,
              style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
              icon: const Icon(Icons.wifi_tethering, size: 16),
              label: Text(_isTesting ? 'Testing...' : 'Test connection'),
            ),
            ElevatedButton.icon(
              onPressed: _saveLocalConfig,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.systemBlue,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.save_outlined, size: 16),
              label: const Text('Save config'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _sectionLabel('MODEL'),
        const SizedBox(height: 8),
        _buildTextField(
          label: 'Models directory',
          controller: _modelsPathController,
          hintText: '/path/to/project/ai_models/ollama',
        ),
        const SizedBox(height: 12),
        _buildModelSelector(settings),
      ],
    );
  }

  /// Right column on wide screens: hardware context and runtime setup.
  Widget _buildSystemColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('YOUR SYSTEM'),
        const SizedBox(height: 8),
        _buildHardwareDiagnostics(),
        const SizedBox(height: 20),
        _sectionLabel('RUNTIME SETUP'),
        const SizedBox(height: 8),
        _buildRuntimeActions(fullWidth: true),
      ],
    );
  }

  /// One-time installation actions, kept away from the everyday
  /// connection/model controls.
  Widget _buildRuntimeActions({bool fullWidth = false}) {
    final buttons = <Widget>[
      ElevatedButton.icon(
        onPressed: _isInstalling ? null : _installOllama,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.systemBlue,
          foregroundColor: Colors.white,
        ),
        icon: const Icon(Icons.download_outlined, size: 16),
        label: Text(_isInstalling ? 'Installing...' : 'Install runtime'),
      ),
      OutlinedButton(
        onPressed: _isInstalling
            ? null
            : () => _installOllama(method: LocalAiInstallMethod.snap),
        style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
        child: const Text('Install via snap'),
      ),
      ElevatedButton.icon(
        onPressed: _isDownloading ? null : _downloadModel,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.systemGreen,
          foregroundColor: Colors.white,
        ),
        icon: const Icon(Icons.cloud_download_outlined, size: 16),
        label: Text(_isDownloading ? 'Downloading...' : 'Download model'),
      ),
    ];

    if (!fullWidth) {
      return Wrap(spacing: 12, runSpacing: 8, children: buttons);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, b) in buttons.indexed) ...[
          if (i > 0) const SizedBox(height: 8),
          b,
        ],
      ],
    );
  }

  /// Small uppercase section label — encodes grouping, not decoration.
  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.45),
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
      ),
    );
  }

  Widget _buildStatusChip(bool isConfigured) {
    final color = isConfigured ? AppColors.systemGreen : AppColors.systemOrange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isConfigured ? Icons.check_circle : Icons.error_outline,
            color: color,
            size: 13,
          ),
          const SizedBox(width: 5),
          Text(
            isConfigured ? 'Configured' : 'Not configured',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Build hardware diagnostics widget
  Widget _buildHardwareDiagnostics() {
    return Consumer(
      builder: (context, ref, child) {
        final hardwareAsync = ref.watch(hardwareInfoProvider);

        return hardwareAsync.when(
          data: (hardware) {
            return GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🖥️ System Specifications',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildHardwareRow(
                      icon: '💾',
                      label: 'Total Memory',
                      value: '${hardware.totalMemoryMB ~/ 1024} GB',
                      detail:
                          '${hardware.availableForModel ~/ 1024} GB available for models',
                    ),
                    _buildHardwareRow(
                      icon: '⚙️',
                      label: 'CPU Cores',
                      value: '${hardware.cpuCores}',
                      detail: hardware.cpuModel,
                    ),
                    _buildHardwareRow(
                      icon: '🐧',
                      label: 'OS',
                      value: hardware.osName,
                      detail: hardware.osVersion,
                    ),
                    if (hardware.hasGpu)
                      _buildHardwareRow(
                        icon: '🎮',
                        label: 'GPU',
                        value: 'Detected',
                        detail:
                            '${hardware.gpuMemoryMB ?? 0} MB VRAM (if available)',
                      ),
                  ],
                ),
              ),
            );
          },
          loading: () => Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: const [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text(
                  'Detecting hardware...',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          error: (err, stack) => Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Could not detect hardware: $err',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        );
      },
    );
  }

  /// Build single hardware row
  Widget _buildHardwareRow({
    required String icon,
    required String label,
    required String value,
    required String detail,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  detail,
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build intelligent model selector
  Widget _buildModelSelector(ExtendedAppSettings settings) {
    return Consumer(
      builder: (context, ref, child) {
        final recommendedAsync = ref.watch(recommendedModelsProvider);
        final allRatedAsync = ref.watch(allRatedModelsProvider);
        final endpoint = _endpointController.text.isNotEmpty
            ? _endpointController.text
            : 'http://localhost:8080';
        final installedAsync = ref.watch(
          ollamaAvailableModelsProvider(endpoint),
        );
        final installedModels =
            installedAsync.asData?.value ?? const <OllamaModel>[];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Model',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 6),
            // Installed models from running Ollama
            installedAsync.when(
              data: (installed) {
                if (installed.isEmpty) return const SizedBox.shrink();
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    border: Border.all(
                      color: AppColors.systemBlue.withValues(alpha: 0.4),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '✅ Installed on this machine:',
                        style: TextStyle(
                          color: AppColors.systemBlue,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ...installed.map((model) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: GestureDetector(
                            onTap: () => _selectAndSaveModel(model.name),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    color: AppColors.systemGreen,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      model.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    model.sizeFormatted,
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
            // Recommended models dropdown
            recommendedAsync.when(
              data: (recommended) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick recommended section
                    if (recommended.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          border: Border.all(
                            color: AppColors.systemGreen.withValues(alpha: 0.3),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '⭐ Recommended for your system:',
                              style: TextStyle(
                                color: AppColors.systemGreen,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            ...recommended.take(3).map((model) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 3,
                                ),
                                child: GestureDetector(
                                  onTap: () => _selectAndSaveModel(model.name),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.08,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                model.displayName,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: _parseHexColor(
                                                  model.ratingColor,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(3),
                                              ),
                                              child: Text(
                                                model.ratingIcon,
                                                style: const TextStyle(
                                                  fontSize: 9,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          model.reason,
                                          style: const TextStyle(
                                            color: Colors.white60,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    // All models dropdown
                    allRatedAsync.when(
                      data: (allModels) {
                        return _buildModelDropdown(allModels, installedModels);
                      },
                      loading: () => Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Loading models...',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ),
                      error: (err, _) => TextField(
                        controller: _modelController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'mistral-medium-3.5:latest',
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
                          errorText: 'Could not load models',
                        ),
                      ),
                    ),
                  ],
                );
              },
              loading: () => Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Analyzing recommended models...',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              error: (err, _) => TextField(
                controller: _modelController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'mistral-medium-3.5:latest',
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
            ),
          ],
        );
      },
    );
  }

  /// Selects [name] as the active model and persists the configuration
  /// immediately, so picking a model is enough to make the chat usable —
  /// no separate "Save config" step to forget.
  void _selectAndSaveModel(String name) {
    _modelController.text = name;
    _saveLocalConfig();
  }

  /// Build model dropdown with all options
  Widget _buildModelDropdown(
    List<OllamaModelInfo> allModels,
    List<OllamaModel> installed,
  ) {
    // Server-reported models become first-class entries so they never show
    // up as "(not installed)" while actually running on the server.
    final mergedModels = ModelCatalog.mergeWithInstalled(allModels, installed);
    final installedNames = ModelCatalog.installedNames(installed);
    // Deduplicate by name: duplicate values break DropdownButton's
    // "exactly one item per value" invariant.
    final seen = <String>{};
    final models = <OllamaModelInfo>[
      for (final m in mergedModels)
        if (seen.add(m.name)) m,
    ];
    final currentValue = _modelController.text.isNotEmpty
        ? _modelController.text
        : null;
    // True when the configured model is among the detected models.
    final hasCurrent =
        currentValue != null && models.any((m) => m.name == currentValue);

    return Column(
      children: [
        DropdownButtonFormField<String>(
          initialValue: currentValue,
          // Expand to the parent width so the Expanded inside each item gets a
          // bounded constraint; without this the dropdown computes intrinsic
          // widths over an unbounded Expanded and trips rendering/semantics
          // assertions.
          isExpanded: true,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          dropdownColor: const Color(0xFF1a1a2e),
          decoration: InputDecoration(
            hintText: 'Select or type model name',
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
            prefixIcon: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('🤖', style: TextStyle(fontSize: 16)),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 32),
          ),
          items:
              models.map<DropdownMenuItem<String>>((model) {
                  final isInstalled = installedNames.contains(model.name);
                  return DropdownMenuItem<String>(
                    value: model.name,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        isInstalled
                            ? const Icon(
                                Icons.check_circle,
                                color: AppColors.systemGreen,
                                size: 12,
                              )
                            : Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _parseHexColor(model.ratingColor),
                                  shape: BoxShape.circle,
                                ),
                              ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                model.displayName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                isInstalled ? '✅ Installed' : model.ratingIcon,
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList()
                // Keep a hand-typed model selectable even when neither the
                // catalog nor the server knows it, so the dropdown value
                // always matches exactly one item.
                ..insertAll(0, [
                  if (!hasCurrent && currentValue != null)
                    DropdownMenuItem<String>(
                      value: currentValue,
                      child: Text(
                        '$currentValue (not detected on server)',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ),
                ]),
          onChanged: (value) {
            if (value != null) {
              _selectAndSaveModel(value);
            }
          },
        ),
        if (_modelController.text.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildModelDetails(models),
        ],
      ],
    );
  }

  /// Build model details info
  Widget _buildModelDetails(List<OllamaModelInfo> allModels) {
    final OllamaModelInfo selectedModel;
    try {
      selectedModel = allModels.firstWhere(
        (m) => m.name == _modelController.text,
      );
    } catch (e) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _parseHexColor(selectedModel.ratingColor).withValues(alpha: 0.1),
        border: Border.all(
          color: _parseHexColor(
            selectedModel.ratingColor,
          ).withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  selectedModel.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                selectedModel.ratingIcon,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            selectedModel.description,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 12,
            children: [
              _buildDetailChip(icon: '📦', label: '${selectedModel.sizeGB} GB'),
              _buildDetailChip(
                icon: '💾',
                label: '${selectedModel.vramRequiredMB ~/ 1024} GB RAM',
              ),
              if (selectedModel.isQuantized)
                _buildDetailChip(icon: '🔧', label: selectedModel.quantization),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '💡 ${selectedModel.reason}',
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 10,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  /// Build detail chip
  Widget _buildDetailChip({required String icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 10)),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
        ],
      ),
    );
  }

  /// Parse hex color from string
  Color _parseHexColor(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hexColor', radix: 16));
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
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

  Future<void> _testOllama() async {
    final endpoint = _endpointController.text.trim();
    final model = _modelController.text.trim();

    if (endpoint.isEmpty) {
      setState(() {
        _log = 'Endpoint is required.';
      });
      return;
    }

    setState(() {
      _isTesting = true;
      _log = 'Testing connection to $endpoint...';
    });

    try {
      final service = OllamaService(
        baseUrl: endpoint,
        model: model.isEmpty ? null : model,
      );
      final isAvailable = await service.isAvailable();
      setState(() {
        _log = isAvailable
            ? 'Ollama is reachable at $endpoint.'
            : 'Ollama not reachable at $endpoint.';
      });
    } catch (e) {
      setState(() {
        _log = 'Test failed: $e';
      });
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  void _saveLocalConfig() {
    final model = _modelController.text.trim();
    final path = _modelsPathController.text.trim();

    final validation = EndpointValidator().validate(_endpointController.text);
    if (!validation.isValid) {
      setState(() {
        _log = 'Endpoint not saved: ${validation.error}.';
      });
      return;
    }
    // Reflect the normalized form (scheme added, trailing slash removed).
    if (validation.normalized != null) {
      _endpointController.text = validation.normalized!;
    }

    ref
        .read(extendedSettingsProvider.notifier)
        .setSettings(
          ref
              .read(extendedSettingsProvider)
              .copyWith(
                ollamaEndpoint: validation.normalized,
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
