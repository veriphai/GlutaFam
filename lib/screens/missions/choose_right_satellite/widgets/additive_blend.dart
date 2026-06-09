// Composites [child] ADDITIVELY (BlendMode.plus) over whatever is painted
// behind it. The clean fix for "glow" cut-out sprites (the Earth hologram, neon
// rings) that carry a faint near-white matte fringe from the glow's own soft
// falloff: over the DARK stage, additive turns that fringe into invisible faint
// light AND makes the sprite read as emissive. (Per the playbook — additive only
// over a dark background; over bright art it would blow out to white.)

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class AdditiveBlend extends SingleChildRenderObjectWidget {
  const AdditiveBlend({super.key, required Widget super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => _AdditiveRenderBox();
}

class _AdditiveRenderBox extends RenderProxyBox {
  @override
  void paint(PaintingContext context, Offset offset) {
    final c = child;
    if (c == null) return;
    context.canvas.saveLayer(offset & size, Paint()..blendMode = BlendMode.plus);
    context.paintChild(c, offset);
    context.canvas.restore();
  }
}
