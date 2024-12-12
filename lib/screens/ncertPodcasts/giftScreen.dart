import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:eureka_app/events/referralScreenEvents.dart';
import 'package:eureka_app/screens/ncertPodcasts/chapterListingScreen.dart';
import 'package:eureka_app/utils/authTokenService.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class GiftScreen extends StatefulWidget {
  final int joinedReferrals;
  final String? redeemedGiftId;

  const GiftScreen(
      {Key? key, required this.joinedReferrals, this.redeemedGiftId})
      : super(key: key);

  @override
  _GiftScreenState createState() => _GiftScreenState();
}

class _GiftScreenState extends State<GiftScreen> {
  late List<Map<String, dynamic>> gifts;
  bool isLoading = true;
  bool hasError = false;
  String? redeemedGiftId;

  @override
  void initState() {
    super.initState();
    setState(() {
      redeemedGiftId = widget.redeemedGiftId;
    });
    _fetchGifts();
    logRedeemGiftScreenView(
        widget.joinedReferrals, redeemedGiftId != '' ? true : false);
  }

  Future<void> _fetchGifts() async {
    const url = 'https://glutaclass.com:8080/gluta/fam/referral-gifts';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        gifts = data
            .map((gift) => {
                  "id": gift["id"],
                  "text": gift["text"],
                  "imageUrl": gift["imageUrl"],
                  "referralRequired": gift["referralRequired"],
                  "title": gift["title"]
                })
            .toList();
        setState(() {
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load gifts');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        hasError = true;
      });
      print('Error fetching gifts: $e');
    }
  }

  Future<void> redeemGift(String giftId, String phoneNumber) async {
    const url =
        'https://glutaclass.com:8080/gluta/fam/redeem-gift'; // API Endpoint
    try {
      // Replace this with the method to get your auth token
      final AuthTokenService authTokenService = AuthTokenService();
      final authToken = await authTokenService.getAuthToken();

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          "giftId": giftId,
          "phoneNumber": phoneNumber,
        }),
      );

      if (response.statusCode == 200) {
        print("Gift redeemed successfully: ${response.body}");
        setState(() {
          redeemedGiftId = giftId;
        });
        return; // Success
      } else {
        print("Failed to redeem gift: ${response.body}");
        throw Exception("Failed to redeem gift: ${response.statusCode}");
      }
    } catch (e) {
      print("Error redeeming gift: $e");
      throw Exception("Error redeeming gift: $e");
    }
  }

  void _showPhoneNumberPopup(
      BuildContext context, String giftName, String giftId) {
    TextEditingController phoneController = TextEditingController();
    ValueNotifier<bool> isButtonEnabled = ValueNotifier<bool>(false);

    phoneController.addListener(() {
      if (phoneController.text.length >= 10) {
        isButtonEnabled.value = true;
      } else {
        isButtonEnabled.value = false;
      }
    });

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black, // Black background
          title: Center(
            child: Text(
              "Enter Your Phone Number",
              style: GoogleFonts.raleway(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white, // White text for better contrast
              ),
            ),
          ),
          content: TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            style:
                TextStyle(color: Colors.white), // White text inside the field
            decoration: InputDecoration(
              hintText: "Enter phone number",
              hintStyle: TextStyle(color: Colors.grey), // Grey hint text
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey), // Grey border
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide:
                    BorderSide(color: const Color.fromRGBO(255, 217, 0, 1)),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          actionsAlignment:
              MainAxisAlignment.center, // Center alignment for buttons
          actions: [
            ValueListenableBuilder<bool>(
              valueListenable: isButtonEnabled,
              builder: (context, isEnabled, child) {
                return ElevatedButton(
                  onPressed: isEnabled
                      ? () async {
                          Navigator.of(context).pop();
                          _showConfirmationPopup(context, giftName, giftId);

                          // await Future.delayed(Duration(milliseconds: 1000));
                          try {
                            redeemGift(
                              giftId,
                              phoneController.text,
                            );
                            logPhoneNumberForRedemption(widget.joinedReferrals,
                                giftId, phoneController.text);
                          } catch (e) {}
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(255, 217, 0, 1),
                    disabledBackgroundColor: Colors.grey,
                  ),
                  child: Text(
                    "Continue",
                    style: GoogleFonts.raleway(
                      color: Colors.black,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _showConfirmationPopup(
      BuildContext context, String giftName, String giftId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black, // Black background
          title: Center(
            child: Text(
              "Congratulations!",
              style: GoogleFonts.raleway(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white, // White text for better contrast
              ),
            ),
          ),
          content: Text(
            "Your request for '$giftName' has been submitted. Our team will contact you shortly.",
            textAlign: TextAlign.center, // Center the text
            style: GoogleFonts.raleway(fontSize: 16, color: Colors.white),
          ),
          actionsAlignment:
              MainAxisAlignment.center, // Center alignment for buttons
          actions: [
            ElevatedButton(
              onPressed: () {
                logGiftSucessfullyRedeemedContinueButtonClick(
                    widget.joinedReferrals, giftId);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => Chapterscreen()),
                  (Route<dynamic> route) =>
                      false, // Removes all previous routes
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromRGBO(255, 217, 0, 1),
              ),
              child: Text(
                "OK",
                style: GoogleFonts.raleway(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final int referralsToGo = 10 - widget.joinedReferrals;

    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            "Redeem Your Gifts",
            style: GoogleFonts.raleway(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          iconTheme: IconThemeData(color: Colors.white),
          backgroundColor: Colors.black,
        ),
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(
            color: const Color.fromRGBO(255, 217, 0, 1),
          ),
        ),
      );
    }

    if (hasError) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            "Redeem Your Gifts",
            style: GoogleFonts.raleway(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          iconTheme: IconThemeData(color: Colors.white),
          backgroundColor: Colors.black,
        ),
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            "Failed to load gifts. Please try again later.",
            style: GoogleFonts.raleway(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Redeem Your Gifts",
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              redeemedGiftId != ""
                  ? "You have redeemed your gift!"
                  : referralsToGo > 0
                      ? "You have $referralsToGo more referrals to go."
                      : "You can redeem your gift now!",
              style: GoogleFonts.raleway(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: gifts.length,
                itemBuilder: (context, index) {
                  final gift = gifts[index];
                  final isRedeemed = redeemedGiftId == gift["id"];

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[850],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        // Gift Image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: gift["imageUrl"],
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Gift Name
                        Expanded(
                          child: Text(
                            gift["text"],
                            style: GoogleFonts.raleway(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Redeem Button
                        ElevatedButton(
                          onPressed: redeemedGiftId != ""
                              ? null
                              : widget.joinedReferrals >=
                                      gift["referralRequired"]
                                  ? () {
                                      _showPhoneNumberPopup(
                                          context, gift["title"], gift["id"]);
                                      logRedeemButtonClick(
                                          widget.joinedReferrals, gift["id"]);
                                    }
                                  : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromRGBO(255, 217, 0, 1),
                            disabledBackgroundColor: Colors.grey,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            isRedeemed ? "Redeemed" : "Redeem",
                            style: GoogleFonts.raleway(
                              color: widget.joinedReferrals >=
                                      gift["referralRequired"]
                                  ? Colors.black
                                  : Colors.grey[600],
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
