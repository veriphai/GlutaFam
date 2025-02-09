import 'package:chiclet/chiclet.dart';
import 'package:eureka_app/utils/avatars.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bubble_box/bubble_box.dart';

class NudgeWidget extends StatefulWidget {
  final Map<String, dynamic> friendData;
  final Map<String, dynamic> userProfile;
  final String message;
  final Function(String, String, String, String) onNudgeSent;

  const NudgeWidget({
    Key? key,
    required this.friendData,
    required this.userProfile,
    required this.message,
    required this.onNudgeSent,
  }) : super(key: key);

  @override
  _NudgeWidgetState createState() => _NudgeWidgetState();
}

class _NudgeWidgetState extends State<NudgeWidget> {
  int selectedNudgeIndex = 0; // Default selection

  final List<Map<String, String>> nudgeOptions = [
    {"text": "Let's finish strong!", "image": "lib/assets/strong_nudge.png"},
    {
      "text": "Don't make me show my claws!",
      "image": "lib/assets/bear_nudge.png"
    },
    {"text": "High five buddy!", "image": "lib/assets/high_five_nudge.png"},
    {"text": "Please don't make me cry!", "image": "lib/assets/cry_nudge.png"},
  ];

  void selectNudge(int index) {
    setState(() {
      selectedNudgeIndex = index; // Change selected index
    });
  }

  @override
  Widget build(BuildContext context) {
    Map<String, String> selectedNudge = nudgeOptions[selectedNudgeIndex];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color.fromRGBO(19, 31, 36, 1),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Center(
              child: Text(
            "Nudge ${widget.friendData['name']}",
            style: GoogleFonts.raleway(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          )),
          const SizedBox(height: 16),

          // Bubble Message & Avatar Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Bubble Box (Message)
              Expanded(
                  child: BubbleBox(
                maxWidth: MediaQuery.of(context).size.width * 0.6,
                shape: BubbleShapeBorder(
                  border: BubbleBoxBorder(
                    color: Colors.grey.shade700,
                    width: 3,
                  ),
                  radius: BorderRadius.circular(12),
                  position: const BubblePosition.center(0),
                  direction: BubbleDirection.right,
                  arrowHeight: 12,
                ),
                backgroundColor: Colors.grey[900],
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Image.asset(selectedNudge["image"]!, height: 50),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedNudge["text"]!,
                            style: GoogleFonts.raleway(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700),
                          ),
                          Text(
                            widget.message,
                            style: GoogleFonts.raleway(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          )
                        ],
                      )),
                    ],
                  ),
                ),
              )),

              // My Avatar
              ClipRRect(
                borderRadius: BorderRadius.circular(80),
                child: Container(
                  color: Colors.amber,
                  child: Image.asset(
                    getAvatar(widget.userProfile["avatar"])["imagePath"]!,
                    height: 80,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Nudge Options (Chiclet Buttons)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(nudgeOptions.length, (index) {
              return ChicletOutlinedAnimatedButton(
                onPressed: () => selectNudge(index),
                buttonType: ChicletButtonTypes.roundedRectangle,
                height: 80,
                borderColor: selectedNudgeIndex == index
                    ? Color.fromRGBO(
                        255, 217, 0, 1) // Highlight selected button
                    : Colors.grey,
                backgroundColor: Colors.black,
                borderWidth: 2.0,
                buttonHeight: 2,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(nudgeOptions[index]["image"]!, height: 50),
                  ],
                ),
              );
            }),
          ),

          const SizedBox(height: 24),

          // Send Nudge Button
          ChicletAnimatedButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
              widget.onNudgeSent(
                  widget.friendData["id"],
                  selectedNudge["text"]!,
                  selectedNudge["image"]!,
                  widget.message);
            },
            buttonType: ChicletButtonTypes.roundedRectangle,
            height: 50,
            width: double.infinity,
            buttonColor: Color.fromRGBO(187, 160, 2, 1),
            backgroundColor: Color.fromRGBO(255, 217, 0, 1),
            child: Text(
              "SEND NUDGE TO ${widget.friendData['name'].toUpperCase()}",
              style: GoogleFonts.raleway(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ChicletAnimatedButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            buttonType: ChicletButtonTypes.roundedRectangle,
            height: 50,
            width: double.infinity,
            buttonColor: Colors.transparent,
            backgroundColor: Colors.transparent,
            child: Text(
              "NO THANKS!",
              style: GoogleFonts.raleway(
                color: Color.fromRGBO(255, 217, 0, 1),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
