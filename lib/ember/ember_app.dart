// Ember — ember_app.dart
//
// The module ROOT widget. It owns Ember's own [ProviderContainer] (a scope
// SEPARATE from the host app's Riverpod), applies the production DI overrides
// (real Hive repo, SystemClock, placeholder/sprite art, audioplayers audio, the
// wired registry), runs the one-time bootstrap (installAll the leaves' push
// seams -> load the save -> offline catch-up), registers the lifecycle observer,
// and mounts the MaterialApp themed by ember_theme. First run routes into the
// site-selection flow; thereafter straight into the world.
//
// FROZEN: onInstall + the lifecycle observer receive the legacy Riverpod `Ref`
// (flutter_riverpod ^2.x) handed by the container-backed root, NOT a WidgetRef.
//
// Zero coupling: nothing here imports the host app. EmberApp is the single symbol
// the host mounts (re-exported from ember.dart).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'art/ember_art.dart';
import 'art/sprite_art.dart';
import 'contracts/ember_audio.dart';
import 'core/ember_clock.dart';
import 'data/repository/hive_save_repository.dart';
import 'data/repository/save_repository.dart';
import 'registry/concept_registry.dart';
import 'registry/ember_registry.dart';
import 'state/lifecycle_observer.dart';
import 'state/providers.dart';
import 'state/world_controller.dart';
import 'ui/ember_theme.dart';
import 'ui/site_selection_screen.dart';
import 'ui/world_screen.dart';

/// A one-time bootstrap hook that runs every installed leaf's onInstall against
/// the root [Ref] (publishing cross-concept push seams) shortly after the world
/// container is built. No-op-safe while the registry is stubbed (empty). Defined
/// here so it has a real provider [Ref] to hand the leaves.
///
/// The install is DEFERRED to a microtask rather than run inside this provider's
/// build: a leaf's onInstall PUSHES into seam StateProviders (e.g. tools append a
/// GatherModifier to toolMultiplierProvider), and Riverpod forbids a provider
/// mutating ANOTHER provider during its own initialization (it threw a boot-time
/// assertion otherwise). Running installAll on the next microtask moves the seam
/// writes out of this provider's build, so no provider mutates another during
/// init. Safe ordering: the seams pushed here feed only the UI-facing DERIVED
/// providers (effectiveGatherModifierProvider, the population-cap selector); the
/// SIM reads the COMPOSED SimRegistry.gatherModifier directly (independent of the
/// push), so the deferred push cannot race the world bootstrap's sim reads.
final Provider<void> _installProvider = Provider<void>((Ref ref) {
  final ConceptRegistry registry = ref.read(registryProvider);
  Future<void>.microtask(() => EmberRegistry.installAll(ref, registry));
});

/// The Ember root. Mount this anywhere (it is fully self-contained).
class EmberApp extends StatefulWidget {
  const EmberApp({
    super.key,
    this.artOverride,
    this.audioOverride,
    this.repositoryOverride,
    this.clockOverride,
    this.overlayBuilder,
  });

  /// Optional widget stacked ABOVE the app, INSIDE the module's ProviderScope —
  /// the standalone entry uses this for the debug scene picker. Production mounts
  /// leave it null.
  final WidgetBuilder? overlayBuilder;

  /// Optional art override (defaults to programmatic placeholder art).
  final EmberArt? artOverride;

  /// Optional audio override (defaults to a silent player so a fresh checkout
  /// runs without shipping clips; swap in audioplayers once assets exist).
  final EmberAudio? audioOverride;

  /// Optional repository override (defaults to the real Hive repo).
  final SaveRepository? repositoryOverride;

  /// Optional clock override (defaults to the system clock).
  final EmberClock? clockOverride;

  @override
  State<EmberApp> createState() => _EmberAppState();
}

class _EmberAppState extends State<EmberApp> {
  late final ProviderContainer _container;
  late final EmberLifecycleObserver _observer;
  late final Future<void> _ready;

  @override
  void initState() {
    super.initState();
    _container = ProviderContainer(
      overrides: <Override>[
        registryProvider.overrideWithValue(EmberRegistry.build()),
        saveRepositoryProvider.overrideWithValue(
          widget.repositoryOverride ?? HiveSaveRepository(),
        ),
        clockProvider.overrideWithValue(
          widget.clockOverride ?? const SystemClock(),
        ),
        // SPRITE-BACKED ART is the default now: the real flat sprite pack drives
        // the world visuals (terrain, placeables, nodes, player/elder/tribe,
        // placement ring), falling back to the programmatic placeholder for any
        // unmapped slot. The cache is preloaded in EmberGame.onLoad. A caller can
        // still inject [artOverride] (e.g. a test/headless PlaceholderEmberArt).
        artProvider.overrideWithValue(
          widget.artOverride ?? SpriteEmberArt(),
        ),
        audioProvider.overrideWithValue(
          widget.audioOverride ?? const SilentEmberAudio(),
        ),
      ],
    );
    _observer = _container.read(lifecycleObserverProvider);
    WidgetsBinding.instance.addObserver(_observer);
    _ready = _bootstrap();
  }

  Future<void> _bootstrap() async {
    // 1) Publish every leaf's push seams (no-op while stubbed).
    _container.read(_installProvider);
    // 2) Load the save + run offline catch-up to now.
    await _container.read(worldControllerProvider.notifier).bootstrap();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_observer);
    _container.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return UncontrolledProviderScope(
      container: _container,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Ember',
        theme: buildEmberTheme(),
        builder: widget.overlayBuilder == null
            ? null
            : (BuildContext context, Widget? child) {
                return Stack(
                  children: <Widget>[
                    if (child != null) child,
                    widget.overlayBuilder!(context),
                  ],
                );
              },
        home: FutureBuilder<void>(
          future: _ready,
          builder: (BuildContext context, AsyncSnapshot<void> snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const _BootSplash();
            }
            return const _EmberRoot();
          },
        ),
      ),
    );
  }
}

/// Chooses the first screen once bootstrap is done: site selection on first run,
/// the world thereafter. Watches the site-chosen flag so committing a site swaps
/// straight into the world without a manual route.
class _EmberRoot extends ConsumerWidget {
  const _EmberRoot();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool siteChosen = ref.watch(
      worldControllerProvider
          .select((s) => s.knowledge.get(WorldController.kSiteChosenFlag)),
    );
    if (!siteChosen) {
      return SiteSelectionScreen(
        // Choosing a site flips the flag; this widget rebuilds into the world.
        onChosen: () {},
      );
    }
    return const WorldScreen();
  }
}

/// A minimal boot splash shown while load + catch-up run.
class _BootSplash extends StatelessWidget {
  const _BootSplash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFE0C79B),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.local_fire_department,
                color: Color(0xFFF2873B), size: 64),
            SizedBox(height: 16),
            Text(
              'Ember',
              style: TextStyle(
                color: Color(0xFF3A2A1A),
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 24),
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Color(0xFFF2873B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
