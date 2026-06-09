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
enum CardMotif { energyLoop }

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
      "light. Stop cranking, and that energy doesn't vanish. It just stops "
      'becoming light.',
  reach:
      'A candle, a car, a star, you — nothing in the entire universe has ever '
      'broken this rule.',
  linkedCardName: 'The Great Escape', // Card 04 — the law, and its consequence
);
