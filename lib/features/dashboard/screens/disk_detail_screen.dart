import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/glassmorphism.dart';
import '../../../core/theme/app_icons.dart';
import '../../file_manager/file_manager_screen.dart';
import '../controllers/storage_controller.dart';
import '../widgets/mount_point_card.dart';

class DiskDetailScreen extends ConsumerStatefulWidget {
  const DiskDetailScreen({super.key});

  @override
  ConsumerState<DiskDetailScreen> createState() => _DiskDetailScreenState();
}

class _DiskDetailScreenState extends ConsumerState<DiskDetailScreen> {
  String? _selectedMountPoint;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(storageControllerProvider.notifier).loadAllMountPoints();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mountPointsAsync = ref.watch(storageControllerProvider);
    final directoriesAsync = ref.watch(directorySizesControllerProvider);

    return Scaffold(
      body: Container(
        decoration: AppTheme.backgroundGradient(isDark),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(AppIcons.arrowBack, color: Colors.white, size: AppIcons.defaultSize),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.systemOrange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(AppIcons.disk, color: AppColors.systemOrange, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Disk Space',
                            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            'All storage devices',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withOpacity(0.8),
                                ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(AppIcons.refresh, color: Colors.white, size: AppIcons.defaultSize),
                      onPressed: () {
                        ref.read(storageControllerProvider.notifier).loadAllMountPoints();
                        if (_selectedMountPoint != null) {
                          ref.read(directorySizesControllerProvider.notifier)
                              .loadDirectorySizes(_selectedMountPoint!);
                        }
                      },
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: mountPointsAsync.when(
                  data: (mountPoints) {
                    if (mountPoints.isEmpty) {
                      return Center(
                        child: Text(
                          'No storage devices found',
                          style: TextStyle(color: Colors.white.withOpacity(0.7)),
                        ),
                      );
                    }

                    // Auto-select mount point with most usage on first load
                    if (_selectedMountPoint == null && mountPoints.isNotEmpty) {
                      _selectedMountPoint = mountPoints
                          .reduce((a, b) => a.usedInGB > b.usedInGB ? a : b)
                          .mountPoint;
                      Future.microtask(() {
                        ref.read(directorySizesControllerProvider.notifier)
                            .loadDirectorySizes(_selectedMountPoint!);
                      });
                    }

                    final overview = StorageOverview.fromMountPoints(mountPoints);

                    return ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        // Storage Overview
                        _buildStorageOverview(context, overview, isDark),
                        const SizedBox(height: 24),

                        // Mount Points Section
                        Text(
                          'Storage Devices',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 12),

                        // Mount Points List
                        ...mountPoints.map((mp) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: MountPointCard(
                                mountPoint: mp,
                                isDark: isDark,
                                onOpenInFileManager: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => FileManagerScreen(
                                        initialPath: mp.mountPoint,
                                      ),
                                    ),
                                  );
                                },
                                onEject: mp.isRemovable
                                    ? () async {
                                        final deviceOps = ref.read(deviceOperationsProvider);
                                        final success = await deviceOps.ejectDevice(mp.device);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                success
                                                    ? 'Device ejected successfully'
                                                    : 'Failed to eject device',
                                              ),
                                              backgroundColor: success
                                                  ? AppColors.systemGreen
                                                  : AppColors.systemRed,
                                            ),
                                          );
                                          if (success) {
                                            ref.read(storageControllerProvider.notifier).loadAllMountPoints();
                                          }
                                        }
                                      }
                                    : null,
                                onShowInfo: () {
                                  _showDeviceInfo(context, mp, isDark);
                                },
                              ),
                            )),

                        const SizedBox(height: 24),

                        // Top Directories Section
                        _buildTopDirectoriesSection(
                          context,
                          mountPoints,
                          directoriesAsync,
                          isDark,
                        ),
                      ],
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.systemOrange),
                  ),
                  error: (error, stack) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(AppIcons.error, color: AppColors.systemRed, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading storage devices',
                          style: TextStyle(color: Colors.white.withOpacity(0.9)),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error.toString(),
                          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStorageOverview(BuildContext context, StorageOverview overview, bool isDark) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(AppIcons.disk, color: AppColors.systemOrange, size: 24),
              const SizedBox(width: 12),
              Text(
                'Total Storage Overview',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildOverviewStat(
                context,
                'Total',
                '${overview.totalGB.toStringAsFixed(1)} GB',
                AppColors.systemBlue,
                isDark,
              ),
              _buildOverviewStat(
                context,
                'Used',
                '${overview.usedGB.toStringAsFixed(1)} GB',
                AppColors.systemOrange,
                isDark,
              ),
              _buildOverviewStat(
                context,
                'Available',
                '${overview.availableGB.toStringAsFixed(1)} GB',
                AppColors.systemGreen,
                isDark,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: overview.totalGB > 0 ? overview.usedGB / overview.totalGB : 0,
              minHeight: 12,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                overview.averagePercentage < 70
                    ? AppColors.systemGreen
                    : overview.averagePercentage < 85
                        ? AppColors.systemYellow
                        : AppColors.systemRed,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${overview.averagePercentage}% average usage across all devices',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 11,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewStat(
    BuildContext context,
    String label,
    String value,
    Color color,
    bool isDark,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildTopDirectoriesSection(
    BuildContext context,
    List<MountPoint> mountPoints,
    AsyncValue<List<DirectoryInfo>> directoriesAsync,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Top Directories',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            // Mount point selector dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: DropdownButton<String>(
                value: _selectedMountPoint,
                dropdownColor: isDark ? const Color(0xFF1a1a2e) : Colors.white,
                underline: const SizedBox(),
                style: TextStyle(
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  fontSize: 14,
                ),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white, size: 20),
                items: mountPoints.map((mp) {
                  return DropdownMenuItem<String>(
                    value: mp.mountPoint,
                    child: Text(mp.mountPoint),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedMountPoint = value;
                    });
                    ref.read(directorySizesControllerProvider.notifier).loadDirectorySizes(value);
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        directoriesAsync.when(
          data: (directories) {
            if (directories.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'No directories found or permission denied',
                    style: TextStyle(color: Colors.white.withOpacity(0.6)),
                  ),
                ),
              );
            }

            final maxSize = directories.fold<double>(
              0.0,
              (max, dir) => dir.sizeInGB > max ? dir.sizeInGB : max,
            );

            return Column(
              children: directories.map((dir) {
                return _buildDirectoryCard(context, dir, isDark, maxSize);
              }).toList(),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: AppColors.systemOrange),
            ),
          ),
          error: (error, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Error loading directories',
                style: TextStyle(color: Colors.white.withOpacity(0.6)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDirectoryCard(BuildContext context, DirectoryInfo directory, bool isDark, double maxSize) {
    final percentage = maxSize > 0 ? (directory.sizeInGB / maxSize * 100).clamp(0.0, 100.0) : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getIconForPath(directory.path),
                  color: AppColors.systemOrange,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        directory.path,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Size: ${directory.size}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
                            ),
                      ),
                    ],
                  ),
                ),
                Text(
                  directory.size,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.systemOrange,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
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
                    widthFactor: percentage / 100,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.systemOrange,
                            AppColors.systemOrange.withOpacity(0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${percentage.toStringAsFixed(1)}% of largest directory',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 11,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForPath(String path) {
    if (path.contains('home')) return AppIcons.home;
    if (path.contains('usr')) return AppIcons.apps;
    if (path.contains('var')) return AppIcons.folder;
    if (path.contains('tmp')) return AppIcons.delete;
    if (path.contains('opt')) return AppIcons.apps;
    if (path.contains('lib')) return AppIcons.fileCode;
    if (path.contains('bin')) return AppIcons.fileCode;
    if (path.contains('etc')) return AppIcons.settings;
    if (path.contains('root')) return AppIcons.folder;
    if (path.contains('snap')) return AppIcons.apps;
    return AppIcons.folder;
  }

  void _showDeviceInfo(BuildContext context, MountPoint mp, bool isDark) async {
    final deviceOps = ref.read(deviceOperationsProvider);
    final info = await deviceOps.getDeviceInfo(mp.device);

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1a1a2e) : Colors.white,
        title: Row(
          children: [
            const Icon(AppIcons.info, color: AppColors.systemPurple),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Device Information',
                style: TextStyle(
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Device', mp.device, isDark),
            _buildInfoRow('Mount Point', mp.mountPoint, isDark),
            _buildInfoRow('File System', mp.fsType, isDark),
            _buildInfoRow('Size', mp.size, isDark),
            _buildInfoRow('Used', mp.used, isDark),
            _buildInfoRow('Available', mp.available, isDark),
            _buildInfoRow('Usage', '${mp.percentage}%', isDark),
            if (info.isNotEmpty) ...[
              const Divider(),
              ...info.entries.map((e) => _buildInfoRow(e.key, e.value, isDark)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
