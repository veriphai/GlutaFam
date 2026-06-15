// Ember — art/craft_kit.dart
//
// The shared RENDER-CRAFT KIT: a closed set of pure, static Canvas helpers that
// implement the module's quality-bar rendering primitives in ONE place so every
// craft prop (Fire / Tools / Shelter), the player avatar, and the world
// components paint hot/solid objects the SAME way.
//
// These are NOT components and own NO state — they are stateless drawing verbs a
// caller invokes from inside its own `render(Canvas)` (the caller owns the value
// it animates in tick()/update() with the dt-correct ease; the kit just paints
// the current frame). That keeps them dt-/resolution-independent: nothing here
// reads a clock, holds a phase, or allocates per-frame state. Pass in the live
// 0..1 levels you already eased and the kit draws them.
//
// QUALITY BAR these encode (see module brief):
//   * Hot/solid objects are VOLUMETRIC + lit: stacked stroke cylinders
//     (contact shadow -> 3-stop cross-axis gradient body -> specular spine),
//     BlendMode.plus bloom scaled by intensity, MaskFilter.blur halos,
//     deterministic ember/heat speckle that dies as the value drops.
//   * ONE fixed UPPER-LEFT key light ([EmberMetrics.lightDir]) — every helper
//     lights to the same source so silhouettes agree across the scene.
//   * A blurred ground-contact ellipse so nothing floats.
//
// disableAnimations-aware: helpers that have a *temporal* component (the speckle
// field's drift + twinkle) accept a [reduceMotion] flag. When true they fall
// back to a still, calm field — a same-frame causal value (the level) is NEVER
// softened, only the ambient motion is stilled. Callers pass
// MediaQuery.maybeOf(context)?.disableAnimations ?? false (resolved once, not
// per frame).
//
// Presentation-only (art/): flame metrics + flutter painting; NO clock, NO
// randomness that feeds state. The speckle field is a DETERMINISTIC hash of
// (seed, index) so the same inputs always draw the same motes (no math.Random).

import 'dart:math' as math;

import 'package:flutter/painting.dart';

import 'ember_palette.dart';

/// The shared render-craft kit — a namespace of pure static drawing verbs.
///
/// Call these from inside a component's `render(Canvas)`. Coordinates are in the
/// caller's local space; each helper documents its anchor convention.
abstract final class CraftKit {
  // ===========================================================================
  // Lighting — the ONE shared key light. Everything tilts highlights/shadows to
  // this so the whole scene agrees on where the sun is.
  // ===========================================================================

  /// The global key-light direction (points FROM the light TOWARD the surface),
  /// re-exported from [EmberMetrics.lightDir] so craft helpers and callers share
  /// one constant. Upper-left.
  static const Offset lightDir = EmberMetrics.lightDir;

  /// The unit vector pointing back AT the light (where highlights gather).
  /// Upper-left, normalized.
  static const Offset towardLight = Offset(0.55, 0.83);

  // ===========================================================================
  // litCylinder — a volumetric, upper-left-lit cylinder (the workhorse for any
  // hot/solid round prop: drill spindle, torch pole, bone, limb, log...).
  // ===========================================================================

