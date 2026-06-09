// WHERE SLOT POSITIONS ARE CONFIGURED.
//
// Every drop zone / final part placement is defined here as factors RELATIVE
// to the satellite body's on-screen rectangle (not absolute pixels), so the
// layout stays correct on any screen size. Tune these numbers to nudge where a
// part snaps — nothing else needs to change.
//
//   positionFactor : the anchor point ON the body (0,0 = body top-left,
//                    1,1 = body bottom-right).
//   partAnchor     : which point OF THE PART sprite is pinned to positionFactor
//                    (0,0 = part top-left … 1,1 = part bottom-right). e.g. a
//                    left solar panel pins its RIGHT edge (1, 0.5) to the body's
//                    left hinge so it extends outward.
//   widthFactor    : installed part width as a fraction of the body width.
//   finalAngleDeg  : rotation applied when locked in.

import 'dart:ui' show Offset;

class SlotConfig {
  final String id;
  final String acceptsPartId;
  final Offset positionFactor;
  final Offset partAnchor;
  final double widthFactor;
  final double finalAngleDeg;

  const SlotConfig({
    required this.id,
    required this.acceptsPartId,
    required this.positionFactor,
    this.partAnchor = const Offset(0.5, 0.5),
    required this.widthFactor,
    this.finalAngleDeg = 0,
  });
}

/// Keyed by slot id. Order roughly follows the 7-step mission flow.
const Map<String, SlotConfig> kSlotConfigs = {
  // Step 1 — solar panels attach to the left/right hinge mounts and extend out.
  'left_solar_panel_slot': SlotConfig(
    id: 'left_solar_panel_slot',
    acceptsPartId: 'left_solar_panel',
    positionFactor: Offset(0.07, 0.46),
    partAnchor: Offset(1.0, 0.5), // pin panel's right edge to the body
    widthFactor: 0.42,
    finalAngleDeg: -4,
  ),
  'right_solar_panel_slot': SlotConfig(
    id: 'right_solar_panel_slot',
    acceptsPartId: 'right_solar_panel',
    positionFactor: Offset(0.93, 0.46),
    partAnchor: Offset(0.0, 0.5), // pin panel's left edge to the body
    widthFactor: 0.42,
    finalAngleDeg: 4,
  ),

  // Step 2 — antenna mounts on the top face socket.
  'antenna_base_slot': SlotConfig(
    id: 'antenna_base_slot',
    acceptsPartId: 'antenna_base',
    positionFactor: Offset(0.5, 0.21),
    partAnchor: Offset(0.5, 0.78), // base sits down into the socket
    widthFactor: 0.34,
  ),
  'antenna_dish_slot': SlotConfig(
    id: 'antenna_dish_slot',
    acceptsPartId: 'antenna_dish',
    positionFactor: Offset(0.5, 0.18),
    partAnchor: Offset(0.5, 0.9), // dish rises above the installed base
    widthFactor: 0.42,
  ),

  // Step 3 — camera fills the front octagon bay.
  'camera_slot': SlotConfig(
    id: 'camera_slot',
    acceptsPartId: 'camera_module',
    positionFactor: Offset(0.5, 0.52),
    widthFactor: 0.30,
  ),

  // Step 4 — computer core chip on the upper-right of the front face.
  'computer_core_slot': SlotConfig(
    id: 'computer_core_slot',
    acceptsPartId: 'computer_core_chip',
    positionFactor: Offset(0.69, 0.40),
    widthFactor: 0.20,
  ),

  // Step 5 — battery on the lower-left of the front face.
  'battery_slot': SlotConfig(
    id: 'battery_slot',
    acceptsPartId: 'battery_module',
    positionFactor: Offset(0.33, 0.66),
    widthFactor: 0.24,
  ),

  // Step 6 — thruster on the bottom ring, extending below.
  'thruster_slot': SlotConfig(
    id: 'thruster_slot',
    acceptsPartId: 'thruster',
    positionFactor: Offset(0.5, 0.9),
    partAnchor: Offset(0.5, 0.18), // top of the thruster meets the ring
    widthFactor: 0.32,
  ),

  // Step 7 — thermal blanket settles over the top face.
  'thermal_blanket_slot': SlotConfig(
    id: 'thermal_blanket_slot',
    acceptsPartId: 'thermal_blanket',
    positionFactor: Offset(0.5, 0.26),
    widthFactor: 0.46,
    finalAngleDeg: -2,
  ),
};

SlotConfig slotConfig(String id) => kSlotConfigs[id]!;
