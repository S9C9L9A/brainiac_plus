import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/glassmorphism.dart';
import '../../dashboard/dashboard_screen.dart';

class MarketplaceTab extends ConsumerStatefulWidget {
  const MarketplaceTab({super.key});

  @override
  ConsumerState<MarketplaceTab> createState() => _MarketplaceTabState();
}

class _MarketplaceTabState extends ConsumerState<MarketplaceTab> {
  String _searchQuery = '';

  final List<MarketplaceAutomation> _mockAutomations = [
    MarketplaceAutomation(
      name: 'AI Content Creator Pro',
      author: 'AutomationHub',
      description: 'Create and publish AI-generated content across all social platforms',
      downloads: 15420,
      rating: 4.8,
      price: 0,
      category: 'Social Media',
      tags: ['AI', 'Content', 'Multi-platform'],
    ),
    MarketplaceAutomation(
      name: 'Instagram Growth Bot',
      author: 'GrowthExperts',
      description: 'Automated engagement, DM responses, and follower growth strategies',
      downloads: 8930,
      rating: 4.6,
      price: 9.99,
      category: 'Social Media',
      tags: ['Instagram', 'Growth', 'Engagement'],
      isPro: true,
    ),
    MarketplaceAutomation(
      name: 'Notion Project Manager',
      author: 'ProductivityMax',
      description: 'Sync tasks, deadlines, and team updates across Notion and other tools',
      downloads: 5670,
      rating: 4.9,
      price: 0,
      category: 'Productivity',
      tags: ['Notion', 'Project Management'],
    ),
    MarketplaceAutomation(
      name: 'Email to Task Converter',
      author: 'WorkflowWizard',
      description: 'Automatically convert emails into actionable tasks in your favorite apps',
      downloads: 3220,
      rating: 4.7,
      price: 4.99,
      category: 'Productivity',
      tags: ['Email', 'Tasks', 'Automation'],
      isPro: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _searchQuery.isEmpty
        ? _mockAutomations
        : _mockAutomations
            .where((a) =>
                a.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                a.description.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    return Column(
      children: [
        _buildSearchBar(),
        _buildCategoryTabs(),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, kBottomNavHeight),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return _buildMarketplaceCard(filtered[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: TextField(
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search marketplace...',
          hintStyle: const TextStyle(color: Colors.white60),
          prefixIcon: const Icon(Icons.search, color: Colors.white70),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (value) => setState(() => _searchQuery = value),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      height: 50,
      margin: const EdgeInsets.only(top: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _buildCategoryChip('All', Icons.grid_view),
          _buildCategoryChip('Popular', Icons.trending_up),
          _buildCategoryChip('New', Icons.fiber_new),
          _buildCategoryChip('Free', Icons.money_off),
          _buildCategoryChip('Pro', Icons.star),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.white70),
            const SizedBox(width: 6),
            Text(label),
          ],
        ),
        onSelected: (_) {},
        backgroundColor: Colors.white.withValues(alpha: 0.1),
        labelStyle: const TextStyle(color: Colors.white70),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
      ),
    );
  }

  Widget _buildMarketplaceCard(MarketplaceAutomation automation) {
    return GlassCard(
      child: InkWell(
        onTap: () => _showAutomationDetails(automation),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.purple, Colors.blue],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                automation.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (automation.isPro)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Colors.amber, Colors.orange],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'PRO',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'by ${automation.author}',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                automation.description,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: automation.tags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    automation.rating.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.download, color: Colors.white70, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${automation.downloads}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () => _installAutomation(automation),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: automation.price > 0
                          ? Colors.amber
                          : AppColors.systemBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          automation.price > 0 ? Icons.shopping_cart : Icons.download,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          automation.price > 0
                              ? '\$${automation.price}'
                              : 'Free',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAutomationDetails(MarketplaceAutomation automation) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.black.withValues(alpha: 0.95),
              Colors.purple.withValues(alpha: 0.3),
            ],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.purple, Colors.blue],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.auto_awesome,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                automation.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'by ${automation.author}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        _buildStatBadge(
                          Icons.star,
                          automation.rating.toString(),
                          Colors.amber,
                        ),
                        const SizedBox(width: 12),
                        _buildStatBadge(
                          Icons.download,
                          '${automation.downloads}',
                          AppColors.systemBlue,
                        ),
                        const SizedBox(width: 12),
                        _buildStatBadge(
                          Icons.category,
                          automation.category,
                          AppColors.systemGreen,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Description',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      automation.description,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Tags',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: automation.tags.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _installAutomation(automation);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: automation.price > 0
                            ? Colors.amber
                            : AppColors.systemBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            automation.price > 0
                                ? Icons.shopping_cart
                                : Icons.download,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            automation.price > 0
                                ? 'Buy for \$${automation.price}'
                                : 'Install for Free',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBadge(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _installAutomation(MarketplaceAutomation automation) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          automation.price > 0
              ? 'Purchase ${automation.name} for \$${automation.price}?'
              : 'Installing ${automation.name}...',
        ),
        backgroundColor: AppColors.systemBlue,
        action: automation.price > 0
            ? SnackBarAction(
                label: 'Confirm',
                textColor: Colors.white,
                onPressed: () {},
              )
            : null,
      ),
    );
  }
}

class MarketplaceAutomation {
  final String name;
  final String author;
  final String description;
  final int downloads;
  final double rating;
  final double price;
  final String category;
  final List<String> tags;
  final bool isPro;

  MarketplaceAutomation({
    required this.name,
    required this.author,
    required this.description,
    required this.downloads,
    required this.rating,
    required this.price,
    required this.category,
    required this.tags,
    this.isPro = false,
  });
}
