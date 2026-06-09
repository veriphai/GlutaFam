// The six satellite parts teased on the bridge screen (PRD bridge: "if it has
// to help people, what should we put inside it?"). Icon + Flutter label only —
// these are a preview of the NEXT activity (Build Your Satellite), not
// interactive here.

import 'asset_paths.dart';

class PartTease {
  final String label;
  final String asset; // flutter path
  const PartTease(this.label, this.asset);
}

final List<PartTease> kBridgeParts = [
  PartTease('SOLAR\nPANEL', OL.flutter(OL.partSolar)),
  PartTease('CAMERA', OL.flutter(OL.partCamera)),
  PartTease('ANTENNA', OL.flutter(OL.partAntenna)),
  PartTease('BATTERY', OL.flutter(OL.partBattery)),
  PartTease('COMPUTER\nCHIP', OL.flutter(OL.partChip)),
  PartTease('THRUSTER', OL.flutter(OL.partThruster)),
];
