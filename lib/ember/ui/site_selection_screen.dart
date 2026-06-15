// Ember — ui/site_selection_screen.dart
//
// The first-run, consequential decision: WHERE to plant the village. We surface a
// handful of candidate sites drawn from the seeded map — high ground (flood-safe,
// far from water), riverbank (fertile but flood-prone), and a balanced grassland
// — and let the player weigh the trade-off. Picking one writes Village.siteTile
// (via WorldController.setSiteTile) and marks the choice made, then calls
// [onChosen] so the app routes into the world.
//
// Reads the seeded tiles to score candidates; the only mutation is the site
// decision through the controller (a foundation method, not a leaf concern).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../art/ember_palette.dart';
import '../core/enums.dart';
import '../core/geometry.dart';
import '../data/models/tile.dart';
import '../data/models/world_state.dart';
import '../state/providers.dart';
import '../state/world_controller.dart';
import 'ember_theme.dart';
import 'widgets/ember_button.dart';
import 'widgets/site_thumbnail.dart';

/// A scored candidate village site.
class _SiteCandidate {
  const _SiteCandidate({
    required this.coord,
    required this.title,
    required this.blurb,
    required this.floodRisk,
    required this.terrain,
    required this.icon,
  });

  final GridCoord coord;
  final String title;
  final String blurb;
  final double floodRisk;
  final TerrainType terrain;
  final IconData icon;
}

/// The first-run site selection flow.
class SiteSelectionScreen extends ConsumerStatefulWidget {
  const SiteSelectionScreen({super.key, required this.onChosen});

  /// Called after the site is committed (the app routes into the world).
  final VoidCallback onChosen;

  @override
  ConsumerState<SiteSelectionScreen> createState() =>
      _SiteSelectionScreenState();
}

class _SiteSelectionScreenState extends ConsumerState<SiteSelectionScreen> {
  GridCoord? _selected;

