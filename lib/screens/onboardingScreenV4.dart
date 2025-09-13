import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:bubble_box/bubble_box.dart';
import 'package:chiclet/chiclet.dart';
import 'package:eureka_app/apis/getClassOptions.dart';
import 'package:eureka_app/apis/saveProfile.dart';
import 'package:eureka_app/events/onboardingAndLoginEvents.dart';
import 'package:eureka_app/main.dart';
import 'package:eureka_app/screens/home/homeScreen.dart';
import 'package:eureka_app/utils/authTokenService.dart';
import 'package:eureka_app/widgets/schoolSelectionWidget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreenV4 extends StatefulWidget {
  final String? deviceId;
  final String? platform;
  final String? userIP;
  const OnboardingScreenV4({
    Key? key,
    this.deviceId,
    this.platform,
    this.userIP,
  }) : super(key: key);

  @override
  _OnboardingScreenV4State createState() => _OnboardingScreenV4State();
}

class _OnboardingScreenV4State extends State<OnboardingScreenV4> {
  int currentPage = 0;
  int currentProgress = 1;
  String? selectedOption;
  Map<String, dynamic> selectedOptions = {};
  TextEditingController? nameController; // Persistent controller
  final AudioPlayer continueAudioPlayer = AudioPlayer();
  AuthTokenService authTokenService = AuthTokenService();
  Map<String, Set<String>> multiSelectStates = {};

  late List<Map<String, dynamic>> classOptions = [
    {"name": "Class 6", "standard": 6},
    {"name": "Class 7", "standard": 7},
    {"name": "Class 8", "standard": 8},
    {"name": "Class 9", "standard": 9},
    {"name": "Class 10", "standard": 10}
  ];

