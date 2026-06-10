// Activity 3 · beat 1.2 — the six source "personalities".
//
// Each source teaches via TWO BEATS of top-text (update spec Change 2):
//   • upside    — Beat 1, the promise, shown ON ARRIVAL (selecting the source)
//   • catchLine — Beat 2, the catch, shown ONLY AFTER the day reveals it
// The catch is named as a FACT about the felt consequence (the haze, the
// blackout, the flicker) — never the number. Pros/cons remain consequences the
// kid causes (haze / dark town / cost), never a ratings table (§4.4).
//
// The other fields are the data the sim needs to turn a choice into that felt
// consequence: how it makes power across the day (drives town brightness), how
// dirty its runtime is (the haze), and how its cost climbs.

import 'package:flutter/material.dart';

/// The six ways the town can be powered (PRD §4.3). Order = selector order.
enum SourceKind { solar, wind, coal, gas, nuclear, hydro }

@immutable
class SourcePersonality {
  const SourcePersonality({
    required this.kind,
    required this.label,
    required this.accent,
    required this.icon,
    required this.hazeRate,
    required this.costRate,
    required this.buildCost,
    required this.upside,
    required this.catchLine,
  });

  final SourceKind kind;
  final String label;
  final Color accent; // selector chip + source visual tint
  final IconData icon;

  /// Haze added per day-hour of runtime (0..1 fills the smog layer). Non-zero
  /// ONLY for the fuel-burners — coal worst, gas less. This IS "dirty", felt.
  final double hazeRate;

  /// Cost added per day-hour of runtime — the meter's steady climb.
  final double costRate;

  /// A one-shot cost charged the instant this source is chosen (its build cost).
  /// Nuclear's is large: clean + steady, yet the meter leaps — "expensive", felt.
  final double buildCost;

  /// Beat 1 — the upside, shown on arrival (3–4 words).
  final String upside;

  /// Beat 2 — the catch, shown only after the day reveals it (3–5 words).
  final String catchLine;

  bool get isSolar => kind == SourceKind.solar;
  bool get isWind => kind == SourceKind.wind;
  bool get isHydro => kind == SourceKind.hydro;

  /// Whether this source ever dirties the air (drives the source visual's stack).
  bool get emits => hazeRate > 0;
}

const List<SourcePersonality> kSources = [
  SourcePersonality(
    kind: SourceKind.solar,
    label: 'Solar',
    accent: Color(0xFFFFC857),
    icon: Icons.wb_sunny_rounded,
    hazeRate: 0.0, // clean
    costRate: 0.22,
    buildCost: 7,
    upside: 'Free, Clean, Silent',
    catchLine: 'But Dies Every Night',
  ),
  SourcePersonality(
    kind: SourceKind.wind,
    label: 'Wind',
    accent: Color(0xFFBFD8E8),
    icon: Icons.air_rounded,
    hazeRate: 0.0, // clean
    costRate: 0.28,
    buildCost: 7,
    upside: 'Free and Clean',
    catchLine: 'No Wind, No Power',
  ),
  SourcePersonality(
    kind: SourceKind.coal,
    label: 'Coal',
    accent: Color(0xFFFF8A4D),
    icon: Icons.local_fire_department_rounded,
    hazeRate: 0.075, // dirtiest — thick haze builds across the day
    costRate: 0.92,
    buildCost: 6,
    upside: 'Steady All Day',
    catchLine: 'But the Air Turns Filthy',
  ),
  SourcePersonality(
    kind: SourceKind.gas,
    label: 'Gas',
    accent: Color(0xFF5BC0F8),
    icon: Icons.gas_meter_rounded,
    hazeRate: 0.04, // less than coal, still emits
    costRate: 0.82,
    buildCost: 5,
    upside: 'Steady, a Bit Cleaner',
    catchLine: 'Still Dirties the Air',
  ),
  SourcePersonality(
    kind: SourceKind.nuclear,
    label: 'Nuclear',
    accent: Color(0xFF7CE0B0),
    icon: Icons.radio_button_checked_rounded,
    hazeRate: 0.0, // clean air
    costRate: 0.5,
    buildCost: 34, // huge up-front build cost → the meter is high from the start
    upside: 'Steady, Day and Night',
    catchLine: 'Clean — But Costs a Fortune',
  ),
  SourcePersonality(
    kind: SourceKind.hydro,
    label: 'Hydro',
    accent: Color(0xFF4FA8F5),
    icon: Icons.water_drop_rounded,
    hazeRate: 0.0, // clean
    costRate: 0.2,
    buildCost: 8,
    upside: 'Clean and Steady',
    catchLine: 'Only Where Rivers Run',
  ),
];

SourcePersonality sourceOf(SourceKind k) => kSources.firstWhere((s) => s.kind == k);
