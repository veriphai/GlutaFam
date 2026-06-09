// A self-contained sequential voice thread for the static scenes (intro /
// brief / success): plays a list of Orbit clips in order on its OWN player,
// exposing the current clip index (drives bubble reveals) and a done flag
// (gates the closing CTA). Advance is idempotent and driven by
// onPlayerComplete with a clip-length+2.5s safety/reading fallback, so muted
// users and missing assets still progress (playbook: never completion-only,
// never fixed-timer-only). dispose() stops audio so lines never leak across
// scene transitions.

import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../config/cs_audio.dart';
import '../config/orbit_voice.dart';

class OrbitVoiceThread {
  OrbitVoiceThread({required this.clips, this.gapMs = 320});

  final List<int> clips;
  final int gapMs;

  final AudioPlayer _player = AudioPlayer();

  /// Index into [clips] currently playing (bubbles ≤ this index are revealed).
  final ValueNotifier<int> current = ValueNotifier(0);
  final ValueNotifier<bool> done = ValueNotifier(false);

  StreamSubscription<void>? _sub;
  Timer? _timer;
  bool _disposed = false;
  int _advancedFor = -1;
  bool _duckHeld = false;

  void start() {
    _player.setReleaseMode(ReleaseMode.stop);
    // No-focus mix context BEFORE any play(), or this player's first clip
    // pauses the BGM bed forever on Android (focus steal).
    _player.setAudioContext(kMixAudioContext).catchError((_) {});
    _sub = _player.onPlayerComplete.listen((_) => _advance());
    // duck the bed for the whole thread (clips chain with small gaps).
    _duckHeld = true;
    CsBgm.I.duck();
    _playIndex(0);
  }

  void _releaseDuck() {
    if (_duckHeld) {
      _duckHeld = false;
      CsBgm.I.unduck();
    }
  }

  void _playIndex(int i) {
    if (_disposed) return;
    if (i >= clips.length) {
      done.value = true;
      _releaseDuck();
      return;
    }
    current.value = i;
    final clip = clips[i];
    _player.stop();
    _player.play(orbitClipSource(clip)).catchError((_) {});
    // Safety / muted reading fallback — completion normally beats this.
    _timer?.cancel();
    final secs = (kOrbitClipSecs[clip] ?? 4.0) + 2.5;
    _timer = Timer(Duration(milliseconds: (secs * 1000).round()), _advance);
  }

  void _advance() {
    if (_disposed || _advancedFor >= current.value) return;
    _advancedFor = current.value;
    _timer?.cancel();
    Timer(Duration(milliseconds: gapMs), () {
      if (!_disposed) _playIndex(_advancedFor + 1);
    });
  }

  void dispose() {
    _disposed = true;
    _releaseDuck();
    _timer?.cancel();
    _sub?.cancel();
    _player.stop();
    _player.dispose();
    current.dispose();
    done.dispose();
  }
}
