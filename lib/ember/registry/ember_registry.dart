// Ember — registry/ember_registry.dart
//
// THE wiring file (and the ONLY file allowed to import the concept leaves). In
// this stage it is STUBBED: build() returns an EMPTY ConceptRegistry (no leaves
// imported yet) so the whole foundation runs to a seeded empty world — the build
// menu opens empty, no activities are registered, gathering is x1.0. The three
// leaves (fire / tools / shelter) are added in Step 4 at the marked spot.
//
// DIR-LOCK: until the leaves land this file imports NOTHING under concepts/. Each
// leaf is added as `<X>Module()` in [_modules] and nowhere else; the registry
// constructor (concept_registry.dart) flattens their content, and [installAll]
// runs each module's onInstall(ref) at bootstrap so cross-concept push-seams are
// published before the world is read.

import 'package:flutter_riverpod/flutter_riverpod.dart';

// ===========================================================================
// STEP 4 INSERTION POINT — leaf imports. All three leaves are wired now (fire,
// tools, shelter), in tech-tree order.
// ===========================================================================
import '../concepts/fire/fire_module.dart';
import '../concepts/shelter/shelter_module.dart';
import '../concepts/tools/tools_module.dart';
import '../contracts/concept_module.dart';
import '../registry/concept_registry.dart';

/// Constructs + installs the module's concept leaves. Pure assembly + the one
/// place that knows all three leaves; everything else stays leaf-blind.
class EmberRegistry {
  const EmberRegistry._();

  /// The concept modules shipped by the build, in tech-tree order. FIRE is wired
  /// now; tools + shelter land later (add them here as `ToolsModule()` /
  /// `ShelterModule()` once those leaves exist):
  /// ```dart
  /// return <ConceptModule>[
  ///   FireConceptModule(),
  ///   ToolsModule(),
  ///   ShelterModule(),
  /// ];
  /// ```
  static List<ConceptModule> _modules() => const <ConceptModule>[
        FireConceptModule(),
        ToolsConceptModule(),
        ShelterConceptModule(),
      ];

  /// Builds the concrete [ConceptRegistry] (which implements SimRegistry + the
  /// content lookups the UI reads). Safe to call before any leaf exists — an
  /// empty registry yields x1.0 gather, no defs, no activities, no resolvers.
  static ConceptRegistry build() => ConceptRegistry(_modules());

  /// Runs every module's onInstall(ref) so leaves publish their cross-concept
  /// push-seams (tool multipliers, population-cap sources, ...). No-op-safe when
  /// there are no modules. Call ONCE at bootstrap, after the container exists,
  /// before the first world read.
  static void installAll(Ref ref, ConceptRegistry registry) {
    for (final ConceptModule module in registry.modules) {
      module.onInstall(ref);
    }
  }
}
