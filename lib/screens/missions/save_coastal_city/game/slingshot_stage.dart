// Stage 2 — "Place It in the Right Orbit" (PRD §13): pull-and-release orbit
// slingshot. The child pulls the satellite back from the launch pad, a dashed
// trajectory preview shows where it'll go (colour-coded by predicted band),
// release flies the satellite along the curve; the controller decides the
// banded outcome (tooLow / tooFar / almost / locked — generous + snap).
//
// Everything spatial is a factor of the stage size; programmatic rings/band/
// trajectory/cone painters (AI arc sprites are single-framing renders).

import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart' show Colors;

import '../config/scc_assets.dart';
import '../config/scc_stage_configs.dart';
import '../config/scc_theme.dart';
import '../state/mission_state.dart';
import 'save_city_game.dart';

enum _Phase { idle, dragging, flying, orbiting, returning }

class SlingshotStage extends PositionComponent {
  SlingshotStage({required this.game});

  final SaveCityGame game;

  // ── factor anchors (live-tuning pass expected) ──────────────────────────
  static const _earthCenterF = Offset(0.5, 0.30);
  static const _earthRadiusF = 0.24; // of width
  static const _ringLowF = 0.33;
  static const _ringWatchF = 0.46;
  static const _ringFarF = 0.60;
  static const _slingF = Offset(0.5, 0.84);
  static const _maxPullF = 0.26; // of height

  _Phase _phase = _Phase.idle;
  int _lastFlightToken = 0;

  // drag state
  Vector2? _dragSat; // satellite position while pulling
  double _strength = 0;

  // flight state
  double _t = 0;
  SlingOutcome _outcome = SlingOutcome.none;
  Offset _flightFrom = Offset.zero;
  Offset _flightTo = Offset.zero;
  double _orbitAngle = 0;
  double _orbitTime = 0;
  double _flightR = 0; // arrival radius of the current flight (px)
  final List<Offset> _trail = [];

  // success FX
  double _pulseT = 0; // green pulse after lock

