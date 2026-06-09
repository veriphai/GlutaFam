// Renders a crisp Flutter Material icon inside the Flame canvas as a one-shot
// effect (pop-in with a soft glow, optional fade-out). Used to replace the
// poor-quality generated effect sprites with clean icons.
//
// Icons render via a TextPainter using the icon's font glyph — this works
// because `uses-material-design: true` bundles the MaterialIcons font.

import 'package:flame/components.dart';
import 'package:flutter/widgets.dart';

class IconFx extends PositionComponent {
  IconFx({
    required this.icon,
    required this.color,
    required double glyphSize,
    required Vector2 position,
    Color? glowColor,
    this.startDelay = 0,
    this.lifetime = 0.9,
    this.persist = false,
    this.scaleFrom = 0.4,
    this.scaleTo = 1.15,
  })  : glowColor = glowColor ?? color,
        super(position: position, anchor: Anchor.center, size: Vector2.all(glyphSize));

  final IconData icon;
  final Color color;
  final Color glowColor;
  final double startDelay;
  final double lifetime;
  final bool persist;
  final double scaleFrom;
  final double scaleTo;

  double _t = 0;
  double _alpha = 0;
  double _scale = 0.4;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    final t = _t - startDelay;
    if (t < 0) {
      _alpha = 0;
      return;
    }
    if (t < 0.22) {
      // Pop in with overshoot + fade in.
      final k = (t / 0.22).clamp(0.0, 1.0);
      _scale = scaleFrom + (scaleTo - scaleFrom) * Curves.easeOutBack.transform(k);
      _alpha = k;
    } else {
      // Settle scale to 1.0.
      _scale = scaleTo + (1.0 - scaleTo) * ((t - 0.22) / 0.18).clamp(0.0, 1.0);
      _alpha = 1;
    }
    if (!persist) {
      const fade = 0.3;
      final fadeStart = lifetime - fade;
      if (t > fadeStart) _alpha = (1 - (t - fadeStart) / fade).clamp(0.0, 1.0);
      if (t >= lifetime) removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    if (_alpha <= 0.01) return;
    final cx = size.x / 2, cy = size.y / 2;
    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(_scale);
    canvas.translate(-cx, -cy);

    // Soft glow behind the glyph (can be a different colour than the glyph).
    canvas.drawCircle(
      Offset(cx, cy),
      size.x * 0.42,
      Paint()
        ..color = glowColor.withValues(alpha: _alpha * 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );

    final painter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          fontSize: size.x,
          color: color.withValues(alpha: _alpha),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, Offset((size.x - painter.width) / 2, (size.y - painter.height) / 2));
    canvas.restore();
  }
}
