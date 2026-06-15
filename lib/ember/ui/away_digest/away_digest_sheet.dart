// Ember — ui/away_digest/away_digest_sheet.dart
//
// The "while you were away" summary. After bootstrap/resume runs the offline
// catch-up, the controller stamps an [AwayDigest] into awayDigestProvider; the
// world screen watches that and presents this sheet once, then clears it on
// dismiss. Shows how long passed (capped at 12h), how many things happened, and
// one line per event (flood / predator / storm / cold) with a severity tint.
//
// Reads the digest provider; the only state it touches is clearing the digest on
// dismiss (a UI-state provider, not the world).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../art/ember_palette.dart';
import '../../core/enums.dart';
import '../../sim/away_digest.dart';
import '../../state/providers.dart';
import '../../state/world_controller.dart';
import '../ember_theme.dart';
import '../widgets/ember_button.dart';

/// Watches the away digest and shows the summary sheet exactly once.
class AwayDigestHost extends ConsumerStatefulWidget {
  const AwayDigestHost({super.key});

  @override
  ConsumerState<AwayDigestHost> createState() => _AwayDigestHostState();
}

class _AwayDigestHostState extends ConsumerState<AwayDigestHost> {
  bool _showing = false;

  @override
  Widget build(BuildContext context) {
    final AwayDigest? digest = ref.watch(awayDigestProvider);
    if (digest != null && !digest.isEmpty && !_showing) {
      _showing = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _present(digest));
    }
    return const SizedBox.shrink();
  }

  Future<void> _present(AwayDigest digest) async {
    final EmberPalette p = ref.read(artProvider).palette;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext ctx) => AwayDigestSheet(digest: digest, palette: p),
    );
    // Clear the digest so it doesn't re-present, and re-arm for the next resume.
    if (mounted) {
      ref.read(awayDigestProvider.notifier).state = null;
      _showing = false;
    }
  }
}

/// The summary card itself.
class AwayDigestSheet extends StatelessWidget {
  const AwayDigestSheet({
    super.key,
    required this.digest,
    this.palette = EmberPalette.dusk,
  });

  final AwayDigest digest;
  final EmberPalette palette;

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
              Row(
                children: <Widget>[
                  Icon(Icons.schedule, color: p.ember, size: 26),
                  const SizedBox(width: EmberUi.gapS),
                  Text(
                    'While you were away',
                    style: TextStyle(
                      color: p.ink,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: EmberUi.gapS),
              Text(
                _elapsedLine(),
                style: TextStyle(color: p.inkSoft, fontSize: 14),
              ),
              if (digest.wasCapped)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    "(We only catch up the last 12 hours.)",
                    style: TextStyle(color: p.inkSoft, fontSize: 12),
                  ),
                ),
              const SizedBox(height: EmberUi.gap),
              if (digest.hasEvents)
                ...<Widget>[
                  for (final AwayDigestLine line in digest.lines) ...<Widget>[
                    _eventRow(p, line),
                    const SizedBox(height: EmberUi.gapS),
                  ],
                ]
              else
                Container(
                  padding: const EdgeInsets.all(EmberUi.gap),
                  decoration: EmberUi.chip(p, fill: p.surface),
                  child: Row(
                    children: <Widget>[
                      Icon(Icons.check_circle_outline,
                          color: p.success, size: 20),
                      const SizedBox(width: EmberUi.gapS),
                      Expanded(
                        child: Text(
                          'All quiet. Your village rested peacefully.',
                          style: TextStyle(
                            color: p.ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: EmberUi.gap),
              EmberButton(
                label: 'Continue',
                icon: Icons.play_arrow_rounded,
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

  String _elapsedLine() {
    final int ms = digest.cappedElapsedMs > 0
        ? digest.cappedElapsedMs
        : digest.elapsedMs;
    final Duration d = Duration(milliseconds: ms);
    if (d.inHours >= 1) {
      final int h = d.inHours;
      final int m = d.inMinutes % 60;
      return 'You were gone for ${h}h${m > 0 ? ' ${m}m' : ''}.';
    }
    if (d.inMinutes >= 1) {
      return 'You were gone for ${d.inMinutes} min.';
    }
    return 'You were gone briefly.';
  }

  Widget _eventRow(EmberPalette p, AwayDigestLine line) {
    final (IconData icon, Color tint) = switch (line.type) {
      WorldEventType.flood => (Icons.water, p.water),
      WorldEventType.nightPredator => (Icons.pets, p.danger),
      WorldEventType.storm => (Icons.thunderstorm, p.cold),
      WorldEventType.coldNight => (Icons.ac_unit, p.cold),
      WorldEventType.hunt => (Icons.restaurant, p.food),
    };
    final Color border = line.severity >= 0.6
        ? p.danger
        : line.severity >= 0.3
            ? p.warning
            : p.outline;
    return Container(
      padding: const EdgeInsets.all(EmberUi.gap),
      decoration: EmberUi.chip(p, fill: p.surface, border: border),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: tint, size: 22),
          const SizedBox(width: EmberUi.gapS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  line.headline,
                  style: TextStyle(
                    color: p.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (line.detail.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    line.detail,
                    style: TextStyle(color: p.inkSoft, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
