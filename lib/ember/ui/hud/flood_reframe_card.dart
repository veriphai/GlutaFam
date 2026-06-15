// Ember — ui/hud/flood_reframe_card.dart
//
// THE FLAGSHIP REFRAME, made to land. After the river has risen and bitten the
// low camp (the FloodResolver damages low/weak shelters + raises the
// `world.floodAftermath` flag), this watcher surfaces the Elder's turn ONE TIME:
// the flood is not a curse — it comes in a cycle you can read, build above it, and
// the same water that swept the low ground lays the richest soil for next season.
// That is the fear -> understanding -> mastery beat the whole Shelter concept
// builds toward.
//
// It mirrors the AwayDigestHost pattern: a zero-size watcher that reads the world
// snapshot, presents a modal sheet exactly once per aftermath, and remembers it
// has shown so it never nags. It NEVER mutates the world (it only reads the
// knowledge flags the resolver set) — pure presentation.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../art/ember_palette.dart';
import '../../data/models/world_state.dart';
import '../../state/providers.dart';
import '../../state/world_controller.dart';
import '../ember_theme.dart';
import '../widgets/ember_button.dart';

/// The frozen `world.*` / `shelter.*` flags the FloodResolver + Shelter activity
/// raise. Referenced by their stable contract strings (matching ShelterKnowledge)
/// so this presentation card needs no concept-leaf import.
const String _kFloodAftermathFlag = 'world.floodAftermath';
const String _kBestSoilNextSeasonFlag = 'world.bestSoilNextSeason';

/// The reframe is the SHELTER concept's payoff, so it must only land once the
/// player has actually raised a shelter / the camp is housed — never over the
/// empty-world flood showcase that has no homes to bite. Either of these flags
/// means the settled-village experience exists.
const String _kShelterDiscoveredFlag = 'shelter.discovered';
const String _kVillageHousedFlag = 'world.villageHoused';

/// Watches for a freshly-lived-through flood and presents the reframe once.
class FloodReframeHost extends ConsumerStatefulWidget {
  const FloodReframeHost({super.key});

  @override
  ConsumerState<FloodReframeHost> createState() => _FloodReframeHostState();
}

class _FloodReframeHostState extends ConsumerState<FloodReframeHost> {
  /// True while the sheet is on screen (so we don't stack presentations).
  bool _showing = false;

  /// True once we've shown it for the current aftermath; cleared when the
  /// aftermath flag goes away (a new game / a future "season reset"), so a NEW
  /// flood in a later session can land its reframe again.
  bool _shownForThisAftermath = false;

  /// Set while the modal route is on screen so we can dismiss it if the aftermath
  /// is cleared out from under it (e.g. a new game) before the player taps.
  bool _routeUp = false;

  /// The root navigator, captured safely in didChangeDependencies so dispose can
  /// pop a lingering reframe route WITHOUT an unsafe ancestor lookup after the
  /// host (and its WorldScreen) has been deactivated.
  NavigatorState? _rootNav;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _rootNav = Navigator.of(context, rootNavigator: true);
  }

  @override
  void dispose() {
    // If the world tears down (e.g. a new game) while the reframe is still up, the
    // modal lives on the ROOT navigator and would otherwise outlive its world.
    // Pop it so it can never linger over an unrelated screen.
    if (_routeUp) {
      _routeUp = false;
      _rootNav?.maybePop();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final EmberWorldState s = ref.watch(worldControllerProvider);
    final bool settled = s.knowledge.get(_kShelterDiscoveredFlag) ||
        s.knowledge.get(_kVillageHousedFlag);
    final bool aftermath = settled && s.knowledge.get(_kFloodAftermathFlag);

    if (!aftermath) {
      // Re-arm for the next flood once the aftermath clears.
      _shownForThisAftermath = false;
      // If a stale reframe is still up (the flag was reset under it), drop it so
      // it can't linger over an unrelated world.
      if (_routeUp) {
        _routeUp = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Navigator.of(context, rootNavigator: true).maybePop();
        });
      }
      return const SizedBox.shrink();
    }

    if (!_shownForThisAftermath && !_showing) {
      _shownForThisAftermath = true;
      _showing = true;
      final bool bestSoil = s.knowledge.get(_kBestSoilNextSeasonFlag);
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _present(bestSoil: bestSoil));
    }
    return const SizedBox.shrink();
  }

  Future<void> _present({required bool bestSoil}) async {
    // The post-frame callback can fire after this host has been torn down (e.g. a
    // new game / leaving the world mid-frame) — bail before touching context.
    if (!mounted) {
      _showing = false;
      return;
    }
    final EmberPalette p = ref.read(artProvider).palette;
    _routeUp = true;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      builder: (BuildContext ctx) =>
          FloodReframeSheet(palette: p, bestSoil: bestSoil),
    );
    _routeUp = false;
    if (mounted) _showing = false;
  }
}

