import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'hud_theme.dart';

/// The HUD's signature element: an arc-reactor ring gauge. A 270° track holds
/// a glowing load arc, a bright cap rides its end, and a thin scanner segment
/// sweeps the outer edge — the one animated flourish, kept to a slow rotation.
/// Everything else on the dashboard stays quiet around it.
class HudRingGauge extends StatefulWidget {
  final String label;

  /// 0..100 load driving the arc and colour.
  final double percent;

  /// Big centre readout (e.g. "42%" or "17.2G").
  final String value;

  /// Small line under the value (e.g. "3.2 / 6.4 GHz").
  final String? detail;

  final double size;

  const HudRingGauge({
    super.key,
    required this.label,
    required this.percent,
    required this.value,
    this.detail,
    this.size = 168,
  });

  @override
  State<HudRingGauge> createState() => _HudRingGaugeState();
}

class _HudRingGaugeState extends State<HudRingGauge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scanner;

  @override
  void initState() {
    super.initState();
    _scanner = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _scanner.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pct = HudTheme.clampPercent(widget.percent);
    final color = HudTheme.statusColor(pct);

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _scanner,
        builder: (context, _) {
          return CustomPaint(
            painter: _RingPainter(
              percent: pct,
              color: color,
              scan: _scanner.value,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.value,
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'monospace',
                      fontSize: widget.size * 0.19,
                      fontWeight: FontWeight.w700,
                      height: 1,
                      shadows: [
                        Shadow(
                          color: color.withValues(alpha: 0.7),
                          blurRadius: 14,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.label.toUpperCase(),
                    style: TextStyle(
                      color: color,
                      fontSize: widget.size * 0.062,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.2,
                    ),
                  ),
                  if (widget.detail != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.detail!,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontFamily: 'monospace',
                        fontSize: widget.size * 0.055,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double percent;
  final Color color;
  final double scan; // 0..1 rotation phase

  _RingPainter({
    required this.percent,
    required this.color,
    required this.scan,
  });

  static const double _startDeg = 135;
  static const double _sweepDeg = 270;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    final start = _startDeg * math.pi / 180;
    final fullSweep = _sweepDeg * math.pi / 180;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Track.
    canvas.drawArc(
      rect,
      start,
      fullSweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..color = HudTheme.cyan.withValues(alpha: 0.12),
    );

    // Tick marks around the track.
    final tickPaint = Paint()
      ..color = HudTheme.cyan.withValues(alpha: 0.18)
      ..strokeWidth = 1.4;
    const ticks = 28;
    for (var i = 0; i <= ticks; i++) {
      final a = start + fullSweep * (i / ticks);
      final outer = center + Offset(math.cos(a), math.sin(a)) * (radius + 6);
      final inner = center + Offset(math.cos(a), math.sin(a)) * (radius + 1);
      canvas.drawLine(inner, outer, tickPaint);
    }

    final valueSweep = fullSweep * (percent / 100);

    // Glow underlay for the value arc.
    canvas.drawArc(
      rect,
      start,
      valueSweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    // Crisp value arc.
    canvas.drawArc(
      rect,
      start,
      valueSweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..color = color,
    );

    // Bright cap at the arc end.
    if (percent > 0) {
      final capAngle = start + valueSweep;
      final cap =
          center + Offset(math.cos(capAngle), math.sin(capAngle)) * radius;
      canvas.drawCircle(cap, 4.5, Paint()..color = Colors.white);
      canvas.drawCircle(
        cap,
        9,
        Paint()
          ..color = color.withValues(alpha: 0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }

    // Inner hairline ring.
    canvas.drawCircle(
      center,
      radius - 16,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = HudTheme.cyan.withValues(alpha: 0.1),
    );

    // Rotating scanner segment on the outer edge — the animated flourish.
    final scanStart = scan * 2 * math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius + 8),
      scanStart,
      0.5,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = HudTheme.cyanGlow.withValues(alpha: 0.55),
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.percent != percent || old.color != color || old.scan != scan;
}
