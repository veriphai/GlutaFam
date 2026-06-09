// "How Things Work" — the curiosity-concept rail on the career home, slotted
// after Explore Worlds. Mirrors FeaturedProfessionsSection's structure (section
// header + horizontal card rail), but the cards open a CONCEPT (a locally
// seeded ProfessionDetail) instead of a backend profession. No "View All" yet —
// the catalog is a single concept today — so the header is title-only.

import 'package:flutter/material.dart';

import 'careerCommon.dart';
import 'careerTheme.dart';
import 'wowConcepts.dart';

class HowThingsWorkSection extends StatelessWidget {
  const HowThingsWorkSection({
    super.key,
    required this.concepts,
    this.onConceptTap,
  });

  final List<WowConcept> concepts;
  final void Function(WowConcept concept)? onConceptTap;

  @override
  Widget build(BuildContext context) {
    if (concepts.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: CareerSpace.page),
          child: Row(
            children: [
              const Text('💡', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 7),
              Expanded(
                child: Text('How Things Work', style: CareerText.sectionTitle),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 168,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: CareerSpace.page),
            itemCount: concepts.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, i) => RevealOnLoad(
              delay: Duration(milliseconds: 120 + i * 90),
              child: ConceptCard(
                concept: concepts[i],
                onTap: onConceptTap == null ? null : () => onConceptTap!(concepts[i]),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ConceptCard extends StatelessWidget {
  const ConceptCard({super.key, required this.concept, this.onTap});

  final WowConcept concept;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = concept;
    return PressableScale(
      onTap: c.locked ? null : onTap,
      child: SizedBox(
        width: 248,
        // Same split-layer trick as ProfessionCard: outer draws border+shadow,
        // inner ClipRRect (radius − border width) clips children so the clip
        // never notches the border corners.
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(CareerRadii.smallCard),
            border: Border.all(color: CareerColors.glassBorder),
            boxShadow: [
              BoxShadow(
                color: c.accent.withValues(alpha: 0.28),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(CareerRadii.smallCard - 1),
            child: Stack(
              children: [
                Positioned.fill(
                  child: IllustrationPanel(gradient: c.gradient, asset: c.asset),
                ),
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x00000000), Color(0x66000000), Color(0xE6000000)],
                        stops: [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                ),
                // "WOW CONCEPT" eyebrow + icon badge, top-left.
                Positioned(
                  left: 12,
                  top: 12,
                  child: Row(
                    children: [
                      IconBadge(icon: c.icon, color: c.accent, size: 34),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.fromLTRB(9, 4, 10, 4),
                        decoration: BoxDecoration(
                          color: c.accent.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(CareerRadii.pill),
                          border: Border.all(color: c.accent.withValues(alpha: 0.55)),
                        ),
                        child: Text(
                          'WOW CONCEPT',
                          style: CareerText.label.copyWith(color: Colors.white, fontSize: 8),
                        ),
                      ),
                    ],
                  ),
                ),
                // Title + subtitle block, bottom.
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        c.title,
                        style: CareerText.cardTitleLg.copyWith(height: 1.12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(right: 30), // clear the arrow
                        child: Text(
                          c.subtitle,
                          style: CareerText.body.copyWith(color: Colors.white70),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                // Arrow CTA.
                Positioned(
                  right: 10,
                  bottom: 10,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: c.accent.withValues(alpha: 0.9),
                      boxShadow: [
                        BoxShadow(color: c.accent.withValues(alpha: 0.5), blurRadius: 10),
                      ],
                    ),
                    child: const Icon(Icons.chevron_right_rounded, size: 18, color: Colors.white),
                  ),
                ),
                if (c.locked) ...[
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
