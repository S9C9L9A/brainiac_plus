import 'dart:math';

import 'package:brainiac_plus/core/navigation/navigation_service.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../models/social_media_service.dart';
import '../social_media_card.dart';

class SocialMediaServicesSection extends StatelessWidget {
  final List<SocialMediaService> services;

  const SocialMediaServicesSection({
    super.key,
    required this.services,
  });

  @override
  Widget build(BuildContext context) {
    if (services.isEmpty) {
      return _buildEmptyState(context);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final gridSpec = _gridSpecForWidth(constraints.maxWidth, services.length);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Social Media',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    NavigationService().navigateToTab(
                      context,
                      NavigationService.tabSettings,
                    );
                  },
                  icon: const Icon(Icons.add, color: Colors.white70),
                  label: const Text(
                    'Add Service',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: gridSpec.crossAxisCount,
                childAspectRatio: gridSpec.childAspectRatio,
                crossAxisSpacing: gridSpec.spacing,
                mainAxisSpacing: gridSpec.spacing,
              ),
              itemCount: services.length,
              itemBuilder: (context, index) {
                return SocialMediaCard(service: services[index]);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 600;
        final padding = isCompact ? 24.0 : 40.0;
        final iconSize = isCompact ? 44.0 : 56.0;
        final titleSize = isCompact ? 18.0 : 22.0;
        final bodySize = isCompact ? 12.0 : 14.0;

        return Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.purple.withOpacity(0.2),
                Colors.blue.withOpacity(0.2),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(isCompact ? 18 : 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.15),
                      Colors.white.withOpacity(0.05),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: FaIcon(
                  FontAwesomeIcons.shareNodes,
                  color: Colors.white.withOpacity(0.9),
                  size: iconSize,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No Social Media Configured',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: titleSize,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Connect your social media accounts to monitor\nyour online presence and engagement',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.75),
                  fontSize: bodySize,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: () {
                  NavigationService().navigateToTab(
                    context,
                    NavigationService.tabSettings,
                  );
                },
                icon: const FaIcon(FontAwesomeIcons.plus, size: 16),
                label: const Text(
                  'Add Service',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue[700],
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 16,
                  ),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  _GridSpec _gridSpecForWidth(double width, int serviceCount) {
    if (width < 600) {
      return _GridSpec(
        crossAxisCount: min(1, serviceCount),
        childAspectRatio: 1.35,
        spacing: 12,
      );
    }

    if (width < 900) {
      return _GridSpec(
        crossAxisCount: min(2, serviceCount),
        childAspectRatio: 1.3,
        spacing: 14,
      );
    }

    if (width < 1200) {
      return _GridSpec(
        crossAxisCount: min(3, serviceCount),
        childAspectRatio: 1.2,
        spacing: 16,
      );
    }

    return _GridSpec(
      crossAxisCount: min(4, serviceCount),
      childAspectRatio: 1.25,
      spacing: 16,
    );
  }
}

class _GridSpec {
  final int crossAxisCount;
  final double childAspectRatio;
  final double spacing;

  const _GridSpec({
    required this.crossAxisCount,
    required this.childAspectRatio,
    required this.spacing,
  });
}
