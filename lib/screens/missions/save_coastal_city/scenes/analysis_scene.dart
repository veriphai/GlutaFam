// Stage 6 — Read the Satellite Image (PRD §17). Earth-Detective mode: three
// layer tabs (CLOUD / RAIN+HEAT / WIND) crossfade the satellite image; the
// child DRAWS A CIRCLE around the cyclone spiral with a finger. The scene
// validates the loop geometrically (overlap of the cyclone target zone with
// the drawn polygon) and reports to the controller — >60% overlap succeeds
// (PRD §17.5 logic, verbatim thresholds in AnalysisTuning).

import 'package:flutter/material.dart';

import '../config/scc_assets.dart';
import '../config/scc_stage_configs.dart';
import '../config/scc_theme.dart';
import '../state/mission_stage_controller.dart';
import '../state/mission_state.dart';

class AnalysisScene extends StatefulWidget {
  const AnalysisScene({super.key, required this.controller});

  final MissionStageController controller;

  @override
  State<AnalysisScene> createState() => _AnalysisSceneState();
}

class _AnalysisSceneState extends State<AnalysisScene>
    with SingleTickerProviderStateMixin {
  final List<Offset> _stroke = [];
  bool _drawing = false;
  int _lastWrongToken = 0;
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  static const _layers = [SCC.layerCloud, SCC.layerRainHeat, SCC.layerWindRadar];
  static const _tabs = [
    (Icons.cloud_rounded, 'CLOUD VIEW'),
    (Icons.water_drop_rounded, 'RAIN + HEAT'),
    (Icons.air_rounded, 'WIND FLOW'),
  ];

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  void _endStroke(Size area) {
    if (!_drawing || _stroke.length < AnalysisTuning.minCirclePoints) {
      setState(() {
        _drawing = false;
        _stroke.clear();
      });
      return;
    }
    _drawing = false;

    // target zone in px
    final target = Offset(area.width * AnalysisTuning.cycloneCenter.dx,
        area.height * AnalysisTuning.cycloneCenter.dy);
    final targetR = area.width * AnalysisTuning.cycloneRadius;

    // overlap: fraction of sample points across the target disk that fall
    // inside the drawn polygon
    var inside = 0, total = 0;
    const grid = 9;
    for (var i = 0; i < grid; i++) {
      for (var j = 0; j < grid; j++) {
        final p = Offset(
          target.dx + (i / (grid - 1) - 0.5) * 2 * targetR,
          target.dy + (j / (grid - 1) - 0.5) * 2 * targetR,
        );
        if ((p - target).distance > targetR) continue;
        total++;
        if (_pointInPolygon(p, _stroke)) inside++;
      }
    }
    final overlap = total == 0 ? 0.0 : inside / total;

    // centroid distance (in target radii) for the "close" hint band
    var cx = 0.0, cy = 0.0;
    for (final p in _stroke) {
      cx += p.dx;
      cy += p.dy;
    }
    final centroid = Offset(cx / _stroke.length, cy / _stroke.length);
    final centerDistFactor = (centroid - target).distance / targetR;

    widget.controller.circleDrawn(
        overlap: overlap, centerDistFactor: centerDistFactor);
    if (overlap < AnalysisTuning.minOverlap) {
      // rejected stroke fades via the shake animation; clear after
      _shake.forward(from: 0).then((_) {
        if (mounted) setState(_stroke.clear);
      });
    } else {
      setState(() {});
    }
  }

  bool _pointInPolygon(Offset p, List<Offset> poly) {
    var inside = false;
    for (var i = 0, j = poly.length - 1; i < poly.length; j = i++) {
      final a = poly[i], b = poly[j];
      if ((a.dy > p.dy) != (b.dy > p.dy) &&
          p.dx < (b.dx - a.dx) * (p.dy - a.dy) / (b.dy - a.dy) + a.dx) {
        inside = !inside;
      }
    }
    return inside;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final a = widget.controller.state.analysis;
        if (a.wrongToken != _lastWrongToken) {
          _lastWrongToken = a.wrongToken;
        }
        final found = a.phase == AnalysisPhase.found;
        // the circle step unlocks after all three layers have been viewed
        final toured = a.visitedLayers.length >= 3;
        final canDraw = toured && !found;

        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(child: sceneVignette(strength: 0.4)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
            children: [
              // ── layer tabs ───────────────────────────────────────────────
              Row(
                children: [
                  for (var i = 0; i < _tabs.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(
                      child: _LayerTab(
                        icon: _tabs[i].$1,
                        label: _tabs[i].$2,
                        active: a.layer == i,
                        visited: a.visitedLayers.contains(i),
                        onTap: () => widget.controller.setAnalysisLayer(i),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              // ── image + draw surface ─────────────────────────────────────
              Expanded(
                child: LayoutBuilder(
                  builder: (context, box) {
                    final area = Size(box.maxWidth, box.maxHeight);
                    return GestureDetector(
                      onPanStart: !canDraw
                          ? null
                          : (d) => setState(() {
                                _drawing = true;
                                _stroke
                                  ..clear()
                                  ..add(d.localPosition);
                              }),
                      onPanUpdate: !canDraw
                          ? null
                          : (d) => setState(() => _stroke.add(d.localPosition)),
                      onPanEnd: !canDraw ? null : (_) => _endStroke(area),
                      child: Container(
                        decoration: sccPanel(
                            borderColor: found ? SccColors.success : null,
                            radius: 20),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // crossfading layers (frameless, generated from
                            // the Stage-4 captured photo)
                            for (var i = 0; i < _layers.length; i++)
                              AnimatedOpacity(
                                duration: const Duration(milliseconds: 350),
                                opacity: a.layer == i ? 1 : 0,
                                child: sccImage(SCC.flutter(_layers[i]),
                                    fit: BoxFit.cover),
                              ),
                            // 3rd hint → visually ring the cyclone zone
                            // (PRD §22.4 level-3 visual guide)
                            if (!found &&
                                widget.controller
                                        .hintLevelFor(MissionStage.readImage) >=
                                    3)
                              Align(
                                alignment: Alignment(
                                  AnalysisTuning.cycloneCenter.dx * 2 - 1,
                                  AnalysisTuning.cycloneCenter.dy * 2 - 1,
                                ),
                                child: IgnorePointer(
                                  child: FractionallySizedBox(
                                    widthFactor: AnalysisTuning.cycloneRadius * 2.4,
                                    child: AspectRatio(
                                      aspectRatio: 1,
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: SccColors.warningAmber
                                                  .withValues(alpha: 0.85),
                                              width: 3),
                                          boxShadow: [
                                            BoxShadow(
                                              color: SccColors.warningAmber
                                                  .withValues(alpha: 0.35),
                                              blurRadius: 16,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            // success: a green check pops on the spiral (the
                            // choose_right_satellite treatment — no cyclone
                            // animation overlay)
                            if (found)
                              Align(
                                alignment: Alignment(
                                  AnalysisTuning.cycloneCenter.dx * 2 - 1,
                                  AnalysisTuning.cycloneCenter.dy * 2 - 1,
                                ),
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0, end: 1),
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.elasticOut,
                                  builder: (context, t, child) =>
                                      Transform.scale(scale: t, child: child),
                                  child: Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: SccColors.panelNavy
                                          .withValues(alpha: 0.85),
                                      boxShadow: [
                                        BoxShadow(
                                          color: SccColors.success
                                              .withValues(alpha: 0.55),
                                          blurRadius: 20,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(Icons.check_circle_rounded,
                                        size: 52, color: SccColors.success),
                                  ),
                                ),
                              ),
                            // scan corner brackets (instrument framing)
                            IgnorePointer(
                              child: CustomPaint(
                                size: Size.infinite,
                                painter: _CornerBracketsPainter(
                                    color: found
                                        ? SccColors.success
                                        : SccColors.cyan),
                              ),
                            ),
                            // the drawn stroke
                            IgnorePointer(
                              child: AnimatedBuilder(
                                animation: _shake,
                                builder: (context, _) => CustomPaint(
                                  painter: _StrokePainter(
                                    stroke: _stroke,
                                    color: found
                                        ? SccColors.success
                                        : _shake.isAnimating
                                            ? SccColors.alertRed
                                            : SccColors.white,
                                    fade: _shake.isAnimating ? 1 - _shake.value : 1,
                                  ),
                                ),
                              ),
                            ),
                            // affordance — tour first, then circle
                            if (_stroke.isEmpty && !found)
                              Positioned(
                                bottom: 10,
                                left: 0,
                                right: 0,
                                child: IgnorePointer(
                                  child: Column(
                                    children: [
                                      Icon(
                                          toured
                                              ? Icons.gesture_rounded
                                              : Icons.layers_rounded,
                                          color: SccColors.cyan,
                                          size: 24),
                                      Text(
                                          toured
                                              ? 'circle the cyclone spiral'
                                              : 'view all three layers first',
                                          style: SccText.label
                                              .copyWith(color: SccColors.cyan)),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LayerTab extends StatelessWidget {
  const _LayerTab(
      {required this.icon,
      required this.label,
      required this.active,
      required this.visited,
      required this.onTap});

  final IconData icon;
  final String label;
  final bool active;
  final bool visited;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? SccColors.cyan : SccColors.textMuted;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          gradient: active
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    SccColors.cyan.withValues(alpha: 0.30),
                    SccColors.cyan.withValues(alpha: 0.08),
                  ],
                )
              : null,
          color: active ? null : SccColors.panelFill,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: active ? SccColors.cyan : SccColors.panelBorder,
              width: active ? 1.6 : 1),
          boxShadow: active
              ? [BoxShadow(color: SccColors.cyan.withValues(alpha: 0.3), blurRadius: 10)]
              : null,
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: color),
                if (visited) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.check_circle_rounded,
                      size: 12, color: SccColors.success),
                ],
              ],
            ),
            const SizedBox(height: 2),
            Text(label, style: SccText.label.copyWith(fontSize: 9, color: color)),
          ],
        ),
      ),
    );
  }
}

class _CornerBracketsPainter extends CustomPainter {
  _CornerBracketsPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    const m = 12.0, len = 22.0;
    final corners = <(Offset, Offset, Offset)>[
      (const Offset(m, m), const Offset(1, 0), const Offset(0, 1)),
      (Offset(size.width - m, m), const Offset(-1, 0), const Offset(0, 1)),
      (Offset(m, size.height - m), const Offset(1, 0), const Offset(0, -1)),
      (Offset(size.width - m, size.height - m), const Offset(-1, 0), const Offset(0, -1)),
    ];
    for (final (o, dx, dy) in corners) {
      canvas.drawLine(o, o + dx * len, p);
      canvas.drawLine(o, o + dy * len, p);
    }
  }

  @override
  bool shouldRepaint(covariant _CornerBracketsPainter old) => old.color != color;
}

class _StrokePainter extends CustomPainter {
  _StrokePainter({required this.stroke, required this.color, required this.fade});

  final List<Offset> stroke;
  final Color color;
  final double fade;

  @override
  void paint(Canvas canvas, Size size) {
    if (stroke.length < 2) return;
    final paint = Paint()
      ..color = color.withValues(alpha: 0.95 * fade)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2);
    final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
    for (final p in stroke.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _StrokePainter old) =>
      old.stroke.length != stroke.length || old.color != color || old.fade != fade;
}
