// The auto-capture MOMENT (PRD §3): "the scene briefly freezes, a frame draws
// around it, and the tile slides up and pins under the question." Discovery and
// capture are ONE act — the activity fires this when a felt moment lands; the kid
// never taps to collect. A brief scrim dims the scene, a framed tile pops at centre
// with camera-style corner brackets, then it flies up toward the board strip and
// fades — and the strip (independently) shows the newly-pinned tile.
//
// Self-contained: plays on mount, calls [onDone] when finished. Respects reduced
// motion (a quick fade instead of the fly-up).

import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'evidence_models.dart';
import 'evidence_tile.dart';

class CaptureFlash extends StatefulWidget {
  const CaptureFlash({super.key, required this.tile, required this.onDone, this.imageBytes});

  final EvidenceTile tile;
  final Uint8List? imageBytes; // the real captured scene frame
  final VoidCallback onDone;

  @override
  State<CaptureFlash> createState() => _CaptureFlashState();
}

class _CaptureFlashState extends State<CaptureFlash> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1350));

  bool get _reduced => MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  @override
  void initState() {
    super.initState();
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onDone();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final tileSize = (media.size.width * 0.42).clamp(140.0, 240.0);
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value;
          // Envelope phases: pop-in → hold (freeze+frame) → fly up & fade.
          final scrim = t < 0.15
              ? t / 0.15
              : t < 0.6
                  ? 1.0
                  : (1 - (t - 0.6) / 0.4).clamp(0.0, 1.0);
          final popIn = Curves.easeOutBack.transform((t / 0.18).clamp(0.0, 1.0));
          final fly = ((t - 0.6) / 0.4).clamp(0.0, 1.0);
          final flyCurve = Curves.easeInCubic.transform(fly);

          // Position: centre during the hold, then up toward the board (top).
          final align = Alignment.lerp(
            const Alignment(0, 0.04),
            const Alignment(0, -0.92),
            _reduced ? 0 : flyCurve,
          )!;
          final scale = _reduced
              ? (0.6 + 0.4 * popIn)
              : (1 - 0.62 * flyCurve) * (0.6 + 0.4 * popIn);
          final tileOpacity = _reduced
              ? (t < 0.5 ? 1.0 : (1 - (t - 0.5) / 0.5)).clamp(0.0, 1.0)
              : (t < 0.85 ? 1.0 : (1 - (t - 0.85) / 0.15)).clamp(0.0, 1.0);
          final framing = ((t - 0.12) / 0.2).clamp(0.0, 1.0) * (1 - fly);

          return Stack(
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: scrim * 0.5,
                  child: const ColoredBox(color: Color(0xFF05070F)),
                ),
              ),
              Align(
                alignment: align,
                child: Opacity(
                  opacity: tileOpacity,
                  child: Transform.scale(
                    scale: scale,
                    child: _FramedCapture(
                      tile: widget.tile,
                      imageBytes: widget.imageBytes,
                      size: tileSize,
                      framing: framing,
                    ),
                  ),
                ),
              ),
              if (scrim > 0.2 && t < 0.6)
                Align(
                  alignment: const Alignment(0, 0.42),
                  child: Opacity(
                    opacity: scrim,
                    child: Text(
                      'CAPTURED',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 3,
                        color: widget.tile.accent.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// The tile with animated camera-style corner brackets drawing around it.
class _FramedCapture extends StatelessWidget {
  const _FramedCapture({required this.tile, required this.size, required this.framing, this.imageBytes});
  final EvidenceTile tile;
  final Uint8List? imageBytes;
  final double size;
  final double framing;

  @override
  Widget build(BuildContext context) {
    final pad = size * 0.14;
    return SizedBox(
      width: size + pad * 2,
      height: size + pad * 2 + size * 0.26, // room for the label
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: 0,
            child: CustomPaint(
              size: Size(size + pad * 2, size + pad * 2),
              painter: _CornerBracketsPainter(tile.accent, framing),
            ),
          ),
          Positioned(
            top: pad,
            child: EvidenceTileView(tile: tile, size: size, selected: true, imageBytes: imageBytes),
          ),
        ],
      ),
    );
  }
}

class _CornerBracketsPainter extends CustomPainter {
  _CornerBracketsPainter(this.color, this.t);
  final Color color;
  final double t; // 0..1 draw-in

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0) return;
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.9);
    final len = size.width * 0.18 * t;
    final m = size.width * 0.02;
    final corners = [
      [Offset(m, m), const Offset(1, 0), const Offset(0, 1)],
      [Offset(size.width - m, m), const Offset(-1, 0), const Offset(0, 1)],
      [Offset(m, size.height - m), const Offset(1, 0), const Offset(0, -1)],
      [Offset(size.width - m, size.height - m), const Offset(-1, 0), const Offset(0, -1)],
    ];
    for (final c in corners) {
      final o = c[0], dx = c[1], dy = c[2];
      canvas.drawLine(o, o + Offset(dx.dx * len, dx.dy * len), p);
      canvas.drawLine(o, o + Offset(dy.dx * len, dy.dy * len), p);
    }
  }

  @override
  bool shouldRepaint(_CornerBracketsPainter old) => old.t != t || old.color != color;
}
