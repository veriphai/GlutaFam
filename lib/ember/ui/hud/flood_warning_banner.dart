// Ember — ui/hud/flood_warning_banner.dart
//
// A loud, unmistakable "FLOOD!" banner shown across the top of the world while a
// flood world-event is active. It is the HUD half of the flood read (the cyan
// water wash + rising waterline live in the Flame FloodOverlayComponent) so a
// flood can NEVER be confused with nighttime — even before the shelter leaf
// lands and a resolver clears the event.
//
// Reads the world snapshot only (an unresolved, due flood event); never mutates.
// Pulses gently so it draws the eye without being annoying for kids.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../art/ember_palette.dart';
import '../../core/enums.dart';
import '../../data/models/world_event.dart';
import '../../data/models/world_state.dart';
import '../../state/providers.dart';
import '../../state/world_controller.dart';
import '../ember_theme.dart';

/// A pulsing flood-warning banner; renders nothing when no flood is active.
class FloodWarningBanner extends ConsumerStatefulWidget {
  const FloodWarningBanner({super.key});

  @override
  ConsumerState<FloodWarningBanner> createState() => _FloodWarningBannerState();
}

class _FloodWarningBannerState extends ConsumerState<FloodWarningBanner>
    with SingleTickerProviderStateMixin {
  // EAGERLY constructed in initState (NOT a `late final` lazy initializer): a
  // lazy `_pulse` that was never touched (the banner never showed a flood) would
  // be CONSTRUCTED for the first time inside dispose() when we call
  // `_pulse.dispose()` — and AnimationController's ctor calls createTicker ->
  // TickerMode.getValuesNotifier, an InheritedWidget ancestor lookup, which is
  // illegal on a deactivated element ("Looking up a deactivated widget's ancestor
  // is unsafe"). Building it in initState guarantees it always exists, so dispose
  // only ever disposes an already-built controller.
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final EmberPalette p = ref.watch(artProvider).palette;
    final EmberWorldState s = ref.watch(worldControllerProvider);
    final bool flooding = _hasActiveFlood(s);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      transitionBuilder: (Widget child, Animation<double> a) => FadeTransition(
        opacity: a,
        child: SizeTransition(sizeFactor: a, child: child),
      ),
      child: flooding ? _banner(p) : const SizedBox.shrink(),
    );
  }

  bool _hasActiveFlood(EmberWorldState s) {
    for (final WorldEvent e in s.events) {
      if (e.type != WorldEventType.flood) continue;
      if (e.scheduledForMs > s.simNowMs) continue;
      // A debug flood (review loop) is shown even after the live sim
      // auto-resolves it (no flood resolver until the shelter leaf lands).
      if (e.payload['debug'] == true || !e.resolved) return true;
    }
    return false;
  }

  Widget _banner(EmberPalette p) {
    // A cool cyan/teal banner — the same colour language as the in-world water
    // wash — so the flood read is consistent and never reads as "night".
    final Color bg = p.water;
    return AnimatedBuilder(
      animation: _pulse,
      builder: (BuildContext context, Widget? child) {
        final double t = _pulse.value;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
              horizontal: EmberUi.gap, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[
                Color.lerp(bg, p.waterDeep, 0.2 + 0.3 * t)!,
                p.waterDeep,
              ],
            ),
            borderRadius: BorderRadius.circular(EmberUi.radius),
            border: Border.all(color: p.spark, width: 2),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: p.waterDeep.withValues(alpha: 0.4 + 0.3 * t),
                blurRadius: 12 + 6 * t,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: child,
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Icon(Icons.water_drop, color: Colors.white, size: 22),
          const SizedBox(width: 8),
          const Text(
            'FLOOD! The river is rising',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.warning_amber_rounded, color: p.spark, size: 22),
        ],
      ),
    );
  }
}
