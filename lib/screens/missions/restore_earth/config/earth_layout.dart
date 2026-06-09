// WHERE THE DIORAMA IS COMPOSED + TUNED.
//
// The pack ships a BARE terrain base + 5 separate zone-prop "mini-islands". We
// build the rich diorama by overlaying the props on the base at the factors
// below (all relative to the Earth rect). These WILL need a live tuning pass —
// nudging a single number here moves a district. Zone-label positions live here
// too so the Flame composite and the Flutter labels stay in sync.

import 'dart:ui' show Offset;

import 'asset_paths.dart';

/// Earth base placement within the Flame stage (factors of the stage size).
const Offset kEarthCenterOnStage = Offset(0.5, 0.85); // lower → uses the bottom space
const double kEarthWidthOnStage = 0.88; // earth width / stage width

/// Processed earth base aspect (h/w ≈ 631/820). Used by the Flutter zone-label
/// overlay to mirror where the Flame Earth rect sits.
const double kEarthAspect = 0.77;

/// A zone prop overlaid on the base. center/width are factors of the Earth rect.
class ZonePlacement {
  final String asset; // flame path
  final Offset center; // 0..1 of Earth rect
  final double width; // / Earth width
  const ZonePlacement(this.asset, this.center, this.width);
}

/// Painted back-to-front. Tune centers/widths against the base terrain.
const List<ZonePlacement> kZoneProps = [
  ZonePlacement('restore_earth/${RE.cityProps}', Offset(0.32, 0.40), 0.46),
  ZonePlacement('restore_earth/${RE.oceanProps}', Offset(0.66, 0.33), 0.42),
  ZonePlacement('restore_earth/${RE.farmProps}', Offset(0.76, 0.56), 0.42),
  ZonePlacement('restore_earth/${RE.villageProps}', Offset(0.27, 0.70), 0.36),
  ZonePlacement('restore_earth/${RE.stormProps}', Offset(0.54, 0.73), 0.40),
];

/// Flutter pill labels positioned over the stage (factors of the Earth rect).
class ZoneLabelDef {
  final String text;
  final Offset center;
  const ZoneLabelDef(this.text, this.center);
}

const List<ZoneLabelDef> kZoneLabels = [
  ZoneLabelDef('CITY', Offset(0.30, 0.37)),
  ZoneLabelDef('OCEAN', Offset(0.64, 0.30)),
  ZoneLabelDef('FARM', Offset(0.80, 0.52)),
  ZoneLabelDef('MOUNTAIN VILLAGE', Offset(0.22, 0.68)),
  ZoneLabelDef('STORM AREA', Offset(0.58, 0.70)),
];
