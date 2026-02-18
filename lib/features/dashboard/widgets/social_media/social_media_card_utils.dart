import 'package:flutter/cupertino.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../models/social_media_service.dart';

IconData getPlatformIcon(SocialPlatform platform) {
  switch (platform) {
    case SocialPlatform.facebook:
      return FontAwesomeIcons.facebook;
    case SocialPlatform.instagram:
      return FontAwesomeIcons.instagram;
    case SocialPlatform.twitter:
      return FontAwesomeIcons.xTwitter;
    case SocialPlatform.linkedin:
      return FontAwesomeIcons.linkedin;
    case SocialPlatform.youtube:
      return FontAwesomeIcons.youtube;
    case SocialPlatform.tiktok:
      return FontAwesomeIcons.tiktok;
    default:
      return FontAwesomeIcons.shareNodes;
  }
}

Color getEngagementColor(double rate) {
  if (rate >= 7.0) return const Color(0xFF4ADE80); // Green - Excellent
  if (rate >= 4.0) return const Color(0xFF60A5FA); // Blue - Good
  if (rate >= 2.0) return const Color(0xFFFBBF24); // Yellow - Average
  return const Color(0xFFF87171); // Red - Needs work
}

String formatNumber(int number) {
  if (number >= 1000000) {
    return '${(number / 1000000).toStringAsFixed(1)}M';
  } else if (number >= 1000) {
    return '${(number / 1000).toStringAsFixed(1)}K';
  }
  return number.toString();
}

String getTimeAgo(DateTime dateTime) {
  final diff = DateTime.now().difference(dateTime);

  if (diff.inMinutes < 1) {
    return 'just now';
  } else if (diff.inHours < 1) {
    return '${diff.inMinutes}m ago';
  } else if (diff.inDays < 1) {
    return '${diff.inHours}h ago';
  } else if (diff.inDays < 7) {
    return '${diff.inDays}d ago';
  } else {
    return '${(diff.inDays / 7).floor()}w ago';
  }
}

double? calculateTrend(int currentValue) {
  // TODO: Implement trend calculation based on historical data.
  return null;
}
