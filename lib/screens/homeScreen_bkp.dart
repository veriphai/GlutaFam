import 'package:eureka_app/screens/conceptLearningScreen.dart';
import 'package:eureka_app/widgets/streakScreen.dart';
import 'package:flutter/material.dart';
import 'package:chiclet/chiclet.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

class HomeScreenBKP extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreenBKP>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  String _activeTopic = '';
  int activeTopicIndex = 0;
  List<GlobalKey> _topicKeys = [];

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
      _activeButtonColour = buttonColours[0];
      addSequentialNumbers(chapters);
    }
    // Initialize keys for each topic
    _topicKeys = List.generate(
      chapters.fold<int>(
          0, (total, chapter) => total + (chapter['topics'].length as int)),
      (index) => GlobalKey(),
    );
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: const Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  OverlayEntry? _dropdownOverlayEntry;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  bool _isDropdownVisible = false;

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();

    super.dispose();
  }

  void _toggleDropdown(BuildContext context, GlobalKey buttonKey) {
    if (_isDropdownVisible) {
      _closeDropdown();
    } else {
      _showDropdown(context, buttonKey);
    }
  }

  void _showDropdown(BuildContext context, GlobalKey buttonKey) {
    final RenderBox renderBox =
        buttonKey.currentContext!.findRenderObject() as RenderBox;
    final Offset buttonPosition = renderBox.localToGlobal(Offset.zero);
    final Size buttonSize = renderBox.size;

    _dropdownOverlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: buttonPosition.dy + buttonSize.height,
        left: buttonPosition.dx,
        width: 200, // Adjust the width of the dropdown
        child: Material(
          color: Colors.transparent,
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "My Books",
                    style: GoogleFonts.raleway(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      print("Book 1 selected");
                      _closeDropdown();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Text(
                        "Book 1",
                        style: GoogleFonts.raleway(
                          color: Colors.grey[300],
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      print("Book 2 selected");
                      _closeDropdown();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Text(
                        "Book 2",
                        style: GoogleFonts.raleway(
                          color: Colors.grey[300],
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      print("Book 3 selected");
                      _closeDropdown();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Text(
                        "Book 3",
                        style: GoogleFonts.raleway(
                          color: Colors.grey[300],
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_dropdownOverlayEntry!);
    setState(() {
      _isDropdownVisible = true;
    });
    _animationController.forward();
  }

  void _closeDropdown() {
    _animationController.reverse().whenComplete(() {
      _dropdownOverlayEntry?.remove();
      _dropdownOverlayEntry = null;
      setState(() {
        _isDropdownVisible = false;
      });
    });
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
          if (position.dy <= MediaQuery.of(context).size.height * 0.2 &&
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
          if (position.dy <= MediaQuery.of(context).size.height * 0.5 &&
              position.dy > -box.size.height) {
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
  Widget build(BuildContext context) {
    final GlobalKey buttonKey = GlobalKey();

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
                  key: buttonKey,
                  onTap: () => _toggleDropdown(context, buttonKey),
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
        ListView.builder(
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
                              if (index == 0 || index == concepts.length - 1) {
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

                // print('${concepts[index]['name']} clicked');
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