  final List<Map<String, dynamic>> pages = [
    {
      "pageNo": 2,
      "type": "info_message",
      "headingType": "generic",
      "heading": "Hi there! I am Tuto!",
      "mascotImage": "lib/assets/animations/lovelyCat.json",
      "description": "",
    },
    {
      "pageNo": 2,
      "type": "info_message",
      "headingType": "generic",
      "heading":
          'My parents used to say, "Curiosity killed the cat," but they never mentioned the second part: "satisfaction brought it back."',
      "mascotImage": "lib/assets/animations/lovelyCat.json",
      "description": "",
    },
    {
      "pageNo": 2,
      "type": "info_message",
      "headingType": "generic",
      "heading":
          "I am curious to learn more about you. I just have a few quick questions before we start your first lesson.",
      "mascotImage": "lib/assets/animations/lovelyCat.json",
      "description": "",
    },
    {
      "pageNo": 1,
      "type": "class_selection",
      "heading": "In which class are you?",
      "mascotImage": "lib/assets/animations/catNotingDown.json",
      "description": "",
      "options": ["Class 6", "Class 7", "Class 8", "Class 9", "Class 10"]
    },
    {
      "pageNo": 2,
      "type": "info_message",
      "headingType": "class",
      "heading":
          "Get ready to join all the {} learners growing their conceptual understanding!",
      "mascotImage": "lib/assets/animations/lovelyCat.json",
      "description": "",
    },
    {
      "pageNo": 2,
      "type": "source_of_information",
      "heading": "How did you hear about Tuto?",
      "mascotImage": "lib/assets/animations/catNotingDown.json",
      "description": "",
      "options": [
        "App Store",
        "Facebook/Instagram",
        "Friends/Family",
        "Google Search",
        "News/Article/Blog"
      ]
    },
    {
      "pageNo": 3,
      "type": "goal_selection",
      "heading": "What is your primary goal with Tuto?",
      "mascotImage": "lib/assets/animations/catNotingDown.json",
      "description": "",
      "options": [
        "Improve grades",
        "Revise for exams",
        "Understand concepts better",
        "Explore new topics"
      ]
    },
    {
      "pageNo": 2,
      "type": "info_message",
      "headingType": "goal",
      "heading":
          "Great! We'll focus on helping you {} and make learning paws-itively fun!",
      "mascotImage": "lib/assets/animations/lovelyCat.json",
      "description": "",
    },
    {
      "pageNo": 2,
      "type": "info_message",
      "headingType": "generic",
      "heading": "Let's personalise the journey for you!",
      "mascotImage": "lib/assets/animations/lovelyCat.json",
      "description": "",
    },
    {
      "pageNo": 0,
      "type": "challenges",
      "subType": "multi-select",
      "heading": "Which challenge trips you up most when studying on your own?",
      "mascotImage": "lib/assets/animations/catNotingDown.json",
      "description": "",
      "options": [
        "💤 Can’t focus / phone pings",
        "⏲ Too little time",
        "🤯 Concepts feel confusing",
        "🤷‍♂️ No one to clear doubts",
        "😓 Forget soon after studying",
        "📚 Too much homework / syllabus",
        "😐 Material feels boring"
      ]
    },
    {
      "pageNo": 0,
      "type": "startNewChapter",
      "subType": "multi-select",
      "heading": "What’s your first move when you start a new chapter?",
      "mascotImage": "lib/assets/animations/catNotingDown.json",
      "description": "",
      "options": [
        "✍️ Work through practice questions",
        "🎞 Watch a short video",
        "📖 Read textbook/notes",
        "🎤 Talk it out with someone",
        "🧠 Use flashcards/mnemonics",
        "🛠 Do a hands-on project"
      ]
    },
    {
      "pageNo": 0,
      "type": "learnBestThrough",
      "subType": "multi-select",
      "heading": "What methods help you learn tough concepts the best?",
      "mascotImage": "lib/assets/animations/catNotingDown.json",
      "description": "",
      "options": [
        "🧩 Step-by-step solved examples",
        "🌍 Real-life stories/analogies",
        "🎨 Animated visuals",
        "🧠 Memory tricks/flashcards",
        "💬 Discussion & Q&A"
      ]
    },
    {
      "pageNo": 0,
      "type": "helpNeeded",
      "subType": "multi-select",
      "heading": "When do you usually feel you need help or extra assistance?",
      "mascotImage": "lib/assets/animations/catNotingDown.json",
      "description": "",
      "options": [
        "📝 While doing homework / assignments",
        "🧪 Before an upcoming test",
        "🔄 When revising what was taught in class",
        "❓ When I’m stuck on a specific doubt",
        "🚀 When I want to get ahead / explore",
        "🧐 To quiz me"
      ]
    },
    {
      "pageNo": 0,
      "type": "videoIssues",
      "subType": "multi-select",
      "heading": "What bugs you most about learning videos on YouTube?",
      "mascotImage": "lib/assets/animations/catNotingDown.json",
      "description": "",
      "options": [
        "⏱ Too long / rambling",
        "🚀 Too fast",
        "❓ Can’t ask doubts",
        "🎯 Hard to find exact topic",
        "📝 Lack of notes & practice questions",
        "🧹 Too much filler / clickbait intro",
        "🔧 Not personalised to your context"
      ]
    },
    {
      "pageNo": 2,
      "type": "info_message",
      "headingType": "generic",
      "heading": "I think you and me are going to get along purr-fectly",
      "mascotImage": "lib/assets/animations/lovelyCat.json",
      "description": "",
    },
    {
      "pageNo": 2,
      "type": "info_message",
      "headingType": "generic",
      "heading":
          "I got so excited meeting you that I forgot to even ask about your name!",
      "mascotImage": "lib/assets/animations/lovelyCat.json",
      "description": "",
    },
    {
      "pageNo": 10,
      "type": "name_input",
      "heading": "What is your name?",
      "mascotImage": "assets/images/mascot_name.png",
      "description": "",
      "inputType": "text"
    },
    {
      "pageNo": 2,
      "type": "info_message",
      "headingType": "generic",
      "heading":
          "I am so satisfied by getting to know you. Let's dive into learning, and remember learning with Tuto everyday keeps bad grades away!",
      "mascotImage": "lib/assets/animations/lovelyCat.json",
      "description": "",
    }
  ];

  @override
  void initState() {
    super.initState();
    fetchClassOptions();
    // Initialize the controller with the selected option (if available)
    nameController = TextEditingController(text: selectedOptions["name_input"]);
    continueAudioPlayer.setSource(AssetSource('correct_answer.mp3')).then((_) {
      print('Correct answer audio preloaded');
    });
    logOnboardingScreenView(widget.deviceId ?? "", widget.platform ?? "",
        widget.userIP ?? "", currentPage + 1);
  }

