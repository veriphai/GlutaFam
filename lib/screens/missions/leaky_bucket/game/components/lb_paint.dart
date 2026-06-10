// Shared paint primitives for the Leaky Bucket premium scene — the colour
// palette, a soft additive/blur glow paint, and the slide-scale-fade entrance
// helper. Adapted from trace_it_back's scene kit so the two electricity
// activities feel like one product; kept in-module so leaky_bucket stays
// self-contained.

import 'package:flutter/material.dart';

// Warm light (energy / fire / bulb).
const Color lbWarm = Color(0xFFFFE9B8);
const Color lbWarmHot = Color(0xFFFFF6E0);
const Color lbEnergy = Color(0xFFFFD27A);
const Color lbHeat = Color(0xFFFF7A2E); // escaping heat (felt loss)
const Color lbEmber = Color(0xFFFF8A3C);

// Steel machinery.
const Color lbSteelDark = Color(0xFF3C466B);
const Color lbSteel = Color(0xFF8FA0C8);
const Color lbSteelLite = Color(0xFFC8D4F0);
const Color lbGlassDeep = Color(0xFF0C1230);

// Water / steam / electrical.
const Color lbWater = Color(0xFF49C7F5);
const Color lbSteam = Color(0xFFD8E6F2);
const Color lbSpark = Color(0xFFFFE9A8);

/// A soft blurred glow paint (optionally additive over the dark stage).
Paint lbGlow(Color color, double sigma, {double alpha = 1, bool additive = false}) {
  final p = Paint()
    ..color = color.withValues(alpha: alpha)
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, sigma);
  if (additive) p.blendMode = BlendMode.plus;
  return p;
}

/// Entrance helper: slide + scale + fade a component in as its [rev] goes 0→1
/// (a magnetic "drop into the slot" feel). Only pays for a saveLayer while
/// actually revealing; full draw once settled.
void lbReveal(Canvas canvas, Size stage, double rev, Offset slide, Offset pivot, VoidCallback draw) {
  if (rev >= 0.999) {
    draw();
    return;
  }
  if (rev <= 0.001) return;
  canvas.saveLayer(Offset.zero & stage, Paint()..color = Colors.white.withValues(alpha: rev));
  canvas.translate(slide.dx * (1 - rev), slide.dy * (1 - rev));
  final s = 0.82 + 0.18 * rev;
  canvas.translate(pivot.dx, pivot.dy);
  canvas.scale(s);
  canvas.translate(-pivot.dx, -pivot.dy);
  draw();
  canvas.restore();
}
