// Ember — ui/build_menu/build_menu_sheet.dart
//
// The build menu: a bottom sheet listing the placeable defs the registry knows,
// with cost + affordability, that are UNLOCKED (the reducer records an unlock as
// the knowledge flag "unlock.<type>"). Tapping an affordable, unlocked entry
// fires [onBeginPlace] so the world screen kicks off the placement ghost — this
// sheet never touches the game/placement directly (stays UI-pure).
//
// While the registry is STUBBED the def list is empty, so the sheet shows a
// friendly "discover concepts to unlock building" empty state — the correct
// empty-foundation behaviour for this stage.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../art/ember_palette.dart';
import '../../contracts/placeable_def.dart';
import '../../core/enums.dart';
import '../../data/models/resource_cost.dart';
import '../../data/models/resource_stock.dart';
import '../../registry/concept_registry.dart';
import '../../state/providers.dart';
import '../../state/selectors.dart';
import '../../state/world_controller.dart';
import '../ember_theme.dart';
import '../widgets/ember_button.dart';

/// The build menu bottom sheet. Call [show] to present it.
class BuildMenuSheet extends ConsumerWidget {
  const BuildMenuSheet({super.key, required this.onBeginPlace});

  /// Fired with the chosen type when the player taps an affordable, unlocked
  /// entry (the world screen starts the placement ghost).
  final void Function(PlaceableType type) onBeginPlace;

  /// Presents the build menu as a modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required void Function(PlaceableType type) onBeginPlace,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext ctx) => BuildMenuSheet(onBeginPlace: onBeginPlace),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final EmberPalette p = ref.watch(artProvider).palette;
    final ConceptRegistry registry = ref.watch(registryProvider);
    final ResourceStock stock = ref.watch(resourceStockProvider);
    final Map<String, bool> flags = ref.watch(
      worldControllerProvider.select((s) => s.knowledge.flags),
    );

    // Only show defs the player has unlocked (flag "unlock.<type>").
    final List<PlaceableDef> unlocked = <PlaceableDef>[
      for (final PlaceableDef d in registry.placeableDefs)
        if (flags['unlock.${d.kind.name}'] ?? false) d,
    ];

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (BuildContext ctx, ScrollController scroll) {
        return Container(
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: p.outline, width: 1.5),
          ),
          child: Column(
            children: <Widget>[
              _grabber(p),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: EmberUi.gapL),
                child: Row(
                  children: <Widget>[
                    Icon(Icons.handyman_outlined, color: p.ember, size: 24),
                    const SizedBox(width: EmberUi.gapS),
                    Text(
                      'Build',
                      style: TextStyle(
                        color: p.ink,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: EmberUi.gapS),
              Expanded(
                child: unlocked.isEmpty
                    ? _emptyState(p)
                    : ListView.separated(
                        controller: scroll,
                        padding: const EdgeInsets.all(EmberUi.gapL),
                        itemCount: unlocked.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: EmberUi.gap),
                        itemBuilder: (BuildContext ctx, int i) {
                          final PlaceableDef def = unlocked[i];
                          return _BuildRow(
                            def: def,
                            palette: p,
                            affordable: stock.canAfford(def.cost),
                            onPick: () {
                              Navigator.of(ctx).pop();
                              onBeginPlace(def.kind);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _grabber(EmberPalette p) => Padding(
        padding: const EdgeInsets.symmetric(vertical: EmberUi.gap),
        child: Container(
          width: 44,
          height: 5,
          decoration: BoxDecoration(
            color: p.inkSoft,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      );

  Widget _emptyState(EmberPalette p) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(EmberUi.gapL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.lock_outline, color: p.inkSoft, size: 48),
            const SizedBox(height: EmberUi.gap),
            Text(
              'Nothing to build yet',
              style: TextStyle(
                color: p.ink,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: EmberUi.gapS),
            Text(
              'Discover new ideas to unlock things you can build.',
              textAlign: TextAlign.center,
              style: TextStyle(color: p.inkSoft, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _BuildRow extends StatelessWidget {
  const _BuildRow({
    required this.def,
    required this.palette,
    required this.affordable,
    required this.onPick,
  });

  final PlaceableDef def;
  final EmberPalette palette;
  final bool affordable;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final EmberPalette p = palette;
    return Container(
      padding: const EdgeInsets.all(EmberUi.gap),
      decoration: EmberUi.panel(p, raised: true),
      child: Row(
        children: <Widget>[
          Container(
            width: 46,
            height: 46,
            decoration: EmberUi.chip(p, fill: p.surfaceRaised),
            child: Icon(_iconFor(def.kind), color: p.ember, size: 26),
          ),
          const SizedBox(width: EmberUi.gap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  def.displayName,
                  style: TextStyle(
                    color: p.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                _costRow(def.cost, p),
              ],
            ),
          ),
          const SizedBox(width: EmberUi.gapS),
          EmberButton(
            label: 'Place',
            style: affordable
                ? EmberButtonStyle.primary
                : EmberButtonStyle.secondary,
            palette: p,
            onPressed: affordable ? onPick : null,
          ),
        ],
      ),
    );
  }

  Widget _costRow(ResourceCost cost, EmberPalette p) {
    if (cost.isEmpty) {
      return Text('Free', style: TextStyle(color: p.inkSoft, fontSize: 13));
    }
    return Wrap(
      spacing: 8,
      children: <Widget>[
        for (final ResourceType t in ResourceType.values)
          if (cost.amountOf(t) > 0)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(_resIcon(t), color: _resTint(t, p), size: 14),
                const SizedBox(width: 3),
                Text(
                  '${cost.amountOf(t)}',
                  style: TextStyle(
                    color: p.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
      ],
    );
  }

  IconData _iconFor(PlaceableType t) => switch (t) {
        PlaceableType.hearth ||
        PlaceableType.cookingFire =>
          Icons.local_fire_department,
        PlaceableType.torch => Icons.wb_incandescent_outlined,
        PlaceableType.brazier => Icons.whatshot,
        PlaceableType.knappingStation => Icons.construction,
        PlaceableType.toolRack => Icons.handyman,
        PlaceableType.leanTo => Icons.cabin,
        PlaceableType.hideTent => Icons.festival,
        PlaceableType.hut => Icons.home,
        PlaceableType.palisade => Icons.fence,
      };

  IconData _resIcon(ResourceType t) => switch (t) {
        ResourceType.wood => Icons.park,
        ResourceType.stone => Icons.terrain,
        ResourceType.food => Icons.local_florist,
        ResourceType.hide => Icons.layers,
      };

  Color _resTint(ResourceType t, EmberPalette p) => switch (t) {
        ResourceType.wood => p.wood,
        ResourceType.stone => p.rock,
        ResourceType.food => p.food,
        ResourceType.hide => p.hide,
      };
}
