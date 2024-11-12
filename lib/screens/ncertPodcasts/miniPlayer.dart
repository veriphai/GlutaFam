// import 'package:audioplayers/audioplayers.dart';
import 'package:eureka_app/screens/ncertPodcasts/podcastScreen.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class MiniPlayer extends StatefulWidget {
  final String episodeImageUrl;
  final String chapterName;
  final String episodeName;
  final int duration;
  final String audioUrl;
  final AudioPlayer audioPlayer;
  final String description;
  final String chapterId;
  final int chapterNo;
  final Map<String, dynamic> cerData;
  final String? pdfUrl;
  final Duration currentPosition;
  final Duration totalDuration;
  final bool isPlaying;

  MiniPlayer(
      {required this.episodeImageUrl,
      required this.chapterName,
      required this.episodeName,
      required this.duration,
      required this.audioUrl,
      required this.audioPlayer,
      required this.description,
      required this.chapterId,
      required this.chapterNo,
      required this.cerData,
      required this.pdfUrl,
      required this.currentPosition,
      required this.totalDuration,
      required this.isPlaying});

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> {
  // late AudioPlayer _audioPlayer;
  bool isPlaying = false;
  Duration currentPosition = Duration.zero;
  Duration totalDuration = Duration.zero;

  @override
  void initState() {
    // widget.audioPlayer = AudioPlayer();
    super.initState();

    widget.audioPlayer.durationStream.listen((Duration? duration) {
      if (mounted && duration != null) {
        setState(() {
          totalDuration = duration;
        });
      }
    });

    widget.audioPlayer.positionStream.listen((Duration position) {
      if (mounted) {
        setState(() {
          currentPosition = position;
        });
      }
    });

    widget.audioPlayer.playerStateStream.listen((playerState) {
      if (mounted) {
        setState(() {
          isPlaying = playerState
              .playing; // Update isPlaying based on actual playback state
        });
      }
    });

    // Set initial play/pause icon state based on audio player
    isPlaying = widget.audioPlayer.playing;

    // playPauseAudio();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void playPauseAudio() async {
    print("Audio playing from miniplayer.");

    if (isPlaying) {
      await widget.audioPlayer.pause();
      setState(() {
        isPlaying = false;
      });
    } else {
      // Remove the setUrl() call to avoid resetting the playback position
      await widget.audioPlayer.play();
      setState(() {
        isPlaying = true;
      });
    }
  }

  String _formatEndTimeDuration(int duration) {
    final endDuration = Duration(seconds: (duration ~/ 1000).toInt());
    return "${endDuration.inMinutes} mins ${(endDuration.inSeconds % 60).toString()} seconds";
  }

  @override
  Widget build(BuildContext context) {
    // print("Miniplayer current position: ${widget.currentPosition}");
    // print("Miniplayer total duration: ${widget.totalDuration}");
    return GestureDetector(
      onTap: () {
        // widget.audioPlayer.pause();
        print("total duration ********************: ${totalDuration}");
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PodcastScreen(
              title: widget.episodeName,
              description: widget.description,
              imageUrl: widget.episodeImageUrl,
              audioUrl: widget.audioUrl,
              duration: widget.duration,
              chapterName: widget.chapterName,
              chapterNo: widget.chapterNo,
              cerData: widget.cerData,
              chapterId: widget.chapterId,
              sectionNumber: 1,
              audioPlayer: widget.audioPlayer,
              totalDurationFromMiniplayer: totalDuration,
            ),
          ),
        );
      },
      child: Container(
        color: Colors.grey[900],
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // LinearProgressIndicator(
            //   value: progress,
            //   backgroundColor: Colors.grey,
            //   valueColor: AlwaysStoppedAnimation<Color>(Colors.yellowAccent),
            // ),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    widget.episodeImageUrl,
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
                      widget.episodeName,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      widget.chapterName,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _formatEndTimeDuration(widget.duration),
                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                    )
                  ],
                )),
                IconButton(
                  icon: Icon(
                    isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_fill,
                    color: Color.fromRGBO(255, 217, 0, 1),
                    size: 40,
                  ),
                  onPressed: playPauseAudio,
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
