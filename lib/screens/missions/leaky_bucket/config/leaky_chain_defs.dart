// Activity 4 · The Leaky Bucket (beat 1.3) — the energy chain as DATA.
//
// A vertical energy-flow Sankey: 100 units enter at the top and flow down a chain
// of conversion STAGES; at every stage a fraction leaks sideways as HEAT, so only
// a thin survivor (~38) reaches the bulb. Efficiencies are FIXED — this is a
// build-and-watch-it-leak demonstration, not an efficiency-tuning game.

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// One lossy conversion in the chain (Burn→Boil→Spin→Wire for coal).
enum LeakStepKind { burn, boil, spin, wire }

extension LeakStepKindInfo on LeakStepKind {
  /// The machine's name shown in the parts tray.
  String get machineName {
    switch (this) {
      case LeakStepKind.burn:
        return 'Furnace';
      case LeakStepKind.boil:
        return 'Boiler';
      case LeakStepKind.spin:
        return 'Turbine';
      case LeakStepKind.wire:
        return 'Generator';
    }
  }

  IconData get icon {
    switch (this) {
      case LeakStepKind.burn:
        return PhosphorIconsFill.fire;
      case LeakStepKind.boil:
        return PhosphorIconsFill.drop;
      case LeakStepKind.spin:
        return PhosphorIconsFill.fan;
      case LeakStepKind.wire:
        return PhosphorIconsFill.lightning;
    }
  }

  /// The machine's own tint. The escaping HEAT is a separate uniform warm orange
  /// (see [kHeatColor]) so every leak reads as the same thing.
  Color get accent {
    switch (this) {
      case LeakStepKind.burn:
        return const Color(0xFFFF7A3C);
      case LeakStepKind.boil:
        return const Color(0xFFFFB05A);
      case LeakStepKind.spin:
        return const Color(0xFFFFC24D);
      case LeakStepKind.wire:
        return const Color(0xFF6FA8FF);
    }
  }
}

/// The colour every escaping leak is drawn in — felt heat, uniform across stages.
const Color kHeatColor = Color(0xFFFF7A2E);

/// The warm "alive" energy travelling down the main stream.
const Color kEnergyColor = Color(0xFFFFD27A);

/// One stage in the chain: its kind + its fixed efficiency. [dramatic] marks the
/// one big leak (the turbine).
@immutable
class LeakStep {
  const LeakStep({required this.kind, required this.defaultEff, this.dramatic = false});
  final LeakStepKind kind;
  final double defaultEff;
  final bool dramatic;
}

enum LeakySource { coal }

@immutable
class LeakySourceDef {
  const LeakySourceDef({required this.source, required this.steps});
  final LeakySource source;

  /// The ordered chain top→bottom: Burn → Boil → Spin → Wire.
  final List<LeakStep> steps;
}

// Coal: burn 0.85 · boil 0.88 · spin 0.55 (the dramatic one) · wire 0.92 → ~38.
const LeakySourceDef _coal = LeakySourceDef(
  source: LeakySource.coal,
  steps: [
    LeakStep(kind: LeakStepKind.burn, defaultEff: 0.85),
    LeakStep(kind: LeakStepKind.boil, defaultEff: 0.88),
    LeakStep(kind: LeakStepKind.spin, defaultEff: 0.55, dramatic: true),
    LeakStep(kind: LeakStepKind.wire, defaultEff: 0.92),
  ],
);

const Map<LeakySource, LeakySourceDef> kLeakySources = {LeakySource.coal: _coal};
