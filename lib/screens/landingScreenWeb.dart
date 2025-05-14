import 'package:eureka_app/screens/loginScreen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:url_launcher/url_launcher.dart';

class LandingScreenWeb extends StatefulWidget {
  const LandingScreenWeb({super.key});

  @override
  _LandingScreenWebState createState() => _LandingScreenWebState();
}

class _LandingScreenWebState extends State<LandingScreenWeb> {
  final List<Map<String, String>> onboardingData = [
    {
      "topText": "Every student deserves",
      "secondTopText": "a personal tutor.",
      "imagePath": "lib/assets/on-1.png",
      "bottomText": "Our AI tutor teaches concepts",
      "bottomMidText": "step by step in real time.",
      "bottomBoldText": "Just like your favorite teacher."
    },
    {
      "topText": "Learning isn't one-size-fits-all.",
      "secondTopText": "So we personalize it.",
      "imagePath": "lib/assets/on-2.png",
      "bottomText": "We understand your interests",
      "bottomMidText": "and explain concepts accordingly.",
      "bottomBoldText": "Interest-led learning"
    },
    {
      "topText": "Quizzes? More like",
      "secondTopText": "quests.",
      "imagePath": "lib/assets/on-3.png",
      "bottomText": "Streaks, XP, quests –",
      "bottomMidText": "learning feels like a game.",
      "bottomBoldText": "Gamification that works"
    }
  ];

  final List<String> carouselImages = [
    'lib/assets/1.png',
    'lib/assets/3.png',
    'lib/assets/4.png',
    'lib/assets/6.png',
    'lib/assets/7.png',
    'lib/assets/8.png',
    'lib/assets/9.png',
  ];

