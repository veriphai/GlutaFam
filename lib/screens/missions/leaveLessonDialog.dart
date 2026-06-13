// The "wait, don't go!" moment — the premium confirm modal shown when the
// user presses system back during a lesson's VIDEO cutscene instead of
// letting the back gesture silently end the lesson run.
//
// showLeaveLessonDialog(...): blurred + dimmed backdrop, gradient-border
// glass card with sad Orbit pleading in first person, "Keep Going 🚀" as
// the primary CTA and "Leave Mission" as the quiet secondary. Returns true
// ONLY when the user explicitly chooses to leave; tapping outside / back
// again counts as "keep going" (the forgiving default for kids).
//
// The video screen owns its own PopScope and calls this directly so it can
// pause/resume playback around the dialog (see missionVideoScreen.dart).
//
// Activities deliberately do NOT use a confirm-on-back guard: they finish
// via Navigator.maybePop() from their success screens, and a system back
// uses the same maybePop, so the two are indistinguishable — guarding them
// would make the activity's own "Continue" button open this dialog and
// trap the user. See the activity-route note in lessonRunner.dart.

import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../utils/howwowEventLogger.dart';
import '../../utils/howwowEventNames.dart';
import '../../utils/s3_assets.dart';
import '../home/career/careerTheme.dart';

/// Sad Orbit — drooping eyes + frown. Lives on S3 with the rest of the
/// activity art; usually already warm in the ImageCache because
/// save_coastal_city's manifest precaches it at lesson start.
const String _sadOrbitAsset = 'assets/images/save_coastal_city/orbit_worried.png';

/// Orbit's plea, in first person — he's the one asking the kid to stay.
/// One variant is picked at random per prompt so the modal stays fresh
/// across episodes. Tone: a friend who needs you, never a guilt trip.
const List<({String title, String message})> _copyVariants = [
  (
    title: 'Wait — don\'t go! 🥺',
    message:
        'I can\'t finish this mission without you. We\'re SO close — please don\'t give up now!',
  ),
  (
    title: 'Hey, partner…',
    message:
        'It gets lonely up here in space. Stay with me — one more push and we\'ve done it!',
  ),
  (
    title: 'I need you!',
    message:
        'Earth is counting on us, and I can\'t do this part alone. Will you stay?',
  ),
];

/// Neutral, mascot-free copy for the curiosity concepts (electricity /
/// de-extinction), where Orbit's first-person mission plea doesn't fit. Shown
/// via the `generic: true` path with no avatar / speech bubble.
const ({String title, String message}) _genericCopy = (
  title: 'Leave this lesson?',
  message: "You haven't finished this part yet. Leave for now, or keep going?",
);

/// Show the leave-lesson confirm modal. Returns true when the user
/// explicitly taps "Leave Mission"; false/null (Keep Going, tap-outside,
/// back again) means stay. Fires prompt telemetry on both outcomes.
Future<bool> showLeaveLessonDialog(
  BuildContext context, {
  String? lessonId,
  int? resourceIndex,
  String? resourceType,
  bool generic = false,
}) async {
  HowwowEventLogger.instance.log(
    HowwowEvents.lessonLeavePromptShown,
    props: {
      'lesson_id': lessonId,
      'resource_index': resourceIndex,
      'type': resourceType,
    },
  );

  final copy =
      generic ? _genericCopy : _copyVariants[math.Random().nextInt(_copyVariants.length)];

  final leave = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'keep-going',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (ctx, _, __) => _LeaveLessonCard(copy: copy, generic: generic),
    transitionBuilder: (ctx, anim, _, child) {
      final curved = Curves.easeOutBack.transform(anim.value.clamp(0.0, 1.0));
      // Backdrop blur ramps in with the card — the paused scene behind
      // melts out of focus, which is most of the "premium" feel.
      return BackdropFilter(
        filter: ImageFilter.blur(
            sigmaX: 5 * anim.value, sigmaY: 5 * anim.value),
        child: Opacity(
          opacity: anim.value,
          child: Transform.scale(scale: 0.9 + 0.1 * curved, child: child),
        ),
      );
    },
  );

  HowwowEventLogger.instance.log(
    leave == true
        ? HowwowEvents.lessonLeavePromptLeft
        : HowwowEvents.lessonLeavePromptKeptGoing,
    props: {
      'lesson_id': lessonId,
      'resource_index': resourceIndex,
      'type': resourceType,
    },
  );
  return leave == true;
}

class _LeaveLessonCard extends StatelessWidget {
  const _LeaveLessonCard({required this.copy, this.generic = false});

  final ({String title, String message}) copy;

  /// Generic (concept) styling: a plain centred message, no mascot/bubble, and
  /// neutral button labels ("Keep Going" / "Leave").
  final bool generic;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 320,
          // Gradient border shell — same recipe as the home hero card.
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
            padding: const EdgeInsets.fromLTRB(24, 26, 24, 18),
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
                Text(
                  copy.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: CareerColors.textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                if (generic)
                  // Concept lessons: a plain centred line — no mascot, no bubble,
                  // no first person.
                  Text(
                    copy.message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: CareerColors.textSecondary,
                      fontSize: 13.5,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                else
                  // Sad Orbit + his message bubble — he asks in first person.
                  Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 78,
                      height: 92,
                      child: netImageWidget(
                        _sadOrbitAsset,
                        fit: BoxFit.contain,
                        // Offline / cold-cache fallback so the modal never
                        // shows an empty hole where Orbit should be.
                        errorBuilder: (_, __, ___) => const Center(
                            child: Text('🥺', style: TextStyle(fontSize: 40))),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Bubble tail pointing at Orbit.
                    CustomPaint(
                      size: const Size(8, 14),
                      painter: _BubbleTailPainter(),
                    ),
                    Expanded(
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: CareerColors.glassFillStrong,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: CareerColors.glassBorder),
                        ),
                        child: Text(
                          copy.message,
                          style: GoogleFonts.poppins(
                            color: CareerColors.textPrimary,
                            fontSize: 12.5,
                            height: 1.45,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Primary — Keep Going (gold, full width).
                SizedBox(
                  width: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: CareerGradients.gold,
                      borderRadius: BorderRadius.circular(CareerRadii.pill),
                      boxShadow: [
                        BoxShadow(
                          color: CareerColors.gold.withValues(alpha: 0.4),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(CareerRadii.pill),
                        ),
                      ),
                      child: Text(
                        generic ? 'Keep Going' : 'Keep Going 🚀',
                        style: GoogleFonts.poppins(
                          color: CareerColors.onLight,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // Secondary — quiet leave.
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(
                    generic ? 'Leave' : 'Leave Mission',
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

/// Little leftward triangle joining the speech bubble to Orbit — drawn
/// (not an asset) so it always matches the bubble's glass fill exactly.
class _BubbleTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width, 0)
      ..lineTo(0, size.height / 2)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = CareerColors.glassFillStrong);
  }

  @override
  bool shouldRepaint(_BubbleTailPainter oldDelegate) => false;
}
