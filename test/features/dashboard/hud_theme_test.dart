import 'package:brainiac_plus/features/dashboard/widgets/hud/hud_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HudTheme.statusColor', () {
    test('nominal load reads as cyan', () {
      expect(HudTheme.statusColor(0), HudTheme.cyan);
      expect(HudTheme.statusColor(49.9), HudTheme.cyan);
    });

    test('elevated load reads as amber', () {
      expect(HudTheme.statusColor(50), HudTheme.amber);
      expect(HudTheme.statusColor(84.9), HudTheme.amber);
    });

    test('critical load reads as danger red', () {
      expect(HudTheme.statusColor(85), HudTheme.danger);
      expect(HudTheme.statusColor(100), HudTheme.danger);
    });
  });

  group('HudTheme.statusLabel', () {
    test('maps load bands to HUD wording', () {
      expect(HudTheme.statusLabel(10), 'NOMINAL');
      expect(HudTheme.statusLabel(60), 'ELEVATED');
      expect(HudTheme.statusLabel(90), 'CRITICAL');
    });
  });

  group('HudTheme.clampPercent', () {
    test('clamps into 0..100', () {
      expect(HudTheme.clampPercent(-5), 0);
      expect(HudTheme.clampPercent(150), 100);
      expect(HudTheme.clampPercent(42.5), 42.5);
    });
  });

  test('palette exposes the Jarvis colors', () {
    expect(HudTheme.cyan, isA<Color>());
    expect(HudTheme.background.a, 1.0); // opaque base
  });
}
