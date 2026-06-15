// Ember — animation/spine_actor_seam.dart
//
// The Spine seam: a ONE-FILE swap point for skeletal animation. There is NO
// spine_flutter dependency yet — this is a compiling stub that conforms to
// [AnimatedActor] so the rest of the module can target Spine-quality animation
// without taking the dependency now.
//
// HOW TO ACTIVATE (later, in THIS file only):
//   1. Add `spine_flutter: <ver>` to pubspec dev/runtime deps.
//   2. Import it here, load a SkeletonData/atlas in [SpineActor], and back
//      [component] with a SpineComponent.
//   3. Map each [AnimState] to a Spine animation name via [_animName] and call
//      the AnimationState track API in [play].
// Nothing outside this file changes — callers keep using [AnimatedActor].
//
// Until then, [SpineActor] delegates to a programmatic fallback so it is always
// safe to construct (e.g. behind a feature flag) without crashing.

import 'package:flame/components.dart';

import '../art/ember_palette.dart';
import '../core/enums.dart';
import 'animated_actor.dart';
import 'programmatic_actor.dart';

/// Maps the closed [AnimState] set to the Spine animation track names a future
/// skeleton is expected to expose. Defined now so the contract is frozen and the
/// asset team can author against it.
String spineAnimationName(AnimState s) => switch (s) {
      AnimState.idle => 'idle',
      AnimState.walk => 'walk',
      AnimState.work => 'work',
      AnimState.celebrate => 'celebrate',
      AnimState.fail => 'fail',
    };

/// Conventional Spine skeleton asset names per [ActorKind] (under
/// assets/ember/spine/). The atlas + skeleton json/skel are expected at:
///   `assets/ember/spine/<name>.atlas`
///   `assets/ember/spine/<name>.skel`
String spineSkeletonName(ActorKind kind) => switch (kind) {
      ActorKind.elder => 'elder',
      ActorKind.tribe => 'tribe',
      ActorKind.predator => 'predator',
      ActorKind.flame => 'flame',
    };

/// A Spine-backed [AnimatedActor] SEAM.
///
/// Today it forwards to a [ProgrammaticActor] fallback so it always compiles and
/// runs. When spine_flutter is wired (see file header), swap [_fallback] for a
/// real SpineComponent-backed implementation — no caller changes.
class SpineActor implements AnimatedActor {
  SpineActor(
    this.kind, {
    EmberPalette palette = EmberPalette.dusk,
  }) : _fallback = ProgrammaticActor(kind, palette: palette);

  final ActorKind kind;

  /// Programmatic stand-in until a Spine skeleton is loaded.
  final ProgrammaticActor _fallback;

  /// True once a real Spine skeleton backs this actor. Always false in the stub.
  bool get isSpineBacked => false;

  @override
  Component get component => _fallback.component;

  @override
  AnimState get current => _fallback.current;

  @override
  void play(AnimState state, {bool loop = true}) {
    // When Spine-backed: animationState.setAnimation(0, spineAnimationName(state), loop);
    _fallback.play(state, loop: loop);
  }
}
