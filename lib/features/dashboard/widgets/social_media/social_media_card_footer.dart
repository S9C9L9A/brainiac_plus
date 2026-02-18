import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'social_media_card_layout.dart';
import 'social_media_card_utils.dart';

class SocialMediaCardFooter extends StatelessWidget {
  final DateTime? lastSync;
  final SocialMediaCardLayout layout;

  const SocialMediaCardFooter({
    super.key,
    required this.lastSync,
    required this.layout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          FaIcon(
            FontAwesomeIcons.clock,
            color: Colors.white.withOpacity(0.7),
            size: layout.footerIconSize,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              lastSync != null
                  ? 'Updated ${getTimeAgo(lastSync!)}'
                  : 'Not synced yet',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: layout.footerFontSize,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          FaIcon(
            FontAwesomeIcons.chevronRight,
            color: Colors.white.withOpacity(0.6),
            size: layout.footerIconSize,
          ),
        ],
      ),
    );
  }
}
