// Sample data models + seed data for the career-discovery homepage.
// Swap `asset` in for real illustrations later; widgets fall back to a
// gradient + icon placeholder whenever `asset` is null or fails to load.
//
// The `Profession`, `CareerWorld`, and `ContinueMission` types are also the
// contract the widget tree consumes. When real data arrives from
// /howwow/career/home, the `.fromApi(...)` factories at the bottom of this
// file convert the wire-shape DTOs (HowwowProfession, HowwowWorld,
// HowwowCurrentLesson) into these UI types — so the widgets themselves
// stay untouched.

import 'package:flutter/material.dart';
import '../../../models/howwow/howwowCareer.dart' as api;
import '../../../models/howwow/howwowProfile.dart' as api;
import 'careerTheme.dart';

class Profession {
  final String name;
  final String world;
  final String description;
  final IconData icon;
  final List<Color> gradient; // illustration panel background
  final Color accent; // icon badge + world label colour
  final bool recommended; // shows a crown + highlighted border
  final bool locked;      // gameplay gated; the widget can disable taps / dim the card
  final String? asset;

  const Profession({
    required this.name,
    required this.world,
    required this.description,
    required this.icon,
    required this.gradient,
    required this.accent,
    this.recommended = false,
    this.locked = false,
    this.asset,
  });

  /// Build the UI type from the `/howwow/career/home` profession DTO.
  /// `worlds` is needed to resolve `worldId` → human-readable world name.
  factory Profession.fromApi(api.HowwowProfession p, {Map<String, String> worldNamesById = const {}}) {
    return Profession(
      name: p.name,
      world: worldNamesById[p.worldId] ?? (p.worldId ?? ''),
      description: p.description ?? '',
      icon: iconForKey(p.iconKey),
      gradient: parseGradient(p.gradient),
      accent: parseHexColor(p.accentColor) ?? CareerColors.purple,
      recommended: p.recommended,
      locked: p.locked,
      asset: p.imageUrl,
    );
  }
}

// Demo-mode seed (used only when /career/home fails). Lock state mirrors the
// backend: only Satellite Engineer is unlocked at launch.
const List<Profession> kProfessions = [
  Profession(
    name: 'Satellite Engineer',
    world: 'Space World',
    description: 'Build satellites that help Earth from space.',
    icon: Icons.satellite_alt_rounded,
    gradient: [Color(0xFF3A2C7A), Color(0xFF1A2566)],
    accent: CareerColors.purple,
    recommended: true,
    locked: false,
    asset: 'assets/images/satellite_engineer.png',
  ),
  Profession(
    name: 'Astronaut',
    world: 'Space World',
    description: 'Live in space and solve problems in zero gravity.',
    icon: Icons.rocket_launch_rounded,
    gradient: [Color(0xFF4B2E8A), Color(0xFF2A2160)],
    accent: CareerColors.pink,
    locked: true,
    asset: 'assets/images/astronaut.png',
  ),
  Profession(
    name: 'AI Engineer',
    world: 'AI & Robotics World',
    description: 'Teach machines to learn patterns and help people.',
    icon: Icons.smart_toy_rounded,
    gradient: [Color(0xFF12407A), Color(0xFF0E2A6B)],
    accent: CareerColors.cyan,
    locked: true,
    asset: 'assets/images/ai_engineer.png',
  ),
  Profession(
    name: 'Nuclear Scientist',
    world: 'Deep Science World',
    description: 'Explore atoms, energy, and safe power systems.',
    icon: Icons.science_rounded,
    gradient: [Color(0xFF1E5E2E), Color(0xFF143F22)],
    accent: CareerColors.green,
    locked: true,
    asset: 'assets/images/nuclear_scientist.png',
  ),
  Profession(
    name: 'Marine Biologist',
    world: 'Ocean World',
    description: 'Discover ocean life and underwater mysteries.',
    icon: Icons.waves_rounded,
    gradient: [Color(0xFF0E5A86), Color(0xFF0B3A66)],
    accent: CareerColors.blue,
    locked: true,
    asset: 'assets/images/marine_biologist.png',
  ),
];

class CareerWorld {
  final String name;
  final int professionCount;
  final List<String> sampleProfessions;
  final IconData icon;
  final List<Color> gradient;
  final Color accent;
  final bool locked;       // gameplay gated; the widget can disable taps / dim the card
  final String? asset;

  const CareerWorld({
    required this.name,
    required this.professionCount,
    required this.sampleProfessions,
    required this.icon,
    required this.gradient,
    required this.accent,
    this.locked = false,
    this.asset,
  });

  /// Build the UI type from the `/howwow/career/home` world DTO. The icon
  /// is derived from the world's name (no separate iconKey on the wire).
  factory CareerWorld.fromApi(api.HowwowWorld w) {
    return CareerWorld(
      name: w.name,
      professionCount: w.professionCount,
      sampleProfessions: w.sampleProfessions,
      icon: iconForWorldName(w.name),
      gradient: parseGradient(w.gradient),
      accent: parseHexColor(w.accentColor) ?? CareerColors.purple,
      locked: w.locked,
      asset: w.imageUrl,
    );
  }
}

