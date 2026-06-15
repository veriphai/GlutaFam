// Ember — ui/codex/model_upgrade_card.dart
//
// The myth -> evidence "before / after" card. Renders a [ModelUpgrade]: the old
// belief struck through on the left, the evidence-based belief glowing on the
// right, with an arrow between. When the upgrade has not yet been applied (the
// concept's activity isn't done), it shows a muted, blurred "discover to reveal"
// state instead of spoiling the answer. Pure UI.

import 'package:flutter/material.dart';

import '../../art/ember_palette.dart';
import '../../contracts/codex_entry.dart';
import '../ember_theme.dart';

/// A before/after belief-shift card for a [ModelUpgrade].
class ModelUpgradeCard extends StatelessWidget {
  const ModelUpgradeCard({
    super.key,
    required this.upgrade,
    required this.revealed,
    this.palette = EmberPalette.dusk,
  });

  final ModelUpgrade upgrade;

  /// Whether the upgrade has been applied (else show the locked teaser).
  final bool revealed;
  final EmberPalette palette;

  @override
  Widget build(BuildContext context) {
    final EmberPalette p = palette;
    return Container(
      padding: const EdgeInsets.all(EmberUi.gap),
      decoration: EmberUi.panel(p, raised: true),
      child: revealed ? _revealed(p) : _locked(p),
    );
  }

  Widget _revealed(EmberPalette p) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: _belief(
            p,
            label: 'We thought',
            body: upgrade.mythBelief,
            tint: p.inkSoft,
            strike: true,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: EmberUi.gapS),
          child: Icon(Icons.arrow_forward, color: p.ember, size: 22),
        ),
        Expanded(
          child: _belief(
            p,
            label: 'Now we know',
            body: upgrade.evidenceBelief,
            tint: p.success,
            strike: false,
          ),
        ),
      ],
    );
  }

  Widget _belief(
    EmberPalette p, {
    required String label,
    required String body,
    required Color tint,
    required bool strike,
  }) {
    return Container(
      padding: const EdgeInsets.all(EmberUi.gapS),
      decoration: EmberUi.chip(p, fill: p.surface, border: tint),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(
              color: tint,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: TextStyle(
              color: p.ink,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.3,
              decoration:
                  strike ? TextDecoration.lineThrough : TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }

  Widget _locked(EmberPalette p) {
    return Row(
      children: <Widget>[
        Icon(Icons.lock_outline, color: p.inkSoft, size: 22),
        const SizedBox(width: EmberUi.gapS),
        Expanded(
          child: Text(
            'Discover this idea to reveal what we learned.',
            style: TextStyle(
              color: p.inkSoft,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
