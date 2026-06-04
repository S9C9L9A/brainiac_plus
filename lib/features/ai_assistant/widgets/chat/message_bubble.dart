import 'package:brainiac_plus/core/theme/app_icons.dart';
import 'package:brainiac_plus/features/ai_assistant/models/ai_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'dart:ui';

class MessageBubble extends StatelessWidget {
  final AiMessage message;
  final VoidCallback? onDelete;

  const MessageBubble({
    super.key,
    required this.message,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    final assistantGlow = isUser
        ? null
        : [
            BoxShadow(
              color: Colors.blue.withOpacity(0.15),
              blurRadius: 16,
            ),
          ];

    final bubbleContent = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUser
            ? Colors.purple.withOpacity(0.3)
            : Colors.grey.shade900.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUser
              ? Colors.purple.withOpacity(0.5)
              : Colors.grey.shade800,
          width: 1,
        ),
        boxShadow: assistantGlow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser && message.agentId != null) ...[
            _buildAgentBadge(message.agentId!),
            const SizedBox(height: 8),
          ],
          SelectableText(
            message.content,
            style: TextStyle(
              color: message.isError ? Colors.red.shade300 : Colors.white,
              fontSize: 15,
              height: 1.4,
            ),
          ),
          if (message.codeSnippet != null) ...[
            const SizedBox(height: 12),
            _buildCodeSnippet(message.codeSnippet!),
          ],
          if (message.filesPaths != null && message.filesPaths!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildFilesList(message.filesPaths!),
          ],
        ],
      ),
    );

    final bubble = isUser
        ? bubbleContent
        : ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: bubbleContent,
            ),
          );

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) _buildAvatar(isUser),
          if (!isUser) const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Tooltip(
                  message: isUser ? '' : 'Tap to copy',
                  child: InkWell(
                    onTap: isUser ? null : () => _copyMessage(context),
                    borderRadius: BorderRadius.circular(16),
                    child: bubble,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(message.timestamp),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    if (!isUser) ...[
                      const SizedBox(width: 8),
                      Icon(
                        AppIcons.copy,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                    ],
                    if (!isUser && message.codeSnippet != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(
                          AppIcons.copy,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: message.codeSnippet!),
                          );
                          HapticFeedback.lightImpact();
                        },
                        tooltip: 'Copy code',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 12),
          if (isUser) _buildAvatar(isUser),
        ],
      ),
    );
  }

  void _copyMessage(BuildContext context) {
    Clipboard.setData(ClipboardData(text: message.content));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('AI response copied'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildAvatar(bool isUser) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isUser
            ? Colors.purple.withOpacity(0.3)
            : Colors.blue.withOpacity(0.3),
        shape: BoxShape.circle,
        border: Border.all(
          color: isUser ? Colors.purple.shade700 : Colors.blue.shade700,
          width: 2,
        ),
      ),
      child: Icon(
        isUser ? LucideIcons.user : AppIcons.ai,
        size: 20,
        color: Colors.white,
      ),
    );
  }

  Widget _buildCodeSnippet(String code) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.shade800,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.code,
                size: 14,
                color: Colors.grey.shade400,
              ),
              const SizedBox(width: 6),
              Text(
                'Code',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            code,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              color: Colors.green.shade300,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilesList(List<String> files) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade900.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.shade800,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                AppIcons.file,
                size: 14,
                color: Colors.grey.shade400,
              ),
              const SizedBox(width: 6),
              Text(
                'Affected files',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: files
                .map(
                  (file) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.grey.shade800,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      file,
                      style: TextStyle(
                        color: Colors.grey.shade300,
                        fontSize: 11,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAgentBadge(String agentId) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blueGrey.withOpacity(0.25),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.blueGrey.withOpacity(0.5)),
      ),
      child: Text(
        'Agent: $agentId',
        style: TextStyle(
          color: Colors.blueGrey.shade200,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}