import 'package:flutter/material.dart';

import 'hud_theme.dart';

/// Faint technical grid with a soft cyan glow rising from the centre-bottom —
/// the surface the HUD readouts float on. Static and quiet by design: the
/// motion budget belongs to the ring gauges.
class HudBackground extends StatelessWidget {
  final Widget child;
  const HudBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, 0.4),
          radius: 1.1,
          colors: [Color(0xFF0A1A2E), HudTheme.background],
          stops: [0, 1],
        ),
      ),
      child: CustomPaint(painter: _GridPainter(), child: child),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = HudTheme.gridLine
      ..strokeWidth = 1;
    const step = 46.0;
    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => false;
}
