import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eureka_app/services/checkpointFeedbackService.dart';

// Color Palette (matching the main feedback screen)
class AppColors {
  static const Color bg = Color(0xFFF6EDDA);
  static const Color card = Color(0xFFFFFBF2);
  static const Color ink = Color(0xFF0B1220);
  static const Color sub = Color(0xFF70695B);
  static const Color border = Color(0xFFE7DEC9);
  static const Color accent = Color(0xFF1D4ED8);
  static const Color good = Color(0xFF0F766E);
  static const Color warn = Color(0xFFB45309);
  static const Color bad = Color(0xFFDC2626);
}

class SubjectPalette {
  final Color dot;
  final Color light;

  const SubjectPalette({required this.dot, required this.light});

  static const Map<String, SubjectPalette> palettes = {
    'Mathematics': SubjectPalette(
      dot: Color(0xFF2563EB),
      light: Color(0x1A2563EB),
    ),
    'Science': SubjectPalette(
      dot: Color(0xFF059669),
      light: Color(0x1A059669),
    ),
    'History': SubjectPalette(
      dot: Color(0xFFD97706),
      light: Color(0x1AD97706),
    ),
    'English': SubjectPalette(
      dot: Color(0xFF7C3AED),
      light: Color(0x1A7C3AED),
    ),
    'Default': SubjectPalette(
      dot: Color(0xFF0EA5E9),
      light: Color(0x1A0EA5E9),
    ),
  };
}

class CompactFeedbackCard extends StatefulWidget {
  final CheckpointReport report;
  final int checkpointNumber;
  final VoidCallback? onTap;
  final bool showDismissButton;
  final Function()? onDismiss;

  const CompactFeedbackCard({
    Key? key,
    required this.report,
    required this.checkpointNumber,
    this.onTap,
    this.showDismissButton = false,
    this.onDismiss,
  }) : super(key: key);

  @override
  State<CompactFeedbackCard> createState() => _CompactFeedbackCardState();
}

