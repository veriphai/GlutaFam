// Ember — audio/audioplayers_audio.dart
//
// The real EmberAudio, backed by the already-present `audioplayers` package. It
// reads from assets/ember/audio/* using a frozen naming convention and is SAFE
// IF FILES ARE ABSENT: every call is fire-and-forget and swallows load/playback
// errors, so a missing clip degrades to silence instead of crashing. Swap this
// over the default [SilentAudio] via a provider override once clips ship.
//
// Asset convention (declare assets/ember/audio/ in pubspec to activate):
//   one-shots : assets/ember/audio/sfx/<Sfx.name>.mp3
//   loops     : assets/ember/audio/ambience/<Ambience.name>.mp3
//
// Looping beds get a dedicated, reused AudioPlayer per [Ambience] (so loop/stop/
// crossfade target the right bed). One-shots use a small rotating pool so rapid
// taps don't cut each other off.

import 'package:audioplayers/audioplayers.dart';

import '../contracts/ember_audio.dart';

/// audioplayers-backed [EmberAudio]. Fire-and-forget, crash-safe.
class AudioPlayersEmberAudio implements EmberAudio {
  AudioPlayersEmberAudio({
    this.sfxDir = 'ember/audio/sfx/',
    this.ambienceDir = 'ember/audio/ambience/',
    int sfxPoolSize = 6,
    double masterVolume = 1.0,
  })  : _master = masterVolume.clamp(0.0, 1.0),
        _pool = List<AudioPlayer>.generate(
          sfxPoolSize.clamp(1, 16),
          (_) => AudioPlayer()..setReleaseMode(ReleaseMode.stop),
        );

  /// Asset sub-paths (relative to the `assets/` root, as audioplayers expects:
  /// it prefixes `assets/` itself, so we pass `ember/audio/...`).
  final String sfxDir;
  final String ambienceDir;

  final double _master;

  /// Rotating one-shot players.
  final List<AudioPlayer> _pool;
  int _poolCursor = 0;

  /// One dedicated looping player per active [Ambience].
  final Map<Ambience, AudioPlayer> _loops = <Ambience, AudioPlayer>{};

  bool _disposed = false;

  String _sfxPath(Sfx s) => '$sfxDir${s.name}.mp3';
  String _ambiencePath(Ambience a) => '$ambienceDir${a.name}.mp3';

  AudioPlayer _nextPoolPlayer() {
    final AudioPlayer p = _pool[_poolCursor];
    _poolCursor = (_poolCursor + 1) % _pool.length;
    return p;
  }

  @override
  void play(Sfx sfx, {double volume = 1.0}) {
    if (_disposed) return;
    final AudioPlayer p = _nextPoolPlayer();
    // Fire-and-forget; never await, never throw to the caller.
    _safe(() => p.play(
          AssetSource(_sfxPath(sfx)),
          volume: (volume * _master).clamp(0.0, 1.0),
          mode: PlayerMode.lowLatency,
        ));
  }

  @override
  void loop(Ambience ambience, {double volume = 1.0}) {
    if (_disposed) return;
    final AudioPlayer p =
        _loops.putIfAbsent(ambience, () => AudioPlayer());
    _safe(() async {
      await p.setReleaseMode(ReleaseMode.loop);
      await p.play(
        AssetSource(_ambiencePath(ambience)),
        volume: (volume * _master).clamp(0.0, 1.0),
      );
    });
  }

  @override
  void stop([Ambience? ambience]) {
    if (_disposed) return;
    if (ambience == null) {
      for (final AudioPlayer p in _loops.values) {
        _safe(p.stop);
      }
      return;
    }
    final AudioPlayer? p = _loops[ambience];
    if (p != null) _safe(p.stop);
  }

  /// Release all players. Call when tearing down the module.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    for (final AudioPlayer p in _pool) {
      await _safeFuture(p.dispose);
    }
    for (final AudioPlayer p in _loops.values) {
      await _safeFuture(p.dispose);
    }
    _loops.clear();
  }

  /// Runs [action], swallowing any sync throw or async rejection so a missing
  /// asset (or a platform without audio) never bubbles up.
  void _safe(dynamic Function() action) {
    try {
      final dynamic result = action();
      if (result is Future) {
        result.catchError((Object _) {});
      }
    } catch (_) {
      // Intentionally ignored: audio is best-effort.
    }
  }

  Future<void> _safeFuture(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      // Intentionally ignored.
    }
  }
}