  // ── geometry helpers ────────────────────────────────────────────────────
  Offset get _earthC => Offset(size.x * _earthCenterF.dx, size.y * _earthCenterF.dy);
  double get _earthR => size.x * _earthRadiusF;
  Offset get _slingP => Offset(size.x * _slingF.dx, size.y * _slingF.dy);
  double _ringR(SlingOutcome o) => switch (o) {
        SlingOutcome.tooLow => size.x * _ringLowF,
        SlingOutcome.tooFar => size.x * _ringFarF,
        _ => size.x * _ringWatchF,
      };

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
  }

  Offset _satPos() {
    switch (_phase) {
      case _Phase.idle:
        // Once the controller declares the orbit locked, the satellite LIVES
        // on the watch ring (keeps circling) — it must not snap back to the
        // sling after the flight resolves.
        if (game.controller.state.orbit.phase == SlingPhase.locked) {
          final r = _ringR(SlingOutcome.locked);
          return _earthC +
              Offset(math.cos(_orbitAngle), math.sin(_orbitAngle)) * r;
        }
        return _slingP;
      case _Phase.dragging:
        return Offset(_dragSat!.x, _dragSat!.y);
      case _Phase.flying:
        return _bezier(_flightFrom, _flightTo, _t);
      case _Phase.orbiting:
        return _earthC +
            Offset(math.cos(_orbitAngle), math.sin(_orbitAngle)) * _flightR;
      case _Phase.returning:
        return Offset.lerp(_flightTo, _slingP, _easeInOut(_t))!;
    }
  }

  /// Quadratic bezier from the sling up to the arrival point on the ring.
  Offset _bezier(Offset a, Offset b, double t) {
    final c = Offset(a.dx + (b.dx - a.dx) * 0.15, math.min(a.dy, b.dy) - size.y * 0.10);
    final u = 1 - t;
    return a * (u * u) + c * (2 * u * t) + b * (t * t);
  }

  /// Where a flight of [outcome] arrives: top of its ring, leaning the pull's
  /// lateral aim a little so the release feels causal. An `almost` flight
  /// lands visibly OFF the watch ring (just inside/outside, by which side the
  /// strength missed on) so the "almost there" hint reads true.
  Offset _arrivalFor(SlingOutcome outcome, double strength, double lateral) {
    var r = _ringR(outcome);
    if (outcome == SlingOutcome.almost) {
      r = size.x *
          _ringWatchF *
          (strength < SlingshotTuning.lowMax ? 0.86 : 1.14);
    }
    final ang = -math.pi / 2 + lateral * 0.5;
    return _earthC + Offset(math.cos(ang), math.sin(ang)) * r;
  }

  // ── input (forwarded by the game's gesture catcher) ─────────────────────
  void onStageDragStart(Vector2 p) {
    if (game.controller.state.orbit.phase != SlingPhase.aiming) return;
    if (_phase != _Phase.idle) return;
    // grab anywhere near the lower third — generous for kid fingers
    if (p.y < size.y * 0.55) return;
    _phase = _Phase.dragging;
    _dragSat = p.clone();
  }

  void onStageDragUpdate(Vector2 p, Vector2 delta) {
    if (_phase != _Phase.dragging) return;
    final sling = _slingP;
    // Pull DOWN from the pad (slingshot feel); clamp the leash.
    final raw = Vector2(p.x, math.max(p.y, sling.dy.toDouble()));
    final v = Offset(raw.x - sling.dx, raw.y - sling.dy);
    final maxPull = size.y * _maxPullF;
    final len = v.distance.clamp(0.0, maxPull);
    final dir = v.distance == 0 ? const Offset(0, 1) : v / v.distance;
    final pos = sling + dir * len;
    _dragSat = Vector2(pos.dx, pos.dy);
    _strength = len / maxPull;
  }

  void onStageDragEnd() {
    if (_phase != _Phase.dragging) return;
    final strength = _strength;
    _phase = _Phase.idle; // controller decides; flightToken kicks the flight
    _dragSat = null;
    game.controller.slingshotReleased(strength);
  }

  void onStageTap(Vector2 p) {}

  // ── per-frame ───────────────────────────────────────────────────────────
  @override
  void update(double dt) {
    super.update(dt);
    final orbit = game.controller.state.orbit;

    // launch a flight when the token bumps
    if (orbit.flightToken != _lastFlightToken) {
      _lastFlightToken = orbit.flightToken;
      _outcome = orbit.outcome;
      _t = 0;
      _trail.clear();
      _flightFrom = _slingP;
      const lateral = 0.0; // pull is vertical-leashed; lateral kept for tuning
      _flightTo = _arrivalFor(_outcome, orbit.strength, lateral);
      _flightR = (_flightTo - _earthC).distance;
      _phase = _Phase.flying;
    }

    switch (_phase) {
      case _Phase.flying:
        _t += dt / 1.15;
        _trail.add(_satPos());
        if (_t >= 1) {
          _t = 1;
          _orbitAngle = -math.pi / 2;
          _orbitTime = 0;
          _phase = _Phase.orbiting;
        }
      case _Phase.orbiting:
        _orbitTime += dt;
        _orbitAngle += dt * 1.5;
        final good = _outcome == SlingOutcome.locked;
        if (good) {
          _pulseT = math.min(1, _pulseT + dt * 1.4);
          if (_orbitTime > 1.5) {
            _phase = _Phase.idle;
            game.controller.flightResolved();
          }
        } else if (_orbitTime > 1.1) {
          // wrong band: wobble done — come home
          _flightTo = _satPos();
          _t = 0;
          _phase = _Phase.returning;
        }
      case _Phase.returning:
        _t += dt / 0.55;
        if (_t >= 1) {
          _phase = _Phase.idle;
          _trail.clear();
          game.controller.flightResolved();
        }
      case _Phase.idle:
        // keep the locked satellite gently circling the watch ring
        if (game.controller.state.orbit.phase == SlingPhase.locked) {
          _orbitAngle += dt * 0.6;
        }
      case _Phase.dragging:
        break;
    }
  }

  // ── painting ────────────────────────────────────────────────────────────
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final earthC = _earthC;
    final locked = game.controller.state.orbit.phase == SlingPhase.locked ||
        _phase == _Phase.orbiting && _outcome == SlingOutcome.locked;

    // orbit rings (dashed)
    _dashedCircle(canvas, earthC, size.x * _ringLowF,
        SccColors.textMuted.withValues(alpha: 0.5), 1.4);
    _dashedCircle(canvas, earthC, size.x * _ringFarF,
        SccColors.textMuted.withValues(alpha: 0.5), 1.4);
    // the storm-watch ring glows
    final watchColor = locked ? SccColors.success : SccColors.cyan;
    _dashedCircle(canvas, earthC, size.x * _ringWatchF,
        watchColor.withValues(alpha: 0.25), 7,
        blur: 6);
    _dashedCircle(canvas, earthC, size.x * _ringWatchF, watchColor, 2.2);

    // Earth
    final earth = game.maybeSprite(SCC.earthCycloneCity);
    final earthR = _earthR;
    if (earth != null) {
      earth.render(canvas,
          position: Vector2(earthC.dx - earthR, earthC.dy - earthR),
          size: Vector2.all(earthR * 2));
    } else {
      drawPlaceholder(canvas, earthC, earthR, const Color(0xFF1B4D8C));
    }

    final sat = _satPos();

    // slingshot base + bands
    final base = game.maybeSprite(SCC.slingshotBase);
    final sling = _slingP;
    final baseW = size.x * 0.30;
    if (base != null) {
      base.render(canvas,
          position: Vector2(sling.dx - baseW / 2, sling.dy - baseW * 0.18),
          size: Vector2(baseW, baseW * 0.62));
    }
    final atPad = (_phase == _Phase.idle &&
            game.controller.state.orbit.phase != SlingPhase.locked) ||
        _phase == _Phase.dragging;
    if (atPad) {
      final bandPaint = Paint()
        ..color = SccColors.warningAmber.withValues(alpha: 0.9)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2);
      canvas.drawLine(Offset(sling.dx - baseW * 0.34, sling.dy), sat, bandPaint);
      canvas.drawLine(Offset(sling.dx + baseW * 0.34, sling.dy), sat, bandPaint);
    }

    // trajectory preview while pulling
    if (_phase == _Phase.dragging && _strength > 0.06) {
      final outcome = game.controller.outcomeFor(_strength);
      final color = switch (outcome) {
        SlingOutcome.locked => SccColors.success,
        SlingOutcome.almost => SccColors.warningAmber,
        SlingOutcome.tooLow => SccColors.alertRed,
        _ => SccColors.warningAmber,
      };
      final to = _arrivalFor(outcome, _strength, 0);
      _dashedBezier(canvas, sat, to, color);
    }

    // flight trail
    if (_trail.length > 1) {
      final trailPaint = Paint()
        ..color = SccColors.cyan.withValues(alpha: 0.55)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3);
      for (var i = 1; i < _trail.length; i++) {
        canvas.drawLine(_trail[i - 1], _trail[i], trailPaint);
      }
    }

    // view cone (arrival/orbiting) — wide-faint for tooFar, narrow for tooLow
    if (_phase == _Phase.orbiting) {
      _renderCone(canvas, sat, earthC);
    }

    // success pulse on lock
    if (_pulseT > 0 && locked) {
      final pulse = game.maybeSprite(SCC.fxGreenSuccessPulse);
      final r = earthR * (0.8 + 0.6 * _pulseT);
      if (pulse != null) {
        canvas.saveLayer(null, Paint()..blendMode = BlendMode.plus);
        pulse.render(canvas,
            position: Vector2(sat.dx - r / 2, sat.dy - r / 2),
            size: Vector2.all(r),
            overridePaint: Paint()
              ..color = Colors.white.withValues(alpha: (1 - _pulseT) * 0.9));
        canvas.restore();
      }
    }

    // the satellite itself (idle sprite everywhere — the "orbiting" render
    // ships a baked-checker motion ring, the fake-transparency gotcha)
    final satSprite = game.maybeSprite(SCC.satWeatherIdle);
    final satW = size.x * 0.16;
    if (satSprite != null) {
      satSprite.render(canvas,
          position: Vector2(sat.dx - satW / 2, sat.dy - satW / 2),
          size: Vector2.all(satW));
    } else {
      drawPlaceholder(canvas, sat, satW / 2, const Color(0xFF8FB7E8));
    }
  }

  void _renderCone(Canvas canvas, Offset sat, Offset earthC) {
    final dir = earthC - sat;
    final dist = dir.distance;
    if (dist < 1) return;
    final n = dir / dist;
    final halfAngle = switch (_outcome) {
      SlingOutcome.tooLow => 0.10,
      SlingOutcome.tooFar => 0.55,
      _ => 0.30,
    };
    final alpha = _outcome == SlingOutcome.tooFar ? 0.10 : 0.20;
    final color = (_outcome == SlingOutcome.locked
            ? SccColors.success
            : SccColors.warningAmber)
        .withValues(alpha: alpha);
    final perp = Offset(-n.dy, n.dx);
    final reach = dist + _earthR * 0.4;
    final a = sat + n * reach + perp * (reach * math.tan(halfAngle));
    final b = sat + n * reach - perp * (reach * math.tan(halfAngle));
    final path = Path()
      ..moveTo(sat.dx, sat.dy)
      ..lineTo(a.dx, a.dy)
      ..lineTo(b.dx, b.dy)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _dashedCircle(Canvas canvas, Offset c, double r, Color color, double width,
      {double? blur}) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    if (blur != null) paint.maskFilter = MaskFilter.blur(BlurStyle.normal, blur);
    const dashes = 44;
    for (var i = 0; i < dashes; i++) {
      final a0 = i * 2 * math.pi / dashes;
      final a1 = a0 + math.pi / dashes * 0.9;
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), a0, a1 - a0, false, paint);
    }
  }

  void _dashedBezier(Canvas canvas, Offset from, Offset to, Color color) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.95)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4;
    const n = 26;
    for (var i = 0; i < n; i += 2) {
      final p0 = _bezier(from, to, i / n);
      final p1 = _bezier(from, to, math.min(1, (i + 1) / n));
      canvas.drawLine(p0, p1, paint);
    }
  }
}

/// Ease helper without dragging Flutter's Curves name into a Flame component.
double _easeInOut(double t) =>
    t < 0.5 ? 2 * t * t : 1 - math.pow(-2 * t + 2, 2) / 2;
