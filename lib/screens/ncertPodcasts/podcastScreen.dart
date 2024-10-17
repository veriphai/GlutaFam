import 'package:eureka_app/screens/ncertPodcasts/cerScreen.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class PodcastScreen extends StatefulWidget {
  final String title;
  final String description;
  final String imageUrl;
  final String audioUrl;
  final int duration;
  final String chapterName;
  final int chapterNo;
  final Map<String, dynamic> cerData;
  final String chapterId;

  const PodcastScreen(
      {Key? key,
      required this.title,
      required this.description,
      required this.imageUrl,
      required this.audioUrl,
      required this.duration,
      required this.chapterName,
      required this.chapterNo,
      required this.cerData,
      required this.chapterId})
      : super(key: key);

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
      if (widget.cerData.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                CERPage(data: widget.cerData, chapterId: widget.chapterId),
          ),
        );
      }
    });

    playPauseAudio();
  }

  void stopAudioAndJumpToCER() async {
    await _audioPlayer.pause(); // Stop the audio playback
    setState(() {
      isPlaying = false;
    });
    // Navigate to CER
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CERPage(data: widget.cerData, chapterId: widget.chapterId),
      ),
    );
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
        backgroundColor: Colors.black,
        body: Container(
          // decoration: BoxDecoration(
          //     gradient: LinearGradient(
          //         colors: [
          //       Colors.deepPurple.shade800.withOpacity(0.8),
          //       Colors.black87.withOpacity(0.8)
          //     ],
          //         begin: Alignment.topCenter,
          //         end: Alignment.bottomCenter,
          //         tileMode: TileMode.mirror)),
          child: Column(
            children: [
              SizedBox(height: 40),
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
                        // textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: Colors.white),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.left,
                      ),
                      SizedBox(height: 10),
                      // Text(
                      //   widget.description,
                      //   style: TextStyle(fontSize: 16),
                      // ),
                      // SizedBox(height: 10),
                      Text(
                        "Chapter ${widget.chapterNo} • ${widget.chapterName}",
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.left,
                      ),
                    ],
                  ),
                ),
              ),
              // Music controls
              Padding(
                padding: EdgeInsets.only(bottom: 30),
                child: Column(
                  children: [
                    Slider(
                      value: currentPosition.inSeconds.toDouble(),
                      min: 0,
                      max: totalDuration.inSeconds.toDouble(),
                      onChanged: (value) {
                        _audioPlayer.seek(Duration(seconds: value.toInt()));
                      },
                      activeColor: Color.fromRGBO(255, 217, 0, 1),
                      inactiveColor: Colors.grey[700],
                      thumbColor: Color.fromRGBO(255, 217, 0, 1),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24.0), // Adjust padding if needed
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "${currentPosition.inMinutes}:${(currentPosition.inSeconds % 60).toString().padLeft(2, '0')}",
                            style: TextStyle(color: Colors.white),
                          ),
                          Text(
                            "${totalDuration.inMinutes}:${(totalDuration.inSeconds % 60).toString().padLeft(2, '0')}",
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      iconSize: 80,
                      icon: Icon(
                        isPlaying
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_fill,
                        color: Color.fromRGBO(255, 217, 0, 1),
                      ),
                      onPressed: playPauseAudio,
                    ),
                    // IconButton(
                    //   iconSize: 80,
                    //   icon: Icon(
                    //     isPlaying
                    //         ? Icons.sports_gymnastics
                    //         : Icons.sports_gymnastics,
                    //     color: Colors.white,
                    //   ),
                    //   onPressed: () {
                    //     Navigator.push(
                    //       context,
                    //       MaterialPageRoute(
                    //         builder: (context) => CERPage(),
                    //       ),
                    //     );
                    //   },
                    // )
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
      iconTheme: const IconThemeData(
        color: Colors.white, // Set the back button color to white
      ),
      actions: [
        if (widget.cerData.isNotEmpty)
          Padding(
            padding:
                const EdgeInsets.only(right: 16.0), // Add padding to the right
            child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Color.fromRGBO(255, 217, 0, 1),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              onPressed: stopAudioAndJumpToCER,
              child: const Text(
                'Go to Case',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                ),
              ),
            ),
          ),
      ],
    );
    ;
  }
}
