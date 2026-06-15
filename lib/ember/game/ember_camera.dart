// Ember — game/ember_camera.dart
//
// The camera rig: a thin wrapper around Flame's [CameraComponent] that adds the
// world-builder controls — drag PAN, pinch ZOOM clamped to [0.5, 2.5], and a
// BOUNDS clamp so the viewfinder can never wander off the iso-projected map AABB.
// The game forwards gesture deltas (from its ScaleDetector) into [panBy] /
// [zoomBy]; this class does the math + clamping in one place.
//
// Pan/zoom are applied to the viewfinder; after each change the viewfinder
// position is re-clamped to the map bounds (inset by half the visible world rect
// so the camera centre stays over the map). Presentation-only — no clock/random.

import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/camera.dart';
import 'package:flame/components.dart';

import 'iso/iso_projection.dart';

/// Configures + drives an Ember [CameraComponent].
class EmberCamera {
  EmberCamera({
    required this.camera,
    required this.projection,
    required this.gridWidth,
    required this.gridHeight,
    this.minZoom = 0.5,
    this.maxZoom = 2.5,
  });

  /// Builds a camera looking at [world], homed on the map centre at a sensible
  /// starting zoom, and returns the rig wrapping it.
  factory EmberCamera.forWorld({
    required World world,
    required IsoProjection projection,
    required int gridWidth,
    required int gridHeight,
    double minZoom = 0.5,
    double maxZoom = 2.5,
    double startZoom = 1.0,
  }) {
    final CameraComponent camera = CameraComponent(world: world);
    camera.viewfinder.anchor = Anchor.center;
    camera.viewfinder.zoom = startZoom.clamp(minZoom, maxZoom);
    camera.viewfinder.position = projection.mapCenter(gridWidth, gridHeight);
    return EmberCamera(
      camera: camera,
      projection: projection,
      gridWidth: gridWidth,
      gridHeight: gridHeight,
      minZoom: minZoom,
      maxZoom: maxZoom,
    );
  }

  final CameraComponent camera;
  final IsoProjection projection;
  final int gridWidth;
  final int gridHeight;
  final double minZoom;
  final double maxZoom;

  Viewfinder get _vf => camera.viewfinder;

  /// Current zoom.
  double get zoom => _vf.zoom;

  /// Re-home on the map centre at the current zoom.
  void home() {
    _vf.position = projection.mapCenter(gridWidth, gridHeight);
    _clamp();
  }

  /// Pan by a WORLD-space delta (the inverse of a screen drag — dragging right
  /// moves the world right, i.e. the camera left). Callers pass the negated
  /// screen delta divided by zoom; this method clamps to bounds.
  void panBy(Vector2 worldDelta) {
    _vf.position = _vf.position + worldDelta;
    _clamp();
  }

  /// Pan by a SCREEN-space drag delta (px). Converts to world space using the
  /// current zoom and inverts so the world follows the finger.
  void panByScreen(Vector2 screenDelta) {
    panBy(Vector2(-screenDelta.x / _vf.zoom, -screenDelta.y / _vf.zoom));
  }

  /// Multiply the zoom by [factor] (pinch scale), keeping it in [minZoom,
  /// maxZoom], then re-clamp the position so the new visible rect stays on-map.
  void zoomBy(double factor) {
    setZoom(_vf.zoom * factor);
  }

  /// Set the zoom absolutely (clamped).
  void setZoom(double z) {
    _vf.zoom = z.clamp(minZoom, maxZoom);
    _clamp();
  }

  /// Centre the camera on a world position (e.g. an activity focus), clamped.
  void lookAt(Vector2 worldPos) {
    _vf.position = worldPos;
    _clamp();
  }

  /// Clamp the viewfinder centre so the visible world rect never leaves the map
  /// AABB. When the map is smaller than the viewport on an axis, the centre is
  /// pinned to the map centre on that axis (so a small map stays centred).
  void _clamp() {
    final Rect bounds = projection.mapBounds(
      gridWidth,
      gridHeight,
      pad: projection.tileWidth,
    );
    final Vector2 visible = _visibleWorldSize();
    final double halfW = visible.x / 2;
    final double halfH = visible.y / 2;

    final Vector2 pos = _vf.position;

    // X axis.
    double x;
    if (visible.x >= bounds.width) {
      x = bounds.center.dx; // map narrower than view -> pin centre.
    } else {
      x = pos.x.clamp(bounds.left + halfW, bounds.right - halfW);
    }
    // Y axis.
    double y;
    if (visible.y >= bounds.height) {
      y = bounds.center.dy;
    } else {
      y = pos.y.clamp(bounds.top + halfH, bounds.bottom - halfH);
    }
    _vf.position = Vector2(x, y);
  }

  /// The size (world px) of the rectangle the camera currently sees.
  Vector2 _visibleWorldSize() {
    final Vector2 vp = camera.viewport.size;
    final double z = math.max(_vf.zoom, 0.0001);
    return Vector2(vp.x / z, vp.y / z);
  }
}
