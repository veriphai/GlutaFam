// Collectible-card data model + the electricity deck's section system and the
// Prologue's foundational card. Built to the howwow collectible spec:
//   • per-section accent colours encode the journey,
//   • the Foundations section (Prologue) is PRISMATIC + Foundational rarity —
//     the rarest card, the first the kid earns,
//   • copy may name the general LAW; it never re-narrates what the kid felt.
//
// Shared across episodes — every future card adds an entry here.

import 'package:flutter/material.dart';

/// Deck sections, in journey order (Foundations → … → The Bill). The accent is
/// the card's colour identity (guilloché frame + glow). Foundations is special:
/// prismatic (full-spectrum), not a single accent.
enum CardSection { foundations, generation, transmission, homeSafety, grid, theBill }

extension CardSectionInfo on CardSection {
  String get label {
    switch (this) {
      case CardSection.foundations:
        return 'FOUNDATIONS';
      case CardSection.generation:
        return 'GENERATION';
      case CardSection.transmission:
        return 'TRANSMISSION';
      case CardSection.homeSafety:
        return 'HOME & SAFETY';
      case CardSection.grid:
        return 'GRID';
      case CardSection.theBill:
        return 'THE BILL';
    }
  }

  /// Base accent on the frame. Foundations uses [prismatic] for the sheen but
  /// this silver base tints its hairlines/glow.
  Color get accent {
    switch (this) {
      case CardSection.foundations:
        return const Color(0xFFDCE3F2); // silver base; prismatic sheen on top
      case CardSection.generation:
        return const Color(0xFFFF9B42); // amber — heat, fire, sun
      case CardSection.transmission:
        return const Color(0xFF3FB9F5); // electric blue — high voltage
      case CardSection.homeSafety:
        return const Color(0xFF3FD99B); // emerald
      case CardSection.grid:
        return const Color(0xFFB08CF7); // violet
      case CardSection.theBill:
        return const Color(0xFFE0A96D); // warm copper
    }
  }

  bool get isPrismatic => this == CardSection.foundations;

  IconData get icon {
    switch (this) {
      case CardSection.foundations:
        return Icons.all_inclusive_rounded; // the unbreakable loop
      case CardSection.generation:
        return Icons.bolt_rounded;
      case CardSection.transmission:
        return Icons.electrical_services_rounded;
      case CardSection.homeSafety:
        return Icons.home_rounded;
      case CardSection.grid:
        return Icons.hub_rounded;
      case CardSection.theBill:
        return Icons.receipt_long_rounded;
    }
  }
}

enum CardRarity { foundational, core }

/// The motif drawn in the art window (its own painter per motif).
enum CardMotif {
  energyLoop, // Card 01 — arm → spark → light/heat/sound, cycling
  induction, // Card 02 — a magnet sweeping past a coil, field lines blooming
  tradeoff, // Card 03 — a balance that can't level: light vs haze vs cost, none wins
  escape, // Card 04 — a stream narrowing as heat wisps peel off, a thin survivor lights
  synthesis, // Card 05 — many source-glyphs feeding ONE grid hub that lights a town
  recipe, // De-extinction Prologue — a single coiled strand, certified-specimen
}

@immutable
class CollectibleCard {
  const CollectibleCard({
    required this.id,
    required this.cardName,
    required this.realName,
    required this.law,
    required this.kicker,
    required this.section,
    required this.rarity,
    required this.motif,
    required this.number,
    required this.deckTotal,
    required this.tieBack,
    required this.reach,
    this.linkedCardName,
    this.companionName = 'VOLTIX', // the back's companion mark; Helix on de-extinction
    this.companionIcon = Icons.bolt_rounded,
    this.frontImage,
    this.backImage,
  });

  final String id;
  final String cardName; // display (Bricolage Grotesque)
  final String realName; // mono small-caps — the "specimen label"
  final String law; // headline (Plus Jakarta Sans)
  final String kicker; // small body
  final CardSection section;
  final CardRarity rarity;
  final CardMotif motif;
  final int number; // 1-based position in the deck
  final int deckTotal;
  final String tieBack; // back: ties to what the kid felt
  final String reach; // back: one surprising extension
  final String? linkedCardName; // recurring-idea link badge (Card 01 ↔ Card 04)
  final String companionName; // the companion who hands the card over (back mark)
  final IconData companionIcon;

