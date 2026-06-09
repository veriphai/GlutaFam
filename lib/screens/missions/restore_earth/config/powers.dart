// The four satellite powers (PRD §12 / §30.1). Config-driven so the UI, beam
// colour, and mode glow all read from one place.

import 'dart:ui';

import 'asset_paths.dart';

enum PowerId { location, weather, signal, scan }

class PowerDef {
  final PowerId id;
  final String label; // button label
  final String fullName; // e.g. "Location Beam"
  final String iconAsset; // flutter path (Image.asset)
  final String beamAsset; // flame path (beam core sprite)
  final Color beamColor; // beam + satellite mode glow (PRD §30.1)
  final Color buttonColor; // 2x2 button background (matches mockup)
  final String aimCopy; // mission text when selected (PRD §27)
  final int aimVoice; // Orbit voice clip number (1..54) — see voice index

  const PowerDef({
    required this.id,
    required this.label,
    required this.fullName,
    required this.iconAsset,
    required this.beamAsset,
    required this.beamColor,
    required this.buttonColor,
    required this.aimCopy,
    required this.aimVoice,
  });
}

const Map<PowerId, PowerDef> kPowers = {
  PowerId.location: PowerDef(
    id: PowerId.location,
    label: 'LOCATION',
    fullName: 'Location Beam',
    iconAsset: 'assets/images/restore_earth/${RE.iconLocation}',
    beamAsset: 'restore_earth/${RE.beamLocation}',
    beamColor: Color(0xFF39D8FF),
    buttonColor: Color(0xFF1C82C9),
    aimCopy: 'Location mode is on. Let’s aim it where someone is lost.',
    aimVoice: 3,
  ),
  PowerId.weather: PowerDef(
    id: PowerId.weather,
    label: 'WEATHER',
    fullName: 'Weather Eye',
    iconAsset: 'assets/images/restore_earth/${RE.iconWeather}',
    beamAsset: 'restore_earth/${RE.beamWeather}',
    beamColor: Color(0xFF8B5CFF),
    buttonColor: Color(0xFF6A45C8),
    aimCopy: 'Weather Eye is ready. Let’s point it at clouds or storms.',
    aimVoice: 4,
  ),
  PowerId.signal: PowerDef(
    id: PowerId.signal,
    label: 'SIGNAL',
    fullName: 'Signal Beam',
    iconAsset: 'assets/images/restore_earth/${RE.iconSignal}',
    beamAsset: 'restore_earth/${RE.beamSignal}',
    beamColor: Color(0xFF35C6FF),
    buttonColor: Color(0xFFE07C1C),
    aimCopy: 'Signal mode is on. Let’s aim it where connection is missing.',
    aimVoice: 5,
  ),
  PowerId.scan: PowerDef(
    id: PowerId.scan,
    label: 'SCAN',
    fullName: 'Earth Scan',
    iconAsset: 'assets/images/restore_earth/${RE.iconScan}',
    beamAsset: 'restore_earth/${RE.beamScan}',
    beamColor: Color(0xFF6BFF45),
    buttonColor: Color(0xFF3E9B2E),
    aimCopy: 'Earth Scan is ready. Let’s use it where we need a big view from above.',
    aimVoice: 6,
  ),
};

PowerDef power(PowerId id) => kPowers[id]!;

/// 2×2 grid order (matches the mockup).
const List<PowerId> kPowerGridOrder = [
  PowerId.location,
  PowerId.weather,
  PowerId.signal,
  PowerId.scan,
];