  @override
  void dispose() {
    nameController
        ?.dispose(); // Dispose of the controller when no longer needed
    super.dispose();
  }

  void _playSound(String soundPath) {
    try {
      continueAudioPlayer.play(AssetSource(soundPath));
    } catch (e) {
      print("Error playing sound: $e");
    }
  }

  void _updateSelection(String type, dynamic value) {
    setState(() {
      selectedOptions[type] = value;
    });
  }

  Future<void> fetchClassOptions() async {
    try {
      final classesData = await getClassOptions();

      setState(() {
        classOptions = classesData;
      });
    } catch (error) {
      print("Error fetching class options: $error");
    }
  }

  String findPreparationType(int classNumber) {
    if (classNumber == 11) {
      return "JEE_2025";
    }
    if (classNumber == 12) {
      return "JEE_2026";
    }
    if (classNumber == 13) {
      return "NEET_2025";
    }
    if (classNumber == 14) {
      return "NEET_2026";
    }
    if (classNumber == 15) {
      return "UPSC";
    }
    return "K_10";
  }

  Map<String, dynamic> prepareDataToSave(SharedPreferences prefs) {
    String refereeCode = prefs.getString("referralCode") ?? '';
    String fcmToken = prefs.getString("fcmToken") ?? '';
    Map<String, dynamic> processedData = {};
    int standard = 0;
    String stream = "";
    int streak = 7;

    // Class selection processing
    if (selectedOptions["class_selection"] != null) {
      String classSelection = selectedOptions["class_selection"];
      // Find the matching option in the list
      final selected = classOptions.firstWhere(
        (option) => option['name'] == classSelection,
        orElse: () => {},
      );

      if (selected.isNotEmpty) {
        standard = selected['standard'];
        stream = selected['stream'] ?? ""; // Will be null for classes 6-10
      }
    }
    if (selectedOptions["commit_to_learning"] != null) {
      String classSelection = selectedOptions["commit_to_learning"];
      if (classSelection == "7 day streak") {
        streak = 7;
      } else if (classSelection == "14 day streak") {
        streak = 14;
      } else if (classSelection == "30 day streak") {
        streak = 30;
      } else if (classSelection == "50 day streak") {
        streak = 50;
      }
    }

    String? primaryGoal = selectedOptions["goal_selection"];

    String? sourceOfInformation = selectedOptions["source_of_information"];

    String? dailyGoal = selectedOptions["daily_goal"];

    String? preferredLearningTime = selectedOptions["learning_time"];

    String? motivation = selectedOptions["motivation"];

    String? learningPreference = selectedOptions["learning_preference"];

    String? progressReports = selectedOptions["progress_reports"];

    String? userName = selectedOptions["name_input"];

    String? state = selectedOptions["state"];
    String? city = selectedOptions["city"];
    String? school = selectedOptions["school"];
    String? schoolId = selectedOptions["schoolId"];

    String challenges = (multiSelectStates["challenges"] ?? {}).join(", ");
    String startNewChapter =
        (multiSelectStates["startNewChapter"] ?? {}).join(", ");
    String videoIssues = (multiSelectStates["videoIssues"] ?? {}).join(", ");
    String learnBestThrough =
        (multiSelectStates["learnBestThrough"] ?? {}).join(", ");
    String helpNeeded = (multiSelectStates["helpNeeded"] ?? {}).join(", ");

    // Add all processed data to the map
    processedData = {
      "standard": standard,
      "stream": stream,
      "quizType": "K_12",
      "goal": primaryGoal,
      "sourceOfInformation": sourceOfInformation,
      "dailyGoal": dailyGoal,
      "streakGoal": streak,
      "preferredLearningTime": preferredLearningTime,
      "motivation": motivation,
      "learningPreference": learningPreference,
      "progressReports": progressReports,
      "firstName": userName,
      "state": state,
      "city": city,
      "school": school,
      "schoolId": schoolId,
      "deviceId": widget.deviceId,
      "refereeCode": refereeCode,
      "devicePlatform": widget.platform,
      "userIp": widget.userIP,
      "fcmDeviceToken": fcmToken,
      "challenges": challenges,
      "startNewChapter": startNewChapter,
      "videoIssues": videoIssues,
      "learnBestThrough": learnBestThrough,
      "helpNeeded": helpNeeded
    };

    return processedData;
  }

