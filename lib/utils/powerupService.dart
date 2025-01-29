import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PowerUpService {
  static const String _cacheKey = "active_powerups";

  // Function to add a power-up to the cache
  Future<void> addPowerUp(Map<String, dynamic> powerup) async {
    final prefs = await SharedPreferences.getInstance();

    // Fetch existing power-ups
    List<String> cachedPowerUps = prefs.getStringList(_cacheKey) ?? [];

    // Add the new power-up
    cachedPowerUps.add(json.encode(powerup));
    await prefs.setStringList(_cacheKey, cachedPowerUps);

    // If validity is greater than 1, set a timer to disable it
    if (powerup['validity'] != 1) {
      _schedulePowerUpExpiry(powerup, prefs);
    }
  }

  // Function to disable a power-up after its validity ends
  Future<void> _schedulePowerUpExpiry(
      Map<String, dynamic> powerup, SharedPreferences prefs) async {
    final int validityMinutes = powerup['validity'];

    // Schedule a timer
    Timer(Duration(minutes: validityMinutes), () async {
      // Fetch active power-ups
      List<String> cachedPowerUps = prefs.getStringList(_cacheKey) ?? [];

      // Remove the expired power-up
      cachedPowerUps.removeWhere((p) => json.decode(p)['id'] == powerup['id']);
      await prefs.setStringList(_cacheKey, cachedPowerUps);
    });
  }

  // Function to fetch all active power-ups
  Future<List<dynamic>> getActivePowerUps() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> cachedPowerUps = prefs.getStringList(_cacheKey) ?? [];
    return cachedPowerUps.map((p) => json.decode(p)).toList();
  }
}
