// Ember — ui/codex/codex_screen.dart
//
// The codex browser: a scrollable list of every knowledge card the registry
// ships, grouped by concept, each shown LOCKED (a teaser) until the player has
// unlocked it (the reducer records that as the knowledge flag "codex.<id>").
// Tapping an unlocked entry opens its detail (discovery story / science /
// history) plus the concept's myth->evidence model-upgrade card.
//
// Reads the registry (content) + the world's knowledge flags (what's unlocked).
// Never mutates. While the registry is STUBBED the list is empty and a friendly
// empty state is shown — the correct empty-foundation behaviour for this stage.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../activity/apply_reducer.dart';
import '../../art/ember_palette.dart';
import '../../contracts/codex_entry.dart';
import '../../contracts/concept_module.dart';
import '../../core/enums.dart';
import '../../registry/concept_registry.dart';
import '../../state/providers.dart';
import '../../state/world_controller.dart';
import '../ember_theme.dart';
import '../widgets/ember_button.dart';
import 'model_upgrade_card.dart';

/// The full-screen codex browser + detail.
class CodexScreen extends ConsumerWidget {
  const CodexScreen({super.key, this.initialEntryId});

  /// If set, the screen opens directly on this entry's detail (when unlocked).
  final String? initialEntryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final EmberPalette p = ref.watch(artProvider).palette;
    final ConceptRegistry registry = ref.watch(registryProvider);
    final Map<String, bool> flags = ref.watch(
      worldControllerProvider.select((s) => s.knowledge.flags),
    );

