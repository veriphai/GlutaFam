// Ember — data/models/save_envelope.dart
//
// The persisted wrapper around EmberWorldState. Carries a schemaVersion (drives
// migrations) and savedAtMs (wall clock at save). One of these jsonEncode's to
// the single Hive document.

import 'world_state.dart';

class SaveEnvelope {
  const SaveEnvelope({
    required this.schemaVersion,
    required this.savedAtMs,
    required this.state,
  });

  /// Current on-disk schema version. Bump when the JSON shape changes; add a
  /// migration in save_migrations.dart.
  static const int currentSchemaVersion = 1;

  final int schemaVersion;
  final int savedAtMs;
  final EmberWorldState state;

  SaveEnvelope copyWith({
    int? schemaVersion,
    int? savedAtMs,
    EmberWorldState? state,
  }) {
    return SaveEnvelope(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      savedAtMs: savedAtMs ?? this.savedAtMs,
      state: state ?? this.state,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'schemaVersion': schemaVersion,
        'savedAtMs': savedAtMs,
        'state': state.toJson(),
      };

  factory SaveEnvelope.fromJson(Map<String, dynamic> j) => SaveEnvelope(
        schemaVersion: (j['schemaVersion'] as num?)?.toInt() ?? 1,
        savedAtMs: (j['savedAtMs'] as num?)?.toInt() ?? 0,
        state: EmberWorldState.fromJson(
            (j['state'] as Map).cast<String, dynamic>()),
      );

  @override
  bool operator ==(Object other) =>
      other is SaveEnvelope &&
      other.schemaVersion == schemaVersion &&
      other.savedAtMs == savedAtMs &&
      other.state == state;

  @override
  int get hashCode => Object.hash(schemaVersion, savedAtMs, state);
}
