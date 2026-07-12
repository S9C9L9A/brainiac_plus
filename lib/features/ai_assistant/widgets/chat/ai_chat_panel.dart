import 'package:brainiac_plus/core/theme/app_icons.dart';
import 'package:brainiac_plus/features/ai_assistant/controllers/ai_chat_controller.dart';
import 'package:brainiac_plus/features/ai_assistant/widgets/chat/chat_input_bar.dart';
import 'package:brainiac_plus/features/ai_assistant/widgets/chat/message_bubble.dart';
import 'package:brainiac_plus/features/ai_assistant/models/agent_task.dart';
import 'package:brainiac_plus/features/ai_assistant/widgets/chat/suggested_actions_bar.dart';
import 'package:brainiac_plus/features/dashboard/controllers/gpu_metrics_provider.dart';
import 'package:brainiac_plus/features/dashboard/controllers/system_metrics_provider.dart';
import 'package:brainiac_plus/features/settings/models/extended_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:brainiac_plus/features/settings/providers/extended_settings_provider.dart';
import 'package:brainiac_plus/routes/app_routes.dart';

class AiChatPanel extends ConsumerStatefulWidget {
  const AiChatPanel({super.key});

  @override
  ConsumerState<AiChatPanel> createState() => _AiChatPanelState();
}

