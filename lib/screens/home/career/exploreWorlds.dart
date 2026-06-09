// "Explore by World" — the secondary discovery layer: broader domains, each
// grouping several professions. Full-bleed world portals with text overlaid at
// the bottom over a dark scrim.

import 'package:flutter/material.dart';
import '../../../utils/howwowEventLogger.dart';
import '../../../utils/howwowEventNames.dart';
import 'careerCommon.dart';
import 'careerModels.dart';
import 'careerTheme.dart';

class ExploreWorldsSection extends StatelessWidget {
  const ExploreWorldsSection({
    super.key,
    required this.worlds,
    this.onViewAll,
    this.onWorldTap,
  });

  final List<CareerWorld> worlds;
  final VoidCallback? onViewAll;
  final void Function(CareerWorld world)? onWorldTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: CareerSpace.page),
          child: SectionHeader(
            emoji: '🌎',
            title: 'Explore by World',
            actionLabel: 'View All Worlds',
            onAction: onViewAll ?? () => debugPrint('tap: view all worlds'),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 210,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: CareerSpace.page),
            itemCount: worlds.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, i) => RevealOnLoad(
              delay: Duration(milliseconds: 160 + i * 90),
              child: WorldCard(
                world: worlds[i],
                onTap: onWorldTap == null
                    ? null
                    : () => onWorldTap!(worlds[i]),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class WorldCard extends StatelessWidget {
  const WorldCard({super.key, required this.world, this.onTap});

  final CareerWorld world;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final w = world;

    return PressableScale(
      // Locked worlds swallow navigation but emit a telemetry event so we
      // can prioritise which worlds users keep tapping. Active worlds get
      // a world_tapped event; the debugPrint placeholder stays until the
      // world detail page lands.
      onTap: w.locked
          ? () => HowwowEventLogger.instance.logImmediate(
                HowwowEvents.lockedWorldTap,
                props: {'world_name': w.name},
              )
          : () {
              HowwowEventLogger.instance.log(
                HowwowEvents.worldTapped,
                props: {'world_name': w.name},
              );
              (onTap ?? () => debugPrint('tap: world ${w.name}'))();
            },
      child: SizedBox(
        width: 236,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(CareerRadii.smallCard),
            border: Border.all(color: CareerColors.glassBorder),
            boxShadow: [
              BoxShadow(
                color: w.locked
                    ? Colors.black.withValues(alpha: 0.28)
                    : w.accent.withValues(alpha: 0.28),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: IllustrationPanel(gradient: w.gradient, asset: w.asset),
              ),
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x00000000), Color(0x00000000), Color(0xD9000000)],
                      stops: [0.0, 0.35, 1.0],
                    ),
                  ),
                ),
              ),
              // separator line at the illustration / text seam
              Positioned(
                left: 16,
                right: 16,
                bottom: 96,
                child: Container(height: 1, color: Colors.white.withValues(alpha: 0.20)),
              ),
              // text block (left-aligned) below the separator
              Positioned(
                left: 14,
                right: 14,
                bottom: 8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(w.name, style: CareerText.cardTitleLg, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text('${w.professionCount} professions inside',
                        style: CareerText.worldLabel.copyWith(color: w.accent, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(w.sampleProfessions.join(' • '),
                        style: CareerText.body.copyWith(fontSize: 10.5, color: Colors.white70),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              // world icon — centered, straddling the separator line
              Positioned(
                left: 0,
                right: 0,
                bottom: 81,
                child: Center(child: IconBadge(icon: w.icon, color: w.accent, size: 30)),
              ),
              // Locked overlay — drawn LAST so it sits above everything else.
              if (w.locked) ...[
                Positioned.fill(
                  child: ColoredBox(color: Colors.black.withValues(alpha: 0.45)),
                ),
                const Positioned(top: 10, right: 10, child: LockBadge(size: 28)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
