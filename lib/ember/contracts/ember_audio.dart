// Ember — contracts/ember_audio.dart
//
// The audio facade. Activities/leaves request sound through these closed enums;
// a concrete implementation (audioplayers-backed, in audio/) maps them to files.
// Kept a contract so the sim/activity layers can be silent in tests (a no-op impl)
// and the real player drops in behind the same interface.

/// Closed set of one-shot sound effects.
enum Sfx {
  tap,
  place,
  buildComplete,
  gather,
  fireIgnite,
  fireCrackle,
  toolKnap,
  success,
  failure,
  discover,
  predatorGrowl,
  floodRush,
  thunder,
  uiOpen,
  uiClose,
}

/// Closed set of looping ambience beds.
enum Ambience {
  daytime,
  night,
  rain,
  fireLoop,
  riverLoop,
  windCold,
}

/// The audio seam. A no-op implementation satisfies sim/tests; the real one
/// (audio/) plays through audioplayers. Implementations may be async internally
/// but the contract is fire-and-forget.
abstract interface class EmberAudio {
  /// Plays a one-shot [sfx] at [volume] (0..1).
  void play(Sfx sfx, {double volume = 1.0});

  /// Starts/crossfades a looping [ambience] bed at [volume] (0..1).
  void loop(Ambience ambience, {double volume = 1.0});

  /// Stops a specific looping [ambience], or all loops if null.
  void stop([Ambience? ambience]);
}

/// A do-nothing audio implementation for tests / headless sim runs.
class SilentEmberAudio implements EmberAudio {
  const SilentEmberAudio();

  @override
  void play(Sfx sfx, {double volume = 1.0}) {}

  @override
  void loop(Ambience ambience, {double volume = 1.0}) {}

  @override
  void stop([Ambience? ambience]) {}
}
