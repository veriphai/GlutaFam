// The four satellite types the child dispatches (PRD §5.2, §11). Each type
// carries its own display label, hero sprite, tray accent colour, and a small
// Material glyph used as the tray-card function accent — so the tray is built
// from this enum, never hardcoded per card.

import 'package:flutter/material.dart';

import '../../../home/career/careerTheme.dart';
import '../config/asset_paths.dart';

enum SatelliteType { navigation, weather, communication, earthObservation }

extension SatelliteTypeX on SatelliteType {
  /// Short tray label (PRD §10.6).
  String get label {
    switch (this) {
      case SatelliteType.navigation:
        return 'Navigation';
      case SatelliteType.weather:
        return 'Weather';
      case SatelliteType.communication:
        return 'Communication';
      case SatelliteType.earthObservation:
        return 'Earth Observation';
    }
  }

  /// The hero satellite sprite (tray card + drag sprite + success dock).
  String get sprite {
    switch (this) {
      case SatelliteType.navigation:
        return CrsAssets.satelliteNavigation;
      case SatelliteType.weather:
        return CrsAssets.satelliteWeather;
      case SatelliteType.communication:
        return CrsAssets.satelliteCommunication;
      case SatelliteType.earthObservation:
        return CrsAssets.satelliteEarthObservation;
    }
  }

  /// Tray-card accent / glow colour.
  Color get accent {
    switch (this) {
      case SatelliteType.navigation:
        return CareerColors.orange;
      case SatelliteType.weather:
        return CareerColors.cyan;
      case SatelliteType.communication:
        return CareerColors.blue;
      case SatelliteType.earthObservation:
        return CareerColors.green;
    }
  }

  /// Small function glyph shown on the tray card + mission-log row.
  IconData get glyph {
    switch (this) {
      case SatelliteType.navigation:
        return Icons.location_on_rounded;
      case SatelliteType.weather:
        return Icons.cloud_rounded;
      case SatelliteType.communication:
        return Icons.settings_input_antenna_rounded;
      case SatelliteType.earthObservation:
        return Icons.photo_camera_rounded;
    }
  }

  /// Analytics token.
  String get id {
    switch (this) {
      case SatelliteType.navigation:
        return 'navigation';
      case SatelliteType.weather:
        return 'weather';
      case SatelliteType.communication:
        return 'communication';
      case SatelliteType.earthObservation:
        return 'earthObservation';
    }
  }
}
