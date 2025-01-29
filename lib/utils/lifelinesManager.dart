import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LifelineManager {
  static const int maxLifelines = 5;
  static const Duration refillInterval = Duration(hours: 5);

  Timer? _refillTimer;

  Future<int> getLifelines() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('lifelines') ?? maxLifelines; // Default to max
  }

  Future<void> setLifelines(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lifelines', value);
  }

  Future<DateTime?> getLastRefillTime() async {
    final prefs = await SharedPreferences.getInstance();
    final lastRefillMillis = prefs.getInt('lastRefillTime');
    if (lastRefillMillis != null) {
      return DateTime.fromMillisecondsSinceEpoch(lastRefillMillis);
    }
    return null;
  }

  Future<void> setLastRefillTime(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lastRefillTime', time.millisecondsSinceEpoch);
  }

  void startRefillTimer() async {
    _refillTimer?.cancel(); // Cancel existing timer, if any
    _refillTimer = Timer.periodic(refillInterval, (_) async {
      await _refillLifelines();
    });
  }

  void stopRefillTimer() {
    _refillTimer?.cancel();
    _refillTimer = null;
  }

  Future<void> _refillLifelines() async {
    final lifelines = await getLifelines();
    if (lifelines < maxLifelines) {
      await setLifelines(lifelines + 1);
      await setLastRefillTime(DateTime.now());
    }

    // Stop the timer if lifelines are full
    if (lifelines + 1 >= maxLifelines) {
      stopRefillTimer();
    }
  }

  Future<void> reduceLifeline() async {
    final lifelines = await getLifelines();
    if (lifelines > 0) {
      await setLifelines(lifelines - 1);

      // Start the timer if lifelines are less than the max
      if (lifelines - 1 < maxLifelines && _refillTimer == null) {
        startRefillTimer();
      }
    }
  }

  Future<void> initializeLifelines() async {
    final lifelines = await getLifelines();
    final lastRefillTime = await getLastRefillTime();

    if (lifelines < maxLifelines && lastRefillTime != null) {
      final now = DateTime.now();
      final elapsed = now.difference(lastRefillTime);

      // Calculate the number of refills due
      final int refillsDue = elapsed.inHours ~/ refillInterval.inHours;
      if (refillsDue > 0) {
        final newLifelines = (lifelines + refillsDue).clamp(0, maxLifelines);
        await setLifelines(newLifelines);
        await setLastRefillTime(now);
      }
    }

    // Start the timer if lifelines are less than the max
    if (lifelines < maxLifelines) {
      startRefillTimer();
    }
  }
}
