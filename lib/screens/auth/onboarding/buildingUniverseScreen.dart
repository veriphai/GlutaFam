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
  late final List<String> _orbitEmojis;

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
    _orbitEmojis = [
      for (final opt in kOnboardingInterests)
        if (widget.answers.interests.contains(opt.id)) opt.emoji,
    ].take(3).toList();

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
                _Phase.building => _buildingView(),
                _Phase.success => _successView(),
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
    return Column(
      children: [
        const Spacer(flex: 3),
        _orbitVisual(),
        const Spacer(flex: 2),
        AnimatedBuilder(
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
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        CareerColors.gold),
                  ),
                ),
              ],
            );
          },
        ),
        const Spacer(flex: 2),
      ],
    );
  }

  /// Pulsing rings + glowing rocket core + the user's own interest emojis
  /// in orbit. Their choices literally circle the launch — personalization
  /// you can see.
  Widget _orbitVisual() {
    const size = 250.0;
    return SizedBox(
      width: size,
      height: size,
      child: AnimatedBuilder(
        animation: _orbit,
        builder: (context, _) {
          final t = _orbit.value;
          final pulse = (math.sin(t * 2 * math.pi * 4) + 1) / 2;
          return Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(size, size),
                painter: _RingsPainter(pulse),
              ),
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: CareerGradients.gold,
                  boxShadow: [
                    BoxShadow(
                      color: CareerColors.gold
                          .withValues(alpha: 0.35 + pulse * 0.25),
                      blurRadius: 30 + pulse * 14,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('🚀', style: TextStyle(fontSize: 40)),
                ),
              ),
              for (final (i, emoji) in _orbitEmojis.indexed)
                Transform.translate(
                  offset: Offset.fromDirection(
                    2 * math.pi * t + i * (2 * math.pi / 3),
                    99,
                  ),
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: CareerColors.glassFillStrong,
                      border: Border.all(color: CareerColors.glassBorder),
                    ),
                    child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _successView() {
    final name = widget.answers.name;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(flex: 3),
        const Center(child: Text('🌌', style: TextStyle(fontSize: 64)))
            .animate()
            .scale(
                begin: const Offset(0.4, 0.4),
                duration: 500.ms,
                curve: Curves.easeOutBack),
        const SizedBox(height: 24),
        Text(
          'Your universe is ready,\n$name!',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1.2,
          ),
        ).animate().fadeIn(duration: 400.ms, delay: 150.ms).slideY(begin: 0.2),
        const SizedBox(height: 12),
        Text(
          'Career worlds picked just for you are waiting.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 14.5,
            color: CareerColors.textSecondary,
            height: 1.45,
          ),
        ).animate().fadeIn(duration: 400.ms, delay: 280.ms),
        const Spacer(flex: 3),
        GoldCta(label: 'Start Exploring 🚀', onTap: _goHome)
            .animate()
            .fadeIn(duration: 400.ms, delay: 420.ms)
            .slideY(begin: 0.3, curve: Curves.easeOutCubic),
      ],
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

/// Two concentric rings that breathe with the pulse value.
class _RingsPainter extends CustomPainter {
  _RingsPainter(this.pulse);
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    paint.color =
        CareerColors.gold.withValues(alpha: 0.18 + pulse * 0.14);
    canvas.drawCircle(center, 99, paint);

    paint.color = Colors.white.withValues(alpha: 0.08 + pulse * 0.06);
    canvas.drawCircle(center, 124 - pulse * 4, paint);
  }

  @override
  bool shouldRepaint(_RingsPainter old) => old.pulse != pulse;
}
