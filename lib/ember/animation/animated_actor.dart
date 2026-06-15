// Ember — animation/animated_actor.dart
//
// The animation seam. An AnimatedActor wraps ONE Flame component and can be
// driven through the closed [AnimState] set. The default implementation is
// programmatic (programmatic_actor.dart); a Spine-backed one drops in behind the
// same interface later (spine_actor_seam.dart) with NO change to callers.
//
// Presentation-only (animation/), so it depends on flame + flutter painting.
// There is no clock here — animation time is fed by Flame's update(dt) loop.

import 'package:flame/components.dart';

import '../core/enums.dart';

/// A drivable, animatable on-screen figure.
///
/// Callers add [component] to the game tree and call [play] to switch states.
/// Implementations are responsible for tweening between states themselves.
abstract interface class AnimatedActor {
  /// The single Flame component this actor renders through. Add this to a parent
  /// (a [World], a tile component, etc.). Owned by the actor for its lifetime.
  Component get component;

  /// Switch to animation [state]. If [loop] is false the actor plays the state
  /// once and (for one-shots like [AnimState.celebrate]/[AnimState.fail])
  /// settles back to [AnimState.idle] when finished.
  void play(AnimState state, {bool loop = true});

  /// The currently-playing (or settled) state.
  AnimState get current;
}
