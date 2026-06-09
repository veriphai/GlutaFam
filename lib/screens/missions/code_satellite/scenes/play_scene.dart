// The play scene — arranging / running / failed all share this layout. The
// upper region is left transparent so the Flame satellite stage (a permanent
// layer behind, in the shell) shows through; the lower panel carries Orbit's
// teaching beat, the command timeline, the tray, and the run control. When a
// step fails, the FailureOverlay stacks on top.
//
// Placement choreography (game-feel): tap a correct block → it turns green in
// the tray → ~200ms later it ARCS and flies up into the active slot → lands as
// the slot snaps green (the timeline's pop). A wrong tap flashes the slot red.

// GlobalKey.currentContext (not this State's context) is read after a delay,
// guarded by a mounted check — the lint can't see through the GlobalKey.
// ignore_for_file: use_build_context_synchronously

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config/asset_paths.dart';
import '../config/code_satellite_tuning.dart';
import '../models/satellite_command.dart';
import '../state/code_satellite_controller.dart';
import '../state/code_satellite_state.dart';
import '../widgets/captured_thumbnail.dart';
import '../widgets/command_block.dart';
import '../widgets/command_timeline.dart';
import '../widgets/command_tray.dart';
import '../widgets/cta_button.dart';
import '../widgets/failure_overlay.dart';
import '../widgets/mission_header.dart';
import '../widgets/orbit_dialogue.dart';
import '../../../../utils/s3_assets.dart';

class PlayScene extends StatefulWidget {
  const PlayScene({super.key, required this.state, required this.controller, required this.onBack});

  final CodeSatelliteState state;
  final CodeSatelliteController controller;
  final VoidCallback onBack;

  @override
  State<PlayScene> createState() => _PlaySceneState();
}

class _PlaySceneState extends State<PlayScene> with TickerProviderStateMixin {
  final GlobalKey _activeSlotKey = GlobalKey();
  final Map<SatelliteCommand, GlobalKey> _trayKeys = {};

  // Wrong-tap feedback: shrink-and-shake + a red border on the tapped card.
  late final AnimationController _wrongPulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
  SatelliteCommand? _wrongCard;

