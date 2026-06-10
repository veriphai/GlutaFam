// The Leaky Bucket (Episode 1 · beat 1.3) — the Flutter shell. A full-bleed Flame
// power-station scene (built ONCE) under a Flutter chrome overlay.
//
// A tight build-and-watch-it-leak DEMONSTRATION (PRD): the kid SNAP-BUILDS the
// plant — drag the 4 machines from the tray onto the scene (a DragTarget over the
// stage); each snaps to its correct slot (no wrong order, no fail). When all are
// in, "Power It Up" wakes them in sequence, each leaking heat as it comes online,
// until the bulb lands dim (~38). Then the meaning-lines + Card 04 + the
// transmission hand-off. No mascot, no plugging, no puzzle.

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../collectibles/collectible_earn_overlay.dart';
import '../../collectibles/collectible_models.dart';
import '../../home/career/careerCommon.dart';
import '../../home/career/careerTheme.dart';
import 'config/leaky_chain_defs.dart';
import 'engine/leaky_bot_engine.dart' show LBPhase;
import 'game/leaky_bucket_game.dart';
import 'state/leaky_bucket_controller.dart';
import 'widgets/assembly_tray.dart';
import 'widgets/energy_field_background.dart';
import 'widgets/instruction_banner.dart';
import 'widgets/scene_numbers.dart';

class LeakyBucketScreen extends StatefulWidget {
  const LeakyBucketScreen({super.key});

  @override
  State<LeakyBucketScreen> createState() => _LeakyBucketScreenState();
}

class _LeakyBucketScreenState extends State<LeakyBucketScreen> {
  late final LeakyBucketController _controller;
  late final LeakyBucketGame _game;
  late final Widget _gameWidget; // built ONCE

  @override
  void initState() {
    super.initState();
    final reduced = WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations;
    _controller = LeakyBucketController()..onSelectHaptic = HapticFeedback.selectionClick;
    _game = LeakyBucketGame(controller: _controller, reducedMotion: reduced);
    _gameWidget = GameWidget(game: _game);
    WidgetsBinding.instance.addPostFrameCallback((_) => _controller.start());
  }

  void _finish() => Navigator.of(context).maybePop();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: Scaffold(
        backgroundColor: const Color(0xFF070A1C),
        body: Stack(
          children: [
            const Positioned.fill(child: EnergyFieldBackground()),
            Positioned.fill(child: _gameWidget),
            Positioned.fill(child: SceneNumbers(controller: _controller)),

            // Snap-build drop zone — a machine dropped anywhere over the stage
            // snaps to its own correct slot. Active only during the build beat.
            Positioned.fill(
              child: DragTarget<LeakStepKind>(
                onWillAcceptWithDetails: (d) =>
                    _controller.phase.value == LBPhase.build && !_controller.isPlaced(d.data),
                onAcceptWithDetails: (d) => _controller.placeMachine(d.data),
                builder: (_, __, ___) => const SizedBox.expand(),
              ),
            ),

            // Top chrome — back button + the large instruction / meaning line.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _Header(onBack: () => Navigator.of(context).maybePop()),
                      const SizedBox(height: 18),
                      InstructionBanner(controller: _controller),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom — the parts tray while building, then the Power It Up CTA.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      if (_controller.powered) return const SizedBox.shrink();
                      if (_controller.unplacedMachines.isNotEmpty) {
                        return PartsTray(controller: _controller);
                      }
                      return Center(
                        child: _PrimaryButton(label: 'Power It Up', icon: Icons.bolt_rounded, onTap: _controller.powerUp),
                      );
                    },
                  ),
                ),
              ),
            ),

            // Continue CTA — after the hand-off lands (card collected).
            Positioned.fill(
              child: ValueListenableBuilder<bool>(
                valueListenable: _controller.canFinish,
                builder: (context, canFinish, _) => ValueListenableBuilder<bool>(
                  valueListenable: _controller.showCardEarn,
                  builder: (context, earning, __) {
                    if (!canFinish || earning) return const IgnorePointer(child: SizedBox.shrink());
                    return SafeArea(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 26),
                          child: _PrimaryButton(label: 'Continue', icon: Icons.arrow_forward_rounded, onTap: _finish),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // The collectible earn moment (Card 04) — de-personified (no mascot).
            Positioned.fill(
              child: ValueListenableBuilder<bool>(
                valueListenable: _controller.showCardEarn,
                builder: (context, show, _) => show
                    ? CollectibleEarnOverlay(
                        card: kGreatEscapeCard,
                        eyebrow: 'NEW CARD',
                        brag: 'Energy is never destroyed — it just becomes heat you didn’t want.',
                        showMascot: false,
                        onDone: _controller.onCardCollected,
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

class _Header extends StatelessWidget {
  const _Header({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        PressableScale(
          onTap: onBack,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 21),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('The Leaky Bucket',
                  style: GoogleFonts.bricolageGrotesque(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.4, height: 1.05, color: Colors.white),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text('WHERE THE ENERGY GOES',
                  style: GoogleFonts.ibmPlexMono(fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 1.6, color: const Color(0xFFE8C98A).withValues(alpha: 0.7))),
            ],
          ),
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 30),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF5C451), Color(0xFFD9A43B)]),
          borderRadius: BorderRadius.circular(CareerRadii.pill),
          boxShadow: [
            BoxShadow(color: const Color(0xFFF5C451).withValues(alpha: 0.35), blurRadius: 16, spreadRadius: 1),
            BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF1A1340))),
            const SizedBox(width: 7),
            Icon(icon, size: 20, color: const Color(0xFF1A1340)),
          ],
        ),
      ),
    );
  }
}
