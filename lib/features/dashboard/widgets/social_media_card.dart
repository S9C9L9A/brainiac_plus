import 'package:flutter/material.dart';
import '../models/social_media_service.dart';
import 'social_media/social_media_card_footer.dart';
import 'social_media/social_media_card_header.dart';
import 'social_media/social_media_card_layout.dart';
import 'social_media/social_media_card_metrics.dart';
import 'social_media/social_media_dot_pattern_painter.dart';

/// Card moderna che mostra le metriche di un servizio social configurato
class SocialMediaCard extends StatefulWidget {
  final SocialMediaService service;
  final VoidCallback? onTap;

  const SocialMediaCard({super.key, required this.service, this.onTap});

  @override
  State<SocialMediaCard> createState() => _SocialMediaCardState();
}

class _SocialMediaCardState extends State<SocialMediaCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.service.platform.brandColors;

    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = SocialMediaCardLayout.fromWidth(constraints.maxWidth);

        return MouseRegion(
          onEnter: (_) {
            setState(() => _isHovered = true);
            _controller.forward();
          },
          onExit: (_) {
            setState(() => _isHovered = false);
            _controller.reverse();
          },
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: GestureDetector(
              onTap: widget.onTap ?? () => _navigateToDetails(context),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(layout.cardRadius),
                  gradient: LinearGradient(
                    colors: [Color(colors[0]), Color(colors[1])],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(
                        colors[0],
                      ).withOpacity(_isHovered ? 0.5 : 0.3),
                      blurRadius: _isHovered ? 25 : 15,
                      offset: Offset(0, _isHovered ? 8 : 5),
                      spreadRadius: _isHovered ? 2 : 0,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(layout.cardRadius),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Opacity(
                          opacity: 0.05,
                          child: CustomPaint(
                            painter: SocialMediaDotPatternPainter(),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.15),
                                Colors.white.withOpacity(0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: layout.contentPadding,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SocialMediaCardHeader(
                              service: widget.service,
                              layout: layout,
                            ),
                            SizedBox(height: layout.sectionGap),
                            SocialMediaCardMetrics(
                              metrics: widget.service.metrics,
                              layout: layout,
                            ),
                            SizedBox(height: layout.sectionGap),
                            SocialMediaCardFooter(
                              lastSync: widget.service.lastSync,
                              layout: layout,
                            ),
                          ],
                        ),
                      ),
                      if (_isHovered)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.1),
                                  Colors.transparent,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _navigateToDetails(BuildContext context) {
    Navigator.pushNamed(
      context,
      '/social-media-detail',
      arguments: widget.service,
    );
  }
}
