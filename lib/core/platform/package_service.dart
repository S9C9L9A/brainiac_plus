import 'dart:io';

/// Package information
class PackageInfo {
  final String name;
  final String version;
  final String? description;
  final bool isInstalled;
  final String source; // apt, snap, flatpak

  PackageInfo({
    required this.name,
    required this.version,
    this.description,
    required this.isInstalled,
    required this.source,
  });
}

/// Package manager service
class PackageService {
  /// List installed apt packages
  Future<List<PackageInfo>> listAptPackages() async {
    try {
      final result = await Process.run('dpkg', ['-l']);
      final lines = result.stdout.toString().split('\n');
      
      final packages = <PackageInfo>[];
      for (var line in lines) {
        if (line.startsWith('ii')) {
          final parts = line.split(RegExp(r'\s+'));
          if (parts.length >= 3) {
            packages.add(PackageInfo(
              name: parts[1],
              version: parts[2],
              description: parts.length > 3 ? parts.sublist(3).join(' ') : null,
              isInstalled: true,
              source: 'apt',
            ));
          }
        }
      }
      return packages;
    } catch (e) {
      return [];
    }
  }

  /// List installed snap packages
  Future<List<PackageInfo>> listSnapPackages() async {
    try {
      final result = await Process.run('snap', ['list']);
      final lines = result.stdout.toString().split('\n');
      
      final packages = <PackageInfo>[];
      for (var i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        
        final parts = line.split(RegExp(r'\s+'));
        if (parts.isNotEmpty) {
          packages.add(PackageInfo(
            name: parts[0],
            version: parts.length > 1 ? parts[1] : 'unknown',
            description: parts.length > 4 ? parts[4] : null,
            isInstalled: true,
            source: 'snap',
          ));
        }
      }
      return packages;
    } catch (e) {
      return [];
    }
  }

  /// Search apt packages
  Future<List<PackageInfo>> searchApt(String query) async {
    try {
      final result = await Process.run('apt', ['search', query]);
      final lines = result.stdout.toString().split('\n');
      
      final packages = <PackageInfo>[];
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.contains('/')) {
          final parts = line.split(' ');
          if (parts.isNotEmpty) {
            final namePart = parts[0].split('/')[0];
            packages.add(PackageInfo(
              name: namePart,
              version: 'available',
              description: lines.length > i + 1 ? lines[i + 1].trim() : null,
              isInstalled: false,
              source: 'apt',
            ));
          }
        }
      }
      return packages;
    } catch (e) {
      return [];
    }
  }

  /// Install package
  Future<String> installPackage(String packageName, String source) async {
    try {
      ProcessResult result;
      
      switch (source) {
        case 'apt':
          result = await Process.run('sudo', ['apt', 'install', '-y', packageName]);
          break;
        case 'snap':
          result = await Process.run('sudo', ['snap', 'install', packageName]);
          break;
        default:
          return 'Unsupported package source: $source';
      }
      
      if (result.exitCode == 0) {
        return 'Package installed successfully';
      } else {
        return 'Installation failed: ${result.stderr}';
      }
    } catch (e) {
      return 'Error: $e';
    }
  }

  /// Remove package
  Future<String> removePackage(String packageName, String source) async {
    try {
      ProcessResult result;
      
      switch (source) {
        case 'apt':
          result = await Process.run('sudo', ['apt', 'remove', '-y', packageName]);
          break;
        case 'snap':
          result = await Process.run('sudo', ['snap', 'remove', packageName]);
          break;
        default:
          return 'Unsupported package source: $source';
      }
      
      if (result.exitCode == 0) {
        return 'Package removed successfully';
      } else {
        return 'Removal failed: ${result.stderr}';
      }
    } catch (e) {
      return 'Error: $e';
    }
  }

  /// Update package lists
  Future<String> updatePackageLists() async {
    try {
      final result = await Process.run('sudo', ['apt', 'update']);
      if (result.exitCode == 0) {
        return 'Package lists updated';
      } else {
        return 'Update failed: ${result.stderr}';
      }
    } catch (e) {
      return 'Error: $e';
    }
  }

  /// Upgrade packages
  Future<String> upgradePackages() async {
    try {
      final result = await Process.run('sudo', ['apt', 'upgrade', '-y']);
      if (result.exitCode == 0) {
        return 'Packages upgraded successfully';
      } else {
        return 'Upgrade failed: ${result.stderr}';
      }
    } catch (e) {
      return 'Error: $e';
    }
  }
}
