// Stage 4 — Capture the Cyclone Image (PRD §15). The screen becomes a camera
// scope: one-finger PAN + pinch (or the side slider) to ZOOM the live Earth
// view; the fixed centre reticle locks green when the cyclone spiral is
// centred AND the zoom is in the ideal band; then the capture button unlocks
// → scanline + flash + success.
//
// The pannable content is the full-bleed Earth-with-storm photo; the cyclone
// sits at a factor anchor (CameraTuning.cycloneCenter — tuning pass expected).

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config/scc_assets.dart';
import '../config/scc_stage_configs.dart';
import '../config/scc_theme.dart';
import '../state/mission_stage_controller.dart';
import '../state/mission_state.dart';

class CameraScene extends StatefulWidget {
  const CameraScene({super.key, required this.controller});

  final MissionStageController controller;

  @override
  State<CameraScene> createState() => _CameraSceneState();
}

class _CameraSceneState extends State<CameraScene>
    with TickerProviderStateMixin {
  // view state (scene-local; controller only hears band-relevant reports)
  double _zoom = CameraTuning.zoomMin;
  Offset _pan = Offset.zero; // content offset from centered, px
  double _gestureStartZoom = 1;

  late final AnimationController _capture = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  // bottom-up photo reveal on the captured card (signal_rescue pattern)
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1700),
  );
  int _lastFlashToken = 0;

  Size _viewport = Size.zero;

  @override
  void dispose() {
    _capture.dispose();
    _reveal.dispose();
    super.dispose();
  }

  // content (the image) is square, FIT-WIDTH × zoom — at low zoom the globe
  // spans the width and the starfield shows above/below (full-bleed look)
  double get _contentSide {
    return _viewport.width * _zoom;
  }

  Offset _clampPan(Offset pan) {
    final extraW = math.max(0.0, (_contentSide - _viewport.width) / 2);
    final extraH = math.max(0.0, (_contentSide - _viewport.height) / 2);
    return Offset(
      pan.dx.clamp(-extraW, extraW),
      pan.dy.clamp(-extraH, extraH),
    );
  }

  /// Cyclone position relative to the viewport centre, in px.
  Offset get _cycloneFromCenter {
    final side = _contentSide;
    final cyc = Offset(
      (CameraTuning.cycloneCenter.dx - 0.5) * side,
      (CameraTuning.cycloneCenter.dy - 0.5) * side,
    );
    return cyc + _pan;
  }

  void _report() {
    final dist = _cycloneFromCenter.distance /
        (_viewport.shortestSide == 0 ? 1 : _viewport.shortestSide);
    widget.controller.cameraReport(centerDistFrac: dist, zoom: _zoom);
  }

  void _onScaleStart(ScaleStartDetails d) => _gestureStartZoom = _zoom;

  void _onScaleUpdate(ScaleUpdateDetails d) {
    if (widget.controller.state.camera.phase == CameraPhase.captured) return;
    setState(() {
      if (d.scale != 1.0) {
        _zoom = (_gestureStartZoom * d.scale)
            .clamp(CameraTuning.zoomMin, CameraTuning.zoomMax);
      }
      _pan = _clampPan(_pan + d.focalPointDelta);
    });
    _report();
  }

  void _setZoom(double z) {
    if (widget.controller.state.camera.phase == CameraPhase.captured) return;
    setState(() {
      _zoom = z.clamp(CameraTuning.zoomMin, CameraTuning.zoomMax);
      _pan = _clampPan(_pan);
    });
    _report();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final cam = widget.controller.state.camera;
        if (cam.flashToken != _lastFlashToken) {
          _lastFlashToken = cam.flashToken;
          _capture.forward(from: 0);
          // photo download starts once the flash settles
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) _reveal.forward(from: 0);
          });
        }
        final locked = cam.phase == CameraPhase.locked || cam.phase == CameraPhase.captured;

        // FULL-BLEED scope: the Earth IS the background — fit-width content,
        // so at low zoom the shell's starfield shows above/below the globe;
        // all controls float over the scene.
        return LayoutBuilder(
          builder: (context, box) {
            _viewport = Size(box.maxWidth, box.maxHeight);
            final side = _contentSide;
            return GestureDetector(
              onScaleStart: _onScaleStart,
              onScaleUpdate: _onScaleUpdate,
              child: ClipRect(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                            // pannable Earth content
                            OverflowBox(
                              maxWidth: double.infinity,
                              maxHeight: double.infinity,
                              child: Transform.translate(
                                offset: _pan,
                                child: SizedBox(
                                  width: side,
                                  height: side,
                                  child: sccImage(
                                    SCC.flutter(SCC.scopeContent),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            // fixed centre reticle (procedural, state-tinted)
                            IgnorePointer(
                              child: CustomPaint(
                                painter: _ReticlePainter(
                                  locked: locked,
                                  color: locked ? SccColors.success : SccColors.cyan,
                                ),
                              ),
                            ),
                            // 3rd hint → animated arrow toward the cyclone
                            // (PRD §22.4 level-3 visual guide example)
                            if (!locked &&
                                widget.controller
                                        .hintLevelFor(MissionStage.captureImage) >=
                                    3)
                              IgnorePointer(
                                child: Center(
                                  child: Transform.rotate(
                                    angle: _cycloneFromCenter.direction,
                                    child: Transform.translate(
                                      offset: const Offset(70, 0),
                                      child: const Icon(
                                          Icons.arrow_forward_rounded,
                                          color: SccColors.warningAmber,
                                          size: 38),
                                    ),
                                  ),
                                ),
                              ),
                            // TARGET LOCK badge
                            Positioned(
                              top: 10,
                              left: 12,
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 250),
                                opacity: locked ? 1 : 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: sccPanel(
                                      borderColor: SccColors.success, radius: 10),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.gps_fixed_rounded,
                                          color: SccColors.success, size: 14),
                                      const SizedBox(width: 5),
                                      Text('TARGET LOCK',
                                          style: SccText.chip.copyWith(
                                              color: SccColors.success,
                                              fontSize: 9.5)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // zoom slider (right edge) — below the shutter
                            Positioned(
                              right: 8,
                              top: 104,
                              bottom: 24,
                              child: _ZoomSlider(zoom: _zoom, onZoom: _setZoom),
                            ),
                            // captured photo card — the image "downloads"
                            // bottom-up over static with a glowing scan line
                            // at the reveal edge (the signal_rescue monitor
                            // pattern)
                            if (cam.phase == CameraPhase.captured)
                              IgnorePointer(
                                child: Center(
                                  child: _CapturedPhotoCard(reveal: _reveal),
                                ),
                              ),
                            // capture scanline + flash
                            IgnorePointer(
                              child: AnimatedBuilder(
                                animation: _capture,
                                builder: (context, _) {
                                  final t = _capture.value;
                                  if (t == 0 || _capture.isDismissed) {
                                    return const SizedBox.shrink();
                                  }
                                  return Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      // scanline sweeping down
                                      Align(
                                        alignment: Alignment(0, -1 + 2 * t),
                                        child: Container(
                                          height: 3,
                                          color: SccColors.cyan
                                              .withValues(alpha: 0.9),
                                        ),
                                      ),
                                      // white flash early in the anim
                                      Container(
                                        color: Colors.white.withValues(
                                            alpha: (1 - t) * 0.55),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                    // shutter floats top-right
                    Positioned(
                      top: 10,
                      right: 12,
                      child: _CaptureButton(
                        enabled: cam.phase == CameraPhase.locked,
                        captured: cam.phase == CameraPhase.captured,
                        onTap: widget.controller.captureImage,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// The captured cyclone "photo downloading" card: static noise fades out as
/// the photo reveals bottom-up behind a glowing scan line; the label flips to
/// CYCLONE CAPTURED when the download completes.
class _CapturedPhotoCard extends StatelessWidget {
  const _CapturedPhotoCard({required this.reveal});

  final Animation<double> reveal;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: reveal,
      builder: (context, _) {
        final r = Curves.easeInOut.transform(reveal.value);
        final done = r >= 0.999;
        final color = done ? SccColors.success : SccColors.cyan;
        return Container(
          width: 240,
          padding: const EdgeInsets.all(10),
          decoration: sccPanel(borderColor: color, radius: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AspectRatio(
                aspectRatio: 4 / 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // static noise, fading as the photo arrives
                      Opacity(
                        opacity: (1 - r).clamp(0.0, 1.0),
                        child: sccImage(SCC.flutter(SCC.monitorStatic),
                            fit: BoxFit.cover),
                      ),
                      // the photo, revealing bottom-up
                      if (r > 0.001)
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: FractionallySizedBox(
                            heightFactor: r,
                            widthFactor: 1,
                            child: sccImage(SCC.flutter(SCC.capturePhoto),
                                fit: BoxFit.cover, alignment: Alignment.bottomCenter),
                          ),
                        ),
                      // glowing scan line at the reveal edge
                      if (r > 0.001 && !done)
                        Align(
                          alignment: Alignment(0, 1 - r * 2),
                          child: Container(
                            height: 3,
                            decoration: BoxDecoration(
                              color: color,
                              boxShadow: [
                                BoxShadow(
                                    color: color.withValues(alpha: 0.9),
                                    blurRadius: 8),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 7),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(done ? Icons.check_circle_rounded : Icons.downloading_rounded,
                      size: 14, color: color),
                  const SizedBox(width: 6),
                  Text(done ? 'CYCLONE CAPTURED' : 'RECEIVING IMAGE…',
                      style: SccText.chip.copyWith(color: color, fontSize: 9.5)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Round camera SHUTTER: outer glowing ring + inner disc, like a real camera
/// app — pulses alive when the lock enables it.
class _CaptureButton extends StatelessWidget {
  const _CaptureButton(
      {required this.enabled, required this.captured, required this.onTap});

  final bool enabled;
  final bool captured;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = captured
        ? SccColors.success
        : enabled
            ? SccColors.cyan
            : SccColors.textMuted;
    return IgnorePointer(
      ignoring: !enabled || captured,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 62,
              height: 62,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2.4),
                boxShadow: enabled || captured
                    ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 16)]
                    : null,
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      color.withValues(alpha: enabled || captured ? 0.85 : 0.3),
                      color.withValues(alpha: enabled || captured ? 0.5 : 0.15),
                    ],
                  ),
                ),
                child: Icon(
                    captured ? Icons.check_rounded : Icons.photo_camera_rounded,
                    color: SccColors.white,
                    size: 26),
              ),
            ),
            const SizedBox(height: 3),
            Text(captured ? 'CAPTURED' : 'CAPTURE',
                style: SccText.label.copyWith(fontSize: 9, color: color)),
          ],
        ),
      ),
    );
  }
}

class _ZoomSlider extends StatelessWidget {
  const _ZoomSlider({required this.zoom, required this.onZoom});

  final double zoom;
  final ValueChanged<double> onZoom;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: SccColors.panelFill,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SccColors.panelBorder),
      ),
      child: Column(
        children: [
          const Icon(Icons.add_rounded, size: 18, color: SccColors.textSecondary),
          Expanded(
            child: RotatedBox(
              quarterTurns: -1,
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 3,
                  activeTrackColor: SccColors.cyan,
                  inactiveTrackColor: SccColors.panelBorder,
                  thumbColor: SccColors.cyan,
                  overlayShape: SliderComponentShape.noOverlay,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 9),
                ),
                child: Slider(
                  value: zoom,
                  min: CameraTuning.zoomMin,
                  max: CameraTuning.zoomMax,
                  onChanged: onZoom,
                ),
              ),
            ),
          ),
          const Icon(Icons.remove_rounded, size: 18, color: SccColors.textSecondary),
        ],
      ),
    );
  }
}

/// Procedural scope reticle: corner brackets + concentric rings + crosshair
/// ticks, translucent centre, tinted by lock state (playbook pattern —
/// crisper than the AI reticle sprite and state-tintable).
class _ReticlePainter extends CustomPainter {
  _ReticlePainter({required this.locked, required this.color});

  final bool locked;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide * 0.20;
    final stroke = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final faint = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawCircle(c, r, stroke);
    canvas.drawCircle(c, r * 1.45, faint);
    canvas.drawCircle(c, 3, Paint()..color = color);
    // crosshair ticks
    for (final d in const [Offset(1, 0), Offset(-1, 0), Offset(0, 1), Offset(0, -1)]) {
      canvas.drawLine(c + d * (r * 0.55), c + d * (r * 0.95), stroke);
    }
    // corner brackets of the scope frame
    final m = size.shortestSide * 0.05;
    final len = size.shortestSide * 0.08;
    final corners = <(Offset, Offset, Offset)>[
      (Offset(m, m), const Offset(1, 0), const Offset(0, 1)),
      (Offset(size.width - m, m), const Offset(-1, 0), const Offset(0, 1)),
      (Offset(m, size.height - m), const Offset(1, 0), const Offset(0, -1)),
      (Offset(size.width - m, size.height - m), const Offset(-1, 0), const Offset(0, -1)),
    ];
    for (final (o, dx, dy) in corners) {
      canvas.drawLine(o, o + dx * len, stroke);
      canvas.drawLine(o, o + dy * len, stroke);
    }
  }

  @override
  bool shouldRepaint(covariant _ReticlePainter old) =>
      old.locked != locked || old.color != color;
}
