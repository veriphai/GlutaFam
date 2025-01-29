import 'dart:async';
import 'package:bubble_box/bubble_box.dart';
import 'package:chiclet/chiclet.dart';
import 'package:eureka_app/apis/fetchChatResponse.dart';
import 'package:eureka_app/utils/appHelperService.dart';
import 'package:eureka_app/utils/avatars.dart';
import 'package:eureka_app/widgets/mcqQuestionsWidget.dart';
import 'package:flutter/material.dart';
import 'package:chat_bubbles/chat_bubbles.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown_latex/flutter_markdown_latex.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

class ConversationScreen extends StatefulWidget {
  final String conceptId;
  final String conceptName;
  final int maxXP;
  const ConversationScreen(
      {Key? key,
      required this.conceptId,
      required this.conceptName,
      required this.maxXP})
      : super(key: key);
  @override
  _ConversationScreenState createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final List<Map<String, String>> conversations = [
    {
      "_id": "conversation_1",
      "name": "Aarav",
      "conversation": """
Oh, that’s cool! So if \$a = 3\$ and \$b = 4\$, then \$c\$ would be:
\\[ c = \\sqrt{3^2 + 4^2} = \\sqrt{9 + 16} = 5 \\]
"""
    },
    {
      "_id": "conversation_2",
      "name": "Meera",
      "conversation": "Simplify \$(3x^2-5x+3)+(-3x^2+5x-3)\$"
    },
    {
      "_id": "conversation_3",
      "name": "Sam",
      "conversation": "Wait, so plants don’t just eat food like us?"
    },
    {
      "_id": "conversation_4",
      "name": "Meera",
      "conversation":
          "Nope! They make their food. It’s kind of like they’re little chefs. They take sunlight as energy, water from the soil, and carbon dioxide from the air to create glucose – their food."
    },
    {
      "_id": "conversation_5",
      "name": "Tara",
      "conversation":
          "And they also give out oxygen as a by-product, which we breathe in!"
    },
    {
      "_id": "conversation_6",
      "name": "Aarav",
      "conversation":
          "Ohhh, that’s cool! But how does sunlight help them make food?"
    },
    {
      "_id": "conversation_7",
      "name": "Meera",
      "conversation":
          "Good question! Plants have this green pigment called chlorophyll, which absorbs sunlight. Chlorophyll is what makes leaves look green."
    },
    {
      "_id": "conversation_8",
      "name": "Sam",
      "conversation": "So, chlorophyll is why plants are green?"
    },
    {"_id": "conversation_9", "name": "Meera", "conversation": "Exactly!"},
    {
      "_id": "conversation_10",
      "name": "Aarav",
      "conversation":
          "Okay, so they use sunlight and chlorophyll. But where do the other things come in – like water and carbon dioxide?"
    },
    {
      "_id": "conversation_11",
      "name": "Meera",
      "conversation":
          "Water is absorbed by the roots from the soil. Carbon dioxide comes from the air and enters the leaves through tiny pores called stomata."
    },
    {
      "_id": "conversation_12",
      "name": "Aarav",
      "conversation": "Stomata? What are those?"
    },
    {
      "_id": "conversation_13",
      "name": "Meera",
      "conversation":
          "They’re just tiny pores on the leaves that allow the plant to take in carbon dioxide and release oxygen."
    },
    {
      "_id": "conversation_14",
      "name": "Sam",
      "conversation": "What happens next? How does it all come together?"
    },
    {
      "_id": "conversation_15",
      "name": "Tara",
      "conversation":
          "Inside the chloroplasts, sunlight provides energy to combine water and carbon dioxide to make glucose, and oxygen is released as a by-product."
    },
    {
      "_id": "conversation_16",
      "name": "Aarav",
      "conversation": "Ohh, so plants are literally like little factories?"
    },
    {
      "_id": "conversation_17",
      "name": "Meera",
      "conversation":
          "Yep! And the whole reaction looks like this in science terms: 6CO2 + 6H2O + light energy → C6H12O6 + 6O2."
    },
    {
      "_id": "conversation_18",
      "name": "Sam",
      "conversation": "That’s wild. But why does it matter so much?"
    },
    {
      "_id": "conversation_19",
      "name": "Tara",
      "conversation":
          "Because plants are the base of the food chain. They make food for themselves and for all of us. Plus, they give out oxygen, so we can breathe."
    },
    {
      "_id": "conversation_20",
      "name": "Aarav",
      "conversation":
          "Got it! So let me sum this up: Photosynthesis happens in plants, algae, and some bacteria. It needs sunlight, water, and carbon dioxide. Chlorophyll traps sunlight to power the process. It makes glucose and oxygen."
    },
    {
      "_id": "conversation_21",
      "name": "Tara",
      "conversation":
          "Perfect! And don’t forget, it all happens in the chloroplasts in the cells."
    },
    {
      "_id": "conversation_22",
      "name": "Sam",
      "conversation":
          "You know, I never thought about how important plants are. They’re like the planet’s life-support system."
    },
    {
      "_id": "conversation_23",
      "name": "Meera",
      "conversation":
          "Yeah, they’re literally keeping us alive. No photosynthesis, no oxygen, no us."
    },
    {
      "_id": "conversation_24",
      "name": "Aarav",
      "conversation": "Wow, plants are superheroes in disguise! Respect. 🌱"
    }
  ];
  List<Map<String, String>> displayedConversations = [];
  int conversationIndex = 0;
  final ScrollController _scrollController = ScrollController();
  bool isContinueButtonEnabled = false;
  bool isRenderingConversations = false;
  bool isChatMode = false;
  Map<String, dynamic> raiseHandConversations = {};
  Map<String, String> characters = {};
  late Map<String, dynamic> userProfile;

