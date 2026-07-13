import 'package:flutter/material.dart';

import '../hud/hud_theme.dart';

/// A panel detached into an in-app floating window: drag its title bar to move
/// it, drag the bottom-right corner to resize it, and re-dock or close it from
/// the header. Reliable everywhere (unlike native OS multi-window on Wayland),
/// while giving the same "pop out / re-attach" feel.
///
/// Must be placed directly inside a [Stack] — it returns a [Positioned].
class FloatingPanel extends StatefulWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Offset initialOffset;
  final Size initialSize;

  /// Re-attach the panel to the docked layout.
  final VoidCallback onDock;

  /// Optional close action; hidden when null.
  final VoidCallback? onClose;

  final Size minSize;

  const FloatingPanel({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    required this.onDock,
    this.onClose,
    this.initialOffset = const Offset(80, 80),
    this.initialSize = const Size(420, 360),
    this.minSize = const Size(240, 180),
  });

  @override
  State<FloatingPanel> createState() => _FloatingPanelState();
}

class _FloatingPanelState extends State<FloatingPanel> {
  late Offset _offset = widget.initialOffset;
  late Size _size = widget.initialSize;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _offset.dx,
      top: _offset.dy,
      child: Container(
        width: _size.width,
        height: _size.height,
        decoration: BoxDecoration(
          color: HudTheme.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: HudTheme.cyan.withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.55),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            children: [
              _titleBar(),
              Expanded(child: widget.child),
              _resizeHandle(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _titleBar() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanUpdate: (d) => setState(() => _offset += d.delta),
      child: MouseRegion(
        cursor: SystemMouseCursors.move,
        child: Container(
          height: 38,
          padding: const EdgeInsets.only(left: 12, right: 6),
          color: HudTheme.panel.withValues(alpha: 0.9),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 14,
                color: HudTheme.cyan.withValues(alpha: 0.85),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Dock',
                onPressed: widget.onDock,
                icon: const Icon(Icons.close_fullscreen, size: 15),
                color: HudTheme.cyanGlow,
                splashRadius: 15,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
              ),
              if (widget.onClose != null)
                IconButton(
                  tooltip: 'Close',
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close, size: 16),
                  color: Colors.white54,
                  splashRadius: 15,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 30,
                    minHeight: 30,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _resizeHandle() {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: (d) => setState(() {
          _size = Size(
            (_size.width + d.delta.dx).clamp(widget.minSize.width, 2000.0),
            (_size.height + d.delta.dy).clamp(widget.minSize.height, 2000.0),
          );
        }),
        child: MouseRegion(
          cursor: SystemMouseCursors.resizeDownRight,
          child: Container(
            width: 22,
            height: 22,
            alignment: Alignment.bottomRight,
            padding: const EdgeInsets.all(3),
            child: Icon(
              Icons.open_in_full,
              size: 12,
              color: HudTheme.cyan.withValues(alpha: 0.6),
            ),
          ),
        ),
      ),
    );
  }
}
