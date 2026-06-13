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

  // ── Episode 2 — "The Long Way Home" (transmission) ─────────────────────────
  pushFlow, // Card 06 (2.1) — a pressure column driving a mote stream to a lit lamp
  narrowPipe, // Card 07 (2.2) — a wire reshaping; thin chokes the flow, fat lets it run
  electricFriction, // Card 08 (2.3) — a glowing wire shedding rising heat strokes
  squareTax, // Card 09 (2.4) — a steep parabola rising off a glowing wire
  starveTheWire, // Card 10 (2.5) — a tall thin rectangle over a cold line to a lit town
  stillMachine, // Card 11 (2.6) — a ring core with turns, a changing field, no moving parts
  twoCurrents, // Card 12 (2.7) — a flat DC line vs a reversing AC wave
  highRoad, // Card 13 (EP2 CER) — the rectangle standing over a cold line to a lit far city
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
  frontImage: 'assets/images/collectibles/conservation_front.webp',
  backImage: 'assets/images/collectibles/conservation_back.webp',
);

// ── Card 02 — Electromagnetic Induction (Episode 1 · Generation) ───────
// The first card earned through a discovery beat (trace_it_back, beat 1.1). The
// back carries the bedrock honesty — the "nobody can explain why" line is the
// most brag-worthy thing on it (card spec Part 2 · Card 02). Core rarity; the
// induction↔transformer recurring-idea link lands in Episode 2, so no link yet.
const CollectibleCard kMagnetTrickCard = CollectibleCard(
  id: 'electromagnetic_induction',
  frontImage: 'assets/images/collectibles/electromagnetic_induction_front.webp',
  backImage: 'assets/images/collectibles/electromagnetic_induction_back.webp',
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
  frontImage: 'assets/images/collectibles/energy_trade_off_front.webp',
  backImage: 'assets/images/collectibles/energy_trade_off_back.webp',
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

// ═══ Episode 2 — "The Long Way Home" (transmission) ═══════════════════════════
// The transmission deck (Cards 06–13). One beat-card per quick-reference-table
// concept (2.1→2.7) plus the EP2 CER synthesis card (13). 2.8 (war_of_currents)
// earns NO card (its PRD §8: "Why the grid is AC" is not a quick-reference row —
// the DC/AC row is 2.7's card; 2.8 is the synthesis that feeds the EP2 CER).
// Section: transmission (electric-blue #3FB9F5) throughout. Copy is verbatim from
// each beat PRD's §8/§10; numbers assigned sequentially after EP1's 05; deckTotal
// stays 23 (13 ≤ 23). linkedCardName references another card's cardName.

// ── Card 06 — The Push and the Flow (2.1 · Transmission) ───────────────
// voltage_and_current §8. The episode's two named quantities, kept distinct.
const CollectibleCard kPushFlowCard = CollectibleCard(
  id: 'voltage_and_current',
  frontImage: 'assets/images/collectibles/voltage_and_current_front.webp',
  backImage: 'assets/images/collectibles/voltage_and_current_back.webp',
  cardName: 'The Push and the Flow',
  realName: 'VOLTAGE & CURRENT',
  law: 'Voltage is the push that drives charge; current is how much actually flows.',
  kicker: 'They can rise together — they are never the same thing.',
  section: CardSection.transmission,
  rarity: CardRarity.core,
  motif: CardMotif.pushFlow,
  number: 6,
  deckTotal: 23,
  tieBack:
      'One slider set the push; the current answered on its own. And the instant '
      'the voltage hit zero, the flow and the lamp died with it — same frame, '
      'nothing stored.',
  reach:
      'A doorknob spark is tens of thousands of volts — enormous push, almost no '
      'flow. That is why it stings instead of kills.',
);

// ── Card 07 — The Narrow Pipe (2.2 · Transmission) ─────────────────────
// what_resistance_is §8. Resistance is the wire's shape-set opposition to current.
const CollectibleCard kNarrowPipeCard = CollectibleCard(
  id: 'resistance',
  frontImage: 'assets/images/collectibles/resistance_front.webp',
  backImage: 'assets/images/collectibles/resistance_back.webp',
  cardName: 'The Narrow Pipe',
  realName: 'RESISTANCE',
  law: 'Every wire opposes the current through it — its shape sets how much.',
  kicker: 'Thin fights. Fat flows.',
  section: CardSection.transmission,
  rarity: CardRarity.core,
  motif: CardMotif.narrowPipe,
  number: 7,
  deckTotal: 23,
  tieBack:
      'You pinned the voltage and reshaped the wire — stretched thin, the current '
      'choked; squashed fat, it surged.',
  reach:
      'Every cable in your house is sized for the current it must carry — fatter '
      'for the oven, slimmer for a lamp.',
);

// ── Card 08 — Electric Friction (2.3 · Transmission) ───────────────────
// current_heats_wire §8. Loss = heat: current through resistance sheds heat. The
// "loss-as-heat is conservation in costume" thread links back to Card 01.
const CollectibleCard kElectricFrictionCard = CollectibleCard(
  id: 'joule_heating',
  frontImage: 'assets/images/collectibles/joule_heating_front.webp',
  backImage: 'assets/images/collectibles/joule_heating_back.webp',
  cardName: 'Electric Friction',
  realName: 'JOULE HEATING',
  law: 'Current forced through resistance sheds energy as heat.',
  kicker: "Loss isn't gone — it's heat.",
  section: CardSection.transmission,
  rarity: CardRarity.core,
  motif: CardMotif.electricFriction,
  number: 8,
  deckTotal: 23,
  tieBack:
      'You raised the current and the wire itself warmed — then you made the very '
      'same heat with your finger, just by rubbing.',
  reach:
      "Every toaster, kettle and room heater is a wire built to 'lose' on purpose.",
  linkedCardName: 'The Unbreakable Rule', // ← Card 01: loss-as-heat is conservation
);

// ── Card 09 — The Square Tax (2.4 · Transmission) ──────────────────────
// squared_loss §8. The punishment term: loss grows with the SQUARE of the current.
// Links the "loss = heat" thread to the 2.3 card (Electric Friction).
const CollectibleCard kSquareTaxCard = CollectibleCard(
  id: 'squared_loss',
  frontImage: 'assets/images/collectibles/squared_loss_front.webp',
  backImage: 'assets/images/collectibles/squared_loss_back.webp',
  cardName: 'The Square Tax',
  realName: 'JOULE HEATING · I²R',
  law: 'Wasted heat grows with the square of the current — double the current, '
      'quadruple the loss.',
  kicker: 'Current is punished hard.',
  section: CardSection.transmission,
  rarity: CardRarity.core,
  motif: CardMotif.squareTax,
  number: 9,
  deckTotal: 23,
  tieBack:
      "You nudged the dial from ×1 to ×2 and the wire's heat leapt fourfold. Volts "
      'lost along the wire grow with the current — and the heat is those volts '
      'times the current again. Current × current.',
  reach:
      'The same square is why a phone fast-charger raises voltage instead of '
      'pushing more current.',
  linkedCardName: 'Electric Friction', // ← Card 08: the loss = heat thread
);

// ── Card 10 — Starve the Wire (2.5 · Transmission) · THE STAR ──────────
// transmission_trick §8. The fixed-power inversion: higher voltage → lower current
// → far lower loss. Links back to the I² card (the loss this trick defeats). The
// 5.1 kWh card will later link FORWARD to this one (the rectangle recurrence) —
// that card does not exist yet, so this stays singly linked to The Square Tax.
const CollectibleCard kStarveTheWireCard = CollectibleCard(
  id: 'transmission_trick',
  frontImage: 'assets/images/collectibles/transmission_trick_front.webp',
  backImage: 'assets/images/collectibles/transmission_trick_back.webp',
  cardName: 'Starve the Wire',
  realName: 'HIGH-VOLTAGE TRANSMISSION',
  law: 'Fixed power: higher voltage means lower current — and the loss falls with '
      'the current squared.',
  kicker: 'Why pylon lines carry hundreds of thousands of volts.',
  section: CardSection.transmission,
  rarity: CardRarity.core,
  motif: CardMotif.starveTheWire,
  number: 10,
  deckTotal: 23,
  tieBack:
      'You dragged the rectangle taller and the current thinned by itself — the '
      'wire went cold and the far town lit to full.',
  reach:
      'The same pinned-area rectangle prices your electricity bill: energy is '
      'power × time.',
  linkedCardName: 'The Square Tax', // ← Card 09: the squared loss this trick beats
);

// ── Card 11 — The Still Machine (2.6 · Transmission) ───────────────────
// the_transformer §8. The turns rule + induction with no moving parts. Links to
// Card 02 'The Magnet Trick' — the recurring induction law (reused here).
const CollectibleCard kStillMachineCard = CollectibleCard(
  id: 'transformer',
  frontImage: 'assets/images/collectibles/transformer_front.webp',
  backImage: 'assets/images/collectibles/transformer_back.webp',
  cardName: 'The Still Machine',
  realName: 'TRANSFORMER',
  law: 'Turns set the voltage: wind more and it steps up, wind fewer and it steps '
      'down.',
  kicker: 'Nothing moves but the field.',
  section: CardSection.transmission,
  rarity: CardRarity.core,
  motif: CardMotif.stillMachine,
  number: 11,
  deckTotal: 23,
  tieBack:
      'You wound turns onto a coil and watched the voltage climb — nothing '
      'spinning, only a changing field at work.',
  reach:
      'The grey cylinder on a street pole is one of these, stepping the line down '
      'for your home.',
  linkedCardName: 'The Magnet Trick', // ← Card 02: the recurring induction law
);

// ── Card 12 — The Two Currents (2.7 · Transmission) ────────────────────
// ac_vs_dc §8. DC steady one-way vs AC reversing; only AC works a transformer.
// Links to The Still Machine (2.6 — the device this rule feeds).
const CollectibleCard kTwoCurrentsCard = CollectibleCard(
  id: 'ac_vs_dc',
  frontImage: 'assets/images/collectibles/ac_vs_dc_front.webp',
  backImage: 'assets/images/collectibles/ac_vs_dc_back.webp',
  cardName: 'The Two Currents',
  realName: 'DIRECT / ALTERNATING CURRENT',
  law: 'DC flows steadily one way; AC reverses many times a second.',
  kicker: 'Only the restless one can work a transformer.',
  section: CardSection.transmission,
  rarity: CardRarity.core,
  motif: CardMotif.twoCurrents,
  number: 12,
  deckTotal: 23,
  tieBack:
      'You flipped a battery and the dead transformer blinked awake — every '
      'reversal, one flicker; every steady moment, nothing.',
  reach:
      'The wall socket reverses its current fifty times a second — yet every chip '
      'in your phone insists on steady DC.',
  linkedCardName: 'The Still Machine', // ← Card 11: the device this rule feeds
);

// ── Card 13 — The High Road (Episode 2 · CER synthesis) ────────────────
// prd_make_your_case_ep2 §10. The EPISODE-synthesis card (EP1 precedent, Card 05):
// earned at the end of the EP2 "Make Your Case" closing flow. It names the
// journey's COMPOSITE law (distance + the voltage/current trade + the AC
// condition) — none of the beat cards states it. Links back to 'Starve the Wire'
// (Card 10 — the trick this whole case rests on), exactly as Card 05 linked Card 03.
const CollectibleCard kHighRoadCard = CollectibleCard(
  id: 'the_high_road',
  frontImage: 'assets/images/collectibles/the_high_road_front.webp',
  backImage: 'assets/images/collectibles/the_high_road_back.webp',
  cardName: 'The High Road',
  realName: 'HIGH-VOLTAGE AC TRANSMISSION',
  law: 'Distance is crossed at enormous voltage and tiny current — and only AC '
      'could be stepped up that high.',
  kicker: 'How power beats distance.',
  section: CardSection.transmission,
  rarity: CardRarity.core,
  motif: CardMotif.highRoad,
  number: 13,
  deckTotal: 23,
  tieBack:
      'You watched heat bleed off the wire and leap with the square — then raised '
      'the voltage, the current fell on its own, and the far city lit to full.',
  reach:
      'Follow any pylon line on the horizon: it is running this exact case right '
      'now, at hundreds of thousands of volts.',
  linkedCardName: 'Starve the Wire', // ← Card 10: the trick this case rests on
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
