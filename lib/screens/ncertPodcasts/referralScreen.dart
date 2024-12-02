import 'package:eureka_app/apis/getProfile.dart';
import 'package:eureka_app/screens/ncertPodcasts/giftScreen.dart';
import 'package:eureka_app/utils/generateReferralLink.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({Key? key}) : super(key: key);

  @override
  _ReferralScreenState createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  int totalReferrals = 0;
  int joinedReferrals = 0;
  String referralCode = "";
  String redeemedGiftId = "";

  @override
  void initState() {
    super.initState();
    _fetchUserProfileAndReferralCode();
  }

  Future<void> _fetchUserProfileAndReferralCode() async {
    try {
      // Fetch the user profile
      Map<String, dynamic> profile = await fetchUserProfile();

      setState(() {
        referralCode = profile['referralCode'] ?? ""; // Extract referral code
        totalReferrals = profile['totalReferralCount'] ?? 0; // Example field
        joinedReferrals = profile['referralConverted'] ?? 0; // Example field
        redeemedGiftId = profile['redeemedGiftId'] ?? "";
      });
    } catch (e) {
      print("Error fetching user profile: $e");
    }
  }

  void shareReferralLink() async {
    if (referralCode.isNotEmpty) {
      String referralLink = await generateReferralLink(referralCode);

      Share.share(
        'Join me on GlutaClass! Use my referral link: $referralLink',
        subject: 'Your GlutaClass Referral Link',
      );
    } else {
      print("Referral code is not available.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Invite Friends",
          style: GoogleFonts.raleway(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 30),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                "lib/assets/glutaclassLogo.png",
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 20),

            Text(
              "Earn exciting rewards by getting your friends on GlutaClass!",
              style: GoogleFonts.raleway(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            // Refer Button
            ElevatedButton(
              onPressed: shareReferralLink,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromRGBO(255, 217, 0, 1),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Invite Your Friends",
                    style: GoogleFonts.raleway(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8), // Spacing between text and icon
                  const Icon(
                    Icons.share, // Icon for sharing
                    color: Colors.black,
                    size: 20,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Text(
              "How it works?",
              style: GoogleFonts.raleway(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            // Pointers
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPointer("Share the link with your friends.", "1"),
                const SizedBox(height: 15),
                _buildPointer(
                    "Your referral counts when they join the GlutaClass family.",
                    "2"),
                const SizedBox(height: 15),
                _buildPointer(
                    "Invite 10 friends and unlock exciting rewards!", "3"),
              ],
            ),
            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        // GiftScreen(joinedReferrals: joinedReferrals),
                        GiftScreen(
                      joinedReferrals: 10,
                      redeemedGiftId: redeemedGiftId,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromRGBO(255, 217, 0, 1),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Redeem Gift",
                    style: GoogleFonts.raleway(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                ],
              ),
            ),
            SizedBox(
              height: 10,
            ),
            Text(
              "$joinedReferrals/10 referred",
              style: GoogleFonts.raleway(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPointer(String text, String number) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
                color: const Color.fromRGBO(255, 217, 0, 1), width: 2),
          ),
          child: Center(
            child: Text(
              number,
              style: GoogleFonts.arOneSans(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.raleway(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }
}
