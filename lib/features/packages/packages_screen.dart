import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/glassmorphism.dart';
import '../../core/platform/package_service.dart';
import 'controllers/package_controller.dart';

class PackagesScreen extends ConsumerStatefulWidget {
  const PackagesScreen({super.key});

  @override
  ConsumerState<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends ConsumerState<PackagesScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(packageProvider);

    return Scaffold(
      body: Container(
        decoration: AppTheme.backgroundGradient(isDark),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              _buildSearchBar(),
              _buildFilterTabs(),
              Expanded(
                child: state.isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                    : _buildPackageList(state.filteredPackages),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            const Icon(Icons.apps, color: Colors.white),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Package Manager',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () => ref.read(packageProvider.notifier).loadPackages(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search packages...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
            border: InputBorder.none,
            icon: const Icon(Icons.search, color: Colors.white70),
          ),
          onChanged: (value) {
            ref.read(packageProvider.notifier).setFilter(value);
          },
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    final state = ref.watch(packageProvider);
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildTabButton('All', 'all', state.source),
          const SizedBox(width: 8),
          _buildTabButton('APT', 'apt', state.source),
          const SizedBox(width: 8),
          _buildTabButton('Snap', 'snap', state.source),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, String value, String current) {
    final isSelected = current == value;
    
    return Expanded(
      child: InkWell(
        onTap: () => ref.read(packageProvider.notifier).setSource(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.systemBlue : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  Widget _buildPackageList(List<PackageInfo> packages) {
    if (packages.isEmpty) {
      return const Center(
        child: Text('No packages found', style: TextStyle(color: Colors.white70, fontSize: 16)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: packages.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final package = packages[index];
        return _buildPackageItem(package);
      },
    );
  }

  Widget _buildPackageItem(PackageInfo package) {
    return InkWell(
      onTap: () => _showPackageDetails(package),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getSourceColor(package.source).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getSourceIcon(package.source),
                color: _getSourceColor(package.source),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    package.name,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    package.version,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  if (package.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      package.description!,
                      style: const TextStyle(color: Colors.white60, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: package.isInstalled ? AppColors.systemGreen : AppColors.systemGray,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                package.isInstalled ? 'Installed' : 'Available',
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPackageDetails(PackageInfo package) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(package.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Version: ${package.version}', style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 16),
            if (package.description != null)
              Text(package.description!, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 24),
            if (package.isInstalled)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  ref.read(packageProvider.notifier).removePackage(package.name, package.source);
                },
                icon: const Icon(Icons.delete),
                label: const Text('Remove'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.systemRed,
                  minimumSize: const Size(double.infinity, 48),
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  ref.read(packageProvider.notifier).installPackage(package.name, package.source);
                },
                icon: const Icon(Icons.download),
                label: const Text('Install'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.systemGreen,
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getSourceIcon(String source) {
    switch (source) {
      case 'apt': return Icons.inventory_2;
      case 'snap': return Icons.widgets;
      default: return Icons.apps;
    }
  }

  Color _getSourceColor(String source) {
    switch (source) {
      case 'apt': return AppColors.systemOrange;
      case 'snap': return AppColors.systemGreen;
      default: return AppColors.systemBlue;
    }
  }
}
