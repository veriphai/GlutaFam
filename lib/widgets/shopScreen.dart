import 'package:carousel_slider/carousel_slider.dart';
import 'package:chiclet/chiclet.dart';
import 'package:eureka_app/utils/appHelperService.dart';
import 'package:eureka_app/utils/powerupService.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class ShopScreen extends StatefulWidget {
  final int gems;
  final Function(Map<String, dynamic>, int) onPowerUpPurchased;

  ShopScreen({Key? key, required this.gems, required this.onPowerUpPurchased})
      : super(key: key);
  @override
  _ShopScreenState createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final List<Map<String, dynamic>> trialPlans = [
    {
      "id": "plan-1",
      "name": "Super",
      "heading": "Supercharge your learning with AI Tutor",
      "subheading": "Do unlimited concepts with unlimited hearts",
      "image": "https://via.placeholder.com/150"
    },
    {
      "id": "plan-2",
      "name": "Basic",
      "heading": "Features for faster learning",
      "subheading": "Do unlimited concepts with unlimited hearts",
      "image": "https://via.placeholder.com/150"
    },
  ];

  final List<Map<String, dynamic>> powerups = [
    {
      "id": "xp-boost-1",
      "name": "XP Boost",
      "type": "XP_BOOST",
      "description": "Double your XP",
      "benefit": 2,
      "validity": 2,
      "image": "https://gluta.s3.ap-south-1.amazonaws.com/gems.jpg",
      "credits": 200
    },
    {
      "id": "xp-boost-2",
      "name": "XP Boost",
      "type": "XP_BOOST",
      "description": "Triple your XP",
      "benefit": 2,
      "validity": 15,
      "image": "https://gluta.s3.ap-south-1.amazonaws.com/gems.jpg",
      "credits": 300
    },
    {
      "id": "lifeline_boost_1",
      "name": "Unlimited Hearts",
      "type": "LIFELINE_BOOST",
      "description": "Unlimited hearts",
      "validity": 2,
      "image": "https://gluta.s3.ap-south-1.amazonaws.com/gems.jpg",
      "credits": 400
    },
    {
      "id": "lifeline_boost_2",
      "name": "Refill Hearts",
      "type": "LIFELINE_BOOST",
      "description": "Unlimited hearts",
      "validity": 1,
      "image": "https://gluta.s3.ap-south-1.amazonaws.com/gems.jpg",
      "credits": 300
    },
    {
      "id": "god_mode",
      "name": "God Mode",
      "type": "GOD_MODE",
      "description": "Triple your XP with unlimited hearts",
      "validity": 15,
      "image": "https://gluta.s3.ap-south-1.amazonaws.com/gems.jpg",
      "credits": 500
    },
  ];

  late PowerUpService powerUpService;
  late int creditsAvailable;

  @override
  void initState() {
    super.initState();
    powerUpService = PowerUpService();

    setState(() {
      creditsAvailable = widget.gems;
    });
    // Initialize lifelines count
  }

  void onPowerUpPurchased(Map<String, dynamic> powerup) async {
    await powerUpService.addPowerUp(powerup);
    int updatedCredits = creditsAvailable - (powerup["credits"] as int);
    updateCredits(updatedCredits);

    setState(() {
      creditsAvailable = updatedCredits;
    });
    widget.onPowerUpPurchased(powerup, updatedCredits);

    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("${powerup['name']} activated!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(19, 31, 36, 1),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 40),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  Text(
                    'Shop',
                    style: GoogleFonts.raleway(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      Image.asset(
                        'lib/assets/gemIcon.png',
                        height: 24,
                        width: 24,
                      ),
                      SizedBox(width: 5),
                      Text("$creditsAvailable",
                          style: TextStyle(color: Colors.white))
                    ],
                  )
                ],
              ),
            ),
            const Divider(
              color: Colors.grey,
              thickness: 1,
            ),
            const SizedBox(height: 20),
            CarouselSlider(
              options: CarouselOptions(
                  height: 250,
                  enlargeCenterPage: true,
                  autoPlay: true,
                  autoPlayInterval: const Duration(seconds: 60),
                  viewportFraction: 1.0),
              items: trialPlans.map((plan) {
                return Builder(
                  builder: (BuildContext context) {
                    return Container(
                      width: MediaQuery.of(context).size.width,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey, width: 1.0),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withOpacity(0.7),
                              Colors.transparent
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Expanded(
                                  child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    plan["heading"],
                                    style: GoogleFonts.raleway(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    plan["subheading"],
                                    style: GoogleFonts.raleway(
                                      color: Colors.grey[300],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              )),
                              Image.asset(
                                'lib/assets/gemIcon.png',
                                height: 100,
                                width: 100,
                              ),
                            ]),
                            SizedBox(
                              height: 20,
                            ),
                            ChicletAnimatedButton(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                              },
                              height: 40,
                              width: double.infinity,
                              buttonHeight: 4,
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              buttonColor: Color.fromRGBO(187, 160, 2, 1),
                              backgroundColor: Color.fromRGBO(255, 217, 0, 1),
                              child: Text(
                                "TRY 1 WEEK FOR FREE",
                                style: GoogleFonts.arOneSans(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 30),

            // Power-ups Section
            Text(
              "Power-ups",
              style: GoogleFonts.raleway(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: ListView.builder(
                itemCount: powerups.length,
                itemBuilder: (context, index) {
                  final powerup = powerups[index];
                  return GestureDetector(
                      onTap: () => _showPowerUpDetails(context, powerup),
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey),
                        ),
                        child: Row(
                          children: [
                            Image.network(
                              powerup["image"],
                              height: 60,
                              width: 60,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    powerup["name"],
                                    style: GoogleFonts.raleway(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    powerup["description"],
                                    style: GoogleFonts.raleway(
                                      color: Colors.grey[300],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                Image.asset(
                                  'lib/assets/gemIcon.png',
                                  height: 24,
                                  width: 24,
                                ),
                                SizedBox(width: 5),
                                Text("${powerup["credits"]}",
                                    style: TextStyle(color: Colors.white))
                              ],
                            )
                          ],
                        ),
                      ));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPowerUpDetails(BuildContext context, Map<String, dynamic> powerup) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.network(
                powerup["image"],
                height: 150,
                width: 150,
              ),
              const SizedBox(height: 20),
              Text(
                powerup["name"],
                style: GoogleFonts.raleway(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                powerup["description"],
                style: GoogleFonts.raleway(
                  color: Colors.grey[300],
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                powerup["validity"] == 1
                    ? "One-time use"
                    : "Validity: ${powerup["validity"]} minutes",
                style: GoogleFonts.raleway(
                  color: Colors.blue[300],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),
              ChicletAnimatedButton(
                onPressed: () {
                  onPowerUpPurchased(powerup);
                  Navigator.pop(context);
                },
                height: 50,
                width: double.infinity,
                buttonHeight: 4,
                buttonColor: Colors.amber,
                backgroundColor: Colors.yellow[600],
                child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "GET IT NOW",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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
                              "${powerup['credits']}",
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    )),
              ),
            ],
          ),
        );
      },
    );
  }
}
