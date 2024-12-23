import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:eureka_app/apis/askAnyQuestionWeb.dart';
import 'package:eureka_app/apis/logEventsApi.dart';
import 'package:eureka_app/apis/saveCheckpointResultApi.dart';
import 'package:eureka_app/apis/submitFeedbackApi.dart';
import 'package:eureka_app/events/audioPlayerScreenEvents.dart';
import 'package:eureka_app/screens/ncertPodcasts/bestPracticesModal.dart';
import 'package:eureka_app/screens/ncertPodcasts/earlyExitFeedbackModal.dart';
import 'package:eureka_app/screens/ncertPodcasts/endQuestionsScreen.dart';
import 'package:eureka_app/screens/ncertPodcasts/feedbackScreen.dart';
import 'package:eureka_app/services/audioProvider.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:audioplayers/audioplayers.dart';
import 'package:pdfx/pdfx.dart'; // Import pdfx package
import 'package:http/http.dart' as http;
import 'package:flutter_sound/flutter_sound.dart' as flutter_sound;
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http_parser/http_parser.dart';
import 'package:audio_session/audio_session.dart' as audioSession;
import 'dart:async'; // Import for Timer
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:html' as html;


import 'dart:io';
import 'dart:convert';

class PodcastScreen extends StatefulWidget {
  final String? sectionId;

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
  final List<dynamic>? sectionEndQuestions;
  final AudioPlayer? audioPlayer;
  final Duration? totalDurationFromMiniplayer;

  const PodcastScreen(
      {Key? key,
      this.sectionId,
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
      this.sectionEndQuestions,
      this.audioPlayer,
      this.totalDurationFromMiniplayer})
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

  flutter_sound.FlutterSoundRecorder? _audioRecorder;
  flutter_sound.FlutterSoundPlayer? _audioPlayerV2;
  bool _isRecording = false;
  String? _audioPath;
  bool _isLoading = false;
  String audioFeedbackPath = "";
  String feedbackText = "";
  String activeSubsectionName = 'Introduction';
  List<dynamic> currentKeyPoints = [];
  bool _isOverlayOpen = false;
  DateTime? _lastOverlayTime;

  List<Map<String, dynamic>> transformedSubsections = [];
  int currentSubsectionIndex = 0;

  Map<String, List<String?>> userAnswers = {};
  Set<String> visitedCheckpoints = {};
  bool _showBestPractices = true;

  html.MediaRecorder? _mediaRecorder;
  List<html.Blob> _audioChunks = [];
  html.MediaStream? _mediaStream;

  late String currentAudioUrl;
  late List<dynamic>? currentSubsections;
  String currentLanguage = 'En';

  void toggleLanguage() {
    setState(() {
      currentLanguage = currentLanguage == 'En' ? 'Hn' : 'En';
    });
  }

