// "How Things Work" — curiosity concepts (e.g. "How Electricity Reaches Your
// Home") shown as a home-page rail. A concept is a kind="concept" profession on
// the backend: it reuses the EXACT profession→lesson→resource machinery, so a
// concept opens the same ProfessionDetailScreen timeline (fetched by id via
// `howwowGetProfessionDetail`). Each episode (lesson) carries an ordered
// resource list, so one episode can play several activities one-by-one.
//
// These are BACKEND-DRIVEN: the cards come from `GET /howwow/career/concepts`
// (see howwowGetConcepts) and the detail is fetched on open — there is no local
// seed any more. [WowConcept] is just the lightweight card model the
// "How Things Work" rail renders.

import 'package:flutter/material.dart';

import '../../../models/howwow/howwowCareer.dart' as api;
import 'careerModels.dart' show iconForKey, parseHexColor, parseGradient;
import 'careerTheme.dart';

/// A curiosity-concept card on the home rail. Opening it pushes the shared
/// ProfessionDetailScreen by [id], which fetches the episode timeline from the
/// backend (same as a profession).
class WowConcept {
  const WowConcept({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.gradient,
    this.asset,
    this.locked = false,
  });

  final String id;
  final String title; // card title
  final String subtitle; // one-liner on the card
  final IconData icon;
  final Color accent;
  final List<Color> gradient; // card illustration fallback
  final String? asset; // optional full-bleed card illustration

  /// "coming soon" concept cards (none locked today).
  final bool locked;

  /// Build a card from a `/howwow/career/concepts` list item (a kind="concept"
  /// profession). The episodes/detail are fetched separately when opened.
  factory WowConcept.fromApi(api.HowwowProfession p) {
    final accent = parseHexColor(p.accentColor) ?? CareerColors.gold;
    return WowConcept(
      id: p.professionId,
      title: p.name,
      subtitle: p.description ?? '',
      icon: iconForKey(p.iconKey),
      accent: accent,
      gradient: parseGradient(p.gradient),
      asset: p.imageUrl,
      locked: p.locked,
    );
  }
}
