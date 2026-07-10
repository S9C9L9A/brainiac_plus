import 'dart:io';

import 'package:brainiac_plus/core/services/gpu_metrics_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds a fake `/sys/class/drm` tree inside [root].
///
/// Mirrors the real amdgpu sysfs layout:
///   card<N>/device/gpu_busy_percent
///   card<N>/device/mem_info_vram_used / mem_info_vram_total
///   card<N>/device/uevent (DRIVER=..., PCI_ID=...)
///   card<N>/device/hwmon/hwmon<M>/temp1_input (millidegrees C)
///   card<N>/device/hwmon/hwmon<M>/power1_average (microwatts)
void writeFakeCard(
  Directory root,
  String card, {
  String? busyPercent,
  String? vramUsed,
  String? vramTotal,
  String? pciId,
  String driver = 'amdgpu',
  String? tempMilliC,
  String? powerMicroW,
  int hwmonIndex = 0,
}) {
  final device = Directory('${root.path}/$card/device')
    ..createSync(recursive: true);
  void write(String name, String content) =>
      File('${device.path}/$name').writeAsStringSync('$content\n');

  if (busyPercent != null) write('gpu_busy_percent', busyPercent);
  if (vramUsed != null) write('mem_info_vram_used', vramUsed);
  if (vramTotal != null) write('mem_info_vram_total', vramTotal);
  write('uevent', 'DRIVER=$driver\n${pciId != null ? 'PCI_ID=$pciId' : ''}');

  if (tempMilliC != null || powerMicroW != null) {
    final hwmon = Directory('${device.path}/hwmon/hwmon$hwmonIndex')
      ..createSync(recursive: true);
    if (tempMilliC != null) {
      File('${hwmon.path}/temp1_input').writeAsStringSync('$tempMilliC\n');
    }
    if (powerMicroW != null) {
      File('${hwmon.path}/power1_average').writeAsStringSync('$powerMicroW\n');
    }
  }
}

void main() {
  late Directory root;

  setUp(() {
    root = Directory.systemTemp.createTempSync('gpu_metrics_test');
  });

  tearDown(() {
    root.deleteSync(recursive: true);
  });

  group('GpuMetricsService.readAll', () {
    test('reads busy%, VRAM, temp, power and PCI id from a card', () async {
      writeFakeCard(
        root,
        'card1',
        busyPercent: '42',
        vramUsed: '18142560256',
        vramTotal: '34208743424',
        pciId: '1002:7551',
        tempMilliC: '44000',
        powerMicroW: '28000000',
        hwmonIndex: 7,
      );

      final service = GpuMetricsService(drmRoot: root.path);
      final all = await service.readAll();

      expect(all, hasLength(1));
      final gpu = all.single;
      expect(gpu.cardId, 'card1');
      expect(gpu.pciId, '1002:7551');
      expect(gpu.busyPercent, 42);
      expect(gpu.vramUsedBytes, 18142560256);
      expect(gpu.vramTotalBytes, 34208743424);
      expect(gpu.temperatureC, closeTo(44.0, 0.001));
      expect(gpu.powerWatts, closeTo(28.0, 0.001));
    });

    test('ignores connector entries and non-amdgpu cards', () async {
      writeFakeCard(
        root,
        'card1',
        busyPercent: '5',
        vramTotal: '1000',
        pciId: '1002:7551',
      );
      // Connector dirs like card1-DP-1 must not be treated as GPUs.
      Directory('${root.path}/card1-DP-1/device').createSync(recursive: true);
      writeFakeCard(
        root,
        'card3',
        busyPercent: '9',
        vramTotal: '500',
        driver: 'nouveau',
      );

      final service = GpuMetricsService(drmRoot: root.path);
      final all = await service.readAll();

      expect(all.map((g) => g.cardId), ['card1']);
    });

    test('missing sensor files yield null fields, not errors', () async {
      writeFakeCard(root, 'card2', vramTotal: '2147483648');

      final service = GpuMetricsService(drmRoot: root.path);
      final gpu = (await service.readAll()).single;

      expect(gpu.busyPercent, isNull);
      expect(gpu.vramUsedBytes, isNull);
      expect(gpu.vramTotalBytes, 2147483648);
      expect(gpu.temperatureC, isNull);
      expect(gpu.powerWatts, isNull);
    });

    test('returns empty list when the drm root does not exist', () async {
      final service = GpuMetricsService(drmRoot: '${root.path}/nope');
      expect(await service.readAll(), isEmpty);
    });
  });

  group('GpuMetricsService.readPrimary', () {
    test('picks the card with the largest VRAM (discrete over iGPU)', () async {
      writeFakeCard(
        root,
        'card1',
        vramTotal: '34208743424',
        pciId: '1002:7551',
        busyPercent: '4',
      );
      writeFakeCard(
        root,
        'card2',
        vramTotal: '2147483648',
        pciId: '1002:13C0',
        busyPercent: '80',
      );

      final service = GpuMetricsService(drmRoot: root.path);
      final primary = await service.readPrimary();

      expect(primary, isNotNull);
      expect(primary!.cardId, 'card1');
    });

    test('returns null when no amdgpu card exists', () async {
      final service = GpuMetricsService(drmRoot: root.path);
      expect(await service.readPrimary(), isNull);
    });
  });

  group('GpuMetrics derived values', () {
    test('exposes MB conversions and VRAM usage percent', () {
      const gpu = GpuMetrics(
        cardId: 'card1',
        pciId: '1002:7551',
        busyPercent: 42,
        vramUsedBytes: 17179869184, // 16 GiB
        vramTotalBytes: 34359738368, // 32 GiB
        temperatureC: 44.0,
        powerWatts: 28.0,
      );

      expect(gpu.vramUsedMB, 16384);
      expect(gpu.vramTotalMB, 32768);
      expect(gpu.vramUsagePercent, closeTo(50.0, 0.001));
    });

    test('vramUsagePercent is null when totals are unavailable', () {
      const gpu = GpuMetrics(cardId: 'card1');
      expect(gpu.vramUsagePercent, isNull);
      expect(gpu.vramUsedMB, isNull);
      expect(gpu.vramTotalMB, isNull);
    });
  });
}
