// Stage 5 — "Send Data to Earth" (PRD §16), premium pass. Full-bleed scene:
// satellite top-left (clean idle sprite, leaning with the aim), ground
// station anchored INTO the bottom-right corner so the Earth curve exits the
// screen edges, with a soft atmosphere rim glow. The antenna beam is the
// hero: multi-pass bloom + white-hot core, colour lerping amber → cyan →
// green with signal quality, energy pulses travelling down it, a soft
// gradient falloff when it's missing, and an impact bloom + lock ring at the
// dish. Packets fly with motion trails and burst on arrival
// (deliveredCount is a ValueNotifier the Flutter console reads).

import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:flutter/material.dart' show Colors;

import '../config/scc_assets.dart';
import '../config/scc_stage_configs.dart';
import '../config/scc_theme.dart';
import '../state/mission_state.dart';
import 'save_city_game.dart';

class SignalStage extends PositionComponent {
  SignalStage({required this.game});

  final SaveCityGame game;

  /// Packets that have reached the dish this transmission — mirrored onto
  /// [SaveCityGame.signalDelivered] so the Flutter console chip can listen.
  ValueNotifier<int> get delivered => game.signalDelivered;
  static const packetCount = 5;

  // ── factor anchors (live-tuning pass expected) ────────────────────────────
  static const _satF = Offset(0.22, 0.15);
  static const _sceneWF = 0.95; // ground-station scene width (of stage width)
  /// The dish's glowing receiver TIP on the scaled-up corner composition —
  /// measured from a device screenshot (the old anchor predated the bigger
  /// scene rect and floated up-left of the actual dish).
  static const _dishOnSceneF = Offset(0.56, 0.09);

  int _lastPacketToken = 0;
  final List<double> _packets = [];
  final List<bool> _packetDone = [];
  double _dishGlow = 0;
  double _impact = 0; // expanding impact ring phase 0..1 (loops while locked)
  double _time = 0;

  Offset get _satP => Offset(size.x * _satF.dx, size.y * _satF.dy);

  Rect get _sceneRect {
    final w = size.x * _sceneWF;
    // anchored into the bottom-right corner: curve exits right + bottom edges
    return Rect.fromLTWH(size.x - w * 0.82, size.y * 0.40, w, w);
  }

  Offset get _dishP {
    final r = _sceneRect;
    return Offset(
        r.left + r.width * _dishOnSceneF.dx, r.top + r.height * _dishOnSceneF.dy);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
  }

  // ── input: vertical drag rotates the antenna aim ──────────────────────────
  void onStageDragStart(Vector2 p) {}

  void onStageDragUpdate(Vector2 p, Vector2 delta) {
    final s = game.controller.state.signal;
    if (s.phase != SignalPhase.tuning) return;
    game.controller.setAntennaAim(s.aimDeg + delta.y * 0.25);
  }

  void onStageDragEnd() {}

  // ── per-frame ──────────────────────────────────────────────────────────────
  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    final s = game.controller.state.signal;

    if (s.packetToken != _lastPacketToken) {
      _lastPacketToken = s.packetToken;
      delivered.value = 0;
      _packets
        ..clear()
        ..addAll(List.generate(packetCount, (i) => -i * 0.18));
      _packetDone
        ..clear()
        ..addAll(List.filled(packetCount, false));
    }
    if (_packets.isNotEmpty) {
      var allDone = true;
      for (var i = 0; i < _packets.length; i++) {
        _packets[i] += dt * 0.55;
        if (_packets[i] >= 1 && !_packetDone[i]) {
          _packetDone[i] = true;
          delivered.value += 1; // arrival burst keys off this too
        }
        if (_packets[i] < 1.12) allDone = false; // small linger for the burst
      }
      if (allDone) {
        _packets.clear();
        _packetDone.clear();
        game.controller.packetsDelivered();
      }
    }

