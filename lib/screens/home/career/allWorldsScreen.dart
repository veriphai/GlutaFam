// "All Worlds" — the full world catalog, reached from the home page's
// "View All Worlds" action.
//
// Layout: cosmic backdrop + glass app bar + a vertical stack of full-width
// immersive "portal" cards (one per world). Each portal is a full-bleed
// illustration with a floating icon badge, a careers-count pill, sample
// profession chips and an Explore CTA. Tapping an unlocked world opens the
// All Jobs catalog pre-filtered to that world; locked worlds dim with a
// "Coming soon" pill and only emit telemetry.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../utils/howwowEventLogger.dart';
import '../../../utils/howwowEventNames.dart';
import 'allJobsScreen.dart';
import 'careerCommon.dart';
import 'careerModels.dart';
import 'careerTheme.dart';
import 'cosmicBackground.dart';

class AllWorldsScreen extends StatelessWidget {
  const AllWorldsScreen({
    super.key,
    required this.worlds,
    required this.professions,
    this.onProfessionTap,
  });

  final List<CareerWorld> worlds;

  /// Full profession catalog — handed to AllJobsScreen when a world portal
  /// is opened, so it can pre-filter to that world.
  final List<Profession> professions;
  final void Function(Profession profession)? onProfessionTap;

  static const double _maxContentWidth = 480;

  void _openWorld(BuildContext context, CareerWorld w) {
    HowwowEventLogger.instance.log(
      HowwowEvents.worldTapped,
      props: {'world_name': w.name, 'source': 'all_worlds'},
    );
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => AllJobsScreen(
        professions: professions,
        worlds: worlds,
        initialWorld: w.name,
        onProfessionTap: onProfessionTap,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final unlocked = worlds.where((w) => !w.locked).length;
    final careers =
        worlds.fold<int>(0, (sum, w) => sum + w.professionCount);

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: Scaffold(
        backgroundColor: CareerColors.bgMid,
        body: Stack(
          children: [
            const Positioned.fill(child: CosmicBackground()),
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _maxContentWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                            CareerSpace.page, 12, CareerSpace.page, 0),
                        child: RevealOnLoad(
                          child: SubpageAppBar(
                            emoji: '🌌',
                            title: 'Explore Worlds',
                            subtitle: unlocked == worlds.length
                                ? '${worlds.length} worlds • $careers careers inside'
                                : '$unlocked open now • ${worlds.length - unlocked} coming soon',
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(
                              CareerSpace.page, 18, CareerSpace.page, 28),
                          itemCount: worlds.length + 1,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 16),
                          itemBuilder: (context, i) {
                            if (i == worlds.length) {
                              return const Padding(
                                padding: EdgeInsets.only(top: 6),
                                child: ComingSoonFooter(
                                    emoji: '🪐',
                                    message:
                                        'More worlds are being built right now…'),
                              );
                            }
                            return RevealOnLoad(
                              delay: Duration(milliseconds: 80 + i * 110),
                              child: _WorldPortalCard(
                                world: worlds[i],
                                onExplore: () =>
                                    _openWorld(context, worlds[i]),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── world portal card ─────────────────────────────────────────────────

class _WorldPortalCard extends StatelessWidget {
  const _WorldPortalCard({required this.world, required this.onExplore});

  final CareerWorld world;
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    final w = world;

    return PressableScale(
      onTap: w.locked
          ? () => HowwowEventLogger.instance.logImmediate(
                HowwowEvents.lockedWorldTap,
                props: {'world_name': w.name, 'source': 'all_worlds'},
              )
          : onExplore,
      child: Container(
        height: 196,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(CareerRadii.card),
          border: Border.all(color: CareerColors.glassBorder),
          boxShadow: [
            BoxShadow(
              color: w.locked
                  ? Colors.black.withValues(alpha: 0.28)
                  : w.accent.withValues(alpha: 0.32),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(CareerRadii.card - 1),
          child: Stack(
            children: [
              Positioned.fill(
                child: IllustrationPanel(gradient: w.gradient, asset: w.asset),
              ),
              // bottom scrim for legibility + a faint accent wash from the
              // left so each portal carries its world colour
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x33000000),
                        Color(0x00000000),
                        Color(0xE6000000)
                      ],
                      stops: [0.0, 0.30, 1.0],
                    ),
                  ),
                ),
              ),
              // careers-count pill (top-left)
              Positioned(
                left: 14,
                top: 12,
                child: GlassSurface(
                  blur: true,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.workspace_premium_rounded,
                          size: 12, color: w.accent),
                      const SizedBox(width: 4),
                      Text(
                        '${w.professionCount} CAREERS',
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // floating world icon (top-right) — gentle idle bob
              Positioned(
                right: 16,
                top: 14,
                child: Floaty(
                  amplitude: 4,
                  child: IconBadge(icon: w.icon, color: w.accent, size: 38),
                ),
              ),
              // text block + CTA
              Positioned(
                left: 16,
                right: 16,
                bottom: 14,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(w.name,
                              style: GoogleFonts.poppins(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1.1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 5,
                            runSpacing: 5,
                            children: [
                              for (final name
                                  in w.sampleProfessions.take(3))
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: CareerColors.glassFillStrong,
                                    borderRadius: BorderRadius.circular(
                                        CareerRadii.chip),
                                    border: Border.all(
                                        color: CareerColors.glassBorder),
                                  ),
                                  child: Text(
                                    name,
                                    style: CareerText.chip
                                        .copyWith(fontSize: 9.5),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (!w.locked) _ExploreCta(accent: w.accent),
                  ],
                ),
              ),
              // Locked overlay — drawn LAST so it dims everything beneath.
              if (w.locked) ...[
                Positioned.fill(
                  child:
                      ColoredBox(color: Colors.black.withValues(alpha: 0.45)),
                ),
                const Positioned(top: 12, right: 14, child: LockBadge(size: 28)),
                Positioned(
                  right: 14,
                  bottom: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(CareerRadii.pill),
                      border: Border.all(
                          color: CareerColors.gold.withValues(alpha: 0.55)),
                    ),
                    child: Text(
                      'COMING SOON',
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: CareerColors.gold,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ExploreCta extends StatelessWidget {
  const _ExploreCta({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent, Color.lerp(accent, Colors.black, 0.30)!],
        ),
        borderRadius: BorderRadius.circular(CareerRadii.pill),
        border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
        boxShadow: [
          BoxShadow(
              color: accent.withValues(alpha: 0.5),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Explore',
              style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          const SizedBox(width: 2),
          const Icon(Icons.chevron_right_rounded,
              size: 16, color: Colors.white),
        ],
      ),
    );
  }
}
