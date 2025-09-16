import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eureka_app/services/checkpointFeedbackService.dart';

// Color Palette
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

class CheckpointFeedbackScreen extends StatefulWidget {
  final String conceptConversations;
  final int checkpointNumber;
  final CheckpointReport? initialReport;

  const CheckpointFeedbackScreen({
    Key? key,
    required this.conceptConversations,
    required this.checkpointNumber,
    this.initialReport,
  }) : super(key: key);

  @override
  State<CheckpointFeedbackScreen> createState() =>
      _CheckpointFeedbackScreenState();
}

class _CheckpointFeedbackScreenState extends State<CheckpointFeedbackScreen> {
  CheckpointReport? report;
  bool isLoading = true;
  String? errorMessage;

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

  @override
  void initState() {
    super.initState();
    if (widget.initialReport != null) {
      report = widget.initialReport;
      isLoading = false;
    } else {
      _loadCheckpointFeedback();
    }
  }

  Future<void> _loadCheckpointFeedback() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final feedbackData =
          await CheckpointFeedbackService.getCheckpointFeedback(
        conceptConversations: widget.conceptConversations,
        checkpointNumber: widget.checkpointNumber,
      );

      setState(() {
        report = feedbackData;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
        // Use sample data as fallback
        report = _getSampleReport();
      });
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

