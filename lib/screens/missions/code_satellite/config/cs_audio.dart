// Shared audio infrastructure for Code the Satellite: the no-focus mix context
// (EVERY player must use it) + the looping BGM bed with ducking.
//
// ⚠️ Android audio-focus steal (verified in How Much Can You See): audioplayers
// requests audio focus on every play() from the player's OWN AudioContextAndroid
// (default `gain`), so a voice player starting PAUSES the looping BGM player —
// and focus-paused players never auto-resume. `AudioPlayer.global.
// setAudioContext` does NOT fix it (only copied into players created AFTER the
// call). The fix is `setAudioContext(kMixAudioContext)` on EVERY player —
// `AndroidAudioFocus.none` means focus is never requested, so all in-app lanes
// mix, and loudness is handled by manual setVolume ducking. Sequence: set
// contexts first, THEN start the BGM loop.

import 'package:audioplayers/audioplayers.dart';

import '../../../../utils/s3_audio.dart';

/// Per-player context that opts out of the focus system (Android) / mixes with
/// others (iOS). Web/desktop have no focus system — this is phone-critical.
final AudioContext kMixAudioContext = AudioContext(
  android: const AudioContextAndroid(audioFocus: AndroidAudioFocus.none),
  iOS: AudioContextIOS(
    category: AVAudioSessionCategory.playback,
    options: const {AVAudioSessionOptions.mixWithOthers},
  ),
);

/// The looping ambient bed. One per activity run: the shell starts/stops it;
/// the shell's voice lane and every scene's OrbitVoiceThread duck it while
/// Orbit speaks. Duck holds are COUNTED so overlapping speakers can't
/// un-duck each other early — callers must pair duck()/unduck() exactly.
class CsBgm {
  CsBgm._();
  static final CsBgm I = CsBgm._();

  static const double _base = 0.20; // ambient bed
  static const double _ducked = 0.05; // while Orbit speaks

  final AudioPlayer _player = AudioPlayer();
  bool _started = false;
  int _holds = 0;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    _holds = 0;
    await _player.setAudioContext(kMixAudioContext).catchError((_) {});
    await _player.setReleaseMode(ReleaseMode.loop);
    _player
        .play(audioSource('sounds/code_satellite/bgm.mp3'), volume: _base)
        .catchError((_) {});
  }

  void duck() {
    _holds++;
    _player.setVolume(_ducked).catchError((_) {});
  }

  void unduck() {
    if (_holds > 0) _holds--;
    if (_holds == 0 && _started) {
      _player.setVolume(_base).catchError((_) {});
      _player.resume().catchError((_) {}); // belt-and-braces vs focus pause
    }
  }

  Future<void> stop() async {
    _started = false;
    _holds = 0;
    await _player.stop().catchError((_) {});
  }
}
