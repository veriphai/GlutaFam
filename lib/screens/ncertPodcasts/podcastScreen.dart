import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class PodcastScreen extends StatefulWidget {
  final String title;
  final String description;
  final String imageUrl;
  final String audioUrl;
  final int duration;

  const PodcastScreen({
    Key? key,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.audioUrl,
    required this.duration,
  }) : super(key: key);

  @override
  _PodcastScreenState createState() => _PodcastScreenState();
}

class _PodcastScreenState extends State<PodcastScreen> {
  late AudioPlayer _audioPlayer;
  bool isPlaying = false;
  Duration currentPosition = Duration.zero;
  Duration totalDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();

    // Set audio player listeners
    _audioPlayer.onDurationChanged.listen((Duration duration) {
      setState(() {
        totalDuration = duration;
      });
    });

    _audioPlayer.onPositionChanged.listen((Duration position) {
      setState(() {
        currentPosition = position;
      });
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      setState(() {
        isPlaying = false;
        currentPosition = Duration.zero;
      });
    });

    playPauseAudio();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void playPauseAudio() async {
    if (isPlaying) {
      await _audioPlayer.pause();
      setState(() {
        isPlaying = false;
      });
    } else {
      await _audioPlayer.play(UrlSource(widget.audioUrl));
      setState(() {
        isPlaying = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: appBar(),
        body: Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [
                Colors.deepPurple.shade800.withOpacity(0.8),
                Colors.black87.withOpacity(0.8)
              ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  tileMode: TileMode.mirror)),
          child: Column(
            children: [
              SizedBox(height: 60),
              // Podcast image
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Image.network(
                  widget.imageUrl,
                  fit: BoxFit.contain,
                ),
              ),
              Expanded(
                flex: 4,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      SizedBox(height: 10),
                      Text(
                        widget.description,
                        style: TextStyle(fontSize: 16),
                      ),
                      // SizedBox(height: 10),
                      // Text(
                      //   "Duration: ${widget.duration}",
                      //   style: TextStyle(fontSize: 16, color: Colors.grey),
                      // ),
                    ],
                  ),
                ),
              ),
              // Music controls
              Padding(
                padding: EdgeInsets.only(bottom: 60),
                child: Column(
                  children: [
                    Slider(
                      value: currentPosition.inSeconds.toDouble(),
                      min: 0,
                      max: totalDuration.inSeconds.toDouble(),
                      onChanged: (value) {
                        _audioPlayer.seek(Duration(seconds: value.toInt()));
                      },
                    ),
                    Text(
                      "${currentPosition.inMinutes}:${(currentPosition.inSeconds % 60).toString().padLeft(2, '0')} / ${totalDuration.inMinutes}:${(totalDuration.inSeconds % 60).toString().padLeft(2, '0')}",
                    ),
                    IconButton(
                      iconSize: 64,
                      icon: Icon(
                        isPlaying
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_fill,
                        color: Colors.blue,
                      ),
                      onPressed: playPauseAudio,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ));
  }

  AppBar appBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: true,
      elevation: 0,
      title: Text(
        'Now Playing',
        style: TextStyle(
            fontSize: 24.0, color: Colors.black, fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
    );
  }
}
