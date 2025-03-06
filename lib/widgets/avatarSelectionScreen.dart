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
        title: Text(
          'Select Your Avatar',
          style: GoogleFonts.raleway(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(
          color: Colors.grey,
        ),
        backgroundColor: const Color.fromRGBO(19, 31, 36, 1),
      ),
      backgroundColor: const Color.fromRGBO(19, 31, 36, 1),
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
                                  ? const Color.fromRGBO(255, 217, 0, 1)
                                  : Colors.transparent,
                              width: 3.0,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey[800],
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
            ElevatedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                if (selectedAvatarKey != null) {
                  Navigator.pop(context, selectedAvatarKey);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromRGBO(255, 217, 0, 1),
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 12.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: Text(
                'Confirm Selection',
                style: GoogleFonts.raleway(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
