// Persistence for the deck — the first place the module genuinely saves state
// across sessions (per the spec). A simple set of collected card ids in
// shared_preferences; swap for hive/sqflite if the deck grows richer.

import 'package:shared_preferences/shared_preferences.dart';

class CollectibleStore {
  CollectibleStore._();

  static const String _key = 'howwow_collected_card_ids';

  static Future<Set<String>> collected() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_key) ?? const <String>[]).toSet();
  }

  static Future<bool> isCollected(String id) async => (await collected()).contains(id);

  static Future<void> add(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final set = (prefs.getStringList(_key) ?? <String>[]).toSet()..add(id);
    await prefs.setStringList(_key, set.toList());
  }
}
