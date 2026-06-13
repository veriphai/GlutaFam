// BuildingUniverseScreen — the payoff moment at the end of onboarding.
//
// Plays a personalized "building your universe" sequence (orbiting emojis of
// the interests the user just picked, rotating status lines that echo their
// name and choices) while the answers are submitted to the backend behind
// the scenes. When BOTH the animation and the API call finish, a confetti
// burst + "Your universe is ready, {name}!" celebration lands them on
// CareerHomeScreen.
//
// The loader is doing real work — research point: a personalized
// "building your plan…" moment is the single strongest premium signal in
// top-app onboarding (Duolingo / Headspace pattern), and it absorbs the
// network latency for free.
//
// Failure UX: if the submit still fails after a silent retry, the animation
// resolves into a friendly error card with "Try again" / "Skip for now".
// Skip clears the pending flag and proceeds — a first session must never be
// held hostage by one profile write (the session cache is already patched,
// so the home header still greets them by name).

import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../apis/howwow/howwowOnboarding.dart';
import '../../../apis/howwow/howwowSession.dart';
import '../../../utils/howwowEventLogger.dart';
import '../../../utils/howwowEventNames.dart';
import '../../home/career/careerHomeScreen.dart';
import '../../home/career/careerTheme.dart';
import '../../home/career/cosmicBackground.dart';
import 'onboardingFlow.dart';

enum _Phase { building, success, error }

class BuildingUniverseScreen extends StatefulWidget {
  const BuildingUniverseScreen(this.answers, {super.key});

  final OnboardingAnswers answers;

  @override
  State<BuildingUniverseScreen> createState() => _BuildingUniverseScreenState();
}