// Demo-mode seed (used only when /career/home fails). Lock state mirrors the
// backend: only Space World is unlocked at launch.
const List<CareerWorld> kWorlds = [
  CareerWorld(
    name: 'Space World',
    professionCount: 4,
    sampleProfessions: ['Satellite Engineer', 'Astronaut', 'Rocket Scientist'],
    icon: Icons.public_rounded,
    gradient: [Color(0xFF3A2C7A), Color(0xFF1A2566)],
    accent: CareerColors.purple,
    locked: false,
    asset: 'assets/images/space_world.png',
  ),
  CareerWorld(
    name: 'AI & Robotics World',
    professionCount: 5,
    sampleProfessions: ['AI Engineer', 'Robotics Expert', 'Data Scientist'],
    icon: Icons.smart_toy_rounded,
    gradient: [Color(0xFF12407A), Color(0xFF0E2A6B)],
    accent: CareerColors.cyan,
    locked: true,
    asset: 'assets/images/ai_robotics_world.png',
  ),
  CareerWorld(
    name: 'Deep Science World',
    professionCount: 4,
    sampleProfessions: ['Nuclear Scientist', 'Chemist', 'Physicist'],
    icon: Icons.science_rounded,
    gradient: [Color(0xFF1E5E2E), Color(0xFF143F22)],
    accent: CareerColors.green,
    locked: true,
    asset: 'assets/images/deep_science_world.png',
  ),
  CareerWorld(
    name: 'Ocean World',
    professionCount: 3,
    sampleProfessions: ['Marine Biologist', 'Ocean Technologist', 'Diver'],
    icon: Icons.water_rounded,
    gradient: [Color(0xFF0E5A86), Color(0xFF0B3A66)],
    accent: CareerColors.blue,
    locked: true,
    asset: 'assets/images/ocean_world.png',
  ),
];

class ContinueMission {
  final String? professionId;
  final String profession;
  final String world;

  /// True when the hero card is showing a WOW concept (e.g. electricity)
  /// rather than a career. Drives the card's framing — "WOW CONCEPT" vs
  /// "CAREER MISSION" copy, and hiding the world label (concepts carry only
  /// a label-only worldId). Sourced from the profession's `kind`.
  final bool isConcept;

  /// Card/hero illustration of the profession/concept (S3 URL or bundled
  /// `assets/...` path). Used to render a concept's own art on the hero card;
  /// careers fall back to the bundled hero scene.
  final String? asset;

  /// Accent colour of the profession/concept. The hero card themes its
  /// border, glow and "WOW CONCEPT" chip off this for concepts (electricity
  /// = gold). Null for careers (they keep the default purple hero theme).
  final Color? accent;
  final String missionTitle;
  final List<String> skills;
  final int current;
  final int total;

  /// True when the user has been inside the current lesson at all —
  /// opened it (server start write) or completed a resource. Drives
  /// START vs CONTINUE copy on the card independently of [current],
  /// which only counts FULLY completed lessons (a kid mid-Episode-1 has
  /// current=0 but should still see "Continue").
  final bool startedCurrentLesson;

  /// 1-based step the user will resume on inside the current lesson and
  /// the lesson's total step count — `null`/0 when unknown (static seed,
  /// old backend payload). Powers the "step 2 of 3" hint.
  final int? resumeStep;
  final int totalSteps;

  /// Resource type of the resume step ("video" | "image" | "activity"),
  /// for friendlier copy ("the mission" vs "the story").
  final String? resumeStepType;

  const ContinueMission({
    this.professionId,
    required this.profession,
    required this.world,
    required this.missionTitle,
    required this.skills,
    required this.current,
    required this.total,
    this.isConcept = false,
    this.asset,
    this.accent,
    this.startedCurrentLesson = false,
    this.resumeStep,
    this.totalSteps = 0,
    this.resumeStepType,
  });

  double get progress => total == 0 ? 0 : current / total;

  /// "Continue" surfaces when the user finished a lesson before OR is
  /// mid-way through the current one; otherwise it's a fresh "Start".
  bool get inProgress => current > 0 || startedCurrentLesson;

  /// Build the UI type from the `/howwow/career/home` current-lesson DTO.
  /// `professions` + `worlds` are needed to resolve professionId → name +
  /// worldId → name (the wire shape only carries IDs).
  ///
  /// Series-level progress (X completed / Y total in this profession) is
  /// now carried directly on {@link api.HowwowCurrentLesson} so the home
  /// Continue card renders the "X / Y Missions" pill without an extra
  /// detail-endpoint round trip.
  static ContinueMission? fromApi(
    api.HowwowCurrentLesson? m, {
    Map<String, String> professionNamesById = const {},
    Map<String, String> worldNamesById = const {},
  }) {
    if (m == null || m.title == null) return null;
    final hasSteps = m.resources.isNotEmpty;
    return ContinueMission(
      professionId: m.professionId,
      // Prefer the name carried in the payload — the professions map excludes
      // concepts, so resolving a concept name from it would fail and fall
      // back to the raw professionId.
      profession: m.professionName ??
          professionNamesById[m.professionId] ??
          (m.professionId ?? ''),
      world: worldNamesById[m.worldId] ?? (m.worldId ?? ''),
      isConcept: m.isConcept,
      asset: m.imageUrl,
      accent: parseHexColor(m.accentColor),
      missionTitle: m.title!,
      skills: m.skills,
      current: m.completedCount,
      total: m.totalCount,
      startedCurrentLesson: m.started,
      resumeStep: hasSteps ? m.nextResourceIndex + 1 : null,
      totalSteps: m.resources.length,
      resumeStepType: hasSteps ? m.resources[m.nextResourceIndex].type : null,
    );
  }
}

