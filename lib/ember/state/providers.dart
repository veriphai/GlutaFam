// Ember — state/providers.dart
//
// The root DI seams. These providers expose the swappable services the rest of
// state/ (and the game/UI) depend on: the save repository, the wall clock, the
// art + audio facades, and the concept registry. ember_app OVERRIDES them at
// bootstrap (real Hive repo, SystemClock, sprite art, audioplayers audio, the
// wired ConceptRegistry); tests/preview leave the safe defaults in place.
//
// FROZEN DECISION: the module uses the legacy Riverpod `Ref` type consistently
// (flutter_riverpod ^2.x). ConceptModule.onInstall(Ref) is handed the
// ProviderContainer-backed Ref at bootstrap, NOT a widget-tree WidgetRef.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../art/ember_art.dart';
import '../art/placeholder_art.dart';
import '../contracts/ember_audio.dart';
import '../core/ember_clock.dart';
import '../data/repository/in_memory_save_repository.dart';
import '../data/repository/save_repository.dart';
import '../registry/concept_registry.dart';

/// The persistence seam. Default = in-memory (platform-channel free) so state/
/// compiles + runs in tests without Hive. ember_app overrides with
/// HiveSaveRepository.
final Provider<SaveRepository> saveRepositoryProvider = Provider<SaveRepository>(
  (Ref ref) => InMemorySaveRepository(),
);

/// The wall-clock seam. Default = SystemClock; tests override with FakeClock.
/// This is the ONLY clock the state layer reads from (offline catch-up,
/// lastSeenMs stamps) — the sim itself never touches it.
final Provider<EmberClock> clockProvider = Provider<EmberClock>(
  (Ref ref) => const SystemClock(),
);

/// The art facade seam. Default = programmatic placeholder art; ember_app may
/// override with sprite-backed art.
final Provider<EmberArt> artProvider = Provider<EmberArt>(
  (Ref ref) => const PlaceholderEmberArt(),
);

/// The audio facade seam. Default = silent (tests/headless); ember_app overrides
/// with the audioplayers-backed implementation.
final Provider<EmberAudio> audioProvider = Provider<EmberAudio>(
  (Ref ref) => const SilentEmberAudio(),
);

/// The concept registry seam. Default = an EMPTY registry so state/ compiles and
/// runs standalone (x1.0 gather, no behaviors/resolvers/defs). ember_app
/// overrides this with the wired ConceptRegistry([fire, tools, shelter]).
final Provider<ConceptRegistry> registryProvider = Provider<ConceptRegistry>(
  (Ref ref) => ConceptRegistry(const <Never>[]),
);