/// The reframe card itself: the Elder speaks, the fear is named + replaced with
/// the cycle, and (when the flood touched flood-path ground) the fertile-soil
/// payoff is promised — the showpiece turn.
class FloodReframeSheet extends StatelessWidget {
  const FloodReframeSheet({
    super.key,
    required this.palette,
    this.bestSoil = true,
  });

  final EmberPalette palette;

  /// Whether the flood touched flood-path ground (so silt -> rich soil applies).
  final bool bestSoil;

  @override
  Widget build(BuildContext context) {
    final EmberPalette p = palette;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(EmberUi.gap),
        child: Container(
          padding: const EdgeInsets.all(EmberUi.gapL),
          decoration: EmberUi.panel(p, raised: true),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // The Elder, speaking the turn.
              Row(
                children: <Widget>[
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: p.ember.withValues(alpha: 0.16),
                      border: Border.all(color: p.ember, width: 1.5),
                    ),
                    child: Icon(Icons.person, color: p.ember, size: 26),
                  ),
                  const SizedBox(width: EmberUi.gapS),
                  Expanded(
                    child: Text(
                      'The Elder reads the river',
                      style: TextStyle(
                        color: p.ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: EmberUi.gap),

              // The fear named (what the tribe thought).
              _Belief(
                palette: p,
                icon: Icons.water_drop,
                tint: p.water,
                label: 'The old fear',
                text:
                    '"The river is cursed — it rose in the night and swept the '
                    'low camp away."',
              ),
              const SizedBox(height: EmberUi.gapS),

              // The reframe (what we now know): the predictable cycle.
              _Belief(
                palette: p,
                icon: Icons.autorenew,
                tint: p.success,
                label: 'Now we know',
                text:
                    '"The river is not cursed. The flood comes in a cycle you can '
                    'read. Build on higher ground, and you will wake dry every '
                    'time the water rises."',
              ),

              if (bestSoil) ...<Widget>[
                const SizedBox(height: EmberUi.gap),
                // The mastery payoff: the water that swept the camp leaves gold.
                Container(
                  padding: const EdgeInsets.all(EmberUi.gap),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: <Color>[
                        p.grass.withValues(alpha: 0.30),
                        p.food.withValues(alpha: 0.28),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(EmberUi.radius),
                    border: Border.all(color: p.grassDark, width: 1.2),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Icon(Icons.eco, color: p.grassDark, size: 24),
                      const SizedBox(width: EmberUi.gapS),
                      Expanded(
                        child: Text(
                          'And the same water left rich, dark soil along the bank '
                          '— next season, that ground will be the best you ever '
                          'planted.',
                          style: TextStyle(
                            color: p.ink,
                            fontSize: 14,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: EmberUi.gapL),
              EmberButton(
                label: 'I can plan for this',
                icon: Icons.lightbulb,
                palette: p,
                expand: true,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One "we thought / we know" belief row (icon + label + the spoken line).
class _Belief extends StatelessWidget {
  const _Belief({
    required this.palette,
    required this.icon,
    required this.tint,
    required this.label,
    required this.text,
  });

  final EmberPalette palette;
  final IconData icon;
  final Color tint;
  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    final EmberPalette p = palette;
    return Container(
      padding: const EdgeInsets.all(EmberUi.gap),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(EmberUi.radius),
        border: Border.all(color: tint.withValues(alpha: 0.5), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, color: tint, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: tint,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            text,
            style: TextStyle(
              color: p.ink,
              fontSize: 14,
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
