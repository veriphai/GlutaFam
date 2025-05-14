import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class LandingScreenWeb extends StatelessWidget {
  const LandingScreenWeb({super.key});

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
      backgroundColor: Color.fromRGBO(255, 245, 227, 1.0),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48.0, vertical: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Image.asset(
                'lib/assets/tuto-text-logo.png',
                height: 50,
              ),
              const SizedBox(height: 24),

              // Headline
              Text(
                'A Personal Tutor For Everyone',
                style: GoogleFonts.raleway(
                  fontSize: 48,
                  fontWeight: FontWeight.w700,
                  color: Color.fromRGBO(14, 42, 82, 1),
                ),
              ),
              // const SizedBox(height: 8),

              // Subtext
              Text(
                'Pick your tutor. Learn your way.',
                style: GoogleFonts.raleway(
                    fontSize: 36,
                    color: Color.fromRGBO(14, 42, 82, 1),
                    fontWeight: FontWeight.w600),
              ),
              // const SizedBox(height: 20),

              // Tutor Cards
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  TutorCard(
                    imagePath: 'lib/assets/storyteller-tuto.png',
                    title: 'Storyteller Tuto',
                    subtitle: 'Explains with stories',
                  ),
                  SizedBox(width: 40),
                  TutorCard(
                    imagePath: 'lib/assets/socratic-sage.png',
                    title: 'Socratic Sage',
                    subtitle: 'Asks smart questions',
                  ),
                  SizedBox(width: 40),
                  TutorCard(
                    imagePath: 'lib/assets/meme-master.png',
                    title: 'Meme Master',
                    subtitle: 'Concepts with punchlines',
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // App Store Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  StoreButton(
                    iconPath: 'lib/assets/apple-logo.png',
                    title: 'Download on the',
                    subtitle: 'App Store',
                    onTap: () => _launchURL(
                        'https://apps.apple.com/us/app/glutaclass-ai-tutor-for-ncert/id6736943726'),
                  ),
                  const SizedBox(width: 32),
                  StoreButton(
                    iconPath: 'lib/assets/play-logo.png',
                    title: 'Get it on',
                    subtitle: 'Google Play',
                    onTap: () => _launchURL(
                        'https://play.google.com/store/apps/details?id=com.gluta.glutafam'),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Footer Text
              Text(
                'Your first 15-minute journey starts today. No pressure. Just joyful learning.',
                style: GoogleFonts.raleway(
                    fontSize: 20,
                    color: Color.fromRGBO(14, 42, 82, 1),
                    fontWeight: FontWeight.w600),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class StoreButton extends StatelessWidget {
  final String iconPath;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const StoreButton({
    super.key,
    required this.iconPath,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 210,
        padding: const EdgeInsets.only(right: 0, top: 4, bottom: 4),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
          // boxShadow: [
          //   BoxShadow(
          //     color: Colors.black.withOpacity(0.05),
          //     blurRadius: 10,
          //     offset: const Offset(0, 4),
          //   ),
          // ],
        ),
        child: Row(
          children: [
            Image.asset(
              iconPath,
              width: 50,
              height: 50,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 4),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.raleway(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.raleway(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class TutorCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final String subtitle;

  const TutorCard({
    super.key,
    required this.imagePath,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // The Card
          Container(
            width: 300,
            margin: const EdgeInsets.only(top: 60), // Leave space for avatar
            padding: const EdgeInsets.fromLTRB(
                24, 200, 24, 24), // top padding for inner spacing
            decoration: BoxDecoration(
              color: const Color.fromRGBO(255, 248, 236, 1.0),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.raleway(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: const Color.fromRGBO(14, 42, 82, 1),
                  ),
                ),
                // const SizedBox(height: 8),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.raleway(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: const Color.fromRGBO(14, 42, 82, 1),
                  ),
                ),
              ],
            ),
          ),

          // Floating Avatar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 270,
                height: 270,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.transparent,
                ),
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
