import 'package:eureka_app/apis/logEventsApi.dart';
import 'package:eureka_app/screens/ncertPodcasts/chapterListingScreen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ClassSelectionPage extends StatefulWidget {
  @override
  _ClassSelection createState() => _ClassSelection();
}

class _ClassSelection extends State<ClassSelectionPage> {
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
    }
  ];

  @override
  void initState() {
    super.initState();
    // Log the event when this page is opened using the generic function
    logPageOpenEvent(
      screenName: "ClassSelectionPage",
      eventDetails: {"description": "User opened the class selection page"},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Background color
      body: SafeArea(
        child: Stack(
          children: [
            if (currentPageIndex < onboardingData.length)
              Positioned(
                top: -700,
                left: -200,
                right: -200,
                child: Image.asset(
                  'lib/assets/yellow_circle.png',
                  width: 1200,
                  height: 1200,
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
                      return _buildClassSelectionPage();
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

  Widget _buildClassSelectionPage() {
    return Column(
      children: [
        const SizedBox(height: 100),
        Center(
            child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            "Select Your Class",
            style: GoogleFonts.raleway(
              color: Colors.black,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
        )),
        const Spacer(flex: 2),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 20,
          runSpacing: 20,
          children: List.generate(5, (index) {
            int classNumber = index + 6;
            bool isSelected = selectedClass == classNumber;
            return GestureDetector(
              onTap: () async {
                setState(() {
                  selectedClass = classNumber;
                });

                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.setInt('selected_class', classNumber);
              },
              child: Container(
                width: 150,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Color.fromRGBO(255, 217, 0, 1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isSelected
                        ? Color.fromRGBO(213, 177, 0, 1)
                        : Colors.white,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    'Class $classNumber',
                    style: GoogleFonts.raleway(
                      color: isSelected ? Colors.black : Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        const Spacer(flex: 2),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 30.0),
      color: Colors.black,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton(
            onPressed: () {
              if (selectedClass == -1) {
                Fluttertoast.showToast(
                  msg: "Please select your class to proceed",
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.BOTTOM,
                  timeInSecForIosWeb: 1,
                  backgroundColor: Colors.red,
                  textColor: Colors.white,
                  fontSize: 16.0,
                );
              } else {
                classSelected();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              padding: EdgeInsets.zero,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.asset(
                  'lib/assets/hex.png',
                  width: 60,
                  height: 60,
                ),
                const Icon(
                  Icons.arrow_forward,
                  color: Colors.black,
                  size: 24,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> classSelected() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final secureStorage = FlutterSecureStorage();

    // Retrieve the saved class and auth token
    int? selectedClass = prefs.getInt('selected_class');
    String? authToken = await secureStorage.read(key: "authKey");

    // Check if authToken and selectedClass are valid
    if (authToken != null && selectedClass != null) {
      int currentTimestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      Map<String, dynamic> eventDetails = {"selectedClass": selectedClass};

      await logEvent(
        eventType: "buttonClick",
        screenName: "ClassSelectionPage",
        eventDetails: eventDetails,
        eventTime: currentTimestamp,
      );
      // Prepare the API URL (replace with your actual backend URL)
      final url = 'https://glutaclass.com:8080/gluta/fam/profile';

      try {
        // Make the POST request with the Authorization header
        final response = await http.post(
          Uri.parse(url),
          headers: {
            "Authorization":
                "Bearer $authToken", // Pass the token in the header
            "Content-Type": "application/json"
          },
          body: jsonEncode({
            "standard":
                selectedClass, // Include the selected class in the request body
          }),
        );

        if (response.statusCode == 200) {
          // If the API call is successful, navigate to the next screen
          print("Class selection saved successfully");
          await prefs.setBool('firstLaunch', false);
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => Chapterscreen()),
            (Route<dynamic> route) => false, // Removes all previous routes
          );
        } else {
          // Handle API errors
          print("Failed to save class selection: ${response.statusCode}");
        }
      } catch (e) {
        // Handle any errors during the HTTP request
        print("Error occurred while saving class selection: $e");
      }
    } else {
      print("Auth token or selected class is missing");
    }
  }
}