  void _nextPage() async {
    if (pages[currentPage]['type'] != 'info_message') {
      _playSound('correct_answer.mp3');
    }
    HapticFeedback.lightImpact();

    if (currentPage < pages.length - 1) {
      setState(() {
        selectedOption = null; // Reset the selected option for the next page
        currentPage++;
      });
      if (pages[currentPage]["type"] != "info_message") {
        currentProgress++;
      }
      logOnboardingScreenView(widget.deviceId ?? "", widget.platform ?? "",
          widget.userIP ?? "", currentPage + 1);
    } else {
      // Complete onboarding logic
      print("Onboarding completed");
      logOnboardingCompleted(
          widget.deviceId ?? "", widget.platform ?? "", widget.userIP ?? "");
      SharedPreferences prefs = await SharedPreferences.getInstance();
      Map<String, dynamic> dataToSave = prepareDataToSave(prefs);
      await saveProfile(profileData: dataToSave);
      await prefs.setBool('appFirstLaunch', false);

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => MainPage()),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentData = pages[currentPage];
    final double progress = (currentProgress) / (pages.length - 11);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: currentData["type"] != "info_message"
            ? LayoutBuilder(
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
                        width: availableWidth * progress,
                        height: 16.0,
                        decoration: BoxDecoration(
                          color: Color.fromRGBO(255, 217, 0, 1),
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                      ),
                    ],
                  );
                },
              )
            : null,
        automaticallyImplyLeading: false,
      ),
      backgroundColor: AppColors.bg,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildPageContent(currentData),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ChicletAnimatedButton(
          onPressed: selectedOption != null ? _nextPage : null,
          buttonType: ChicletButtonTypes.roundedRectangle,
          height: 50,
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          buttonColor: selectedOption != null
              ? Color.fromRGBO(187, 160, 2, 1)
              : Colors.grey,
          backgroundColor: Color.fromRGBO(255, 217, 0, 1),
          child: Text(
            "CONTINUE",
            style: GoogleFonts.raleway(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  /// Main Page Renderer
  Widget _buildPageContent(Map<String, dynamic> pageData) {
    switch (pageData["type"]) {
      case "class_selection":
        pageData["options"] = classOptions.map((c) => c['name']).toList();
        return _buildPageTemplate1(pageData);
      case "source_of_information":
        return _buildPageTemplate1(pageData);
      case "goal_selection":
        return _buildPageTemplate1(pageData);
      case "daily_goal":
        return _buildPageTemplate2(pageData);
      case "learning_time":
        return _buildPageTemplate1(pageData);
      case "commit_to_learning":
        return _buildPageTemplate2(pageData);
      case "progress_reports":
        return _buildPageTemplate1(pageData);
      case "motivation":
        return _buildPageTemplate1(pageData);
      case "learning_preference":
        return _buildPageTemplate1(pageData);
      case "name_input":
        return _buildNameInputPage(pageData);
      case "challenges":
      case "startNewChapter":
      case "videoIssues":
      case "learnBestThrough":
      case "helpNeeded":
        return _buildPageTemplateMultiSelect(pageData);
      case "school_details":
        return SchoolSelectionWidget(
          onSelectionChanged: (state, city, school, schoolId) {
            setState(() {
              selectedOptions["state"] = state;
              selectedOptions["city"] = city;
              selectedOptions["school"] = school;
              selectedOptions["schoolId"] = schoolId;
              selectedOption = school;
            });
          },
        );

      case "info_message":
        return _buildInfoMessageTemplate(pageData);

      default:
        return _buildPageTemplate1(pageData);
    }
  }

  Widget _buildPageTemplateMultiSelect(Map<String, dynamic> pageData) {
    final pageType = pageData["type"];
    // Initialize selection state for this page if needed
    multiSelectStates[pageType] ??= <String>{};

    return Column(
      children: [
        // Mascot and Heading (reuse your code)
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (pageData["mascotImage"] != null)
              SizedBox(
                height: 120,
                width: 120,
                child: Lottie.asset(
                  pageData["mascotImage"],
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(width: 4),
            Flexible(
                child: BubbleBox(
                    shape: BubbleShapeBorder(
                        border: BubbleBoxBorder(
                          color: Colors.grey.shade700,
                          width: 3,
                        ),
                        radius: BorderRadius.circular(12),
                        position: const BubblePosition.center(0),
                        direction: BubbleDirection.left,
                        arrowHeight: 10),
                    backgroundColor: Color.fromRGBO(19, 31, 36, 1),
                    child: Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Stack(
                          children: [
                            Text(
                              pageData["heading"],
                              // textAlign: TextAlign.center,
                              style: GoogleFonts.raleway(
                                color: Colors.transparent,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            AnimatedTextKit(
                              key: ValueKey(pageData[
                                  "heading"]), // Unique key for each message
                              animatedTexts: [
                                TyperAnimatedText(
                                  pageData["heading"],
                                  textStyle: GoogleFonts.raleway(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  speed: const Duration(
                                      milliseconds: 20), // Typing speed
                                ),
                              ],
                              isRepeatingAnimation: false, // No looping
                              totalRepeatCount: 1, // Play once
                            ),
                          ],
                        ))))
          ],
        ),
        const SizedBox(height: 20),
        Expanded(
          child: _buildMultiOptions(pageData),
        ),
      ],
    );
  }

  Widget _buildMultiOptions(Map<String, dynamic> pageData) {
    final options = pageData["options"];
    final pageType = pageData["type"];
    if (options == null || options.isEmpty) return Container();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: options.map<Widget>((option) {
          final String label = option is String ? option : option;
          final isSelected =
              multiSelectStates[pageType]?.contains(label) ?? false;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: ChicletOutlinedAnimatedButton(
              onPressed: () {
                setState(() {
                  if (isSelected) {
                    multiSelectStates[pageType]?.remove(label);
                    if (multiSelectStates[pageType]?.isEmpty == true) {
                      selectedOption = null;
                    }
                  } else {
                    multiSelectStates[pageType]?.add(label);
                    selectedOption = label;
                  }
                  // If you want to save in selectedOptions as well:
                  selectedOptions[pageType] =
                      multiSelectStates[pageType]?.toList();
                });
              },
              width: double.infinity,

              // height: 50,
              borderWidth: 2,
              borderRadius: 12,
              borderColor: isSelected ? Colors.blue : Colors.grey[700]!,
              backgroundColor: Color.fromRGBO(19, 31, 36, 1),
              child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: 50),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        // Icon(
                        //   isSelected
                        //       ? Icons.check_box
                        //       : Icons.check_box_outline_blank,
                        //   color: isSelected ? Colors.blue : Colors.white,
                        // ),
                        // const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            label,
                            style: GoogleFonts.raleway(
                              color: isSelected ? Colors.blue : Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                            // Uncomment below if you want ellipsis instead of wrap:
                            // maxLines: 2,
                            // overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  )),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPageTemplate1(Map<String, dynamic> pageData) {
    return Column(
      children: [
        // Mascot and Heading (Chat Bubble)
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (pageData["mascotImage"] != null)
              SizedBox(
                height: 120,
                width: 120,
                child: Lottie.asset(
                  pageData["mascotImage"],
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(width: 4),
            Flexible(
                child: BubbleBox(
                    shape: BubbleShapeBorder(
                        border: BubbleBoxBorder(
                          color: Colors.grey.shade700,
                          width: 3,
                        ),
                        radius: BorderRadius.circular(12),
                        position: const BubblePosition.center(0),
                        direction: BubbleDirection.left,
                        arrowHeight: 10),
                    backgroundColor: Color.fromRGBO(19, 31, 36, 1),
                    child: Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Stack(
                          children: [
                            Text(
                              pageData["heading"],
                              // textAlign: TextAlign.center,
                              style: GoogleFonts.raleway(
                                color: Colors.transparent,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            AnimatedTextKit(
                              key: ValueKey(pageData[
                                  "heading"]), // Unique key for each message
                              animatedTexts: [
                                TyperAnimatedText(
                                  pageData["heading"],
                                  textStyle: GoogleFonts.raleway(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  speed: const Duration(
                                      milliseconds: 20), // Typing speed
                                ),
                              ],
                              isRepeatingAnimation: false, // No looping
                              totalRepeatCount: 1, // Play once
                            ),
                          ],
                        ))))
          ],
        ),
        const SizedBox(height: 20),
        Expanded(
          child: _buildOptions(pageData), // Options list in scroll view
        ),
      ],
    );
  }

  Widget _buildPageTemplate2(Map<String, dynamic> pageData) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Question
        Text(
          pageData["heading"],
          style: GoogleFonts.raleway(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.left,
        ),
        const SizedBox(height: 20),
        _buildOptionsForTemplate2(
          pageData, // Options list in scroll view
        ),
        if (selectedOption != null) ...[
          SizedBox(
            height: 60,
          ),
          Row(
            children: [
              if (pageData["mascotImage"] != null)
                SizedBox(
                  height: 150,
                  width: 150,
                  child: Lottie.asset(
                    pageData["mascotImage"],
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(width: 16),
              Flexible(
                  child: BubbleBox(
                      shape: BubbleShapeBorder(
                          border: BubbleBoxBorder(
                            color: Colors.grey.shade700,
                            width: 3,
                          ),
                          radius: BorderRadius.circular(12),
                          position: const BubblePosition.center(0),
                          direction: BubbleDirection.left,
                          arrowHeight: 10),
                      backgroundColor: Color.fromRGBO(19, 31, 36, 1),
                      child: Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Stack(
                            children: [
                              Text(
                                pageData["options"]?.firstWhere((opt) =>
                                        opt["label"] ==
                                        selectedOption)["description"] ??
                                    "",
                                style: GoogleFonts.raleway(
                                  color: Colors.transparent,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              AnimatedTextKit(
                                key: ValueKey(pageData["options"]?.firstWhere(
                                        (opt) =>
                                            opt["label"] ==
                                            selectedOption)["description"] ??
                                    ""), // Unique key for each message
                                animatedTexts: [
                                  TyperAnimatedText(
                                    pageData["options"]?.firstWhere((opt) =>
                                            opt["label"] ==
                                            selectedOption)["description"] ??
                                        "",
                                    textStyle: GoogleFonts.raleway(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    speed: const Duration(
                                        milliseconds: 20), // Typing speed
                                  ),
                                ],
                                isRepeatingAnimation: false, // No looping
                                totalRepeatCount: 1, // Play once
                              ),
                            ],
                          ))))
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildInfoMessageTemplate(Map<String, dynamic> pageData) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Center(
            child: BubbleBox(
                maxWidth: double.infinity,
                shape: BubbleShapeBorder(
                    border: BubbleBoxBorder(
                      color: Colors.grey.shade700,
                      width: 3,
                    ),
                    radius: BorderRadius.circular(12),
                    position: const BubblePosition.center(0),
                    direction: BubbleDirection.bottom,
                    arrowHeight: 10),
                backgroundColor: Color.fromRGBO(19, 31, 36, 1),
                child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Stack(
                      children: [
                        Text(
                            generateHeadingForInfoMessages(
                                pageData["heading"], pageData["headingType"]),
                            style: GoogleFonts.raleway(
                              color: Colors.transparent,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            )),
                        AnimatedTextKit(
                          key: ValueKey(pageData[
                              "heading"]), // Unique key for each message
                          animatedTexts: [
                            TyperAnimatedText(
                              generateHeadingForInfoMessages(
                                  pageData["heading"], pageData["headingType"]),
                              textStyle: GoogleFonts.raleway(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                              speed: const Duration(
                                  milliseconds: 20), // Typing speed
                            ),
                          ],
                          isRepeatingAnimation: false, // No looping
                          totalRepeatCount: 1, // Play once
                        ),
                      ],
                    )))),
        if (pageData["mascotImage"] != null)
          Transform.translate(
            offset: Offset(-8, -25), // Moves it up slightly
            child: SizedBox(
              height: 150,
              width: 150,
              child: Lottie.asset(
                pageData["mascotImage"],
                fit: BoxFit.cover,
              ),
            ),
          ),
      ],
    );
  }

  String generateHeadingForInfoMessages(String heading, String headingType) {
    setState(() {
      selectedOption = "info_message";
    });
    if ("class" == headingType) {
      return heading.replaceAll("{}", selectedOptions["class_selection"]);
    } else if ("goal" == headingType) {
      return heading.replaceAll("{}", selectedOptions["goal_selection"]);
    } else if ("learning_time" == headingType) {
      final option = selectedOptions["learning_time"];
      if ("Morning" == option) {
        return "Morning, bright and early! I’ll be up before the birds to make sure you start your day with some pawsome learning! 🌞😺";
      } else if ("Afternoon" == option) {
        return "Afternoon, nice choice! While the sun is shining, we’ll dive into learning and make it a purr-ductive day! 🌤️🐾";
      } else if ("Evening" == option) {
        return "Evening, huh? That’s usually my nap time, but no worries—I’ll wake up, stretch, and be ready to remind you for your lesson! 🌅😺";
      } else {
        return "Night owl, I see! Don’t worry, I’ll light up the learning path and keep you company with some purr-fect study vibes! 🌙😺";
      }
    } else if ("name" == headingType) {
      return heading.replaceAll("{}", selectedOptions["name_input"]);
    } else {
      return heading;
    }
  }

  Widget _buildNameInputPage(Map<String, dynamic> pageData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Heading
        Text(
          pageData["heading"],
          style: GoogleFonts.raleway(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),

        // Text Input Field
        TextField(
          controller: nameController,
          onChanged: (value) {
            setState(() {
              selectedOption =
                  value; // Update the selected option for validation
              _updateSelection("name_input", value); // Save in selectedOptions
            });
          },
          decoration: InputDecoration(
            hintText: "Enter your name",
            hintStyle: GoogleFonts.raleway(
              color: Colors.grey,
              fontSize: 16,
            ),
            filled: true,
            fillColor: Colors.grey[800],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          ),
          style: GoogleFonts.raleway(
            color: Colors.white,
            fontSize: 16,
          ),
        )
      ],
    );
  }

  Widget _buildOptions(Map<String, dynamic> pageData) {
    final options = pageData["options"];
    if (options == null || options.isEmpty) return Container();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: options.map<Widget>((option) {
          final String label =
              option is String ? option : option; // Handle string directly
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: ChicletOutlinedAnimatedButton(
              onPressed: () {
                setState(() {
                  selectedOption = label;
                  _updateSelection(pageData["type"], label);
                });
              },
              width: double.infinity,
              height: 50,
              borderWidth: 1,
              borderRadius: 12,
              borderColor: selectedOption == label
                  ? Colors.blue
                  : Colors.grey[700]!, // Change border on selection
              backgroundColor: Color.fromRGBO(19, 31, 36, 1),
              child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      label,
                      style: GoogleFonts.raleway(
                        color: selectedOption == label
                            ? Colors.blue
                            : Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOptionsForTemplate2(Map<String, dynamic> pageData) {
    final options = pageData["options"];
    if (options == null || options.isEmpty) return Container();
    if (selectedOption == null && options.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          selectedOption = options[0]["label"];
          _updateSelection(pageData["type"], options[0]["label"]);
        });
      });
    }
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: options.map<Widget>((option) {
          final String label = option["label"];

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: ChicletOutlinedAnimatedButton(
              onPressed: () {
                setState(() {
                  selectedOption = label;
                  _updateSelection(pageData["type"], label);
                });
              },
              width: double.infinity,
              height: 50,
              borderWidth: 1,
              borderRadius: 12,
              borderColor: selectedOption == label
                  ? Colors.blue
                  : Colors.grey[700]!, // Change border on selection
              backgroundColor: Color.fromRGBO(19, 31, 36, 1),
              child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.raleway(
                          color: selectedOption == label
                              ? Colors.blue
                              : Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        option["helperText"],
                        style: GoogleFonts.raleway(
                          color: selectedOption == label
                              ? Colors.blue
                              : Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    ],
                  )),
            ),
          );
        }).toList(),
      ),
    );
  }
}
