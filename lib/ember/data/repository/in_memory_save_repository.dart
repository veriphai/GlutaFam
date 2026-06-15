// Ember — data/repository/in_memory_save_repository.dart
//
// A platform-channel-free fake SaveRepository for tests + the standalone
// preview loop. Persists by jsonEncode round-tripping through migrations, so it
// exercises the SAME serialization path as Hive (catching round-trip bugs).

import 'dart:convert';

import '../models/save_envelope.dart';
import 'save_migrations.dart';
import 'save_repository.dart';

class InMemorySaveRepository implements SaveRepository {
  InMemorySaveRepository({SaveMigrations? migrations})
      : _migrations = migrations ?? const SaveMigrations();

  final SaveMigrations _migrations;

  /// The single encoded document (mirrors Hive's one-string storage).
  String? _doc;

  @override
  Future<SaveEnvelope?> load() async {
    final String? raw = _doc;
    if (raw == null) return null;
    final Map<String, dynamic> decoded =
        (jsonDecode(raw) as Map).cast<String, dynamic>();
    final Map<String, dynamic> migrated = _migrations.migrate(decoded);
    return SaveEnvelope.fromJson(migrated);
  }

  @override
  Future<void> save(SaveEnvelope e) async {
    _doc = jsonEncode(e.toJson());
  }

  @override
  Future<bool> exists() async => _doc != null;

  @override
  Future<void> wipe() async {
    _doc = null;
  }
}
