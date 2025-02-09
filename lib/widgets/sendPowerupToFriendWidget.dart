import 'package:chiclet/chiclet.dart';
import 'package:eureka_app/utils/appHelperService.dart';
import 'package:eureka_app/utils/avatars.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bubble_box/bubble_box.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SendPowerupToFriendWidget extends StatefulWidget {
  final Map<String, dynamic> friendData;
  final Map<String, dynamic> userProfile;
  final String message;
  final int powerupCost;
  final Function(String, String) onPowerupSent;

  const SendPowerupToFriendWidget({
    Key? key,
    required this.friendData,
    required this.userProfile,
    required this.message,
    required this.powerupCost,
    required this.onPowerupSent,
  }) : super(key: key);

  @override
  _SendPowerupToFriendWidgetState createState() =>
      _SendPowerupToFriendWidgetState();
}

class _SendPowerupToFriendWidgetState extends State<SendPowerupToFriendWidget> {
  late int creditsAvailable;
  Future<void> fetchCredits() async {
    try {
      // final profileData = await getProfile();
      final prefs = await SharedPreferences.getInstance();
      final creditsFromCache = prefs.getInt("credits");

      setState(() {
        creditsAvailable = creditsFromCache ?? 0;
      });
    } catch (error) {
      print("Error fetching credits: $error");
    }
  }

  @override
  void initState() {
    super.initState();
    fetchCredits();
  }

  @override
  Widget build(BuildContext context) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Image.asset(
                'lib/assets/gemIcon.png',
                height: 24,
                width: 24,
              ),
              const SizedBox(width: 5),
              Text(
                "$creditsAvailable",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
                      Image.asset("lib/assets/xp-booster.png", height: 50),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Hi ${widget.friendData["name"]}, here's an XP Boost for you!",
                            style: GoogleFonts.raleway(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700),
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
          ChicletAnimatedButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
              int updatedCredits = creditsAvailable - widget.powerupCost;
              updateCredits(updatedCredits);
              widget.onPowerupSent(widget.friendData["id"], "xp-boost-1");
            },
            buttonType: ChicletButtonTypes.roundedRectangle,
            height: 50,
            width: double.infinity,
            buttonColor: Color.fromRGBO(187, 160, 2, 1),
            backgroundColor: Color.fromRGBO(255, 217, 0, 1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "SEND FOR",
                  style: GoogleFonts.raleway(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(
                  width: 10,
                ),
                Row(
                  children: [
                    Image.asset(
                      'lib/assets/gemIcon.png',
                      height: 24,
                      width: 24,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      "${widget.powerupCost}",
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
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
