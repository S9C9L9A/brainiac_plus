import 'package:flutter/material.dart';
import '../../../core/platform/file_service.dart';
import '../../../core/theme/colors.dart';

class FileIcon extends StatelessWidget {
  final FileItem file;
  final double size;

  const FileIcon({super.key, required this.file, this.size = 24});

  @override
  Widget build(BuildContext context) {
    if (file.isDirectory) {
      return Icon(Icons.folder, color: AppColors.systemYellow, size: size);
    }

    final icon = _getIconForExtension(file.extension);
    final color = _getColorForExtension(file.extension);
    return Icon(icon, color: color, size: size);
  }

  IconData _getIconForExtension(String ext) {
    switch (ext) {
      case 'png': case 'jpg': case 'jpeg': case 'gif': case 'svg': return Icons.image;
      case 'mp4': case 'avi': case 'mov': return Icons.video_file;
      case 'mp3': case 'wav': return Icons.audio_file;
      case 'pdf': return Icons.picture_as_pdf;
      case 'doc': case 'docx': return Icons.description;
      case 'txt': case 'md': return Icons.text_snippet;
      case 'dart': case 'java': case 'py': case 'js': return Icons.code;
      case 'zip': case 'tar': case 'gz': return Icons.archive;
      default: return Icons.insert_drive_file;
    }
  }

  Color _getColorForExtension(String ext) {
    switch (ext) {
      case 'png': case 'jpg': return AppColors.systemPink;
      case 'mp4': case 'mov': return AppColors.systemPurple;
      case 'pdf': return AppColors.systemRed;
      case 'dart': case 'java': return AppColors.systemBlue;
      default: return AppColors.systemGray3;
    }
  }
}
