// Ember — audio/silent_audio.dart
//
// The no-op EmberAudio: the DEFAULT until real SFX assets exist. Tests, headless
// sim runs, and the boot-with-no-audio path all use this so nothing ever blocks
// on the audio facade.
//
// The contract already ships a const [SilentEmberAudio] in contracts/; this file
// gives the audio/ package its canonical, named default and a const singleton so
// callers in state/ and game/ can wire `const SilentAudio()` without importing
// the contracts package directly for the impl.

import '../contracts/ember_audio.dart';

/// A do-nothing [EmberAudio]. Every call is a safe no-op.
class SilentAudio implements EmberAudio {
  const SilentAudio();

  /// Shared const instance — the module-wide default audio sink.
  static const SilentAudio instance = SilentAudio();

  @override
  void play(Sfx sfx, {double volume = 1.0}) {}

  @override
  void loop(Ambience ambience, {double volume = 1.0}) {}

  @override
  void stop([Ambience? ambience]) {}
}
