// Ember — data/repository/save_migrations.dart
//
// Forward-only JSON migrations vN -> vN+1, applied to the RAW decoded map before
// SaveEnvelope.fromJson runs. Pure functions; no clock/random. v1 is identity.
//
// When the on-disk shape changes:
//   1. bump SaveEnvelope.currentSchemaVersion
//   2. add a `_steps[oldVersion] = (json) => migrated`
//   3. migrate() chains every step from the file's version up to current.

import '../models/save_envelope.dart';

class SaveMigrations {
  const SaveMigrations();

  /// Map of fromVersion -> transform producing the next version's shape.
  /// Empty for v1 (nothing to migrate yet); identity is implied.
  static final Map<int, Map<String, dynamic> Function(Map<String, dynamic>)>
      _steps = <int, Map<String, dynamic> Function(Map<String, dynamic>)>{
    // Example for the future:
    // 1: (Map<String, dynamic> j) { ...transform v1 -> v2...; return j; },
  };

  /// Migrates a raw decoded save map up to [SaveEnvelope.currentSchemaVersion].
  /// Returns a map safe to pass to SaveEnvelope.fromJson.
  Map<String, dynamic> migrate(Map<String, dynamic> raw) {
    Map<String, dynamic> j = Map<String, dynamic>.of(raw);
    int version = (j['schemaVersion'] as num?)?.toInt() ?? 1;

    while (version < SaveEnvelope.currentSchemaVersion) {
      final Map<String, dynamic> Function(Map<String, dynamic>)? step =
          _steps[version];
      if (step == null) {
        // No transform registered: bump version (treated as identity) so we
        // never loop forever. This keeps unknown-but-compatible bumps working.
        version += 1;
        j['schemaVersion'] = version;
        continue;
      }
      j = step(j);
      version += 1;
      j['schemaVersion'] = version;
    }
    return j;
  }
}
