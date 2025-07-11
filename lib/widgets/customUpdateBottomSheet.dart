import 'dart:io' show Platform;
import 'package:chiclet/chiclet.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomUpdateBottomSheet extends StatelessWidget {
  final bool forceUpdate;
  final String message;

  const CustomUpdateBottomSheet({
    Key? key,
    required this.forceUpdate,
    required this.message,
  }) : super(key: key);

  void _launchStore(BuildContext context) async {
    final url = Platform.isAndroid
        ? "https://play.google.com/store/apps/details?id=com.gluta.glutafam"
        : "https://apps.apple.com/us/app/glutaclass-ai-tutor-for-ncert/id6736943726";

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not launch the store link.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 30),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Expanded so text can use leftover space
              Expanded(
                child: Text(
                  "Update Available",
                  style: GoogleFonts.raleway(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              // Button with auto width
              ChicletAnimatedButton(
                onPressed: () => _launchStore(context),
                buttonType: ChicletButtonTypes.roundedRectangle,
                width: 120,
                height: 40,
                buttonColor: const Color.fromRGBO(187, 160, 2, 1),
                backgroundColor: const Color.fromRGBO(255, 217, 0, 1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    "UPDATE NOW",
                    style: GoogleFonts.raleway(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        )
      ],
    );
  }
}
