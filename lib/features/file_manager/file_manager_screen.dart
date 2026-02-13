import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/glassmorphism.dart';
import '../../core/theme/app_icons.dart';
import 'controllers/file_controller.dart';
import 'widgets/file_list_item.dart';

class FileManagerScreen extends ConsumerWidget {
  const FileManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(fileManagerProvider);

    return Scaffold(
      body: Container(
        decoration: AppTheme.backgroundGradient(isDark),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              _buildAppBar(context, ref, state),

              // Path breadcrumb
              _buildPathBreadcrumb(context, ref, state),

              // File list
              Expanded(
                child: state.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : state.error != null
                        ? _buildError(context, state.error!)
                        : _buildFileList(context, ref, state),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFab(context, ref),
    );
  }

  Widget _buildAppBar(
    BuildContext context,
    WidgetRef ref,
    FileManagerState state,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(AppIcons.arrowBack, color: Colors.white, size: AppIcons.defaultSize),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 8),
            const Icon(AppIcons.folderOpen, color: Colors.white, size: AppIcons.defaultSize),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'File Manager',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            IconButton(
              icon: Icon(
                state.showHidden ? AppIcons.visibilityOn : AppIcons.visibilityOff,
                color: Colors.white,
                size: AppIcons.defaultSize,
              ),
              onPressed: () {
                ref.read(fileManagerProvider.notifier).toggleShowHidden();
              },
            ),
            IconButton(
              icon: const Icon(AppIcons.refresh, color: Colors.white, size: AppIcons.defaultSize),
              onPressed: () {
                ref.read(fileManagerProvider.notifier).loadFiles();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPathBreadcrumb(
    BuildContext context,
    WidgetRef ref,
    FileManagerState state,
  ) {
    final parts = state.currentPath.split('/').where((p) => p.isNotEmpty).toList();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(AppIcons.arrowUp, color: Colors.white, size: 20),
              onPressed: () {
                ref.read(fileManagerProvider.notifier).navigateUp();
              },
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildPathSegment(context, '/', () {
                      ref.read(fileManagerProvider.notifier).navigateTo('/');
                    }),
                    for (int i = 0; i < parts.length; i++) ...[
                      const Icon(AppIcons.chevronRight, color: Colors.white70, size: 16),
                      _buildPathSegment(context, parts[i], () {
                        final path = '/${parts.sublist(0, i + 1).join('/')}';
                        ref.read(fileManagerProvider.notifier).navigateTo(path);
                      }),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPathSegment(BuildContext context, String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildFileList(
    BuildContext context,
    WidgetRef ref,
    FileManagerState state,
  ) {
    if (state.files.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(AppIcons.folderOpen, color: Colors.white70, size: 64),
            const SizedBox(height: 16),
            Text(
              'Empty directory',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white70,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: state.files.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final file = state.files[index];
        
        return FileListItem(
          file: file,
          onTap: () {
            if (file.isDirectory) {
              ref.read(fileManagerProvider.notifier).navigateTo(file.path);
            } else {
              // TODO: Open file
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Open: ${file.name}')),
              );
            }
          },
          onLongPress: () {
            _showFileOptions(context, ref, file);
          },
        );
      },
    );
  }

  Widget _buildError(BuildContext context, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: GlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(AppIcons.error, color: AppColors.systemRed, size: 48),
              const SizedBox(height: 16),
              Text(
                'Error',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFab(BuildContext context, WidgetRef ref) {
    return FloatingActionButton(
      onPressed: () => _showCreateDialog(context, ref),
      backgroundColor: AppColors.systemBlue,
      child: const Icon(AppIcons.createFolder),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Directory'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Directory name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                ref
                    .read(fileManagerProvider.notifier)
                    .createDirectory(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showFileOptions(BuildContext context, WidgetRef ref, file) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(AppIcons.edit),
              title: const Text('Rename'),
              onTap: () {
                Navigator.pop(context);
                _showRenameDialog(context, ref, file);
              },
            ),
            ListTile(
              leading: const Icon(AppIcons.delete, color: AppColors.systemRed),
              title: const Text('Delete'),
              onTap: () {
                Navigator.pop(context);
                ref.read(fileManagerProvider.notifier).deleteItem(file.path);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context, WidgetRef ref, file) {
    final controller = TextEditingController(text: file.name);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'New name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty && controller.text != file.name) {
                ref
                    .read(fileManagerProvider.notifier)
                    .renameItem(file.path, controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }
}