  // Capture cinematic: a big framed photo flashes in at center, holds, then
  // arcs + shrinks into the thumbnail slot.
  final GlobalKey _thumbKey = GlobalKey();
  late final AnimationController _photoCtl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2300))
        ..addStatusListener((st) {
          if (st == AnimationStatus.completed) {
            setState(() {
              _photoActive = false;
              _photoLanded = true;
            });
          }
        });
  bool _photoActive = false;
  bool _photoLanded = false;

  @override
  void didUpdateWidget(PlayScene old) {
    super.didUpdateWidget(old);
    if (widget.state.photoToken != old.state.photoToken && widget.state.photoToken > 0) {
      setState(() {
        _photoActive = true;
        _photoLanded = false;
      });
      _photoCtl.forward(from: 0);
    }
  }

  late final AnimationController _fly =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 460))
        ..addStatusListener((st) {
          if (st == AnimationStatus.completed) {
            final c = _flying;
            if (c != null) widget.controller.confirmPlace(c);
            setState(() {
              _flying = null;
              _flyFrom = null;
              _flyTo = null;
            });
          }
        });

  SatelliteCommand? _selecting; // green in tray, pre-flight
  SatelliteCommand? _flying; // arcing into the slot
  Rect? _flyFrom;
  Rect? _flyTo;

  CodeSatelliteState get state => widget.state;
  CodeSatelliteController get controller => widget.controller;

  GlobalKey _keyFor(SatelliteCommand c) => _trayKeys.putIfAbsent(c, () => GlobalKey());

  @override
  void dispose() {
    _fly.dispose();
    _wrongPulse.dispose();
    _photoCtl.dispose();
    super.dispose();
  }

  void _onTapCommand(SatelliteCommand c) {
    if (state.phase != Activity10Phase.arranging) return;
    if (_flying != null || _selecting != null) return;
    if (!controller.isCorrectNext(c)) {
      controller.rejectPlace(c);
      setState(() => _wrongCard = c);
      _wrongPulse.forward(from: 0);
      Future<void>.delayed(const Duration(milliseconds: 750), () {
        if (mounted && _wrongCard == c) setState(() => _wrongCard = null);
      });
      return;
    }
    // Correct: confirm-feedback, show it green in place, then fly it in.
    controller.playSelectFeedback();
    setState(() => _selecting = c);
    Future<void>.delayed(const Duration(milliseconds: 200), () {
      if (!mounted || _selecting != c) return;
      // Reading GlobalKey contexts (not this State's context); guarded by the
      // mounted check above.
      final fromCtx = _trayKeys[c]?.currentContext;
      final toCtx = _activeSlotKey.currentContext;
      if (fromCtx == null || toCtx == null) {
        controller.confirmPlace(c);
        setState(() => _selecting = null);
        return;
      }
      final fromBox = fromCtx.findRenderObject() as RenderBox;
      final toBox = toCtx.findRenderObject() as RenderBox;
      setState(() {
        _flyFrom = fromBox.localToGlobal(Offset.zero) & fromBox.size;
        _flyTo = toBox.localToGlobal(Offset.zero) & toBox.size;
        _flying = c;
        _selecting = null;
      });
      _fly.forward(from: 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                MissionHeader(state: state, onBack: widget.onBack),
                // Transparent stage region (the Flame satellite shows here).
                Expanded(
                  child: Align(
                    alignment: Alignment.topRight,
                    child: AnimatedOpacity(
                      // Hidden until the captured photo lands here — no "No image
                      // yet" placeholder. (Kept in the tree so the capture
                      // cinematic can target its position.)
                      opacity: state.imageCaptured && _photoLanded ? 1 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: KeyedSubtree(
                        key: _thumbKey,
                        child: CapturedThumbnail(hasImage: state.imageCaptured && _photoLanded),
                      ),
                    ),
                  ),
                ),
                _bottomPanel(),
              ],
            ),
          ),
        ),
        if (state.phase == Activity10Phase.failed)
          Positioned.fill(
            child: FailureOverlay(
              message: state.failureMessage ?? 'Something went wrong. Let’s fix the order!',
              onReorder: controller.reorderCommands,
            ),
          ),
        if (_flying != null && _flyFrom != null && _flyTo != null) _flyingCard(),
        if (_photoActive) _capturedPhotoOverlay(),
        if (_showConnected) _connectedChip(),
      ],
    );
  }

  // "✓ Connected" badge above the ground station, during the antenna + send
  // steps (the uplink line is green by then).
  bool get _showConnected {
    final i = state.activeStepIndex;
    if (i == null || i < 0 || i >= state.slots.length) return false;
    final cmd = state.slots[i];
    return cmd == SatelliteCommand.pointAntennaToGroundStation ||
        cmd == SatelliteCommand.sendData;
  }

  Widget _connectedChip() {
    // station sits at CSStage.stationCenter (factor of the full-screen stage);
    // place the chip just above it.
    final ax = CSStage.stationCenter.dx * 2 - 1;
    final ay = (CSStage.stationCenter.dy - 0.09) * 2 - 1;
    return IgnorePointer(
      child: Align(
        alignment: Alignment(ax, ay),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutBack,
          builder: (_, t, child) => Transform.scale(scale: t, child: Opacity(opacity: t.clamp(0, 1), child: child)),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFF0D2A1E).withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: CSColors.green, width: 1.4),
              boxShadow: [BoxShadow(color: CSColors.green.withValues(alpha: 0.4), blurRadius: 14)],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded, size: 16, color: CSColors.green),
                const SizedBox(width: 6),
                Text('Connected',
                    style: TextStyle(color: CSColors.green, fontSize: 13, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Capture cinematic overlay: a framed photo flashes in at screen centre,
  // holds, then arcs + shrinks into the thumbnail slot.
  Widget _capturedPhotoOverlay() {
    final screen = MediaQuery.sizeOf(context);
    final bigW = screen.width * 0.72;
    final bigH = bigW * 0.8;
    final bigCenter = Offset(screen.width * 0.5, screen.height * 0.40);
    return AnimatedBuilder(
      animation: _photoCtl,
      builder: (context, _) {
        final v = _photoCtl.value;
        Rect thumb;
        final tctx = _thumbKey.currentContext;
        final ro = tctx?.findRenderObject();
        if (ro is RenderBox && ro.hasSize) {
          thumb = ro.localToGlobal(Offset.zero) & ro.size;
        } else {
          thumb = Rect.fromLTWH(screen.width - 92, 76, 78, 78);
        }
        final appear = (v / 0.16).clamp(0.0, 1.0);
        final flyT = ((v - 0.72) / 0.28).clamp(0.0, 1.0);
        Offset c;
        double w, h;
        if (flyT <= 0) {
          final s = Curves.easeOutBack.transform(appear);
          c = bigCenter;
          w = bigW * s;
          h = bigH * s;
        } else {
          final e = Curves.easeInOutCubic.transform(flyT);
          c = Offset.lerp(bigCenter, thumb.center, e)!;
          w = bigW + (thumb.width - bigW) * e;
          h = bigH + (thumb.height - bigH) * e;
        }
        final flash = (1 - v / 0.12).clamp(0.0, 1.0);
        return Positioned(
          left: c.dx - w / 2,
          top: c.dy - h / 2,
          width: w,
          height: h,
          child: IgnorePointer(child: _photoCard(flash)),
        );
      },
    );
  }

  Widget _photoCard(double flash) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CSColors.cyan, width: 2.5),
        boxShadow: [
          BoxShadow(color: CSColors.cyan.withValues(alpha: 0.55), blurRadius: 26, spreadRadius: 2),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            netImageWidget(
              CS.flutter(CS.capturedThumb),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: const Color(0xFF0E1633)),
            ),
            if (flash > 0) Container(color: Colors.white.withValues(alpha: 0.85 * flash)),
          ],
        ),
      ),
    );
  }

  Widget _bottomPanel() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        OrbitDialogue(mood: state.mascot, message: state.message, mascotSize: 64),
        const SizedBox(height: 10),
        CommandTimeline(state: state, controller: controller, activeSlotKey: _activeSlotKey),
        const SizedBox(height: 10),
        // Tray while arranging; a running status strip otherwise.
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          child: state.phase == Activity10Phase.arranging
              ? CommandTray(
                  key: const ValueKey('tray'),
                  state: state,
                  onTapCommand: _onTapCommand,
                  keyFor: _keyFor,
                  selecting: _selecting,
                  hidden: _flying,
                  wrong: _wrongCard,
                  wrongPulse: _wrongPulse,
                )
              : _runningStrip(key: const ValueKey('running')),
        ),
        // Run slot only when it has something to show (Run Mission while
        // arranging, Next/Replay in step-through debug) — during the auto run
        // it collapses so the panel sits at the bottom with no dead space.
        if (state.phase == Activity10Phase.arranging || state.awaitingNextStep) ...[
          const SizedBox(height: 10),
          SizedBox(height: 58, child: _runControl()),
        ],
      ],
    );
  }

  // Quadratic-bezier flight: the card arcs up over a control point and scales
  // from tray size → slot size, with a green glow that swells mid-flight.
  Widget _flyingCard() {
    final from = _flyFrom!, to = _flyTo!;
    final fc = from.center, tc = to.center;
    final ctrl = Offset((fc.dx + tc.dx) / 2, math.min(fc.dy, tc.dy) - 80);
    return AnimatedBuilder(
      animation: _fly,
      builder: (context, _) {
        final t = Curves.easeInOutCubic.transform(_fly.value);
        final u = 1 - t;
        final pos = Offset(
          u * u * fc.dx + 2 * u * t * ctrl.dx + t * t * tc.dx,
          u * u * fc.dy + 2 * u * t * ctrl.dy + t * t * tc.dy,
        );
        final w = from.width + (to.width - from.width) * t;
        final h = from.height + (to.height - from.height) * t;
        final glow = math.sin(math.pi * _fly.value);
        return Positioned(
          left: pos.dx - w / 2,
          top: pos.dy - h / 2,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: CSColors.green.withValues(alpha: 0.55 * glow),
                    blurRadius: 22 * glow + 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: CommandCard(
                command: _flying,
                style: CommandCardStyle.correct,
                width: w,
                height: h,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _runningStrip({required Key key}) {
    final idx = state.activeStepIndex;
    final cmd = (idx != null && idx >= 0 && idx < state.slots.length) ? state.slots[idx] : null;
    final awaiting = state.awaitingNextStep;
    final label = idx == null
        ? (state.phase == Activity10Phase.failed ? 'Mission paused' : 'Executing commands…')
        : 'Step ${idx + 1} / ${state.slots.length}${cmd != null ? ' · ${cmd.label}' : ''}';
    return Container(
      key: key,
      height: 64,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CSColors.cyan.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (awaiting)
            const Icon(Icons.check_circle_rounded, size: 20, color: CSColors.green)
          else
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2.4, color: CSColors.cyan),
            ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _runControl() {
    // Debug step-through: Replay + Next Step while paused between commands.
    if (state.awaitingNextStep) {
      return Row(
        children: [
          Expanded(
            child: CtaButton(
              label: 'Replay',
              icon: Icons.replay_rounded,
              onTap: controller.replayCurrentStep,
              colors: const [Color(0xFF3A4668), Color(0xFF2A3350)],
              dark: false,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: CtaButton(
              label: 'Next Step',
              icon: Icons.skip_next_rounded,
              onTap: controller.advanceStep,
              colors: const [Color(0xFF36C5F0), Color(0xFF2D6FF7)],
              dark: false,
            ),
          ),
        ],
      );
    }
    if (state.phase != Activity10Phase.arranging) {
      return const SizedBox.shrink();
    }
    final ready = state.allSlotsFilled;
    // Also wait for Orbit's in-flight line (e.g. the "plan is ready" beat) —
    // listen-before-run.
    return CtaButton(
      label: ready ? 'Run Mission' : 'Fill all 9 steps',
      icon: ready ? Icons.play_arrow_rounded : Icons.lock_outline_rounded,
      enabled: ready && !state.voicePlaying,
      onTap: controller.runMission,
      colors: const [Color(0xFF34D17E), Color(0xFF17A95C)],
      dark: false,
    );
  }
}