    final locked = s.phase != SignalPhase.tuning;
    final wantGlow = locked || s.holdProgress > 0.4;
    _dishGlow = (_dishGlow + (wantGlow ? dt * 2 : -dt * 2)).clamp(0.0, 1.0);
    if (locked || s.holdProgress > 0) {
      _impact = (_impact + dt * 0.9) % 1;
    }
  }

  /// 0..1 signal quality — drives every colour on this stage (beam, glow,
  /// and the Flutter oscilloscope mirrors the same formula).
  double get quality {
    final s = game.controller.state.signal;
    if (s.phase != SignalPhase.tuning) return 1;
    final aimGood = s.aimDeg.abs() <= SignalTuning.aimToleranceDeg;
    final freqGood =
        (s.freq - SignalTuning.freqTarget).abs() <= SignalTuning.freqTolerance;
    if (aimGood && freqGood) return 1;
    if (aimGood) return 0.55;
    return 0.18;
  }

  Color get _qualityColor {
    final q = quality;
    return q < 0.5
        ? Color.lerp(SccColors.warningAmber, SccColors.cyan, q * 2)!
        : Color.lerp(SccColors.cyan, SccColors.success, (q - 0.5) * 2)!;
  }

  // ── painting ───────────────────────────────────────────────────────────────
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final s = game.controller.state.signal;
    final sat = _satP;
    final dish = _dishP;
    final r = _sceneRect;

    // atmosphere rim glow behind the planet curve
    canvas.saveLayer(null, Paint()..blendMode = BlendMode.plus);
    canvas.drawCircle(
      Offset(r.center.dx, r.top + r.height * 0.60),
      r.width * 0.42,
      Paint()
        ..color = SccColors.cyan.withValues(alpha: 0.10)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 26
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30),
    );
    canvas.restore();

    // ground-station scene
    final scene = game.maybeSprite(SCC.groundStationScene);
    if (scene != null) {
      scene.render(canvas,
          position: Vector2(r.left, r.top), size: Vector2(r.width, r.height));
    } else {
      drawPlaceholder(canvas, r.center, r.width * 0.4, const Color(0xFF14406B));
    }

    // (no dish halo — the beam impact + lock ring carry the feedback)

    // the beam (under the satellite so it reads as emitted from the antenna)
    _renderBeam(canvas, sat, dish, s);

    // packets with motion trails + arrival bursts
    if (_packets.isNotEmpty) _renderPackets(canvas, sat, dish);

    // hold-steady lock ring at the dish
    if (s.phase == SignalPhase.tuning && s.holdProgress > 0.02) {
      final ringR = r.width * 0.13;
      canvas.saveLayer(null, Paint()..blendMode = BlendMode.plus);
      canvas.drawCircle(
          dish,
          ringR,
          Paint()
            ..color = SccColors.success.withValues(alpha: 0.18)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 9
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
      canvas.drawArc(
          Rect.fromCircle(center: dish, radius: ringR),
          -math.pi / 2,
          2 * math.pi * s.holdProgress,
          false,
          Paint()
            ..color = SccColors.success
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4.5
            ..strokeCap = StrokeCap.round);
      canvas.restore();
    }

    // impact ring while locked/sending
    if (_dishGlow > 0.5 && s.phase != SignalPhase.tuning) {
      canvas.drawCircle(
        dish,
        12 + 40 * _impact,
        Paint()
          ..color = _qualityColor.withValues(alpha: (1 - _impact) * 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }

    // the satellite — clean idle sprite, leaning with the aim
    final satSprite = game.maybeSprite(SCC.satWeatherIdle);
    final satW = size.x * 0.30;
    final lean = s.aimDeg * 0.6 * math.pi / 180;
    canvas.save();
    canvas.translate(sat.dx, sat.dy);
    canvas.rotate(lean);
    if (satSprite != null) {
      satSprite.render(canvas,
          position: Vector2(-satW / 2, -satW / 2), size: Vector2.all(satW));
    } else {
      drawPlaceholder(canvas, Offset.zero, satW / 2, const Color(0xFF8FB7E8));
    }
    canvas.restore();
  }

  void _renderBeam(Canvas canvas, Offset sat, Offset dish, SignalSub s) {
    final base = dish - sat;
    final baseAng = math.atan2(base.dy, base.dx);
    final ang = baseAng + s.aimDeg * math.pi / 180;
    final aimGood = s.aimDeg.abs() <= SignalTuning.aimToleranceDeg;
    final lockedOrLater = s.phase != SignalPhase.tuning;
    final q = quality;
    final color = _qualityColor;

    final dir = Offset(math.cos(ang), math.sin(ang));
    // emit from the antenna side of the satellite, not its centre
    final from = sat + dir * (size.x * 0.30 * 0.34);
    final len = base.distance * (lockedOrLater || aimGood ? 1.0 : 1.25);
    final end = sat + dir * len;

    canvas.saveLayer(null, Paint()..blendMode = BlendMode.plus);

    void pass(double width, double alpha, double blur, {bool fade = false}) {
      final p = Paint()
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round;
      if (blur > 0) p.maskFilter = MaskFilter.blur(BlurStyle.normal, blur);
      if (fade) {
        // soft falloff toward the far end when the beam is missing
        p.shader = ui.Gradient.linear(from, end, [
          color.withValues(alpha: alpha),
          color.withValues(alpha: alpha * 0.05),
        ]);
      } else {
        p.color = color.withValues(alpha: alpha);
      }
      canvas.drawLine(from, end, p);
    }

    final missing = !aimGood && !lockedOrLater;
    final flicker = !lockedOrLater && aimGood && q < 1
        ? 0.55 + 0.45 * math.sin(_time * 19)
        : 1.0;
    pass(26, 0.10 + 0.10 * q, 16, fade: missing);
    pass(11, 0.16 + 0.22 * q, 6, fade: missing);
    pass(4, (0.35 + 0.50 * q) * flicker, 1.5, fade: missing);
    if (q >= 1) {
      // white-hot core
      canvas.drawLine(
          from,
          end,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.85)
            ..strokeWidth = 1.6
            ..strokeCap = StrokeCap.round);
    }

    // energy pulses travelling down the beam
    final pulses = q >= 1 ? 3 : (aimGood ? 2 : 1);
    for (var i = 0; i < pulses; i++) {
      final f = ((_time * 0.45) + i / pulses) % 1;
      final c = Offset.lerp(from, end, f)!;
      canvas.drawCircle(
        c,
        4.5,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.65 * q + 0.1)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }
    canvas.restore();
  }

  void _renderPackets(Canvas canvas, Offset sat, Offset dish) {
    final orb = game.maybeSprite(SCC.fxBlueEnergyOrb);
    final burst = game.maybeSprite(SCC.fxBlueEnergyBurst);
    canvas.saveLayer(null, Paint()..blendMode = BlendMode.plus);
    for (var i = 0; i < _packets.length; i++) {
      final p = _packets[i];
      // arrival burst at the dish
      if (p >= 1 && p < 1.12 && burst != null) {
        final bt = (p - 1) / 0.12;
        final bw = size.x * 0.16 * (0.6 + 0.4 * bt);
        burst.render(canvas,
            position: Vector2(dish.dx - bw / 2, dish.dy - bw / 2),
            size: Vector2.all(bw),
            overridePaint: Paint()
              ..color = Colors.white.withValues(alpha: (1 - bt) * 0.85));
        continue;
      }
      if (p < 0 || p > 1) continue;
      // motion trail: two fading copies behind the packet
      for (var k = 2; k >= 0; k--) {
        final f = (p - k * 0.045).clamp(0.0, 1.0);
        final pos = Offset.lerp(sat, dish, f)!;
        final ow = size.x * 0.065 * (1 - k * 0.22);
        final alpha = k == 0 ? 1.0 : (0.35 - k * 0.12);
        if (orb != null) {
          orb.render(canvas,
              position: Vector2(pos.dx - ow / 2, pos.dy - ow / 2),
              size: Vector2.all(ow),
              overridePaint: Paint()
                ..color = Colors.white.withValues(alpha: alpha));
        } else {
          canvas.drawCircle(
              pos, ow * 0.3, Paint()..color = SccColors.cyan.withValues(alpha: alpha));
        }
      }
    }
    canvas.restore();
  }
}
