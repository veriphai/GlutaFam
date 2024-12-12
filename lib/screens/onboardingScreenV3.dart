import 'package:eureka_app/events/onboardingAndLoginEvents.dart';
import 'package:eureka_app/screens/ncertPodcasts/chapterListingScreen.dart';
import 'package:eureka_app/screens/onboardingScreenV2.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingScreenV3 extends StatefulWidget {
  @override
  _OnboardingScreenV3State createState() => _OnboardingScreenV3State();
}

class _OnboardingScreenV3State extends State<OnboardingScreenV3> {
  late VideoPlayerController _videoController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  String currentText = "Hey there, and welcome to GlutaClass!";
  int currentIndex = 0;

  Duration _audioDuration = Duration.zero;
  Duration _currentPosition = Duration.zero;
  bool _isPlaying = false;

  // Static JSON data for dynamic text updates
  final List<Map<String, dynamic>> onboardingFlow = [
    {
      "_id": "onboarding_1",
      "line": "Hey there, and welcome to GlutaClass!",
      "startTime": 0,
      "endTime": 2
    },
    {
      "_id": "onboarding_2",
      "line":
          "Imagine this: You’re reading your NCERT textbook—just like you do every day",
      "startTime": 2,
      "endTime": 7
    },
    {
      "_id": "onboarding_3",
      "line": "—but now you have an audio tutor reading with you,",
      "startTime": 7,
      "endTime": 11
    },
    {
      "_id": "onboarding_4",
      "line": "explaining concepts and asking questions to keep you engaged.",
      "startTime": 11,
      "endTime": 15
    },
    {
      "_id": "onboarding_5",
      "line":
          "But you may ask “Why?” Why should I listen to an audio while reading?",
      "startTime": 15,
      "endTime": 20
    },
    {
      "_id": "onboarding_6",
      "line": "GlutaClass is built on top of scientific research.",
      "startTime": 20,
      "endTime": 24
    },
    {
      "_id": "onboarding_7",
      "line": "Studies show that combining reading with listening",
      "startTime": 24,
      "endTime": 28
    },
    {
      "_id": "onboarding_8",
      "line":
          "improves comprehension by 76% and increases reading accuracy by 52%.",
      "startTime": 28,
      "endTime": 34
    },
    {
      "_id": "onboarding_9",
      "line": "As you read, GlutaClass reads along with you,",
      "startTime": 34,
      "endTime": 38
    },
    {
      "_id": "onboarding_10",
      "line": "pausing to explain complex ideas and highlighting key points.",
      "startTime": 38,
      "endTime": 42
    },
    {
      "_id": "onboarding_11",
      "line": "If you ever struggle to understand because of language,",
      "startTime": 42,
      "endTime": 46
    },
    {
      "_id": "onboarding_12",
      "line": "GlutaClass has you covered—you can switch to explanations",
      "startTime": 46,
      "endTime": 50
    },
    {
      "_id": "onboarding_13",
      "line": "in the language you’re most comfortable with,",
      "startTime": 50,
      "endTime": 53
    },
    {
      "_id": "onboarding_14",
      "line": "because sometimes knowledge gaps are actually language gaps.",
      "startTime": 53,
      "endTime": 57
    },
    {
      "_id": "onboarding_15",
      "line": "Our audio tutor is designed to make you exam-ready.",
      "startTime": 57,
      "endTime": 61
    },
    {
      "_id": "onboarding_16",
      "line":
          "It focuses on important questions and back-of-the-chapter exercises,",
      "startTime": 61,
      "endTime": 66
    },
    {
      "_id": "onboarding_17",
      "line":
          "guiding you to answer out loud and giving you feedback on your answers.",
      "startTime": 66,
      "endTime": 70
    },
    {
      "_id": "onboarding_18",
      "line": "It doesn’t just quiz you; the audio tutor is always on standby",
      "startTime": 70,
      "endTime": 75
    },
    {
      "_id": "onboarding_19",
      "line": "to answer any questions you have during the lesson,",
      "startTime": 75,
      "endTime": 78
    },
    {
      "_id": "onboarding_20",
      "line": "helping you clear doubts as they come up.",
      "startTime": 78,
      "endTime": 81
    },
    {
      "_id": "onboarding_21",
      "line": "The best part? You don’t have to carve out extra time.",
      "startTime": 81,
      "endTime": 84
    },
    {
      "_id": "onboarding_22",
      "line": "You’re already reading NCERT,",
      "startTime": 84,
      "endTime": 86
    },
    {
      "_id": "onboarding_23",
      "line": "and GlutaClass is simply supercharging that very moment.",
      "startTime": 86,
      "endTime": 90
    },
    {
      "_id": "onboarding_24",
      "line": "But here’s something you need to remember:",
      "startTime": 90,
      "endTime": 93
    },
    {
      "_id": "onboarding_25",
      "line": "This entire experience is designed to enhance",
      "startTime": 93,
      "endTime": 96
    },
    {
      "_id": "onboarding_26",
      "line": "your reading of the actual NCERT textbook.",
      "startTime": 96,
      "endTime": 99
    },
    {
      "_id": "onboarding_27",
      "line": "If you don’t have your textbook open right now—",
      "startTime": 99,
      "endTime": 102
    },
    {
      "_id": "onboarding_28",
      "line": "if you’re not in study mode—this app won’t be much help.",
      "startTime": 102,
      "endTime": 106
    },
    {
      "_id": "onboarding_29",
      "line": "GlutaClass thrives when you’re actively reading,",
      "startTime": 106,
      "endTime": 110
    },
    {
      "_id": "onboarding_30",
      "line": "guiding you every step of the way.",
      "startTime": 110,
      "endTime": 112
    },
    {
      "_id": "onboarding_31",
      "line":
          "So Grab your textbook, open the chapter you’re currently studying,",
      "startTime": 112,
      "endTime": 116
    },
    {
      "_id": "onboarding_32",
      "line": "and let’s start learning the Gluta way.",
      "startTime": 116,
      "endTime": 120
    }
  ];

