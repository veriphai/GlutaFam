// THROWAWAY headless-preview entrypoint (playbook Phase 6) — boots straight
// into the Save the Coastal City mission so Playwright can screenshot/drive
// it without in-app navigation. DELETE before shipping.

import 'package:flutter/material.dart';

import 'screens/missions/save_coastal_city/save_coastal_city_screen.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: SaveCoastalCityMissionScreen(),
  ));
}
