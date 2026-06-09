// "How Things Work" — curiosity concepts (e.g. "How Electricity Reaches Your
// Home") shown as a home-page rail. Each concept is a mini-series that reuses
// the EXACT profession structure: a [ProfessionDetail] holding [Lesson]s, each
// lesson carrying an ordered [HowwowLessonResource] list (so a lesson can play
// several activities one-by-one through the lessonRunner). A concept opens the
// same ProfessionDetailScreen timeline — the only difference is these are
// seeded locally (no backend profession).
//
// When backend support lands, a `WowConcept.fromApi(...)` factory drops in the
// same way Profession/CareerWorld did — the section + detail screen are already
// decoupled from the source.

import 'package:flutter/material.dart';

import '../../../models/howwow/howwowProfile.dart' show HowwowLessonResource;
import 'careerTheme.dart';
import 'professionDetailModels.dart';

/// A curiosity concept card on the home rail + the detail payload it opens.
class WowConcept {
  const WowConcept({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.gradient,
    required this.detail,
    this.asset,
    this.locked = false,
  });

  final String id;
  final String title; // card + detail title
  final String subtitle; // one-liner on the card
  final IconData icon;
  final Color accent;
  final List<Color> gradient; // card illustration fallback
  final String? asset; // optional full-bleed card illustration

  /// Reuses the profession detail payload → same timeline + lesson launcher.
  final ProfessionDetail detail;

  /// Future-proofing for "coming soon" concept cards (none locked today).
  final bool locked;
}

// ── Seed ─────────────────────────────────────────────────────────────
// The electricity concept: a Prologue + 5 episodes. Only the Prologue is built
// today — its single resource is the Hand-Crank Lamp activity (lessonId null →
// the runner skips backend progress writes; episodes can hold MULTIPLE activity
// resources later, played one-by-one). Episodes 1–5 are locked placeholders
// until their activities ship; unlock + add `resources` then.

