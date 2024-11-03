import 'package:eureka_app/apis/logEventsApi.dart';
import 'package:eureka_app/screens/ncertPodcasts/cerScreen.dart';
import 'package:eureka_app/screens/ncertPodcasts/endQuestionsScreen.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:pdfx/pdfx.dart'; // Import pdfx package
import 'package:http/http.dart' as http;
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:audio_session/audio_session.dart' as audioSession;
import 'dart:async'; // Import for Timer

import 'dart:io';
import 'dart:convert';

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
  final int sectionNumber;
  final List<dynamic>? subsections;

  const PodcastScreen({
    Key? key,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.audioUrl,
    required this.duration,
    required this.chapterName,
    required this.chapterNo,
    required this.cerData,
    required this.chapterId,
    required this.sectionNumber,
    this.pdfUrl,
    this.subsections,
  }) : super(key: key);

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

  FlutterSoundRecorder? _audioRecorder;
  FlutterSoundPlayer? _audioPlayerV2;
  bool _isRecording = false;
  String? _audioPath;
  bool _isLoading = false;
  String audioFeedbackPath = "";
  String feedbackText = "";
  String activeSubsectionName = '';

  List<Map<String, dynamic>> transformedSubsections = [];

  void _prepareSubsections() {
    transformedSubsections = [];
    bool isFirstSubsection = true;

    widget.subsections?.forEach((subsection) {
      if (isFirstSubsection) {
        // Add the first subsection as it is, without splitting
        transformedSubsections.add({
          'name': subsection['name'],
          'startTime': subsection['startTime'],
          'endTime': subsection['endTime'],
        });
        isFirstSubsection =
            false; // Set to false after processing the first subsection
      } else {
        // Split other subsections into "Concept" and "Concept Q&A"
        transformedSubsections.add({
          'name': "${subsection['name']}",
          'startTime': subsection['startTime'],
          'endTime': subsection['explanationEndTime'],
        });

        transformedSubsections.add({
          'name': "${subsection['name']} Q&A",
          'startTime': subsection['qnaStartTime'],
          'endTime': subsection['qnaEndTime'],
        });
      }
    });
  }

  void _updateActiveSubsectionName() {
    for (var subsection in transformedSubsections) {
      final startTime =
          Duration(seconds: (subsection['startTime'] / 1000).toInt());
      final endTime = Duration(seconds: (subsection['endTime'] / 1000).toInt());

      if (currentPosition >= startTime && currentPosition < endTime) {
        setState(() {
          activeSubsectionName = subsection['name'];
        });
        return;
      }
    }
    // Reset if no subsection is active (e.g., at the beginning or end of audio)
    setState(() {
      activeSubsectionName = '';
    });
  }

  @override
  void initState() {
    super.initState();
    _audioRecorder = FlutterSoundRecorder();
    _audioPlayerV2 = FlutterSoundPlayer();

    logPageOpenEvent(
      screenName: screenName,
      eventDetails: {
        "description": "User opened the audio lesson",
        "chapterId": widget.chapterId,
        "section": widget.title
      },
    );

    _prepareSubsections();
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
        _updateActiveSubsectionName();
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
    _initializeRecorder();
    _initializeAudioSession();

    if (widget.pdfUrl != null && widget.pdfUrl!.isNotEmpty) {
      _loadPdfFromNetwork(widget.pdfUrl!);
    }
  }

  Future<void> _initializeRecorder() async {
    await Permission.microphone.request();
    await _audioRecorder!.openRecorder();
  }

  Future<void> _initializeAudioSession() async {
    final session = await audioSession.AudioSession.instance;
    await session.configure(audioSession.AudioSessionConfiguration(
      avAudioSessionCategory: audioSession.AVAudioSessionCategory.playAndRecord,
      avAudioSessionCategoryOptions:
          audioSession.AVAudioSessionCategoryOptions.allowBluetooth |
              audioSession.AVAudioSessionCategoryOptions.defaultToSpeaker,
      avAudioSessionMode: audioSession.AVAudioSessionMode.spokenAudio,
    ));
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
    _audioRecorder!.closeRecorder();

    super.dispose();
  }

  Future<void> _toggleRecording(StateSetter modalSetState) async {
    if (_isLoading) return;

    if (_isRecording) {
      print('Stopping recorder...');
      await _audioRecorder!.stopRecorder();

      // Update UI immediately to reflect stopped recording
      modalSetState(() {
        _isRecording = false;
        _isLoading = true;
      });

      if (_audioPath != null && _audioPath!.isNotEmpty) {
        print('Audio path: $_audioPath');
        await _sendAudioToBackend(File(_audioPath!));
      }

      // Reset loading state after backend call finishes
      modalSetState(() {
        _isLoading = false;
      });
    } else {
      print('Starting recorder...');
      await _audioPlayer.pause();
      if (_audioPlayerV2!.isPlaying) {
        await _audioPlayerV2!.pausePlayer();
      }

      modalSetState(() {
        isPlaying = false;
        _isRecording = true;
      });

      final tempDir = await getTemporaryDirectory();
      _audioPath = '${tempDir.path}/podcast_audio_record.wav';

      await _audioRecorder!.startRecorder(
        toFile: _audioPath,
        codec: Codec.pcm16WAV,
        bitRate: 16000,
        sampleRate: 44100,
      );
    }
  }

  Future<void> _sendAudioToBackend(File audioFile) async {
    // setState(() {
    //   _isLoading = true; // Show loader when sending audio
    // });
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://glutaclass.com:8080/gluta/fam/ask-any-questions'),
      );

      request.files.add(await http.MultipartFile.fromPath(
        'audio',
        audioFile.path,
        contentType: MediaType('audio', 'wav'),
      ));
      request.fields['chapterId'] = widget.chapterId;
      request.fields['sectionNumber'] = widget.sectionNumber.toString();

      final response = await request.send();
      print("response : ${response}");
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final Map<String, dynamic> responseJson = json.decode(responseData);

        final evaluationMessage = responseJson['evaluationResponse']['message'];
        final audioBase64 = responseJson['evaluationResponse']['audioMessage'];

        setState(() {
          feedbackText = evaluationMessage;
        });

        // Flip the card when showing feedback

        if (audioBase64 != null) {
          _playBase64Audio(audioBase64);
        }
      } else {
        print('Failed to upload audio. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error while sending audio: $e');
    } finally {
      // setState(() {
      //   _isLoading = false; // Hide loader after the backend response
      // });
    }
  }

  Future<void> _playBase64Audio(String base64Audio) async {
    try {
      final audioBytes = base64Decode(base64Audio);
      final tempDir = await getTemporaryDirectory();
      final audioFile = File('${tempDir.path}/response_audio.wav');
      await audioFile.writeAsBytes(audioBytes);
      audioFeedbackPath = audioFile.path;

      await _audioPlayerV2!.openPlayer();
      await _audioPlayerV2!.startPlayer(fromURI: audioFile.path);
    } catch (e) {
      print('Error playing base64 audio: $e');
    }
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

  void _openAskQuestionModel(BuildContext context) {
    Map<String, dynamic> eventDetails = {
      "chapterId": widget.chapterId,
      "section": widget.title,
      "description": "NCERT Book Opened"
    };
    logEvents(eventDetails, "buttonClick");

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter modalSetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.30,
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 10.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Ask a Question',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.white),
                          onPressed: () {
                            modalSetState(() {
                              _isRecording = false;
                            });
                            if (_audioPlayerV2!.isPlaying) {
                              _audioPlayerV2!.pausePlayer();
                            }
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        await _toggleRecording(
                            modalSetState); // Pass modal's setState
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: _isRecording
                              ? LinearGradient(
                                  colors: [Colors.redAccent, Colors.red],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : LinearGradient(
                                  colors: [
                                    Color.fromRGBO(255, 217, 0, 1),
                                    Color.fromRGBO(255, 217, 0, 1),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                          boxShadow: [
                            BoxShadow(
                              color: _isRecording
                                  ? Colors.redAccent
                                  : Color.fromRGBO(255, 217, 0, 1),
                              blurRadius: 20,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: _isLoading
                            ? SizedBox(
                                width: 50,
                                height: 50,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 4.0,
                                  ),
                                ),
                              )
                            : Icon(
                                _isRecording ? Icons.mic : Icons.mic_none,
                                color: Colors.white,
                                size: 50,
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _isLoading
                        ? 'AI Tutor is thinking... Please wait'
                        : (_isRecording
                            ? 'Recording... Tap to submit question'
                            : 'Tap to ask question'),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSubsectionList(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.4,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Subsections',
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
                child: StreamBuilder<Duration>(
                  stream: _audioPlayer.onPositionChanged,
                  builder: (context, snapshot) {
                    final currentPosition = snapshot.data ?? Duration.zero;

                    return ListView.builder(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      itemCount: transformedSubsections.length,
                      itemBuilder: (context, index) {
                        final subsection = transformedSubsections[index];
                        final conceptName = subsection['name'];
                        final startTime = Duration(
                            seconds: (subsection['startTime'] / 1000).toInt());
                        final endTime = Duration(
                            seconds: (subsection['endTime'] / 1000).toInt());

                        final isActive = currentPosition >= startTime &&
                            currentPosition < endTime;

                        return ListTile(
                          title: Text(
                            conceptName,
                            style: TextStyle(
                              color: isActive
                                  ? Color.fromRGBO(
                                      255, 217, 0, 1) // Highlight color
                                  : Colors.white, // Default color
                              fontSize: 16,
                            ),
                          ),
                          trailing: Text(
                            _formatDuration(startTime),
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            _seekToTime(
                                (subsection['startTime'] / 1000).toInt());
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _seekToTime(int seconds) {
    final position = Duration(seconds: seconds);
    _audioPlayer.seek(position);
    setState(() {
      isPlaying = true;
    });
  }

  String _formatDuration(Duration duration) {
    return "${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}";
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
            child: Column(
          children: [
            // Podcast image
            Container(
              width: double.infinity,
              padding:
                  EdgeInsets.only(left: 20, right: 20, top: 15, bottom: 20),
              child: Image.network(
                widget.imageUrl,
                fit: BoxFit.contain,
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.left,
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Chapter ${widget.chapterNo} • ${widget.chapterName}",
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.left,
                    ),
                    if (widget.subsections != null &&
                        widget.subsections!.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(
                            top: 10.0), // Adjust the left padding as needed
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () => _showSubsectionList(context),
                              child: Icon(
                                Icons.list,
                                color: Color.fromRGBO(255, 217, 0, 1),
                                size: 24, // Adjust the size as needed
                              ),
                            ),
                            SizedBox(width: 4),
                            Text(
                              activeSubsectionName.isNotEmpty
                                  ? activeSubsectionName
                                  : '',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Music controls
            Padding(
              padding: EdgeInsets.only(bottom: 0),
              child: Column(
                children: [
                  Container(
                    height: 30, // Set a specific height
                    child: Slider(
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
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        iconSize: 50,
                        icon: Icon(Icons.replay_10,
                            color: Color.fromRGBO(255, 217, 0, 1)),
                        onPressed: jumpBackward,
                      ),
                      SizedBox(width: 20),
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
                      SizedBox(width: 20),
                      IconButton(
                        iconSize: 50,
                        icon: Icon(
                          Icons.forward_10,
                          color: Color.fromRGBO(255, 217, 0, 1),
                        ),
                        onPressed: jumpForward,
                      ),
                    ],
                  ),
                  // Buttons Panel
                  // SizedBox(
                  //   height: 10,
                  // ),
                  Container(
                    margin: EdgeInsets.only(top: 20, bottom: 30),
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Ask Questions Button
                        Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 5.0),
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[850],
                                padding: EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              icon: Icon(
                                Icons.mic,
                                color: Color.fromRGBO(255, 217, 0, 1),
                              ),
                              label: Text(
                                'Ask Questions',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              onPressed: () {
                                _openAskQuestionModel(context);

                                // Add functionality for the microphone button here
                              },
                            ),
                          ),
                        ),
                        // View Book Button
                        Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 5.0),
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[850],
                                padding: EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              icon: Icon(
                                Icons.menu_book,
                                color: Color.fromRGBO(255, 217, 0, 1),
                              ),
                              label: Text(
                                'View Book',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              onPressed: () {
                                // Add functionality to view the book here
                                _openPdfInModal(context);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        )));
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
        Padding(
            padding:
                const EdgeInsets.only(right: 16.0), // Add padding to the right
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[850],
                padding: EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: Icon(
                Icons.question_answer_outlined,
                color: Color.fromRGBO(255, 217, 0, 1),
              ),
              label: Text(
                'Go To Book Q&A',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onPressed: () async {
                await _audioPlayer.pause();
                setState(() {
                  isPlaying = false;
                });

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        EndQuestionScreen(chapterId: widget.chapterId),
                  ),
                );

                // Add functionality for the microphone button here
              },
            )),
      ],
    );
    ;
  }
}
