import 'package:audioplayers/audioplayers.dart';
import 'package:eureka_app/screens/ncertPodcasts/podcastScreen.dart';
import 'package:flutter/material.dart';

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

  MiniPlayer({
    required this.episodeImageUrl,
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
  });

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

    widget.audioPlayer.onDurationChanged.listen((Duration duration) {
      if (mounted) {
        setState(() {
          totalDuration = duration;
        });
      }
    });

    widget.audioPlayer.onPositionChanged.listen((Duration position) {
      if (mounted) {
        setState(() {
          currentPosition = position;
        });
      }
    });

    playPauseAudio();
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
      await widget.audioPlayer.play(UrlSource(widget.audioUrl));
      setState(() {
        isPlaying = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // print("Miniplayer current position: ${widget.currentPosition}");
    // print("Miniplayer total duration: ${widget.totalDuration}");
    return GestureDetector(
      onTap: () {
        widget.audioPlayer.pause();
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
                Image.network(
                  widget.episodeImageUrl,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
                const SizedBox(width: 10),
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.chapterName,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      widget.episodeName,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${widget.duration ~/ 60} min ${widget.duration % 60} sec',
                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                    )
                  ],
                )),
                IconButton(
                  icon: Icon(
                    isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_fill,
                    color: Colors.yellowAccent,
                    size: 36,
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