  void _showEarlyExitModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return EarlyExitFeedbackModal(
          onSubmit: (selectedOptions) {
            // Handle feedback submission here
            print("User feedback: $selectedOptions");
            submitFeedback(
              chapterId: widget.chapterId,
              sectionId: widget.sectionId ?? '',
              feedbackOptions: selectedOptions.toList(),
              type: 'earlyExit',
            );
            Navigator.of(context).pop(); // Close the modal
            Navigator.of(context).pop(); // Navigate back
          },
          topicId: widget.sectionId ?? "",
          onclose: () {
            Navigator.of(context).pop(); // Close the modal
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  void _prepareSubsections() {
    transformedSubsections = [];
    bool isFirstSubsection = true;
    int currentOrder = 1;
    int checkpointNumber = 1;

    currentSubsections?.forEach((subsection) {
      if (isFirstSubsection) {
        // Add the first subsection as it is, without splitting
        transformedSubsections.add({
          'id': "${subsection['id']}",
          'name': subsection['name'],
          'startTime': subsection['startTime'],
          'endTime': subsection['endTime'],
          'order': currentOrder,
          'type': 'intro'
        });
        isFirstSubsection = false;
        currentOrder++;
      } else {
        // Split other subsections into "Concept" and "Concept Q&A"
        transformedSubsections.add({
          'id': "${subsection['id']}",
          'name': "${subsection['name']}",
          'startTime': subsection['startTime'],
          'endTime': subsection['explanationEndTime'],
          'keypoints': subsection['keypoints'],
          'order': currentOrder,
          'mcqs': subsection['mcqs'],
          'type': 'concept'
        });
        currentOrder++;
        transformedSubsections.add({
          'id': "${subsection['id']}",
          'name': " Checkpoint ${checkpointNumber}",
          'startTime': subsection['qnaStartTime'] + 1000000000,
          'endTime': subsection['qnaEndTime'] + 1000000000,
          'order': currentOrder,
          'type': 'checkpoint'
        });
        checkpointNumber++;
        currentOrder++;

        transformedSubsections.add({
          'id': "${subsection['id']}",
          'name': "${subsection['name']} Q&A",
          'startTime': subsection['qnaStartTime'],
          'endTime': subsection['qnaEndTime'],
          'order': currentOrder,
          'type': 'qna'
        });
        currentOrder++;
      }
    });
    print(transformedSubsections);
  }

  void _updateActiveSubsectionName() {
    for (var subsection in transformedSubsections) {
      final startTime = Duration(milliseconds: subsection['startTime']);
      final endTime = Duration(milliseconds: subsection['endTime']);

      if (currentPosition >= startTime && currentPosition < endTime) {
        // if (subsection['type'] == 'qna') {
        //   _showKeyPointsOverlay(false);
        // }
        setState(() {
          activeSubsectionName = subsection['name'];
          currentSubsectionIndex =
              (subsection['order'] != null && subsection['order'] > 0)
                  ? subsection['order'] - 1
                  : 0;
          // print("current subsection: ${currentSubsectionIndex}");

          context
              .read<AudioProvider>()
              .updateAudioParams(currentSubsectionIndex);
          checkThatCheckpointShown();
        });
        return;
      }
    }
    // Reset if no subsection is active (e.g., at the beginning or end of audio)
    // setState(() {
    //   activeSubsectionName = '';
    // });
  }

  final List<LinearGradient> optionGradients = [
    LinearGradient(
      colors: [Color.fromRGBO(220, 21, 140, 1), Colors.pink.shade900],
      end: Alignment.topLeft,
      begin: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Colors.green.shade500, Colors.green.shade900],
      end: Alignment.topLeft,
      begin: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Colors.purple.shade500, Colors.purple.shade900],
      end: Alignment.topLeft,
      begin: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color.fromRGBO(71, 125, 148, 1), Colors.blueGrey.shade900],
      end: Alignment.topLeft,
      begin: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Colors.red.shade500, Colors.red.shade900],
      end: Alignment.topLeft,
      begin: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Colors.teal.shade500, Colors.teal.shade900],
      end: Alignment.topLeft,
      begin: Alignment.bottomRight,
    ),
  ];

  void renderCheckpoint(int index) {
    if (index == 0) {
      index++;
    }
    final subsectionId = transformedSubsections[index - 1]['id'];
    final hasExistingAnswers = userAnswers.containsKey(subsectionId) &&
        userAnswers[subsectionId]!.any((answer) => answer != null);

    // Calculate scores
    int correctAnswers = 0;
    int attemptedQuestions = 0;

    if (hasExistingAnswers) {
      final mcqs = transformedSubsections[index - 1]['mcqs'];
      for (int i = 0; i < mcqs.length; i++) {
        if (userAnswers[subsectionId]![i] != null) {
          attemptedQuestions++;
          if (userAnswers[subsectionId]![i] == mcqs[i]['correctAnswer']) {
            correctAnswers++;
          }
        }
      }
    }

    print("index: $index");
    _showKeyPointsOverlay(
      hasExistingAnswers,
      index: index - 1,
      initialCorrectAnswers: correctAnswers,
      initialAttemptedQuestions: attemptedQuestions,
    );
  }

  void _showKeyPointsOverlay(
    bool reviewMode, {
    int index = 0,
    int initialCorrectAnswers = 0,
    int initialAttemptedQuestions = 0,
  }) {
    if (_isOverlayOpen) return;
    _isOverlayOpen = true;
    _audioPlayer.pause();

    int currentQuestionIndex = 0;
    bool showQuestions = false;
    bool showResult = false;
    bool inReviewMode = reviewMode;
    int correctAnswers = initialCorrectAnswers;
    String? selectedOption;

    if (index > 0) {
      currentSubsectionIndex = index;
    }
    final subsection = transformedSubsections[currentSubsectionIndex];
    int attemptedQuestions =
        (subsection['mcqs'] != null && subsection['mcqs'] is List)
            ? subsection['mcqs'].length
            : 0;

    final subsectionId = subsection['id'];
    visitedCheckpoints.add(subsectionId);

    userAnswers[subsectionId] ??= List.filled(
      subsection['mcqs'].length,
      null,
    );

    currentKeyPoints =
        subsection.containsKey('keypoints') && subsection['keypoints'] != null
            ? subsection['keypoints']
            : [];

    logCheckpointAppeared(
        widget.sectionId ?? '',
        _audioPlayer.playing,
        _audioPlayer.position.inSeconds,
        subsectionId,
        transformedSubsections.isNotEmpty
            ? transformedSubsections[currentSubsectionIndex]['id']
            : "");

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      enableDrag: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter modalSetState) {
            return Container(
              padding: EdgeInsets.all(16),
              height: MediaQuery.of(context).size.height * 1, // Adjust height
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Checkpoint',
                        // showQuestions
                        //     ? (showResult ? 'Result' : 'Question')
                        //     : 'Checkpoint',
                        style: GoogleFonts.raleway(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.white),
                        onPressed: () {
                          if (!showQuestions && !showResult && !inReviewMode) {
                            logCheckpointClosedWithoutMcq(
                                widget.sectionId ?? '',
                                _audioPlayer.playing,
                                _audioPlayer.position.inSeconds,
                                subsectionId,
                                transformedSubsections.isNotEmpty
                                    ? transformedSubsections[
                                        currentSubsectionIndex]['id']
                                    : "");
                          }
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  if (!showQuestions && !showResult && !inReviewMode) ...[
                    // Display Key Points
                    Container(
                      height: MediaQuery.of(context).size.height * 0.8,
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Add Key Points heading at the top
                          Text(
                            'Key Points',
                            style: GoogleFonts.raleway(
                              color: Color.fromRGBO(255, 217, 0, 1),
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),

                          SizedBox(height: 20),
                          Expanded(
                            child: ListView.builder(
                              itemCount: currentKeyPoints.length,
                              itemBuilder: (context, index) {
                                final keyPoint = currentKeyPoints[index];

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      keyPoint['title'],
                                      style: GoogleFonts.raleway(
                                        color: Color.fromRGBO(255, 217, 0,
                                            1), // Set to white to show gradient properly
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      keyPoint['content'],
                                      style: GoogleFonts.raleway(
                                          color: Colors.white),
                                    ),
                                    if (index < currentKeyPoints.length - 1)
                                      Divider(
                                          color: Colors.white.withOpacity(0.5)),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else if (showQuestions && !showResult) ...[
                    renderMCQContent(
                      modalSetState,
                      currentQuestionIndex,
                      selectedOption,
                      index > 0 ? index : currentSubsectionIndex,
                      (value) {
                        modalSetState(() {
                          selectedOption = value;
                          userAnswers[subsectionId]![currentQuestionIndex] =
                              value;
                        });
                      },
                    ),
                  ] else if (showResult) ...[
                    // Display Result Summary
                    Container(
                      height: MediaQuery.of(context).size.height * 0.8,
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 150,
                                  height: 150,
                                  child: CircularProgressIndicator(
                                    value: correctAnswers / attemptedQuestions,
                                    strokeWidth: 8.0,
                                    backgroundColor: Colors.grey,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Color.fromRGBO(255, 217, 0, 1),
                                    ),
                                  ),
                                ),
                                Text(
                                  '${((correctAnswers / attemptedQuestions) * 100).toInt()}%',
                                  style: GoogleFonts.raleway(
                                    color: Colors.white,
                                    fontSize: 30,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 40),
                            Text(
                              'You have done $correctAnswers out of $attemptedQuestions correct',
                              style: GoogleFonts.raleway(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            SizedBox(height: 80),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: double
                                      .infinity, // Set width to fill the container
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5.0),
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            Color.fromRGBO(255, 217, 0, 1),
                                        padding:
                                            EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      icon: Icon(
                                        Icons.play_circle_fill,
                                        color: Colors.black,
                                      ),
                                      label: Text(
                                        currentSubsectionIndex >=
                                                transformedSubsections.length -
                                                    3
                                            ? 'End Lesson'
                                            : 'Continue Lesson',
                                        style: GoogleFonts.raleway(
                                          color: Colors.black,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      onPressed: () {
                                        logCheckpointContinueLesson(
                                            widget.sectionId ?? '',
                                            _audioPlayer.playing,
                                            _audioPlayer.position.inSeconds,
                                            subsectionId,
                                            transformedSubsections.isNotEmpty
                                                ? transformedSubsections[
                                                        currentSubsectionIndex]
                                                    ['id']
                                                : "",
                                            inReviewMode
                                                ? "review"
                                                : "attempt");
                                        if (currentSubsectionIndex >=
                                            transformedSubsections.length - 3) {
                                          if (mounted) {
                                            context
                                                .read<AudioProvider>()
                                                .resetAudioPosition();
                                          }
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  FeedbackScreen(
                                                chapterId: widget.chapterId,
                                                sectionEndQuestions:
                                                    widget.sectionEndQuestions,
                                                sectionId: widget.sectionId,
                                              ),
                                            ),
                                          );
                                        } else if (index > 0) {
                                          _seekToTime(
                                              transformedSubsections[index + 3]
                                                  ['startTime']);
                                          Navigator.pop(context);
                                        } else {
                                          _seekToTime(transformedSubsections[
                                                  currentSubsectionIndex + 3]
                                              ['startTime']);
                                          Navigator.pop(context);
                                        }
                                      },
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: double
                                      .infinity, // Set width to fill the container
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5.0, vertical: 10.0),
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.grey[850],
                                        padding:
                                            EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          side: BorderSide(
                                            color: Color.fromRGBO(
                                                255, 217, 0, 1), // Border color
                                            width: 2, // Border width
                                          ),
                                        ),
                                      ),
                                      icon: Icon(
                                        Icons.play_circle_fill,
                                        color: Color.fromRGBO(255, 217, 0, 1),
                                      ),
                                      label: Text(
                                        'Curious QnAs',
                                        style: GoogleFonts.raleway(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      onPressed: () {
                                        logCheckpointCuriousQna(
                                            widget.sectionId ?? '',
                                            _audioPlayer.playing,
                                            _audioPlayer.position.inSeconds,
                                            subsectionId,
                                            transformedSubsections.isNotEmpty
                                                ? transformedSubsections[
                                                        currentSubsectionIndex]
                                                    ['id']
                                                : "",
                                            inReviewMode
                                                ? "review"
                                                : "attempt");
                                        if (index > 0) {
                                          _seekToTime(
                                              transformedSubsections[index + 2]
                                                  ['startTime']);
                                        } else {
                                          _seekToTime(transformedSubsections[
                                                  currentSubsectionIndex + 2]
                                              ['startTime']);
                                        }
                                        Navigator.pop(context);
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )
                  ] else if (inReviewMode) ...[
                    renderMCQContentinReviewMode(
                      modalSetState,
                      currentQuestionIndex,
                      subsectionId,
                      index > 0 ? index : currentSubsectionIndex,
                    ),
                  ],
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (!showQuestions && !showResult && !inReviewMode)
                        Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 5.0),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color.fromRGBO(255, 217, 0, 1),
                                padding: EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () {
                                modalSetState(() {
                                  showQuestions = subsection['mcqs'] != null &&
                                      subsection['mcqs'].isNotEmpty;
                                });
                                logCheckpointMcqSectionOpened(
                                    widget.sectionId ?? '',
                                    _audioPlayer.playing,
                                    _audioPlayer.position.inSeconds,
                                    subsectionId,
                                    transformedSubsections.isNotEmpty
                                        ? transformedSubsections[
                                            currentSubsectionIndex]['id']
                                        : "");
                              },
                              child: Text(
                                "Continue",
                                style: GoogleFonts.raleway(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (showQuestions && !showResult)
                        Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 5.0),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color.fromRGBO(255, 217, 0, 1),
                                padding: EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () {
                                logCheckpointNextMcq(
                                    widget.sectionId ?? '',
                                    _audioPlayer.playing,
                                    _audioPlayer.position.inSeconds,
                                    subsectionId,
                                    transformedSubsections.isNotEmpty
                                        ? transformedSubsections[
                                            currentSubsectionIndex]['id']
                                        : "",
                                    subsection['mcqs'][currentQuestionIndex]
                                        ['id'],
                                    selectedOption ?? '',
                                    inReviewMode ? "review" : "attempt");
                                if (selectedOption != null) {
                                  if (selectedOption ==
                                      subsection['mcqs'][currentQuestionIndex]
                                          ['correctAnswer']) {
                                    correctAnswers++;
                                  }
                                }
                                if (currentQuestionIndex <
                                    subsection['mcqs'].length - 1) {
                                  modalSetState(() {
                                    currentQuestionIndex++;
                                    selectedOption = null;
                                  });
                                } else {
                                  logCheckpointResultsScreen(
                                      widget.sectionId ?? '',
                                      _audioPlayer.playing,
                                      _audioPlayer.position.inSeconds,
                                      subsectionId,
                                      transformedSubsections[
                                          currentSubsectionIndex]['id'],
                                      reviewMode ? "review" : "attempt",
                                      correctAnswers);
                                  modalSetState(() {
                                    showResult = true;
                                    showQuestions = false;
                                  });
                                  final userAnswerForCheckpoint = userAnswers[
                                      transformedSubsections[
                                          currentSubsectionIndex]['id']];
                                  saveCheckpointResultApi(
                                      chapterId: widget.chapterId,
                                      episodeId: widget.sectionId ?? '',
                                      checkpointId: transformedSubsections[
                                          currentSubsectionIndex]['id'],
                                      score: correctAnswers,
                                      userAnswers:
                                          userAnswerForCheckpoint ?? []);
                                }
                              },
                              child: Text(
                                  currentQuestionIndex <
                                          subsection['mcqs'].length - 1
                                      ? "Next"
                                      : "Show Results",
                                  style: GoogleFonts.raleway(
                                    color: Colors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  )),
                            ),
                          ),
                        ),
                      if (showResult)
                        Container(
                          width: MediaQuery.of(context).size.width -
                              32, // Set a fixed width
                          padding: const EdgeInsets.only(bottom: 0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Continue Lesson Button
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5.0),
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey[850],
                                      padding: EdgeInsets.symmetric(
                                        vertical: 12,
                                        // horizontal: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    icon: Icon(
                                      Icons.rate_review_outlined,
                                      color: Color.fromRGBO(255, 217, 0, 1),
                                    ),
                                    label: Text(
                                      'Review Questions',
                                      style: GoogleFonts.raleway(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    onPressed: () {
                                      modalSetState(() {
                                        showResult = false;
                                        inReviewMode = true;
                                        currentQuestionIndex = 0;
                                      });
                                      logCheckpointReviewQuestions(
                                          widget.sectionId ?? '',
                                          _audioPlayer.playing,
                                          _audioPlayer.position.inSeconds,
                                          subsectionId,
                                          transformedSubsections.isNotEmpty
                                              ? transformedSubsections[
                                                  currentSubsectionIndex]['id']
                                              : "",
                                          inReviewMode ? "review" : "attempt");
                                      // Add functionality for the microphone button here
                                    },
                                  ),
                                ),
                              ),
                              // Curious QnAs Button
                            ],
                          ),
                        ),
                      if (inReviewMode && !showResult)
                        Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 5.0),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color.fromRGBO(255, 217, 0, 1),
                                padding: EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () {
                                logCheckpointNextMcq(
                                    widget.sectionId ?? '',
                                    _audioPlayer.playing,
                                    _audioPlayer.position.inSeconds,
                                    subsectionId,
                                    transformedSubsections.isNotEmpty
                                        ? transformedSubsections[
                                            currentSubsectionIndex]['id']
                                        : "",
                                    subsection['mcqs'][currentQuestionIndex]
                                        ['id'],
                                    userAnswers[subsectionId]
                                            ?[currentQuestionIndex] ??
                                        '',
                                    "review");
                                if (currentQuestionIndex <
                                    subsection['mcqs'].length - 1) {
                                  modalSetState(() {
                                    currentQuestionIndex++;
                                    // selectedOption = null;
                                  });
                                } else {
                                  modalSetState(() {
                                    showResult = true;
                                    showQuestions = false;
                                  });
                                }
                              },
                              child: Text(
                                  currentQuestionIndex <
                                          subsection['mcqs'].length - 1
                                      ? "Next"
                                      : "Show Results",
                                  style: GoogleFonts.raleway(
                                    color: Colors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  )),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      _isOverlayOpen = false;
      _lastOverlayTime = DateTime.now();
      isPlaying = true;
      _audioPlayer.play();
    });
  }