  /// Draws a lit vertical cylinder of width [w] and height [h] standing on the
  /// origin's baseline.
  ///
  /// Anchor convention: the cylinder stands UP from [base] (its bottom-centre);
  /// the body extends to `base - Offset(0, h)`. This matches the module's
  /// bottom-centre-anchored, draw-upward (-y) convention.
  ///
  /// Layers, bottom to top:
  ///   1. a soft blurred ground-contact ellipse under the foot (unless
  ///      [contactShadow] is false),
  ///   2. a 3-stop CROSS-AXIS gradient body (shaded edge -> lit body -> rim) tilted
  ///      to the key light, capped with an elliptical top so it reads as a tube,
  ///   3. a hairline [outline],
  ///   4. a soft SPECULAR spine — a blurred bright streak on the lit (upper-left)
  ///      flank — its strength scaled by [specular] (0..1).
  ///
  /// [body] is the mid tone; [shade]/[rim] default to darkened/lightened [body].
  /// [glow] (0..1), if > 0, lerps the whole body toward [glowColor] and adds a
  /// faint additive bloom up the lit flank (for a heating shaft).
  static void litCylinder(
    Canvas canvas, {
    required Offset base,
    required double w,
    required double h,
    required Color body,
    Color? shade,
    Color? rim,
    Color outline = const Color(0xFF3A2A1A),
    double specular = 0.6,
    double radiusFactor = 0.42,
    bool contactShadow = true,
    double glow = 0.0,
    Color glowColor = const Color(0xFFFFD15C),
    double opacity = 1.0,
  }) {
    if (h <= 0 || w <= 0 || opacity <= 0.0) return;
    final double g = glow.clamp(0.0, 1.0);
    final double a = opacity.clamp(0.0, 1.0);
    final Color bodyC = Color.lerp(body, glowColor, g * 0.6)!;
    final Color shadeC = shade ?? _darken(body, 0.34);
    final Color rimC = rim ?? _lighten(body, 0.30);
    final double capH = w * radiusFactor; // elliptical cap half-height-ish

    if (contactShadow) {
      groundContactEllipse(canvas, center: base, width: w * 1.15, strength: a);
    }

    final Rect bodyRect = Rect.fromLTWH(base.dx - w / 2, base.dy - h, w, h);

    // 3-stop cross-axis gradient: shaded far edge (right) -> lit body -> bright
    // rim on the lit (upper-left) flank. Begin/end run ACROSS the cylinder.
    final Paint bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: const Alignment(0.9, -0.2), // shaded (away from light)
        end: const Alignment(-0.9, 0.2), // lit flank (toward upper-left)
        colors: <Color>[
          shadeC.withValues(alpha: a),
          bodyC.withValues(alpha: a),
          rimC.withValues(alpha: a),
        ],
        stops: const <double>[0.0, 0.55, 1.0],
      ).createShader(bodyRect);

    // The tube: a rounded shaft with an elliptical TOP cap (so it reads round).
    final Path tube = Path()
      ..moveTo(bodyRect.left, bodyRect.bottom)
      ..lineTo(bodyRect.left, bodyRect.top + capH)
      ..arcToPoint(
        Offset(bodyRect.right, bodyRect.top + capH),
        radius: Radius.elliptical(w / 2, capH),
        clockwise: true,
      )
      ..lineTo(bodyRect.right, bodyRect.bottom)
      ..arcToPoint(
        Offset(bodyRect.left, bodyRect.bottom),
        radius: Radius.elliptical(w / 2, capH * 0.7),
        clockwise: true,
      )
      ..close();
    canvas.drawPath(tube, bodyPaint);

