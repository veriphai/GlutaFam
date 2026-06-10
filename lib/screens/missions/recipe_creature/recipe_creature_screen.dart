// Prologue · "The One Thing You Need" — the Flutter shell (PRD §4: pure Flutter,
// no Flame). A Stack of Positioned.fill layers: the calm dark base → a SafeArea
// Column (header · creature hero · Helix bubble · the bottom controls/tray) →
// the collectible earn overlay. A Ticker is the one clock — it pumps
// controller.tick(dt); the controller owns all state + animation; the
// CreaturePainter is a pure renderer.

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../collectibles/collectible_earn_overlay.dart';
import '../../collectibles/collectible_models.dart';
import '../../home/career/careerCommon.dart';
import '../../home/career/careerTheme.dart';
import 'config/creature_tuning.dart';
import 'config/genome.dart';
import 'engine/helix_beat_engine.dart';
import 'state/recipe_creature_controller.dart';
import 'widgets/artifact_tray.dart';
import 'widgets/creature_painter.dart';
import 'widgets/dna_peek.dart';
import 'widgets/helix_avatar.dart';
import 'widgets/helix_helper.dart';
import 'widgets/inline_fact.dart';
import 'widgets/instruction_control.dart';
import 'widgets/stage_background.dart';

class RecipeCreatureScreen extends StatefulWidget {
  const RecipeCreatureScreen({super.key});

  @override
  State<RecipeCreatureScreen> createState() => _RecipeCreatureScreenState();
}

class _RecipeCreatureScreenState extends State<RecipeCreatureScreen>
    with SingleTickerProviderStateMixin {
  late final RecipeCreatureController _controller;
  late final Ticker _ticker;
  Duration _last = Duration.zero;

  @override
  void initState() {
    super.initState();
    // Block bodies (not `=> …`) so the cascades aren't absorbed into the lambda.
    _controller = RecipeCreatureController()
      ..onTraitChanged = () { HapticFeedback.selectionClick(); }
      ..onFirstMove = () { HapticFeedback.lightImpact(); }
      ..onArtifact = () { HapticFeedback.selectionClick(); }
      ..onRebuild = () { HapticFeedback.mediumImpact(); };
    _ticker = createTicker(_onTick)..start();
    WidgetsBinding.instance.addPostFrameCallback((_) => _controller.start());
  }

  void _onTick(Duration elapsed) {
    final dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    if (dt > 0 && dt < 0.1) _controller.tick(dt);
  }

  void _finish() => Navigator.of(context).maybePop();

  @override
  void dispose() {
    _ticker.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _controller.reducedMotion = MediaQuery.of(context).disableAnimations;
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: Scaffold(
        backgroundColor: RC.baseBottom,
        body: Stack(
          children: [
            // Living stage backdrop — spotlight, life-motes, faint helix/cell
            // watermark, vignette. The hero is the creature; chrome recedes.
            Positioned.fill(child: StageBackground(controller: _controller)),
            // Signature frame — certified-specimen corner ornaments tying the
            // activity to the collectible card's identity (PRD §9).
            const Positioned.fill(
              child: IgnorePointer(child: CustomPaint(painter: _SignaturePainter())),
            ),
            Positioned.fill(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                  child: Column(
                    children: [
                      const SubpageAppBar(
                        title: 'The One Thing You Need',
                        emoji: '🧬',
                        subtitle: 'Build it. Then bring it back.',
                      ),
                      const SizedBox(height: 10),
                      _BeatProgress(controller: _controller),
                      const SizedBox(height: 4),
                      // Hero — the creature upper-center, the inline fact beside it.
                      Expanded(
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: CustomPaint(painter: CreaturePainter(_controller)),
                            ),
                            Positioned(
                              right: 0,
                              top: 6,
                              child: InlineFact(controller: _controller),
                            ),
                          ],
                        ),
                      ),
                      // Helix, docked low just above the controls.
                      HelixHelper(controller: _controller),
                      const SizedBox(height: 8),
                      _BottomArea(controller: _controller),
                    ],
                  ),
                ),
              ),
            ),
            // The earn moment (after the 0.3 after-line) — Helix accompanies.
            Positioned.fill(
              child: ValueListenableBuilder<bool>(
                valueListenable: _controller.showCardEarn,
                builder: (context, show, _) => show
                    ? CollectibleEarnOverlay(
                        card: kRecipeIsCreatureCard,
                        eyebrow: 'NEW CARD',
                        brag: 'Whoa — your first card. And the rarest kind.',
                        mascot: const HelixAvatar(mood: Mood.celebrating, size: 88),
                        onDone: () {
                          _controller.onCardCollected();
                          _finish();
                        },
                      )
                    : const IgnorePointer(child: SizedBox.shrink()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The bottom third — the instruction controls (0.1/0.2 + the responsive rebuild)
/// OR the artifact tray (0.3), plus the peek panel and the Continue affordance.
/// One clock drives the creature, so swapping these never disturbs the hero.
class _BottomArea extends StatelessWidget {
  const _BottomArea({required this.controller});
  final RecipeCreatureController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<RCPhase>(
      valueListenable: controller.phase,
      builder: (context, phase, _) {
        final showTray = phase == RCPhase.selecting;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // The 0.2 peek panel (collapses to nothing when closed).
            DnaPeek(controller: controller),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              child: showTray
                  ? Padding(
                      key: const ValueKey('tray'),
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: ArtifactTray(controller: controller),
                    )
                  : KeyedSubtree(
                      key: const ValueKey('controls'),
                      child: _Controls(controller: controller),
                    ),
            ),
            const SizedBox(height: 8),
            _ContinueBar(controller: controller),
          ],
        );
      },
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({required this.controller});
  final RecipeCreatureController controller;

  @override
  Widget build(BuildContext context) {
    // Rebuilds with the genome so the sliders track live drags.
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final g = controller.displayGenome;
        final inReveal = controller.phase.value == RCPhase.reveal;
        return Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.05),
                Colors.white.withValues(alpha: 0.02),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.biotech_rounded, size: 13, color: RC.lifeGreen.withValues(alpha: 0.8)),
                  const SizedBox(width: 6),
                  Text(
                    'INSTRUCTIONS',
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.2,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              for (final f in GeneField.values)
                InstructionControl(
                  field: f,
                  value: g.value(f),
                  onChanged: (v) => controller.setTrait(f, v),
                  // The peek affordance rides the colour control, only in 0.2.
                  showPeek: inReveal && f == GeneField.colour,
                  onPeek: () => controller.openPeek(GeneField.colour),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// A slim 3-beat progress strip — Build · Read · Restore — filling as the
/// activity advances, so the arc is felt.
class _BeatProgress extends StatelessWidget {
  const _BeatProgress({required this.controller});
  final RecipeCreatureController controller;

  static const _labels = ['Build', 'Read', 'Restore'];

  int _step(RCPhase p) {
    switch (p) {
      case RCPhase.explore:
        return 0;
      case RCPhase.reveal:
        return 1;
      case RCPhase.extinction:
      case RCPhase.selecting:
      case RCPhase.rebuilt:
      case RCPhase.closing:
        return 2;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<RCPhase>(
      valueListenable: controller.phase,
      builder: (context, phase, _) {
        final step = _step(phase);
        return Row(
          children: [
            for (var i = 0; i < 3; i++) ...[
              Expanded(
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 350),
                      height: 3,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        gradient: i <= step
                            ? const LinearGradient(colors: [RC.lifeGreen, RC.lifeAmber])
                            : null,
                        color: i <= step ? null : Colors.white.withValues(alpha: 0.10),
                        boxShadow: i == step
                            ? [BoxShadow(color: RC.lifeGreen.withValues(alpha: 0.5), blurRadius: 7)]
                            : null,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _labels[i].toUpperCase(),
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                        color: Colors.white.withValues(alpha: i <= step ? 0.75 : 0.3),
                      ),
                    ),
                  ],
                ),
              ),
              if (i < 2) const SizedBox(width: 8),
            ],
          ],
        );
      },
    );
  }
}

