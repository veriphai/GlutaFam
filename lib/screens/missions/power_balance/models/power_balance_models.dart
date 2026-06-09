// Pure enums for the Power Balance Challenge. No widget/Flame imports — shared
// by the immutable state, the controller, the Flame game, and the Flutter UI.

/// Where the satellite is along its orbit, per PRD §11.3. Drives charging,
/// which world objects are present, and the shadow darkening.
enum OrbitZone {
  sunlight,
  cycloneTarget,
  groundStationRange,
  shadow,
}

/// Guided-to-free mission progression (PRD §13). The first capture/transmission
/// and the shadow are guided (the orbit HOLDS at the teachable zone); after the
/// shadow tutorial the orbit flows freely and the child finishes independently.
enum MissionPhase {
  intro,
  lowBatteryCrisis,
  solarTutorial,
  firstCapture,
  firstTransmission,
  shadowTutorial,
  freeMissionLoop,
  success,
  failure,
}

/// Solar panel alignment (PRD §11.2 — tap-to-align, V1).
enum SolarAlignState { misaligned, aligning, aligned }

/// Mission Control helper mood, mapped to an avatar sprite by the card.
enum MascotMood { neutral, thinking, excited, warning, success }

/// Which control the tutorial is currently asking the child to use. Drives the
/// "highlight this button / dim the rest" affordance in the dock.
enum ControlHint { none, solar, camera, antenna }

/// A one-shot achievement/feedback badge that pops at a key moment (PRD per-scene
/// "Required Assets"). Mapped to a sprite by the feedback-badge overlay.
enum FeedbackBadge { none, imageCaptured, dataSent, shadow, sunlight, lowPower }

extension OrbitZoneX on OrbitZone {
  bool get isSunlit => this == OrbitZone.sunlight;
  bool get isShadow => this == OrbitZone.shadow;

  /// Short HUD label for the optional zone badge.
  String get label => switch (this) {
        OrbitZone.sunlight => 'SUNLIGHT',
        OrbitZone.cycloneTarget => 'TARGET',
        OrbitZone.groundStationRange => 'GROUND LINK',
        OrbitZone.shadow => 'SHADOW',
      };
}
