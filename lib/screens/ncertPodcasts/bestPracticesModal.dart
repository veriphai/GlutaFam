import 'package:eureka_app/events/audioPlayerScreenEvents.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BestPracticesModal extends StatefulWidget {
  final VoidCallback onDismiss;
  final VoidCallback listenInHindi;
  final String topicId;

  const BestPracticesModal(
      {Key? key,
      required this.onDismiss,
      required this.listenInHindi,
      required this.topicId})
      : super(key: key);

  @override
  _BestPracticesModalState createState() => _BestPracticesModalState();
}

class _BestPracticesModalState extends State<BestPracticesModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _opacityAnimation;

  String currentLanguage = 'En';

  void toggleLanguage() {
    setState(() {
      currentLanguage = currentLanguage == 'En' ? 'Hn' : 'En';
    });
  }

  @override
  void initState() {
    super.initState();
    _setCurrentScreen();
    logBestPracticesModalView(widget.topicId);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, -1.0),
      end: Offset(0, 0),
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _animationController.forward();
  }

  Future<void> _setCurrentScreen() async {
    await FirebaseAnalytics.instance.logScreenView(
        screenClass: 'BestPracticesModal',
        screenName: "Best Practices Modal",
        parameters: {"topicId": widget.topicId});
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Dimmed background
        GestureDetector(
          onTap: widget.onDismiss,
          child: Container(
            color: Colors.black.withOpacity(0.6),
          ),
        ),
        // Modal content with animations
        Center(
          child: SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _opacityAnimation,
              child: SingleChildScrollView(
                child: Container(
                  padding: EdgeInsets.all(0),
                  margin: EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        children: [
                          // Center-aligned title
                          Padding(
                            padding: const EdgeInsets.only(
                                top: 32.0), // Adjust vertical padding
                            child: Align(
                              alignment: Alignment.center,
                              child: Text(
                                "Best Practices While Listening",
                                style: GoogleFonts.raleway(
                                  color: Color.fromRGBO(255, 217, 0, 1),
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.none,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          // Close button at the top-right corner
                          Positioned(
                            top: 0,
                            right: 0,
                            child: IconButton(
                              icon: Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 20,
                              ),
                              onPressed: () {
                                logBestPracticesClosed(widget.topicId);
                                widget.onDismiss();
                              },
                              tooltip:
                                  "Close", // Optional tooltip for accessibility
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildPracticeItem(
                              title: "Find a Quiet Space",
                              description:
                                  "Choose a comfortable, distraction-free environment to focus on your studies.",
                            ),
                            _buildPracticeItem(
                              title: "Have Your Textbook Ready",
                              description:
                                  "Keep your NCERT textbook handy to read along with the audio. If you don't have it, use the 'View Book' button to access the content within the app.",
                            ),
                            _buildPracticeItem(
                              title: "Read Along with the Audio",
                              description:
                                  "Follow the text as the audio plays to enhance comprehension and retention.",
                            ),
                            _buildPracticeItem(
                              title: "Take Notes",
                              description:
                                  "Jot down important points, definitions, or any questions that come to mind.",
                            ),
                            _buildPracticeItem(
                              title: "Engage with Checkpoints",
                              description:
                                  "Use the regular checkpoints to summarize key concepts and assess your understanding through knowledge check questions.",
                            ),
                            _buildPracticeItem(
                              title: "Ask Questions Immediately",
                              description:
                                  "Use the 'Ask a Question' feature to get instant answers from the AI tutor for any doubts or clarifications.",
                            ),
                            // _buildPracticeItem(
                            //   title: "Stay Consistent",
                            //   description:
                            //       "Make it a habit to use the app regularly to reinforce learning and build a strong foundation.",
                            // ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              logBestPracticesStartLessonClick(
                                  widget.topicId, currentLanguage);
                              if (currentLanguage == "En") {
                                widget.onDismiss();
                              } else {
                                widget.listenInHindi();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color.fromRGBO(255, 217, 0, 1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 16), // Adjust padding
                            ),
                            icon: Icon(
                              Icons
                                  .play_circle_fill, // Choose an appropriate icon
                              color: Colors.black,
                            ),
                            label: Text(
                              "Start Lesson",
                              style: GoogleFonts.raleway(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          SizedBox(
                            width: 90, // Set your desired fixed width here
                            child: ElevatedButton.icon(
                              onPressed: () {
                                toggleLanguage();
                                logBestPracticesToggleLanguage(
                                    widget.topicId, currentLanguage);
                                // widget.listenInHindi();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                    color: Color.fromRGBO(255, 217, 0, 1),
                                    width: 2,
                                  ),
                                ),
                                padding: EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 16), // Adjust padding
                              ),
                              icon: Icon(
                                Icons.language,
                                color: Color.fromRGBO(255, 217, 0, 1),
                              ),
                              label: FittedBox(
                                // Ensures the text adjusts within the fixed width
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  currentLanguage,
                                  style: GoogleFonts.raleway(
                                    color: Color.fromRGBO(255, 217, 0, 1),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPracticeItem(
      {required String title, required String description}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.check_circle,
                  color: Color.fromRGBO(255, 217, 0, 1), size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.raleway(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.only(left: 30.0),
            child: Text(
              description,
              style: GoogleFonts.raleway(
                  color: Colors.white,
                  fontSize: 14,
                  decoration: TextDecoration.none,
                  fontWeight: FontWeight.normal),
            ),
          ),
        ],
      ),
    );
  }
}
