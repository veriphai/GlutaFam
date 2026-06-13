// The hero "Continue Career Mission" card.
//
// A compact, WIDE landscape banner: gradient border, a full-height illustration
// panel filling the right ~42% (drop `assets/images/hero_mission.png` in to
// replace the placeholder), and tightly-packed mission content on the left.

import 'package:flutter/material.dart';
import 'careerCommon.dart';
import 'careerModels.dart';
import 'careerTheme.dart';

class ContinueMissionCard extends StatelessWidget {
  const ContinueMissionCard({super.key, required this.mission, this.onContinue});

  final ContinueMission mission;
  final VoidCallback? onContinue;

  static const _innerTop = Color(0xFF18244F);
  static const _innerBottom = Color(0xFF0C1430);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(CareerRadii.card),
        gradient: _borderGradient,
        boxShadow: [
          BoxShadow(color: _glow.withValues(alpha: 0.30), blurRadius: 24, offset: const Offset(0, 10)),
        ],
      ),
      padding: const EdgeInsets.all(1.4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(CareerRadii.card - 1.4),
        child: LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            return Stack(
              children: [
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [_innerTop, _innerBottom],
                      ),
                    ),
                  ),
                ),
                // Full-bleed illustration. Careers use the bundled hero scene
                // (shifted right so its empty left overflows off-card, freeing
                // clean space for text); WOW concepts use their OWN card art,
                // filling the card so the readability scrim below simply fades
                // it out under the text on the left.
                Positioned.fill(child: _heroImage(w)),
                // Readability scrim: dark on the left (text), clear on the right (art).
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [_innerTop, _innerTop, Color(0x0018244F)],
                        stops: [0.0, 0.30, 0.74],
                      ),
                    ),
                  ),
                ),
                // Content (left).
                Padding(
                  padding: EdgeInsets.fromLTRB(14, 12, w * 0.42, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _badgeLabel(),
                      const SizedBox(height: 8),
                      // Concept names are long ("How Electricity Reaches Your
                      // Home") — let them wrap to two lines at full size rather
                      // than shrink to one. Careers ("Satellite Engineer") keep
                      // the single-line scale-to-fit treatment.
                      if (mission.isConcept)
                        Text(
                          mission.profession,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: CareerText.heroTitle.copyWith(
                              fontSize: 18,
                              height: 1.05,
                              shadows: const [Shadow(color: Colors.black54, blurRadius: 8)]),
                        )
                      else
                        SizedBox(
                          width: double.infinity,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(mission.profession,
                                maxLines: 1,
                                style: CareerText.heroTitle
                                    .copyWith(shadows: const [Shadow(color: Colors.black54, blurRadius: 8)])),
                          ),
                        ),
                      if (_showWorld) ...[
                        const SizedBox(height: 3),
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          const Text('🪐', style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 5),
                          Text(mission.world, style: CareerText.worldLabel.copyWith(color: CareerColors.blue, fontWeight: FontWeight.w700)),
                        ]),
                      ],
                      // The specific episode title (e.g. "Prologue — What
                      // Electricity Does") shows for careers, but is omitted for
                      // WOW concepts where the concept name alone leads.
                      if (!mission.isConcept) ...[
                        const SizedBox(height: 7),
                        Text(mission.missionTitle,
                            style: CareerText.body.copyWith(
                                color: Colors.white,
                                fontSize: 11,
                                shadows: const [Shadow(color: Colors.black54, blurRadius: 6)]),
                            maxLines: 2),
                      ],
                      if (_resumeHint() != null) ...[
                        const SizedBox(height: 4),
                        Text(_resumeHint()!,
                            style: CareerText.body.copyWith(
                                color: CareerColors.gold,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                shadows: const [Shadow(color: Colors.black54, blurRadius: 6)]),
                            maxLines: 1),
                      ],
                      if (mission.skills.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final skill in mission.skills)
                              SkillChip(icon: Icons.auto_awesome_rounded, label: skill),
                          ],
                        ),
                      ],
                      const SizedBox(height: 11),
                      _progress(),
                      const SizedBox(height: 11),
                      _cta(),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Accent used for concept theming — the profession/concept accent, or a
  /// gold default until the backend supplies one. Only consulted for concepts.
  Color get _accent => mission.accent ?? CareerColors.gold;

  /// Card border gradient: concepts use a gradient built from their accent
  /// (electricity → gold); careers keep the default purple→blue hero border.
  Gradient get _borderGradient => mission.isConcept
      ? LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(_accent, Colors.white, 0.30)!, _accent],
        )
      : CareerGradients.heroBorder;

  /// Outer glow colour, matched to the border family.
  Color get _glow => mission.isConcept ? _accent : CareerColors.purple;

  /// The full-bleed hero illustration behind the mission content.
  ///
  /// • Career → the bundled `hero_mission.png` scene, nudged right by 12% so
  ///   its empty left edge clips off-card and leaves clean space for text.
  /// • WOW concept → the concept's own card art ([mission.asset], an S3 URL
  ///   or bundled path), filling the card; the readability scrim above does
  ///   the left-side fade so the title/subtitle stay legible. Same visual
  ///   language as the career card, just sourced per-concept.
  Widget _heroImage(double w) {
    if (mission.isConcept) {
      final src = mission.asset;
      if (src == null || src.isEmpty) return const SizedBox.shrink();
      return src.startsWith('http')
          ? Image.network(
              src,
              fit: BoxFit.cover,
              alignment: Alignment.centerRight,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            )
          : Image.asset(
              src,
              fit: BoxFit.cover,
              alignment: Alignment.centerRight,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            );
    }
    return Transform.translate(
      offset: Offset(w * 0.12, 0),
      child: Image.asset(
        'assets/images/hero_mission.png',
        fit: BoxFit.cover,
        alignment: Alignment.center,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    );
  }

  /// Whether to render the "🪐 World" line. WOW concepts carry only a
  /// label-only worldId (no seeded world doc), so the resolved name is
  /// unfriendly — hide the row for concepts, and whenever the backend hands
  /// us no world at all.
  bool get _showWorld =>
      !mission.isConcept && mission.world.trim().isNotEmpty;

  /// "Resume step 2 of 3 — the mission!" hint, shown only when the user is
  /// mid-way through the current lesson AND the payload carries step info
  /// (resources + the start/progress fields from
  /// docs/howwow-resource-start-spec.md). Null → row not rendered, card
  /// looks exactly as before.
  String? _resumeHint() {
    if (!mission.startedCurrentLesson) return null;
    final step = mission.resumeStep;
    if (step == null || mission.totalSteps <= 0) return null;
    final what = switch (mission.resumeStepType) {
      'activity' => 'the mission!',
      'video' => 'the story',
      'image' => 'the story',
      _ => 'where you left off',
    };
    return 'Resume step $step of ${mission.totalSteps} — $what';
  }

  Widget _badgeLabel() {
    return Container(
      padding: const EdgeInsets.fromLTRB(7, 4, 10, 4),
      decoration: BoxDecoration(
        color: (mission.isConcept ? _accent : CareerColors.purple).withValues(alpha: 0.40),
        borderRadius: BorderRadius.circular(CareerRadii.pill),
        border: Border.all(
            color: (mission.isConcept ? _accent : CareerColors.purple).withValues(alpha: 0.6)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.play_arrow_rounded, size: 14, color: Colors.white),
        const SizedBox(width: 3),
        // "START" for a brand-new user, "CONTINUE" once they've made any
        // progress — including being mid-way through their FIRST lesson
        // (inProgress covers started-but-nothing-completed via the
        // server's resource-start write). The noun follows the profession's
        // kind: a WOW concept reads "WOW CONCEPT", a career "CAREER MISSION".
        Text(
            '${mission.inProgress ? 'CONTINUE' : 'START'} '
            '${mission.isConcept ? 'WOW CONCEPT' : 'CAREER MISSION'}',
            style: CareerText.label),
      ]),
    );
  }

  Widget _progress() {
    return Row(children: [
      const Icon(Icons.star_rounded, color: CareerColors.gold, size: 18),
      const SizedBox(width: 7),
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: Container(
            height: 7,
            color: Colors.white.withValues(alpha: 0.14),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: mission.progress),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: value.clamp(0.0, 1.0),
                  heightFactor: 1,
                  child: const DecoratedBox(decoration: BoxDecoration(gradient: CareerGradients.gold)),
                ),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(width: 9),
      Text('${mission.current} / ${mission.total} Missions',
          style: CareerText.body.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
    ]);
  }

  Widget _cta() {
    return PressableScale(
      onTap: onContinue ?? () => debugPrint('tap: continue mission'),
      pressedScale: 0.94,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          gradient: CareerGradients.gold,
          borderRadius: BorderRadius.circular(CareerRadii.pill),
          boxShadow: [BoxShadow(color: CareerColors.gold.withValues(alpha: 0.45), blurRadius: 14)],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          // "Start now" for a fresh user — "Continue" once they've made
          // any progress (finished a lesson OR are mid-way through one).
          // Same condition as the badge label above so both CTA states
          // flip in lockstep.
          Text(mission.inProgress ? 'Continue' : 'Start now',
              style: CareerText.cta.copyWith(color: CareerColors.onLight)),
          const SizedBox(width: 7),
          const Icon(Icons.chevron_right_rounded, color: CareerColors.onLight, size: 20),
        ]),
      ),
    );
  }
}
