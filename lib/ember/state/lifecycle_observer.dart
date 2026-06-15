// Ember — state/lifecycle_observer.dart
//
// Bridges Flutter app-lifecycle events to the WorldController. On RESUME it runs
// the offline catch-up (replaying the away window through the same sim) and
// stamps a fresh away digest; on PAUSE/INACTIVE/DETACH it persists the world and
// stamps lastSeenMs (via EmberClock, owned by the controller). Register it with
// WidgetsBinding.instance.addObserver in EmberApp and remove it on dispose.

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'world_controller.dart';

class EmberLifecycleObserver with WidgetsBindingObserver {
  EmberLifecycleObserver(this._ref);

  final Ref _ref;

  WorldController get _controller => _ref.read(worldControllerProvider.notifier);

  /// Whether we have already persisted for the current background episode (so a
  /// pause -> inactive -> detached burst doesn't double-save).
  bool _backgrounded = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _backgrounded = false;
        // Replay the away window; the controller stamps lastSeenMs = now.
        // ignore: discarded_futures — fire-and-forget; UI watches worldReady.
        _controller.resume();
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        if (!_backgrounded) {
          _backgrounded = true;
          // Guaranteed save + lastSeenMs stamp before the app is suspended.
          // ignore: discarded_futures — best-effort flush on background.
          _controller.persistNow();
        }
    }
  }
}

/// Provider that constructs the lifecycle observer bound to the root Ref. EmberApp
/// reads this once and registers it with the WidgetsBinding.
final Provider<EmberLifecycleObserver> lifecycleObserverProvider =
    Provider<EmberLifecycleObserver>((Ref ref) => EmberLifecycleObserver(ref));