const List<WowConcept> kWowConcepts = [
  WowConcept(
    id: 'concept_electricity',
    title: 'How Electricity Reaches Your Home',
    subtitle: 'From a hand-crank lamp to the power plant, the grid, and your bill.',
    icon: Icons.bolt_rounded,
    accent: CareerColors.gold,
    gradient: [Color(0xFF3A2C12), Color(0xFF1A1330)],
    detail: ProfessionDetail(
      professionId: 'concept_electricity',
      name: 'How Electricity Reaches Your Home',
      world: 'How Things Work',
      worldEmoji: '⚡',
      accentColor: CareerColors.gold,
      seriesLabel: 'WOW CONCEPT',
      seasonTitle: 'Electricity',
      tagline:
          'Where does electricity come from — and where does it go the instant you switch off?',
      heroGradient: [Color(0xFF3A2C12), Color(0xFF1A1330)],
      lessons: [
        // ── Prologue — the only built episode ──────────────────────────
        Lesson(
          number: 0,
          lessonId: null, // no backend lesson → runner skips progress POSTs
          title: 'Prologue — What Electricity Does',
          shortDescription:
              'Crank a hand generator and watch the lamp live and die with your effort.',
          longDescription:
              'Turn the crank and the lamp brightens. Stop, and it dies the instant you '
              'stop — nothing is stored. Then drive a fan, a heater, a speaker with the '
              'same crank: same electricity, different result.',
          discoverHook:
              "Electricity isn't a fuel that fills up and drains — it carries energy and stores none.",
          // No collectible — this is the opener.
          rewardName: null,
          thumbnailIcon: Icons.bolt_rounded,
          thumbnailColor: CareerColors.gold,
          isCompleted: false,
          isLocked: false,
          resources: [
            HowwowLessonResource(type: 'activity', activityId: 'hand_crank_lamp'),
          ],
        ),

        // ── Episode 1 — locked placeholder ─────────────────────────────
        Lesson(
          number: 1,
          title: 'Episode 1 — Where Power Is Born',
          shortDescription:
              'Spin a magnet, boil water, catch the wind — find the one trick behind every power plant.',
          longDescription:
              'Every power plant hides the same trick: spin a magnet and electricity '
              'appears. See how coal, nuclear, wind, and water all just turn that magnet — '
              'and why making electricity always wastes some of it.',
          discoverHook:
              'Almost all electricity comes from spinning a magnet — and every source is a trade-off, none perfect.',
          rewardName: 'Collectible Card',
          thumbnailIcon: Icons.factory_rounded,
          thumbnailColor: CareerColors.cyan,
          isLocked: true,
        ),

        // ── Episode 2 — locked placeholder (LONGEST) ───────────────────
        Lesson(
          number: 2,
          title: 'Episode 2 — The Long Way Home',
          shortDescription:
              'Send power across a country without losing it all to heat on the way.',
          longDescription:
              'The power plant is hundreds of kilometres away, and the wire leaks heat the '
              'whole journey. So how does the electricity survive the trip? Push the voltage '
              'sky-high and watch the waste vanish.',
          discoverHook:
              'Pushing electricity at enormous voltage is the trick that stops it leaking away over long distances.',
          rewardName: 'Collectible Card',
          thumbnailIcon: Icons.cable_rounded,
          thumbnailColor: CareerColors.blue,
          isLocked: true,
          tag: 'LONGEST',
        ),

        // ── Episode 3 — locked placeholder ─────────────────────────────
        Lesson(
          number: 3,
          title: 'Episode 3 — Into Your House (Without Getting Hurt)',
          shortDescription:
              'Bring lethal voltage down to a safe level — and learn why the bird on the wire survives.',
          longDescription:
              'That travelling voltage would arc across your room. Tame it down to a safe '
              "level, find out why a bird on a power line isn't fried, and meet the hidden "
              'wire that protects you.',
          discoverHook:
              "Electricity only flows — and only harms — when there's a difference between two points, not just contact.",
          rewardName: 'Collectible Card',
          thumbnailIcon: Icons.home_rounded,
          thumbnailColor: CareerColors.green,
          isLocked: true,
        ),

        // ── Episode 4 — locked placeholder ─────────────────────────────
        Lesson(
          number: 4,
          title: 'Episode 4 — Keeping the Lights On',
          shortDescription:
              'Balance a whole city\'s power in real time, and fight off a cascading blackout.',
          longDescription:
              'Somewhere right now, a plant is making exactly what your city uses this '
              "second — because power can't be stored. Take the controls: match the "
              'dinnertime surge, and stop the grid from crashing into a blackout.',
          discoverHook:
              "Electricity can't be stored, so it must be made the exact instant it's used — every second.",
          rewardName: 'Collectible Card',
          thumbnailIcon: Icons.electric_meter_rounded,
          thumbnailColor: CareerColors.pink,
          isLocked: true,
        ),

        // ── Episode 5 — locked placeholder ─────────────────────────────
        Lesson(
          number: 5,
          title: 'Episode 5 — Who Pays for All This?',
          shortDescription:
              'Read an electricity bill and trace every cost back to the machine you built.',
          longDescription:
              "You've built the whole machine — now read the bill. Find out why 6pm power "
              "costs more than 3am, why there's just one set of wires down your street, and "
              'where every cost comes from.',
          discoverHook:
              'You pay for energy — power multiplied by time — and peak-hour power costs more because it is harder to make.',
          rewardName: 'Collectible Card',
          thumbnailIcon: Icons.receipt_long_rounded,
          thumbnailColor: CareerColors.orange,
          isLocked: true,
        ),
      ],
      rewards: [],
      certificate: Certificate(
        title: 'Electricity Explorer',
        requirementLine: 'Finish every episode to earn',
      ),
      footerHint: 'New episodes unlock as you complete the current one!',
    ),
  ),
];
