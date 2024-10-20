import 'package:eureka_app/apis/logEventsApi.dart';
import 'package:eureka_app/screens/ncertPodcasts/cerScreen.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:pdfx/pdfx.dart'; // Import pdfx package
import 'package:http/http.dart' as http;

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
  final String? pdfUrl;

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
      required this.chapterId,
      this.pdfUrl})
      : super(key: key);

  @override
  _PodcastScreenState createState() => _PodcastScreenState();
}

class _PodcastScreenState extends State<PodcastScreen> {
  late AudioPlayer _audioPlayer;
  bool isPlaying = false;
  Duration currentPosition = Duration.zero;
  Duration totalDuration = Duration.zero;
  final String screenName = "AudioLessonPlayerScreen";
  PdfController? _pdfController;
  bool isPdfLoaded = false;

  @override
  void initState() {
    super.initState();

    logPageOpenEvent(
      screenName: screenName,
      eventDetails: {
        "description": "User opened the audio lesson",
        "chapterId": widget.chapterId,
        "section": widget.title
      },
    );
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
        Map<String, dynamic> eventDetails = {
          "chapterId": widget.chapterId,
          "section": widget.title,
          "description": "Moved to CER after audio Completion"
        };
        logEvents(eventDetails, "autoRedirection");
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

    if (widget.pdfUrl != null && widget.pdfUrl!.isNotEmpty) {
      _loadPdfFromNetwork(widget.pdfUrl!);
    }
  }

  Future<void> _loadPdfFromNetwork(String pdfUrl) async {
    try {
      final response = await http.get(Uri.parse(pdfUrl));
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        setState(() {
          _pdfController = PdfController(
            document: PdfDocument.openData(bytes),
          );
          isPdfLoaded = true; // Set PDF as loaded
        });
      } else {
        throw Exception("Failed to load PDF");
      }
    } catch (e) {
      print("Error loading PDF: $e");
      isPdfLoaded = false;
    }
  }

  Future<void> logEvents(eventDetails, eventType) async {
    int currentTimestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await logEvent(
      eventType: eventType,
      screenName: screenName,
      eventDetails: eventDetails,
      eventTime: currentTimestamp,
    );
  }

  void stopAudioAndJumpToCER() async {
    await _audioPlayer.pause(); // Stop the audio playback
    int currentTimestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    Map<String, dynamic> eventDetails = {
      "chapterId": widget.chapterId,
      "section": widget.title,
      "description": "CER button Clicked before Audio Completion"
    };

    await logEvent(
      eventType: "buttonClick",
      screenName: screenName,
      eventDetails: eventDetails,
      eventTime: currentTimestamp,
    );
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

  void _openPdfInModal(BuildContext context) {
    if (widget.pdfUrl != null && widget.pdfUrl!.isNotEmpty && isPdfLoaded) {
      Map<String, dynamic> eventDetails = {
        "chapterId": widget.chapterId,
        "section": widget.title,
        "description": "NCERT Book Opened"
      };
      logEvents(eventDetails, "buttonClick");
      showModalBottomSheet(
        context: context,
        isScrollControlled: true, // Allows the modal to be more than 50%
        backgroundColor: Colors.black, // Adjust the background color
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (BuildContext context) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.8, // 80% of height
            child: Column(
              children: [
                // Close button at the top
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'View Book',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.white),
                        onPressed: () {
                          Navigator.pop(context); // Close the modal
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                    child: Container(
                  color: Colors.black,
                  child: PdfView(
                    controller: _pdfController!,
                    scrollDirection: Axis.vertical, // Enable vertical scrolling
                  ),
                ))
              ],
            ),
          );
        },
      );
    }
  }

  void jumpForward() {
    final remainingDuration = totalDuration - currentPosition;
    if (remainingDuration.inSeconds <= 10) {
      _audioPlayer.seek(totalDuration);
    } else {
      final newPosition = currentPosition + Duration(seconds: 10);
      _audioPlayer.seek(newPosition);
    }
  }

  void jumpBackward() {
    final newPosition = currentPosition - Duration(seconds: 10);
    if (newPosition > Duration.zero) {
      _audioPlayer.seek(newPosition);
    } else {
      _audioPlayer.seek(Duration.zero);
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
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      IconButton(
                        iconSize: 50,
                        icon: Icon(Icons.replay_10,
                            color: Color.fromRGBO(255, 217, 0, 1)),
                        onPressed: jumpBackward,
                      ),
                      SizedBox(
                        width: 20,
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
                      SizedBox(
                        width: 20,
                      ),
                      IconButton(
                        iconSize: 50,
                        icon: Icon(
                          Icons.forward_10,
                          color: Color.fromRGBO(255, 217, 0, 1),
                        ),
                        onPressed: jumpForward,
                      )
                    ]),
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
        if (widget.pdfUrl != null && widget.pdfUrl!.isNotEmpty)
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent, // Transparent background
                elevation: 0, // No shadow
                side: BorderSide.none, // No borders
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              onPressed: () => _openPdfInModal(context),
              child: const Icon(Icons.menu_book, // Open book icon
                  color: Color.fromRGBO(255, 217, 0, 1),
                  size: 30 // Set the icon color
                  ),
            ),
          ),
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
