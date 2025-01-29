import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:bubble_box/bubble_box.dart';
import 'package:chiclet/chiclet.dart';
import 'package:eureka_app/apis/saveProfile.dart';
import 'package:eureka_app/main.dart';
import 'package:eureka_app/utils/authTokenService.dart';
import 'package:eureka_app/widgets/schoolSelectionWidget.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

  @override
  void initState() {
    super.initState();
    // Initialize the controller with the selected option (if available)
    nameController = TextEditingController(text: selectedOptions["name_input"]);
  }

  @override
  void dispose() {
    nameController
        ?.dispose(); // Dispose of the controller when no longer needed
    super.dispose();
  }

  void _updateSelection(String type, dynamic value) {
    setState(() {
      selectedOptions[type] = value;
    });
  }

  final List<Map<String, dynamic>> pages = [
    {
      "pageNo": 2,
      "type": "info_message",
      "headingType": "generic",
      "heading": "Hi there! I am Haru!",
      "mascotImage": "lib/assets/streakIcon.png",
      "description": "",
    },
    {
      "pageNo": 2,
      "type": "info_message",
      "headingType": "generic",
      "heading":
          "My parents often used to say curiosity killed the cat but never told me the satisfaction brought it back",
      "mascotImage": "lib/assets/streakIcon.png",
      "description": "",
    },
    {
      "pageNo": 2,
      "type": "info_message",
      "headingType": "generic",
      "heading":
          "I am curious to learn more about you just few quick questions before we start your first lesson!",
      "mascotImage": "lib/assets/streakIcon.png",
      "description": "",
    },
    {
      "pageNo": 1,
      "type": "class_selection",
      "heading": "In which class are you?",
      "mascotImage": "lib/assets/streakIcon.png",
      "description": "",
      "options": [
        "Class 6",
        "Class 7",
        "Class 8",
        "Class 9",
        "Class 10",
        "Class 11 - Science",
        "Class 11 - Commerce",
        "Class 11 - Humanities",
        "Class 12 - Science",
        "Class 12 - Commerce",
        "Class 12 - Humanities"
      ]
    },
    {
      "pageNo": 2,
      "type": "info_message",
      "headingType": "class",
      "heading":
          "Get ready to join all the {} learners growing their conceptual understanding!",
      "mascotImage": "lib/assets/streakIcon.png",
      "description": "",
    },
    {
      "pageNo": 2,
      "type": "source_of_information",
      "heading": "How did you hear about Haruki Learning?",
      "mascotImage": "lib/assets/streakIcon.png",
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
      "heading": "What is your primary goal with Haruki Learning?",
      "mascotImage": "lib/assets/streakIcon.png",
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
      "mascotImage": "lib/assets/streakIcon.png",
      "description": "",
    },
    {
      "pageNo": 2,
      "type": "info_message",
      "headingType": "generic",
      "heading": "Let's set up a learning routine!",
      "mascotImage": "lib/assets/streakIcon.png",
      "description": "",
    },
    {
      "pageNo": 4,
      "type": "daily_goal",
      "heading": "What’s your daily learning goal?",
      "mascotImage": "lib/assets/streakIcon.png",
      "description":
          "With consistent achievement of goals, students are likely to improve drastically!",
      "options": [
        {
          "label": "10 min / day",
          "helperText": "Casual",
          "description": "1x likely to improve"
        },
        {
          "label": "15 min / day",
          "helperText": "Regular",
          "description": "2x likely to improve"
        },
        {
          "label": "20 min / day",
          "helperText": "Serious",
          "description": "3x likely to grade jump"
        },
        {
          "label": "30 min / day",
          "helperText": "Intense",
          "description": "5x likely to grade jump"
        }
      ]
    },
    {
      "pageNo": 5,
      "type": "learning_time",
      "heading": "What is your preferred learning time?",
      "mascotImage": "lib/assets/streakIcon.png",
      "description": "",
      "options": ["Morning", "Afternoon", "Evening", "Night"]
    },
    {
      "pageNo": 2,
      "type": "info_message",
      "headingType": "learning_time",
      "heading": "Let's set up a learning routine!",
      "mascotImage": "lib/assets/streakIcon.png",
      "description": "",
    },
    {
      "pageNo": 2,
      "type": "info_message",
      "headingType": "generic",
      "heading": "It can be hard to stay motivated...",
      "mascotImage": "lib/assets/streakIcon.png",
      "description": "",
    },
    {
      "pageNo": 2,
      "type": "info_message",
      "headingType": "generic",
      "heading": "so Haruki Learning is designed to be fun like a game!",
      "mascotImage": "lib/assets/streakIcon.png",
      "description": "",
    },
    {
      "pageNo": 6,
      "type": "commit_to_learning",
      "heading": "Commit to learning",
      "mascotImage": "lib/assets/streakIcon.png",
      "description": "",
      "options": [
        {
          "label": "7 day streak",
          "helperText": "Good",
          "description": "3x Multiplier"
        },
        {
          "label": "14 day streak",
          "helperText": "Great",
          "description": "5x Multiplier"
        },
        {
          "label": "30 day streak",
          "helperText": "Incredible",
          "description": "7x Multiplier"
        },
        {
          "label": "50 day streak",
          "helperText": "Unstoppable",
          "description": " 9x Multiplier"
        }
      ]
    },
    {
      "pageNo": 2,
      "type": "info_message",
      "headingType": "generic",
      "heading": "I think you and me are going to get along purr-fectly",
      "mascotImage": "lib/assets/streakIcon.png",
      "description": "",
    },
    {
      "pageNo": 2,
      "type": "info_message",
      "headingType": "generic",
      "heading":
          "I got so excited meeting you that I forgot to even ask about your name!",
      "mascotImage": "lib/assets/streakIcon.png",
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
      "pageNo": 11,
      "type": "school_details",
      "heading": "In which school do you study?",
      "mascotImage": "assets/images/mascot_school.png",
      "description": "",
      "inputs": [
        {
          "label": "State",
          "placeholder": "Enter your state",
          "inputType": "text"
        },
        {
          "label": "City",
          "placeholder": "Enter your city",
          "inputType": "text"
        },
        {
          "label": "School",
          "placeholder": "Enter your school",
          "inputType": "text"
        }
      ]
    },
    {
      "pageNo": 2,
      "type": "info_message",
      "headingType": "name",
      "heading": "Welcome, {}! Your profile is almost setup",
      "mascotImage": "lib/assets/streakIcon.png",
      "description": "",
    },
    {
      "pageNo": 2,
      "type": "info_message",
      "headingType": "generic",
      "heading":
          "Finally, a little bit about your learning preferences! So we can improve the app to support you better",
      "mascotImage": "lib/assets/streakIcon.png",
      "description": "",
    },
    {
      "pageNo": 7,
      "type": "progress_reports",
      "heading": "Would you like to receive progress reports?",
      "mascotImage": "lib/assets/streakIcon.png",
      "description": "",
      "options": ["Yes - Weekly", "Yes - Monthly", "No"]
    },
    {
      "pageNo": 8,
      "type": "motivation",
      "heading": "What motivates you to learn?",
      "mascotImage": "lib/assets/streakIcon.png",
      "description": "",
      "options": [
        "Rewards",
        "Parental encouragement",
        "Personal interest",
        "Peer pressure",
        "Career goals"
      ]
    },
    {
      "pageNo": 9,
      "type": "learning_preference",
      "heading": "Do you prefer competitive or individual learning?",
      "mascotImage": "lib/assets/streakIcon.png",
      "description": "",
      "options": ["Compete with others", "Learn at my own pace"]
    },
    {
      "pageNo": 2,
      "type": "info_message",
      "headingType": "generic",
      "heading":
          "Ahhh! I am so satisfied by getting to know you. Thanks for telling me everything about you!",
      "mascotImage": "lib/assets/streakIcon.png",
      "description": "",
    },
    {
      "pageNo": 2,
      "type": "info_message",
      "headingType": "generic",
      "heading":
          "Let's dive into learning, and remember haruki learning everyday keeps bad grades away!",
      "mascotImage": "lib/assets/streakIcon.png",
      "description": "",
    }
  ];

  AuthTokenService authTokenService = AuthTokenService();
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
      if (classSelection == "Class 6") {
        standard = 6;
      } else if (classSelection == "Class 7") {
        standard = 7;
      } else if (classSelection == "Class 8") {
        standard = 8;
      } else if (classSelection == "Class 9") {
        standard = 9;
      } else if (classSelection == "Class 10") {
        standard = 10;
      } else if (classSelection == "Class 11 - Science") {
        standard = 11;
        stream = "Science";
      } else if (classSelection == "Class 11 - Commerce") {
        standard = 11;
        stream = "Commerce";
      } else if (classSelection == "Class 11 - Humanities") {
        standard = 11;
        stream = "Humanities";
      } else if (classSelection == "Class 12 - Science") {
        standard = 12;
        stream = "Science";
      } else if (classSelection == "Class 12 - Commerce") {
        standard = 12;
        stream = "Commerce";
      } else if (classSelection == "Class 12 - Humanities") {
        standard = 12;
        stream = "Humanities";
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
      "fcmDeviceToken": fcmToken
    };

    return processedData;
  }

  void _nextPage() async {
    if (currentPage < pages.length - 1) {
      setState(() {
        selectedOption = null; // Reset the selected option for the next page
        currentPage++;
      });
      if (pages[currentPage]["type"] != "info_message") {
        currentProgress++;
      }
    } else {
      // Complete onboarding logic
      print("Onboarding completed");
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
    final double progress = (currentProgress) / (pages.length - 12);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromRGBO(19, 31, 36, 1),
        elevation: 0,
        title: currentData["type"] != "info_message"
            ? Expanded(
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
                          width: availableWidth * progress,
                          height: 16.0,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              )
            : null,
        automaticallyImplyLeading: false,
      ),
      backgroundColor: Color.fromRGBO(19, 31, 36, 1),
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

  Widget _buildPageTemplate1(Map<String, dynamic> pageData) {
    return Column(
      children: [
        // Mascot and Heading (Chat Bubble)
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (pageData["mascotImage"] != null)
              Image.asset(
                pageData["mascotImage"],
                height: 100,
                width: 100,
                fit: BoxFit.cover,
              ),
            const SizedBox(width: 4),
            BubbleBox(
                maxWidth: MediaQuery.of(context).size.width * 0.6,
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
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                    )))
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
      children: [
        // Question
        Text(
          pageData["heading"],
          style: GoogleFonts.raleway(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
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
                Image.asset(
                  pageData["mascotImage"],
                  height: 100,
                  width: 100,
                  fit: BoxFit.cover,
                ),
              const SizedBox(width: 16),
              BubbleBox(
                  maxWidth: MediaQuery.of(context).size.width * 0.6,
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
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                      )))
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
          Image.asset(
            pageData["mascotImage"],
            height: 100,
            width: 100,
            fit: BoxFit.cover,
          )
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
                          fontWeight: FontWeight.w700,
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
