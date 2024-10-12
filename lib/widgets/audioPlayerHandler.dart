// import 'package:audio_service/audio_service.dart';
// import 'package:just_audio/just_audio.dart';

// class AudioPlayerHandler extends BaseAudioHandler with SeekHandler {
//   final AudioPlayer _audioPlayer = AudioPlayer();

//   AudioPlayerHandler() {
//     // Listen to playback events and update the playback state
//     _audioPlayer.playbackEventStream.listen((event) {
//       playbackState.add(_transformEventToPlaybackState(event));
//     });

//     // Update the position of the current playback
//     _audioPlayer.positionStream.listen((position) {
//       final mediaItem = this.mediaItem.value;
//       if (mediaItem != null) {
//         // Update the media item with the new position and duration
//         final updatedMediaItem =
//             mediaItem.copyWith(duration: _audioPlayer.duration);
//         this.mediaItem.add(updatedMediaItem);
//       }
//     });
//   }

//   @override
//   Future<void> play() => _audioPlayer.play();
//   @override
//   Future<void> pause() => _audioPlayer.pause();
//   @override
//   Future<void> stop() => _audioPlayer.stop();
//   @override
//   Future<void> seek(Duration position) => _audioPlayer.seek(position);

//   Future<void> loadMediaItem({
//     required String id,
//     required String album,
//     required String title,
//     required String artist,
//     required String audioUrl,
//     required String artUri,
//   }) async {
//     // Update the MediaItem with the podcast details
//     mediaItem.add(
//       MediaItem(
//         id: id,
//         album: album,
//         title: title,
//         artist: artist,
//         artUri: Uri.parse(artUri),
//         duration: _audioPlayer.duration,
//       ),
//     );

//     // Load the audio from the URL
//     await _audioPlayer.setUrl(audioUrl);
//   }

//   // Transform just_audio's event to audio_service's PlaybackState
//   PlaybackState _transformEventToPlaybackState(AudioPlaybackEvent event) {
//     return PlaybackState(
//       controls: [
//         MediaControl.skipToPrevious,
//         if (_audioPlayer.playing) MediaControl.pause else MediaControl.play,
//         MediaControl.stop,
//         MediaControl.skipToNext,
//       ],
//       androidCompactActionIndices: const [0, 1, 3],
//       systemActions: const {
//         MediaAction.seek,
//       },
//       processingState: _transformProcessingState(_audioPlayer.processingState),
//       playing: _audioPlayer.playing,
//       updatePosition: _audioPlayer.position,
//       bufferedPosition: _audioPlayer.bufferedPosition,
//       speed: _audioPlayer.speed,
//       queueIndex: null,
//     );
//   }

//   // Helper method to map just_audio's processing states to audio_service states
//   AudioProcessingState _transformProcessingState(ProcessingState state) {
//     switch (state) {
//       case ProcessingState.idle:
//         return AudioProcessingState.idle;
//       case ProcessingState.loading:
//         return AudioProcessingState.loading;
//       case ProcessingState.buffering:
//         return AudioProcessingState.buffering;
//       case ProcessingState.ready:
//         return AudioProcessingState.ready;
//       case ProcessingState.completed:
//         return AudioProcessingState.completed;
//     }
//   }
// }
