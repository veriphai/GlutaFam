// A drop-in, NON-VISUAL looping background-music bed for an activity. Place it
// anywhere in the widget tree (typically as the first child of the activity's
// body Stack); it plays [asset] on mount — looped, at a low ambient volume,
// MIXING with any other app audio (it never grabs audio focus) — and stops +
// disposes its player on unmount. Renders nothing (a zero-size box).
//
// The path is resolved through [audioSource], so S3-hosted activity beds
// (`sounds/<id>/bgm.mp3`) stream/cache exactly like everywhere else, while
// bundled paths fall back to AssetSource — no per-call-site decision needed.

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';

import '../../utils/s3_audio.dart' show audioSource;

class ActivityBgm extends StatefulWidget {
  const ActivityBgm(this.asset, {super.key, this.volume = 0.18});

  /// e.g. `'sounds/build_satellite/bgm.mp3'` — relative to `assets/` /
  /// resolvable by [audioSource] (S3 or bundle).
  final String asset;
  final double volume;

  @override
  State<ActivityBgm> createState() => _ActivityBgmState();
}

class _ActivityBgmState extends State<ActivityBgm> {
  final AudioPlayer _player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _player.setReleaseMode(ReleaseMode.loop);
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    // Per-player context: mix with other audio rather than seizing focus.
    final mix = AudioContext(
      android: AudioContextAndroid(audioFocus: AndroidAudioFocus.none),
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playback,
        options: const {AVAudioSessionOptions.mixWithOthers},
      ),
    );
    await _player.setAudioContext(mix).catchError((_) {});
    if (!mounted) return;
    _player.play(audioSource(widget.asset), volume: widget.volume).catchError((_) {});
  }

  @override
  void dispose() {
    _player.stop().catchError((_) {});
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