  @override
  void initState() {
    super.initState();
    logAudioOnboardingView();
    _initializeVideo();
    _initializeAudio();
  }

  @override
  void dispose() {
    _videoController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  // Initialize looping video
  void _initializeVideo() {
    _videoController =
        VideoPlayerController.asset('lib/assets/onboardingAudioAnimation.mp4')
          ..initialize().then((_) {
            _videoController.setLooping(true);
            setState(() {});
          });
  }

  // Initialize audio player and start text updates
  void _initializeAudio() async {
    const String audioUrl =
        'https://gluta.s3.ap-south-1.amazonaws.com/Final+Audio+Onboarding.mp3';

    try {
      await _audioPlayer.play(AssetSource('Final Audio Onboarding.mp3'));

      setState(() {
        _isPlaying = true;
      });
      _audioDuration = await _audioPlayer.getDuration() ?? Duration.zero;

      logAudioOnboardingAudioStarted();

      _videoController.play();

      logAudioOnboardingVideoStarted();
      _startTextUpdate();

      _audioPlayer.onPositionChanged.listen((duration) {
        setState(() {
          _currentPosition = duration;
        });
      });

      _audioPlayer.onPlayerComplete.listen((event) {
        logAudioOnboardingAudioCompleted();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => Chapterscreen()),
          (Route<dynamic> route) => false,
        );
      });
    } catch (e) {
      print("Error playing audio: $e");
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes);
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  // Start updating the text based on the audio timing
  void _startTextUpdate() {
    _audioPlayer.onPositionChanged.listen((duration) {
      int currentTime = duration.inSeconds;
      for (int i = 0; i < onboardingFlow.length; i++) {
        int startTime = onboardingFlow[i]['startTime'];
        int endTime = onboardingFlow[i]['endTime'];
        if (currentTime >= startTime && currentTime <= endTime) {
          if (currentIndex != i) {
            setState(() {
              currentText = onboardingFlow[i]['line'];
              currentIndex = i;
            });
          }
          break;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Spacer to push content to the center
                const Spacer(),

                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Video Player
                      SizedBox(
                        height: 20,
                      ),
                      Text(
                        "Welcome To GlutaClass",
                        style: GoogleFonts.raleway(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(
                        height: 40,
                      ),
                      AspectRatio(
                        aspectRatio: _videoController.value.aspectRatio,
                        child: VideoPlayer(_videoController),
                      ),
                      const SizedBox(height: 20),

                      // Countdown Timer
                      Text(
                        _audioDuration == Duration.zero
                            ? "02:00"
                            : _formatDuration(
                                _audioDuration - _currentPosition),
                        style: GoogleFonts.arOneSans(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.white, // Bottom border color
                              width: 1, // Thickness of the bottom border
                            ),
                          ),
                        ),
                        child: IntrinsicHeight(
                          child: TextButton(
                            onPressed: () {
                              _audioPlayer.stop();
                              logAudioOnboardingSkipped(
                                  _currentPosition.inSeconds);
                              if ((_audioDuration - _currentPosition)
                                      .inSeconds <
                                  30) {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => Chapterscreen()),
                                  (Route<dynamic> route) => false,
                                );
                              } else {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          OnboardingScreenV2()),
                                  (Route<dynamic> route) => false,
                                );
                              }
                            },
                            style: TextButton.styleFrom(
                              padding:
                                  EdgeInsets.zero, // Remove default padding
                              minimumSize:
                                  Size(0, 0), // No minimum size constraints
                              tapTargetSize: MaterialTapTargetSize
                                  .shrinkWrap, // Shrink the touch target size
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  "Skip",
                                  style: GoogleFonts.raleway(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(
                                    width: 4), // Space between text and icon
                                Icon(
                                  Icons.fast_forward,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 40,
                      ),
                      // Dynamic Text Display
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: SizedBox(
                          height: 250.0, // Fixed height for the dial container
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Previous Text
                              SizedBox(
                                  height:
                                      40.0, // Fixed height for the previous text
                                  child: Align(
                                      alignment: Alignment.center,
                                      child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 32.0),
                                          child: Text(
                                            currentIndex > 0
                                                ? onboardingFlow[
                                                    currentIndex - 1]['line']
                                                : '',
                                            style: GoogleFonts.raleway(
                                              color:
                                                  Colors.white.withOpacity(0.6),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w400,
                                            ),
                                            textAlign: TextAlign.center,
                                          )))),

                              const SizedBox(height: 18),
                              // Current Text
                              SizedBox(
                                height: 50.0,
                                child: Align(
                                  alignment: Alignment.center,
                                  child: Text(
                                    currentText,
                                    key: ValueKey('current_$currentIndex'),
                                    style: GoogleFonts.raleway(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 18),

                              // Next Text
                              SizedBox(
                                  height:
                                      40.0, // Fixed height for the previous text
                                  child: Align(
                                      alignment: Alignment.center,
                                      child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 32.0),
                                          child: Text(
                                            currentIndex <
                                                    onboardingFlow.length - 1
                                                ? onboardingFlow[
                                                    currentIndex + 1]['line']
                                                : '',
                                            key: ValueKey('next_$currentIndex'),
                                            style: GoogleFonts.raleway(
                                              color:
                                                  Colors.white.withOpacity(0.6),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w400,
                                            ),
                                            textAlign: TextAlign.center,
                                          )))),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
