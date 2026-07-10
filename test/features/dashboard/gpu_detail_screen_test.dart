import 'dart:io';

import 'package:brainiac_plus/core/services/gpu_metrics_service.dart';
import 'package:brainiac_plus/features/dashboard/controllers/gpu_metrics_provider.dart';
import 'package:brainiac_plus/features/dashboard/screens/gpu_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void writeFakeCard(
  Directory root,
  String card, {
  required String pciId,
  String? busyPercent,
  String? vramUsed,
  String? vramTotal,
  String? tempMilliC,
}) {
  final device = Directory('${root.path}/$card/device')
    ..createSync(recursive: true);
  void write(String name, String content) =>
      File('${device.path}/$name').writeAsStringSync('$content\n');

  write('uevent', 'DRIVER=amdgpu\nPCI_ID=$pciId');
  if (busyPercent != null) write('gpu_busy_percent', busyPercent);
  if (vramUsed != null) write('mem_info_vram_used', vramUsed);
  if (vramTotal != null) write('mem_info_vram_total', vramTotal);
  if (tempMilliC != null) {
    final hwmon = Directory('${device.path}/hwmon/hwmon0')
      ..createSync(recursive: true);
    File('${hwmon.path}/temp1_input').writeAsStringSync('$tempMilliC\n');
  }
}

Widget host(String drmRoot) {
  return ProviderScope(
    overrides: [
      gpuMetricsServiceProvider.overrideWithValue(
        GpuMetricsService(drmRoot: drmRoot),
      ),
    ],
    child: const MaterialApp(home: GpuDetailScreen()),
  );
}

void main() {
  late Directory root;

  setUp(() {
    root = Directory.systemTemp.createTempSync('gpu_detail_test');
  });

  tearDown(() {
    root.deleteSync(recursive: true);
  });

  testWidgets('lists every amdgpu card with its metrics', (tester) async {
    writeFakeCard(
      root,
      'card1',
      pciId: '1002:7551',
      busyPercent: '42',
      vramUsed: '17179869184',
      vramTotal: '34359738368',
      tempMilliC: '44000',
    );
    writeFakeCard(
      root,
      'card2',
      pciId: '1002:13C0',
      busyPercent: '3',
      vramUsed: '1073741824',
      vramTotal: '2147483648',
    );

    await tester.pumpWidget(host(root.path));
    await tester.pump();

    expect(find.textContaining('1002:7551'), findsOneWidget);
    expect(find.textContaining('1002:13C0'), findsOneWidget);
    expect(find.text('42%'), findsOneWidget);
    expect(find.text('16384 / 32768 MB'), findsOneWidget);
    expect(find.text('44.0°C'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('shows an empty state when no GPU exists', (tester) async {
    await tester.pumpWidget(host('${root.path}/nope'));
    await tester.pump();

    expect(find.textContaining('No GPU detected'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });
}
