// Ember — art/sprite_cache.dart
//
// A tiny, synchronous-after-preload image cache for the flat sprite pack. It
// decodes each PNG (via the asset bundle) into a [ui.Image] keyed by BARE
// filename, so the render-path lookup is a cheap map read with no per-frame
// allocation. SpriteEmberArt owns one of these; the game preloads the mapped set
// at boot so the first paint is never blank.
//
// Why ui.Image (not Flame Sprite): the world components paint to a raw Canvas
// (diamond faces, bottom-center cutouts) rather than mounting SpriteComponents,
// so a decoded ui.Image + canvas.drawImageRect is the smallest seam that drops
// straight into the existing render() methods. A Flame Image with the right asset
// prefix would work too, but this keeps zero coupling to Flame's global cache.
//
// Presentation-only (art/): no clock/randomness. Decode is async (preload); the
// per-frame [image] getter is pure + sync.

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart' show rootBundle;

import 'sprite_slots.dart';

/// Decodes + caches sprite PNGs by bare filename.
class SpriteCache {
  SpriteCache();

  final Map<String, ui.Image> _images = <String, ui.Image>{};

  /// True once at least one image has been decoded (so the art facade can choose
  /// to start serving sprites — though [image] is null-safe before then too).
  bool get isLoaded => _images.isNotEmpty;

  /// The decoded image for [file] (bare filename), or null if not loaded yet /
  /// failed to decode. Callers MUST fall back to programmatic art when null.
  ui.Image? image(String file) => _images[file];

  /// Preload every file in [files] (deduplicated). Failures are swallowed per
  /// file (a missing/corrupt PNG just leaves that slot programmatic) so a bad
  /// asset never blanks the whole world or throws at boot.
  Future<void> preload(Iterable<String> files) async {
    final Set<String> unique = files.toSet();
    await Future.wait(<Future<void>>[
      for (final String f in unique)
        if (!_images.containsKey(f)) _loadOne(f),
    ]);
  }

  /// Convenience: preload exactly the mapped-slot manifest.
  Future<void> preloadMapped() => preload(EmberSpriteSlots.preloadFiles);

  Future<void> _loadOne(String file) async {
    try {
      final ByteData data = await rootBundle.load('$kEmberSpriteDir$file');
      final ui.Codec codec =
          await ui.instantiateImageCodec(data.buffer.asUint8List());
      final ui.FrameInfo frame = await codec.getNextFrame();
      _images[file] = frame.image;
    } catch (_) {
      // Leave the slot unloaded -> the component falls back to placeholder art.
    }
  }

  /// Dispose all decoded images (the game owns the cache lifetime).
  void dispose() {
    for (final ui.Image img in _images.values) {
      img.dispose();
    }
    _images.clear();
  }
}
