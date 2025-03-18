import 'dart:async';
import 'package:bubble_box/bubble_box.dart';
import 'package:chat_bubbles/chat_bubbles.dart';
import 'package:chiclet/chiclet.dart';
import 'package:eureka_app/apis/questionMistakesCorrection.dart';
import 'package:eureka_app/widgets/conceptResultScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown_latex/flutter_markdown_latex.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

class MistakesCorrectionScreen extends StatefulWidget {
  final String conceptId;
  final String conceptName;
  final int totalXp;
  final String timeTaken;
  final double accuracy;
  final List<Map<String, dynamic>> incorrectQuestions;
  const MistakesCorrectionScreen({
    Key? key,
    required this.conceptId,
    required this.conceptName,
    required this.totalXp,
    required this.timeTaken,
    required this.accuracy,
    required this.incorrectQuestions,
  }) : super(key: key);
  @override
  _MistakesCorrectionScreenState createState() =>
      _MistakesCorrectionScreenState();
}

class _MistakesCorrectionScreenState extends State<MistakesCorrectionScreen> {
  late int currentQuestionIndex;
  late List<Map<String, String>> chatMessages;
  List<Map<String, String>> allConversations = [];
  final ScrollController _scrollController = ScrollController();
  int conversationNo = 1;
  bool conversationCompleted = false;
  bool conversationStarted = false;
  int mistakesCorrected = 0;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    currentQuestionIndex = 0;
    chatMessages = [];