// Function to render MCQ content
  Widget renderMCQContent(
    StateSetter modalSetState,
    int currentQuestionIndex,
    String? selectedOption,
    int subsectionIndex,
    ValueChanged<String?> onOptionSelected,
  ) {
    // Define gradient colors for each option
    currentSubsectionIndex = subsectionIndex;
    logCheckpointMcqViewed(
        widget.sectionId ?? '',
        _audioPlayer.playing,
        _audioPlayer.position.inSeconds,
        transformedSubsections.isNotEmpty
            ? transformedSubsections[currentSubsectionIndex]['id']
            : "",
        transformedSubsections.isNotEmpty
            ? transformedSubsections[currentSubsectionIndex]['id']
            : "",
        transformedSubsections.isNotEmpty
            ? transformedSubsections[currentSubsectionIndex]['mcqs']
                [currentQuestionIndex]['id']
            : "",
        "attempt");
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            "Question ${transformedSubsections[currentSubsectionIndex]['mcqs'][currentQuestionIndex]['order']}",
            textAlign: TextAlign.center,
            style: GoogleFonts.raleway(
              color: Color.fromRGBO(255, 217, 0, 1),
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 40),
          Text(
            transformedSubsections[currentSubsectionIndex]['mcqs']
                [currentQuestionIndex]['question'],
            textAlign: TextAlign.center,
            style: GoogleFonts.raleway(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: transformedSubsections[currentSubsectionIndex]['mcqs']
                      [currentQuestionIndex]['options']
                  .length,
              itemBuilder: (context, index) {
                final option = transformedSubsections[currentSubsectionIndex]
                    ['mcqs'][currentQuestionIndex]['options'][index];
                final gradient =
                    optionGradients[index % optionGradients.length];
                final bool isSelected = option['id'] == selectedOption;

                return GestureDetector(
                  onTap: () {
                    logCheckpointMcqOptionSelect(
                        widget.sectionId ?? '',
                        _audioPlayer.playing,
                        _audioPlayer.position.inSeconds,
                        transformedSubsections.isNotEmpty
                            ? transformedSubsections[currentSubsectionIndex]
                                ['id']
                            : "",
                        transformedSubsections.isNotEmpty
                            ? transformedSubsections[currentSubsectionIndex]
                                ['id']
                            : "",
                        transformedSubsections.isNotEmpty
                            ? transformedSubsections[currentSubsectionIndex]
                                ['mcqs'][currentQuestionIndex]['id']
                            : "",
                        option['id']);
                    modalSetState(() {
                      onOptionSelected(option['id']);
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Container(
                      decoration: BoxDecoration(
                          // gradient: gradient,
                          borderRadius: BorderRadius.circular(4),
                          color:
                              isSelected ? Colors.blue[800] : Colors.grey[850]),
                      child: Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              option['content'],
                              style: GoogleFonts.raleway(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          // if (isSelected)
                          //   Align(
                          //     alignment: Alignment.topRight,
                          //     child: Padding(
                          //       padding: const EdgeInsets.all(8.0),
                          //       child: Container(
                          //         width: 20,
                          //         height: 20,
                          //         decoration: BoxDecoration(
                          //           shape: BoxShape.circle,
                          //           color: Colors.white,
                          //         ),
                          //         child: Icon(
                          //           Icons.check,
                          //           color: Colors.green,
                          //           size: 16,
                          //         ),
                          //       ),
                          //     ),
                          //   ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget renderMCQContentinReviewMode(
    StateSetter modalSetState,
    int currentQuestionIndex,
    String subSectionId,
    int subsectionIndex,
  ) {
    // Access the user's selected answer and the correct answer for this question
    final question =
        transformedSubsections[subsectionIndex]['mcqs'][currentQuestionIndex];
    final correctAnswer = question['correctAnswer'];
    final userAnswer = userAnswers[subSectionId]
        ?[currentQuestionIndex]; // Retrieve user's answer from the map

    logCheckpointMcqViewed(
        widget.sectionId ?? '',
        _audioPlayer.playing,
        _audioPlayer.position.inSeconds,
        subSectionId,
        transformedSubsections.isNotEmpty
            ? transformedSubsections[currentSubsectionIndex]['id']
            : "",
        question['id'],
        "review");
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            "Question ${question['order']}",
            textAlign: TextAlign.center,
            style: GoogleFonts.raleway(
              color: Color.fromRGBO(255, 217, 0, 1),
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 40),
          Text(
            question['question'],
            textAlign: TextAlign.center,
            style: GoogleFonts.raleway(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: question['options'].length,
              itemBuilder: (context, index) {
                final option = question['options'][index];
                // final gradient =
                //     optionGradients[index % optionGradients.length];
                final bool isCorrectOption = option['id'] == correctAnswer;
                final bool isUserSelected = option['id'] == userAnswer;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      // gradient: gradient,
                      borderRadius: BorderRadius.circular(4),
                      color: isUserSelected
                          ? (isCorrectOption
                              ? Colors.green.withOpacity(0.7)
                              : Colors.red.withOpacity(0.7))
                          : (isCorrectOption
                              ? Colors.green.withOpacity(0.7)
                              : Colors.grey[850]),
                    ),
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            option['content'],
                            style: GoogleFonts.raleway(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        // if (isUserSelected || isCorrectOption)
                        //   Align(
                        //     alignment: Alignment.topRight,
                        //     child: Padding(
                        //       padding: const EdgeInsets.all(8.0),
                        //       child: Icon(
                        //         isCorrectOption ? Icons.check : Icons.close,
                        //         color: Colors.white,
                        //         size: 20,
                        //       ),
                        //     ),
                        //   ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _checkEndOfSubsection() {
    if (_lastOverlayTime != null &&
        DateTime.now().difference(_lastOverlayTime!) <
            Duration(milliseconds: 1000)) {
      return;
    }

    for (var subsection in transformedSubsections) {
      if (currentPosition.inMilliseconds >= subsection['endTime'] - 300 &&
          currentPosition.inMilliseconds < subsection['endTime'] + 500) {
        logSubsectionsChanged(widget.sectionId ?? "", _audioPlayer.playing,
            _audioPlayer.position.inSeconds, subsection["id"]);
        final listOfSubsection = subsection.containsKey('keypoints') &&
                subsection['keypoints'] != null
            ? subsection['keypoints']
            : [];
        if (listOfSubsection.length > 0) {
          setState(() {
            currentKeyPoints = listOfSubsection;
            isPlaying = false;
          });
          _showKeyPointsOverlay(false);
        }

        break;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _setCurrentScreen();
    currentAudioUrl = widget.audioUrl;
    currentSubsections = widget.subsections;
    _audioRecorder = flutter_sound.FlutterSoundRecorder();
    _audioPlayerV2 = flutter_sound.FlutterSoundPlayer();

    if (widget.pdfUrl != null && widget.pdfUrl!.isNotEmpty) {
      _loadPdfFromNetwork(widget.pdfUrl!);
    }

    logPodcastScreenView(widget.chapterId, widget.sectionId ?? '');

    _prepareSubsections();
    _audioPlayer = context.read<AudioProvider>().audioPlayer ?? AudioPlayer();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Show the modal after the screen builds
      if (_showBestPractices) {
        if (widget.audioUrl !=
            context.read<AudioProvider>().getCurrentAudioUrl()) {
          _showBestPracticesModal();
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AudioProvider>().setAudioPlayer(
          _audioPlayer, currentAudioUrl,
          title: widget.title,
          album: widget.chapterName,
          artUri: widget.imageUrl,
          artist: widget.chapterName,
          episodeName: widget.title,
          chapterName: widget.chapterName,
          duration: widget.duration,
          currentPosition: currentPosition,
          totalDuration: totalDuration,
          chapterNo: widget.chapterNo,
          chapterId: widget.chapterId,
          sectionId: widget.sectionId ?? '',
          pdfUrl: widget.pdfUrl,
          sectionNumber: widget.sectionNumber,
          subsections: currentSubsections,
          sectionEndQuestions: widget.sectionEndQuestions);
    });
    // Set audio player listeners
    // totalDuration = widget.totalDurationFromMiniplayer ?? Duration.zero;
    _audioPlayer.durationStream.listen((Duration? duration) {
      if (mounted && duration != null) {
        setState(() {
          totalDuration = duration;
          print("Total duration: $totalDuration");
        });
      }
    });

    _audioPlayer.positionStream.listen((Duration position) {
      if (mounted) {
        setState(() {
          currentPosition = position;
          _updateActiveSubsectionName();
          if (currentSubsectionIndex < transformedSubsections.length - 1) {
            _checkEndOfSubsection();
          }
        });
      }
    });

    _audioPlayer.playerStateStream.listen((playerState) {
      if (mounted) {
        final isComplete =
            playerState.processingState == ProcessingState.completed;
        setState(() {
          isPlaying = !isComplete;
          if (isComplete) {
            currentPosition = Duration.zero;
            context.read<AudioProvider>().resetAudioPosition();
          }
        });
        if (isComplete) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FeedbackScreen(
                chapterId: widget.chapterId,
                sectionEndQuestions: widget.sectionEndQuestions,
                sectionId: widget.sectionId,
              ),
            ),
          );
        }
      }
    });

    _audioPlayer.playerStateStream.listen((playerState) {
      if (mounted) {
        setState(() {
          isPlaying = playerState
              .playing; // Update isPlaying based on actual playback state
        });
      }
    });
    _initializeRecorder();
    _initializeAudioSession();
  }

  Future<void> _setCurrentScreen() async {
    await FirebaseAnalytics.instance.logScreenView(
        screenClass: 'AudioPlayerScreen',
        screenName: "Audio Player Screen",
        parameters: {"topicId": widget.sectionId ?? ""});
  }

  Future<void> _fetchLanguageSpecificDataAndUpdate() async {
    String languageSuffix = currentLanguage == 'Hn' ? '_hindi' : '';

    String url =
        'https://glutaclass.com:8080/gluta/fam/podcast?episodeId=${widget.sectionId}$languageSuffix';
    try {
      final response = await http.get(Uri.parse(url), headers: {
        'Content-Type': 'application/json',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          currentAudioUrl = data['audioUrl'];
          currentSubsections = data['subSections'];
        });
        _prepareSubsections();

        // Restart the audio player with the new audioUrl
        context.read<AudioProvider>().setAudioPlayer(
              _audioPlayer,
              currentAudioUrl,
              title: widget.title,
              album: widget.chapterName,
              artUri: widget.imageUrl,
              artist: widget.chapterName,
              episodeName: widget.title,
              chapterName: widget.chapterName,
              duration: widget.duration,
              currentPosition: currentPosition,
              totalDuration: totalDuration,
              chapterNo: widget.chapterNo,
              chapterId: widget.chapterId,
              sectionId: widget.sectionId ?? '',
              pdfUrl: widget.pdfUrl,
              sectionNumber: widget.sectionNumber,
              subsections: currentSubsections,
              sectionEndQuestions: widget.sectionEndQuestions,
            );

        // Navigator.pop(context);
      } else {
        throw Exception("Failed to fetch Hinglish data: ${response.body}");
      }
    } catch (e) {
      print("Error in _fetchHinglishDataAndUpdate: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Failed to load Hinglish version. Please try again later.",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showBestPracticesModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: EdgeInsets.all(0),
          child: BestPracticesModal(
            onDismiss: () {
              setState(() {
                _showBestPractices = false;
                _audioPlayer.play();
              });
              Navigator.pop(context);
              if (_audioPlayer.playing) {
                logPodcastStart(widget.sectionId ?? '');
              }
            },
            listenInHindi: () {
              setState(() {
                _showBestPractices = false;
                currentLanguage = "Hn";
              });
              Navigator.pop(context);
              fetchHindiLangData();
            },
            topicId: widget.sectionId ?? '',
          ),
        );
      },
    );
  }

  void fetchHindiLangData() async {
    await _fetchLanguageSpecificDataAndUpdate();
    _audioPlayer.play();
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
    await logEvent(
        eventType: eventType,
        screenName: screenName,
        eventDetails: eventDetails);
  }

  @override
  void dispose() {
    // _audioPlayer.dispose();
    // _audioPlayer.pause();
    _audioRecorder!.closeRecorder();

    super.dispose();
  }

  Future<void> _toggleRecording(StateSetter modalSetState) async {
    if (_isLoading) return;

    if (_isRecording) {
      // print('Stopping recorder...');
      // await _audioRecorder!.stopRecorder();
      _mediaRecorder?.stop();
      print("Stopped MediaRecorder.");

      final Completer<void> dataAvailableCompleter = Completer<void>();

      _mediaRecorder?.addEventListener('dataavailable', (event) {
        final blob = (event as html.BlobEvent).data;
        if (blob != null) {
          _audioChunks.add(blob);
        } else {
          print("No Data In BlobEvent");
        }
        dataAvailableCompleter.complete();
      });
      
      await dataAvailableCompleter.future;

      // Complete audio chunks into a single blob
      final audioBlob = html.Blob(_audioChunks);

      // Use filereader to read blob and get base64-encoded audio
      final reader = html.FileReader();
      final Completer<void> readerCompleter = Completer<void>();
      reader.readAsArrayBuffer(audioBlob);

      reader.onLoadEnd.listen((event) async {
        final audioBytes = reader.result as List<int>;
        final base64Audio = base64Encode(audioBytes);

        //print('audio bytes: $audioBytes');
        // print('base 64 audio: $base64Audio');

        html.window.localStorage['recorded-audio'] = base64Audio;
        //print('Audio stored in localStorage: $base64Audio');
        modalSetState(() {
          _isRecording = false;
          _isLoading = true;
        });
        final audioResponse = await sendAudioToBackendWeb(base64Audio: base64Audio, chapterId: widget.chapterId, sectionNumber: widget.sectionNumber);
        _playBase64Audio(audioResponse);
        modalSetState(() {
          _isLoading = false;
        });
        readerCompleter.complete();
      });
      await readerCompleter.future;
      _audioChunks.clear();

      _mediaStream?.getTracks().forEach((track) => track.stop());
      _mediaStream = null;


      // Update UI immediately to reflect stopped recording
      // modalSetState(() {
      //   _isRecording = false;
      //   _isLoading = true;
      // });

      logAskQuestionMicrophoneOff(
          widget.sectionId ?? '',
          _audioPlayer.playing,
          _audioPlayer.position.inSeconds,
          transformedSubsections.isNotEmpty
              ? transformedSubsections[currentSubsectionIndex]['id']
              : "");

      // if (_audioPath != null && _audioPath!.isNotEmpty) {
      //   print('Audio path: $_audioPath');
      //   await _sendAudioToBackend(File(_audioPath!));
      // }

      // Reset loading state after backend call finishes
      // modalSetState(() {
      //   _isLoading = false;
      // });
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

      print("recording on web");
      _mediaStream = await html.window.navigator.mediaDevices!.getUserMedia({'audio': true});

      _mediaRecorder = html.MediaRecorder(_mediaStream!);
      _mediaRecorder!.addEventListener('dataavailable',(event) {
        final blob = (event as html.BlobEvent).data;
        if (blob != null) {
          //print("data available in blob: ${blob.size}");
          _audioChunks.add(blob);
        } else {
          print('No data in blobEvent');
        }
      });
      _mediaRecorder!.start();
      print("Started MediaRecorder on web");

      // final tempDir = await getTemporaryDirectory();
      // _audioPath = '${tempDir.path}/podcast_audio_record.wav';

      // await _audioRecorder!.startRecorder(
      //   toFile: _audioPath,
      //   codec: flutter_sound.Codec.pcm16WAV,
      //   bitRate: 16000,
      //   sampleRate: 44100,
      // );
      logAskQuestionMicrophoneOn(
          widget.sectionId ?? '',
          _audioPlayer.playing,
          _audioPlayer.position.inSeconds,
          transformedSubsections.isNotEmpty
              ? transformedSubsections[currentSubsectionIndex]['id']
              : "");
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
      request.fields['language'] = currentLanguage;
      if (transformedSubsections.isNotEmpty &&
          currentSubsectionIndex < transformedSubsections.length) {
        request.fields['subsectionId'] =
            transformedSubsections[currentSubsectionIndex]['id'];
      } else {
        // Handle the null or empty case appropriately
        request.fields['subsectionId'] =
            ''; // Or set a default value if required
      }

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
      // final tempDir = await getTemporaryDirectory();
      // final audioFile = File('${tempDir.path}/response_audio.wav');
      // await audioFile.writeAsBytes(audioBytes);
      // audioFeedbackPath = audioFile.path;

      // await _audioPlayerV2!.openPlayer();
      // await _audioPlayerV2!.startPlayer(fromURI: audioFile.path);

      await _audioPlayerV2!.openPlayer();
      await _audioPlayerV2!.startPlayer(
        fromDataBuffer: audioBytes
      );
      if (_audioPlayerV2!.isPlaying) {
        logAskQuestionResponsePlayed(
            widget.sectionId ?? '',
            _audioPlayer.playing,
            _audioPlayer.position.inSeconds,
            transformedSubsections.isNotEmpty
                ? transformedSubsections[currentSubsectionIndex]['id']
                : "");
      }
    } catch (e) {
      print('Error playing base64 audio: $e');
    }
  }

  void playPauseAudio() async {
    if (isPlaying) {
      logPauseButtonClick(
          widget.sectionId ?? '',
          _audioPlayer.playing,
          _audioPlayer.position.inSeconds,
          transformedSubsections.isNotEmpty
              ? transformedSubsections[currentSubsectionIndex]['id']
              : "");
      await _audioPlayer.pause();
      setState(() {
        isPlaying = false;
      });
    } else {
      // await _audioPlayer.setUrl(widget.audioUrl); // Set the audio source URL
      logPlayButtonClick(
          widget.sectionId ?? '',
          _audioPlayer.playing,
          _audioPlayer.position.inSeconds,
          transformedSubsections.isNotEmpty
              ? transformedSubsections[currentSubsectionIndex]['id']
              : "");
      await _audioPlayer.play(); // Start playback
      if (mounted) {
        setState(() {
          isPlaying = true;
        });
      }
    }
  }

  void _openPdfInModal(BuildContext context) {
    // Open the modal immediately
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
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
                      style: GoogleFonts.raleway(
                          color: Colors.white, fontSize: 16),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        logViewBookClosed(
                            widget.sectionId ?? '',
                            _audioPlayer.playing,
                            _audioPlayer.position.inSeconds,
                            transformedSubsections.isNotEmpty
                                ? transformedSubsections[currentSubsectionIndex]
                                    ['id']
                                : "");
                        Navigator.pop(context); // Close the modal
                      },
                    ),
                  ],
                ),
              ),
              // PDF Viewer or Loader
              Expanded(
                child: Container(
                  color: Colors.black,
                  child: FutureBuilder(
                    future:
                        _loadPdf(), // This would be the async function to load the PDF
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        // Show loader while waiting for PDF to load
                        return Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color.fromRGBO(255, 217, 0, 1)),
                          ),
                        );
                      } else if (snapshot.hasError) {
                        // Handle any loading errors
                        logViewBookPdfLoaded(
                            widget.sectionId ?? '',
                            _audioPlayer.playing,
                            _audioPlayer.position.inSeconds,
                            transformedSubsections.isNotEmpty
                                ? transformedSubsections[currentSubsectionIndex]
                                    ['id']
                                : "",
                            false);
                        return Center(
                          child: Text(
                            'Failed to load PDF',
                            style: GoogleFonts.raleway(color: Colors.red),
                          ),
                        );
                      } else {
                        // Display PDF when loaded
                        logViewBookPdfLoaded(
                            widget.sectionId ?? '',
                            _audioPlayer.playing,
                            _audioPlayer.position.inSeconds,
                            transformedSubsections.isNotEmpty
                                ? transformedSubsections[currentSubsectionIndex]
                                    ['id']
                                : "",
                            true);
                        return PdfView(
                          controller: _pdfController!,
                          scrollDirection: Axis.vertical,
                        );
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _loadPdf() async {
    const int maxRetries = 10;
    const Duration delay = Duration(seconds: 2);

    int retries = 0;

    while (!isPdfLoaded && retries < maxRetries) {
      await Future.delayed(delay);
      retries++;
      if (isPdfLoaded) {
        break;
      }
    }

    if (!isPdfLoaded) {
      print("PDF loading timed out.");
    }
  }

  void _openAskQuestionModel(BuildContext context) {
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
                          style: GoogleFonts.raleway(
                              color: Colors.white, fontSize: 16),
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
                            logAskQuestionClosed(
                                widget.sectionId ?? '',
                                _audioPlayer.playing,
                                _audioPlayer.position.inSeconds,
                                transformedSubsections.isNotEmpty
                                    ? transformedSubsections[
                                        currentSubsectionIndex]['id']
                                    : "");
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
                    style: GoogleFonts.raleway(
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
    logSubsectionsBottomSheetOpened(
        widget.sectionId ?? '',
        _audioPlayer.playing,
        _audioPlayer.position.inSeconds,
        transformedSubsections.isNotEmpty
            ? transformedSubsections[currentSubsectionIndex]['id']
            : "");
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
                      style: GoogleFonts.raleway(
                          color: Colors.white, fontSize: 16),
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
                  stream: _audioPlayer.positionStream,
                  builder: (context, snapshot) {
                    final currentPosition = snapshot.data ?? Duration.zero;

                    return ListView.builder(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      itemCount: transformedSubsections.length,
                      itemBuilder: (context, index) {
                        final subsection = transformedSubsections[index];
                        final conceptName = subsection['name'];
                        final startTime =
                            Duration(milliseconds: subsection['startTime']);
                        final endTime =
                            Duration(milliseconds: subsection['endTime']);

                        final isActive = currentPosition >= startTime &&
                            currentPosition < endTime;

                        return ListTile(
                          title: Text(
                            conceptName,
                            style: GoogleFonts.raleway(
                              color: isActive
                                  ? Color.fromRGBO(
                                      255, 217, 0, 1) // Highlight color
                                  : Colors.white, // Default color
                              fontSize: 16,
                            ),
                          ),
                          // trailing: Text(
                          //   _formatDuration(startTime),
                          //   style: GoogleFonts.raleway(color: Colors.grey, fontSize: 14),
                          // ),
                          onTap: () {
                            Navigator.pop(context);
                            logSubsectionSelected(
                                widget.sectionId ?? '',
                                _audioPlayer.playing,
                                _audioPlayer.position.inSeconds,
                                transformedSubsections.isNotEmpty
                                    ? transformedSubsections[
                                        currentSubsectionIndex]['id']
                                    : "",
                                subsection['id']);
                            if (subsection['type'] == 'checkpoint') {
                              renderCheckpoint(index);
                            } else {
                              _seekToTime(subsection['startTime']);
                            }
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

  void _seekToTime(int milliseconds) {
    // milliseconds = milliseconds + 1000;
    final position = Duration(milliseconds: milliseconds);
    _audioPlayer.seek(position);
    setState(() {
      isPlaying = true;
    });
  }

  String _formatDuration(Duration duration) {
    return "${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}";
  }

  String _formatEndTimeDuration(int duration) {
    final endDuration = Duration(seconds: (duration ~/ 1000).toInt());
    return "${endDuration.inMinutes}:${(endDuration.inSeconds % 60).toString().padLeft(2, '0')}";
  }

  void checkThatCheckpointShown() async {
    final subsection = transformedSubsections[currentSubsectionIndex];
    if (subsection['type'] == 'qna' &&
        !visitedCheckpoints.contains(subsection['id']) &&
        currentPosition.inMilliseconds < subsection['startTime'] + 7000) {
      await _audioPlayer.seek(Duration(
          milliseconds: transformedSubsections[currentSubsectionIndex - 2]
                  ['endTime'] -
              300));
      // setState(() {
      //   currentSubsectionIndex = currentSubsectionIndex - 2;
      // });
    }
  }

  void jumpForward() {
    logForwardBackwardClick(
        widget.sectionId ?? '',
        _audioPlayer.playing,
        _audioPlayer.position.inSeconds,
        transformedSubsections.isNotEmpty
            ? transformedSubsections[currentSubsectionIndex]['id']
            : "",
        'forward');
    final remainingDuration = totalDuration - currentPosition;
    if (remainingDuration.inSeconds <= 10) {
      _audioPlayer.seek(totalDuration);
    } else {
      final newPosition = currentPosition + Duration(seconds: 10);
      _audioPlayer.seek(newPosition);
      // checkThatCheckpointShown();
    }
  }

  void jumpBackward() {
    logForwardBackwardClick(
        widget.sectionId ?? '',
        _audioPlayer.playing,
        _audioPlayer.position.inSeconds,
        transformedSubsections.isNotEmpty
            ? transformedSubsections[currentSubsectionIndex]['id']
            : "",
        'backward');
    final newPosition = currentPosition - Duration(seconds: 10);
    if (newPosition > Duration.zero) {
      _audioPlayer.seek(newPosition);
      // checkThatCheckpointShown();
    } else {
      _audioPlayer.seek(Duration.zero);
    }
  }

  void skipContent() async {
    int counterToAdd = 1;

    if (currentSubsectionIndex == transformedSubsections.length - 1) {
      await _audioPlayer.pause();
      setState(() {
        isPlaying = false;
      });

      logSkipClick(
          widget.sectionId ?? '',
          _audioPlayer.playing,
          _audioPlayer.position.inSeconds,
          transformedSubsections.isNotEmpty
              ? transformedSubsections[currentSubsectionIndex]['id']
              : "",
          "End Lesson");
      if (mounted) {
        context.read<AudioProvider>().resetAudioPosition();
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FeedbackScreen(
            chapterId: widget.chapterId,
            sectionEndQuestions: widget.sectionEndQuestions,
            sectionId: widget.sectionId,
          ),
        ),
      );
    } else {
      logSkipClick(
          widget.sectionId ?? '',
          _audioPlayer.playing,
          _audioPlayer.position.inSeconds,
          transformedSubsections.isNotEmpty
              ? transformedSubsections[currentSubsectionIndex]['id']
              : "",
          transformedSubsections.isNotEmpty
              ? transformedSubsections[currentSubsectionIndex]['type']
              : "");
      final nextSubsection = transformedSubsections[currentSubsectionIndex + 1];

      if (nextSubsection['type'] == 'checkpoint') {
        // counterToAdd = 2;
        renderCheckpoint(currentSubsectionIndex + 1);
      } else {
        _seekToTime(
            transformedSubsections[currentSubsectionIndex + counterToAdd]
                ['startTime']);
      }
    }
  }

  void _exitAndShowMiniPlayer() {
    // Navigator.pop(context);
    Navigator.pop(context, {
      'audioUrl': currentAudioUrl,
      'episodeName': widget.title,
      'imageUrl': widget.imageUrl,
      'chapterName': widget.chapterName,
      "duration": widget.duration,
      'audioPlayer': _audioPlayer,
      'currentPosition': currentPosition,
      'totalDuration': totalDuration,
      'isPlaying': isPlaying
    });
  }

  bool _canPop() {
    if (currentSubsectionIndex >= 2) {
      return true; // Allow pop if the user is past the early subsections
    }

    int randomNumber =
        Random().nextInt(10) + 1; // Generate a number between 1 and 10
    bool shouldShowModal = randomNumber % 3 == 0 && !_audioPlayer.playing;
    return !shouldShowModal;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: _canPop(), // Determine if the screen can pop
        onPopInvoked: (didPop) {
          if (!didPop) {
            _showEarlyExitModal();
          }
        },
        child: Scaffold(
            appBar: appBar(),
            backgroundColor: Colors.black,
            body: Container(
                child: Column(
              children: [
                // Podcast image
                Container(
                  width: 450,
                  padding:
                      EdgeInsets.only(left: 20, right: 20, top: 15, bottom: 20),
                  child: CachedNetworkImage(
                    imageUrl: widget.imageUrl,
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
                        Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              widget.title,
                              style: GoogleFonts.raleway(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.left,
                            )),
                        SizedBox(height: 5),
                        Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "Chapter ${widget.chapterNo} • ${widget.chapterName}",
                              style: GoogleFonts.arOneSans(
                                  fontSize: 14, color: Colors.grey),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.left,
                            )),
                        if (currentSubsections != null &&
                            currentSubsections!.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(
                                top: 5.0), // Adjust the left padding as needed
                            child: Row(
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
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => _showSubsectionList(context),
                                    child: Text(
                                      activeSubsectionName.isNotEmpty
                                          ? activeSubsectionName
                                          : '',
                                      style: GoogleFonts.raleway(
                                        color: Color.fromRGBO(255, 217, 0, 1),
                                        fontSize: 16,
                                        decoration: TextDecoration.underline,
                                        decorationColor: Color.fromRGBO(255,
                                            217, 0, 1), // Set underline color
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow
                                          .ellipsis, // Prevent overflow
                                    ),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0),
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.grey[850],
                                        padding: EdgeInsets.symmetric(
                                          vertical: 4,
                                          horizontal: 10,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      onPressed: skipContent,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            currentSubsectionIndex ==
                                                    transformedSubsections
                                                            .length -
                                                        1
                                                ? 'End Lesson'
                                                : transformedSubsections[
                                                                currentSubsectionIndex]
                                                            ['type'] ==
                                                        'qna'
                                                    ? 'Skip QnA'
                                                    : transformedSubsections[
                                                                    currentSubsectionIndex]
                                                                ['type'] ==
                                                            'intro'
                                                        ? 'Skip Intro'
                                                        : 'Skip Concept',
                                            style: GoogleFonts.raleway(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Icon(
                                            Icons.fast_forward_rounded,
                                            color:
                                                Color.fromRGBO(255, 217, 0, 1),
                                            size: 20,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
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
                          height: 20,
                          child: Slider(
                            value: currentPosition.inMilliseconds
                                .toDouble()
                                .clamp(0.0,
                                    totalDuration.inMilliseconds.toDouble()),
                            min: 0,
                            max: totalDuration.inMilliseconds.toDouble(),
                            onChanged: (value) {
                              _audioPlayer
                                  .seek(Duration(milliseconds: value.toInt()));
                              logSeekerClick(
                                  widget.sectionId ?? '',
                                  _audioPlayer.playing,
                                  _audioPlayer.position.inSeconds,
                                  transformedSubsections.isNotEmpty
                                      ? transformedSubsections[
                                          currentSubsectionIndex]['id']
                                      : "");
                            },
                            activeColor: Color.fromRGBO(255, 217, 0, 1),
                            inactiveColor: Colors.grey[700],
                            thumbColor: Color.fromRGBO(255, 217, 0, 1),
                          )),
                      // Padding(
                      //   padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      //   child: Row(
                      //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      //     children: [
                      //       Text(
                      //         "${currentPosition.inMinutes}:${(currentPosition.inSeconds % 60).toString().padLeft(2, '0')}",
                      //         style: GoogleFonts.raleway(color: Colors.white),
                      //       ),
                      //       Text(
                      //         _formatEndTimeDuration(widget.duration),
                      //         style: GoogleFonts.raleway(color: Colors.white),
                      //       ),
                      //     ],
                      //   ),
                      // ),
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
                                    style: GoogleFonts.raleway(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  onPressed: () {
                                    logAskQuestionButtonClick(
                                        widget.sectionId ?? '',
                                        _audioPlayer.playing,
                                        _audioPlayer.position.inSeconds,
                                        transformedSubsections.isNotEmpty
                                            ? transformedSubsections[
                                                currentSubsectionIndex]['id']
                                            : "");
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
                                    style: GoogleFonts.raleway(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  onPressed: () {
                                    // Add functionality to view the book here
                                    logViewBookButtonClick(
                                        widget.sectionId ?? '',
                                        _audioPlayer.playing,
                                        _audioPlayer.position.inSeconds,
                                        transformedSubsections.isNotEmpty
                                            ? transformedSubsections[
                                                currentSubsectionIndex]['id']
                                            : "");
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
            ))));
  }

  void _showBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter modalSetState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.language,
                      color: currentLanguage == 'En'
                          ? Color.fromRGBO(255, 217, 0, 1)
                          : Colors.white,
                    ),
                    title: Text(
                      "Listen in English",
                      style: GoogleFonts.raleway(
                        color: currentLanguage == 'En'
                            ? Color.fromRGBO(255, 217, 0, 1)
                            : Colors.white,
                      ),
                    ),
                    onTap: () async {
                      if (currentLanguage == 'En') {
                        Navigator.pop(context); // Just close the sheet
                      } else {
                        modalSetState(() {
                          currentLanguage = 'En';
                        });
                        logLanguageSelected(
                            widget.sectionId ?? '',
                            _audioPlayer.playing,
                            _audioPlayer.position.inSeconds,
                            currentLanguage);
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return Center(
                              child: CircularProgressIndicator(
                                color: Color.fromRGBO(255, 217, 0, 1),
                              ),
                            );
                          },
                        );

                        try {
                          await _fetchLanguageSpecificDataAndUpdate();
                          Navigator.pop(context);
                        } finally {
                          Navigator.pop(context); // Close the loading dialog
                          await _audioPlayer.play(); // Start playback
                          setState(() {
                            isPlaying = true;
                          });
                        }
                      }
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.language,
                      color: currentLanguage == 'Hn'
                          ? Color.fromRGBO(255, 217, 0, 1)
                          : Colors.white,
                    ),
                    title: Text(
                      "Listen in Hindi",
                      style: GoogleFonts.raleway(
                        color: currentLanguage == 'Hn'
                            ? Color.fromRGBO(255, 217, 0, 1)
                            : Colors.white,
                      ),
                    ),
                    onTap: () async {
                      if (currentLanguage == 'Hn') {
                        Navigator.pop(context);
                      } else {
                        modalSetState(() {
                          currentLanguage = 'Hn';
                        });
                        logLanguageSelected(
                            widget.sectionId ?? '',
                            _audioPlayer.playing,
                            _audioPlayer.position.inSeconds,
                            currentLanguage);
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return Center(
                              child: CircularProgressIndicator(
                                color: Color.fromRGBO(255, 217, 0, 1),
                              ),
                            );
                          },
                        );

                        try {
                          await _fetchLanguageSpecificDataAndUpdate();
                          Navigator.pop(context);
                        } finally {
                          Navigator.pop(context); // Close the loading dialog
                          await _audioPlayer.play(); // Start playback
                          setState(() {
                            isPlaying = true;
                          });
                        }
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  AppBar appBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: true,
      elevation: 0,
      iconTheme: const IconThemeData(
        color: Colors.white, // Set the back button color to white
      ),
      // leading: IconButton(
      //   icon: Icon(Icons.arrow_back),
      //   onPressed: _exitAndShowMiniPlayer,
      // ),
      actions: [
        Padding(
            padding:
                const EdgeInsets.only(right: 16.0), // Add padding to the right
            child: Row(children: [
              ElevatedButton.icon(
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
                  style: GoogleFonts.raleway(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onPressed: () async {
                  logGoToBookQnaButtonClick(widget.sectionId ?? '',
                      _audioPlayer.playing, _audioPlayer.position.inSeconds);
                  await _audioPlayer.pause();
                  setState(() {
                    isPlaying = false;
                  });

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EndQuestionScreen(
                        chapterId: widget.chapterId,
                        sectionEndQuestions: widget.sectionEndQuestions,
                        sourceScreen: "AudioPlayerScreen",
                      ),
                    ),
                  );

                  // Add functionality for the microphone button here
                },
              ),
              SizedBox(
                width: 10,
              ),
              ElevatedButton.icon(
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
                onPressed: () {
                  logLanguageChangeButtonClick(widget.sectionId ?? '',
                      _audioPlayer.playing, _audioPlayer.position.inSeconds);
                  _showBottomSheet(context);
                },
                icon: Icon(
                  Icons.language,
                  color: Color.fromRGBO(255, 217, 0, 1),
                ),
                label: Text(
                  currentLanguage == 'En'
                      ? 'En'
                      : 'Hn', // Update based on selected language
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            ])),
      ],
    );
  }
}
