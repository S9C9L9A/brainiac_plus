import 'dart:io';

import 'package:brainiac_plus/core/services/gpu_metrics_service.dart';
import 'package:brainiac_plus/features/dashboard/controllers/gpu_metrics_provider.dart';
import 'package:brainiac_plus/features/dashboard/widgets/metrics/compact_metrics_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Writes a minimal fake amdgpu sysfs card under [root].
void writeFakeCard(
  Directory root,
  String card, {
  String? busyPercent,
  String? vramUsed,
  String? vramTotal,
  String? tempMilliC,
  String? powerMicroW,
}) {
  final device = Directory('${root.path}/$card/device')
    ..createSync(recursive: true);
  void write(String name, String content) =>
      File('${device.path}/$name').writeAsStringSync('$content\n');

  write('uevent', 'DRIVER=amdgpu\nPCI_ID=1002:7551');
  if (busyPercent != null) write('gpu_busy_percent', busyPercent);
  if (vramUsed != null) write('mem_info_vram_used', vramUsed);
  if (vramTotal != null) write('mem_info_vram_total', vramTotal);

  final hwmon = Directory('${device.path}/hwmon/hwmon0')
    ..createSync(recursive: true);
  if (tempMilliC != null) {
    File('${hwmon.path}/temp1_input').writeAsStringSync('$tempMilliC\n');
  }
  if (powerMicroW != null) {
    File('${hwmon.path}/power1_average').writeAsStringSync('$powerMicroW\n');
  }
}

Widget buildCard(String drmRoot) {
  return ProviderScope(
    overrides: [
      gpuMetricsServiceProvider.overrideWithValue(
        GpuMetricsService(drmRoot: drmRoot),
      ),
    ],
    child: const MaterialApp(home: Scaffold(body: CompactMetricsCard())),
  );
}

void main() {
  late Directory root;

  setUp(() {
    root = Directory.systemTemp.createTempSync('gpu_card_test');
  });

  tearDown(() {
    root.deleteSync(recursive: true);
  });

  testWidgets('shows the GPU item with busy percent when a GPU is present', (
    tester,
  ) async {
    writeFakeCard(
      root,
      'card1',
      busyPercent: '42',
      vramUsed: '17179869184',
      vramTotal: '34359738368',
      tempMilliC: '44000',
      powerMicroW: '28000000',
    );

    await tester.pumpWidget(buildCard(root.path));
    await tester.pump();

    expect(find.text('GPU'), findsOneWidget);
    expect(find.text('42%'), findsOneWidget);

    // Unmount so the polling timer is disposed before the test ends.
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('hides the GPU item when no amdgpu card exists', (tester) async {
    await tester.pumpWidget(buildCard('${root.path}/nope'));
    await tester.pump();

    expect(find.text('GPU'), findsNothing);
    // CPU/RAM/Disk items are still there.
    expect(find.text('CPU'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('tapping the GPU item opens a detail sheet with VRAM and temp', (
    tester,
  ) async {
    writeFakeCard(
      root,
      'card1',
      busyPercent: '42',
      vramUsed: '17179869184',
      vramTotal: '34359738368',
      tempMilliC: '44000',
      powerMicroW: '28000000',
    );

    await tester.pumpWidget(buildCard(root.path));
    await tester.pump();

    await tester.tap(find.text('GPU'));
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    expect(find.text('16384 / 32768 MB'), findsOneWidget);
    expect(find.text('44.0°C'), findsOneWidget);
    expect(find.text('28.0 W'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });
}
