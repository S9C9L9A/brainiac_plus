import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../routes/app_routes.dart';
import '../../controllers/social_media_controller.dart';
import '../../models/social_media_service.dart';
import 'hud_panel.dart';
import 'hud_theme.dart';

/// Dashboard panel for connected social accounts, with follower counts when
/// the platform reports them. Empty state points to settings.
class SocialsPanel extends ConsumerWidget {
  const SocialsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(socialMediaServicesProvider);
    final services = state.configuredServices;

    return HudPanel(
      title: 'SOCIAL FEEDS',
      icon: Icons.share,
      trailing: services.isEmpty
          ? _connectButton(context)
          : Text(
              '${services.length}',
              style: TextStyle(
                color: HudTheme.cyan.withValues(alpha: 0.7),
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
      child: services.isEmpty
          ? Text(
              'No accounts connected — link Facebook or Instagram in Settings.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 12,
              ),
            )
          : Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [for (final s in services) _SocialCard(service: s)],
            ),
    );
  }

  Widget _connectButton(BuildContext context) {
    return TextButton(
      onPressed: () => AppRoutes.navigateTo(context, AppRoutes.settings),
      style: TextButton.styleFrom(
        foregroundColor: HudTheme.cyan,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: Size.zero,
      ),
      child: const Text(
        'CONNECT',
        style: TextStyle(fontSize: 10, letterSpacing: 1),
      ),
    );
  }
}

class _SocialCard extends StatelessWidget {
  final SocialMediaService service;
  const _SocialCard({required this.service});

  @override
  Widget build(BuildContext context) {
    final followers = service.metrics?.followers;
    final active = service.isActive;
    return Container(
      width: 180,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HudTheme.cyan.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Text(
            service.platform.iconEmoji,
            style: const TextStyle(fontSize: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  service.platform.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  followers != null ? '$followers followers' : 'connected',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: active ? HudTheme.cyan : Colors.white24,
              shape: BoxShape.circle,
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: HudTheme.cyan.withValues(alpha: 0.7),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
