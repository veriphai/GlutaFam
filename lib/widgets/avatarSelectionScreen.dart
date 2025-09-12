import 'package:chiclet/chiclet.dart';
import 'package:eureka_app/screens/home/homeScreen.dart';
import 'package:eureka_app/utils/avatars.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AvatarSelectionScreen extends StatefulWidget {
  final String? initialAvatarKey;

  const AvatarSelectionScreen({Key? key, this.initialAvatarKey})
      : super(key: key);

  @override
  _AvatarSelectionScreenState createState() => _AvatarSelectionScreenState();
}

class _AvatarSelectionScreenState extends State<AvatarSelectionScreen> {
  String? selectedAvatarKey;

  @override
  void initState() {
    super.initState();
    // Set initial selection
    selectedAvatarKey = widget.initialAvatarKey ?? avatars.keys.first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Align(
          alignment: Alignment.centerLeft, // This forces left alignment
          child: Text(
            "Select Your Avatar",
            style: GoogleFonts.inter(
              color: AppColors.ink,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        iconTheme: IconThemeData(
          color: Colors.grey,
        ),
        backgroundColor: AppColors.bg,
      ),
      backgroundColor: AppColors.bg,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Avatar Grid
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, // Number of columns
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                ),
                itemCount: avatars.length,
                itemBuilder: (context, index) {
                  final avatarKey = avatars.keys.elementAt(index);
                  final avatar = avatars[avatarKey]!;

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        selectedAvatarKey = avatarKey;
                      });
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Avatar Image
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: selectedAvatarKey == avatarKey
                                  ? Color.fromRGBO(29, 78, 216, 1)
                                  : Colors.transparent,
                              width: 3.0,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color: AppColors.card,
                          ),
                          padding: const EdgeInsets.all(8.0),
                          child: Image.asset(
                            avatar["imagePath"]!,
                            fit: BoxFit.cover,
                          ),
                        ),
                        // Avatar Name
                        // Positioned(
                        //   bottom: 4.0,
                        //   child: Text(
                        //     avatar["name"]!,
                        //     style: GoogleFonts.raleway(
                        //       color: Colors.white,
                        //       fontSize: 16,
                        //       fontWeight: FontWeight.w700,
                        //     ),
                        //     textAlign: TextAlign.center,
                        //   ),
                        // ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16.0),
            // Confirm Button
            ChicletAnimatedButton(
              onPressed: () {
                if (selectedAvatarKey != null) {
                  Navigator.pop(context, selectedAvatarKey);
                }
                // Logic for adding friends
              },
              buttonType: ChicletButtonTypes.roundedRectangle,
              height: 50,
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              buttonColor: Color.fromRGBO(6, 72, 255, 1),
              backgroundColor: Color.fromRGBO(29, 78, 216, 1),
              child: Text(
                "CONFIRM SELECTION",
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