  void _showComingSoonMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.schedule,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text('Gap resolution coming soon!'),
          ],
        ),
        backgroundColor: AppColors.accent,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _toggleShowAllGaps() {
    if (report == null) return;

    setState(() {
      report = report!.copyWith(showAllGaps: !report!.showAllGaps);
    });
  }

  void _toggleObjective(String id) {
    if (report == null) return;

    setState(() {
      final objectives = report!.objectives
          .map((o) => o.id == id ? o.copyWith(open: !o.open) : o)
          .toList();

      report = report!.copyWith(objectives: objectives);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show loading state
    if (isLoading) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text(
                'Generating feedback for this checkpoint.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'It may take 5 seconds.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Show error state
    if (report == null) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.bad,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load checkpoint feedback',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  errorMessage!,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.sub,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadCheckpointFeedback,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                ),
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final palette = SubjectPalette.palettes[report!.subject] ??
        SubjectPalette.palettes['Default']!;

    final objectivesScore = report!.objectives.isNotEmpty
        ? (report!.objectives.map((o) => o.score).reduce((a, b) => a + b) /
                report!.objectives.length *
                100)
            .round()
        : 0;

    final status = _getStatusForScore(objectivesScore / 100);
    final resolvedCount = report!.gaps.where((g) => g.resolved).length;
    final topGaps =
        report!.showAllGaps ? report!.gaps : report!.gaps.take(2).toList();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          // Sticky Header
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              border: Border(
                bottom: BorderSide(color: AppColors.border),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Icon(
                          Icons.chevron_left,
                          size: 18,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            report!.title,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${report!.subject} · ${report!.checkpointTitle}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.sub,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (status['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: (status['color'] as Color).withOpacity(0.25),
                        ),
                      ),
                      child: Text(
                        status['label'],
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: status['color'],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  // Main Result Card
                  _buildResultCard(objectivesScore, status, palette),
                  const SizedBox(height: 12),

                  // Learning Gaps Section
                  if (report!.gaps.isNotEmpty) ...[
                    _buildSectionTitle(
                      'Learning gaps',
                      subtitle:
                          '$resolvedCount resolved · ${report!.gaps.length - resolvedCount} open',
                      tone: 'warn',
                    ),
                    const SizedBox(height: 8),
                    _buildLearningGapsSection(topGaps),
                    const SizedBox(height: 12),
                  ],

                  // Shining Moments Section
                  if (report!.shining.isNotEmpty) ...[
                    _buildSectionTitle('Shining moments', tone: 'good'),
                    const SizedBox(height: 8),
                    _buildShiningMomentsSection(),
                    const SizedBox(height: 12),
                  ],

                  // Objectives Section
                  if (report!.objectives.isNotEmpty) ...[
                    _buildSectionTitle('Objectives'),
                    const SizedBox(height: 8),
                    _buildObjectivesSection(),
                    const SizedBox(height: 12),
                  ],

                  // Articulation & Reasoning Section
                  _buildSectionTitle('Articulation & reasoning'),
                  const SizedBox(height: 8),
                  _buildArticulationSection(),
                  const SizedBox(height: 12),

                  // Quick Board Update Section
                  if (report!.boardDelta != null &&
                      (report!.boardDelta!.added.isNotEmpty ||
                          report!.boardDelta!.removed.isNotEmpty)) ...[
                    _buildSectionTitle('Learning moments'),
                    const SizedBox(height: 8),
                    _buildBoardUpdateSection(),
                    const SizedBox(height: 12),
                  ],

                  const SizedBox(height: 80), // Space for bottom bar
                ],
              ),
            ),
          ),
        ],
      ),

      // Bottom Action Bar
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.bg,
          border: Border(
            top: BorderSide(color: AppColors.border),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    '$resolvedCount/${report!.gaps.length} gaps resolved',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.sub,
                    ),
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, 'continue');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 8,
                    shadowColor: AppColors.accent.withOpacity(0.25),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Back to discussion',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard(int objectivesScore, Map<String, dynamic> status,
      SubjectPalette palette) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    palette.light,
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.6],
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Progress Ring
                _buildProgressRing(objectivesScore, status['color']),
                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Text(
                      //   'Checkpoint result',
                      //   style: GoogleFonts.inter(
                      //     fontSize: 14,
                      //     color: AppColors.sub,
                      //   ),
                      // ),
                      // const SizedBox(height: 8),

                      // Chips
                      // Wrap(
                      //   spacing: 8,
                      //   runSpacing: 4,
                      //   children: [
                      //     _buildChip(
                      //       icon: Icons.check_circle,
                      //       text:
                      //           'Objectives met ${report!.objectives.where((o) => o.score >= 1.0).length}/${report!.objectives.length}',
                      //       color: const Color(0xFF065F46),
                      //       bg: const Color(0xFFECFDF5),
                      //     ),
                      //     _buildChip(
                      //       icon: Icons.access_time,
                      //       text:
                      //           '${(report!.timeSpentSec / 60).floor()}m ${report!.timeSpentSec % 60}s',
                      //       color: const Color(0xFF1F2937),
                      //       bg: const Color(0xFFF3F4F6),
                      //     ),
                      //     if (report!.turns.hints > 0)
                      //       _buildChip(
                      //         icon: Icons.lightbulb_outline,
                      //         text:
                      //             '${report!.turns.hints} hint${report!.turns.hints > 1 ? 's' : ''}',
                      //         color: const Color(0xFF92400E),
                      //         bg: const Color(0xFFFFFBEB),
                      //       ),
                      //   ],
                      // ),

                      const SizedBox(height: 12),
                      Text(
                        report!.summary,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.ink,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRing(int percentage, Color color) {
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        children: [
          // Background circle
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: AppColors.border),
            ),
          ),

          // Progress circle
          CustomPaint(
            size: const Size(80, 80),
            painter: ProgressRingPainter(
              percentage: percentage / 100,
              color: color,
              strokeWidth: 2,
            ),
          ),

          // Center content
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _getGradeFromPercentage(percentage),
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink,
                    ),
                  ),
                  Text(
                    'mastery',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: AppColors.sub,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required IconData icon,
    required String text,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, {String? subtitle, String? tone}) {
    Color color = AppColors.ink;
    Color bgColor = AppColors.accent.withOpacity(0.08);
    IconData icon = Icons.info_outline;

    if (tone == 'good') {
      color = const Color(0xFF059669);
      bgColor = const Color(0xFF059669).withOpacity(0.12);
      icon = Icons.star_outline;
    } else if (tone == 'warn') {
      color = const Color(0xFFB45309);
      bgColor = const Color(0xFFB45309).withOpacity(0.12);
      icon = Icons.warning_amber_outlined;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(width: 8),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: color.withOpacity(0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLearningGapsSection(List<LearningGap> gaps) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xE6FFF1E6), // rgba(255,241,230,.9)
            AppColors.card,
          ],
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          ...gaps.map((gap) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildLearningGapCard(gap),
              )),
          if (report!.gaps.length > 2)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 4),
              child: OutlinedButton(
                onPressed: _toggleShowAllGaps,
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: Text(
                  report!.showAllGaps
                      ? 'Show less'
                      : 'Show all ${report!.gaps.length}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLearningGapCard(LearningGap gap) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warn.withOpacity(0.2)),
        color: const Color(0xFFFFF7ED),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_outlined,
                  size: 16,
                  color: AppColors.warn,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    gap.title,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.warn.withOpacity(0.2)),
                  ),
                  child: Text(
                    'Severity ${gap.severity}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.warn,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              children: [
                // Student quote
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GAP DETAIL',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.sub,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '"${gap.evidence}"',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Tutor note
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Color(0xFFEEF2FF), Colors.white],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TUTOR FIX',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.sub,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        gap.fix,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _showComingSoonMessage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF3F4F6),
                          foregroundColor: AppColors.sub,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: AppColors.border),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 16,
                              color: AppColors.sub,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Coming soon',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                color: AppColors.sub,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // OutlinedButton(
                    //   onPressed: () {
                    //     // Handle see example
                    //   },
                    //   style: OutlinedButton.styleFrom(
                    //     backgroundColor: Colors.white,
                    //     side: BorderSide(color: AppColors.border),
                    //     shape: RoundedRectangleBorder(
                    //       borderRadius: BorderRadius.circular(8),
                    //     ),
                    //     padding: const EdgeInsets.symmetric(
                    //       horizontal: 12,
                    //       vertical: 8,
                    //     ),
                    //   ),
                    //   child: Row(
                    //     mainAxisSize: MainAxisSize.min,
                    //     children: [
                    //       Icon(
                    //         Icons.info_outline,
                    //         size: 16,
                    //         color: AppColors.ink,
                    //       ),
                    //       const SizedBox(width: 4),
                    //       Text(
                    //         'See example',
                    //         style: GoogleFonts.inter(
                    //           fontSize: 14,
                    //           color: AppColors.ink,
                    //         ),
                    //       ),
                    //     ],
                    //   ),
                    // ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShiningMomentsSection() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xD9DEF7EC), // rgba(222,247,236,.85)
            AppColors.card,
          ],
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: report!.shining
            .map((moment) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0x2110B981)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.star_outline,
                        size: 16,
                        color: const Color(0xFF059669),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              moment.type,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '"${moment.quote}"',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppColors.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildObjectivesSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        children: report!.objectives
            .map((objective) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () => _toggleObjective(objective.id),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              _buildStatusDot(objective.score),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  objective.text,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ),
                              Icon(
                                objective.open
                                    ? Icons.keyboard_arrow_down
                                    : Icons.chevron_right,
                                size: 16,
                                color: AppColors.sub,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (objective.open)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'EVIDENCE',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.sub,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  objective.evidence,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildStatusDot(double score) {
    Color color;
    if (score >= 1.0) {
      color = const Color(0xFF16A34A);
    } else if (score >= 0.5) {
      color = const Color(0xFFEAB308);
    } else {
      color = AppColors.bad;
    }

    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildArticulationSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _buildMeterCard(
            'Clarity',
            report!.clarity,
            report!.clarityText,
            const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFDE68A), Color(0xFFFEF3C7)],
            ),
          ),
          const SizedBox(height: 12),
          _buildMeterCard(
            'Reasoning depth',
            report!.depth,
            report!.depthText,
            const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFC7D2FE), Color(0xFFE0E7FF)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeterCard(
      String label, double value, String tip, Gradient gradient) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        gradient: gradient,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            // mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSmallProgressRingWithPercentage(
                  value.round(), AppColors.accent),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  tip,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.ink,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallProgressRing(int percentage, Color color) {
    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        children: [
          CustomPaint(
            size: const Size(56, 56),
            painter: ProgressRingPainter(
              percentage: percentage / 100,
              color: color,
              strokeWidth: 2,
            ),
          ),
          Center(
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: AppColors.border),
              ),
              child: Center(
                child: Text(
                  _getGradeFromPercentage(percentage),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallProgressRingWithPercentage(int percentage, Color color) {
    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        children: [
          CustomPaint(
            size: const Size(56, 56),
            painter: ProgressRingPainter(
              percentage: percentage / 100,
              color: color,
              strokeWidth: 2,
            ),
          ),
          Center(
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: AppColors.border),
              ),
              child: Center(
                child: Text(
                  '$percentage%',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoardUpdateSection() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xD9DBEBFE), // rgba(219,234,254,.85)
            AppColors.card,
          ],
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          ...report!.boardDelta!.added.map(
              (text) => _buildDeltaRow('+', text, const Color(0xFF1D4ED8))),
          ...report!.boardDelta!.removed.map(
              (text) => _buildDeltaRow('−', text, const Color(0xFF991B1B))),
        ],
      ),
    );
  }

  Widget _buildDeltaRow(String sign, String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sign,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Sample data for testing/fallback
  CheckpointReport _getSampleReport() {
    return CheckpointReport(
      subject: 'Mathematics',
      title: 'Checkpoint 1 feedback',
      checkpointTitle: 'Spot the relationship',
      timeSpentSec: 218,
      turns: TurnsData(student: 4, assistant: 5, hints: 1),
      summary:
          'Correct rule surfaced; link to constant k was implicit. Add one more test pair to lock it in.',
      objectives: [
        Objective(
          id: 'o1',
          text: 'Define direct proportion in plain words.',
          score: 1.0,
          evidence: 'When x goes up, y goes up in the same ratio.',
        ),
        Objective(
          id: 'o2',
          text: 'Identify proportional pairs in stories.',
          score: 0.5,
          evidence:
              'Chose the doubling case correctly, missed the price/quantity counterexample.',
        ),
        Objective(
          id: 'o3',
          text: 'Distinguish proportional vs. not proportional.',
          score: 0.0,
          evidence: 'Marked inverse case as direct.',
        ),
      ],
      gaps: [
        LearningGap(
          id: 'g1',
          type: 'Incomplete link',
          title: 'Skipped why k stays constant',
          severity: 62,
          evidence: 'Double x so y doubles',
          fix:
              'Show k = y/x stays the same across pairs; try (3,6) and (5,10).',
          action: 'drill',
        ),
        LearningGap(
          id: 'g2',
          type: 'Misconception',
          title: 'Mixed direct and inverse wording',
          severity: 55,
          evidence: 'If x doubles then y halves',
          fix:
              'Contrast direct (y = kx) with inverse (xy = k) using two mini-examples.',
          action: 'example',
        ),
      ],
      shining: [
        ShiningMoment(
          type: 'Reasoning',
          quote: 'If x doubles then y doubles, so it\'s proportional.',
        ),
        ShiningMoment(
          type: 'Precision',
          quote: 'Proportion means the ratio stays the same.',
        ),
      ],
      clarity: 68,
      clarityText: 'Short, concrete phrasing with minimal filler.',
      depth: 72,
      depthText: 'Claim → reason → small example or check.',
      boardDelta: BoardDelta(
        added: ['Use k = y/x to test proportion'],
        removed: [],
      ),
    );
  }
}

// Custom Painter for Progress Ring
class ProgressRingPainter extends CustomPainter {
  final double percentage;
  final Color color;
  final double strokeWidth;

  ProgressRingPainter({
    required this.percentage,
    required this.color,
    this.strokeWidth = 4.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background circle
    final backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.06)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * percentage;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
