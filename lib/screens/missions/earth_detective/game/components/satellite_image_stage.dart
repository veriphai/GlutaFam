// The satellite image stage: the single source of truth for the displayed
// image rect, the zoom/pan transform, and ALL normalised↔screen conversion.
// It renders, in one shared transform: the scene image (or before/after
// composite), the scan-grid HUD, the hint glow, the clue-reveal overlays, and
// the scanner lens. Keeping every layer here means none of them drift apart
// when the ship mission zooms (the "size overlays from the base, share one
// transform" gotchas).

import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../config/asset_paths.dart';
import '../../models/earth_detective_mission.dart';
import '../../state/earth_detective_state.dart';
import '../earth_detective_game.dart';
import '../../../../../utils/s3_assets.dart';

class SatelliteImageStage extends PositionComponent
    with HasGameReference<EarthDetectiveGame> {
  SatelliteImageStage();

  static const _cyan = Color(0xFF18D6FF);
  static const _green = Color(0xFF65D65E);

  EarthDetectiveMission? _mission;
  Sprite? _scene; // base / before
  Sprite? _after; // compare after image
  int _loadGen = 0; // guards against stale async scene loads
  int _loadedIndex = -1; // which mission's scene is currently loaded

  // animation clocks
  double _gridPhase = 0;
  double _revealT = 0; // overlay reveal 0..1
  double _flashT = -1; // scanner success flash (-1 = idle)
  double _sweepT = -1; // change-detection sweep (-1 = idle)
  int _lastSuccess = 0;
  int _lastSweep = 0;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
    position = Vector2.zero();
  }

  /// Loads a mission's scene image(s) and resets the animation clocks.
  void loadMission(EarthDetectiveMission m) {
    _mission = m;
    _scene = null;
    _after = null;
    _revealT = 0;
    _flashT = -1;
    _sweepT = -1;
    final gen = ++_loadGen;
    loadFlameImageFromS3(game.images, m.sceneAsset).then((img) {
      if (img != null && gen == _loadGen) _scene = Sprite(img);
    });
    if (m.secondarySceneAsset != null) {
      loadFlameImageFromS3(game.images, m.secondarySceneAsset!).then((img) {
        if (img != null && gen == _loadGen) _after = Sprite(img);
      });
    }
  }

  // ── transform & coordinate conversion ──────────────────────────────────
  /// The un-zoomed, contain-fitted 4:3 image rect. A headroom band is reserved
  /// at the TOP for the floating satellite; the image is top-anchored just below
  /// it so there's no wasted letterbox at the bottom of the card.
  static const double _topHeadFactor = 0.20; // satellite headroom (of width)

  Rect get imageRect {
    if (size.x <= 0 || size.y <= 0) return Rect.zero;
    const pad = 6.0;
    final topHead = size.x * _topHeadFactor;
    final avail = Rect.fromLTWH(pad, topHead, size.x - pad * 2, size.y - topHead - pad);
    const aspect = 4 / 3;
    double w = avail.width, h = w / aspect;
    if (h > avail.height) {
      h = avail.height;
      w = h * aspect;
    }
    // centred in the area below the satellite headroom
    return Rect.fromLTWH(
      avail.left + (avail.width - w) / 2,
      avail.top + (avail.height - h) / 2,
      w,
      h,
    );
  }

  /// The image rect after zoom about the focal point (scanner position),
  /// clamped to always cover [imageRect].
  Rect get displayRect {
    final ir = imageRect;
    final s = game.controller.state;
    final zoom = (_mission?.interactionMode == InteractionMode.compareBeforeAfter)
        ? 1.0
        : s.zoomLevel;
    if (zoom <= 1.0001) return ir;
    final w = ir.width * zoom, h = ir.height * zoom;
    final focal = s.scannerNorm;
    double left = ir.left + focal.dx * ir.width - focal.dx * w;
    double top = ir.top + focal.dy * ir.height - focal.dy * h;
    left = left.clamp(ir.right - w, ir.left);
    top = top.clamp(ir.bottom - h, ir.top);
    return Rect.fromLTWH(left, top, w, h);
  }

  Offset normToScreen(Offset n) {
    final r = displayRect;
    return Offset(r.left + n.dx * r.width, r.top + n.dy * r.height);
  }

  Offset screenToNorm(Offset s) {
    final r = displayRect;
    if (r.width == 0 || r.height == 0) return const Offset(0.5, 0.5);
    return Offset((s.dx - r.left) / r.width, (s.dy - r.top) / r.height);
  }

  // ── update ─────────────────────────────────────────────────────────────
  @override
  void update(double dt) {
    super.update(dt);
    final s = game.controller.state;

    // Drive the per-mission scene swap from update() (which runs every frame
    // while mounted), NOT a controller listener: the GameWidget unmounts
    // between missions, so a listener added in onLoad would be torn down by
    // onRemove and never reload later missions.
    if (s.scene == EdScene.missionPlay && s.missionIndex != _loadedIndex) {
      _loadedIndex = s.missionIndex;
      loadMission(game.controller.mission);
    }

    _gridPhase += dt * 0.22;

    final revealing = s.phase == PlayPhase.resolving || s.phase == PlayPhase.found;
    if (revealing) {
      _revealT = math.min(1, _revealT + dt / 0.5);
    } else {
      _revealT = 0;
    }

    if (s.successToken != _lastSuccess) {
      _lastSuccess = s.successToken;
      _flashT = 0;
    }
    if (_flashT >= 0) {
      _flashT += dt / 0.6;
      if (_flashT > 1) _flashT = -1;
    }

    if (s.sweepToken != _lastSweep) {
      _lastSweep = s.sweepToken;
      if (_mission?.interactionMode == InteractionMode.compareBeforeAfter) _sweepT = 0;
    }
    if (_sweepT >= 0) {
      _sweepT += dt / 0.9;
      if (_sweepT > 1) _sweepT = -1;
    }
  }

  // ── render ───────────────────────────────────────────────────────────────
  @override
  void render(Canvas canvas) {
    final ir = imageRect;
    if (ir.isEmpty) return;
    final rrect = RRect.fromRectAndRadius(ir, const Radius.circular(18));

    canvas.save();
    canvas.clipRRect(rrect);

    // dark placeholder while the scene streams in
    canvas.drawRect(ir, Paint()..color = const Color(0xFF0A1430));

    final compare = _mission?.interactionMode == InteractionMode.compareBeforeAfter;
    if (compare) {
      _renderCompare(canvas, ir);
    } else if (_scene != null) {
      _drawSpriteRect(canvas, _scene!, displayRect);
    }

    _renderScanGrid(canvas, ir);
    _renderHintGlow(canvas, ir);
    if (_revealT > 0) _renderOverlays(canvas);

    canvas.restore();

    // Satellite + beam + scanner draw OUTSIDE the image clip. In the compare
    // mission aiming is TAP-based, so the target/beam only appear after the
    // first tap (scannerActive) — sliding the divider never moves them.
    final s = game.controller.state;
    final showTarget = !compare || s.scannerActive;
    if (showTarget) {
      final target = normToScreen(s.scannerNorm);
      final locked = s.scannerState == ScannerState.lock;
      _renderBeam(canvas, _satEmit(ir), target, ir, locked);
      _renderScanner(canvas, ir);
    }
    if (compare) {
      // slider pucks at the exact ends of the divider, unclipped
      final divX = ir.left + s.sliderNorm.clamp(0.0, 1.0) * ir.width;
      _drawSliderHandle(canvas, Offset(divX, ir.top));
      _drawSliderHandle(canvas, Offset(divX, ir.bottom));
    }
    _renderSatellite(canvas, ir);

    // HUD corner brackets sit on top of the rounded frame edge.
    _renderCornerBrackets(canvas, ir);
  }

  // ── satellite + beam (Restore-Earth style link to the scanner) ─────────
  double _satWidth(Rect ir) => ir.width * 0.20;

  Offset _satCenter(Rect ir) {
    final spr = game.sprite(EdAssets.satelliteTiny);
    final h = _satWidth(ir) / (spr.srcSize.x / spr.srcSize.y);
    final bob = math.sin(_gridPhase * 2 * math.pi) * 4;
    final minCy = h * 0.5 + 2;
    final cy = math.max(minCy, ir.top * 0.5 + bob); // float in the top letterbox
    return Offset(size.x * 0.5, cy);
  }

  Offset _satEmit(Rect ir) {
    final spr = game.sprite(EdAssets.satelliteTiny);
    final h = _satWidth(ir) / (spr.srcSize.x / spr.srcSize.y);
    return _satCenter(ir) + Offset(0, h * 0.40); // dish/underside
  }

  void _renderSatellite(Canvas canvas, Rect ir) {
    _drawSpriteCentered(canvas, game.sprite(EdAssets.satelliteTiny), _satCenter(ir), _satWidth(ir));
  }

  /// A glowing beam from the satellite to the scanner. Cyan thin line normally;
  /// green + widening cone when the scanner is locked on the clue.
  void _renderBeam(Canvas canvas, Offset emit, Offset target, Rect ir, bool locked) {
    final d = target - emit;
    final len = d.distance;
    if (len < 1) return;
    final color = locked ? _green : _cyan;
    final ux = d.dx / len, uy = d.dy / len;
    final px = -uy, py = ux; // perpendicular unit

    if (locked) {
      final apexH = ir.width * 0.012, baseH = ir.width * 0.075;
      final cone = Path()
        ..moveTo(emit.dx + px * apexH, emit.dy + py * apexH)
        ..lineTo(target.dx + px * baseH, target.dy + py * baseH)
        ..lineTo(target.dx - px * baseH, target.dy - py * baseH)
        ..lineTo(emit.dx - px * apexH, emit.dy - py * apexH)
        ..close();
      canvas.drawPath(
        cone,
        Paint()
          ..color = color.withValues(alpha: 0.22)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawPath(cone, Paint()..color = color.withValues(alpha: 0.28));
    }

    canvas.drawLine(
      emit,
      target,
      Paint()
        ..color = color.withValues(alpha: 0.30)
        ..strokeWidth = 7
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawLine(emit, target, Paint()..color = color.withValues(alpha: 0.7)..strokeWidth = 3);
    canvas.drawLine(emit, target, Paint()..color = Colors.white.withValues(alpha: 0.9)..strokeWidth = 1.4);
    canvas.drawCircle(emit, ir.width * 0.013, Paint()..color = color);
  }

  // scene compositing for the before/after mission
  void _renderCompare(Canvas canvas, Rect ir) {
    if (_scene != null) _drawSpriteRect(canvas, _scene!, ir);
    final s = game.controller.state;
    final divX = ir.left + s.sliderNorm.clamp(0.0, 1.0) * ir.width;
    if (_after != null) {
      canvas.save();
      canvas.clipRect(Rect.fromLTRB(divX, ir.top, ir.right, ir.bottom));
      _drawSpriteRect(canvas, _after!, ir);
      canvas.restore();
    }

    // overlays (deforestation boundary + sweep) draw before the divider so the
    // bright divider/handle stay on top
    if (_revealT > 0) _renderOverlays(canvas);
    if (_sweepT >= 0) {
      final sprite = game.sprite(EdAssets.cmpSweep);
      final x = ir.left + _sweepT * ir.width;
      final bandW = ir.width * 0.14;
      _drawSpriteCentered(canvas, sprite, Offset(x, ir.center.dy), bandW,
          opacity: math.sin(_sweepT * math.pi));
    }

    // A single, crisp glowing divider line marks the reveal boundary; the
    // scanner (drawn on top) is the draggable handle now.
    _drawDividerLine(canvas, divX, ir);
  }

  /// A clean vertical divider: soft cyan glow → mid stroke → bright white core,
  /// with ◄► slider-handle pucks at the top and bottom so it reads as draggable
  /// rather than a static dividing line.
  void _drawDividerLine(Canvas canvas, double x, Rect ir) {
    final top = Offset(x, ir.top), bottom = Offset(x, ir.bottom);
    canvas.drawLine(
      top,
      bottom,
      Paint()
        ..color = _cyan.withValues(alpha: 0.30)
        ..strokeWidth = 9
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawLine(top, bottom, Paint()..color = _cyan.withValues(alpha: 0.65)..strokeWidth = 3.5);
    canvas.drawLine(top, bottom, Paint()..color = Colors.white.withValues(alpha: 0.95)..strokeWidth = 1.6);
    // handle pucks are drawn OUTSIDE the image clip (see render()) so they can
    // sit exactly on the line's ends without being half-clipped
  }

  /// A round puck with left/right arrowheads — the "drag me sideways" affordance.
  void _drawSliderHandle(Canvas canvas, Offset c) {
    const r = 14.0;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = _cyan.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawCircle(c, r, Paint()..color = const Color(0xE60A1A38));
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = _cyan,
    );
    final arrow = Paint()..color = Colors.white;
    canvas.drawPath(
      Path() // ◄
        ..moveTo(c.dx - 4.5, c.dy - 4.5)
        ..lineTo(c.dx - 4.5, c.dy + 4.5)
        ..lineTo(c.dx - 9.5, c.dy)
        ..close(),
      arrow,
    );
    canvas.drawPath(
      Path() // ►
        ..moveTo(c.dx + 4.5, c.dy - 4.5)
        ..lineTo(c.dx + 4.5, c.dy + 4.5)
        ..lineTo(c.dx + 9.5, c.dy)
        ..close(),
      arrow,
    );
  }

  void _renderScanGrid(Canvas canvas, Rect ir) {
    final line = Paint()
      ..color = _cyan.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    for (int i = 1; i < 7; i++) {
      final x = ir.left + ir.width * i / 7;
      canvas.drawLine(Offset(x, ir.top), Offset(x, ir.bottom), line);
    }
    for (int i = 1; i < 5; i++) {
      final y = ir.top + ir.height * i / 5;
      canvas.drawLine(Offset(ir.left, y), Offset(ir.right, y), line);
    }
    // moving HUD sweep line
    final sy = ir.top + (_gridPhase % 1) * ir.height;
    canvas.drawLine(Offset(ir.left, sy), Offset(ir.right, sy),
        Paint()..color = _cyan.withValues(alpha: 0.10)..strokeWidth = 1.5);
  }

  void _renderHintGlow(Canvas canvas, Rect ir) {
    final s = game.controller.state;
    if (s.phase != PlayPhase.investigating || s.hintLevel < 3 || _mission == null) return;
    final breathe = 0.5 + 0.5 * math.sin(_gridPhase * 2 * math.pi);
    final pz = _mission!.clueProximityZone;
    final center = normToScreen(pz.center);
    final radius = pz.width * displayRect.width * 0.5;
    // level 3: pulsing ring over the correct quadrant
    canvas.drawCircle(
      center,
      radius * (0.9 + 0.1 * breathe),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = _cyan.withValues(alpha: 0.25 + 0.25 * breathe),
    );
    // level 4+: broaden with a soft fill
    if (s.hintLevel >= 4) {
      canvas.drawCircle(center, radius,
          Paint()..color = _cyan.withValues(alpha: 0.06 + 0.05 * breathe));
    }
  }

  void _renderOverlays(Canvas canvas) {
    final m = _mission;
    if (m == null) return;

    // success glow ring blooms at the clue centre first
    final glowCenter = normToScreen(m.clueCenter);
    final glow = game.sprite(EdAssets.fxSuccessGlow);
    _drawSpriteCentered(canvas, glow, glowCenter,
        displayRect.width * 0.30 * (0.6 + 0.6 * _revealT),
        opacity: (1 - _revealT) * 0.9, additive: true);

    for (final ov in m.overlays) {
      final t = _delayed(_revealT, ov.delay);
      if (t <= 0) continue;
      final sprite = game.sprite(ov.asset);
      final center = normToScreen(ov.centerNorm);
      final baseW = displayRect.width * ov.widthFactor;
      switch (ov.anim) {
        case OverlayAnim.pulse:
          final breathe = 1 + 0.04 * math.sin(_gridPhase * 4 * math.pi);
          _drawSpriteCentered(canvas, sprite, center,
              baseW * _overshoot(t) * breathe,
              opacity: t, additive: ov.additive);
        case OverlayAnim.fadePulse:
          final breathe = 0.82 + 0.18 * (0.5 + 0.5 * math.sin(_gridPhase * 3 * math.pi));
          _drawSpriteCentered(canvas, sprite, center, baseW,
              opacity: t * breathe, additive: ov.additive);
        case OverlayAnim.pinDrop:
          final drop = (1 - t) * displayRect.height * 0.12;
          _drawSpriteCentered(canvas, sprite, center.translate(0, -drop), baseW,
              opacity: t, additive: ov.additive);
        case OverlayAnim.sweep:
          _drawSpriteCentered(canvas, sprite, center, baseW * _overshoot(t),
              opacity: t, additive: ov.additive);
      }
    }
  }

  void _renderScanner(Canvas canvas, Rect ir) {
    final s = game.controller.state;
    // Always visible during play (sits at the centre until the child drags it).
    final center = normToScreen(s.scannerNorm);
    final radius = ir.width * 0.075; // BASE size — never scales with zoom
    final locked = s.scannerState == ScannerState.lock;
    final near = s.scannerState == ScannerState.near;
    // Flutter-drawn target: cyan while scanning, green when locked on the clue.
    _drawScanTarget(canvas, center, radius, locked ? _green : _cyan, sweep: !locked, near: near);

    // success flash — expanding green bloom
    if (_flashT >= 0) {
      final fr = radius * (1 + 1.5 * _flashT);
      final a = (1 - _flashT).clamp(0.0, 1.0);
      canvas.drawCircle(center, fr, Paint()..color = _green.withValues(alpha: a * 0.22));
      canvas.drawCircle(
        center,
        fr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = _green.withValues(alpha: a),
      );
    }
  }

  /// The scanner/target reticle, drawn programmatically (matches the tutorial):
  /// concentric rings + crosshair + rotating sweep, with a translucent centre so
  /// the satellite image shows through.
  void _drawScanTarget(Canvas canvas, Offset c, double r, Color color,
      {bool sweep = true, bool near = false}) {
    // translucent interior
    canvas.drawCircle(c, r, Paint()..color = color.withValues(alpha: near ? 0.18 : 0.10));
    // soft outer glow
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..color = color.withValues(alpha: near ? 0.45 : 0.30)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    // outer + inner rings
    canvas.drawCircle(c, r, Paint()..style = PaintingStyle.stroke..strokeWidth = 3..color = color);
    canvas.drawCircle(c, r * 0.5,
        Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = color.withValues(alpha: 0.85));
    // centre dot
    canvas.drawCircle(c, (r * 0.12).clamp(2.5, 5.0), Paint()..color = color);
    // crosshair ticks
    final tick = Paint()..color = color..strokeWidth = 2.4..strokeCap = StrokeCap.round;
    final t = r * 0.18;
    for (final o in const [Offset(1, 0), Offset(-1, 0), Offset(0, 1), Offset(0, -1)]) {
      canvas.drawLine(c + o * (r - t), c + o * (r + t * 0.6), tick);
    }
    // rotating sweep tick (scanning only)
    if (sweep) {
      final a = _gridPhase * 2 * math.pi;
      final dir = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(
        c,
        c + dir * (r - 3),
        Paint()..color = color.withValues(alpha: 0.7)..strokeWidth = 2..strokeCap = StrokeCap.round,
      );
    }
  }

  void _renderCornerBrackets(Canvas canvas, Rect ir) {
    final p = Paint()
      ..color = _cyan.withValues(alpha: 0.55)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    final len = ir.width * 0.06;
    void corner(Offset o, double dx, double dy) {
      canvas.drawLine(o, o.translate(dx * len, 0), p);
      canvas.drawLine(o, o.translate(0, dy * len), p);
    }
    corner(ir.topLeft, 1, 1);
    corner(ir.topRight, -1, 1);
    corner(ir.bottomLeft, 1, -1);
    corner(ir.bottomRight, -1, -1);
  }

  // ── drawing helpers ────────────────────────────────────────────────────
  void _drawSpriteRect(Canvas canvas, Sprite sprite, Rect rect) {
    sprite.render(
      canvas,
      position: Vector2(rect.left, rect.top),
      size: Vector2(rect.width, rect.height),
      overridePaint: Paint()..filterQuality = FilterQuality.high,
    );
  }

  /// Draws [sprite] centred at [center] with the given on-screen [width]
  /// (height derived from the sprite's intrinsic aspect, unless [vertical] +
  /// [targetHeight] are given for tall glow strips).
  void _drawSpriteCentered(
    Canvas canvas,
    Sprite sprite,
    Offset center,
    double width, {
    double opacity = 1.0,
    bool additive = false,
    bool vertical = false,
    double? targetHeight,
    Color? tint,
  }) {
    if (opacity <= 0) return;
    final aspect = sprite.srcSize.x / sprite.srcSize.y;
    double w, h;
    if (vertical && targetHeight != null) {
      h = targetHeight;
      w = h * aspect;
    } else {
      w = width;
      h = w / aspect;
    }
    final paint = Paint()
      ..filterQuality = FilterQuality.high
      ..color = Color.fromRGBO(255, 255, 255, opacity.clamp(0.0, 1.0));
    if (tint != null) paint.colorFilter = ColorFilter.mode(tint, BlendMode.modulate);
    if (additive) paint.blendMode = BlendMode.plus;
    sprite.render(
      canvas,
      position: Vector2(center.dx - w / 2, center.dy - h / 2),
      size: Vector2(w, h),
      overridePaint: paint,
    );
  }

  /// Reveal progress that starts after [delay] within the 0.5s reveal window.
  double _delayed(double t, Duration delay) {
    final d = delay.inMilliseconds / 500.0;
    if (d <= 0) return t;
    return ((t - d) / (1 - d)).clamp(0.0, 1.0);
  }

  /// Ease-out-back style overshoot for pop-in scale.
  double _overshoot(double t) {
    final x = t - 1;
    return 1 + (2.7 * x * x * x + 1.7 * x * x);
  }
}
