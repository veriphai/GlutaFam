import 'package:eureka_app/screens/conceptLearningScreen.dart';
import 'package:eureka_app/widgets/chapterSelection.dart';
import 'package:eureka_app/widgets/streakScreen.dart';
import 'package:eureka_app/widgets/subjectSelection.dart';
import 'package:flutter/material.dart';
import 'package:chiclet/chiclet.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  String _activeTopic = '';
  String activeChapter = '';
  int activeTopicIndex = 0;
  List<GlobalKey> _topicKeys = [];
  String _selectedSubject = "Science";

  // Mock data
  final List<Map<String, dynamic>> chapters = [
    {
      "chapterName": "Chapter 1",
      "chapterNumber": 1,
      "topics": [
        {
          "topicName": "Basic Sentences",
          "topicNumber": 1,
          "concepts": [
            {"name": "Form basic sentences", "type": "study"},
            {"name": "Earn a bonus", "type": "reward"},
            {"name": "Form basic sentences", "type": "study"},
            {"name": "Form basic sentences", "type": "study"},
            {"name": "Form basic sentences", "type": "study"},
            {"name": "Form basic sentences", "type": "study"},
          ],
        },
        {
          "topicName": "Greetings",
          "topicNumber": 2,
          "concepts": [
            {"name": "Say hello", "type": "study"},
            {"name": "Get a reward", "type": "reward"},
            {"name": "Form basic sentences", "type": "study"},
            {"name": "Form basic sentences", "type": "study"},
            {"name": "Form basic sentences", "type": "study"},
            {"name": "Form basic sentences", "type": "study"},
          ],
        },
        {
          "topicName": "Greetings -2",
          "topicNumber": 2,
          "concepts": [
            {"name": "Say hello", "type": "study"},
            {"name": "Get a reward", "type": "reward"},
            {"name": "Form basic sentences", "type": "study"},
            {"name": "Form basic sentences", "type": "study"},
            {"name": "Form basic sentences", "type": "study"},
          ],
        },
        {
          "topicName": "Greetings -2",
          "topicNumber": 2,
          "concepts": [
            {"name": "Say hello", "type": "study"},
            {"name": "Get a reward", "type": "reward"},
            {"name": "Form basic sentences", "type": "study"},
            {"name": "Form basic sentences", "type": "study"},
            {"name": "Form basic sentences", "type": "study"},
          ],
        },
      ],
    },
    {
      "chapterName": "Chapter 2",
      "chapterNumber": 2,
      "topics": [
        {
          "topicName": "Verbs and Actions",
          "topicNumber": 1,
          "concepts": [
            {"name": "Identify verbs", "type": "study"},
            {"name": "Win a badge", "type": "reward"},
            {"name": "Form basic sentences", "type": "study"},
            {"name": "Form basic sentences", "type": "study"},
            {"name": "Form basic sentences", "type": "study"},
          ],
        },
        {
          "topicName": "Verbs and Actions-2",
          "topicNumber": 2,
          "concepts": [
            {"name": "Identify verbs", "type": "study"},
            {"name": "Win a badge", "type": "reward"},
            {"name": "Form basic sentences", "type": "study"},
            {"name": "Form basic sentences", "type": "study"},
            {"name": "Form basic sentences", "type": "study"},
          ],
        },
      ],
    },
  ];

  final List<Map<String, dynamic>> buttonColours = [
    {
      "background": Color.fromRGBO(255, 217, 0, 1),
      "button": Color.fromRGBO(187, 160, 2, 1)
    },
    {
      "background": Color.fromRGBO(249, 168, 93, 1),
      "button": Color.fromRGBO(189, 113, 41, 1)
    },
    {
      "background": Color.fromRGBO(151, 241, 105, 1),
      "button": Color.fromRGBO(105, 185, 65, 1)
    },
    {
      "background": Color.fromRGBO(105, 207, 241, 1),
      "button": Color.fromRGBO(66, 158, 188, 1)
    },
    {
      "background": Color.fromRGBO(235, 122, 245, 1),
      "button": Color.fromRGBO(187, 86, 196, 1)
    }
  ];

  Map<String, dynamic> _activeButtonColour = {};

  void addSequentialNumbers(List<Map<String, dynamic>> chapters) {
    int seqNumber = 1; // Start the sequence from 1

    for (var chapter in chapters) {
      for (var topic in chapter['topics']) {
        topic['seqNumber'] = seqNumber; // Add seqNumber to the topic
        seqNumber++; // Increment for the next topic
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    if (chapters.isNotEmpty && chapters[0]['topics'].isNotEmpty) {
      _activeTopic = chapters[0]['topics'][0]['topicName'];
      activeChapter = chapters[0]['chapterName'];
      _activeButtonColour = buttonColours[0];
      addSequentialNumbers(chapters);
    }
    // Initialize keys for each topic
    _topicKeys = List.generate(
      chapters.fold<int>(
          0, (total, chapter) => total + (chapter['topics'].length as int)),
      (index) => GlobalKey(),
    );
  }

  double _previousScrollPosition = 0.0;

  void _onScroll() {
    double currentScrollPosition = _scrollController.position.pixels;
    bool isScrollingDown = currentScrollPosition > _previousScrollPosition;

    for (int i = 0; i < _topicKeys.length; i++) {
      final keyContext = _topicKeys[i].currentContext;
      if (keyContext != null) {
        final box = keyContext.findRenderObject() as RenderBox;
        final position = box.localToGlobal(Offset.zero);

        if (isScrollingDown) {
          // Scrolling Down: Update when the topic section enters the viewport
          if (position.dy <= MediaQuery.of(context).size.height * 0.25 &&
              position.dy >= 0) {
            setState(() {
              _activeTopic = chapters
                  .expand((chapter) => chapter['topics'])
                  .toList()[i]['topicName'];
              _activeButtonColour = buttonColours[i % buttonColours.length];
              activeTopicIndex = i;
            });
            break;
          }
        } else {
          // Scrolling Up: Update when the topic section is about to leave the viewport
          if (position.dy <= MediaQuery.of(context).size.height * 0.4 &&
              position.dy > -(box.size.height - 150)) {
            setState(() {
              _activeTopic = chapters
                  .expand((chapter) => chapter['topics'])
                  .toList()[i]['topicName'];
              _activeButtonColour = buttonColours[i % buttonColours.length];
              activeTopicIndex = i;
            });
            break;
          }
        }
      }
    }

    _previousScrollPosition = currentScrollPosition;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _showSubjectSelectionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[900],
      builder: (BuildContext context) {
        return SubjectSelection(
          selectedSubject: _selectedSubject,
          onSubjectSelect: (selected) {
            setState(() {
              _selectedSubject = selected;
            });
          },
        );
      },
    );
  }

  Future<void> scrollToTopic(int firstTopicIndex) async {
    // if (_scrollController.position.maxScrollExtent > 50) {
    //   _scrollController.jumpTo(50);
    // }
    final topicKey = _topicKeys[firstTopicIndex];

    // First, try to use the key's context
    if (topicKey.currentContext != null) {
      // If the widget is already rendered, scroll directly to it
      await Scrollable.ensureVisible(
        topicKey.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.1, // Aligns it slightly below the top
      );
    } else {
      ;

      // If the widget is not yet rendered, approximate the position and scroll
      final estimatedPosition = firstTopicIndex *
          MediaQuery.of(context).size.height; // Approximate height
      await _scrollController.animateTo(
        estimatedPosition,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );

      // Post-frame callback to ensure the widget is visible after rendering
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (topicKey.currentContext != null) {
          await Scrollable.ensureVisible(
            topicKey.currentContext!,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            alignment: 0.1,
          );
        }
      });
    }
  }

  void _showChapterSelectionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return ChapterSelection(
          chapters: chapters,
          activeChapter: activeChapter,
          onChapterSelect: (index, chapterName) {
            // Handle the selected chapter
            print("Selected Chapter: $chapterName (Index: $index)");

            // Get the first topic of the selected chapter
            final topics =
                chapters[index]['topics'] as List<Map<String, dynamic>>;
            if (topics.isNotEmpty) {
              // Find the key for the first topic in the selected chapter
              final firstTopicIndex = chapters
                  .take(index) // Take all chapters before the selected chapter
                  .fold<int>(
                    0,
                    (total, chapter) =>
                        total + (chapter['topics'].length as int),
                  ); // Calculate cumulative topic index

              final topicKey = _topicKeys[firstTopicIndex];

              // Scroll to the position of the first topic
              // final estimatedPosition =
              //     firstTopicIndex * 200.0; // Approximate height per item
              // _scrollController.animateTo(
              //   estimatedPosition,
              //   duration: const Duration(milliseconds: 500),
              //   curve: Curves.easeInOut,
              // );
              scrollToTopic(firstTopicIndex);

              // Update the active topic
              setState(() {
                activeChapter = chapterName;
                _activeTopic =
                    topics.first['topicName']; // Set first topic name
              });
            }

            // Navigator.pop(context); // Close the bottom sheet
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Image.asset('lib/assets/glutaclassLogo.png', height: 40),
                SizedBox(width: 10),
                GestureDetector(
                  onTap: () => _showSubjectSelectionSheet(context),
                  child: Icon(Icons.menu_book, color: Colors.yellow),
                ),
              ],
            ),
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.local_fire_department, color: Colors.orange),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => StreakScreen(
                        streakCount: 5, // Replace with actual data
                        streakStartDate: DateTime.now()
                            .subtract(Duration(days: 4)), // Example
                        streakGoal: 7, // Example goal
                      ),
                    );
                  },
                ),
                SizedBox(width: 5),
                Text('5', style: TextStyle(color: Colors.white)),
                SizedBox(width: 15),
                Icon(Icons.monetization_on, color: Colors.yellow),
                SizedBox(width: 5),
                Text('505', style: TextStyle(color: Colors.white)),
              ],
            ),
          ],
        ),
      ),
      body: Stack(children: [
        SizedBox(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: chapters.length,
            itemBuilder: (context, chapterIndex) {
              final chapter = chapters[chapterIndex];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children:
                    chapter['topics'].asMap().entries.map<Widget>((topicEntry) {
                  final int topicIndex = topicEntry.key;
                  final topic = topicEntry.value;
                  final concepts = topic['concepts'];
                  final globalKeyIndex = chapters.take(chapterIndex).fold<int>(
                          0,
                          (total, chapter) =>
                              total + (chapter['topics'].length as int)) +
                      topicIndex;
                  final buttonColour = buttonColours[
                      (topic['seqNumber'] - 1) % buttonColours.length];

                  // final buttonColour;
                  // if (chapterIndex == 0 && topicIndex == 0) {
                  //   buttonColour = buttonColours[topicIndex];
                  // } else {
                  //   int randomIndex = Random().nextInt(4) +
                  //       1; // Generates a random number from 1 to 5
                  //   buttonColour = buttonColours[randomIndex];
                  // }
                  return Padding(
                    key: _topicKeys[globalKeyIndex],
                    padding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Divider with Topic Name
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 20, horizontal: 20),
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      color: Colors.grey,
                                      thickness: 1,
                                      endIndent:
                                          10, // Space between divider and text
                                    ),
                                  ),
                                  Text(
                                    topic['topicName'],
                                    style: GoogleFonts.raleway(
                                      color: Colors.grey,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: Colors.grey,
                                      thickness: 1,
                                      indent:
                                          10, // Space between text and divider
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Concept Islands in a Stack with Alternating Pattern
                        SizedBox(
                          height: concepts.length * 120.0,
                          child: Stack(
                            children: [
                              Positioned(
                                top: 0,
                                left: topicIndex % 2 != 0
                                    ? 20
                                    : null, // Left for odd topics
                                right: topicIndex % 2 == 0
                                    ? 20
                                    : null, // Right for even topics
                                child: Container(
                                  width: 150,
                                  height: concepts.length * 120.0,
                                  alignment: Alignment.center,
                                  child: Image.asset(
                                    'lib/assets/glutaclassLogo.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              ...List.generate(concepts.length, (index) {
                                double topOffset = index * 120.0;
                                double screenWidth =
                                    MediaQuery.of(context).size.width;
                                double leftOffset;

                                // First, fifth, and last concepts are centered
                                if (index == 0 ||
                                    index == concepts.length - 1) {
                                  leftOffset = (screenWidth - 100) / 2;
                                } else {
                                  // Alternate directions based on topicIndex
                                  bool isEvenTopic = topicIndex % 2 == 0;
                                  int shift = index % 2 == 1 ? 30 : 60;
                                  shift = index == 4 ? 10 : shift;
                                  leftOffset = isEvenTopic
                                      ? (screenWidth / 2) -
                                          shift -
                                          60 // Shift left for even topics
                                      : ((screenWidth - 60) / 2) +
                                          shift; // Shift right for odd topics
                                }

                                return Positioned(
                                  top: topOffset,
                                  left: leftOffset,
                                  child: ChicletAnimatedButton(
                                    onPressed: () {
                                      HapticFeedback.lightImpact();
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ConceptLearningScreen(
                                            conceptId: "concept_1",
                                            conceptName: "First Concept",
                                          ),
                                        ),
                                      );
                                    },
                                    buttonType: ChicletButtonTypes.oval,
                                    width: 80,
                                    height: 70,
                                    buttonHeight: 10,
                                    padding: EdgeInsets.all(0),
                                    buttonColor: buttonColour['button'],
                                    backgroundColor: buttonColour['background'],
                                    child: concepts[index]['type'] == 'reward'
                                        ? Icon(Icons.card_giftcard,
                                            color: Colors.black, size: 40)
                                        : Icon(Icons.star,
                                            color: Colors.black, size: 40),
                                  ),
                                );
                              })
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
        Positioned(
          top: 0,
          left: 20,
          right: 20,
          child: ChicletAnimatedButton(
              onPressed: () {
                HapticFeedback.lightImpact();

                // print('${concepts[index]['name']} clicked');
              },
              // buttonType: ChicletButtonTypes.oval,
              // width: 80,
              height: 70,
              buttonHeight: 8,
              padding: EdgeInsets.all(0),
              buttonColor: _activeButtonColour['button'],
              backgroundColor: _activeButtonColour['background'],
              child: Text(
                _activeTopic,
                style: GoogleFonts.raleway(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              )),
        ),
        Positioned(
          bottom: 20,
          left: 20,
          child: ChicletAnimatedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                _showChapterSelectionSheet(context);
              },
              buttonType: ChicletButtonTypes.circle,
              width: 80,
              height: 50,
              buttonHeight: 4,
              padding: EdgeInsets.all(0),
              buttonColor: Color.fromRGBO(187, 160, 2, 1),
              backgroundColor: Color.fromRGBO(255, 217, 0, 1),
              child: Icon(Icons.menu_book, color: Colors.black, size: 30)),
        )
      ]),
    );
  }
}
