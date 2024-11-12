import 'package:flutter/foundation.dart';
// import 'package:audioplayers/audioplayers.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

class AudioProvider extends ChangeNotifier {
  AudioPlayer? audioPlayer;
  bool isPlaying = false;
  String? currentAudioUrl;

  /// Sets the audio player for a new audio and stops any currently playing audio.
  Future<void> setAudioPlayer(
    AudioPlayer player,
    String audioUrl, {
    String album = 'Podcast Album',
    String title = 'Episode Title',
    String artist = 'Podcast Artist',
    String? artUri,
  }) async {
    // If the audio URL is already set and playing, return early
    if (audioPlayer == player && currentAudioUrl == audioUrl && isPlaying) {
      return; // Avoid resetting the URL and position
    }

    // If a player exists and is playing, stop it
    if (audioPlayer != null && isPlaying) {
      await audioPlayer!.stop();
      isPlaying = false;
    }

    // Assign the new audio player and URL
    audioPlayer = player;
    currentAudioUrl = audioUrl;

    // Define media item with metadata for lock screen and notifications
    final mediaItem = MediaItem(
      id: audioUrl,
      album: album,
      title: title,
      artist: artist,
      artUri:
          artUri != null ? Uri.parse(artUri) : null, // Set artUri if provided
    );

    // Set audio source with metadata for background playback
    await player.setAudioSource(
      AudioSource.uri(
        Uri.parse(audioUrl),
        tag: mediaItem,
      ),
    );

    // Start playback
    await player.play();
    isPlaying = true;
    notifyListeners();
  }

  /// Toggles play/pause for the current audio.
  Future<void> playPauseAudio() async {
    if (audioPlayer != null) {
      if (isPlaying) {
        await audioPlayer!.pause();
      } else {
        await audioPlayer!.play();
      }
      isPlaying = !isPlaying;
      notifyListeners();
    }
  }

  /// Stops the audio playback completely.
  Future<void> stopAudio() async {
    await audioPlayer?.stop();
    isPlaying = false;
    notifyListeners();
  }

  /// Disposes the audio player if necessary.
  void disposeAudioPlayer() {
    audioPlayer?.dispose();
    audioPlayer = null;
  }
}
