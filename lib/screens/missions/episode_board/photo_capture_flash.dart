// The auto-capture MOMENT, photo-detective style (PRD §3 — discovery and capture
// are ONE act). A camera SHUTTER flash freezes the scene, the moment "develops" as
// a polaroid at centre, then the photo FLIES up to the corner case node and docks.
// The kid never taps to collect — it just happens, and it feels like snapping a
// photo of what they witnessed.
//
// Self-contained: plays on mount, calls [onDone] when finished. Reduced motion →
// a quick develop + fade (no fly).

import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'case_node.dart' show kCaseNodeAlignment;
import 'evidence_models.dart';
import 'photo_card.dart';

class PhotoCaptureFlash extends StatefulWidget {
  const PhotoCaptureFlash({super.key, required this.tile, required this.onDone, this.imageBytes, this.dockTarget});

  final EvidenceTile tile;
  final Uint8List? imageBytes;

  /// Global screen position of the case node's centre — the photo flies to land
  /// exactly on it. Null → falls back to the top-right [kCaseNodeAlignment].
  final Offset? dockTarget;
  final VoidCallback onDone;

  @override
  State<PhotoCaptureFlash> createState() => _PhotoCaptureFlashState();
}

class _PhotoCaptureFlashState extends State<PhotoCaptureFlash> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1650));

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
    final photo = (media.size.width * 0.46).clamp(150.0, 250.0);
    // Convert the node's global centre into a screen-space Alignment to fly to.
    final dock = widget.dockTarget;
    final dockAlign = dock == null
        ? kCaseNodeAlignment
        : Alignment((dock.dx / media.size.width) * 2 - 1, (dock.dy / media.size.height) * 2 - 1);

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value;

          // 1) Shutter flash — a quick white spike.
          final flash = t < 0.06
              ? t / 0.06
              : t < 0.16
                  ? 1 - (t - 0.06) / 0.10
                  : 0.0;

          // 2) Present + develop the polaroid at centre.
          final present = Curves.easeOutBack.transform((t / 0.16).clamp(0.0, 1.0));
          final develop = ((t - 0.12) / 0.32).clamp(0.0, 1.0);

          // 3) Fly to the corner node + dock.
          final fly = ((t - 0.55) / 0.45).clamp(0.0, 1.0);
          final flyCurve = Curves.easeInCubic.transform(fly);

          final align = _reduced
              ? const Alignment(0, 0.02)
              : Alignment.lerp(const Alignment(0, 0.02), dockAlign, flyCurve)!;
          final scale = _reduced
              ? (0.6 + 0.4 * present)
              : (1 - 0.78 * flyCurve) * (0.6 + 0.4 * present);
          final opacity = _reduced
              ? (t < 0.55 ? 1.0 : (1 - (t - 0.55) / 0.45)).clamp(0.0, 1.0)
              : (t < 0.9 ? 1.0 : (1 - (t - 0.9) / 0.1)).clamp(0.0, 1.0);
          // A slight lean as it flies into the stack.
          final tilt = 0.12 * flyCurve;

          return Stack(
            children: [
              // Scrim — darkens slightly so the photo reads (clears as it flies).
              Positioned.fill(
                child: Opacity(
                  opacity: (t < 0.55 ? 0.5 : 0.5 * (1 - fly)).clamp(0.0, 0.5),
                  child: const ColoredBox(color: Color(0xFF05070F)),
                ),
              ),
              // The shutter flash.
              if (flash > 0)
                Positioned.fill(
                  child: Opacity(opacity: (flash * 0.7).clamp(0.0, 0.7), child: const ColoredBox(color: Colors.white)),
                ),
              // The polaroid.
              Align(
                alignment: align,
                child: Opacity(
                  opacity: opacity,
                  child: Transform.scale(
                    scale: scale,
                    child: PhotoCard(
                      tile: widget.tile,
                      imageBytes: widget.imageBytes,
                      size: photo,
                      kept: false,
                      tilt: tilt,
                      develop: _reduced ? 1 : develop,
                      labelFactor: 0.10, // smaller label for the brief capture snap
                    ),
                  ),
                ),
              ),
              // "SNAP" caption while it develops.
              if (t > 0.14 && t < 0.55)
                Align(
                  alignment: const Alignment(0, 0.5),
                  child: Opacity(
                    opacity: (develop).clamp(0.0, 1.0),
                    child: Text(
                      'SNAPPED',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
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
