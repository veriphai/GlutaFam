import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart' as just_audio;

class MyAudioHandler extends BaseAudioHandler {
  final just_audio.AudioPlayer _audioPlayer = just_audio.AudioPlayer();

  MyAudioHandler() {
    _init();
  }

  Future<void> _init() async {
    // Set up listeners for updating state and metadata
    _audioPlayer.playerStateStream.listen((playerState) {
      playbackState.add(playbackState.value.copyWith(
        controls: [
          MediaControl.pause,
          MediaControl.play,
          MediaControl.stop,
        ],
        systemActions: const {MediaAction.seek},
        playing: playerState.playing,
        processingState: _mapProcessingState(playerState.processingState),
      ));
    });

    _audioPlayer.durationStream.listen((duration) {
      if (duration != null) {
        mediaItem.add(mediaItem.value?.copyWith(duration: duration));
      }
    });

    _audioPlayer.positionStream.listen((position) {
      playbackState.add(playbackState.value.copyWith(
        updatePosition: position, // Use `updatePosition` instead of `position`
      ));
    });
  }

  AudioProcessingState _mapProcessingState(just_audio.ProcessingState state) {
    switch (state) {
      case just_audio.ProcessingState.idle:
        return AudioProcessingState.idle;
      case just_audio.ProcessingState.loading:
      case just_audio.ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case just_audio.ProcessingState.ready:
        return AudioProcessingState.ready;
      case just_audio.ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

  @override
  Future<void> play() => _audioPlayer.play();

  @override
  Future<void> pause() => _audioPlayer.pause();

  @override
  Future<void> stop() => _audioPlayer.stop();

  Future<void> setUrl(String url) async {
    await _audioPlayer.setUrl(url);
    mediaItem.add(MediaItem(id: url, title: "Audio Playback"));
  }
}
