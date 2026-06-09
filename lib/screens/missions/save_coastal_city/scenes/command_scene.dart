// Stage 8 — Upload Command Sequence (PRD §19). Circuit-board panel with the 6
// command nodes laid out as a 2-column zig-zag path. The child DRAWS a glowing
// connection from the path's tail to the next node — correct links persist
// with a green line, wrong links spark red and Orbit explains the concept.
// When the path completes, HOLD TO UPLOAD fills the bar and the energy column
// rises to the satellite.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config/scc_assets.dart';
import '../config/scc_stage_configs.dart';
import '../config/scc_theme.dart';
import '../state/mission_stage_controller.dart';
import '../state/mission_state.dart';
import '../widgets/scc_buttons.dart';

class CommandScene extends StatefulWidget {
  const CommandScene({super.key, required this.controller});

  final MissionStageController controller;

  @override
  State<CommandScene> createState() => _CommandSceneState();
}

class _CommandSceneState extends State<CommandScene>
    with TickerProviderStateMixin {
  Offset? _fingerPos; // live connection endpoint while dragging
  bool _dragging = false;

  int _lastWrongToken = 0;
  CommandNode? _wrongFlashTarget;
  late final AnimationController _wrongFlash = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 550),
  );
  // loops a data spark along the already-connected path
  late final AnimationController _spark = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat();

  @override
  void dispose() {
    _wrongFlash.dispose();
    _spark.dispose();
    super.dispose();
  }

  static const _nodeSizeF = 0.34; // of column width

  Offset _nodeCenter(CommandDef def, Size area) =>
      Offset(area.width * def.anchor.dx, area.height * def.anchor.dy);

  CommandDef? _hitNode(Offset p, Size area) {
    for (final def in kCommandDefs) {
      final c = _nodeCenter(def, area);
      if ((p - c).distance < area.width * _nodeSizeF * 0.55) return def;
    }
    return null;
  }

  void _dragStart(Offset p, Size area) {
    final c = widget.controller.state.command;
    if (c.phase != CommandPhase.connecting) return;
    final tail = kCommandDefs.firstWhere(
        (d) => d.node == kCommandSequence[c.connected]);
    if ((p - _nodeCenter(tail, area)).distance < area.width * _nodeSizeF * 0.7) {
      setState(() {
        _dragging = true;
        _fingerPos = p;
      });
    }
  }

  void _dragEnd(Size area) {
    if (!_dragging) return;
    final p = _fingerPos;
    setState(() {
      _dragging = false;
      _fingerPos = null;
    });
    if (p == null) return;
    final hit = _hitNode(p, area);
    final c = widget.controller.state.command;
    if (hit == null || hit.node == kCommandSequence[c.connected]) return;
    widget.controller.tryConnect(hit.node);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final c = widget.controller.state.command;
        if (c.wrongToken != _lastWrongToken) {
          _lastWrongToken = c.wrongToken;
          _wrongFlashTarget = c.wrongTarget;
          _wrongFlash.forward(from: 0);
        }
        final uploading =
            c.phase == CommandPhase.uploading || c.phase == CommandPhase.done;

        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(child: sceneVignette(strength: 0.4)),
            Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              // ── the command board ────────────────────────────────────────
              Expanded(
                child: LayoutBuilder(
                  builder: (context, box) {
                    final area = Size(box.maxWidth, box.maxHeight);
                    final tailNode = kCommandSequence[c.connected];
                    return GestureDetector(
                      onPanStart: (d) => _dragStart(d.localPosition, area),
                      onPanUpdate: (d) {
                        if (_dragging) {
                          setState(() => _fingerPos = d.localPosition);
                        }
                      },
                      onPanEnd: (_) => _dragEnd(area),
                      child: Container(
                        decoration: sccPanel(radius: 20),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // board texture
                            Opacity(
                              opacity: 0.5,
                              child: sccImage(SCC.flutter(SCC.commandBoard),
                                  fit: BoxFit.cover),
                            ),
                            // upload energy column behind the nodes —
                            // procedural (the sprite shipped baked checker),
                            // same multi-pass glow language as the beams
                            if (uploading)
                              IgnorePointer(
                                child: AnimatedBuilder(
                                  animation: _spark,
                                  builder: (context, _) => CustomPaint(
                                    size: Size.infinite,
                                    painter: _UploadColumnPainter(
                                      progress: c.uploadProgress,
                                      t: _spark.value,
                                    ),
                                  ),
                                ),
                              ),
                            // connection lines + live drag line + data spark
                            IgnorePointer(
                              child: AnimatedBuilder(
                                animation:
                                    Listenable.merge([_wrongFlash, _spark]),
                                builder: (context, _) => CustomPaint(
                                  painter: _LinksPainter(
                                    area: area,
                                    connected: c.connected,
                                    nodeCenter: (def) => _nodeCenter(def, area),
                                    livePos: _dragging ? _fingerPos : null,
                                    tail: tailNode,
                                    wrongTarget:
                                        _wrongFlash.isAnimating ? _wrongFlashTarget : null,
                                    wrongFade: 1 - _wrongFlash.value,
                                    sparkPhase: _spark.value,
                                  ),
                                ),
                              ),
                            ),
                            // the 6 nodes
                            for (var i = 0; i < kCommandDefs.length; i++)
                              _NodeWidget(
                                def: kCommandDefs[i],
                                area: area,
                                sizePx: area.width * _nodeSizeF,
                                state: _nodeStateFor(kCommandDefs[i].node, c),
                                // 3rd hint → glow the correct next node
                                // (PRD §22.4 level-3 visual guide)
                                guide: c.phase == CommandPhase.connecting &&
                                    widget.controller.hintLevelFor(
                                            MissionStage.uploadCommands) >=
                                        3 &&
                                    kCommandDefs[i].node ==
                                        kCommandSequence[c.connected + 1],
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              // ── upload hold ──────────────────────────────────────────────
              if (c.phase == CommandPhase.done)
                SccCta(
                  label: 'UPLOAD COMPLETE',
                  icon: Icons.check_rounded,
                  enabled: false,
                  onTap: () {},
                )
              else
                HoldButton(
                  label: 'HOLD TO UPLOAD',
                  icon: Icons.upload_rounded,
                  enabled: c.phase == CommandPhase.readyToUpload ||
                      c.phase == CommandPhase.uploading,
                  holdDuration: const Duration(milliseconds: 2400),
                  onProgress: widget.controller.uploadProgress,
                  onCancelled: widget.controller.uploadCancelled,
                  onComplete: widget.controller.uploadComplete,
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

  _NodeState _nodeStateFor(CommandNode node, CommandSub c) {
    final idx = kCommandSequence.indexOf(node);
    if (idx <= c.connected - 1 ||
        (c.phase != CommandPhase.connecting && idx <= c.connected)) {
      return _NodeState.connected;
    }
    if (idx == c.connected && c.phase == CommandPhase.connecting) {
      return _NodeState.tail;
    }
    if (idx == c.connected + 1 && c.phase == CommandPhase.connecting) {
      return _NodeState.pending; // the (secret) right answer — no telegraphing
    }
    return _NodeState.pending;
  }
}

enum _NodeState { pending, tail, connected }

class _NodeWidget extends StatelessWidget {
  const _NodeWidget(
      {required this.def,
      required this.area,
      required this.sizePx,
      required this.state,
      this.guide = false});

  final CommandDef def;
  final Size area;
  final double sizePx;
  final _NodeState state;
  final bool guide;

  @override
  Widget build(BuildContext context) {
    final c = Offset(area.width * def.anchor.dx, area.height * def.anchor.dy);
    final color = guide
        ? SccColors.warningAmber
        : switch (state) {
            _NodeState.connected => SccColors.success,
            _NodeState.tail => SccColors.cyan,
            _NodeState.pending => SccColors.panelBorder,
          };
    return Positioned(
      left: c.dx - sizePx / 2,
      top: c.dy - sizePx / 2,
      width: sizePx,
      height: sizePx,
      child: IgnorePointer(
        child: Column(
          children: [
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                decoration: BoxDecoration(
                  color: SccColors.panelNavy.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: color,
                      width: state == _NodeState.pending && !guide ? 1.1 : 2),
                  boxShadow: state != _NodeState.pending || guide
                      ? [BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 12)]
                      : null,
                ),
                padding: const EdgeInsets.all(7),
                child: sccImage(SCC.flutter(def.sprite), fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              def.label,
              textAlign: TextAlign.center,
              style: SccText.nodeLabel.copyWith(
                fontSize: 9,
                color: state == _NodeState.pending
                    ? SccColors.textSecondary
                    : SccColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Procedural upload energy column: layered vertical glow (wide soft → core)
/// rising from the board base, with data streaks floating upward. Intensity
/// follows the hold progress; additive over the dark board.
class _UploadColumnPainter extends CustomPainter {
  _UploadColumnPainter({required this.progress, required this.t});

  final double progress; // 0..1 upload hold
  final double t; // looping clock

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final e = 0.35 + 0.65 * progress;
    canvas.saveLayer(null, Paint()..blendMode = BlendMode.plus);

    // layered column passes (wide soft → narrow core), fading toward the top
    void column(double w, double alpha) {
      final rect = Rect.fromLTWH(cx - w / 2, 0, w, size.height);
      canvas.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              SccColors.cyan.withValues(alpha: alpha * e),
              SccColors.cyan.withValues(alpha: alpha * e * 0.35),
              SccColors.cyan.withValues(alpha: 0),
            ],
            stops: const [0.0, 0.6, 1.0],
          ).createShader(rect),
      );
    }

    column(size.width * 0.46, 0.10);
    column(size.width * 0.26, 0.14);
    column(size.width * 0.10, 0.22);

    // rising data streaks (deterministic pseudo-random lanes)
    for (var i = 0; i < 9; i++) {
      final lane = cx + (i % 3 - 1) * size.width * 0.09 +
          math.sin(i * 4.7) * size.width * 0.05;
      final f = (t * (0.6 + (i % 4) * 0.18) + i / 9) % 1.0;
      final y = size.height * (1 - f);
      final len = 14.0 + (i % 3) * 9;
      canvas.drawLine(
        Offset(lane, y),
        Offset(lane, y + len),
        Paint()
          ..color = Colors.white.withValues(alpha: (1 - f) * 0.55 * e)
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _UploadColumnPainter old) =>
      old.progress != progress || old.t != t;
}

class _LinksPainter extends CustomPainter {
  _LinksPainter({
    required this.area,
    required this.connected,
    required this.nodeCenter,
    required this.livePos,
    required this.tail,
    required this.wrongTarget,
    required this.wrongFade,
    required this.sparkPhase,
  });

  final Size area;
  final int connected;
  final Offset Function(CommandDef) nodeCenter;
  final Offset? livePos;
  final CommandNode tail;
  final CommandNode? wrongTarget;
  final double wrongFade;
  final double sparkPhase;

  CommandDef _def(CommandNode n) => kCommandDefs.firstWhere((d) => d.node == n);

  @override
  void paint(Canvas canvas, Size size) {
    // accepted links
    final link = Paint()
      ..color = SccColors.success.withValues(alpha: 0.9)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2);
    for (var i = 0; i < connected; i++) {
      final a = nodeCenter(_def(kCommandSequence[i]));
      final b = nodeCenter(_def(kCommandSequence[i + 1]));
      canvas.drawLine(a, b, link);
    }
    // data spark travelling the connected path (proof the circuit is live)
    if (connected > 0) {
      final f = sparkPhase * connected; // segment-position along the path
      final seg = f.floor().clamp(0, connected - 1);
      final a = nodeCenter(_def(kCommandSequence[seg]));
      final b = nodeCenter(_def(kCommandSequence[seg + 1]));
      final pos = Offset.lerp(a, b, (f - seg).clamp(0.0, 1.0))!;
      canvas.drawCircle(
        pos,
        5,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.9)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
      canvas.drawCircle(
        pos,
        9,
        Paint()
          ..color = SccColors.cyan.withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }
    // live drag line
    if (livePos != null) {
      canvas.drawLine(
        nodeCenter(_def(tail)),
        livePos!,
        Paint()
          ..color = SccColors.cyan.withValues(alpha: 0.9)
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3),
      );
    }
    // wrong-link red spark, fading out
    if (wrongTarget != null) {
      canvas.drawLine(
        nodeCenter(_def(tail)),
        nodeCenter(_def(wrongTarget!)),
        Paint()
          ..color = SccColors.alertRed.withValues(alpha: 0.85 * wrongFade)
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LinksPainter old) =>
      old.connected != connected ||
      old.livePos != livePos ||
      old.wrongTarget != wrongTarget ||
      old.wrongFade != wrongFade ||
      old.sparkPhase != sparkPhase;
}
