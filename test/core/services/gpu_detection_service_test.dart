import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:brainiac_plus/core/services/gpu_detection_service.dart';

/// Builds a [ProcessRunner] that returns canned [ProcessResult]s keyed by
/// executable name, so detection can be tested without a real GPU.
ProcessRunner fakeRunner(Map<String, ProcessResult> responses) {
  return (String executable, List<String> arguments) async {
    final result = responses[executable];
    if (result == null) {
      // Mimic a missing binary: dart throws a ProcessException.
      throw ProcessException(executable, arguments, 'not found', 2);
    }
    return result;
  };
}

ProcessResult ok(String stdout) => ProcessResult(0, 0, stdout, '');
ProcessResult fail([int code = 1]) => ProcessResult(0, code, '', 'error');

// Real payload captured from `rocm-smi --showproductname --showmeminfo vram
// --json` on the Radeon AI PRO R9700 host: card0 is the discrete GPU, card1 is
// the Ryzen integrated APU.
const _r9700Json =
    '{"card0": {"VRAM Total Memory (B)": "34208743424", "VRAM Total Used Memory (B)": "889229312", "Card Series": "AMD Radeon AI PRO R9700", "Card Model": "0x7551", "Card Vendor": "Advanced Micro Devices, Inc. [AMD/ATI]", "Card SKU": "R9700AT", "GFX Version": "gfx1201"}, "card1": {"VRAM Total Memory (B)": "2147483648", "VRAM Total Used Memory (B)": "45359104", "Card Series": "AMD Ryzen 9 9950X3D 16-Core Processor", "Card Model": "0x13c0", "Card Vendor": "Advanced Micro Devices, Inc. [AMD/ATI]", "Card SKU": "RAPHAEL", "GFX Version": "gfx1036"}}';

void main() {
  group('GpuDetectionService.parseRocmJson', () {
    final service = GpuDetectionService();

    test('picks the discrete GPU over the integrated APU', () {
      final info = service.parseRocmJson(_r9700Json);

      expect(info, isNotNull);
      expect(info!.vendor, GpuVendor.amd);
      expect(info.name, 'AMD Radeon AI PRO R9700');
      expect(info.gfxVersion, 'gfx1201');
      // 34208743424 B / 1024^2 ≈ 32624 MB
      expect(info.memoryMB, 32624);
      expect(info.hasGpu, isTrue);
    });

    test('falls back to largest-VRAM card when only an APU is present', () {
      const apuOnly =
          '{"card0": {"VRAM Total Memory (B)": "2147483648", "Card Series": "AMD Ryzen 9 9950X3D 16-Core Processor", "GFX Version": "gfx1036"}}';
      final info = service.parseRocmJson(apuOnly);

      expect(info, isNotNull);
      expect(info!.vendor, GpuVendor.amd);
      expect(info.memoryMB, 2048);
    });

    test('returns null on malformed JSON', () {
      expect(service.parseRocmJson('not json'), isNull);
    });

    test('returns null on non-object JSON', () {
      expect(service.parseRocmJson('[]'), isNull);
    });

    test('handles missing VRAM field by reporting null memory', () {
      const noMem =
          '{"card0": {"Card Series": "AMD Radeon RX 7900 XTX", "GFX Version": "gfx1100"}}';
      final info = service.parseRocmJson(noMem);

      expect(info, isNotNull);
      expect(info!.name, 'AMD Radeon RX 7900 XTX');
      expect(info.memoryMB, isNull);
    });
  });

  group('GpuDetectionService.detect', () {
    test('detects AMD GPU via rocm-smi', () async {
      final service = GpuDetectionService(
        runner: fakeRunner({'rocm-smi': ok(_r9700Json)}),
      );
      final info = await service.detect();

      expect(info.vendor, GpuVendor.amd);
      expect(info.name, 'AMD Radeon AI PRO R9700');
      expect(info.memoryMB, 32624);
    });

    test('falls back to NVIDIA when rocm-smi is absent', () async {
      final service = GpuDetectionService(
        runner: fakeRunner({
          'nvidia-smi': ok('NVIDIA GeForce RTX 4090, 24564'),
        }),
      );
      final info = await service.detect();

      expect(info.vendor, GpuVendor.nvidia);
      expect(info.name, 'NVIDIA GeForce RTX 4090');
      expect(info.memoryMB, 24564);
    });

    test('returns none when no GPU tooling is available', () async {
      final service = GpuDetectionService(runner: fakeRunner({}));
      final info = await service.detect();

      expect(info.vendor, GpuVendor.none);
      expect(info.hasGpu, isFalse);
      expect(info.memoryMB, isNull);
    });

    test('returns none when rocm-smi exits non-zero and no NVIDIA', () async {
      final service = GpuDetectionService(
        runner: fakeRunner({'rocm-smi': fail()}),
      );
      final info = await service.detect();

      expect(info.hasGpu, isFalse);
    });

    test('prefers AMD over NVIDIA when both are present', () async {
      final service = GpuDetectionService(
        runner: fakeRunner({
          'rocm-smi': ok(_r9700Json),
          'nvidia-smi': ok('NVIDIA GeForce RTX 4090, 24564'),
        }),
      );
      final info = await service.detect();

      expect(info.vendor, GpuVendor.amd);
    });
  });

  group('GpuInfo', () {
    test('none sentinel reports no GPU', () {
      const info = GpuInfo.none();
      expect(info.hasGpu, isFalse);
      expect(info.toString(), 'GpuInfo(none)');
    });

    test('toString includes name and memory when present', () {
      const info = GpuInfo(
        vendor: GpuVendor.amd,
        name: 'AMD Radeon AI PRO R9700',
        memoryMB: 32624,
        gfxVersion: 'gfx1201',
      );
      expect(info.toString(), contains('AMD Radeon AI PRO R9700'));
      expect(info.toString(), contains('32624'));
      expect(info.toString(), contains('gfx1201'));
    });
  });
}
