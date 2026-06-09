// Full-stage, invisible gesture catcher. Component-level Tap + Drag callbacks are
// the modern (non-deprecated) Flame gesture API and work for both touch and mouse.
// `containsLocalPoint => true` catches gestures anywhere on the canvas. It simply
// forwards the pointer's canvas position to the game, which turns it into an
// antenna aim angle (immediate drag — never hold-to-drag).

import 'package:flame/components.dart';
import 'package:flame/events.dart';

import '../signal_rescue_game.dart';

class GestureCatcher extends PositionComponent
    with TapCallbacks, DragCallbacks, HasGameReference<SignalRescueGame> {
  final Vector2 _p = Vector2.zero();

  @override
  bool containsLocalPoint(Vector2 point) => true;

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    game.aimAt(event.canvasPosition);
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    _p.setFrom(event.canvasPosition);
    game.aimAt(_p);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    _p.add(event.localDelta);
    game.aimAt(_p);
  }
}
