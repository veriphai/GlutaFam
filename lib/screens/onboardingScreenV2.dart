import 'package:eureka_app/screens/signupScreen.dart';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreenV2 extends StatefulWidget {
  @override
  _OnboardingScreenV2State createState() => _OnboardingScreenV2State();
}

class _OnboardingScreenV2State extends State<OnboardingScreenV2> {
  final PageController _controller = PageController();
  int currentPageIndex = 0;
  int selectedClass = -1;

  // Define your onboarding data
  final List<Map<String, String>> onboardingData = [
    {
      "topText": "Learn & revise anytime,",
      "secondTopText": "anywhere",
      "imagePath": "lib/assets/on-1.png",
      "bottomText": "Replace boring books with",
      "bottomMidText": "engaging Interest-Led",
      "bottomBoldText": "audio lessons"
    },
    {
      "topText": "Get hands-on understanding ",
      "secondTopText": "of complex concepts",
      "imagePath": "lib/assets/on-2.png",
      "bottomText": "Perform experiments &",
      "bottomMidText": "activities with",
      "bottomBoldText": "AI tutor-led simulations"
    },
    {
      "topText": "No more rote memorization ",
      "secondTopText": "of Q&As",
      "imagePath": "lib/assets/on-3.png",
      "bottomText": "Improve critical reasoning ",
      "bottomMidText": "and build cases using our",
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
            style: const TextStyle(
              color: Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Text(
            secondTopText,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.bold,
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
            style: const TextStyle(
                color: Colors.white, fontSize: 28, fontWeight: FontWeight.w300),
            textAlign: TextAlign.center,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            bottomMidText,
            style: const TextStyle(
                color: Colors.white, fontSize: 28, fontWeight: FontWeight.w300),
            textAlign: TextAlign.center,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            bottomBoldText,
            style: const TextStyle(
                color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
        const Spacer(flex: 2),
      ],
    );
  }

  // This method builds the class selection page
  // Widget _buildClassSelectionPage() {
  //   return Stack(
  //     children: [
  //       // Background Circle for Class Selection
  //       Positioned(
  //         top: -700, // Adjusted top value for class selection page
  //         left: -200, // Adjusted left value for class selection page
  //         right: -200, // Adjusted right value for class selection page
  //         child: Image.asset(
  //           'lib/assets/yellow_circle.png', // Same circle image, different positioning
  //           width: 1200, // Adjust width as needed
  //           height: 1200, // Adjust height as needed
  //         ),
  //       ),
  //       Column(
  //         children: [
  //           const SizedBox(height: 100),
  //           // Top Text
  //           Center(
  //               child: const Padding(
  //             padding: EdgeInsets.symmetric(horizontal: 20.0),
  //             child: Text(
  //               "Select Your Class",
  //               style: TextStyle(
  //                 color: Colors.black,
  //                 fontSize: 28,
  //                 fontWeight: FontWeight.bold,
  //               ),
  //               textAlign: TextAlign.center,
  //             ),
  //           )),
  //           const Spacer(flex: 2),
  //           // Class Selection Buttons
  //           Wrap(
  //             alignment: WrapAlignment.center,
  //             spacing: 20,
  //             runSpacing: 20,
  //             children: List.generate(8, (index) {
  //               int classNumber = index + 5;
  //               bool isSelected = selectedClass == classNumber;
  //               return GestureDetector(
  //                 onTap: () async {
  //                   setState(() {
  //                     selectedClass = classNumber;
  //                   });

  //                   // Save the selected class to shared preferences
  //                   SharedPreferences prefs =
  //                       await SharedPreferences.getInstance();
  //                   await prefs.setInt('selected_class', classNumber);
  //                 },
  //                 child: Container(
  //                   width: 150, // Fixed width for all buttons
  //                   padding: const EdgeInsets.symmetric(
  //                     vertical: 12, // Adjust the vertical padding as needed
  //                   ),
  //                   decoration: BoxDecoration(
  //                     color: isSelected
  //                         ? Color.fromRGBO(255, 217, 0, 1)
  //                         : Colors.transparent,
  //                     borderRadius: BorderRadius.circular(4),
  //                     border: Border.all(
  //                       color: isSelected
  //                           ? Color.fromRGBO(213, 177, 0, 1)
  //                           : Colors.white,
  //                       width: 2,
  //                     ),
  //                   ),
  //                   child: Center(
  //                     child: Text(
  //                       'Class $classNumber',
  //                       style: TextStyle(
  //                         color: isSelected ? Colors.black : Colors.white,
  //                         fontSize: 22,
  //                         fontWeight: FontWeight.bold,
  //                       ),
  //                     ),
  //                   ),
  //                 ),
  //               );
  //             }),
  //           ),
  //           const Spacer(flex: 2),
  //         ],
  //       ),
  //     ],
  //   );
  // }

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
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Signupscreen()),
                );
                // Go to next action or final action when class selection is done
              } else {
                _controller.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
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
          ),
          // ElevatedButton(
          //   onPressed: () {
          //     if (currentPageIndex == onboardingData.length - 1) {
          //       Navigator.push(
          //         context,
          //         MaterialPageRoute(builder: (context) => Signupscreen()),
          //       );
          //     } else {
          //       _controller.nextPage(
          //         duration: const Duration(milliseconds: 300),
          //         curve: Curves.easeInOut,
          //       );
          //     }
          //   },
          //   style: ElevatedButton.styleFrom(
          //     backgroundColor: Color.fromRGBO(255, 217, 0, 1),
          //     shape: const CircleBorder(),
          //     padding: const EdgeInsets.all(16),
          //   ),
          //   child: const Icon(
          //     Icons.arrow_forward,
          //     color: Colors.black,
          //   ),
          // ),
        ],
      ),
    );
  }
}
