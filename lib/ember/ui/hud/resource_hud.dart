// Ember — ui/hud/resource_hud.dart
//
// The top resource bar: one chip per [ResourceType] showing amount / cap with a
// low-stock warning tint, a surplus accent, and a thin "how full" progress fill
// behind the numbers so a 7-year-old reads fullness visually (not as a
// fraction). Watches the stock selector so it rebuilds only when the stockpile
// changes. Self-contained styling (EmberUi + palette); reads state through
// Riverpod selectors only (no world mutation).
//
// LAYOUT: the bar lays its four chips out with [Wrap] so they NEVER overflow on
// a narrow phone — if all four can't sit on one line they flow to a second line
// rather than clipping (the old min-width Row clipped Stone + Hide). The world
// screen gives the bar a full-width line of its own.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../art/ember_palette.dart';
import '../../core/enums.dart';
import '../../data/models/resource_stock.dart';
import '../../state/providers.dart';
import '../../state/selectors.dart';
import '../ember_theme.dart';

/// The horizontal resource bar shown along the top of the world screen.
class ResourceHud extends ConsumerWidget {
  const ResourceHud({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final EmberPalette p = ref.watch(artProvider).palette;
    final ResourceStock stock = ref.watch(resourceStockProvider);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: EmberUi.gapS, vertical: EmberUi.gapS),
      decoration: EmberUi.panel(p, raised: true),
      // Wrap (not a min-width Row): the chips flow to a second line on a narrow
      // phone instead of overflowing — all four resources are always visible.
      child: Wrap(
        spacing: EmberUi.gapS,
        runSpacing: 6,
        children: <Widget>[
          for (final ResourceType t in ResourceType.values)
            _ResourceChip(type: t, line: stock.lineOf(t), palette: p),
        ],
      ),
    );
  }
}

class _ResourceChip extends StatefulWidget {
  const _ResourceChip({
    required this.type,
    required this.line,
    required this.palette,
  });

  final ResourceType type;
  final StockLine line;
  final EmberPalette palette;

  @override
  State<_ResourceChip> createState() => _ResourceChipState();
}

class _ResourceChipState extends State<_ResourceChip>
    with SingleTickerProviderStateMixin {
  // A slow "breathing" pulse used to glow a chip when it hits full cap (surplus)
  // — a small celebratory cue that the stockpile is brimming. Created + started in
  // initState (NOT a field initializer): a field initializer runs at construction,
  // before the element is mounted/has dependencies, so `vsync: this` + repeat()
  // triggers a TickerMode ancestor lookup that throws "deactivated widget's
  // ancestor is unsafe" on teardown. initState runs after mount, which is safe.
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ResourceType type = widget.type;
    final StockLine line = widget.line;
    final EmberPalette palette = widget.palette;
    final (IconData icon, Color tint) = switch (type) {
      ResourceType.wood => (Icons.park, palette.wood),
      ResourceType.stone => (Icons.terrain, palette.rock),
      ResourceType.food => (Icons.local_florist, palette.food),
      ResourceType.hide => (Icons.layers, palette.hide),
    };
    final bool low = line.isLow;
    final bool full = line.isFull;
    final Color border = low
        ? palette.danger
        : full
            ? palette.success
            : palette.outline;
    final double fillFrac =
        line.cap <= 0 ? 0.0 : (line.amount / line.cap).clamp(0.0, 1.0);
    final Color fillColor = (low
            ? palette.danger
            : full
                ? palette.success
                : tint)
        .withValues(alpha: 0.20);

    final Widget chip = ClipRRect(
      borderRadius: BorderRadius.circular(EmberUi.radiusS),
      child: Stack(
        children: <Widget>[
          // "How full" progress fill behind the chip content.
          Positioned.fill(
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: fillFrac,
              child: ColoredBox(color: fillColor),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: EmberUi.chip(
              palette,
              // Transparent fill so the progress band shows through; the chip's
              // own surface is drawn as a faint base behind the fill.
              fill: palette.surface.withValues(alpha: 0.55),
              border: border,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(icon, color: tint, size: 18),
                const SizedBox(width: 6),
                Text(
                  '${line.amount}',
                  style: TextStyle(
                    color: low ? palette.danger : palette.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '/${line.cap}',
                  style: TextStyle(
                    // Bumped from 11/inkSoft to 13/ink-derived so the cap is
                    // legible for young kids.
                    color: palette.ink.withValues(alpha: 0.65),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (low) ...<Widget>[
                  const SizedBox(width: 4),
                  Icon(Icons.warning_amber_rounded,
                      color: palette.danger, size: 16),
                ],
                if (full && !low) ...<Widget>[
                  const SizedBox(width: 4),
                  Icon(Icons.check_circle, color: palette.success, size: 15),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    // When a resource is brimming (surplus), wrap the chip in a softly pulsing
    // success glow so a full stockpile reads as a small reward, not an alert.
    if (!full || low) return chip;
    return AnimatedBuilder(
      animation: _pulse,
      builder: (BuildContext context, Widget? child) {
        final double t = 0.35 + 0.45 * _pulse.value;
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(EmberUi.radiusS),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: palette.success.withValues(alpha: 0.55 * t),
                blurRadius: 8 + 6 * t,
                spreadRadius: 0.5,
              ),
            ],
          ),
          child: child,
        );
      },
      child: chip,
    );
  }
}