// Demo/offline fallback for the hero "beginning" card. Mirrors the backend's
// new-user default: a brand-new user starts on the electricity WOW concept
// (the curiosity hook) rather than a career. Only used when /career/home is
// unreachable; a live backend overrides this with the user's actual
// most-recently-attempted lesson.
const kContinueMission = ContinueMission(
  professionId: 'concept_electricity',
  profession: 'How Electricity Reaches Your Home',
  world: '', // concept — no world label (hidden on the card)
  isConcept: true,
  asset:
      'https://the-how-wow-prod.s3.ap-south-1.amazonaws.com/professions/concept_electricity/card.jpg',
  accent: CareerColors.gold,
  missionTitle: 'Prologue — What Electricity Does',
  skills: ['Energy', 'Curiosity'],
  current: 0,
  total: 6,
);

// ── adapters: API → UI types ─────────────────────────────────────────

/// Parse a `#RRGGBB` or `#AARRGGBB` string into a [Color]. Returns null on
/// invalid input so callers can apply a sensible fallback.
Color? parseHexColor(String? hex) {
  if (hex == null) return null;
  var s = hex.trim();
  if (s.startsWith('#')) s = s.substring(1);
  if (s.length == 6) s = 'FF$s'; // assume fully opaque
  if (s.length != 8) return null;
  final value = int.tryParse(s, radix: 16);
  if (value == null) return null;
  return Color(value);
}

/// Convert a list of hex stops into a `List<Color>` for gradients. Falls
/// back to a neutral two-stop dark gradient when input is empty/invalid.
List<Color> parseGradient(List<String> hexStops) {
  final colors = hexStops.map(parseHexColor).whereType<Color>().toList();
  if (colors.length >= 2) return colors;
  return const [Color(0xFF3A2C7A), Color(0xFF1A2566)];
}

/// Map a profession `iconKey` (returned by the backend) to a Flutter
/// [IconData]. Anything unknown falls back to a neutral career icon so the
/// UI never crashes on a new key the client hasn't seen yet.
IconData iconForKey(String? key) {
  switch (key) {
    case 'satellite_alt':
      return Icons.satellite_alt_rounded;
    case 'rocket_launch':
      return Icons.rocket_launch_rounded;
    case 'smart_toy':
      return Icons.smart_toy_rounded;
    case 'science':
      return Icons.science_rounded;
    case 'waves':
      return Icons.waves_rounded;
    case 'public':
      return Icons.public_rounded;
    case 'water':
      return Icons.water_rounded;
    case 'biotech':
      return Icons.biotech_rounded;
    case 'memory':
      return Icons.memory_rounded;
    case 'engineering':
      return Icons.engineering_rounded;
    // ── WOW-concept icon keys (electricity + de-extinction series) ──────
    case 'bolt':
      return Icons.bolt_rounded;
    case 'factory':
      return Icons.factory_rounded;
    case 'cable':
      return Icons.cable_rounded;
    case 'home':
      return Icons.home_rounded;
    case 'electric_meter':
      return Icons.electric_meter_rounded;
    case 'receipt_long':
      return Icons.receipt_long_rounded;
    case 'history':
      return Icons.history_toggle_off_rounded;
    case 'extension':
      return Icons.extension_rounded;
    case 'find_replace':
      return Icons.find_replace_rounded;
    case 'monitor_heart':
      return Icons.monitor_heart_rounded;
    case 'rule':
      return Icons.rule_rounded;
    case 'forest':
      return Icons.forest_rounded;
    case 'balance':
      return Icons.balance_rounded;
    default:
      return Icons.workspace_premium_rounded;
  }
}

/// World icons are derived from the world's name (the wire shape has no
/// separate iconKey on worlds). Substring match keeps it resilient to
/// minor naming changes ("AI & Robotics World" / "AI Robotics" both match).
IconData iconForWorldName(String name) {
  final lower = name.toLowerCase();
  if (lower.contains('space')) return Icons.public_rounded;
  if (lower.contains('ai') || lower.contains('robot')) return Icons.smart_toy_rounded;
  if (lower.contains('science')) return Icons.science_rounded;
  if (lower.contains('ocean') || lower.contains('water')) return Icons.water_rounded;
  if (lower.contains('bio') || lower.contains('life')) return Icons.biotech_rounded;
  return Icons.public_rounded;
}
