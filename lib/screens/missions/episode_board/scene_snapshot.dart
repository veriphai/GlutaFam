// Capture a live activity SCENE to a PNG thumbnail (PRD §8: the captured artifact
// is a thumbnail/short replayable representation of THE ACTUAL SCENE — reuse the
// already-built Act 2 & Act 3 scenes, render a still). Each capture-bearing
// activity wraps its scene layer in a RepaintBoundary(key); at the discovery beat
// we snapshot that boundary, crop out the chrome, and persist the frame the kid
// actually saw — so the evidence tile IS the real moment, not a drawn stand-in.

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Snapshot the RepaintBoundary behind [key] to PNG bytes, optionally cropping to
/// a normalized sub-rect [cropFactor] (LTRB each 0..1 of the boundary) so we keep
/// only the meaningful region (the scene + its relevant meters) and drop the board
/// strip / back button / dock chrome. Returns null if the boundary isn't ready —
/// the tile then falls back to its drawn motif.
Future<Uint8List?> captureScenePng(
  GlobalKey key, {
  Rect? cropFactor,
  double pixelRatio = 1.6,
}) async {
  final ctx = key.currentContext;
  if (ctx == null) return null;
  final ro = ctx.findRenderObject();
  if (ro is! RenderRepaintBoundary) return null;
  try {
    ui.Image image = await ro.toImage(pixelRatio: pixelRatio);
    if (cropFactor != null) {
      final w = image.width.toDouble(), h = image.height.toDouble();
      final src = Rect.fromLTRB(
        cropFactor.left * w,
        cropFactor.top * h,
        cropFactor.right * w,
        cropFactor.bottom * h,
      );
      final dst = Rect.fromLTWH(0, 0, src.width, src.height);
      final recorder = ui.PictureRecorder();
      Canvas(recorder).drawImageRect(image, src, dst, Paint());
      final cropped =
          await recorder.endRecording().toImage(src.width.round(), src.height.round());
      image.dispose();
      image = cropped;
    }
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return bytes?.buffer.asUint8List();
  } catch (_) {
    return null; // toImage can throw on some platforms/timing — degrade to motif
  }
}
