// "Try an Amazing Job" — the primary discovery layer: a horizontally
// scrollable row of profession cards, the first flagged as recommended.
//
// Each card is a full-bleed illustration (gradient placeholder until a real
// asset is supplied) with an icon badge + title/world/description overlaid at
// the bottom over a dark scrim.

import 'package:flutter/material.dart';
import '../../../utils/howwowEventLogger.dart';
import '../../../utils/howwowEventNames.dart';
import 'careerCommon.dart';
import 'careerModels.dart';
import 'careerTheme.dart';

class FeaturedProfessionsSection extends StatelessWidget {
  const FeaturedProfessionsSection({
    super.key,
    required this.professions,
    this.onProfessionTap,
    this.onViewAll,
  });

  final List<Profession> professions;
  final void Function(Profession profession)? onProfessionTap;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: CareerSpace.page),
          child: SectionHeader(
            emoji: '⭐',
            title: 'Try an Amazing Job',
            actionLabel: 'View All Jobs',
            onAction: onViewAll ?? () => debugPrint('tap: view all jobs'),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 230,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: CareerSpace.page),
            itemCount: professions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, i) => RevealOnLoad(
              delay: Duration(milliseconds: 120 + i * 90),
              child: ProfessionCard(
                profession: professions[i],
                onTap: onProfessionTap == null
                    ? null
                    : () => onProfessionTap!(professions[i]),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ProfessionCard extends StatelessWidget {
  const ProfessionCard({super.key, required this.profession, this.onTap});

  final Profession profession;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = profession;

    return PressableScale(
      // Locked cards swallow navigation but still emit a telemetry event
      // — knowing WHICH locked careers users keep tapping is the strongest
      // signal for what to build next.
      onTap: p.locked
          ? () => HowwowEventLogger.instance.logImmediate(
                HowwowEvents.lockedProfessionTap,
                props: {'profession_name': p.name},
              )
          : () {
              HowwowEventLogger.instance.log(
                HowwowEvents.professionTapped,
                props: {
                  'profession_name': p.name,
                  'recommended': p.recommended,
                  'source': 'rail',
                },
              );
              (onTap ?? () => debugPrint('tap: profession ${p.name}'))();
            },
      child: SizedBox(
        width: 150,
        // Note: do NOT combine `clipBehavior: Clip.antiAlias` with a
        // `border` on the same Container — Flutter's clip cuts INTO the
        // border at the corners (you can see it as black notches on the
        // gold "recommended" frame). Split it into two layers: the outer
        // Container draws the border + shadow, an inner ClipRRect with
        // a slightly-smaller radius (= outer radius − border width) clips
        // the children inside that border. Same visual, no corner notches.
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(CareerRadii.smallCard),
            border: Border.all(
              color: p.recommended ? CareerColors.gold : CareerColors.glassBorder,
              width: p.recommended ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                // Mute the glow for locked cards so the row reads as "one
                // active, others coming soon" instead of all equally lit.
                color: p.locked
                    ? Colors.black.withValues(alpha: 0.30)
                    : (p.recommended ? CareerColors.gold : p.accent).withValues(alpha: 0.30),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(
              CareerRadii.smallCard - (p.recommended ? 2 : 1),
            ),
            child: Stack(
            children: [
              // full-bleed illustration (real asset; gradient is the fallback)
              Positioned.fill(
                child: IllustrationPanel(gradient: p.gradient, asset: p.asset),
              ),
              // bottom scrim for text legibility
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x00000000), Color(0x00000000), Color(0xD9000000)],
                      stops: [0.0, 0.42, 1.0],
                    ),
                  ),
                ),
              ),
              if (p.recommended && !p.locked)
                const Positioned(left: 10, top: 8, child: Text('👑', style: TextStyle(fontSize: 18))),
              // separator line at the illustration / text seam
              Positioned(
                left: 14,
                right: 14,
                bottom: 92,
                child: Container(height: 1, color: Colors.white.withValues(alpha: 0.20)),
              ),
              // text block (left-aligned) below the separator
              Positioned(
                left: 12,
                right: 12,
                bottom: 8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(p.name, style: CareerText.cardTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(p.world,
                        style: CareerText.worldLabel.copyWith(color: p.accent),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(right: 26), // keep clear of the arrow
                      child: Text(p.description,
                          style: CareerText.body.copyWith(color: Colors.white70),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
              // activity icon — centered, straddling the separator line
              Positioned(
                left: 0,
                right: 0,
                bottom: 77.5,
                child: Center(child: IconBadge(icon: p.icon, color: p.accent, size: 29)),
              ),
              // arrow button
              Positioned(
                right: 10,
                bottom: 10,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.16),
                    border: Border.all(color: CareerColors.glassBorder),
                  ),
                  child: const Icon(Icons.chevron_right_rounded, size: 18, color: Colors.white),
                ),
              ),
              // Locked overlay — drawn LAST so it sits above all other layers,
              // dimming the entire card and surfacing a lock badge top-right.
              if (p.locked) ...[
                Positioned.fill(
                  child: ColoredBox(color: Colors.black.withValues(alpha: 0.45)),
                ),
                const Positioned(top: 8, right: 8, child: LockBadge(size: 26)),
              ],
            ],
          ),
          ),
        ),
      ),
    );
  }
}