  void _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(19, 31, 36, 1),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Top Bar
            Container(
              color: Color.fromRGBO(19, 31, 36, 1),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Logo and Name
                  Row(
                    children: [
                      Image.asset(
                        'lib/assets/tuto-logo.png',
                        height: 100,
                        width: 100,
                        fit: BoxFit.contain,
                      ),
                      // SizedBox(width: 20),
                      // Text(
                      //   "GlutaClass",
                      //   style: GoogleFonts.raleway(
                      //     fontSize: 40,
                      //     color: Colors.white,
                      //     fontWeight: FontWeight.bold,
                      //   ),
                      // ),
                    ],
                  ),
                  // Get Started Button
                  // Row(
                  //   children: [
                  //     ElevatedButton(
                  //       onPressed: () {
                  //         _launchURL(
                  //             'https://glutaclass.com/interactive-learning');
                  //       },
                  //       style: ElevatedButton.styleFrom(
                  //         backgroundColor:
                  //             const Color.fromRGBO(255, 217, 0, 0.2),
                  //         padding: const EdgeInsets.symmetric(
                  //             horizontal: 20, vertical: 20),
                  //         side: BorderSide(
                  //           color:
                  //               Color.fromRGBO(255, 217, 0, 1), // Border color
                  //           width: 1, // Border width
                  //         ),
                  //       ),
                  //       child: Text(
                  //         'View Simulations',
                  //         style: GoogleFonts.raleway(
                  //           color: Color.fromRGBO(255, 217, 0, 1),
                  //           fontSize: 16,
                  //           fontWeight: FontWeight.w400,
                  //         ),
                  //       ),
                  //     ),
                  //     SizedBox(
                  //       width: 20,
                  //     ),
                  //     ElevatedButton(
                  //       onPressed: () {
                  //         Navigator.push(
                  //           context,
                  //           MaterialPageRoute(
                  //               builder: (context) => LoginScreen()),
                  //         );
                  //       },
                  //       style: ElevatedButton.styleFrom(
                  //         backgroundColor: const Color.fromRGBO(255, 217, 0, 1),
                  //         padding: const EdgeInsets.symmetric(
                  //             horizontal: 20, vertical: 20),
                  //       ),
                  //       child: Text(
                  //         'Get Started',
                  //         style: GoogleFonts.raleway(
                  //           color: Colors.black,
                  //           fontSize: 16,
                  //           fontWeight: FontWeight.bold,
                  //         ),
                  //       ),
                  //     )
                  //   ],
                  // )
                ],
              ),
            ),
            // Header Content
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 0.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Image Carousel
                  Container(
                    // width: 300,
                    height: 600,
                    child: CarouselSlider(
                      options: CarouselOptions(
                        autoPlay: true,
                        enlargeCenterPage: true,
                        aspectRatio: 1.0,
                        viewportFraction: 1.0,
                      ),
                      items: carouselImages.map((imagePath) {
                        return Builder(
                          builder: (BuildContext context) {
                            return Image.asset(
                              imagePath,
                              fit: BoxFit.cover,
                            );
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Text Content
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Tuto",
                        textAlign: TextAlign.left,
                        style: GoogleFonts.raleway(
                          fontSize: 64,
                          color: Color.fromRGBO(255, 217, 0, 1),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "A Personal AI Tutor That Listens,",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.raleway(
                          fontSize: 36,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        "Understands, and Adapts to You",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.raleway(
                          fontSize: 36,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 50),
                      // Play Store and App Store Images
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          MouseRegion(
                              cursor: SystemMouseCursors
                                  .click, // Changes cursor to pointer (thumb)
                              child: GestureDetector(
                                onTap: () {
                                  _launchURL(
                                      'https://play.google.com/store/apps/details?id=com.gluta.glutafam'); // Replace with your Play Store link
                                },
                                child: Image.asset(
                                  'lib/assets/playStoreButton.png', // Path to your Play Store image
                                  width: 220,
                                  fit: BoxFit.contain,
                                ),
                              )),
                          const SizedBox(width: 20),
                          MouseRegion(
                              cursor: SystemMouseCursors
                                  .click, // Changes cursor to pointer (thumb)
                              child: GestureDetector(
                                onTap: () {
                                  _launchURL(
                                      'https://apps.apple.com/us/app/glutaclass-ai-tutor-for-ncert/id6736943726'); // Replace with your App Store link
                                },
                                child: Image.asset(
                                  'lib/assets/appStoreButton.png', // Path to your App Store image
                                  width: 220,
                                  fit: BoxFit.contain,
                                ),
                              )),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Onboarding Content
            // ListView.builder(
            //   shrinkWrap: true, // Ensures ListView takes only necessary space
            //   physics:
            //       NeverScrollableScrollPhysics(), // Prevents nested scrolling
            //   padding: const EdgeInsets.all(20),
            //   itemCount: onboardingData.length,
            //   itemBuilder: (context, index) {
            //     final item = onboardingData[index];
            //     if (index == 1) {
            //       return _buildRowV2(
            //         item['topText']!,
            //         item['secondTopText']!,
            //         item['imagePath']!,
            //         item['bottomText']!,
            //         item['bottomMidText']!,
            //         item['bottomBoldText']!,
            //       );
            //     } else {
            //       return _buildRow(
            //         item['topText']!,
            //         item['secondTopText']!,
            //         item['imagePath']!,
            //         item['bottomText']!,
            //         item['bottomMidText']!,
            //         item['bottomBoldText']!,
            //       );
            //     }
            //   },
            // ),
            // Padding(
            //   padding:
            //       const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30),
            //   child: ElevatedButton(
            //     onPressed: () {
            //       Navigator.push(
            //         context,
            //         MaterialPageRoute(builder: (context) => LoginScreen()),
            //       );
            //     },
            //     style: ElevatedButton.styleFrom(
            //       minimumSize: Size.fromHeight(50),
            //       backgroundColor: Color.fromRGBO(255, 217, 0, 1),
            //     ),
            //     child: Text(
            //       'Get Started',
            //       style: GoogleFonts.nunito(
            //         color: Colors.black,
            //         fontSize: 20,
            //         fontWeight: FontWeight.bold,
            //       ),
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(
    String topText,
    String secondTopText,
    String imagePath,
    String bottomText,
    String bottomMidText,
    String bottomBoldText,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 200.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Image Section
          Image.asset(
            imagePath,
            height: 500,
            width: 500,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 40),
          // Text Section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                topText,
                style: GoogleFonts.raleway(
                  fontSize: 30,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                secondTopText,
                style: GoogleFonts.raleway(
                  fontSize: 30,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                bottomText,
                style: GoogleFonts.raleway(
                  fontSize: 30,
                  color: Colors.grey[400],
                  fontWeight: FontWeight.normal,
                ),
              ),
              Text(
                bottomMidText,
                style: GoogleFonts.raleway(
                  fontSize: 30,
                  color: Colors.grey[400],
                  fontWeight: FontWeight.normal,
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRowV2(
    String topText,
    String secondTopText,
    String imagePath,
    String bottomText,
    String bottomMidText,
    String bottomBoldText,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 200.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Text Section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                topText,
                style: GoogleFonts.raleway(
                  fontSize: 30,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                secondTopText,
                style: GoogleFonts.raleway(
                  fontSize: 30,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                bottomText,
                style: GoogleFonts.raleway(
                  fontSize: 30,
                  color: Colors.grey[400],
                  fontWeight: FontWeight.normal,
                ),
              ),
              Text(
                bottomMidText,
                style: GoogleFonts.raleway(
                  fontSize: 30,
                  color: Colors.grey[400],
                  fontWeight: FontWeight.normal,
                ),
              )
            ],
          ),

          const SizedBox(width: 40),
          // Image Section
          Image.asset(
            imagePath,
            height: 500,
            width: 500,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }
}
