// import 'package:audioplayers/audioplayers.dart';
import 'dart:math';

import 'package:eureka_app/apis/submitFeedbackApi.dart';
import 'package:eureka_app/events/miniPlayerEvents.dart';
import 'package:eureka_app/screens/ncertPodcasts/earlyExitFeedbackModal.dart';
import 'package:eureka_app/screens/ncertPodcasts/podcastScreen.dart';
import 'package:eureka_app/services/audioProvider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MiniPlayer extends StatefulWidget {
  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> {
  Duration currentPosition = Duration.zero;
  Duration totalDuration = Duration.zero;
  int earlyExitModalLastDisplayTime = 0;

  void getTimeForLastAppearanceEarlyExitModal() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      earlyExitModalLastDisplayTime =
          prefs.getInt('earlyExitModalShownTime') ?? 0;
    });
  }

  @override
  void initState() {
    super.initState();
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);

    // Listen to duration changes
    audioProvider.audioPlayer?.durationStream.listen((Duration? duration) {
      if (mounted && duration != null) {
        setState(() {
          totalDuration = duration;
        });
      }
    });

    // Listen to position changes
    audioProvider.audioPlayer?.positionStream.listen((Duration position) {
      if (mounted) {
        setState(() {
          currentPosition = position;
        });
      }
    });

    // Listen to play/pause state changes
    audioProvider.audioPlayer?.playerStateStream.listen((playerState) {
      if (mounted) {
        setState(() {
          audioProvider.isPlaying = playerState.playing;
        });
      }
    });

    // Set initial play/pause icon state
    audioProvider.isPlaying = audioProvider.audioPlayer?.playing ?? false;
  }

  bool earlyExitModalToShow() {
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    int currentEpochTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    int randomNumber = Random().nextInt(10) + 1;
    bool shouldShowModal = randomNumber % 3 == 0 &&
        audioProvider.subSectionNumber < 2 &&
        currentEpochTime - earlyExitModalLastDisplayTime > 300;
    return shouldShowModal;
  }

  void playPauseAudio() async {
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);

    if (earlyExitModalToShow() && audioProvider.audioPlayer!.playing) {
      _showEarlyExitModal(() {});
    }
    await audioProvider.playPauseAudio();
  }

  String _formatEndTimeDuration(int duration) {
    final endDuration = Duration(seconds: (duration ~/ 1000).toInt());
    return "${endDuration.inMinutes} mins ${(endDuration.inSeconds % 60).toString()} seconds";
  }

  void _showEarlyExitModal(VoidCallback onClose) {
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return EarlyExitFeedbackModal(onSubmit: (selectedOptions) {
          // Handle feedback submission here
          print("User feedback: $selectedOptions");
          submitFeedback(
            chapterId: audioProvider.chapterId,
            sectionId: audioProvider.sectionId,
            feedbackOptions: selectedOptions.toList(),
            type: 'earlyExit',
          );
          Navigator.of(context).pop(); // Close the modal
          onClose(); // Close the MiniPlayer after feedback
        }, onclose: () {
          Navigator.of(context).pop();
          onClose();
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context);
    getTimeForLastAppearanceEarlyExitModal();
    return Visibility(
      visible: audioProvider.showMiniPlayer,
      child: GestureDetector(
        onTap: () {
          logMiniPlayerClick(
              audioProvider.sectionId,
              audioProvider.audioPlayer!.playing,
              audioProvider.audioPlayer!.position.inSeconds);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PodcastScreen(
                  title: audioProvider.episodeName,
                  description: audioProvider.description,
                  imageUrl: audioProvider.artUri ?? '',
                  audioUrl: audioProvider.currentAudioUrl ?? '',
                  duration: audioProvider.duration,
                  chapterName: audioProvider.chapterName,
                  chapterNo: audioProvider.chapterNo,
                  cerData: audioProvider.cerData,
                  chapterId: audioProvider.chapterId,
                  sectionId: audioProvider.sectionId,
                  sectionNumber: audioProvider.sectionNumber,
                  audioPlayer: audioProvider.audioPlayer!,
                  totalDurationFromMiniplayer: totalDuration,
                  pdfUrl: audioProvider.pdfUrl,
                  subsections: audioProvider.subsections,
                  sectionEndQuestions: audioProvider.sectionEndQuestions),
            ),
          );
        },
        child: Container(
          color: Colors.grey[900],
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              const SizedBox(width: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  audioProvider.artUri ?? "",
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      audioProvider.episodeName,
                      style: GoogleFonts.raleway(
                          color: Colors.white, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      audioProvider.chapterName,
                      style:
                          GoogleFonts.raleway(color: Colors.grey, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                    // Text(
                    //   _formatEndTimeDuration(audioProvider.duration),
                    //   style: const GoogleFonts.raleway(color: Colors.grey, fontSize: 10),
                    // )
                  ],
                ),
              ),
              IconButton(
                padding:
                    EdgeInsets.zero, // Removes default padding around the icon

                icon: Icon(
                  audioProvider.isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_fill,
                  color: Color.fromRGBO(255, 217, 0, 1),
                  size: 40,
                ),
                onPressed: playPauseAudio,
              ),
              Container(
                height: 35, // Adjust height
                width: 35,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.transparent,
                  border: Border.all(
                    color: Color.fromRGBO(255, 217, 0, 1), // Border color
                    width: 2.0, // Border width
                  ),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.close,
                    color: Color.fromRGBO(255, 217, 0, 1),
                    size: 16,
                  ),
                  onPressed: () {
                    if (earlyExitModalToShow()) {
                      _showEarlyExitModal(() {
                        // Close the MiniPlayer after submitting feedback
                        audioProvider.stopAudio();
                        audioProvider.showMiniPlayer = false;
                      });
                    } else {
                      // Close the MiniPlayer directly
                      audioProvider.stopAudio();
                      audioProvider.showMiniPlayer = false;
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
