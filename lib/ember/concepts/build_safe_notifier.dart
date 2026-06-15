// Ember — concepts/build_safe_notifier.dart
//
// A [ChangeNotifier] base for the activity interact VIEW-MODELS (fire/tools/
// shelter). These are synced from their Flame scene's update() — which runs
// inside the Flutter frame's persistent/transient-callbacks phase — so a plain
// notifyListeners() there fires the listening AnimatedBuilder -> setState WHILE
// the widget tree is building -> the "setState()/markNeedsBuild() called during
// build" storm.
//
// [safeNotify] notifies SYNCHRONOUSLY only when the scheduler is idle; if a
// build could be in flight it DEFERS one coalesced notify to the next post-frame
// callback (the view lags at most one frame — imperceptible for presentation —
// and the build phase is never violated). A queued deferred notify becomes a
// no-op after dispose (the scene disposes the view on activity exit).

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// A [ChangeNotifier] whose notifications are safe to fire from inside the Flame
/// update loop (which overlaps the Flutter build phase). Use [safeNotify] instead
/// of [notifyListeners].
abstract class BuildSafeChangeNotifier extends ChangeNotifier {
  bool _notifyQueued = false;
  bool _disposed = false;

  /// Notify listeners without ever marking a build in progress. Synchronous when
  /// the scheduler is idle; deferred + coalesced to the next post-frame otherwise.
  @protected
  void safeNotify() {
    if (_disposed) return;
    final SchedulerPhase phase = SchedulerBinding.instance.schedulerPhase;
    final bool buildMayBeInFlight =
        phase == SchedulerPhase.persistentCallbacks ||
            phase == SchedulerPhase.midFrameMicrotasks ||
            phase == SchedulerPhase.transientCallbacks;
    if (!buildMayBeInFlight) {
      notifyListeners();
      return;
    }
    if (_notifyQueued) return; // already coalesced into the pending post-frame.
    _notifyQueued = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _notifyQueued = false;
      if (_disposed) return;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