class _CompactFeedbackCardState extends State<CompactFeedbackCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Helper function to convert percentage to grade
  String _getGradeFromPercentage(int percentage) {
    if (percentage >= 80) {
      return 'A+';
    } else if (percentage >= 65) {
      return 'A';
    } else if (percentage >= 30) {
      return 'B+';
    } else {
      return 'C';
    }
  }

  // Status helper
  Map<String, dynamic> _getStatusForScore(double score) {
    if (score >= 0.8) {
      return {'label': 'Mastered', 'color': const Color(0xFF16A34A)};
    } else if (score >= 0.5) {
      return {'label': 'On track', 'color': const Color(0xFFEAB308)};
    }
    return {'label': 'Needs work', 'color': AppColors.bad};
  }

  @override
  Widget build(BuildContext context) {
    final palette = SubjectPalette.palettes[widget.report.subject] ??
        SubjectPalette.palettes['Default']!;

    final objectivesScore = widget.report.objectives.isNotEmpty
        ? (widget.report.objectives
                    .map((o) => o.score)
                    .reduce((a, b) => a + b) /
                widget.report.objectives.length *
                100)
            .round()
        : 0;

    final status = _getStatusForScore(objectivesScore / 100);
    final resolvedCount = widget.report.gaps.where((g) => g.resolved).length;
    final completedObjectives =
        widget.report.objectives.where((o) => o.score >= 0.6).length;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(20),
                splashColor: palette.dot.withOpacity(0.1),
                highlightColor: palette.dot.withOpacity(0.05),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.border.withOpacity(0.5),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                        spreadRadius: -4,
                      ),
                      BoxShadow(
                        color: palette.dot.withOpacity(0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                        spreadRadius: -8,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Subtle gradient background
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                palette.light.withOpacity(0.3),
                                Colors.transparent,
                                palette.light.withOpacity(0.1),
                              ],
                              stops: const [0.0, 0.5, 1.0],
                            ),
                          ),
                        ),
                      ),

                      // Accent line on left
                      Positioned(
                        left: 0,
                        top: 20,
                        bottom: 20,
                        child: Container(
                          width: 3,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                palette.dot,
                                palette.dot.withOpacity(0.3),
                              ],
                            ),
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(2),
                              bottomRight: Radius.circular(2),
                            ),
                          ),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Row: Checkpoint + Status Tag
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Checkpoint ${widget.checkpointNumber + 1}',
                                  style: GoogleFonts.raleway(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.sub,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                if (widget.showDismissButton &&
                                    widget.onDismiss != null)
                                  GestureDetector(
                                    onTap: widget.onDismiss,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF70695B)
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(0xFF70695B)
                                              .withOpacity(0.3),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Dismiss',
                                            style: GoogleFonts.raleway(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF70695B),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            Icons.close,
                                            size: 12,
                                            color: const Color(0xFF70695B),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            // Hero Section: Mastery Score
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // Large mastery percentage
                                ShaderMask(
                                  shaderCallback: (bounds) => LinearGradient(
                                    colors: [
                                      palette.dot,
                                      palette.dot.withOpacity(0.7),
                                    ],
                                  ).createShader(bounds),
                                  child: Text(
                                    _getGradeFromPercentage(objectivesScore),
                                    style: GoogleFonts.raleway(
                                      fontSize: 36,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      height: 1.0,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                        padding: EdgeInsets.only(bottom: 4),
                                        child: Text(
                                          'Mastery',
                                          style: GoogleFonts.raleway(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w600,
                                            // fontStyle: FontStyle.italic,
                                            color: AppColors.ink,
                                            height: 1.0,
                                          ),
                                        )),
                                    // Text(
                                    //   _getGradeFromPercentage(objectivesScore),
                                    //   style: GoogleFonts.raleway(
                                    //     fontSize: 12,
                                    //     fontWeight: FontWeight.w500,
                                    //     color: status['color'],
                                    //     height: 1.0,
                                    //   ),
                                    // ),
                                  ],
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: (status['color'] as Color)
                                        .withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: (status['color'] as Color)
                                          .withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    status['label'],
                                    style: GoogleFonts.raleway(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: status['color'],
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 18),

                            // Sub-hero: Clarity & Depth
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                _buildSubMetric(
                                  '${widget.report.clarity.round()}%',
                                  'Clarity',
                                  Color.fromARGB(234, 251, 147, 1),
                                ),
                                const SizedBox(width: 24),
                                _buildSubMetric(
                                  '${widget.report.depth.round()}%',
                                  'Depth',
                                  const Color.fromARGB(255, 11, 53, 171),
                                ),
                                Spacer(),
                                // CTA Button

                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        palette.dot,
                                        palette.dot.withOpacity(0.8),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: palette.dot.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: widget.onTap,
                                      borderRadius: BorderRadius.circular(12),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 10),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'View',
                                              style: GoogleFonts.raleway(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Icon(
                                              Icons.arrow_forward_ios,
                                              size: 12,
                                              color: Colors.white,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 18),

                            // Summary text
                            Text(
                              widget.report.summary,
                              style: GoogleFonts.raleway(
                                fontSize: 13,
                                color: AppColors.ink.withOpacity(0.8),
                                height: 1.4,
                                letterSpacing: 0.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),

                            const SizedBox(height: 16),

                            // Bottom tags row
                            Row(
                              children: [
                                _buildBottomTag(
                                  // '$resolvedCount/${widget.report.gaps.length} gaps resolved',
                                  '${widget.report.gaps.length} gaps identified',

                                  AppColors.warn,
                                  Icons.psychology_outlined,
                                ),
                                const SizedBox(width: 12),
                                _buildBottomTag(
                                  '$completedObjectives/${widget.report.objectives.length} objectives',
                                  const Color(0xFF059669),
                                  Icons.check_circle_outline,
                                ),
                              ],
                            ),
                          ],
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

  Widget _buildSubMetric(String value, String label, Color color) {
    return CustomPaint(
      painter: DashedBorderPainter(
        color: color.withOpacity(0.5),
        strokeWidth: 1.5,
        dashLength: 4,
        dashSpace: 3,
        borderRadius: 12,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: GoogleFonts.raleway(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.raleway(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.sub,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomTag(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.raleway(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Painter for Dashed Border
class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double dashSpace;
  final double borderRadius;

  DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashLength,
    required this.dashSpace,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path();
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );

    path.addRRect(RRect.fromRectAndRadius(rect, Radius.circular(borderRadius)));

    final pathMetrics = path.computeMetrics();
    for (final pathMetric in pathMetrics) {
      double distance = 0;
      while (distance < pathMetric.length) {
        final nextDistance = distance + dashLength;
        final extractPath = pathMetric.extractPath(
          distance,
          nextDistance > pathMetric.length ? pathMetric.length : nextDistance,
        );
        canvas.drawPath(extractPath, paint);
        distance = nextDistance + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
