import 'package:brainiac_plus/core/services/system_metrics_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseMemInfo', () {
    // A trimmed real /proc/meminfo.
    const sample = '''
MemTotal:       127094076 kB
MemFree:        37699564 kB
MemAvailable:   99181696 kB
Buffers:         1234000 kB
Cached:         50000000 kB
SwapTotal:       8388604 kB
SwapFree:        8387692 kB
''';

    test('reads total, available and swap', () {
      final info = SystemMetricsService.parseMemInfo(sample);
      expect(info.totalKb, 127094076);
      expect(info.availableKb, 99181696);
      expect(info.swapTotalKb, 8388604);
      expect(info.swapFreeKb, 8387692);
    });

    test('MemAvailable — not MemFree — drives an honest used%', () {
      final info = SystemMetricsService.parseMemInfo(sample);
      final totalMb = info.totalKb / 1024;
      final usedMb = (info.totalKb - info.availableKb) / 1024;
      final usedPct = usedMb / totalMb * 100;
      // Real usage is ~22%, not the ~70% MemFree alone would imply.
      expect(usedPct, closeTo(22, 2));
      final usedPctFromFree = (127094076 - 37699564) / 127094076 * 100;
      expect(usedPctFromFree, greaterThan(65)); // the misleading old value
    });

    test('missing fields default to zero, no throw', () {
      final info = SystemMetricsService.parseMemInfo('Garbage: 1\n');
      expect(info.totalKb, 0);
      expect(info.availableKb, 0);
    });
  });

  group('parseLoadAvg', () {
    test('reads the three averages from /proc/loadavg', () {
      final load = SystemMetricsService.parseLoadAvg(
        '1.27 1.63 1.60 2/5616 642958',
      );
      expect(load, [1.27, 1.63, 1.60]);
    });

    test('malformed input yields zeros, not an exception', () {
      expect(SystemMetricsService.parseLoadAvg(''), [0, 0, 0]);
      expect(SystemMetricsService.parseLoadAvg('x y'), [0, 0, 0]);
    });
  });

  group('availableForModelsMB', () {
    test('is based on free memory, not used', () {
      final m = RealtimeSystemMetrics(
        cpuUsagePercent: 0,
        totalMemoryMB: 16000,
        usedMemoryMB: 4000,
        freeMemoryMB: 12000,
        memoryUsagePercent: 25,
        totalDiskGB: 0,
        usedDiskGB: 0,
        freeDiskGB: 0,
        diskUsagePercent: 0,
        cpuCores: 8,
        cpuModel: 'x',
        hasGpu: false,
        gpuMemoryMB: null,
        lastUpdate: DateTime(2026),
        osName: 'linux',
      );
      // 80% of the 12 GB free, not a fraction of the 4 GB used.
      expect(m.availableForModelsMB, 9600);
    });
  });
}
