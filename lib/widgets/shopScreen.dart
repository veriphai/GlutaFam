import 'package:cached_network_image/cached_network_image.dart';
// import 'package:carousel_slider/carousel_slider.dart';
import 'package:chiclet/chiclet.dart';
import 'package:eureka_app/apis/fetchPowerups.dart';
import 'package:eureka_app/apis/markPowerupUsed.dart';
import 'package:eureka_app/newEvents/shopScreenEvents.dart';
import 'package:eureka_app/utils/appHelperService.dart';
import 'package:eureka_app/utils/powerupService.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

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

  late List<Map<String, dynamic>> powerups;
  late List<Map<String, dynamic>> userAvailablePowerups;

  late PowerUpService powerUpService;
  late int creditsAvailable;
  bool isLoading = true;

  Future<void> getPowerups() async {
    try {
      final data = await fetchPowerups();

      setState(() {
        userAvailablePowerups =
            List<Map<String, dynamic>>.from(data["userPowerups"]);
        powerups = List<Map<String, dynamic>>.from(data["allPowerups"]);
        isLoading = false;
      });
    } catch (error) {
      print("Error fetching powerups: $error");
    }
  }

  @override
  void initState() {
    super.initState();
    logShopScreenView();
    powerUpService = PowerUpService();
    getPowerups();

    setState(() {
      creditsAvailable = widget.gems;
    });
    // Initialize lifelines count
  }

  void onPowerUpPurchased(Map<String, dynamic> powerup,
      {bool alreadyBought = false}) async {
    await powerUpService.addPowerUp(powerup);
    int updatedCredits = creditsAvailable;
    if (!alreadyBought) {
      logPowerupPurchased(powerup['id']);
      updatedCredits = creditsAvailable - (powerup["credits"] as int);
      updateCredits(updatedCredits);

      setState(() {
        creditsAvailable = updatedCredits;
      });
    }
    if (alreadyBought) {
      await markPowerupUsed(powerupId: powerup["id"]);
      await getPowerups();
    }
    logPowerupApplied(powerup['id']);

    widget.onPowerUpPurchased(powerup, updatedCredits);

    // Show confirmation
    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(content: Text("${powerup['name']} activated!")),
    // );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(19, 31, 36, 1),
      body: isLoading
          ? Center(
              child: Shimmer.fromColors(
                baseColor: Colors.grey[700]!,
                highlightColor: Colors.grey[300]!,
                child: Text(
                  'Loading...',
                  style: TextStyle(fontSize: 24),
                ),
              ),
            )
          : Padding(
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
                  // CarouselSlider(
                  //   options: CarouselOptions(
                  //       height: 250,
                  //       enlargeCenterPage: true,
                  //       autoPlay: true,
                  //       autoPlayInterval: const Duration(seconds: 60),
                  //       viewportFraction: 1.0),
                  //   items: trialPlans.map((plan) {
                  //     return Builder(
                  //       builder: (BuildContext context) {
                  //         return Container(
                  //           width: MediaQuery.of(context).size.width,
                  //           decoration: BoxDecoration(
                  //             borderRadius: BorderRadius.circular(12),
                  //             border:
                  //                 Border.all(color: Colors.grey, width: 1.0),
                  //           ),
                  //           child: Container(
                  //             decoration: BoxDecoration(
                  //               borderRadius: BorderRadius.circular(12),
                  //               gradient: LinearGradient(
                  //                 colors: [
                  //                   Colors.black.withOpacity(0.7),
                  //                   Colors.transparent
                  //                 ],
                  //                 begin: Alignment.bottomCenter,
                  //                 end: Alignment.topCenter,
                  //               ),
                  //             ),
                  //             padding: const EdgeInsets.all(16),
                  //             child: Column(
                  //               mainAxisAlignment: MainAxisAlignment.center,
                  //               crossAxisAlignment: CrossAxisAlignment.start,
                  //               children: [
                  //                 Row(children: [
                  //                   Expanded(
                  //                       child: Column(
                  //                     crossAxisAlignment:
                  //                         CrossAxisAlignment.start,
                  //                     children: [
                  //                       Text(
                  //                         plan["heading"],
                  //                         style: GoogleFonts.raleway(
                  //                           color: Colors.white,
                  //                           fontSize: 18,
                  //                           fontWeight: FontWeight.bold,
                  //                         ),
                  //                       ),
                  //                       const SizedBox(height: 8),
                  //                       Text(
                  //                         plan["subheading"],
                  //                         style: GoogleFonts.raleway(
                  //                           color: Colors.grey[300],
                  //                           fontSize: 14,
                  //                         ),
                  //                       ),
                  //                     ],
                  //                   )),
                  //                   Image.asset(
                  //                     'lib/assets/gemIcon.png',
                  //                     height: 100,
                  //                     width: 100,
                  //                   ),
                  //                 ]),
                  //                 SizedBox(
                  //                   height: 20,
                  //                 ),
                  //                 ChicletAnimatedButton(
                  //                   onPressed: () {
                  //                     HapticFeedback.lightImpact();
                  //                   },
                  //                   height: 40,
                  //                   width: double.infinity,
                  //                   buttonHeight: 4,
                  //                   padding:
                  //                       EdgeInsets.symmetric(horizontal: 20),
                  //                   buttonColor: Color.fromRGBO(187, 160, 2, 1),
                  //                   backgroundColor:
                  //                       Color.fromRGBO(255, 217, 0, 1),
                  //                   child: Text(
                  //                     "TRY 1 WEEK FOR FREE",
                  //                     style: GoogleFonts.arOneSans(
                  //                       color: Colors.black,
                  //                       fontSize: 16,
                  //                       fontWeight: FontWeight.w700,
                  //                     ),
                  //                   ),
                  //                 )
                  //               ],
                  //             ),
                  //           ),
                  //         );
                  //       },
                  //     );
                  //   }).toList(),
                  // ),

                  // const SizedBox(height: 30),

                  if (userAvailablePowerups.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Your Boosters",
                          style: GoogleFonts.raleway(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        buildAvailablePowerups(userAvailablePowerups),
                        const SizedBox(height: 20),
                      ],
                    ),

                  // Power-ups Section
                  Text(
                    "Boost Your Learning",
                    style: GoogleFonts.raleway(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  buildPowerupTiles(powerups)
                ],
              ),
            ),
    );
  }

  Widget buildAvailablePowerups(List<Map<String, dynamic>> powerups) {
    return SizedBox(
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.7,
        ),
        itemCount: powerups.length,
        shrinkWrap: true,
        itemBuilder: (context, index) {
          final powerup = powerups[index];
          return GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                _showPowerUpDetails(context, powerup, available: true);
              },
              child: Container(
                padding: const EdgeInsets.all(0.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CachedNetworkImage(
                      imageUrl: powerup["image"],
                      height: 80,
                      width: 80,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      powerup["name"],
                      style: GoogleFonts.raleway(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${powerup["count"]} available",
                      style: GoogleFonts.raleway(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ));
        },
      ),
    );
  }

  Widget buildPowerupTiles(List<Map<String, dynamic>> powerups) {
    return Expanded(
      child: ListView.builder(
        itemCount: powerups.length,
        itemBuilder: (context, index) {
          final powerup = powerups[index];
          return GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                _showPowerUpDetails(context, powerup);
              },
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey),
                ),
                child: Row(
                  children: [
                    CachedNetworkImage(
                      imageUrl: powerup["image"],
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
    );
  }

  void _showPowerUpDetails(BuildContext context, Map<String, dynamic> powerup,
      {bool available = false}) {
    logPowerupClicked(powerup['id']);
    bool purchaseDisabled =
        available ? false : creditsAvailable < powerup["credits"];
    bool isPurchased = false;
    showModalBottomSheet(
      context: context,
      backgroundColor: Color.fromRGBO(19, 31, 36, 1),
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CachedNetworkImage(
                    imageUrl: powerup["image"],
                    height: 150,
                    width: 150,
                  ),
                  const SizedBox(height: 20),

                  // Show Power-up Name
                  Text(
                    powerup["name"],
                    style: GoogleFonts.raleway(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Show different UI based on purchase status
                  if (!isPurchased) ...[
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

                    // Purchase Button
                    ChicletAnimatedButton(
                      onPressed: purchaseDisabled
                          ? null
                          : () async {
                              HapticFeedback.lightImpact();
                              onPowerUpPurchased(powerup,
                                  alreadyBought: available);
                              setModalState(() {
                                isPurchased = true;
                              });
                            },
                      height: 50,
                      width: double.infinity,
                      buttonHeight: 4,
                      buttonColor:
                          purchaseDisabled ? Colors.grey : Colors.amber,
                      backgroundColor: Colors.yellow[600],
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: available
                            ? Center(
                                child: Text(
                                "USE IT NOW",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ))
                            : Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                              ),
                      ),
                    ),
                  ] else ...[
                    // Success Message
                    Text(
                      "✅ ${powerup["name"]} Activated!",
                      style: GoogleFonts.raleway(
                        color: Colors.green,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Use this power-up while doing lessons!",
                      style: GoogleFonts.raleway(
                        color: Colors.grey[300],
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    // Button to Start Lessons
                    ChicletAnimatedButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      height: 50,
                      width: double.infinity,
                      buttonHeight: 4,
                      buttonColor: Colors.blue,
                      backgroundColor: Colors.lightBlueAccent,
                      child: Text(
                        "START LESSON",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ]
                ],
              ),
            );
          },
        );
      },
    );
  }
}
