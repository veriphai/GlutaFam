// Ember — data/repository/save_repository.dart
//
// The persistence seam. state/ depends on this interface, never on Hive
// directly, so tests/preview can swap in InMemorySaveRepository.

import '../models/save_envelope.dart';

abstract interface class SaveRepository {
  /// Loads + migrates the current save, or null if none exists.
  Future<SaveEnvelope?> load();

  /// Persists [e] as the current save (overwrites).
  Future<void> save(SaveEnvelope e);

  /// Whether a save exists.
  Future<bool> exists();

  /// Deletes the save (new-game reset).
  Future<void> wipe();
}
