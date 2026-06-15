// Ember — game/game_bridge.dart
//
// THE single sim touch-point for the Flame layer. Components NEVER import
// Riverpod, never read worldControllerProvider, never mutate state. They hold a
// GameBridge and:
//   * read an IMMUTABLE view of the world (`bridge.state`, plus typed slices),
//   * subscribe to changes via plain [ValueListenable]s (robust + Flame-native —
//     no WidgetRef, no element tree), and
//   * mutate ONLY by dispatching an [Intent] (`bridge.dispatch(...)`).
//
// WHY ValueListenables (the chosen wiring): pushing a ProviderContainer into
// every component and calling `container.listen` from inside Flame's lifecycle
// is fragile — listeners must be torn down on remove, and a component may read
// `game` before it is mounted. Instead the bridge owns the ProviderContainer,
// runs the Riverpod subscriptions in ONE place, and republishes each slice as a
// [ValueNotifier]. Components attach a plain VoidCallback in onMount and detach
// it in onRemove — the standard Flame pattern, with zero Riverpod surface area
// leaking into the component tree.
//
// The bridge is presentation glue (game/), so depending on flutter_riverpod +
// flutter/foundation is fine. It performs NO clock/random work itself — all of
// that lives behind the controller it dispatches into.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../contracts/light_source.dart';
import '../data/models/world_state.dart';
import '../sim/systems/fire_coverage.dart';
import '../state/intents.dart';
import '../state/seams.dart';
import '../state/selectors.dart';
import '../state/world_controller.dart';

/// Read-only world view + Intent dispatch for the Flame layer. Owns the Riverpod
/// subscriptions and republishes the slices components care about as plain
/// [ValueListenable]s. Call [dispose] when the game is detached.
class GameBridge {
  GameBridge(this._container) {
    _world = ValueNotifier<EmberWorldState>(_container.read(worldControllerProvider));
    _coverage = ValueNotifier<FireCoverage>(_container.read(fireCoverageProvider));
    _lights = ValueNotifier<List<LightSource>>(
      _container.read(lightSourcesProvider),
    );
    _isNight = ValueNotifier<bool>(_container.read(isNightProvider));
    _darkness = ValueNotifier<double>(_container.read(darknessProvider));
    _ready = ValueNotifier<bool>(_container.read(worldReadyProvider));
    _wire();
  }

  final ProviderContainer _container;
  final List<ProviderSubscription<dynamic>> _subs =
      <ProviderSubscription<dynamic>>[];

  late final ValueNotifier<EmberWorldState> _world;
  late final ValueNotifier<FireCoverage> _coverage;
  late final ValueNotifier<List<LightSource>> _lights;
  late final ValueNotifier<bool> _isNight;
  late final ValueNotifier<double> _darkness;
  late final ValueNotifier<bool> _ready;

  // ===========================================================================
  // Read surface (immutable)
  // ===========================================================================

  /// The current immutable world snapshot. Components treat this as read-only.
  EmberWorldState get state => _world.value;

  /// The current fire-coverage pass (lit/warm tile sets).
  FireCoverage get coverage => _coverage.value;

  /// The active light sources published by fire placeables.
  List<LightSource> get lightSources => _lights.value;

  /// Whether it is currently night.
  bool get isNight => _isNight.value;

  /// 0..1 ambient darkness factor.
  double get darkness => _darkness.value;

  /// Whether bootstrap (load + offline catch-up) has finished.
  bool get isReady => _ready.value;

  // ===========================================================================
  // Listenables (components attach/detach plain callbacks)
  // ===========================================================================

  /// Fires whenever the world snapshot changes (any intent / tick).
  ValueListenable<EmberWorldState> get worldListenable => _world;

  /// Fires when fire coverage changes (a fire built/removed/refuelled).
  ValueListenable<FireCoverage> get coverageListenable => _coverage;

  /// Fires when the set of light sources changes.
  ValueListenable<List<LightSource>> get lightSourcesListenable => _lights;

  /// Fires when day/night flips.
  ValueListenable<bool> get isNightListenable => _isNight;

  /// Fires when the ambient darkness factor changes.
  ValueListenable<double> get darknessListenable => _darkness;

  /// Fires once bootstrap finishes.
  ValueListenable<bool> get readyListenable => _ready;

  // ===========================================================================
  // Write surface (dispatch only)
  // ===========================================================================

  /// The ONLY way a component mutates the world: hand the controller an Intent.
  /// Determinism + persistence stay entirely inside the controller.
  void dispatch(Intent intent) {
    _container.read(worldControllerProvider.notifier).dispatch(intent);
  }

  /// Drives the live simulation forward by [dtMs] of sim time. The game's render
  /// loop accumulates real time and calls this in fixed-ish chunks.
  void tick(int dtMs) {
    _container.read(worldControllerProvider.notifier).tick(dtMs);
  }

  // ===========================================================================
  // Internals
  // ===========================================================================

  void _wire() {
    _subs.add(
      _container.listen<EmberWorldState>(
        worldControllerProvider,
        (EmberWorldState? prev, EmberWorldState next) => _world.value = next,
      ),
    );
    _subs.add(
      _container.listen<FireCoverage>(
        fireCoverageProvider,
        (FireCoverage? prev, FireCoverage next) => _coverage.value = next,
      ),
    );
    _subs.add(
      _container.listen<List<LightSource>>(
        lightSourcesProvider,
        (List<LightSource>? prev, List<LightSource> next) =>
            _lights.value = next,
      ),
    );
    _subs.add(
      _container.listen<bool>(
        isNightProvider,
        (bool? prev, bool next) => _isNight.value = next,
      ),
    );
    _subs.add(
      _container.listen<double>(
        darknessProvider,
        (double? prev, double next) => _darkness.value = next,
      ),
    );
    _subs.add(
      _container.listen<bool>(
        worldReadyProvider,
        (bool? prev, bool next) => _ready.value = next,
      ),
    );
  }

  /// Tears down the Riverpod subscriptions + notifiers. Call from the game's
  /// onRemove. Does NOT dispose the ProviderContainer (the host owns it).
  void dispose() {
    for (final ProviderSubscription<dynamic> s in _subs) {
      s.close();
    }
    _subs.clear();
    _world.dispose();
    _coverage.dispose();
    _lights.dispose();
    _isNight.dispose();
    _darkness.dispose();
    _ready.dispose();
  }
}
