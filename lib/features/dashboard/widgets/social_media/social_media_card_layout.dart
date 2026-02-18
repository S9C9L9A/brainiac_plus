import 'package:flutter/material.dart';

class SocialMediaCardLayout {
  final bool isCompact;
  final EdgeInsets contentPadding;
  final double cardRadius;
  final double iconPadding;
  final double iconRadius;
  final double iconSize;
  final double titleFontSize;
  final double platformFontSize;
  final EdgeInsets badgePadding;
  final double badgeRadius;
  final double badgeFontSize;
  final double badgeDotSize;
  final double metricIconSize;
  final double metricValueSize;
  final double metricLabelSize;
  final double engagementLabelSize;
  final double engagementValueSize;
  final double footerFontSize;
  final double footerIconSize;
  final double emptyIconSize;
  final double progressHeight;
  final double sectionGap;
  final EdgeInsets metricsPadding;
  final EdgeInsets emptyMetricsPadding;

  const SocialMediaCardLayout({
    required this.isCompact,
    required this.contentPadding,
    required this.cardRadius,
    required this.iconPadding,
    required this.iconRadius,
    required this.iconSize,
    required this.titleFontSize,
    required this.platformFontSize,
    required this.badgePadding,
    required this.badgeRadius,
    required this.badgeFontSize,
    required this.badgeDotSize,
    required this.metricIconSize,
    required this.metricValueSize,
    required this.metricLabelSize,
    required this.engagementLabelSize,
    required this.engagementValueSize,
    required this.footerFontSize,
    required this.footerIconSize,
    required this.emptyIconSize,
    required this.progressHeight,
    required this.sectionGap,
    required this.metricsPadding,
    required this.emptyMetricsPadding,
  });

  factory SocialMediaCardLayout.fromWidth(double width) {
    if (width < 280) {
      return const SocialMediaCardLayout(
        isCompact: true,
        contentPadding: EdgeInsets.all(14),
        cardRadius: 20,
        iconPadding: 10,
        iconRadius: 14,
        iconSize: 22,
        titleFontSize: 14,
        platformFontSize: 9,
        badgePadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        badgeRadius: 16,
        badgeFontSize: 9,
        badgeDotSize: 5,
        metricIconSize: 14,
        metricValueSize: 18,
        metricLabelSize: 8,
        engagementLabelSize: 9,
        engagementValueSize: 13,
        footerFontSize: 9,
        footerIconSize: 11,
        emptyIconSize: 20,
        progressHeight: 5,
        sectionGap: 10,
        metricsPadding: EdgeInsets.all(12),
        emptyMetricsPadding: EdgeInsets.symmetric(vertical: 18),
      );
    }

    if (width < 360) {
      return const SocialMediaCardLayout(
        isCompact: true,
        contentPadding: EdgeInsets.all(16),
        cardRadius: 22,
        iconPadding: 12,
        iconRadius: 14,
        iconSize: 24,
        titleFontSize: 15.5,
        platformFontSize: 10,
        badgePadding: EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        badgeRadius: 18,
        badgeFontSize: 9.5,
        badgeDotSize: 5.5,
        metricIconSize: 16,
        metricValueSize: 20,
        metricLabelSize: 9,
        engagementLabelSize: 10,
        engagementValueSize: 14,
        footerFontSize: 10,
        footerIconSize: 12,
        emptyIconSize: 22,
        progressHeight: 5,
        sectionGap: 12,
        metricsPadding: EdgeInsets.all(14),
        emptyMetricsPadding: EdgeInsets.symmetric(vertical: 20),
      );
    }

    return const SocialMediaCardLayout(
      isCompact: false,
      contentPadding: EdgeInsets.all(20),
      cardRadius: 24,
      iconPadding: 14,
      iconRadius: 16,
      iconSize: 28,
      titleFontSize: 17,
      platformFontSize: 11,
      badgePadding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      badgeRadius: 20,
      badgeFontSize: 10,
      badgeDotSize: 6,
      metricIconSize: 18,
      metricValueSize: 22,
      metricLabelSize: 10,
      engagementLabelSize: 11,
      engagementValueSize: 16,
      footerFontSize: 11,
      footerIconSize: 12,
      emptyIconSize: 24,
      progressHeight: 6,
      sectionGap: 14,
      metricsPadding: EdgeInsets.all(16),
      emptyMetricsPadding: EdgeInsets.symmetric(vertical: 24),
    );
  }
}