  /// Optional pre-rendered hero art for the two faces (square PNGs with their
  /// own frame/glow). When set, the card view shows these instead of the
  /// procedurally-painted face. Both must be provided together.
  final String? frontImage;
  final String? backImage;

  bool get hasImageFaces => frontImage != null && backImage != null;

  String get numberLabel => '${number.toString().padLeft(2, '0')} / $deckTotal';
}

// ── Card 01 — Conservation of Energy (Prologue · foundational) ─────────
const CollectibleCard kConservationCard = CollectibleCard(
  id: 'conservation_of_energy',
  cardName: 'The Unbreakable Rule',
  realName: 'LAW OF CONSERVATION OF ENERGY',
  law: 'Energy can never be created or destroyed.',
  kicker: 'It only changes form.',
  section: CardSection.foundations,
  rarity: CardRarity.foundational,
  motif: CardMotif.energyLoop,
  number: 1,
  deckTotal: 23,
  tieBack:
      'The light you made came from your breakfast — food to muscle to motion to '
      "light. Stop turning the handle, and that energy doesn't vanish. It just stops "
      'becoming light.',
  reach:
      'A candle, a car, a star, you — nothing in the entire universe has ever '
      'broken this rule.',
  linkedCardName: 'The Great Escape', // Card 04 — the law, and its consequence
  frontImage: 'assets/images/collectibles/conservation_front.png',
  backImage: 'assets/images/collectibles/conservation_back.png',
);

// ── Card 02 — Electromagnetic Induction (Episode 1 · Generation) ───────
// The first card earned through a discovery beat (trace_it_back, beat 1.1). The
// back carries the bedrock honesty — the "nobody can explain why" line is the
// most brag-worthy thing on it (card spec Part 2 · Card 02). Core rarity; the
// induction↔transformer recurring-idea link lands in Episode 2, so no link yet.
const CollectibleCard kMagnetTrickCard = CollectibleCard(
  id: 'electromagnetic_induction',
  cardName: 'The Magnet Trick',
  realName: 'ELECTROMAGNETIC INDUCTION',
  law: 'Move a magnet past a coil and electricity appears.',
  kicker: 'It has to move — a still magnet does nothing.',
  section: CardSection.generation,
  rarity: CardRarity.core,
  motif: CardMotif.induction,
  number: 2,
  deckTotal: 23,
  tieBack:
      'This one trick runs almost every power plant on Earth — coal, gas, '
      'nuclear, wind, and water all just spin a magnet. Only solar skips it.',
  reach:
      'And there\'s a hidden reason it works — electricity and magnetism are two '
      'sides of the same coin called electromagnetism.',
);

// ── Card 03 — No Free Lunch (Episode 1 · Generation) ───────────────────
// Earned through the source-personalities beat (1.2), fired on the synthesis the
// kid BUILT by running a town on each source for a day (PRD §4.5). The trade-off
// the per-source consequences added up to — clean / cheap / reliable / always-on,
// and none wins on all four. The controllability seed it plants bites in Episode 4
// (baseload vs peaking) and surfaces on the bill in Episode 5.
const CollectibleCard kNoFreeLunchCard = CollectibleCard(
  id: 'energy_trade_off',
  cardName: 'No Free Lunch',
  realName: 'THE ENERGY TRADE-OFF',
  law: 'Every way of making electricity is a trade-off.',
  kicker: 'None is clean, cheap, reliable, and always-on at once.',
  section: CardSection.generation,
  rarity: CardRarity.core,
  motif: CardMotif.tradeoff,
  number: 3,
  deckTotal: 23,
  tieBack:
      'You felt it: solar went dark at night, wind flickered, coal stayed steady '
      'but thickened the air and ran up the cost, nuclear stayed clean but '
      'expensive. No source kept the town lit, clean, and cheap all at once.',
  reach:
      'This is why no country runs on a single source — every grid is a mix, '
      'each plant covering for what the others can’t do.',
);