class _BuildingUniverseScreenState extends State<BuildingUniverseScreen>
    with TickerProviderStateMixin {
  late final AnimationController _orbit = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat();

  late final AnimationController _progress = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3400),
  );

  late final ConfettiController _confetti =
      ConfettiController(duration: const Duration(seconds: 2));

  _Phase _phase = _Phase.building;
  bool _apiDone = false;
  bool _apiOk = false;

  late final List<String> _messages;
  // The user's picked interests, split across up to two orbiting rings —
  // everything they chose revolves (was previously capped at 3). With 4 or
  // fewer they all sit on the inner ring; beyond that they're divided so the
  // smaller half orbits the inner ring and the rest the outer ring.
  late final List<String> _innerOrbitEmojis;
  late final List<String> _outerOrbitEmojis;

  @override
  void initState() {
    super.initState();

    final labels = _interestLabels();
    _messages = [
      'Scanning your interests…',
      labels.length >= 2
          ? 'Mapping ${labels[0]} & ${labels[1]} careers…'
          : 'Mapping your dream careers…',
      'Charting mission worlds for ${widget.answers.name}…',
      'Packing your explorer kit…',
    ];
    final selectedEmojis = [
      for (final opt in kOnboardingInterests)
        if (widget.answers.interests.contains(opt.id)) opt.emoji,
    ];
    if (selectedEmojis.length <= 4) {
      _innerOrbitEmojis = selectedEmojis;
      _outerOrbitEmojis = const [];
    } else {
      final innerCount = selectedEmojis.length ~/ 2; // smaller half inside
      _innerOrbitEmojis = selectedEmojis.sublist(0, innerCount);
      _outerOrbitEmojis = selectedEmojis.sublist(innerCount);
    }

    _progress.addStatusListener((status) {
      if (status == AnimationStatus.completed) _maybeFinish();
    });
    _progress.forward();
    _submit();
  }

  @override
  void dispose() {
    _orbit.dispose();
    _progress.dispose();
    _confetti.dispose();
    super.dispose();
  }

  List<String> _interestLabels() => [
        for (final opt in kOnboardingInterests)
          if (widget.answers.interests.contains(opt.id)) opt.label,
      ];

  // ── submit ─────────────────────────────────────────────────────────

  Future<void> _submit() async {
    // Patch the session immediately so this session greets by name even if
    // the network is flaky — the server write below is the durable copy.
    HowwowSession.instance.patchOnboarding(
      firstName: widget.answers.name,
      ageGroup: widget.answers.ageGroup,
      interests: widget.answers.interests.toList(),
    );

    var ok = false;
    for (var attempt = 0; attempt < 2 && !ok; attempt++) {
      try {
        await howwowOnboardProfile(
          firstName: widget.answers.name,
          ageGroup: widget.answers.ageGroup,
          interests: widget.answers.interests.toList(),
        );
        ok = true;
      } catch (_) {
        // One silent retry; the second failure surfaces the error card.
      }
    }

    if (ok) {
      await OnboardingPending.clear();
      HowwowEventLogger.instance.log(
        HowwowEvents.onboardingCompleted,
        props: {
          'age_group': widget.answers.ageGroup,
          'interests': widget.answers.interests.toList(),
        },
      );
    } else {
      HowwowEventLogger.instance.log(HowwowEvents.onboardingSubmitFailed);
    }
    if (!mounted) return;
    _apiDone = true;
    _apiOk = ok;
    _maybeFinish();
  }

  /// Resolve the screen only when BOTH the minimum animation time and the
  /// API call are done — never cut the moment short, never celebrate early.
  void _maybeFinish() {
    if (_phase != _Phase.building) return;
    if (!_apiDone || _progress.status != AnimationStatus.completed) return;

    if (_apiOk) {
      setState(() => _phase = _Phase.success);
      HapticFeedback.heavyImpact();
      _confetti.play();
      // The success beat lives on the building screen itself: the status
      // line becomes the "ready" message + a confetti burst, then we sail
      // straight to home — no second screen, no extra tap.
      Future.delayed(const Duration(milliseconds: 1700), () {
        if (mounted && _phase == _Phase.success) _goHome();
      });
    } else {
      setState(() => _phase = _Phase.error);
    }
  }

  void _retry() {
    HapticFeedback.lightImpact();
    setState(() => _phase = _Phase.building);
    _apiDone = false;
    _apiOk = false;
    _progress
      ..reset()
      ..forward();
    _submit();
  }

  Future<void> _skip() async {
    // Don't trap the user in onboarding over one failed write. Clear the
    // flag so AuthGate doesn't loop them back here on next launch.
    HowwowEventLogger.instance.log(HowwowEvents.onboardingSkipped);
    await OnboardingPending.clear();
    _goHome();
  }

  void _goHome() {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const CareerHomeScreen()),
      (route) => false,
    );
  }

  // ── UI ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CareerColors.bgMid,
      body: Stack(
        children: [
          const Positioned.fill(child: CosmicBackground()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
              child: switch (_phase) {
                _Phase.building || _Phase.success => _buildingView(),
                _Phase.error => _errorView(),
              },
            ),
          ),
          // Confetti cannon at the top centre — explosive burst on success.
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 28,
              emissionFrequency: 0.04,
              gravity: 0.18,
              shouldLoop: false,
              colors: const [
                CareerColors.gold,
                CareerColors.cyan,
                CareerColors.purple,
                CareerColors.pink,
                Colors.white,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildingView() {
    final ready = _phase == _Phase.success;
    return Column(
      children: [
        const Spacer(flex: 3),
        _orbitVisual(),
        const Spacer(flex: 2),
        // One slot: the rotating build status while loading, swapped for the
        // celebratory "ready" line at the end. The success state lives right
        // here on the building screen (confetti fires, then it auto-routes).
        ready ? _readyText() : _progressBlock(),
        const Spacer(flex: 2),
      ],
    );
  }

  Widget _progressBlock() {
    return AnimatedBuilder(
      animation: _progress,
      builder: (context, _) {
        final idx = (_progress.value * _messages.length)
            .floor()
            .clamp(0, _messages.length - 1);
        return Column(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: Text(
                _messages[idx],
                key: ValueKey(idx),
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 22),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: Curves.easeInOut.transform(_progress.value),
                minHeight: 6,
                backgroundColor: Colors.white.withValues(alpha: 0.10),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(CareerColors.gold),
              ),
            ),
          ],
        );
      },
    );
  }

  /// The closing celebration line — shown in place of the progress block once
  /// the universe is built. Confetti is already firing from [_maybeFinish];
  /// this is just the headline, after which the screen auto-advances home.
  Widget _readyText() {
    // stretch → both lines span the full width and centre their text,
    // matching how the loading status line is centred (it's full-width via
    // the progress bar). A plain Column would shrink-wrap to the text width
    // and drift off-centre. fadeIn only (no slide) so there's no transient
    // offset before the screen auto-advances.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Your universe is ready,\n${widget.answers.name}!',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Career worlds picked just for you are waiting.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: CareerColors.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  /// Pulsing rings + the glowing HowWow brand icon at the core + the user's
  /// own interest emojis orbiting it. Their choices literally circle the
  /// brand — personalization you can see. With more than 4 interests the
  /// emojis spread across two counter-rotating rings.
  Widget _orbitVisual() {
    const size = 280.0;
    const innerRadius = 80.0;
    const outerRadius = 116.0;
    final hasOuter = _outerOrbitEmojis.isNotEmpty;
    return SizedBox(
      width: size,
      height: size,
      child: AnimatedBuilder(
        animation: _orbit,
        builder: (context, _) {
          final t = _orbit.value;
          final pulse = (math.sin(t * 2 * math.pi * 4) + 1) / 2;
          // Coefficients of t stay ±2π → exactly one revolution per loop, so
          // the .repeat() wrap is seamless. The rings spin opposite ways.
          final innerAngle = 2 * math.pi * t; // clockwise
          final outerAngle = -2 * math.pi * t; // counter-clockwise
          return Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(size, size),
                painter: _RingsPainter(
                  pulse,
                  innerRadius: innerRadius,
                  outerRadius: hasOuter ? outerRadius : null,
                ),
              ),
              // Soft pulsing halo behind the brand icon (replaces the old
              // gold disc — the wordmark has its own colour, so it sits on a
              // glow rather than inside a filled circle).
              Container(
                width: 156,
                height: 156,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      CareerColors.gold.withValues(alpha: 0.26 + pulse * 0.16),
                      CareerColors.purple.withValues(alpha: 0.14),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
              // The HowWow wordmark icon at the centre of the universe.
              Image.asset(
                'assets/howwow-icon.png',
                width: 104,
                height: 104,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
              ),
              for (final (i, emoji) in _outerOrbitEmojis.indexed)
                _orbitBubble(
                  emoji: emoji,
                  angle: outerAngle +
                      math.pi / _outerOrbitEmojis.length +
                      i * (2 * math.pi / _outerOrbitEmojis.length),
                  radius: outerRadius,
                  bubbleSize: 40,
                  emojiSize: 20,
                ),
              for (final (i, emoji) in _innerOrbitEmojis.indexed)
                _orbitBubble(
                  emoji: emoji,
                  angle: innerAngle +
                      i * (2 * math.pi / _innerOrbitEmojis.length),
                  radius: innerRadius,
                  bubbleSize: 44,
                  emojiSize: 22,
                ),
            ],
          );
        },
      ),
    );
  }

  /// A single glass bubble holding one interest emoji, placed on an orbit at
  /// [angle] / [radius] from the centre.
  Widget _orbitBubble({
    required String emoji,
    required double angle,
    required double radius,
    required double bubbleSize,
    required double emojiSize,
  }) {
    return Transform.translate(
      offset: Offset.fromDirection(angle, radius),
      child: Container(
        width: bubbleSize,
        height: bubbleSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: CareerColors.glassFillStrong,
          border: Border.all(color: CareerColors.glassBorder),
        ),
        child: Center(
          child: Text(emoji, style: TextStyle(fontSize: emojiSize)),
        ),
      ),
    );
  }

  Widget _errorView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(flex: 3),
        const Center(child: Text('🛰️', style: TextStyle(fontSize: 56))),
        const SizedBox(height: 20),
        Text(
          'We hit some space debris',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          "Couldn't save your details. Check your connection and try again.",
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: CareerColors.textSecondary,
            height: 1.45,
          ),
        ),
        const Spacer(flex: 3),
        GoldCta(label: 'Try again', onTap: _retry),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: _skip,
            child: Text(
              'Skip for now',
              style: GoogleFonts.poppins(
                color: Colors.white60,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Concentric guide rings that breathe with the pulse value. The inner ring
/// is always drawn; the outer ring only when there are emojis orbiting it.
class _RingsPainter extends CustomPainter {
  _RingsPainter(this.pulse, {required this.innerRadius, this.outerRadius});
  final double pulse;
  final double innerRadius;
  final double? outerRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    paint.color = CareerColors.gold.withValues(alpha: 0.18 + pulse * 0.14);
    canvas.drawCircle(center, innerRadius, paint);

    final outer = outerRadius;
    if (outer != null) {
      paint.color = Colors.white.withValues(alpha: 0.08 + pulse * 0.06);
      canvas.drawCircle(center, outer - pulse * 4, paint);
    }
  }

  @override
  bool shouldRepaint(_RingsPainter old) =>
      old.pulse != pulse ||
      old.innerRadius != innerRadius ||
      old.outerRadius != outerRadius;
}
