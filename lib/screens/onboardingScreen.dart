import 'package:eureka_app/screens/profileCreationScreen.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Color.fromRGBO(59, 128, 185, 1),
      backgroundColor: Color(int.parse("0xffe8effd")),
      body: PageView(
        controller: _controller,
        children: <Widget>[
          _buildCarouselPage(
              "GlutaFam is a tool for parents",
              ["lib/assets/onboarding-1.png", "lib/assets/onboarding-1b.png"],
              "to teach life skills to their little ones"),
          _buildPage(
              "Use 10 minutes of GlutaFam to",
              "lib/assets/onboarding-2.png",
              "Never run out of interesting conversations"),
          _buildPage(
              "100+ activities on your fingertips to",
              "lib/assets/onboarding-3.png",
              "Develop deeper bond with your children"),
          _buildPage(
              "Essential mindful check-ins to",
              "lib/assets/onboarding-4.png",
              "Truly know your child, grow and learn together"),
        ],
      ),
      bottomSheet: _buildBottomNavigationBar(),
    );
  }

  Widget _buildCarouselPage(
      String title, List<String> imagePaths, String bottomText) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(height: 80),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 0, horizontal: 70),
          child: Text(title,
              textAlign: TextAlign.center,
              style: GoogleFonts.raleway(
                  fontSize: 26, fontWeight: FontWeight.bold)),
        ),
        SizedBox(height: 20),
        Container(
          margin: EdgeInsets.symmetric(horizontal: 10),
          child: CarouselSlider(
            options: CarouselOptions(
              autoPlay: true,
              autoPlayInterval: Duration(seconds: 3),
              autoPlayAnimationDuration: Duration(milliseconds: 800),
              viewportFraction: 1,
              height: 400, // Adjust based on your layout needs
            ),
            items: imagePaths
                .map((path) => ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(path,
                          fit: BoxFit.contain, width: double.infinity),
                    ))
                .toList(),
          ),
        ),
        SizedBox(height: 20),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 0, horizontal: 20),
          child: Text(bottomText,
              textAlign: TextAlign.center,
              style: GoogleFonts.raleway(
                  fontSize: 26, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildPage(String title, String imagePath, String bottomText) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          height: 80,
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 0, horizontal: 90),
          child: Text(title,
              textAlign: TextAlign.center,
              style: GoogleFonts.raleway(
                  fontSize: 26, fontWeight: FontWeight.bold)),
        ),
        SizedBox(
          height: 30,
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Image.asset(
            imagePath,
            fit: BoxFit.contain,
            width: double.infinity,
          ),
        ),
        SizedBox(
          height: 30,
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 0, horizontal: 20),
          child: Text(bottomText,
              textAlign: TextAlign.center,
              style: GoogleFonts.raleway(
                  fontSize: 26, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      color: Color(int.parse("0xffe8effd")),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SmoothPageIndicator(
            controller: _controller, // PageController
            count: 4, // Total number of pages
            effect: ExpandingDotsEffect(
              expansionFactor: 2,
              spacing: 8.0,
              radius: 4.0,
              dotWidth: 10.0,
              dotHeight: 10.0,
              dotColor: Colors.grey,
              activeDotColor: Colors.red,
            ), // Customizable effect
          ),
          SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              ElevatedButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ProfileCreationScreen()),
                ),
                style: ElevatedButton.styleFrom(
                    elevation: 0, backgroundColor: Colors.transparent),
                child: Text('Skip',
                    style: GoogleFonts.raleway(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.w400)),
              ),
              ElevatedButton(
                onPressed: () {
                  if (_controller.page!.toInt() == 3) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ProfileCreationScreen()),
                    );
                  } else {
                    _controller.nextPage(
                      duration: Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding:
                        EdgeInsets.symmetric(horizontal: 50, vertical: 10)),
                child: Text('Next',
                    style: GoogleFonts.raleway(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w400)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
