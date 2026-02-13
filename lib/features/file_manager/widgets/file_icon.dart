import 'package:flutter/material.dart';
import '../../../core/platform/file_service.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/app_icons.dart';

class FileIcon extends StatelessWidget {
  final FileItem file;
  final double size;

  const FileIcon({super.key, required this.file, this.size = 24});

  @override
  Widget build(BuildContext context) {
    if (file.isDirectory) {
      return Icon(AppIcons.folder, color: AppColors.systemYellow, size: size);
    }

    final icon = _getIconForExtension(file.extension);
    final color = _getColorForExtension(file.extension);
    return Icon(icon, color: color, size: size);
  }

  IconData _getIconForExtension(String ext) {
    switch (ext) {
      case 'png': case 'jpg': case 'jpeg': case 'gif': case 'svg': return AppIcons.fileImage;
      case 'mp4': case 'avi': case 'mov': return AppIcons.fileVideo;
      case 'mp3': case 'wav': return AppIcons.fileAudio;
      case 'pdf': return AppIcons.filePdf;
      case 'doc': case 'docx': return AppIcons.fileText;
      case 'txt': case 'md': return AppIcons.fileText;
      case 'dart': case 'java': case 'py': case 'js': return AppIcons.fileCode;
      case 'zip': case 'tar': case 'gz': return AppIcons.fileArchive;
      default: return AppIcons.file;
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
