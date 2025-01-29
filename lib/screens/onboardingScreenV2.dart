import 'package:eureka_app/events/onboardingAndLoginEvents.dart';
import 'package:eureka_app/main.dart';
import 'package:eureka_app/screens/homeScreen.dart';
import 'package:eureka_app/screens/ncertPodcasts/chapterListingScreen.dart';
import 'package:eureka_app/utils/appHelperService.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnboardingScreenV2 extends StatefulWidget {
  @override
  _OnboardingScreenV2State createState() => _OnboardingScreenV2State();
}

class _OnboardingScreenV2State extends State<OnboardingScreenV2> {
  final PageController _controller = PageController();
  int currentPageIndex = 0;
  int selectedClass = -1;

  @override
  void initState() {
    super.initState();
    logOnboardingEvents(false);
    _setCurrentScreen();
  }

  Future<void> _setCurrentScreen() async {
    await FirebaseAnalytics.instance.logScreenView(
        screenClass: 'OnboardingScreen', screenName: "Onboarding Screen");
  }

  void logOnboardingEvents(bool buttonClick) async {
    Map<String, String> deviceDetails = await getDeviceDetails();
    String deviceId = deviceDetails['deviceId'] ?? "Unknown";
    String platform = deviceDetails['platform'] ?? "Unknown";
    String userIP = await getUserIP();
    if (buttonClick) {
      logNextButtonClick(deviceId, platform, userIP, currentPageIndex);
    } else {
      logOnboardingScreenView(deviceId, platform, userIP, currentPageIndex);
    }
  }

  final List<Map<String, String>> onboardingData = [
    {
      "topText": "Reading NCERT is now",
      "secondTopText": "exciting.",
      "imagePath": "lib/assets/on-1.png",
      "bottomText": "Interactive audio guides",
      "bottomMidText": "explain as you read.",
      "bottomBoldText": "audio lessons"
    },
    {
      "topText": "Have a doubt? Ask our AI",
      "secondTopText": "tutor anytime.",
      "imagePath": "lib/assets/on-2.png",
      "bottomText": "Instant answers, just like",
      "bottomMidText": "a real teacher.",
      "bottomBoldText": "AI tutor-led simulations"
    },
    {
      "topText": "Revise effectively with AI",
      "secondTopText": "quizzes.",
      "imagePath": "lib/assets/on-3.png",
      "bottomText": "Answer aloud and get",
      "bottomMidText": "immediate feedback.",
      "bottomBoldText": "CER framework"
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Background color
      body: SafeArea(
        child: Stack(
          children: [
            // Top Yellow Circle Image (For Onboarding Pages Only)
            if (currentPageIndex < onboardingData.length)
              Positioned(
                top: -520, // Adjust as needed
                left: -200, // Adjust as needed
                right: -200, // Adjust as needed
                child: Image.asset(
                  'lib/assets/yellow_circle.png', // Replace with your image path
                  width: 1000, // Adjust the size as needed
                  height: 1200, // Adjust the size as needed
                ),
              ),
            Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    onPageChanged: (index) {
                      setState(() {
                        currentPageIndex = index;
                      });
                      logOnboardingEvents(false);
                    },
                    itemCount: onboardingData.length,
                    itemBuilder: (context, index) {
                      // For regular onboarding screens
                      if (index < onboardingData.length) {
                        return _buildPage(
                          onboardingData[index]['topText']!,
                          onboardingData[index]['imagePath']!,
                          onboardingData[index]['bottomText']!,
                          onboardingData[index]['bottomBoldText']!,
                          onboardingData[index]['secondTopText']!,
                          onboardingData[index]['bottomMidText']!,
                        );
                      }
                      // else {
                      //   // For class selection page
                      //   return _buildClassSelectionPage();
                      // }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomSheet: _buildBottomNavigationBar(),
    );
  }

  Widget _buildPage(String topText, String imagePath, String bottomText,
      String bottomBoldText, String secondTopText, String bottomMidText) {
    return Column(
      children: [
        const Spacer(flex: 1), // Spacer before the top text
        const SizedBox(height: 20),
        // Top Text
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Text(
            topText,
            style: GoogleFonts.raleway(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Text(
            secondTopText,
            style: GoogleFonts.raleway(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        // Center Image (Character image)
        Center(
          child: Image.asset(
            imagePath, // Replace with your image
            width: double.infinity,
            // height: 350,
          ),
        ),
        const SizedBox(height: 20),
        // Bottom Text
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            bottomText,
            style: GoogleFonts.raleway(
                color: Colors.white, fontSize: 25, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            bottomMidText,
            style: GoogleFonts.raleway(
                color: Colors.white, fontSize: 25, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
        ),
        // Padding(
        //   padding: const EdgeInsets.symmetric(horizontal: 20.0),
        //   child: Text(
        //     bottomBoldText,
        //     style: const GoogleFonts.raleway(
        //         color: Colors.white, fontSize: 25, fontWeight: FontWeight.bold),
        //     textAlign: TextAlign.center,
        //   ),
        // ),
        const Spacer(flex: 2),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 30.0),
      color: Colors.black,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Smooth Page Indicator (Progress Bar on the left)
          SmoothPageIndicator(
            controller: _controller,
            count: onboardingData.length,
            // Adjusted count to include class selection page
            effect: const ExpandingDotsEffect(
              activeDotColor: Color.fromRGBO(255, 217, 0, 1),
              dotColor: Colors.white,
              expansionFactor: 2,
              dotHeight: 8,
              dotWidth: 20,
            ),
          ),
          // Next Button (on the right)
          ElevatedButton(
            onPressed: () {
              if (currentPageIndex == onboardingData.length - 1) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => MainPage()),
                  (Route<dynamic> route) => false,
                );
                // Go to next action or final action when class selection is done
              } else {
                _controller.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
                logOnboardingEvents(true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              padding:
                  EdgeInsets.zero, // Remove padding to fit the image exactly
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Hexagon image
                Image.asset(
                  'lib/assets/hex.png', // Your hexagon image path
                  width: 60, // Adjust size as needed
                  height: 60, // Adjust size as needed
                ),
                // Arrow icon on top of the hexagon
                const Icon(
                  Icons.arrow_forward,
                  color: Colors.black, // Arrow color
                  size: 24, // Adjust arrow size
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