// ── Card 04 — The Great Escape (Episode 1 · Generation) ────────────────
// Earned on the synthesis after-line of The Leaky Bucket (beat 1.3, PRD §7).
// This is the conservation CALLBACK: Card 01 is the law (energy is never
// destroyed), Card 04 is its consequence (a "loss" is just energy turned into
// heat you didn't want). They are a recurring-idea PAIR — Card 01 already links
// forward to this card, and this one links back, so the deck shows them joined.
const CollectibleCard kGreatEscapeCard = CollectibleCard(
  id: 'energy_loss_in_conversion',
  cardName: 'The Great Escape',
  realName: 'ENERGY LOSS IN CONVERSION',
  law: 'Every energy conversion loses some as heat.',
  kicker: 'You can shrink the loss — never erase it.',
  section: CardSection.generation,
  rarity: CardRarity.core,
  motif: CardMotif.escape,
  number: 4,
  deckTotal: 23,
  tieBack:
      'You watched it: all that coal, and only about 38 of your 100 reached the '
      "bulb. The rest didn't vanish — it slipped away as heat at every step.",
  reach:
      'A car engine is the same story — it throws away roughly three-quarters of '
      'its fuel as heat; only the rest moves the car.',
  linkedCardName: 'The Unbreakable Rule', // ← Card 01: the law, and its consequence
);

// ── Card 05 — The Grid Is a Mix (Episode 1 · CER synthesis) ────────────
// The EPISODE-SYNTHESIS card (PRD §7.2): earned at the end of the "Make Your Case"
// closing flow, when the kid answers the guiding question — "why do we make
// electricity from so many different sources?" — by assembling the evidence they
// captured across Act 2 & Act 3. It visibly ties Card 02 (every source is the SAME
// trick → we CAN use many) and Card 03 (every source has a catch → we MUST use
// many) into one synthesized idea: a grid is a mix because no single source is
// complete. Links back to "No Free Lunch" (Card 03) — the must-use-many half.
const CollectibleCard kGridMixCard = CollectibleCard(
  id: 'grid_is_a_mix',
  cardName: 'The Grid Is a Mix',
  realName: 'WHY GRIDS MIX SOURCES',
  law: 'We use many sources because no single one is complete.',
  kicker: 'Same trick to make it — each with its own catch.',
  section: CardSection.generation,
  rarity: CardRarity.core,
  motif: CardMotif.synthesis,
  number: 5,
  deckTotal: 23,
  tieBack:
      'You proved it yourself: every source spins the same magnet, so any of them '
      'CAN power the town — but each has its own catch, so no single one can do it '
      'alone. So we use many, each covering for what the others lack.',
  reach:
      "That's why real grids blend coal, nuclear, wind, solar and more — never one "
      "source, but a team where each covers what the others can't.",
  linkedCardName: 'No Free Lunch', // ← Card 03: every source is a trade-off
);

// ── De-extinction · Prologue · foundational ────────────────────────────
// The first card of the "How De-Extinction Works" module, earned on the 0.3
// after-line of the Prologue (recipe_creature). Reuses the prismatic Foundations
// treatment — the rarest, certified-specimen look — with the coiled-strand motif
// (PRD §8). Handed over by Helix, not Voltix. NOTE: it shares the Foundations
// section with electricity's Card 01 for now (the module/deck split is deferred);
// its own number/deckTotal reflect the de-extinction module (8 cards).
const CollectibleCard kRecipeIsCreatureCard = CollectibleCard(
  id: 'recipe_is_the_creature',
  cardName: 'The Recipe Is the Creature',
  realName: 'GENOME',
  law: 'A living thing is the readout of its instructions.',
  kicker: 'Recover the instructions and you can rebuild the thing.',
  section: CardSection.foundations,
  rarity: CardRarity.foundational,
  motif: CardMotif.recipe,
  number: 1,
  deckTotal: 8,
  tieBack:
      "You watched it: the bones and the photo couldn't rebuild your creature. "
      'Its genome could.',
  reach:
      'Every living cell carries the complete genome — which is also why a '
      'fossil, however perfect, is never enough to bring something back.',
  companionName: 'HELIX',
  companionIcon: Icons.biotech_rounded,
);
