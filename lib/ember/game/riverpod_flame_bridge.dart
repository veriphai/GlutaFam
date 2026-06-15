// Ember — game/riverpod_flame_bridge.dart
//
// The component-side helper that makes a Flame component react to GameBridge
// changes WITHOUT touching Riverpod directly. A component `with BridgedComponent`
// gets:
//   * `bridge` — the shared [GameBridge] read from the owning [EmberGame],
//   * `listenWorld(cb)` / `listen<T>(listenable, cb)` — register a reaction that
//     is automatically attached on mount + detached on remove, so there are no
//     leaked listeners AND the reaction SURVIVES a remove+re-add (e.g. the iso
//     world being swapped out for an activity scene and restored on exit),
//   * `dispatch(intent)` — sugar over `bridge.dispatch`.
//
// CHOSEN WIRING (documented in game_bridge.dart): we do NOT inject a
// ProviderContainer into components. The bridge republishes Riverpod state as
// plain [ValueListenable]s; this mixin attaches/detaches plain callbacks in the
// standard Flame onMount/onRemove lifecycle. That keeps the Riverpod surface in
// exactly one place and the component tree Flame-pure + robust.
//
// RE-MOUNT SAFETY: bindings are RECORDED on registration but (de)attached in
// onMount/onRemove. onLoad runs once, but onMount runs on EVERY mount — so a
// component removed (its `world` swapped out for an activity) and re-added keeps
// reacting + resyncs (re-fires its `fireImmediately` bindings) once it's back.
// Before this, re-added components had their listeners detached on remove and
// never re-registered (onLoad doesn't re-run), so the restored world froze.

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import '../state/intents.dart';
import 'ember_game.dart';
import 'game_bridge.dart';

/// Mixin for any component that needs the [GameBridge]. Requires the component
/// to be mounted under an [EmberGame] (via [HasGameReference]).
mixin BridgedComponent on Component implements HasGameReference<EmberGame> {
  final List<_Binding<dynamic>> _bindings = <_Binding<dynamic>>[];

  /// Whether this component's bindings are currently attached to their
  /// listenables (true between onMount and onRemove).
  bool _attached = false;

  /// The shared bridge (the only sim touch-point). Available from onMount on.
  GameBridge get bridge => game.bridge;

  /// Dispatch an [Intent] into the world controller.
  void dispatch(Intent intent) => bridge.dispatch(intent);

  /// React to ANY world-state change. Pass [fireImmediately] to also invoke once
  /// on (re)attach. The binding is recorded once and (de)attached with the
  /// component's mount lifecycle, so it survives a remove+re-add.
  void listenWorld(VoidCallback callback, {bool fireImmediately = false}) {
    listen<dynamic>(bridge.worldListenable, callback,
        fireImmediately: fireImmediately);
  }

  /// React to a specific bridge [listenable]. Recorded once; attached on mount,
  /// detached on remove, re-attached on re-mount. [fireImmediately] fires on each
  /// attach (initial mount AND re-mount) so a restored component resyncs.
  void listen<T>(
    ValueListenable<T> listenable,
    VoidCallback callback, {
    bool fireImmediately = false,
  }) {
    final _Binding<T> binding = _Binding<T>(listenable, callback, fireImmediately);
    _bindings.add(binding);
    // If we're already mounted (registration happening after onMount), attach now.
    if (_attached) binding.attach();
  }

  @override
  void onMount() {
    super.onMount();
    if (_attached) return;
    _attached = true;
    for (final _Binding<dynamic> b in _bindings) {
      b.attach();
    }
  }

  @override
  void onRemove() {
    if (_attached) {
      _attached = false;
      for (final _Binding<dynamic> b in _bindings) {
        b.detach();
      }
    }
    super.onRemove();
  }
}

/// A registered listenable+callback pair so it can be (de)attached across the
/// component's mount lifecycle (not just torn down once).
class _Binding<T> {
  _Binding(this.listenable, this.callback, this.fireImmediately);

  final ValueListenable<T> listenable;
  final VoidCallback callback;
  final bool fireImmediately;

  void attach() {
    listenable.addListener(callback);
    if (fireImmediately) callback();
  }

  void detach() => listenable.removeListener(callback);
}
