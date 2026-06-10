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
    subtitle: 'From a handle lamp to the power plant, the grid, and your bill.',
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
              'Spin a handle and watch the lamp live and die with your effort.',
          longDescription:
              'Turn the handle and the lamp brightens. Stop, and it dies the instant you '
              'stop — nothing is stored. Then drive a fan, a heater, a speaker with the '
              'same handle: same electricity, different result.',
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

        // ── Episode 1 — Where Power Is Born ────────────────────────────
        // Three activities played one-by-one, then closed with the CER synthesis
        // beat: Act 2 (trace the sources back to one magnet) → Act 3 (run the town
        // on each source for a day, feel each catch) → "Make Your Case" (assemble
        // the evidence captured across both into an answer to the guiding question).
        Lesson(
          number: 1,
          lessonId: null, // local seed — runner skips backend progress POSTs
          title: 'Episode 1 — Where Power Is Born',
          shortDescription:
              'Spin a magnet, boil water, catch the wind — then make your case for why we use so many sources.',
          longDescription:
              'Every power plant hides the same trick: spin a magnet and electricity '
              'appears. See how coal, nuclear, wind, and water all just turn that magnet, '
              'feel the catch behind each one across a day, then build your own answer to '
              'the big question: why do we make electricity from so many different sources?',
          discoverHook:
              'Almost all electricity comes from spinning a magnet — and we use many sources because no single one is complete.',
          rewardName: 'Collectible Card',
          thumbnailIcon: Icons.factory_rounded,
          thumbnailColor: CareerColors.cyan,
          isLocked: false,
          resources: [
            HowwowLessonResource(type: 'activity', activityId: 'trace_it_back'),
            HowwowLessonResource(type: 'activity', activityId: 'source_personalities'),
            HowwowLessonResource(type: 'activity', activityId: 'make_your_case'),
          ],
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

  // ── De-extinction concept ────────────────────────────────────────────
  // A Prologue + 7 episodes mirroring the electricity series. No activities
  // are built yet, so the Prologue is the open entry point with an empty
  // `resources` list (tapping "Start" shows the "not available yet" snackbar
  // until an activity ships) and Episodes 1–7 are locked placeholders. As each
  // activity lands: register its id in activityRegistry.dart, add it to the
  // episode's `resources`, and unlock the episode (isLocked: false).
  WowConcept(
    id: 'concept_deextinction',
    title: 'How De-Extinction Works',
    subtitle: 'Could we really build a Jurassic Park? Bring a lost animal back, step by step.',
    icon: Icons.biotech_rounded,
    accent: CareerColors.green,
    gradient: [Color(0xFF13331F), Color(0xFF101A30)],
    detail: ProfessionDetail(
      professionId: 'concept_deextinction',
      name: 'How De-Extinction Works',
      world: 'How Things Work',
      worldEmoji: '🧬',
      accentColor: CareerColors.green,
      seriesLabel: 'WOW CONCEPT',
      seasonTitle: 'De-Extinction',
      tagline:
          'Could we ever bring a lost animal back to life — and should we even try?',
      heroGradient: [Color(0xFF13331F), Color(0xFF101A30)],
      lessons: [
        // ── Prologue — the open entry point (activity TBD) ─────────────
        Lesson(
          number: 0,
          lessonId: null, // local seed → runner skips backend progress POSTs
          title: 'Prologue — The One Thing You Need',
          shortDescription:
              'Bones, photos, memories — none of them can bring an animal back. So what can?',
          longDescription:
              "Build a creature from its instructions, watch it come alive, then lose it — "
              "and discover the single thing you'd actually need to bring it back.",
          discoverHook:
              'An animal is built from a recipe called a genome — and the recipe, not the bones, is what brings it back.',
          // No collectible — this is the opener.
          rewardName: null,
          thumbnailIcon: Icons.biotech_rounded,
          thumbnailColor: CareerColors.green,
          isCompleted: false,
          isLocked: false,
          resources: [
            HowwowLessonResource(type: 'activity', activityId: 'recipe_creature'),
          ],
        ),

        // ── Episode 1 — locked placeholder ─────────────────────────────
        Lesson(
          number: 1,
          title: 'Episode 1 — Why Not Dinosaurs?',
          shortDescription:
              "Everyone's first question — and the answer is hiding inside a single molecule.",
          longDescription:
              'Try to pull a recipe from older and older remains, and watch it fall apart in '
              'your hands. Find out exactly why a real Jurassic Park is impossible — and what '
              'that still leaves on the table.',
          discoverHook:
              'DNA decays on a clock, so dinosaurs are long gone — but recently-extinct animals are still within reach.',
          rewardName: 'Collectible Card',
          thumbnailIcon: Icons.history_toggle_off_rounded,
          thumbnailColor: CareerColors.cyan,
          isLocked: true,
        ),

        // ── Episode 2 — locked placeholder ─────────────────────────────
        Lesson(
          number: 2,
          title: "Episode 2 — Reading What's Left",
          shortDescription:
              'The recipe comes back shredded, jumbled, and mixed with junk. Now read it.',
          longDescription:
              'Ancient DNA survives only as tiny broken scraps. Piece them back together — '
              'and discover the one trick that makes it possible at all.',
          discoverHook:
              'You rebuild shredded DNA by matching its scraps against the genome of the closest living relative.',
          rewardName: 'Collectible Card',
          thumbnailIcon: Icons.extension_rounded,
          thumbnailColor: CareerColors.blue,
          isLocked: true,
        ),

        // ── Episode 3 — locked placeholder ─────────────────────────────
        Lesson(
          number: 3,
          title: 'Episode 3 — Editing the Difference',
          shortDescription:
              "You don't build a mammoth. You take an elephant and change what matters.",
          longDescription:
              "Start from a living relative's working recipe and edit only the differences. "
              'Spend a limited budget of changes and see how close you can really get.',
          discoverHook:
              'Gene editing is find-and-replace for DNA — but you can change only so much, so the result resembles the original without being it.',
          rewardName: 'Collectible Card',
          thumbnailIcon: Icons.find_replace_rounded,
          thumbnailColor: CareerColors.gold,
          isLocked: true,
        ),

        // ── Episode 4 — locked placeholder ─────────────────────────────
        Lesson(
          number: 4,
          title: 'Episode 4 — Making It Breathe',
          shortDescription:
              'Edited DNA in a dish is not an animal. So how does it become one?',
          longDescription:
              'Follow the recipe from a single cell to a heartbeat — through cloning, a '
              "surrogate mother, and a birth that doesn't always go right.",
          discoverHook:
              "Edited DNA becomes an animal only through a cell, a surrogate mother, and a birth — and a genome alone can't teach it how to live.",
          rewardName: 'Collectible Card',
          thumbnailIcon: Icons.monitor_heart_rounded,
          thumbnailColor: CareerColors.pink,
          isLocked: true,
        ),

        // ── Episode 5 — locked placeholder ─────────────────────────────
        Lesson(
          number: 5,
          title: 'Episode 5 — Is It Really Back?',
          shortDescription:
              'You made the animal. But is it the species — or just a convincing lookalike?',
          longDescription:
              'Run your creature through every test of what makes a species itself, and '
              "discover there's no single answer — only the one you choose.",
          discoverHook:
              "Whether it counts as \"the species\" isn't science — it's a definition, and which one you pick is a choice.",
          rewardName: 'Collectible Card',
          thumbnailIcon: Icons.rule_rounded,
          thumbnailColor: CareerColors.purple,
          isLocked: true,
        ),

        // ── Episode 6 — locked placeholder ─────────────────────────────
        Lesson(
          number: 6,
          title: 'Episode 6 — A World to Return To',
          shortDescription:
              'One animal isn\'t a species, and the world it left may be gone.',
          longDescription:
              'Find your animal a home in a world that moved on without it — and see whether '
              'a single creature could ever become a living, lasting population.',
          discoverHook:
              'An animal needs a home that may be gone, and one individual is never a population.',
          rewardName: 'Collectible Card',
          thumbnailIcon: Icons.forest_rounded,
          thumbnailColor: CareerColors.green,
          isLocked: true,
        ),

        // ── Episode 7 — locked placeholder (the finale question) ───────
        Lesson(
          number: 7,
          title: 'Episode 7 — Should We?',
          shortDescription:
              'The science says we can bring some things back. That was never the hard part.',
          longDescription:
              'Weigh the cost, the risks, and the reasons — and decide for yourself where '
              '"can we" turns into "should we."',
          discoverHook:
              'The cost, the risks, and the hardest question of all — not whether we can, but whether we should.',
          rewardName: 'Collectible Card',
          thumbnailIcon: Icons.balance_rounded,
          thumbnailColor: CareerColors.orange,
          isLocked: true,
        ),
      ],
      rewards: [],
      certificate: Certificate(
        title: 'De-Extinction Pioneer',
        requirementLine: 'Finish every episode to earn',
      ),
      footerHint: 'New episodes unlock as you complete the current one!',
    ),
  ),
];