    // The lit top cap, a touch brighter than the rim.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(base.dx, bodyRect.top + capH),
        width: w,
        height: capH * 2,
      ),
      Paint()..color = _lighten(bodyC, 0.16).withValues(alpha: a),
    );

    // Hairline outline.
    canvas.drawPath(
      tube,
      Paint()
        ..color = outline.withValues(alpha: 0.85 * a)
        ..style = PaintingStyle.stroke
        ..strokeWidth = EmberMetrics.strokeWidth,
    );

    // Specular spine: a soft bright vertical streak on the lit (upper-left) flank.
    final double spec = specular.clamp(0.0, 1.0);
    if (spec > 0.01) {
      final double sx = base.dx - w * 0.22; // toward the lit flank
      final Rect spine = Rect.fromCenter(
        center: Offset(sx, base.dy - h / 2),
        width: w * 0.16,
        height: h * 0.84,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(spine, Radius.circular(spine.width)),
        Paint()
          ..color = _lighten(bodyC, 0.5).withValues(alpha: 0.55 * spec * a)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.4),
      );
    }

    // Heating bloom up the lit flank when glowing.
    if (g > 0.02) {
      final double br = w * (0.7 + 0.5 * g);
      canvas.drawCircle(
        Offset(base.dx, base.dy - h * 0.5),
        br,
        Paint()
          ..blendMode = BlendMode.plus
          ..shader = RadialGradient(
            colors: <Color>[
              glowColor.withValues(alpha: 0.4 * g * a),
              glowColor.withValues(alpha: 0.0),
            ],
          ).createShader(
            Rect.fromCircle(center: Offset(base.dx, base.dy - h * 0.5), radius: br),
          ),
      );
    }
  }

  // ===========================================================================
  // bloomStack — additive heat/light bloom (outer soft + mid + white-hot core).
  // The shared way to make anything "give off light", scaled by intensity 0..1.
  // ===========================================================================

  /// Stamps a three-layer additive bloom centred at [center], radius [radius] at
  /// full [intensity] (0..1). Layers use [BlendMode.plus] so overlapping blooms
  /// add up like real light. [warm]/[hot] default to ember/spark from a palette
  /// caller; pass your palette colours so day/night themes stay consistent.
  ///
  /// At [intensity] 0 nothing is drawn (a dead fire emits no light). The white-hot
  /// core only appears once [intensity] passes [coreThreshold] (a faint glow has
  /// no white centre).
  static void bloomStack(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required double intensity,
    Color warm = const Color(0xFFF2873B),
    Color hot = const Color(0xFFFFE9A8),
    double coreThreshold = 0.45,
    double opacity = 1.0,
  }) {
    final double k = intensity.clamp(0.0, 1.0);
    final double a = opacity.clamp(0.0, 1.0);
    if (k <= 0.005 || radius <= 0 || a <= 0.0) return;

    // Outer soft halo.
    final double rOuter = radius * (0.7 + 0.6 * k);
    canvas.drawCircle(
      center,
      rOuter,
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = RadialGradient(
          colors: <Color>[
            warm.withValues(alpha: 0.28 * k * a),
            warm.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: rOuter)),
    );

    // Mid bloom (brighter, tighter).
    final double rMid = radius * (0.36 + 0.3 * k);
    canvas.drawCircle(
      center,
      rMid,
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = RadialGradient(
          colors: <Color>[
            Color.lerp(warm, hot, 0.5)!.withValues(alpha: 0.42 * k * a),
            warm.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: rMid)),
    );

    // White-hot core (only once hot enough).
    if (k > coreThreshold) {
      final double cc = ((k - coreThreshold) / (1.0 - coreThreshold)).clamp(0.0, 1.0);
      final double rCore = radius * (0.1 + 0.16 * cc);
      canvas.drawCircle(
        center,
        rCore,
        Paint()
          ..blendMode = BlendMode.plus
          ..color = hot.withValues(alpha: (0.55 * cc * a).clamp(0.0, 1.0)),
      );
    }
  }

  // ===========================================================================
  // woundLashing — a bound cord wrap (back-arc behind the prop + front-arc over
  // it). The shared way to lash a stone head to a haft, a hide to a frame, etc.
  // ===========================================================================

  /// Draws [turns] turns of lashing cord wrapping a shaft of width [w] centred on
  /// the vertical line through [center], spanning [height] px. Each turn is two
  /// arcs: a dim BACK arc (behind the shaft, drawn first/darker) and a lit FRONT
  /// arc (over the shaft), so the cord reads as truly wrapped, not painted on.
  ///
  /// Call this AFTER drawing the shaft body but the back arcs will be partly
  /// hidden behind nothing here (the kit can't know your shaft) — so for a fully
  /// "behind" look, draw [woundLashing] with [frontOnly] true OVER the shaft, or
  /// call it twice (once before the shaft body for the back arcs via [backOnly],
  /// once after for the front). The default draws both in one pass for the common
  /// case where the shaft is opaque enough that the back arcs read as shadow.
  static void woundLashing(
    Canvas canvas, {
    required Offset center,
    required double w,
    required double height,
    int turns = 3,
    Color cord = const Color(0xFF9C734A),
    Color? cordDark,
    double strokeWidth = 3.0,
    bool backOnly = false,
    bool frontOnly = false,
    double opacity = 1.0,
  }) {
    final double a = opacity.clamp(0.0, 1.0);
    if (turns <= 0 || w <= 0 || height <= 0 || a <= 0.0) return;
    final Color darkC = cordDark ?? _darken(cord, 0.4);
    final double gap = height / turns;
    final double bow = w * 0.55; // how far the arc bulges
    final double halfW = w / 2;

    for (int i = 0; i < turns; i++) {
      final double y = center.dy - height / 2 + gap * (i + 0.5);

      // BACK arc: behind the shaft — sits a touch higher, darker, thinner.
      if (!frontOnly) {
        final Path back = Path()
          ..moveTo(center.dx - halfW, y - gap * 0.12)
          ..quadraticBezierTo(
            center.dx, y - gap * 0.12 - bow * 0.5,
            center.dx + halfW, y - gap * 0.12,
          );
        canvas.drawPath(
          back,
          Paint()
            ..color = darkC.withValues(alpha: 0.8 * a)
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth * 0.85
            ..strokeCap = StrokeCap.round,
        );
      }

      // FRONT arc: over the shaft — lower, lit, full width + a tiny highlight.
      if (!backOnly) {
        final Path front = Path()
          ..moveTo(center.dx - halfW, y)
          ..quadraticBezierTo(
            center.dx, y + bow,
            center.dx + halfW, y,
          );
        canvas.drawPath(
          front,
          Paint()
            ..color = cord.withValues(alpha: a)
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth
            ..strokeCap = StrokeCap.round,
        );
        // A thin lit edge on the upper-left of the cord (key light).
        canvas.drawPath(
          front,
          Paint()
            ..color = _lighten(cord, 0.35).withValues(alpha: 0.5 * a)
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth * 0.35
            ..strokeCap = StrokeCap.round,
        );
      }
    }
  }

  // ===========================================================================
  // groundContactEllipse — the blurred shadow so nothing floats.
  // ===========================================================================

  /// Draws a soft, blurred contact-shadow ellipse centred at [center] (the prop's
  /// foot). [width] is the full width; height defaults to an iso-flattened
  /// fraction of it. [strength] (0..1) scales opacity (a fading/ghost prop casts a
  /// fainter shadow). [shadow] defaults to the palette shadow tint.
  static void groundContactEllipse(
    Canvas canvas, {
    required Offset center,
    required double width,
    double? height,
    double strength = 1.0,
    Color shadow = const Color(0x33241608),
    double blur = 4.0,
  }) {
    final double s = strength.clamp(0.0, 1.0);
    if (width <= 0 || s <= 0.0) return;
    final double hgt = height ?? width * 0.34;
    canvas.drawOval(
      Rect.fromCenter(center: center, width: width, height: hgt),
      Paint()
        ..color = shadow.withValues(
          alpha: (shadow.a * (0.6 + 0.4 * s)).clamp(0.0, 1.0),
        )
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur),
    );
  }

  // ===========================================================================
  // emberSpeckle — a DETERMINISTIC seeded field of hot motes whose density scales
  // with a value and DIES as it drops. The shared "this thing is hot" texture.
  // ===========================================================================

  /// Stamps a deterministic field of hot specks rising within an [area] (local
  /// rect), with mote count + brightness scaled by [value] (0..1). The field is a
  /// pure hash of ([seed], moteIndex) so the same inputs draw the same motes — no
  /// math.Random, no per-frame allocation, and it is reproducible across frames.
  ///
  /// [time] (seconds; pass your component's accumulated dt clock) drives a gentle
  /// upward drift + twinkle. When [reduceMotion] is true the motes hold still and
  /// twinkle is frozen (calm ambience) — but their DENSITY still tracks [value]
  /// (the causal "how hot" read is never softened, only the wandering motion).
  ///
  /// As [value] falls, motes drop out from the top of the index range first and
  /// the survivors dim, so the field visibly THINS and dies rather than just
  /// fading uniformly.
  static void emberSpeckle(
    Canvas canvas, {
    required Rect area,
    required double value,
    required double time,
    int maxCount = 14,
    Color warm = const Color(0xFFF2873B),
    Color hot = const Color(0xFFFFD15C),
    int seed = 1,
    bool reduceMotion = false,
    double opacity = 1.0,
  }) {
    final double v = value.clamp(0.0, 1.0);
    final double a = opacity.clamp(0.0, 1.0);
    if (v <= 0.01 || area.width <= 0 || area.height <= 0 || a <= 0.0) return;

    // Density: live motes scale with value. Survivors are the LOW indices, so the
    // field thins from the top down as it cools.
    final int live = (maxCount * v).ceil().clamp(0, maxCount);

    for (int i = 0; i < live; i++) {
      // Deterministic per-mote params from a hash of (seed, i).
      final double rx = _hash01(seed, i, 11); // x fraction
      final double rPhase = _hash01(seed, i, 23); // rise phase offset
      final double rSpeed = 0.5 + _hash01(seed, i, 41) * 0.9; // rise speed
      final double rSize = 0.7 + _hash01(seed, i, 67) * 1.1; // base radius

      // Rise progress 0..1 (loops). Frozen position when reduceMotion.
      final double p = reduceMotion
          ? rPhase
          : ((time * rSpeed + rPhase) % 1.0);

      final double x = area.left + rx * area.width;
      final double y = area.bottom - p * area.height;

      // Twinkle (frozen when reduceMotion -> steady).
      final double twinkle = reduceMotion
          ? 0.85
          : 0.6 + 0.4 * math.sin((time * 6.0 + i * 1.7));

      // This mote's own fade as it rises + the field-wide value gate. Motes near
      // the live/dead boundary dim first (so the field dies smoothly).
      final double edgeFade =
          (1.0 - (i / maxCount - v).clamp(0.0, 1.0) * 3.0).clamp(0.0, 1.0);
      final double fade = (1.0 - p) * v * edgeFade * twinkle;
      if (fade <= 0.03) continue;

      final Color c = i.isEven ? hot : warm;
      canvas.drawCircle(
        Offset(x, y),
        rSize * (0.6 + 0.6 * fade),
        Paint()
          ..blendMode = BlendMode.plus
          ..color = c.withValues(alpha: (0.7 * fade * a).clamp(0.0, 1.0)),
      );
    }
  }

  // ===========================================================================
  // Internal helpers.
  // ===========================================================================

  /// Deterministic [0,1) value from three small ints (a cheap integer hash).
  /// No dart:math Random — same args -> same output, so fields are reproducible.
  static double _hash01(int seed, int index, int salt) {
    int h = 0x811c9dc5; // FNV-ish offset basis (32-bit-ish)
    h = (h ^ (seed & 0xffff)) * 0x01000193 & 0x7fffffff;
    h = (h ^ (index & 0xffff)) * 0x01000193 & 0x7fffffff;
    h = (h ^ (salt & 0xffff)) * 0x01000193 & 0x7fffffff;
    return (h % 100000) / 100000.0;
  }

  static Color _darken(Color c, double t) =>
      Color.lerp(c, const Color(0xFF000000), t.clamp(0.0, 1.0))!;

  static Color _lighten(Color c, double t) =>
      Color.lerp(c, const Color(0xFFFFFFFF), t.clamp(0.0, 1.0))!;
}
