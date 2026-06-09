// "Welcome back — resume or start over?" modal, shown when the user opens
// a lesson they've already partially completed (e.g. watched the intro,
// left, came back). Without it the runner silently jumps straight to the
// next un-completed resource, which feels abrupt.
//
// showResumeLessonDialog(...) returns:
//   • ResumeChoice.resume    — continue from the next un-completed resource
//   • ResumeChoice.startOver — replay the lesson from the intro
//   • null                   — dismissed (tap outside / back): don't launch
//
// Premium career-theme card matching the leave / next-episode dialogs.

import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/howwow/howwowProfile.dart' show HowwowLessonResource;
import 'careerTheme.dart';
import 'professionDetailModels.dart';

enum ResumeChoice { resume, startOver }

Future<ResumeChoice?> showResumeLessonDialog(
  BuildContext context, {
  required Lesson lesson,
}) {
  return showGeneralDialog<ResumeChoice>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'resume-lesson',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 230),
    pageBuilder: (ctx, _, __) => _ResumeCard(lesson: lesson),
    transitionBuilder: (ctx, anim, _, child) {
      final curved = Curves.easeOutBack.transform(anim.value.clamp(0.0, 1.0));
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5 * anim.value, sigmaY: 5 * anim.value),
        child: Opacity(
          opacity: anim.value,
          child: Transform.scale(scale: 0.9 + 0.1 * curved, child: child),
        ),
      );
    },
  );
}

class _ResumeCard extends StatelessWidget {
  const _ResumeCard({required this.lesson});

  final Lesson lesson;

  /// 1-based step the user will resume on, and the total step count.
  (int step, int total) get _progress {
    final total = lesson.resources.length;
    final resumeIdx = lesson.lastCompletedResourceIndex + 1;
    return (resumeIdx + 1, total); // resumeIdx is 0-based → +1 for display
  }

  /// Friendly name for the resource they'd resume into.
  String get _resumeWhat {
    final resumeIdx = lesson.lastCompletedResourceIndex + 1;
    if (resumeIdx < 0 || resumeIdx >= lesson.resources.length) {
      return 'where you left off';
    }
    final HowwowLessonResource r = lesson.resources[resumeIdx];
    return switch (r.type) {
      'activity' => 'the mission',
      'video' => 'the story',
      'image' => 'the story',
      _ => 'where you left off',
    };
  }

  @override
  Widget build(BuildContext context) {
    final (step, total) = _progress;
    final hasSteps = total > 0;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 320,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(1.6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: CareerGradients.heroBorder,
            boxShadow: [
              BoxShadow(
                color: CareerColors.purple.withValues(alpha: 0.45),
                blurRadius: 36,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24.4),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF18244F), Color(0xFF0B1028)],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Waving Orbit.
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: CareerColors.blue.withValues(alpha: 0.14),
                    border: Border.all(
                        color: CareerColors.blue.withValues(alpha: 0.5),
                        width: 1.4),
                    boxShadow: [
                      BoxShadow(
                          color: CareerColors.blue.withValues(alpha: 0.35),
                          blurRadius: 20),
                    ],
                  ),
                  child: const Center(
                      child: Text('👋', style: TextStyle(fontSize: 28))),
                ),
                const SizedBox(height: 14),
                Text(
                  'Welcome back!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: CareerColors.textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  hasSteps
                      ? "You've already started “${lesson.title}”. Pick up at $_resumeWhat, or start over from the beginning?"
                      : "You've already started “${lesson.title}”. Continue where you left off, or start over?",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: CareerColors.textSecondary,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                if (hasSteps) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: CareerColors.glassFillStrong,
                      borderRadius: BorderRadius.circular(CareerRadii.pill),
                      border: Border.all(color: CareerColors.glassBorder),
                    ),
                    child: Text(
                      'Step $step of $total',
                      style: GoogleFonts.poppins(
                        color: CareerColors.gold,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                // Primary — Resume.
                SizedBox(
                  width: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: CareerGradients.gold,
                      borderRadius: BorderRadius.circular(CareerRadii.pill),
                      boxShadow: [
                        BoxShadow(
                            color: CareerColors.gold.withValues(alpha: 0.4),
                            blurRadius: 16),
                      ],
                    ),
                    child: TextButton(
                      onPressed: () =>
                          Navigator.of(context).pop(ResumeChoice.resume),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(CareerRadii.pill),
                        ),
                      ),
                      child: Text(
                        'Resume',
                        style: GoogleFonts.poppins(
                          color: CareerColors.onLight,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                // Secondary — Start Over.
                TextButton(
                  onPressed: () =>
                      Navigator.of(context).pop(ResumeChoice.startOver),
                  child: Text(
                    'Start Over',
                    style: GoogleFonts.poppins(
                      color: CareerColors.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
