// Ember — ui/hud/concept_tracker.dart
//
// The JOURNAL / quest-hint strip: one pill per concept showing its state (locked
// / ready-to-find / learned) so the kid knows WHAT to go discover next. It is no
// longer the launcher — the walk-up discovery NODES on the map start activities.
// For a ready concept it shows a "Find it" hint; tapping it calls back
// [onDiscover] (which the world screen now uses to NUDGE the player toward the
// glowing spot on the map, not to teleport into the activity). Reads the concept
// list + the registry; never touches the world or the game directly.
//
// COLLAPSIBLE: by default the tracker shows a single compact chip (the active /
// next concept, e.g. "Discover Fire") docked to the screen edge so the world
// render stays the hero and NPCs/village are not occluded. Tapping the chip
// expands the full list; tapping the header collapses it again. This addresses
// the "tracker covers the center of the world" finding.
//
// While the registry is STUBBED (no leaves), every concept shows as locked and
// no Discover prompt appears — exactly the empty-foundation state for this stage.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../art/ember_palette.dart';
import '../../contracts/concept_module.dart';
import '../../data/models/concept.dart';
import '../../registry/concept_registry.dart';
import '../../state/providers.dart';
import '../../state/world_controller.dart';
import '../ember_theme.dart';

/// The tech-tree availability strip. [onDiscover] is fired with an activity id
/// when the player taps a ready concept's Discover prompt.
class ConceptTracker extends ConsumerStatefulWidget {
  const ConceptTracker({super.key, required this.onDiscover});

  /// Called with the activity id to launch when a concept is discovered.
  final void Function(String activityId) onDiscover;

  @override
  ConsumerState<ConceptTracker> createState() => _ConceptTrackerState();
}

class _ConceptTrackerState extends ConsumerState<ConceptTracker> {
  /// Collapsed by default so the world stays the hero.
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final EmberPalette p = ref.watch(artProvider).palette;
    final List<Concept> concepts =
        ref.watch(worldControllerProvider.select((s) => s.concepts));
    final ConceptRegistry registry = ref.watch(registryProvider);

    return AnimatedSize(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topLeft,
      child: _expanded
          ? _buildExpanded(p, concepts, registry)
          : _buildCollapsed(p, concepts),
    );
  }

  // ---- Collapsed: a single chip for the active / next concept ----------

  Widget _buildCollapsed(EmberPalette p, List<Concept> concepts) {
    if (concepts.isEmpty) return const SizedBox.shrink();
    final Concept active = _activeConcept(concepts);
    final bool ready = active.unlocked && !active.completed;
    final (IconData icon, Color tint, String label) = active.completed
        ? (Icons.check_circle, p.success, 'All discovered')
        : ready
            ? (Icons.travel_explore, p.ember, 'Find ${active.name}')
            : (Icons.lock_outline, p.inkSoft, 'Next: ${active.name}');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(EmberUi.radius),
        onTap: () => setState(() => _expanded = true),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: EmberUi.panel(
            p,
            raised: true,
            border: ready ? p.ember : p.outline,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, color: tint, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: p.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.expand_more, color: p.inkSoft, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  /// The concept the player should focus on: the first ready-and-incomplete one,
  /// else the first incomplete one, else the last concept.
  Concept _activeConcept(List<Concept> concepts) {
    for (final Concept c in concepts) {
      if (c.unlocked && !c.completed) return c;
    }
    for (final Concept c in concepts) {
      if (!c.completed) return c;
    }
    return concepts.last;
  }

  // ---- Expanded: the full list -----------------------------------------

  Widget _buildExpanded(
    EmberPalette p,
    List<Concept> concepts,
    ConceptRegistry registry,
  ) {
    return Container(
      padding: const EdgeInsets.all(EmberUi.gapS),
      decoration: EmberUi.panel(p, raised: true),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(EmberUi.radiusS),
              onTap: () => setState(() => _expanded = false),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: <Widget>[
                    Icon(Icons.account_tree_outlined, color: p.ember, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'Discoveries',
                      style: TextStyle(
                        color: p.ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.expand_less, color: p.inkSoft, size: 18),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: EmberUi.gapS),
          for (final Concept c in concepts) ...<Widget>[
            _ConceptPill(
              concept: c,
              palette: p,
              registration: registry.activityForConcept(c.id),
              onDiscover: widget.onDiscover,
            ),
            if (c != concepts.last) const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

class _ConceptPill extends StatelessWidget {
  const _ConceptPill({
    required this.concept,
    required this.palette,
    required this.registration,
    required this.onDiscover,
  });

  final Concept concept;
  final EmberPalette palette;
  final ActivityRegistration? registration;
  final void Function(String activityId) onDiscover;

  @override
  Widget build(BuildContext context) {
    final EmberPalette p = palette;
    final bool ready =
        concept.unlocked && !concept.completed && registration != null;

    final (IconData icon, Color tint, String status) = concept.completed
        ? (Icons.check_circle, p.success, 'Learned')
        : concept.unlocked
            ? (Icons.explore_outlined, p.ember, 'Ready')
            : (Icons.lock_outline, p.inkSoft, 'Locked');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(EmberUi.radiusS),
        onTap: ready ? () => onDiscover(registration!.def.id) : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          decoration: EmberUi.chip(
            p,
            fill: concept.completed ? p.surface : p.surfaceRaised,
            border: ready ? p.ember : p.outline,
          ),
          child: Row(
            children: <Widget>[
              Icon(icon, color: tint, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  concept.name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: concept.unlocked ? p.ink : p.inkSoft,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (ready)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: p.ember,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Find it',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                )
              else
                Text(
                  status,
                  style: TextStyle(
                    color: tint,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
