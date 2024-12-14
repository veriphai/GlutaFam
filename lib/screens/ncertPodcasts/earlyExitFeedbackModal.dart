import 'package:eureka_app/events/feedbackScreenEvents.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EarlyExitFeedbackModal extends StatefulWidget {
  final Function(List<String>) onSubmit;
  final Function() onclose;
  final String topicId;

  const EarlyExitFeedbackModal(
      {Key? key,
      required this.onSubmit,
      required this.onclose,
      required this.topicId})
      : super(key: key);

  @override
  _EarlyExitFeedbackModalState createState() => _EarlyExitFeedbackModalState();
}

class _EarlyExitFeedbackModalState extends State<EarlyExitFeedbackModal> {
  Set<String> selectedOptions = {};

  final List<String> feedbackOptions = [
    'Content was not interesting',
    'Audio was too long',
    'Did not understand the content',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _setCurrentScreen();
    logEarlyExitFeedbackScreenView(widget.topicId);
  }

  void toggleOption(String option) {
    setState(() {
      if (selectedOptions.contains(option)) {
        selectedOptions.remove(option);
        logEarlyExitFeedbackCheckboxClick(widget.topicId, option, "selected");
      } else {
        selectedOptions.add(option);
        logEarlyExitFeedbackCheckboxClick(widget.topicId, option, "unselected");
      }
    });
  }

  Future<void> _setCurrentScreen() async {
    await FirebaseAnalytics.instance.logScreenView(
        screenClass: 'EarlyExitFeedbackModal',
        screenName: "Early Exit Feedback Modal",
        parameters: {
          "topicId": widget.topicId,
        });
  }

  void recordTimeForLastAppearance() async {
    int epochTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('earlyExitModalShownTime', epochTime);
  }

  @override
  Widget build(BuildContext context) {
    recordTimeForLastAppearance();
    return AlertDialog(
      backgroundColor: Colors.black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(
        'Leaving So Early, Tell us why?',
        style: GoogleFonts.raleway(
            color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: feedbackOptions.map((option) {
            return CheckboxListTile(
              activeColor: Color.fromRGBO(255, 217, 0, 1),
              checkColor: Colors.black,
              title:
                  Text(option, style: GoogleFonts.raleway(color: Colors.white)),
              value: selectedOptions.contains(option),
              onChanged: (bool? value) {
                toggleOption(option);
              },
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            logEarlyExitFeedbackClose(widget.topicId);
            widget.onclose();
          },
          child: Text('Cancel', style: GoogleFonts.raleway(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: Color.fromRGBO(255, 217, 0, 1)),
          onPressed: () {
            logEarlyExitFeedbackSubmit(widget.topicId);
            widget.onSubmit(selectedOptions.toList());
          },
          child: Text('Submit',
              style: GoogleFonts.raleway(
                  color: Colors.black, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}