    // _fetchAIResponse();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void startCorrectingMistake() {
    setState(() {
      conversationStarted = true;
    });
    _fetchAIResponse();
  }

  Future<void> _fetchAIResponse() async {
    setState(() => isLoading = true);

    // Mock API call (replace with your backend API integration)
    final Map<String, dynamic> aiResponses =
        await fetchQuestionMistakesConversation(
            conversations: [],
            conceptName: "Photosynthesis",
            query: "",
            incorrectQuestion: widget.incorrectQuestions[currentQuestionIndex],
            conversationNo: conversationNo);
    chatMessages = [
      {"role": "ai", "conversation": aiResponses["response"]}
    ];
    allConversations = (aiResponses["conversations"] as List).map((item) {
      return Map<String, String>.from(
          item); // Ensure each item is a Map<String, String>
    }).toList();

    print(allConversations);
    conversationNo++;
    setState(() => isLoading = false);
    scrollToBottom();
  }

  void _nextQuestion() {
    if (currentQuestionIndex < widget.incorrectQuestions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        chatMessages = [];
        allConversations = [];
        conversationStarted = false;
        conversationCompleted = false;
        conversationNo = 1;
      });
    } else {
      // Handle when all questions are completed
      Navigator.pop(context, mistakesCorrected);
      // Navigator.push(
      //   context,
      //   MaterialPageRoute(
      //     builder: (context) => ConceptResultScreen(
      //       conceptName: widget.conceptName,
      //       totalXp: widget.totalXp,
      //       timeTaken: widget.timeTaken,
      //       accuracy: widget.accuracy,
      //       lessonCompletionResponse: widget.lessonCompletionResponse,
      //     ),
      //   ),
      // );
    }
  }

  Widget othersMessage(final conversation) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
                    direction: BubbleDirection.left,
                    arrowHeight: 10),
                backgroundColor: Color.fromRGBO(19, 31, 36, 1),
                child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: MarkdownBody(
                      selectable: true,
                      data: conversation["conversation"]!,
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

  Widget yourMessage(final conversation) {
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
                      data: conversation["conversation"]!,
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

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget renderMessageBar() {
    return Container(
      color: Color.fromRGBO(19, 31, 36, 1),
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: MessageBar(
              messageBarColor: Color.fromRGBO(19, 31, 36, 1),
              onSend: (message) async {
                // Add user's message to the chat
                setState(() {
                  chatMessages.add({
                    "_id": DateTime.now().toString(),
                    "role": "user",
                    "conversation": message,
                  });
                  // scrollToBottom();
                });
                scrollToBottom();

                // Scroll to the bottom after sending a new message

                final Map<String, dynamic> aiResponses =
                    await fetchQuestionMistakesConversation(
                        conversations: allConversations,
                        conceptName: "Photosynthesis",
                        query: message,
                        incorrectQuestion:
                            widget.incorrectQuestions[currentQuestionIndex],
                        conversationNo: conversationNo);

                setState(() {
                  chatMessages.add(
                      {"role": "ai", "conversation": aiResponses["response"]});

                  if (aiResponses["conversationCompleted"] == "Yes") {
                    conversationCompleted = true;
                  }
                });
                scrollToBottom();

                allConversations =
                    (aiResponses["conversations"] as List).map((item) {
                  return Map<String, String>.from(
                      item); // Ensure each item is a Map<String, String>
                }).toList();
                conversationNo++;
              },
            ),
          ),
          // Close Button
        ],
      ),
    );
  }

  double getProgress() {
    return (currentQuestionIndex + 1) / widget.incorrectQuestions.length;
  }

  Color getProgressBarColor(double progress) {
    if (progress <= 0.25) {
      return Colors.red; // Below 25% progress
    } else if (progress <= 0.50) {
      return Colors.orange; // Between 25% and 50%
    } else if (progress <= 0.75) {
      return Colors.yellow; // Between 50% and 75%
    } else {
      return Colors.green; // Above 75%
    }
  }

  double _calculateButtonHeight(String text, double maxWidth) {
    TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: GoogleFonts.raleway(
          fontSize: 14,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 2,
    )..layout(maxWidth: maxWidth - 20); // Adjust padding for width

    int lineCount = textPainter.computeLineMetrics().length;
    return lineCount > 1 ? 60 : 40;
  }

  Widget buildQuestionCard() {
    Map<String, dynamic> currentQuestion =
        widget.incorrectQuestions[currentQuestionIndex];
    return Container(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: MarkdownBody(
                  selectable: true,
                  data: currentQuestion["question"],
                  builders: {
                    'latex': LatexElementBuilder(
                      textStyle: GoogleFonts.raleway(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700),
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
                        fontWeight: FontWeight.w700),
                    blockSpacing: 8.0,
                  ),
                )),

            // Options with User and Correct Answer Indication
            ...currentQuestion["options"].map<Widget>((option) {
              final bool isMCMA = currentQuestion["type"] ==
                  "Multiple Choice - Multiple Answers";

              final bool isSelected = isMCMA
                  ? (currentQuestion["userAnswer"] as String)
                      .split(', ')
                      .contains(option["id"])
                  : currentQuestion["userAnswer"] == option["id"];

              final bool isActualCorrect = isMCMA
                  ? (currentQuestion["correctAnswer"] as String)
                      .split(', ')
                      .contains(option["id"])
                  : currentQuestion["correctAnswer"] == option["id"];
              return LayoutBuilder(builder: (context, constraints) {
                double buttonHeight = _calculateButtonHeight(
                    option['option'], constraints.maxWidth);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: AbsorbPointer(
                    absorbing: true, // Prevent taps but keep appearance
                    child: ChicletOutlinedAnimatedButton(
                        onPressed:
                            () {}, // This won't show ripple or press effect
                        buttonType: ChicletButtonTypes.roundedRectangle,
                        height: buttonHeight,
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        borderWidth: 1.0,
                        borderColor: isActualCorrect
                            ? Colors.green
                            : (isSelected ? Colors.red : Colors.grey),
                        backgroundColor: Color.fromRGBO(19, 31, 36, 1),
                        child: Align(
                            alignment: Alignment.centerLeft,
                            child: MarkdownBody(
                              selectable: false,
                              data: option['option'],
                              builders: {
                                'latex': LatexElementBuilder(
                                  textStyle: GoogleFonts.raleway(
                                    color: Colors.white,
                                    fontSize: 14,
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
                                  fontSize: 14,
                                ),
                              ),
                            ))
                        // child: Row(
                        //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        //   children: [
                        //     MarkdownBody(
                        //       selectable: false,
                        //       data: option['option'],
                        //       builders: {
                        //         'latex': LatexElementBuilder(
                        //           textStyle: GoogleFonts.raleway(
                        //             color: Colors.white,
                        //             fontSize: 14,
                        //           ),
                        //         ),
                        //       },
                        //       extensionSet: md.ExtensionSet(
                        //         [LatexBlockSyntax()],
                        //         [LatexInlineSyntax()],
                        //       ),
                        //       styleSheet: MarkdownStyleSheet(
                        //         p: GoogleFonts.raleway(
                        //           color: Colors.white,
                        //           fontSize: 14,
                        //         ),
                        //       ),
                        //     ),
                        //     if (isActualCorrect)
                        //       Icon(Icons.check, color: Colors.green, size: 24)
                        //     else if (isSelected)
                        //       Icon(Icons.close, color: Colors.red, size: 24),
                        //   ],
                        // ),
                        ),
                  ),
                );
              });
            }).toList(),
            SizedBox(
              height: 20,
            ),
            if (!conversationStarted)
              Row(
                children: [
                  Expanded(
                    child: ChicletAnimatedButton(
                      onPressed: () {
                        startCorrectingMistake();
                      },
                      buttonType: ChicletButtonTypes.roundedRectangle,
                      height: 40,
                      buttonHeight: 4,
                      padding: const EdgeInsets.all(0),
                      buttonColor: Color.fromRGBO(187, 160, 2, 1),
                      backgroundColor: Color.fromRGBO(255, 217, 0, 1),
                      child: Text(
                        "START",
                        style: GoogleFonts.raleway(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8), // Add spacing between buttons
                  Expanded(
                    child: ChicletAnimatedButton(
                      onPressed: () {
                        _nextQuestion();
                      },
                      buttonType: ChicletButtonTypes.roundedRectangle,
                      height: 40,
                      buttonHeight: 4,
                      padding: const EdgeInsets.all(0),
                      buttonColor: Color.fromRGBO(187, 160, 2, 1),
                      backgroundColor: Color.fromRGBO(255, 217, 0, 1),
                      child: Text(
                        "SKIP",
                        style: GoogleFonts.raleway(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              )
          ],
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Mistake Correction",
          style: GoogleFonts.raleway(
              fontWeight: FontWeight.w700, color: Colors.white),
        ),
        backgroundColor: Color.fromRGBO(19, 31, 36, 1),
      ),
      backgroundColor: Color.fromRGBO(19, 31, 36, 1),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                height:
                    20, // Provide a fixed height or adjust based on your design
                child: Column(
                  children: [
                    Expanded(
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
                                width: availableWidth * getProgress(),
                                height: 16.0,
                                decoration: BoxDecoration(
                                  color: getProgressBarColor(getProgress()),
                                  borderRadius: BorderRadius.circular(16.0),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              )),
          // Expanded(
          //   child: Column(
          //     children: [
          //       Padding(
          //           padding: const EdgeInsets.symmetric(horizontal: 16.0),
          //           child: Row(
          //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //             children: [
          //               Text(
          //                 "Question ${currentQuestionIndex + 1} of ${widget.incorrectQuestions.length}",
          //                 style: GoogleFonts.raleway(
          //                   color: Colors.grey,
          //                   fontSize: 16,
          //                 ),
          //               ),
          //               if (conversationStarted)
          //                 ChicletAnimatedButton(
          //                   onPressed: () {
          //                     HapticFeedback.lightImpact();
          //                     _nextQuestion();
          //                   },
          //                   buttonType: ChicletButtonTypes.roundedRectangle,
          //                   height: 20,
          //                   buttonHeight: 4,
          //                   width: 80,
          //                   padding: EdgeInsets.all(0),
          //                   buttonColor: Color.fromRGBO(187, 160, 2, 1),
          //                   backgroundColor: Color.fromRGBO(255, 217, 0, 1),
          //                   child: Text(
          //                     "SKIP",
          //                     style: GoogleFonts.arOneSans(
          //                       color: Colors.black,
          //                       fontSize: 12,
          //                       fontWeight: FontWeight.w500,
          //                     ),
          //                   ),
          //                 ),
          //             ],
          //           )),

          //       buildQuestionCard(),
          //       // Chat Area
          //       if (isLoading)
          //         Center(child: CircularProgressIndicator())
          //       else
          //         Expanded(
          //             child: ListView.builder(
          //           // Disable internal scrolling
          //           itemCount: chatMessages.length,
          //           controller: _scrollController,
          //           itemBuilder: (context, index) {
          //             final chat = chatMessages[index];
          //             return Padding(
          //               padding: const EdgeInsets.symmetric(
          //                 vertical: 8.0,
          //                 horizontal: 12.0,
          //               ),
          //               child: chat['role'] == "user"
          //                   ? yourMessage(chat)
          //                   : othersMessage(chat),
          //             );
          //           },
          //         )),
          //     ],
          //   ),
          // ),
          // // Message Input and Next Button
          Expanded(
            child: ListView(
              controller: _scrollController, // Keep scrolling enabled
              children: [
                // Question Card
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Question ${currentQuestionIndex + 1} of ${widget.incorrectQuestions.length}",
                          style: GoogleFonts.raleway(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                        if (conversationStarted)
                          ChicletAnimatedButton(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              _nextQuestion();
                            },
                            buttonType: ChicletButtonTypes.roundedRectangle,
                            height: 20,
                            buttonHeight: 4,
                            width: 80,
                            padding: EdgeInsets.all(0),
                            buttonColor: Color.fromRGBO(187, 160, 2, 1),
                            backgroundColor: Color.fromRGBO(255, 217, 0, 1),
                            child: Text(
                              "SKIP",
                              style: GoogleFonts.arOneSans(
                                color: Colors.black,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    )),
                buildQuestionCard(),

                // Chat Area
                if (isLoading)
                  Center(child: CircularProgressIndicator())
                else
                  ListView.builder(
                    shrinkWrap: true, // Let it take only required space
                    physics:
                        NeverScrollableScrollPhysics(), // Prevent internal scrolling
                    itemCount: chatMessages.length,
                    itemBuilder: (context, index) {
                      final chat = chatMessages[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8.0,
                          horizontal: 12.0,
                        ),
                        child: chat['role'] == "user"
                            ? yourMessage(chat)
                            : othersMessage(chat),
                      );
                    },
                  ),
              ],
            ),
          ),
          if (!isLoading && !conversationCompleted && conversationStarted)
            renderMessageBar(),
          if (conversationCompleted)
            ChicletAnimatedButton(
              onPressed: () {
                mistakesCorrected += 1;
                _nextQuestion();
              },
              buttonType: ChicletButtonTypes.roundedRectangle,
              height: 40,
              width: double.infinity,
              buttonHeight: 4,
              padding: const EdgeInsets.all(0),
              buttonColor: Color.fromRGBO(187, 160, 2, 1),
              backgroundColor: Color.fromRGBO(255, 217, 0, 1),
              child: Text(
                "CONTINUE",
                style: GoogleFonts.raleway(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            )
        ],
      ),
    );
  }
}
