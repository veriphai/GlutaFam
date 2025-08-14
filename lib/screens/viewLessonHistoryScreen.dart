//final updated code

import 'dart:async';

import 'package:bubble_box/bubble_box.dart';
import 'package:confetti/confetti.dart';
import 'package:eureka_app/apis/fetchLessonHistory.dart';
import 'package:eureka_app/newEvents/aiTutorScreenEvents.dart';
import 'package:eureka_app/utils/tutorAvatars.dart';
import 'package:eureka_app/widgets/tutorMessage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter_markdown_latex/flutter_markdown_latex.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:shimmer/shimmer.dart';
import 'dart:math';

import 'package:stomp_dart_client/stomp_dart_client.dart';
// import 'package:wakelock_plus/wakelock_plus.dart';

class ViewLessonHistory extends StatefulWidget {
  final String conceptId;
  final String conceptName;
  final String conceptConversationsKey;

  const ViewLessonHistory(
      {Key? key,
      required this.conceptId,
      required this.conceptName,
      required this.conceptConversationsKey})
      : super(key: key);
  @override
  _ViewLessonHistoryState createState() => _ViewLessonHistoryState();
}

class _ViewLessonHistoryState extends State<ViewLessonHistory> {
  // late WebSocketServiceForOpenai webSocketService;
  List<Map<String, dynamic>> conversations = [];
  late ScrollController _scrollController;
  bool _isLoading = true;
  late ConfettiController _confettiController;

  late final prefs;

  int _timeLeftSeconds = 0;
  Timer? _timer;

  late Map<String, dynamic> latestTutorResponse;

  late StompClient stompClient;

  Future<void> fetchConceptConversations() async {
    try {
      Map<String, dynamic> conceptDetails = await fetchLessonHistory(
          conceptConversationKey: widget.conceptConversationsKey);

      final raw = conceptDetails['conceptConversations']?['conversations'];
      final convs = (raw is List)
          ? raw
              .map<Map<String, dynamic>>(
                (e) => Map<String, dynamic>.from(e as Map),
              )
              .toList()
          : <Map<String, dynamic>>[];

      setState(() {
        conversations = convs;
        _isLoading = false;
      });
    } catch (error) {
      print("Error fetching lesson history: $error");
    }
  }

  @override
  void initState() {
    super.initState();
    logAITutorScreenView(widget.conceptId);
    fetchConceptConversations();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));

    // WakelockPlus.enable();
    _scrollController = ScrollController();
  }

  Widget othersMessage(final conversation) {
    if (conversation == null || conversation == "") {
      return SizedBox.shrink();
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(
          getTutorAvatar("tutoprime")["imagePath"]!,
          height: 40,
        ),
        Flexible(
            child: BubbleBox(
                maxWidth: double.infinity,
                shape: BubbleShapeBorder(
                    border: BubbleBoxBorder(
                      color: Colors.grey.shade700,
                      width: 3,
                    ),
                    radius: BorderRadius.circular(12),
                    position: const BubblePosition.start(10),
                    direction: BubbleDirection.left,
                    arrowHeight: 10),
                backgroundColor: Color.fromRGBO(19, 31, 36, 1),
                child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: MarkdownBody(
                      selectable: false,
                      data: conversation,
                      builders: {
                        'latex': LatexElementBuilder(
                          textStyle: GoogleFonts.raleway(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      },
                      extensionSet: md.ExtensionSet(
                        [LatexBlockSyntax()],
                        [LatexInlineSyntax()],
                      ),
                      styleSheet: MarkdownStyleSheet(
                        p: GoogleFonts.raleway(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        blockSpacing: 8.0,
                      ),
                    ))))
      ],
    );
  }

  Widget yourMessage(final conversation) {
    if (conversation == null || conversation == "") {
      return SizedBox.shrink();
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Flexible(
            child: BubbleBox(
                maxWidth: double.infinity,
                shape: BubbleShapeBorder(
                    border: BubbleBoxBorder(
                      color: Colors.grey.shade700,
                      width: 3,
                    ),
                    radius: BorderRadius.circular(12),
                    position: const BubblePosition.start(10),
                    direction: BubbleDirection.right,
                    arrowHeight: 10),
                backgroundColor: Color.fromRGBO(19, 36, 22, 1),
                child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: MarkdownBody(
                      selectable: true,
                      data: conversation,
                      builders: {
                        'latex': LatexElementBuilder(
                          textStyle: GoogleFonts.raleway(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      },
                      extensionSet: md.ExtensionSet(
                        [LatexBlockSyntax()],
                        [LatexInlineSyntax()],
                      ),
                      styleSheet: MarkdownStyleSheet(
                        p: GoogleFonts.raleway(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        blockSpacing: 8.0,
                      ),
                    )))),
      ],
    );
  }

  @override
  void dispose() {
    // WakelockPlus.disable();
    _confettiController.dispose();
    _timer?.cancel();

    super.dispose();
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: _isLoading
          ? Scaffold(
              backgroundColor: const Color.fromRGBO(19, 31, 36, 1),
              body: Stack(
                children: [
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.center,
                      child: Shimmer.fromColors(
                        baseColor: Colors.grey[700]!,
                        highlightColor: Colors.grey[300]!,
                        child: const Text(
                          'Loading...',
                          style: TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : Scaffold(
              backgroundColor: const Color.fromRGBO(19, 31, 36, 1),
              appBar: AppBar(
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.conceptName,
                        style: GoogleFonts.raleway(color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
                iconTheme: const IconThemeData(color: Colors.grey),
                backgroundColor: const Color.fromRGBO(19, 31, 36, 1),
                elevation: 0,
                scrolledUnderElevation: 0,
              ),
              body: Stack(
                children: [
                  Column(
                    children: [
                      Align(
                        alignment: Alignment.topCenter,
                        child: ConfettiWidget(
                          confettiController: _confettiController,
                          blastDirection: pi / 2, // downward
                          emissionFrequency: 0.05,
                          numberOfParticles: 20,
                          maxBlastForce: 10,
                          minBlastForce: 5,
                          gravity: 0.3,
                          shouldLoop: false,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final availableWidth = constraints.maxWidth;
                            return Stack(
                              children: [
                                // Background Bar
                                Container(
                                  height: 16.0,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[800],
                                    borderRadius: BorderRadius.circular(16.0),
                                  ),
                                ),
                                // Filled Bar
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                  width: availableWidth *
                                      1, // TODO: replace 1 with progress (0..1)
                                  height: 16.0,
                                  decoration: BoxDecoration(
                                    color: const Color.fromRGBO(255, 217, 0, 1),
                                    borderRadius: BorderRadius.circular(16.0),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: conversations.length,
                                itemBuilder: (context, index) {
                                  final chat = conversations[index];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8.0,
                                      horizontal: 12.0,
                                    ),
                                    child: chat['role'] == "user"
                                        ? yourMessage(chat['text'])
                                        : othersMessage(chat['text']),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
