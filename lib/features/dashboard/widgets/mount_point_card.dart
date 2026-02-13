import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/glassmorphism.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/app_icons.dart';
import '../controllers/storage_controller.dart';

class MountPointCard extends StatelessWidget {
  final MountPoint mountPoint;
  final bool isDark;
  final VoidCallback onOpenInFileManager;
  final VoidCallback? onEject;
  final VoidCallback? onShowInfo;

  const MountPointCard({
    super.key,
    required this.mountPoint,
    required this.isDark,
    required this.onOpenInFileManager,
    this.onEject,
    this.onShowInfo,
  });

  @override
  Widget build(BuildContext context) {
    final usageColor = _getUsageColor();
    final deviceIcon = _getDeviceIcon();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with device info
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: usageColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(deviceIcon, color: usageColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mountPoint.device,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          mountPoint.fsType,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
                              ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '•',
                          style: TextStyle(
                            color: (isDark ? AppColors.textTertiaryDark : AppColors.textTertiary),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          mountPoint.size,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                '${mountPoint.percentage}%',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: usageColor,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Mount point path
          Row(
            children: [
              Icon(
                AppIcons.folder,
                size: 16,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                mountPoint.mountPoint,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: mountPoint.percentage / 100,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          usageColor,
                          usageColor.withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Usage info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${mountPoint.used} used',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 11,
                    ),
              ),
              Text(
                '${mountPoint.available} available',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 11,
                    ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: Colors.white24),
          const SizedBox(height: 12),

          // Action buttons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildActionButton(
                context,
                'Open',
                AppIcons.folderOpen,
                AppColors.systemBlue,
                onOpenInFileManager,
              ),
              if (mountPoint.isRemovable && onEject != null)
                _buildActionButton(
                  context,
                  'Eject',
                  LucideIcons.logOut,
                  AppColors.systemRed,
                  onEject!,
                ),
              if (onShowInfo != null)
                _buildActionButton(
                  context,
                  'Info',
                  AppIcons.info,
                  AppColors.systemPurple,
                  onShowInfo!,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getUsageColor() {
    switch (mountPoint.usageLevel) {
      case 'green':
        return AppColors.systemGreen;
      case 'yellow':
        return AppColors.systemYellow;
      case 'red':
        return AppColors.systemRed;
      default:
        return AppColors.systemBlue;
    }
  }

  IconData _getDeviceIcon() {
    switch (mountPoint.deviceType) {
      case 'usb':
        return LucideIcons.usb;
      case 'network':
        return LucideIcons.network;
      case 'loop':
        return LucideIcons.disc;
      case 'disk':
      default:
        return AppIcons.disk;
    }
  }
}
