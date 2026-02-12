import 'dart:io';

/// File system item model
class FileItem {
  final String name;
  final String path;
  final bool isDirectory;
  final int size;
  final DateTime modified;
  final String permissions;

  FileItem({
    required this.name,
    required this.path,
    required this.isDirectory,
    required this.size,
    required this.modified,
    required this.permissions,
  });

  /// Format file size to human readable
  String get formattedSize {
    if (isDirectory) return '--';
    
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Get file extension
  String get extension {
    if (isDirectory) return '';
    final parts = name.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }

  /// Check if file is hidden
  bool get isHidden => name.startsWith('.');

  factory FileItem.fromFileSystemEntity(FileSystemEntity entity) {
    final stat = entity.statSync();
    final isDir = entity is Directory;
    
    return FileItem(
      name: entity.path.split('/').last,
      path: entity.path,
      isDirectory: isDir,
      size: isDir ? 0 : stat.size,
      modified: stat.modified,
      permissions: stat.modeString(),
    );
  }
}

/// File operations service
class FileService {
  /// List files in directory
  Future<List<FileItem>> listFiles(String path, {bool showHidden = false}) async {
    try {
      final dir = Directory(path);
      if (!await dir.exists()) {
        throw Exception('Directory does not exist: $path');
      }

      final entities = await dir.list().toList();
      final items = entities.map((e) => FileItem.fromFileSystemEntity(e)).toList();

      // Filter hidden files if needed
      final filtered = showHidden 
          ? items 
          : items.where((item) => !item.isHidden).toList();

      // Sort: directories first, then by name
      filtered.sort((a, b) {
        if (a.isDirectory && !b.isDirectory) return -1;
        if (!a.isDirectory && b.isDirectory) return 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

      return filtered;
    } catch (e) {
      throw Exception('Failed to list files: $e');
    }
  }

  /// Copy file or directory
  Future<void> copy(String source, String destination) async {
    final sourceEntity = FileSystemEntity.isDirectorySync(source)
        ? Directory(source)
        : File(source);

    if (sourceEntity is File) {
      await sourceEntity.copy(destination);
    } else if (sourceEntity is Directory) {
      // Recursive copy for directories
      await _copyDirectory(sourceEntity, Directory(destination));
    }
  }

  Future<void> _copyDirectory(Directory source, Directory destination) async {
    await destination.create(recursive: true);
    await for (var entity in source.list()) {
      final name = entity.path.split('/').last;
      if (entity is File) {
        await entity.copy('${destination.path}/$name');
      } else if (entity is Directory) {
        await _copyDirectory(entity, Directory('${destination.path}/$name'));
      }
    }
  }

  /// Move file or directory
  Future<void> move(String source, String destination) async {
    final sourceEntity = FileSystemEntity.isDirectorySync(source)
        ? Directory(source)
        : File(source);

    await sourceEntity.rename(destination);
  }

  /// Delete file or directory
  Future<void> delete(String path) async {
    final entity = FileSystemEntity.isDirectorySync(path)
        ? Directory(path)
        : File(path);

    if (entity is Directory) {
      await entity.delete(recursive: true);
    } else {
      await entity.delete();
    }
  }

  /// Rename file or directory
  Future<void> rename(String path, String newName) async {
    final entity = FileSystemEntity.isDirectorySync(path)
        ? Directory(path)
        : File(path);

    final parentPath = path.substring(0, path.lastIndexOf('/'));
    final newPath = '$parentPath/$newName';
    
    await entity.rename(newPath);
  }

  /// Create new directory
  Future<void> createDirectory(String path) async {
    await Directory(path).create(recursive: true);
  }

  /// Get file/directory info
  Future<Map<String, dynamic>> getInfo(String path) async {
    final entity = FileSystemEntity.isDirectorySync(path)
        ? Directory(path)
        : File(path);
    
    final stat = await entity.stat();
    
    return {
      'path': path,
      'type': entity is Directory ? 'directory' : 'file',
      'size': stat.size,
      'modified': stat.modified,
      'accessed': stat.accessed,
      'changed': stat.changed,
      'permissions': stat.modeString(),
    };
  }
}
