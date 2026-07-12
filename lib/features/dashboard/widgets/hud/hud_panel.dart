import 'package:flutter/material.dart';

import 'hud_theme.dart';

/// A titled HUD panel: an uppercase cyan section header with a hairline rule,
/// framed like the rest of the command interface. The shared container for the
/// dashboard's projects and socials sections.
class HudPanel extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  /// When true, the child fills the panel's remaining height via Expanded —
  /// safe inside a bounded parent, unlike a SizedBox(height: infinity).
  final bool expandChild;

  const HudPanel({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
    this.expandChild = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      decoration: BoxDecoration(
        color: HudTheme.panel.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: HudTheme.cyan.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: HudTheme.cyan.withValues(alpha: 0.8), size: 15),
              const SizedBox(width: 8),
              // Expanded (not a fixed Text + Spacer) so the header never
              // overflows in a narrow panel — the title ellipsizes instead.
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: HudTheme.cyan.withValues(alpha: 0.85),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                Flexible(child: trailing!),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Divider(color: HudTheme.cyan.withValues(alpha: 0.1), height: 1),
          const SizedBox(height: 14),
          if (expandChild) Expanded(child: child) else child,
        ],
      ),
    );
  }
}
