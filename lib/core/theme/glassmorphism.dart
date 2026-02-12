import 'dart:ui';
import 'package:flutter/material.dart';
import 'colors.dart';

/// Glassmorphism Card Widget
/// iOS 17 / Nothing OS inspired glass effect
class GlassCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final Border? border;

  const GlassCard({
    super.key,
    required this.child,
    this.blur = 10.0,
    this.opacity = 0.1,
    this.borderRadius,
    this.padding,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(opacity),
            borderRadius: borderRadius ?? BorderRadius.circular(20),
            border: border ?? Border.all(
              color: isDark ? AppColors.glassBorderDark : AppColors.glassBorder,
              width: 1.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Blur Container - Frosted glass effect
class BlurContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final Color? color;
  final EdgeInsetsGeometry? padding;

  const BlurContainer({
    super.key,
    required this.child,
    this.blur = 15.0,
    this.color,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
      child: Container(
        padding: padding,
        color: color ?? Colors.white.withOpacity(0.05),
        child: child,
      ),
    );
  }
}

/// Nothing OS Glyph Interface Element
class NothingGlyph extends StatelessWidget {
  final bool isActive;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;

  const NothingGlyph({
    super.key,
    this.isActive = false,
    this.size = 24.0,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive 
            ? (activeColor ?? AppColors.glyphRed)
            : (inactiveColor ?? Colors.transparent),
        border: Border.all(
          color: isActive 
              ? (activeColor ?? AppColors.glyphRed)
              : AppColors.systemGray3,
          width: 2,
        ),
      ),
    );
  }
}
