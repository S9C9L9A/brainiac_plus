import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../models/social_media_service.dart';
import 'social_media_card_layout.dart';
import 'social_media_card_utils.dart';

class SocialMediaCardMetrics extends StatelessWidget {
  final SocialMediaMetrics? metrics;
  final SocialMediaCardLayout layout;

  const SocialMediaCardMetrics({
    super.key,
    required this.metrics,
    required this.layout,
  });

  @override
  Widget build(BuildContext context) {
    if (metrics == null) {
      return _buildEmptyMetrics();
    }

    return Container(
      padding: layout.metricsPadding,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  label: 'Followers',
                  value: formatNumber(metrics!.followers),
                  icon: FontAwesomeIcons.users,
                  trend: calculateTrend(metrics!.followers),
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.2),
              ),
              Expanded(
                child: _buildMetricItem(
                  label: 'Posts',
                  value: formatNumber(metrics!.posts),
                  icon: FontAwesomeIcons.squarePen,
                  trend: null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.white.withOpacity(0.2), height: 1),
          const SizedBox(height: 12),
          _buildEngagementMetric(metrics!.engagementRate),
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required String label,
    required String value,
    required IconData icon,
    double? trend,
  }) {
    return Column(
      children: [
        FaIcon(
          icon,
          color: Colors.white.withOpacity(0.9),
          size: layout.metricIconSize,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: layout.metricValueSize,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            if (trend != null) ...[
              const SizedBox(width: 4),
              FaIcon(
                trend >= 0
                    ? FontAwesomeIcons.arrowTrendUp
                    : FontAwesomeIcons.arrowTrendDown,
                color: trend >= 0
                    ? const Color(0xFF4ADE80)
                    : const Color(0xFF87171),
                size: layout.metricLabelSize + 2,
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: layout.metricLabelSize,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _buildEngagementMetric(double rate) {
    final percentage = rate.clamp(0, 100);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                FaIcon(
                  FontAwesomeIcons.chartLine,
                  color: Colors.white.withOpacity(0.9),
                  size: layout.metricLabelSize + 3,
                ),
                const SizedBox(width: 8),
                Text(
                  'ENGAGEMENT',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: layout.engagementLabelSize,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: TextStyle(
                color: Colors.white,
                fontSize: layout.engagementValueSize,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.white.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              getEngagementColor(percentage.toDouble()),
            ),
            minHeight: layout.progressHeight,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyMetrics() {
    return Container(
      padding: layout.emptyMetricsPadding,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: FaIcon(
              FontAwesomeIcons.arrowsRotate,
              color: Colors.white.withOpacity(0.7),
              size: layout.emptyIconSize,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Tap to sync metrics',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: layout.engagementLabelSize + 2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Get latest data',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: layout.engagementLabelSize,
            ),
          ),
        ],
      ),
    );
  }
}
