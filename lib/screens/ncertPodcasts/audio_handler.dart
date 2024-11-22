
import 'package:audio_service/audio_service.dart';
import 'package:audioplayers/audioplayers.dart' as audioPlayers;
import 'package:just_audio/just_audio.dart' as justAudio;

class MyAudioHandler extends BaseAudioHandler with SeekHandler {
  final justAudio.AudioPlayer _player = justAudio.AudioPlayer();

  MyAudioHandler() {
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);

    mediaItem.add(MediaItem(
      id: '1', 
      title: "Sample Audio",
    ));
  }

  Future<void> setAudioSource(String audioUrl) async{
    try {
      await _player.setUrl(audioUrl);
      mediaItem.add(MediaItem(
        id: audioUrl, 
        title: "Audio lesson",
      ));
    } catch (e) {
      print("Error setting audio source: $e");
    }
  }



  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() => _player.stop();

  PlaybackState _transformEvent(justAudio.PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.rewind,
        _player.playing ? MediaControl.pause : MediaControl.play,
        MediaControl.stop,
        MediaControl.fastForward,
      ],
      androidCompactActionIndices: const [0,1,3],
      systemActions: const {MediaAction.seek},
      processingState: {
        justAudio.ProcessingState.idle: AudioProcessingState.idle,
        justAudio.ProcessingState.loading: AudioProcessingState.loading,
        justAudio.ProcessingState.buffering: AudioProcessingState.buffering,
        justAudio.ProcessingState.ready: AudioProcessingState.ready,
        justAudio.ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      updateTime: DateTime.now(),
    );
  }
}