class _AiChatPanelState extends ConsumerState<AiChatPanel>
    with SingleTickerProviderStateMixin {
  final _scrollController = ScrollController();
  late final AnimationController _glowController;
  late final Animation<double> _glowAnimation;

  /// Agent mode: the assistant executes the task (writes files, runs
  /// commands) instead of only replying. On by default — it's the point.
  bool _agentMode = true;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
    _glowAnimation = CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Executes state-mutating actions suggested by the pipeline.
  void _executeStateAction(AgentAction action) {
    if (action.id == 'refresh_metrics') {
      ref.read(systemMetricsProvider.notifier).refresh();
      ref.read(gpuMetricsProvider.notifier).refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('System metrics refreshed'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(aiChatControllerProvider);
    final chatController = ref.read(aiChatControllerProvider.notifier);
    final settings = ref.watch(extendedSettingsProvider);
    final availability = ref.watch(ollamaAvailabilityProvider);

    final isConfigured =
        settings.hasOllamaEndpoint && settings.hasOllamaModelName;
    final isOnline = availability.maybeWhen(
      data: (isUp) => isUp,
      orElse: () => false,
    );
    final canSend = isConfigured && isOnline && !chatState.isLoading;

    if (chatState.messages.isNotEmpty) {
      _scrollToBottom();
    }

    return Stack(
      children: [
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              final glow = 0.02 + (_glowAnimation.value * 0.05);
              return ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: glow),
                          Colors.white.withValues(alpha: glow * 0.6),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: Opacity(
              opacity: 0.35,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    colors: [
                      Colors.purple.withValues(alpha: 0.18),
                      Colors.blue.withValues(alpha: 0.12),
                      Colors.transparent,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
        ),
        Column(
          children: [
            _buildHeader(settings, availability),
            _buildActiveProject(),
            if (!isConfigured || !isOnline)
              _buildConnectionNotice(
                isConfigured: isConfigured,
                isOnline: isOnline,
              ),
            Expanded(
              child: chatState.messages.isEmpty
                  ? _buildEmptyState(canSend)
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: chatState.messages.length,
                      itemBuilder: (context, index) {
                        final message = chatState.messages[index];
                        return MessageBubble(
                          message: message,
                          onDelete: () =>
                              chatController.deleteMessage(message.id),
                        );
                      },
                    ),
            ),
            if (chatState.isLoading) _buildTypingIndicator(),
            // Actions suggested by the multi-agent pipeline for the last
            // message — tapping one navigates straight to the target screen
            // or executes the state change (e.g. refreshing metrics).
            if (!chatState.isLoading)
              SuggestedActionsBar(
                actions:
                    chatState.lastPipelineResult?.suggestedActions ?? const [],
                onStateAction: _executeStateAction,
              ),
            ChatInputBar(
              onSend: (text) {
                if (_agentMode && chatController.agentEnabled) {
                  chatController.sendAgentTask(text);
                } else {
                  chatController.sendMessageStream(text);
                }
                HapticFeedback.lightImpact();
              },
              enabled: canSend,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeader(
    ExtendedAppSettings settings,
    AsyncValue<bool> availability,
  ) {
    final modelLabel = settings.ollamaModelName ?? 'No model selected';
    final endpointLabel = settings.ollamaEndpoint ?? 'Endpoint not set';
    final isConfigured =
        settings.hasOllamaEndpoint && settings.hasOllamaModelName;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade400, Colors.blue.shade400],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withValues(alpha: 0.35),
                  blurRadius: 18,
                ),
              ],
            ),
            child: Icon(AppIcons.ai, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'BrainiacPlus Assistant',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  modelLabel,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  endpointLabel,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          availability.when(
            data: (isUp) => _buildStatusPill(
              isConfigured && isUp ? 'Online' : 'Offline',
              isConfigured && isUp ? Colors.green : Colors.orange,
            ),
            loading: () => _buildStatusPill('Checking', Colors.blueGrey),
            error: (_, _) => _buildStatusPill('Offline', Colors.orange),
          ),
          const SizedBox(width: 10),
          _buildAgentToggle(),
          const SizedBox(width: 6),
          IconButton(
            onPressed: () {
              AppRoutes.navigateTo(context, AppRoutes.settingsAI);
            },
            icon: const Icon(Icons.tune, color: Colors.white70, size: 18),
            tooltip: 'Open AI settings',
            splashRadius: 18,
          ),
        ],
      ),
    );
  }

  /// Banner shown while the assistant is scoped to a project — its file and
  /// command tools operate inside that folder. Tap the ✕ to detach.
  Widget _buildActiveProject() {
    final path = ref.watch(activeProjectProvider);
    if (path == null) return const SizedBox.shrink();
    final name = path.split('/').where((s) => s.isNotEmpty).last;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.cyan.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.flutter_dash, color: Colors.cyanAccent, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Working in: $name',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          InkWell(
            onTap: () => ref.read(activeProjectProvider.notifier).state = null,
            child: const Icon(Icons.close, color: Colors.white54, size: 16),
          ),
        ],
      ),
    );
  }

  /// Toggle between Agent (executes tasks) and Chat (talks only).
  Widget _buildAgentToggle() {
    final color = _agentMode ? Colors.purpleAccent : Colors.white54;
    return Tooltip(
      message: _agentMode
          ? 'Agent mode: the assistant performs the task'
          : 'Chat mode: replies only',
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => setState(() => _agentMode = !_agentMode),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _agentMode ? Icons.bolt : Icons.chat_bubble_outline,
                color: color,
                size: 14,
              ),
              const SizedBox(width: 5),
              Text(
                _agentMode ? 'Agent' : 'Chat',
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(Colors.purple.shade300),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Neural response...',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionNotice({
    required bool isConfigured,
    required bool isOnline,
  }) {
    final title = isConfigured
        ? 'Ollama is offline'
        : 'Ollama is not configured';
    final subtitle = isConfigured
        ? 'Start the Ollama server or check the endpoint.'
        : 'Set endpoint and model in AI settings.';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(AppIcons.warning, color: Colors.orange.shade300, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              AppRoutes.navigateTo(context, AppRoutes.settingsAI);
            },
            child: const Text('Settings'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool canSend) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.purple.withValues(alpha: 0.3),
                  Colors.blue.withValues(alpha: 0.3),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withValues(alpha: 0.3),
                  blurRadius: 24,
                ),
              ],
            ),
            child: Icon(AppIcons.ai, size: 64, color: Colors.white),
          ),
          const SizedBox(height: 24),
          const Text(
            'AI Assistant',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ask me to add features, fix bugs, or automate tasks',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _buildSuggestionChips(canSend),
        ],
      ),
    );
  }

  Widget _buildSuggestionChips(bool canSend) {
    final suggestions = [
      'Add network monitor',
      'Monitor GPU usage',
      'Create cleanup task',
      'Add battery widget',
    ];

    final chatController = ref.read(aiChatControllerProvider.notifier);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: suggestions.map((suggestion) {
        return ActionChip(
          label: Text(suggestion),
          backgroundColor: Colors.grey.shade900,
          labelStyle: TextStyle(color: Colors.grey.shade300),
          side: BorderSide(color: Colors.grey.shade800),
          onPressed: canSend
              ? () {
                  chatController.sendMessageStream(suggestion);
                  HapticFeedback.lightImpact();
                }
              : null,
        );
      }).toList(),
    );
  }
}
