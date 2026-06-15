// Ember — main_ember.dart
//
// The STANDALONE entry for the sim review loop:
//   fvm flutter run -t lib/ember/main_ember.dart
// It boots Hive, runs [EmberApp], and stacks a DEBUG SCENE PICKER over it — a
// floating bug button that opens a panel to jump straight into any reviewable
// state deterministically: the world, a fresh site-selection, each registered
// activity (empty until the leaves land in Step 4), plus force-night, trigger-
// flood, and advance-time toggles. This is the enabler for the on-device review
// loop: no app auth/onboarding, every state one tap away.
//
// The picker reaches the world through the SAME container EmberApp owns (via the
// overlayBuilder, which renders inside the module's ProviderScope), so its debug
// actions run the exact deterministic controller paths live play uses.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'debug/ember_tour.dart';
import 'ember_app.dart';
import 'registry/concept_registry.dart';
import 'state/intents.dart';
import 'state/providers.dart';
import 'state/world_controller.dart';
import 'ui/ember_theme.dart';
import 'ui/widgets/ember_button.dart';

/// When set (built with `--dart-define=EMBER_TOUR=true` or `=1`), the app
/// self-drives through the foundation states on a timer for automated screenshot
/// capture. Defaults to false, so a normal run is unchanged. We accept both the
/// canonical `true` (via bool.fromEnvironment) and `1` (the capture runner's
/// value) — both fold at compile time, so when neither is set EmberTour is never
/// referenced.
const bool kEmberTour = bool.fromEnvironment('EMBER_TOUR') ||
    String.fromEnvironment('EMBER_TOUR') == '1';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  runApp(
    EmberApp(
      // The debug scene picker is always available; in EMBER_TOUR mode the
      // self-driving tour is stacked beneath it (the picker still works, the
      // tour just renders nothing and advances the world on a timer).
      overlayBuilder: (BuildContext context) => const Stack(
        children: <Widget>[
          if (kEmberTour) EmberTour(),
          _DebugScenePicker(),
        ],
      ),
    ),
  );
}

/// A floating debug bug button + panel for jumping into reviewable states.
class _DebugScenePicker extends StatefulWidget {
  const _DebugScenePicker();

  @override
  State<_DebugScenePicker> createState() => _DebugScenePickerState();
}

class _DebugScenePickerState extends State<_DebugScenePicker> {
  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 12,
      bottom: 90,
      child: SafeArea(
        child: FloatingActionButton.small(
          heroTag: 'ember-debug',
          backgroundColor: const Color(0xFF2A3358),
          foregroundColor: const Color(0xFFFFD15C),
          onPressed: () => _openPanel(context),
          child: const Icon(Icons.bug_report),
        ),
      ),
    );
  }

  void _openPanel(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext ctx) => const _DebugPanel(),
    );
  }
}

class _DebugPanel extends ConsumerWidget {
  const _DebugPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final WorldController controller =
        ref.read(worldControllerProvider.notifier);
    final ConceptRegistry registry = ref.watch(registryProvider);

    return SafeArea(
      child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (BuildContext ctx, ScrollController scroll) {
          return Container(
            decoration: const BoxDecoration(
              color: Color(0xFF3A3F5C),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: ListView(
              controller: scroll,
              padding: const EdgeInsets.all(EmberUi.gapL),
              children: <Widget>[
                const _Header(),
                const SizedBox(height: EmberUi.gap),
                _section('Navigate'),
                _btn(
                  'Open the world',
                  Icons.public,
                  () => _close(ctx),
                ),
                _btn(
                  'Restart (new game + site pick)',
                  Icons.restart_alt,
                  () async {
                    Navigator.of(ctx).pop();
                    await controller.newGame();
                  },
                ),
                const SizedBox(height: EmberUi.gap),
                _section('World state'),
                _btn(
                  'Force day',
                  Icons.wb_sunny,
                  () {
                    controller.debugForceDay();
                    _close(ctx);
                  },
                ),
                _btn(
                  'Force night',
                  Icons.nightlight_round,
                  () {
                    controller.debugForceNight();
                    _close(ctx);
                  },
                ),
                _btn(
                  'Trigger flood',
                  Icons.water,
                  () {
                    controller.debugTriggerFlood();
                    _close(ctx);
                  },
                ),
                _btn(
                  'Flood the village (resolve)',
                  Icons.house_siding,
                  () {
                    // Run the REAL FloodResolver so low/weak dwellings take damage
                    // (lean/cracks/waterline) while high-ground homes stay dry.
                    controller.debugResolveFlood();
                    _close(ctx);
                  },
                ),
                _btn(
                  'Clear flood',
                  Icons.wb_cloudy,
                  () {
                    controller.debugClearFlood();
                    _close(ctx);
                  },
                ),
                _btn(
                  'Advance time +1 min',
                  Icons.fast_forward,
                  () => controller.dispatch(const AdvanceTimeDebug(60 * 1000)),
                ),
                _btn(
                  'Advance time +1 hour',
                  Icons.skip_next,
                  () => controller
                      .dispatch(const AdvanceTimeDebug(60 * 60 * 1000)),
                ),
                const SizedBox(height: EmberUi.gap),
                _section('Activities (${registry.activities.length})'),
                if (registry.activities.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'No activities registered yet.\n'
                      'The 3 concept leaves land in Step 4.',
                      style: TextStyle(color: Color(0xFFA7A8C2), fontSize: 13),
                    ),
                  )
                else
                  for (final a in registry.activities)
                    _btn(
                      a.def.title,
                      Icons.science_outlined,
                      () {
                        // Activity launch is owned by the world screen's host;
                        // jumping straight in requires that host, so we just open
                        // the world here and surface the activity in the tracker.
                        _close(ctx);
                      },
                    ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _close(BuildContext ctx) => Navigator.of(ctx).pop();

  Widget _section(String label) => Padding(
        padding: const EdgeInsets.only(bottom: EmberUi.gapS),
        child: Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: Color(0xFFFFD15C),
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      );

  Widget _btn(String label, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: EmberUi.gapS),
      child: Material(
        color: const Color(0xFF4A4F70),
        borderRadius: BorderRadius.circular(EmberUi.radius),
        child: InkWell(
          borderRadius: BorderRadius.circular(EmberUi.radius),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(EmberUi.gap),
            child: Row(
              children: <Widget>[
                Icon(icon, color: const Color(0xFFFFD15C), size: 22),
                const SizedBox(width: EmberUi.gap),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFFE8E6F0),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const Icon(Icons.bug_report, color: Color(0xFFFFD15C), size: 24),
        const SizedBox(width: EmberUi.gapS),
        const Text(
          'Scene Picker',
          style: TextStyle(
            color: Color(0xFFE8E6F0),
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        EmberIconButton(
          icon: Icons.close,
          size: 40,
          background: const Color(0xFF2A3358),
          foreground: const Color(0xFFE8E6F0),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

