import 'dart:convert';
import 'dart:io';

/// Signature for a process runner, injectable so detection logic can be
/// unit-tested without a real GPU / `rocm-smi` on the host.
typedef ProcessRunner =
    Future<ProcessResult> Function(String executable, List<String> arguments);

/// GPU vendor detected on the host.
enum GpuVendor { amd, nvidia, none }

/// Result of GPU detection.
///
/// Used by [SystemMetricsService] to populate `hasGpu` / `gpuMemoryMB` and by
/// the AI assistant to size models against available VRAM.
class GpuInfo {
  final GpuVendor vendor;

  /// Human-readable card name, e.g. "AMD Radeon AI PRO R9700".
  final String name;

  /// Total VRAM in MB, or null if it could not be read.
  final int? memoryMB;

  /// AMD GFX target (e.g. "gfx1201"), null for non-AMD or when unavailable.
  final String? gfxVersion;

  const GpuInfo({
    required this.vendor,
    required this.name,
    this.memoryMB,
    this.gfxVersion,
  });

  /// Sentinel for "no GPU detected".
  const GpuInfo.none()
    : vendor = GpuVendor.none,
      name = 'Unknown',
      memoryMB = null,
      gfxVersion = null;

  bool get hasGpu => vendor != GpuVendor.none;

  @override
  String toString() => hasGpu
      ? 'GpuInfo(${vendor.name}: $name, ${memoryMB ?? '?'} MB'
            '${gfxVersion != null ? ', $gfxVersion' : ''})'
      : 'GpuInfo(none)';
}

/// Detects the host GPU across AMD (ROCm) and NVIDIA.
///
/// AMD detection shells out to `rocm-smi --json` (the same source the project's
/// Python dashboards use); NVIDIA detection falls back to `nvidia-smi`. No
/// native bindings or extra dependencies are required — there is no maintained
/// Dart package for ROCm, and the "shell-out and parse" pattern matches the
/// rest of [SystemMetricsService].
class GpuDetectionService {
  final ProcessRunner _run;

  GpuDetectionService({ProcessRunner? runner}) : _run = runner ?? Process.run;

  /// Detect the most capable GPU available. Prefers AMD/ROCm, then NVIDIA,
  /// returning [GpuInfo.none] if neither tool reports a usable device.
  Future<GpuInfo> detect() async {
    final amd = await _detectAmd();
    if (amd != null) return amd;

    final nvidia = await _detectNvidia();
    if (nvidia != null) return nvidia;

    return const GpuInfo.none();
  }

  /// Detect an AMD GPU via `rocm-smi`. Returns null if rocm-smi is missing,
  /// fails, or reports no discrete GPU.
  Future<GpuInfo?> _detectAmd() async {
    try {
      final result = await _run('rocm-smi', [
        '--showproductname',
        '--showmeminfo',
        'vram',
        '--json',
      ]);
      if (result.exitCode != 0) return null;
      return parseRocmJson(result.stdout.toString());
    } catch (_) {
      return null;
    }
  }

  /// Parse the JSON emitted by
  /// `rocm-smi --showproductname --showmeminfo vram --json`.
  ///
  /// The payload is keyed by card (`card0`, `card1`, ...). Integrated APUs are
  /// reported as cards too (series ends with "Processor"); the discrete GPU is
  /// preferred, falling back to the largest-VRAM card if every card looks like
  /// an APU. Exposed (non-private) for direct unit testing of the parser.
  GpuInfo? parseRocmJson(String raw) {
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      return null;
    }
    if (decoded is! Map<String, dynamic>) return null;

    GpuInfo? bestDiscrete;
    GpuInfo? bestAny;

    for (final value in decoded.values) {
      if (value is! Map) continue;
      final card = value.cast<String, dynamic>();

      final series = (card['Card Series'] ?? '').toString().trim();
      final bytes = int.tryParse(
        (card['VRAM Total Memory (B)'] ?? '').toString().trim(),
      );
      if (bytes == null && series.isEmpty) continue;

      final memMB = bytes != null ? (bytes / (1024 * 1024)).round() : null;
      final gfx = card['GFX Version']?.toString().trim();

      final info = GpuInfo(
        vendor: GpuVendor.amd,
        name: series.isEmpty ? 'AMD GPU' : series,
        memoryMB: memMB,
        gfxVersion: (gfx == null || gfx.isEmpty) ? null : gfx,
      );

      if ((info.memoryMB ?? 0) > (bestAny?.memoryMB ?? -1)) bestAny = info;

      // Integrated APUs surface with "Processor" in the series name.
      final isApu = series.toLowerCase().contains('processor');
      if (!isApu && (info.memoryMB ?? 0) > (bestDiscrete?.memoryMB ?? -1)) {
        bestDiscrete = info;
      }
    }

    return bestDiscrete ?? bestAny;
  }

  /// Detect an NVIDIA GPU via `nvidia-smi`. Returns null if unavailable.
  Future<GpuInfo?> _detectNvidia() async {
    try {
      final result = await _run('nvidia-smi', [
        '--query-gpu=name,memory.total',
        '--format=csv,noheader,nounits',
      ]);
      if (result.exitCode != 0) return null;

      final line = result.stdout.toString().trim().split('\n').first.trim();
      if (line.isEmpty) return null;

      final parts = line.split(',');
      final name = parts.first.trim();
      final memMB = parts.length > 1 ? int.tryParse(parts[1].trim()) : null;
      if (name.isEmpty) return null;

      return GpuInfo(vendor: GpuVendor.nvidia, name: name, memoryMB: memMB);
    } catch (_) {
      return null;
    }
  }
}
