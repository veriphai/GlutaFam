import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioProvider extends ChangeNotifier {
  AudioPlayer? audioPlayer;
  bool isPlaying = false;
  String? currentAudioUrl;

  /// Sets the audio player for a new audio and stops any currently playing audio.
  Future<void> setAudioPlayer(AudioPlayer player, String audioUrl) async {
    // If a player exists and is playing, stop it
    if (audioPlayer != null && isPlaying) {
      await audioPlayer!.stop();
      isPlaying = false;
    }

    // Assign the new audio player and URL
    audioPlayer = player;
    currentAudioUrl = audioUrl;

    // Start playing the new audio
    await audioPlayer!.play(UrlSource(audioUrl));
    isPlaying = true;
    notifyListeners();
  }

  /// Toggles play/pause for the current audio.
  Future<void> playPauseAudio() async {
    if (audioPlayer != null) {
      if (isPlaying) {
        await audioPlayer!.pause();
      } else {
        await audioPlayer!.resume();
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