    final List<CodexEntry> entries = registry.codexEntries;

    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
        backgroundColor: p.surface,
        foregroundColor: p.ink,
        title: const Text('Codex',
            style: TextStyle(fontWeight: FontWeight.w800)),
        elevation: 0,
      ),
      body: entries.isEmpty
          ? _emptyState(p)
          : ListView(
              padding: const EdgeInsets.all(EmberUi.gapL),
              children: <Widget>[
                for (final ConceptId cid in _conceptOrder(entries))
                  ..._conceptSection(
                    context,
                    ref,
                    p,
                    registry,
                    flags,
                    cid,
                  ),
              ],
            ),
    );
  }

  List<ConceptId> _conceptOrder(List<CodexEntry> entries) {
    final List<ConceptId> order = <ConceptId>[];
    for (final CodexEntry e in entries) {
      if (!order.contains(e.concept)) order.add(e.concept);
    }
    return order;
  }

  List<Widget> _conceptSection(
    BuildContext context,
    WidgetRef ref,
    EmberPalette p,
    ConceptRegistry registry,
    Map<String, bool> flags,
    ConceptId cid,
  ) {
    final List<CodexEntry> entries = <CodexEntry>[
      for (final CodexEntry e in registry.codexEntries)
        if (e.concept == cid) e,
    ];
    return <Widget>[
      Padding(
        padding: const EdgeInsets.only(bottom: EmberUi.gapS, top: EmberUi.gap),
        child: Text(
          _conceptLabel(cid),
          style: TextStyle(
            color: p.ember,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      for (final CodexEntry e in entries) ...<Widget>[
        _entryTile(
          context,
          ref,
          p,
          registry,
          e,
          unlocked: flags['$kCodexFlagPrefix${e.id}'] ?? e.unlocked,
        ),
        const SizedBox(height: EmberUi.gapS),
      ],
    ];
  }

  Widget _entryTile(
    BuildContext context,
    WidgetRef ref,
    EmberPalette p,
    ConceptRegistry registry,
    CodexEntry entry, {
    required bool unlocked,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(EmberUi.radius),
        onTap: unlocked
            ? () => _openDetail(context, ref, p, registry, entry)
            : null,
        child: Container(
          padding: const EdgeInsets.all(EmberUi.gap),
          decoration: EmberUi.panel(p, raised: unlocked),
          child: Row(
            children: <Widget>[
              Icon(
                unlocked ? Icons.menu_book : Icons.lock_outline,
                color: unlocked ? p.ember : p.inkSoft,
                size: 26,
              ),
              const SizedBox(width: EmberUi.gap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      unlocked ? entry.title : 'Locked',
                      style: TextStyle(
                        color: unlocked ? p.ink : p.inkSoft,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (unlocked) ...<Widget>[
                      const SizedBox(height: 2),
                      Text(
                        entry.discoveryStory,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: p.inkSoft, fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ),
              if (unlocked)
                Icon(Icons.chevron_right, color: p.inkSoft, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  void _openDetail(
    BuildContext context,
    WidgetRef ref,
    EmberPalette p,
    ConceptRegistry registry,
    CodexEntry entry,
  ) {
    final ModelUpgrade? upgrade = _upgradeFor(registry, entry.concept);
    final bool upgraded = upgrade != null &&
        (ref.read(worldControllerProvider).knowledge.get(upgrade.flag));
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext ctx) => _CodexDetail(
          entry: entry,
          upgrade: upgrade,
          upgraded: upgraded,
          palette: p,
        ),
      ),
    );
  }

  /// Flattens model upgrades from the modules (the registry keeps them per-leaf).
  ModelUpgrade? _upgradeFor(ConceptRegistry registry, ConceptId cid) {
    for (final ConceptModule m in registry.modules) {
      for (final ModelUpgrade u in m.modelUpgrades) {
        if (u.concept == cid) return u;
      }
    }
    return null;
  }

  Widget _emptyState(EmberPalette p) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(EmberUi.gapL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.auto_stories_outlined, color: p.inkSoft, size: 52),
            const SizedBox(height: EmberUi.gap),
            Text(
              'Your codex is empty',
              style: TextStyle(
                color: p.ink,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: EmberUi.gapS),
            Text(
              'Discover ideas in your village to fill these pages.',
              textAlign: TextAlign.center,
              style: TextStyle(color: p.inkSoft, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  String _conceptLabel(ConceptId cid) => switch (cid) {
        ConceptId.fire => 'Fire',
        ConceptId.stoneTools => 'Stone Tools',
        ConceptId.shelter => 'Shelter',
      };
}

/// The entry detail page (discovery story / science / history + upgrade card).
class _CodexDetail extends StatelessWidget {
  const _CodexDetail({
    required this.entry,
    required this.upgrade,
    required this.upgraded,
    required this.palette,
  });

  final CodexEntry entry;
  final ModelUpgrade? upgrade;
  final bool upgraded;
  final EmberPalette palette;

  @override
  Widget build(BuildContext context) {
    final EmberPalette p = palette;
    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
        backgroundColor: p.surface,
        foregroundColor: p.ink,
        title: Text(entry.title,
            style: const TextStyle(fontWeight: FontWeight.w800)),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(EmberUi.gapL),
        children: <Widget>[
          if (upgrade != null) ...<Widget>[
            ModelUpgradeCard(
              upgrade: upgrade!,
              revealed: upgraded,
              palette: p,
            ),
            const SizedBox(height: EmberUi.gapL),
          ],
          _section(p, Icons.explore, 'How we found out', entry.discoveryStory),
          const SizedBox(height: EmberUi.gap),
          _section(p, Icons.science_outlined, 'The science', entry.science),
          const SizedBox(height: EmberUi.gap),
          _section(p, Icons.history_edu_outlined, 'Real history', entry.history),
          const SizedBox(height: EmberUi.gapL),
          EmberButton(
            label: 'Back to codex',
            style: EmberButtonStyle.secondary,
            palette: p,
            expand: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _section(EmberPalette p, IconData icon, String title, String body) {
    return Container(
      padding: const EdgeInsets.all(EmberUi.gap),
      decoration: EmberUi.panel(p, raised: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, color: p.ember, size: 20),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: p.ember,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: EmberUi.gapS),
          Text(
            body,
            style: TextStyle(
              color: p.ink,
              fontSize: 15,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
