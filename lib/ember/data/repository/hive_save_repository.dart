// Ember — data/repository/hive_save_repository.dart
//
// Hive-backed SaveRepository. LOCKED design: persistence is ONE jsonEncode'd
// String in a Box<String> (box 'ember_save', key 'current'). No Hive adapters,
// no build_runner — the whole world is one deterministic JSON document. This is
// the ONLY file in F1 allowed to touch hive/hive_flutter.

import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../models/save_envelope.dart';
import 'save_migrations.dart';
import 'save_repository.dart';

class HiveSaveRepository implements SaveRepository {
  HiveSaveRepository({SaveMigrations? migrations})
      : _migrations = migrations ?? const SaveMigrations();

  static const String boxName = 'ember_save';
  static const String docKey = 'current';

  final SaveMigrations _migrations;
  Box<String>? _box;

  /// Initializes Hive (idempotent) and opens the single string box. Call once
  /// at bootstrap before load/save. Safe to call multiple times.
  Future<void> init() async {
    if (_box != null && _box!.isOpen) return;
    // Hive.initFlutter is idempotent across the app; harmless if already done.
    await Hive.initFlutter();
    _box = await Hive.openBox<String>(boxName);
  }

  Future<Box<String>> _ensureBox() async {
    if (_box == null || !_box!.isOpen) {
      await init();
    }
    return _box!;
  }

  @override
  Future<SaveEnvelope?> load() async {
    final Box<String> box = await _ensureBox();
    final String? raw = box.get(docKey);
    if (raw == null || raw.isEmpty) return null;
    final Map<String, dynamic> decoded =
        (jsonDecode(raw) as Map).cast<String, dynamic>();
    final Map<String, dynamic> migrated = _migrations.migrate(decoded);
    return SaveEnvelope.fromJson(migrated);
  }

  @override
  Future<void> save(SaveEnvelope e) async {
    final Box<String> box = await _ensureBox();
    await box.put(docKey, jsonEncode(e.toJson()));
  }

  @override
  Future<bool> exists() async {
    final Box<String> box = await _ensureBox();
    final String? raw = box.get(docKey);
    return raw != null && raw.isNotEmpty;
  }

  @override
  Future<void> wipe() async {
    final Box<String> box = await _ensureBox();
    await box.delete(docKey);
  }
}
