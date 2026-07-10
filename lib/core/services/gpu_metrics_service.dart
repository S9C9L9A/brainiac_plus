import 'dart:io';

/// Live metrics for a single GPU, read from the amdgpu sysfs interface.
///
/// Complements [GpuDetectionService] (one-shot presence/VRAM detection): this
/// model carries the values that change while the app runs — utilization,
/// VRAM allocation, temperature and power draw — cheap enough to poll every
/// couple of seconds from the dashboard.
class GpuMetrics {
  /// DRM card id, e.g. "card1".
  final String cardId;

  /// PCI vendor:device id from uevent, e.g. "1002:7551".
  final String? pciId;

  /// GPU utilization 0–100, null when the kernel does not expose it.
  final int? busyPercent;

  final int? vramUsedBytes;
  final int? vramTotalBytes;

  /// Edge temperature in °C.
  final double? temperatureC;

  /// Average power draw in watts.
  final double? powerWatts;

  const GpuMetrics({
    required this.cardId,
    this.pciId,
    this.busyPercent,
    this.vramUsedBytes,
    this.vramTotalBytes,
    this.temperatureC,
    this.powerWatts,
  });

  int? get vramUsedMB =>
      vramUsedBytes != null ? (vramUsedBytes! / (1024 * 1024)).round() : null;

  int? get vramTotalMB =>
      vramTotalBytes != null ? (vramTotalBytes! / (1024 * 1024)).round() : null;

  double? get vramUsagePercent {
    if (vramUsedBytes == null ||
        vramTotalBytes == null ||
        vramTotalBytes == 0) {
      return null;
    }
    return vramUsedBytes! / vramTotalBytes! * 100;
  }
}

/// Reads live GPU metrics from `/sys/class/drm/card*/device`.
///
/// Unlike [GpuDetectionService], which shells out to `rocm-smi` once at
/// startup, this reads plain sysfs files (gpu_busy_percent, mem_info_vram_*,
/// hwmon temp/power) so it can be polled every 2 s by the dashboard without
/// spawning processes. The root is injectable so tests can point it at a fake
/// sysfs tree.
class GpuMetricsService {
  final String drmRoot;

  GpuMetricsService({this.drmRoot = '/sys/class/drm'});

  static final _cardDirPattern = RegExp(r'^card\d+$');

  /// Metrics for every amdgpu card, ordered by card id. Connector entries
  /// (card1-DP-1, ...) and cards bound to other drivers are skipped.
  Future<List<GpuMetrics>> readAll() async {
    final root = Directory(drmRoot);
    if (!root.existsSync()) return const [];

    final cards = <GpuMetrics>[];
    for (final entry in root.listSync()) {
      final name = entry.uri.pathSegments.lastWhere((s) => s.isNotEmpty);
      if (!_cardDirPattern.hasMatch(name)) continue;

      final device = '${entry.path}/device';
      final uevent = _readString('$device/uevent');
      if (uevent == null || !uevent.contains('DRIVER=amdgpu')) continue;

      final pciId = RegExp(r'PCI_ID=(\S+)').firstMatch(uevent)?.group(1);
      final temp = _readInt(_findHwmonFile(device, 'temp1_input'));
      final power = _readInt(_findHwmonFile(device, 'power1_average'));

      cards.add(
        GpuMetrics(
          cardId: name,
          pciId: pciId,
          busyPercent: _readInt('$device/gpu_busy_percent'),
          vramUsedBytes: _readInt('$device/mem_info_vram_used'),
          vramTotalBytes: _readInt('$device/mem_info_vram_total'),
          temperatureC: temp != null ? temp / 1000 : null,
          powerWatts: power != null ? power / 1000000 : null,
        ),
      );
    }

    cards.sort((a, b) => a.cardId.compareTo(b.cardId));
    return cards;
  }

  /// The most capable card — largest VRAM wins, so the discrete GPU is
  /// preferred over an integrated APU. Null when no amdgpu card exists.
  Future<GpuMetrics?> readPrimary() async {
    final all = await readAll();
    if (all.isEmpty) return null;
    all.sort(
      (a, b) => (b.vramTotalBytes ?? 0).compareTo(a.vramTotalBytes ?? 0),
    );
    return all.first;
  }

  /// First hwmon channel exposing [sensor], e.g. hwmon7/temp1_input.
  String? _findHwmonFile(String device, String sensor) {
    final hwmonRoot = Directory('$device/hwmon');
    if (!hwmonRoot.existsSync()) return null;
    for (final hwmon in hwmonRoot.listSync()) {
      final candidate = '${hwmon.path}/$sensor';
      if (File(candidate).existsSync()) return candidate;
    }
    return null;
  }

  String? _readString(String? path) {
    if (path == null) return null;
    try {
      return File(path).readAsStringSync().trim();
    } catch (_) {
      return null;
    }
  }

  int? _readInt(String? path) {
    final raw = _readString(path);
    return raw != null ? int.tryParse(raw) : null;
  }
}
