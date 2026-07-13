import 'package:flutter/material.dart';

import '../hud/hud_theme.dart';

/// Two panels separated by a draggable divider, so the user can trade space
/// between them (assistant vs context, source map vs git, …). Works on either
/// axis; the divider shows a resize cursor and a subtle grip.
///
/// The split is expressed as a fraction for [first] and kept between
/// [minFraction] and [maxFraction] so neither side can be dragged away
/// entirely.
class ResizableSplit extends StatefulWidget {
  final Widget first;
  final Widget second;
  final Axis axis;
  final double initialFraction;
  final double minFraction;
  final double maxFraction;
  final double dividerSize;

  /// Key on the drag handle, exposed for tests.
  static const dividerKey = ValueKey('resizable_split_divider');

  const ResizableSplit({
    super.key,
    required this.first,
    required this.second,
    this.axis = Axis.horizontal,
    this.initialFraction = 0.6,
    this.minFraction = 0.2,
    this.maxFraction = 0.8,
    this.dividerSize = 10,
  });

  @override
  State<ResizableSplit> createState() => _ResizableSplitState();
}

class _ResizableSplitState extends State<ResizableSplit> {
  late double _fraction = widget.initialFraction.clamp(
    widget.minFraction,
    widget.maxFraction,
  );

  @override
  Widget build(BuildContext context) {
    final horizontal = widget.axis == Axis.horizontal;
    return LayoutBuilder(
      builder: (context, constraints) {
        final total = horizontal ? constraints.maxWidth : constraints.maxHeight;
        final usable = (total - widget.dividerSize).clamp(0.0, double.infinity);
        final firstExtent = usable * _fraction;

        void onDrag(DragUpdateDetails d) {
          if (usable <= 0) return;
          final delta = horizontal ? d.delta.dx : d.delta.dy;
          setState(() {
            _fraction = ((firstExtent + delta) / usable).clamp(
              widget.minFraction,
              widget.maxFraction,
            );
          });
        }

        final divider = MouseRegion(
          cursor: horizontal
              ? SystemMouseCursors.resizeColumn
              : SystemMouseCursors.resizeRow,
          child: GestureDetector(
            key: ResizableSplit.dividerKey,
            behavior: HitTestBehavior.opaque,
            onPanUpdate: onDrag,
            child: Container(
              width: horizontal ? widget.dividerSize : null,
              height: horizontal ? null : widget.dividerSize,
              color: Colors.transparent,
              alignment: Alignment.center,
              child: Container(
                width: horizontal ? 2 : 36,
                height: horizontal ? 36 : 2,
                decoration: BoxDecoration(
                  color: HudTheme.cyan.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        );

        final first = SizedBox(
          width: horizontal ? firstExtent : null,
          height: horizontal ? null : firstExtent,
          child: widget.first,
        );
        final second = Expanded(child: widget.second);

        return horizontal
            ? Row(children: [first, divider, second])
            : Column(children: [first, divider, second]);
      },
    );
  }
}