  Map<String, String> assignSequentialAvatars(
      List<Map<String, String>> conversations) {
    final Map<String, String> assignedAvatars = {};
    int avatarIndex = 1;

    for (var conversation in conversations) {
      final name = conversation["name"];
      if (name != null && !assignedAvatars.containsKey(name)) {
        assignedAvatars[name] = getAvatar("avatar-$avatarIndex")["imagePath"]!;
        avatarIndex++;
      }
    }

    return assignedAvatars;
  }

  Future<void> fetchProfile() async {
    try {
      final profileData = await getProfile();
      setState(() {
        userProfile = profileData;
      });
    } catch (error) {
      print("Error fetching userProfile: $error");
    }
  }

  @override
  void initState() {
    super.initState();
    fetchProfile();
    characters = assignSequentialAvatars(conversations);
    _startRenderingConversations();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _startRenderingConversations() async {
    if (isRenderingConversations) return; // Prevent multiple calls
    isRenderingConversations = true;

    final batchSize = 4; // Number of messages per batch

    while (conversationIndex < conversations.length) {
      final endIndex =
          (conversationIndex + batchSize).clamp(0, conversations.length);

      for (int i = conversationIndex; i < endIndex; i++) {
        // Show the current message instantly
        setState(() {
          displayedConversations.add(conversations[i]);
        });

        // Scroll to the bottom after adding a new message
        scrollToBottom();

        if (i < endIndex - 1) {
          // Calculate the delay based on the length of the current message
          final currentMessageLength = conversations[i]['conversation']!.length;
          final delayDuration = Duration(
              milliseconds: 50 * currentMessageLength); // 50ms per character

          // Wait for the calculated delay before showing the next message
          await Future.delayed(delayDuration);
        }
      }

      conversationIndex = endIndex;

      setState(() {
        isContinueButtonEnabled = true;
      });

      // Wait for user to click "Continue" before loading the next batch
      await Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 100));
        return isContinueButtonEnabled;
      });
    }

    isRenderingConversations = false;
  }

  void _handleContinue() {
    if (conversationIndex >= conversations.length) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MCQQuestions(
            conceptId: widget.conceptId,
            conceptName: widget.conceptName,
            maxXP: widget.maxXP,
          ),
        ),
      );
    } else {
      setState(() {
        isContinueButtonEnabled = false;
      });

      // Trigger the next batch of messages
      _startRenderingConversations();
    }
  }

  final Map<String, Color> senderColors = {};

  // Generate a consistent color for each sender
  Color getSenderColor(String sender) {
    if (!senderColors.containsKey(sender)) {
      senderColors[sender] =
          Colors.primaries[senderColors.length % Colors.primaries.length];
    }
    return senderColors[sender]!;
  }

  Widget othersMessage(final senderColor, final conversation) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Circular Avatar
        Image.asset(
          characters[conversation["name"]]!,
          height: 60,
        ),
        SizedBox(
          width: 4,
        ),
        // Chat Bubble
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
                    ))))
      ],
    );
  }

  Widget entryExitConversation(final conversation) {
    return Center(
        child: Container(
      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      decoration: BoxDecoration(
          color: Colors.grey, borderRadius: BorderRadius.circular(8)),
      child: Text(
        "${conversation['conversation']!}",
        style: GoogleFonts.raleway(
          color: Colors.white,
          fontSize: 14, // Small size kept aligned to the left
          fontWeight: FontWeight.w500,
        ),
      ),
    ));
  }

  Widget yourMessage(final senderColor, final conversation) {
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
        SizedBox(
          width: 4,
        ),
        Image.asset(
          getAvatar(userProfile["avatar"])["imagePath"]!,
          height: 60,
        ),
      ],
    );
  }

  // Widget yourMessage(final senderColor, final conversation) {
  //   return Row(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Expanded(
  //         child: Stack(
  //           children: [
  //             BubbleSpecialOne(
  //               text: "${conversation['conversation']!}",
  //               color: Color.fromRGBO(44, 250, 106, 0.2),
  //               tail: true,
  //               isSender: true,
  //               textStyle: const TextStyle(
  //                 color: Colors.white,
  //                 fontSize: 16,
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ],
  //   );
  // }

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
      color: Colors.black,
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: MessageBar(
              messageBarColor: Colors.black,
              onSend: (message) async {
                // Add user's message to the chat
                setState(() {
                  displayedConversations.add({
                    "_id": DateTime.now().toString(),
                    "name": "You",
                    "conversation": message,
                  });
                });

                // Scroll to the bottom after sending a new message
                scrollToBottom();

                // Fetch AI responses
                final List<Map<String, dynamic>> aiResponses =
                    await fetchChatResponse(
                  conversations: conversations.sublist(0, conversationIndex),
                  characters: ["Meera", "Sam", "Tara", "Aarav"],
                  conceptName: "Photosynthesis",
                  query: message,
                );

                // Render the first message immediately
                if (aiResponses.isNotEmpty) {
                  setState(() {
                    displayedConversations.add({
                      "_id": aiResponses[0]['conversation'],
                      "name": aiResponses[0]['name'], // AI character name
                      "conversation": aiResponses[0]
                          ['conversation'], // AI message
                    });
                  });

                  // Scroll after adding the first message
                  scrollToBottom();

                  // Render the remaining messages with a delay
                  for (int i = 1; i < aiResponses.length; i++) {
                    await Future.delayed(
                        const Duration(seconds: 2)); // Adjust delay as needed
                    setState(() {
                      displayedConversations.add({
                        "_id": aiResponses[i]['conversation'],
                        "name": aiResponses[i]['name'],
                        "conversation": aiResponses[i]['conversation'],
                      });
                    });

                    // Scroll after each delayed message
                    scrollToBottom();
                  }
                }

                // Exit the conversation after the last response
                setState(() {
                  displayedConversations.add({
                    "_id": DateTime.now().toString(),
                    "name": "You",
                    "conversation": "You exited the conversation!",
                    "entryExit": "True",
                  });

                  // Scroll to the bottom after AI response
                  scrollToBottom();

                  // Close the chat mode
                  isChatMode = false;
                });
              },
            ),
          ),
          // Close Button
          IconButton(
            onPressed: () {
              // Handle close action
              setState(() {
                displayedConversations.add({
                  "_id": DateTime.now().toString(),
                  "name": "You",
                  "conversation": "You exited the conversation!",
                  "entryExit": "True"
                });

                // Scroll to the bottom after AI response
                scrollToBottom();

                isChatMode = false;
              });
            },
            icon: Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  void handleRaiseHandClick() {
    HapticFeedback.lightImpact();
    setState(() {
      isChatMode = true;
    });

    // Add "You joined the chat" and AI greetings
    setState(() {
      displayedConversations.add({
        "_id": DateTime.now().toString(),
        "name": "You",
        "conversation": "You joined the chat",
        "entryExit": "True"
      });

      // AI Participants Greetings
      final List<Map<String, String>> greetings = [
        {"_id": "greeting_1", "name": "Meera", "conversation": "Hi!"},
        {"_id": "greeting_2", "name": "Sam", "conversation": "Hello!"},
        {"_id": "greeting_3", "name": "Tara", "conversation": "Welcome!"},
      ];
      displayedConversations.addAll(greetings);

      // Scroll to the bottom to show greetings
      scrollToBottom();
    });
  }

  double getProgress() {
    return (conversationIndex) / conversations.length;
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

  void _showSkipConfirmationSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Are you sure you want to skip?",
                style: GoogleFonts.raleway(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                "Your Total XP will be reduced by 15.",
                style: GoogleFonts.raleway(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Column(
                children: [
                  ChicletAnimatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close the sheet
                    },
                    buttonType: ChicletButtonTypes.roundedRectangle,
                    height: 50,
                    width: double.infinity,
                    buttonHeight: 4,
                    buttonColor: Color.fromRGBO(187, 160, 2, 1),
                    backgroundColor: Color.fromRGBO(255, 217, 0, 1),
                    child: Text(
                      "STAY ON TRACK",
                      style: GoogleFonts.raleway(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  ChicletAnimatedButton(
                      onPressed: () {
                        Navigator.pop(context); // Close the sheet
                        // Navigate to MCQQuestions screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MCQQuestions(
                              conceptId: widget.conceptId,
                              conceptName: widget.conceptName,
                              maxXP: widget.maxXP - 15,
                            ),
                          ),
                        );
                      },
                      buttonType: ChicletButtonTypes.roundedRectangle,
                      height: 50,
                      width: double.infinity,
                      buttonHeight: 4,
                      buttonColor: Color.fromRGBO(187, 160, 2, 1),
                      backgroundColor: Color.fromRGBO(255, 217, 0, 1),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "TAKE THE SHORTCUT",
                            style: GoogleFonts.raleway(
                              color: Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "  -15",
                            style: GoogleFonts.arOneSans(
                              color: Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            " XP",
                            style: GoogleFonts.raleway(
                              color: Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromRGBO(19, 31, 36, 1),
        elevation: 0,
        iconTheme: IconThemeData(
          color: Colors.grey,
        ),
        title: Text(
          widget.conceptName,
          style: GoogleFonts.raleway(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      backgroundColor: Color.fromRGBO(19, 31, 36, 1),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
            child: Row(
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
                            duration: const Duration(
                                milliseconds: 300), // Animation duration
                            curve: Curves.easeInOut, // Animation curve
                            width: availableWidth *
                                getProgress(), // Dynamically adjust width
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
                const SizedBox(width: 20),
                ChicletAnimatedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _showSkipConfirmationSheet(context);
                  },
                  buttonType: ChicletButtonTypes.roundedRectangle,
                  height: 20,
                  buttonHeight: 4,
                  width: 80,
                  padding: EdgeInsets.all(0),
                  buttonColor: Color.fromRGBO(187, 160, 2, 1),
                  backgroundColor: Color.fromRGBO(255, 217, 0, 1),
                  child: Text(
                    "SKIP  -15 XP",
                    style: GoogleFonts.arOneSans(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Chat List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: displayedConversations.length,
              itemBuilder: (context, index) {
                final conversation = displayedConversations[index];
                final senderColor = getSenderColor(conversation['name']!);

                return Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 12.0),
                    child: conversation.containsKey("entryExit")
                        ? entryExitConversation(conversation)
                        : conversation['name'] == "You"
                            ? yourMessage(senderColor, conversation)
                            : othersMessage(senderColor, conversation));
              },
            ),
          ),
          isChatMode
              ? renderMessageBar()
              : Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      // Continue Button
                      Expanded(
                        child: ChicletAnimatedButton(
                          onPressed:
                              isContinueButtonEnabled ? _handleContinue : null,
                          buttonType: ChicletButtonTypes.roundedRectangle,
                          height: 40,
                          buttonHeight: 4,
                          padding: const EdgeInsets.all(0),
                          buttonColor: isContinueButtonEnabled
                              ? Color.fromRGBO(187, 160, 2, 1)
                              : Colors.grey[600]!,
                          backgroundColor: isContinueButtonEnabled
                              ? Color.fromRGBO(255, 217, 0, 1)
                              : Colors.grey,
                          child: Text(
                            "CONTINUE",
                            style: GoogleFonts.raleway(
                              color: isContinueButtonEnabled
                                  ? Colors.black
                                  : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                          width: 8), // Small space between the buttons
                      // Raise Hand Button
                      SizedBox(
                        width: 50, // Fixed width for the Raise Hand button
                        child: ChicletAnimatedButton(
                          onPressed: isContinueButtonEnabled
                              ? handleRaiseHandClick
                              : null,
                          buttonType: ChicletButtonTypes.roundedRectangle,
                          height: 40,
                          buttonHeight: 4,
                          padding: const EdgeInsets.all(0),
                          buttonColor: isContinueButtonEnabled
                              ? Color.fromRGBO(187, 160, 2, 1)
                              : Colors.grey[600]!,
                          backgroundColor: isContinueButtonEnabled
                              ? Color.fromRGBO(255, 217, 0, 1)
                              : Colors.grey,
                          child: Icon(
                            Icons.back_hand_rounded,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  )),
        ],
      ),
    );
  }
}
