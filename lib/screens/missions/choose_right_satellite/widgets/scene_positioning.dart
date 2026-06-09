// Resolution-independent placement: turns a (centerFactor, widthFactor) pair —
// fractions of the scene rect — plus the sprite's intrinsic aspect into a
// concrete Positioned. One helper so every scene layer, effect, and docked
// satellite is placed the same way and tuning is a one-number edit in config.

import 'package:flutter/widgets.dart';

Positioned crsLayer({
  required Size scene,
  required Offset centerFactor,
  required double widthFactor,
  required double aspect,
  required Widget child,
}) {
  final w = scene.width * widthFactor;
  final h = w / aspect;
  return Positioned(
    left: scene.width * centerFactor.dx - w / 2,
    top: scene.height * centerFactor.dy - h / 2,
    width: w,
    height: h,
    child: child,
  );
}
