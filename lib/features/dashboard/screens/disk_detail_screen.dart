import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/glassmorphism.dart';
import '../controllers/process_controller.dart';

class DiskDetailScreen extends ConsumerStatefulWidget {
  const DiskDetailScreen({super.key});

  @override
  ConsumerState<DiskDetailScreen> createState() => _DiskDetailScreenState();
}

class _DiskDetailScreenState extends ConsumerState<DiskDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(diskControllerProvider.notifier).loadTopDirectories());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final directoriesAsync = ref.watch(diskControllerProvider);

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
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.systemOrange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.sd_storage, color: AppColors.systemOrange, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Disk Usage',
                            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            'Top directories by size',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withOpacity(0.8),
                                ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      onPressed: () {
                        ref.read(diskControllerProvider.notifier).loadTopDirectories();
                      },
                    ),
                  ],
                ),
              ),

              // Directory List
              Expanded(
                child: directoriesAsync.when(
                  data: (directories) {
                    if (directories.isEmpty) {
                      return Center(
                        child: Text(
                          'No directories found',
                          style: TextStyle(color: Colors.white.withOpacity(0.7)),
                        ),
                      );
                    }

                    final maxSize = directories.fold<double>(
                      0.0,
                      (max, dir) => dir.sizeInGB > max ? dir.sizeInGB : max,
                    );

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: directories.length,
                      itemBuilder: (context, index) {
                        final directory = directories[index];
                        return _buildDirectoryCard(context, directory, isDark, maxSize);
                      },
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.systemOrange),
                  ),
                  error: (error, stack) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, color: AppColors.systemRed, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading disk usage',
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

  Widget _buildDirectoryCard(BuildContext context, DiskInfo directory, bool isDark, double maxSize) {
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
    if (path.contains('home')) return Icons.home;
    if (path.contains('usr')) return Icons.apps;
    if (path.contains('var')) return Icons.folder_special;
    if (path.contains('tmp')) return Icons.delete_outline;
    if (path.contains('opt')) return Icons.category;
    if (path.contains('lib')) return Icons.library_books;
    if (path.contains('bin')) return Icons.code;
    if (path.contains('etc')) return Icons.settings;
    if (path.contains('root')) return Icons.shield;
    if (path.contains('snap')) return Icons.apps;
    return Icons.folder;
  }
}
