import 'dart:io';

import 'package:chiclet/chiclet.dart';
import 'package:eureka_app/apis/postFeed.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;

class CollectionDetailsWidget extends StatelessWidget {
  final Map<String, dynamic> collectionItem;

  const CollectionDetailsWidget({Key? key, required this.collectionItem})
      : super(key: key);

  void showShareOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ChicletAnimatedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  postFeed(type: "STICKER_SHARED", feedData: {
                    "image": collectionItem["image"],
                    "rewardId": collectionItem["id"]
                  });
                  Navigator.pop(context);
                },
                buttonType: ChicletButtonTypes.roundedRectangle,
                height: 50,
                width: double.infinity,
                buttonHeight: 4,
                buttonColor: Color.fromRGBO(187, 160, 2, 1),
                backgroundColor: Color.fromRGBO(255, 217, 0, 1),
                child: Text(
                  "POST ON YOUR FEED",
                  style: GoogleFonts.raleway(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(
                height: 10,
              ),
              ChicletAnimatedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context);
                    shareCollectionItem();
                    // Navigator.push(
                    //   context,
                    //   MaterialPageRoute(
                    //     builder: (context) => MCQQuestions(
                    //       conceptId: widget.conceptId,
                    //       conceptName: widget.conceptName,
                    //       maxXP: widget.maxXP - 15,
                    //     ),
                    //   ),
                    // );
                  },
                  buttonType: ChicletButtonTypes.roundedRectangle,
                  height: 50,
                  width: double.infinity,
                  buttonHeight: 4,
                  buttonColor: Color.fromRGBO(187, 160, 2, 1),
                  backgroundColor: Color.fromRGBO(255, 217, 0, 1),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "SHARE USING LINK",
                        style: GoogleFonts.raleway(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )),
            ],
          ),
        );
      },
    );
  }

  void shareCollectionItem() async {
    final response = await http.get(Uri.parse(collectionItem["image"]));
    if (response.statusCode == 200) {
      final imageBytes = response.bodyBytes;
      final tempFile = File(
          '${(await getTemporaryDirectory()).path}/${DateTime.now().millisecondsSinceEpoch}.png');
      await tempFile.writeAsBytes(imageBytes);
      final xFile = XFile(tempFile.path);

      await Share.shareXFiles([xFile], text: 'Check out this sticker');

      await tempFile.delete();
    } else {
      // Handle the error (e.g., show an error message to the user)
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: Column(
        children: [
          // Close button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.close, color: Colors.white),
              ),
              IconButton(
                onPressed: () {
                  showShareOptions(context);
                },
                icon: const Icon(Icons.ios_share, color: Colors.white),
              ),
            ],
          ),
          Spacer(),
          if (collectionItem["image"] != null)
            Center(
              child: Image.network(
                collectionItem["image"],
                height: 200,
                width: 200,
                fit: BoxFit.cover,
              ),
            )
          else
            const Center(
              child: Icon(
                Icons.emoji_events,
                size: 120,
                color: Colors.grey,
              ),
            ),
          const SizedBox(height: 16),
          Text(
            collectionItem["description"] ?? "No description available",
            style: GoogleFonts.raleway(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          Spacer(),
        ],
      ),
    );
  }
}
