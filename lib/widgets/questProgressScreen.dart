import 'package:chiclet/chiclet.dart';
import 'package:eureka_app/main.dart';
import 'package:eureka_app/screens/homeScreen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class QuestProgressScreen extends StatelessWidget {
  final List<Map<String, dynamic>> updatedQuests;

  const QuestProgressScreen({Key? key, required this.updatedQuests})
      : super(key: key);

  String getImageAsset(String questType) {
    if (questType == "XP_COLLECT") {
      return "lib/assets/xpIcon.png";
    } else if (questType == "ACCURACY") {
      return "lib/assets/accuracyIcon.png";
    } else if (questType == "LESSON_COMPLETE") {
      return "lib/assets/gemIcon.png";
    } else {
      return "lib/assets/gemIcon.png";
    }
  }

  bool hasCompletedQuest() {
    return updatedQuests.any((questData) {
      final quest = questData["quest"];
      final newProgress = questData["newProgress"];
      final completionCriteria = quest["completionCriteria"];
      return newProgress >= completionCriteria;
    });
  }

  int countCompletedQuests() {
    return updatedQuests.where((questData) {
      final quest = questData["quest"];
      final newProgress = questData["newProgress"];
      final completionCriteria = quest["completionCriteria"];
      return newProgress >= completionCriteria;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    bool questCompleted = hasCompletedQuest();
    int completedQuestsCount = countCompletedQuests();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Spacer(),
          Text(
            completedQuestsCount > 0
                ? "$completedQuestsCount Daily Quests complete!"
                : "Daily Quests update!",
            style: GoogleFonts.arOneSans(
              color: Color.fromRGBO(255, 217, 0, 1),
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(
            height: 20,
          ),
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color.fromARGB(255, 91, 91, 91)),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.all(16),
              itemCount: updatedQuests.length,
              itemBuilder: (context, index) {
                final questData = updatedQuests[index];
                final quest = questData["quest"];
                final oldProgress = questData["oldProgress"];
                final newProgress = questData["newProgress"];
                final completionCriteria = quest["completionCriteria"];

                return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Image.asset(
                                getImageAsset(quest["questType"]),
                                height: 60,
                                width: 60,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      quest["name"],
                                      style: GoogleFonts.raleway(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    AnimatedProgressBar(
                                      oldProgress: oldProgress,
                                      newProgress: newProgress,
                                      completionCriteria: completionCriteria,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (index < updatedQuests.length - 1)
                          const Divider(
                            color: Colors.grey,
                            thickness: 1,
                            height: 16,
                          ),
                      ],
                    ));
              },
            ),
          ),
          Spacer(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ChicletAnimatedButton(
              onPressed: () {
                Navigator.pop(context);
                if (questCompleted) {
                  // Show rewards dialog
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => MainPage()),
                    (route) => false,
                  );
                  // showDialog(
                  //   context: context,
                  //   builder: (context) => AlertDialog(
                  //     title: Text(
                  //       "Rewards Claimed!",
                  //       style: GoogleFonts.raleway(
                  //           fontWeight: FontWeight.bold, fontSize: 18),
                  //     ),
                  //     content: Text(
                  //       "You have claimed rewards for completed quests!",
                  //       style: GoogleFonts.raleway(fontSize: 16),
                  //     ),
                  //     actions: [
                  //       TextButton(
                  //         onPressed: () {
                  //           Navigator.pop(context);
                  //         },
                  //         child: const Text("OK"),
                  //       ),
                  //     ],
                  //   ),
                  // );
                }
              },
              buttonType: ChicletButtonTypes.roundedRectangle,
              width: double.infinity,
              height: 50,
              buttonHeight: 4,
              padding: const EdgeInsets.all(8),
              buttonColor: const Color.fromARGB(255, 187, 160, 2),
              backgroundColor: const Color.fromARGB(255, 255, 217, 0),
              child: Text(
                questCompleted ? "CLAIM REWARDS" : "CONTINUE",
                style: GoogleFonts.raleway(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedProgressBar extends StatefulWidget {
  final int oldProgress;
  final int newProgress;
  final int completionCriteria;

  const AnimatedProgressBar({
    Key? key,
    required this.oldProgress,
    required this.newProgress,
    required this.completionCriteria,
  }) : super(key: key);

  @override
  _AnimatedProgressBarState createState() => _AnimatedProgressBarState();
}

class _AnimatedProgressBarState extends State<AnimatedProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _animation = Tween<double>(
      begin: widget.oldProgress / widget.completionCriteria,
      end: widget.newProgress / widget.completionCriteria,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return LinearProgressIndicator(
          value: _animation.value,
          backgroundColor: const Color.fromARGB(255, 91, 91, 91),
          borderRadius: BorderRadius.circular(8),
          minHeight: 20,
          valueColor: const AlwaysStoppedAnimation<Color>(
              Color.fromRGBO(255, 217, 0, 1)),
        );
      },
    );
  }
}