/// Certified-specimen signature — fine double-line corner brackets + tiny helix
/// accents, echoing the card frame. Kept faint so the creature stays the hero.
class _SignaturePainter extends CustomPainter {
  const _SignaturePainter();

  @override
  void paint(Canvas canvas, Size size) {
    const inset = 8.0, len = 26.0, gap = 3.0;
    final w = size.width, h = size.height;
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFF5C451).withValues(alpha: 0.16);
    final line2 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = const Color(0xFFF5C451).withValues(alpha: 0.09);

    void corner(double x, double y, double sx, double sy) {
      // outer L.
      canvas.drawLine(Offset(x, y), Offset(x + sx * len, y), line);
      canvas.drawLine(Offset(x, y), Offset(x, y + sy * len), line);
      // inner faint L.
      canvas.drawLine(Offset(x + sx * gap, y + sy * gap), Offset(x + sx * (len * 0.7), y + sy * gap), line2);
      canvas.drawLine(Offset(x + sx * gap, y + sy * gap), Offset(x + sx * gap, y + sy * (len * 0.7)), line2);
    }

    corner(inset, inset, 1, 1);
    corner(w - inset, inset, -1, 1);
    corner(inset, h - inset, 1, -1);
    corner(w - inset, h - inset, -1, -1);
  }

  @override
  bool shouldRepaint(_SignaturePainter old) => false;
}

class _ContinueBar extends StatelessWidget {
  const _ContinueBar({required this.controller});
  final RecipeCreatureController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: controller.canAdvance,
      builder: (context, can, _) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          child: !can
              ? const SizedBox(height: 52, width: double.infinity, key: ValueKey('no-cta'))
              : PressableScale(
                  key: const ValueKey('cta'),
                  onTap: controller.advance,
                  child: Container(
                    height: 52,
                    width: double.infinity,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFFFD27A), Color(0xFFE9A93F)],
                      ),
                      borderRadius: BorderRadius.circular(CareerRadii.pill),
                      boxShadow: [
                        BoxShadow(
                          color: RC.lifeAmber.withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Continue',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1A1340),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward_rounded, size: 19, color: Color(0xFF1A1340)),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }
}