  @override
  Widget build(BuildContext context) {
    final EmberPalette p = ref.watch(artProvider).palette;
    final EmberWorldState s = ref.watch(worldControllerProvider);
    final List<_SiteCandidate> candidates = _candidatesFor(s);

    return Scaffold(
      backgroundColor: p.background,
      body: Stack(
        children: <Widget>[
          // A warm, inviting backdrop: a soft sky gradient with a low ember glow
          // at the horizon so the first decision screen feels like dawn over the
          // valley rather than a plain form.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    Color.lerp(p.background, Colors.white, 0.25)!,
                    p.background,
                    p.backgroundDeep,
                  ],
                  stops: const <double>[0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.0, -0.7),
                  radius: 1.1,
                  colors: <Color>[
                    p.emberBright.withValues(alpha: 0.22),
                    p.ember.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(EmberUi.gapL),
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: EmberUi.gap),
              Text(
                'Where will we settle?',
                style: TextStyle(
                  color: p.ink,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: EmberUi.gapS),
              Text(
                'Choose your village site. Land near water is fertile but '
                'floods; high ground is safe but plain. Choose well.',
                style: TextStyle(color: p.inkSoft, fontSize: 15, height: 1.4),
              ),
              const SizedBox(height: EmberUi.gapL),
              Expanded(
                child: ListView.separated(
                  itemCount: candidates.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: EmberUi.gap),
                  itemBuilder: (BuildContext ctx, int i) {
                    final _SiteCandidate c = candidates[i];
                    return _SiteCard(
                      candidate: c,
                      palette: p,
                      selected: _selected == c.coord,
                      onTap: () => setState(() => _selected = c.coord),
                    );
                  },
                ),
              ),
              const SizedBox(height: EmberUi.gap),
              // The CTA is clearly DISABLED (greyed secondary + hint) until a
              // site is picked, then snaps to a full-orange primary so it reads
              // as obviously tappable (was a pale peach that looked half-on).
              if (_selected == null)
                EmberButton(
                  label: 'Pick a site to settle',
                  icon: Icons.touch_app_outlined,
                  palette: p,
                  expand: true,
                  style: EmberButtonStyle.secondary,
                  // No onPressed -> disabled look.
                )
              else
                EmberButton(
                  label: 'Settle here',
                  icon: Icons.flag,
                  palette: p,
                  expand: true,
                  onPressed: () {
                    ref
                        .read(worldControllerProvider.notifier)
                        .setSiteTile(_selected!);
                    widget.onChosen();
                  },
                ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds three candidate sites from the seeded map: a flood-safe high spot,
  /// a fertile-but-risky riverbank, and a balanced grassland near the centre.
  List<_SiteCandidate> _candidatesFor(EmberWorldState s) {
    final GridCoord highGround =
        _firstTileWhere(s, (Tile t) => t.terrain == TerrainType.highGround) ??
            const GridCoord(13, 2);
    final GridCoord riverbank = _firstTileWhere(
          s,
          (Tile t) =>
              t.terrain == TerrainType.grass &&
              t.buildable &&
              t.floodRisk >= 0.6,
        ) ??
        const GridCoord(7, 5);
    final GridCoord balanced = s.village.siteTile;

    return <_SiteCandidate>[
      _SiteCandidate(
        coord: highGround,
        title: 'The High Ground',
        blurb: 'Safe from floods, but far from the richest land.',
        floodRisk: s.tiles.at(highGround)?.floodRisk ?? 0.0,
        terrain:
            s.tiles.at(highGround)?.terrain ?? TerrainType.highGround,
        icon: Icons.landscape,
      ),
      _SiteCandidate(
        coord: balanced,
        title: 'The Grassland',
        blurb: 'A balanced spot near the heart of the valley.',
        floodRisk: s.tiles.at(balanced)?.floodRisk ?? 0.1,
        terrain: s.tiles.at(balanced)?.terrain ?? TerrainType.grass,
        icon: Icons.grass,
      ),
      _SiteCandidate(
        coord: riverbank,
        title: 'The Riverbank',
        blurb: 'Fertile and close to water — but the river can rise.',
        floodRisk: s.tiles.at(riverbank)?.floodRisk ?? 0.7,
        terrain: s.tiles.at(riverbank)?.terrain ?? TerrainType.grass,
        icon: Icons.water,
      ),
    ];
  }

  GridCoord? _firstTileWhere(EmberWorldState s, bool Function(Tile) test) {
    for (final Tile t in s.tiles.tiles) {
      if (test(t)) return t.coord;
    }
    return null;
  }
}

class _SiteCard extends StatelessWidget {
  const _SiteCard({
    required this.candidate,
    required this.palette,
    required this.selected,
    required this.onTap,
  });

  final _SiteCandidate candidate;
  final EmberPalette palette;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final EmberPalette p = palette;
    final (String riskLabel, Color riskTint) = candidate.floodRisk >= 0.6
        ? ('High flood risk', p.danger)
        : candidate.floodRisk >= 0.3
            ? ('Some flood risk', p.warning)
            : ('Flood-safe', p.success);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(EmberUi.radius),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(EmberUi.gap),
          decoration: EmberUi.panel(
            p,
            raised: true,
            border: selected ? p.ember : p.outline,
            fill: selected ? p.surfaceRaised : p.surface,
          ),
          child: Row(
            children: <Widget>[
              // A small iso preview of the site (terrain + how close the river
              // is), so kids see PLACE, not just an abstract icon.
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(EmberMetrics.chipRadius),
                  border: Border.all(color: p.outline, width: 1.2),
                ),
                child: SiteThumbnail(
                  terrain: candidate.terrain,
                  floodRisk: candidate.floodRisk,
                  palette: p,
                  size: 58,
                ),
              ),
              const SizedBox(width: EmberUi.gap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      candidate.title,
                      style: TextStyle(
                        color: p.ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      candidate.blurb,
                      style: TextStyle(
                        color: p.inkSoft,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: riskTint.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        riskLabel,
                        style: TextStyle(
                          color: riskTint,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle, color: p.ember, size: 26),
            ],
          ),
        ),
      ),
    );
  }
}
