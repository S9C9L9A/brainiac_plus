import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../models/social_media_service.dart';
import 'social_media_card_layout.dart';
import 'social_media_card_utils.dart';

class SocialMediaCardHeader extends StatelessWidget {
  final SocialMediaService service;
  final SocialMediaCardLayout layout;

  const SocialMediaCardHeader({
    super.key,
    required this.service,
    required this.layout,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = service.isActive;

    return Row(
      children: [
        Hero(
          tag: 'social_icon_${service.id}',
          child: Container(
            padding: EdgeInsets.all(layout.iconPadding),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(layout.iconRadius),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: FaIcon(
              getPlatformIcon(service.platform),
              color: Colors.white,
              size: layout.iconSize,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                service.name,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: layout.titleFontSize,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                service.platform.displayName.toUpperCase(),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: layout.platformFontSize,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        _StatusBadge(
          isActive: isActive,
          layout: layout,
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isActive;
  final SocialMediaCardLayout layout;

  const _StatusBadge({
    required this.isActive,
    required this.layout,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: layout.badgePadding,
      decoration: BoxDecoration(
        color: isActive
            ? Colors.white.withOpacity(0.25)
            : Colors.black.withOpacity(0.15),
        borderRadius: BorderRadius.circular(layout.badgeRadius),
        border: Border.all(
          color: isActive
              ? Colors.white.withOpacity(0.4)
              : Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: layout.badgeDotSize,
            height: layout.badgeDotSize,
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFF4ADE80)
                  : const Color(0xFFFBBF24),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (isActive
                          ? const Color(0xFF4ADE80)
                          : const Color(0xFFFBBF24))
                      .withOpacity(0.5),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isActive ? 'LIVE' : 'PAUSED',
            style: TextStyle(
              color: Colors.white.withOpacity(0.95),
              fontSize: layout.badgeFontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
