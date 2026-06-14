// Episode 1 · beat 1.1 (Trace It Back) — the six energy sources for Beat 3.
//
// The whole point of Beat 3 is the "same machine" reveal: coal/gas/nuclear/
// hydro/wind all just spin the SAME turbine→magnet→lamp core (only the FRONT
// END differs), and solar visibly breaks the pattern (it skips the turbine AND
// the magnet). So each source is data: a front-end kind + a particle flavour,
// plus the two booleans that make the reveal literal in code (§4.4, criterion 6):
//   • spinsTurbine — false ONLY for solar
//   • usesMagnet   — false ONLY for solar
// The core components read these and are otherwise untouched across sources.

import 'package:flutter/material.dart';

enum EnergySource { coal, gas, nuclear, hydro, wind, solar }

/// How the front end drives the turbine — the flow the kid sees differ here, the
/// core does not. Steam (coal/gas/nuclear) is boiled by heat; water/wind hit the
/// blades directly; sunlight goes straight to the panel (no turbine, no magnet).
enum FrontEndKind { heatSteam, water, wind, sunlight }

@immutable
class SourceDef {
  const SourceDef({
    required this.source,
    required this.label,
    required this.icon,
    required this.accent,
    required this.kind,
    required this.spinsTurbine,
    required this.usesMagnet,
    required this.flowColor,
  });

  final EnergySource source;
  final String label;
  final IconData icon;
  final Color accent; // chip + front-end tint
  final FrontEndKind kind;
  final bool spinsTurbine; // false only for solar
  final bool usesMagnet; // false only for solar
  final Color flowColor; // the particle-flow colour toward the turbine/panel

  bool get isSolar => source == EnergySource.solar;
}

const List<SourceDef> kSources = [
  SourceDef(
    source: EnergySource.coal,
    label: 'Coal',
    icon: Icons.local_fire_department,
    accent: Color(0xFFFF8A4D),
    kind: FrontEndKind.heatSteam,
    spinsTurbine: true,
    usesMagnet: true,
    flowColor: Color(0xFFFFF2E0), // hot white steam
  ),
  SourceDef(
    source: EnergySource.gas,
    label: 'Gas',
    icon: Icons.whatshot,
    accent: Color(0xFF5BC0F8),
    kind: FrontEndKind.heatSteam,
    spinsTurbine: true,
    usesMagnet: true,
    flowColor: Color(0xFFFFF2E0),
  ),
  SourceDef(
    source: EnergySource.nuclear,
    label: 'Nuclear',
    icon: Icons.science,
    accent: Color(0xFF7CE0B0),
    kind: FrontEndKind.heatSteam,
    spinsTurbine: true,
    usesMagnet: true,
    flowColor: Color(0xFFFFF2E0),
  ),
  SourceDef(
    source: EnergySource.hydro,
    label: 'Hydro',
    icon: Icons.water_drop,
    accent: Color(0xFF4FA8F5),
    kind: FrontEndKind.water,
    spinsTurbine: true,
    usesMagnet: true,
    flowColor: Color(0xFF7CC4FF), // falling water
  ),
  SourceDef(
    source: EnergySource.wind,
    label: 'Wind',
    icon: Icons.air,
    accent: Color(0xFFBFD8E8),
    kind: FrontEndKind.wind,
    spinsTurbine: true,
    usesMagnet: true,
    flowColor: Color(0xFFD8ECFF), // pale wind streaks
  ),
  SourceDef(
    source: EnergySource.solar,
    label: 'Solar',
    icon: Icons.wb_sunny,
    accent: Color(0xFFFFC857),
    kind: FrontEndKind.sunlight,
    spinsTurbine: false, // the odd one out — no turbine
    usesMagnet: false, //   and no magnet (light → electricity directly)
    flowColor: Color(0xFFFFD27A), // warm directional shimmer
  ),
];

SourceDef sourceDef(EnergySource s) => kSources.firstWhere((d) => d.source == s);
