// Tunable layout constants for the Satellite Doctor Flame stage.
//
// The satellite is ASSEMBLED from separate single-angle part renders (the kit has
// no full-satellite hero — see styleboard). The body cube already contains the
// camera lens (front) + battery panel (right); we composite the antenna on top,
// a solar panel on each side, and the thruster below. Perspectives are slightly
// mismatched (playbook "asset-kit realism") — reads fine at kid-scale with FX.
//
// All positions are FACTORS of stage width (resolution-independent) so a nudge in
// the on-device visual-QA pass is a one-number edit here. Part offsets are from
// the rig centre, in units of stage WIDTH (+x right, +y down).

class SDTune {
  SDTune._();

  // rig centre (factor of stage size)
  static const double satCenterX = 0.5;
  static const double satCenterY = 0.44;

  // part sizes (width as a factor of stage width) + offsets from rig centre
  static const double bodyWidthFactor = 0.34; // the cube
  static const double panelWidthFactor = 0.30;
  static const double panelOffsetX = 0.26; // left = -, right = +
  static const double panelOffsetY = 0.02;
  static const double antennaWidthFactor = 0.30;
  static const double antennaOffsetX = 0.02;
  static const double antennaOffsetY = -0.24; // above the cube
  static const double thrusterWidthFactor = 0.16;
  static const double thrusterOffsetX = 0.0;
  static const double thrusterOffsetY = 0.22; // below the cube

  // fault/effect anchor offsets ON the cube body, as factor of BODY width from
  // body centre (the battery panel is centre-right; the camera lens is centre).
  static const double batteryDx = 0.20;
  static const double batteryDy = 0.04;
  static const double cameraDx = -0.02;
  static const double cameraDy = 0.06;

  // idle float
  static const double idleBobPx = 9.0;
  static const double idleBobSeconds = 3.2;
  static const double idleTiltDeg = 1.8;

  // earth horizon band (anchored near bottom), width = factor of stage
  static const double earthCenterY = 0.95;
  static const double earthWidthFactor = 1.4;

  // sun orb (top-left) for thermal/solar missions
  static const double sunCenterX = 0.13;
  static const double sunCenterY = 0.15;
  static const double sunWidthFactor = 0.30;

  // repair reaction magnitudes
  static const double rotateAwayMaxDeg = 22.0; // M1 whole-satellite rotation
  static const double antennaTurnMaxDeg = 70.0; // M2 antenna component turn
  static const double panelTurnMaxDeg = 28.0; // M4 panel component tilt
  static const double dodgeShiftFactor = 0.24; // M6 lateral shift (factor of W)
}
