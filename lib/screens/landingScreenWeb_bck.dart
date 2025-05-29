import 'package:carousel_slider/carousel_slider.dart';
import 'package:eureka_app/apis/fetchAiTeachers.dart';
import 'package:eureka_app/screens/aboutUs.dart';
import 'package:eureka_app/utils/tutorAvatars.dart';
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

  // --- New: Footer Building Method ---
  Widget _buildFooter(BuildContext context) {
    // Define your primary text color for consistency
    final Color textColor = Color.fromRGBO(14, 42, 82, 1);
    final TextStyle footerTextStyle = GoogleFonts.raleway(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: textColor,
    );
    final TextStyle footerLinkStyle = GoogleFonts.raleway(
      fontSize: 14,
      fontWeight: FontWeight.w600, // Slightly bolder for links
      color: textColor,
      // decoration: TextDecoration.underline, // Underline for clickable links
    );
    final TextStyle headingStyle = GoogleFonts.raleway(
      fontSize: 16,
      fontWeight: FontWeight.w700, // Bolder for headings
      color: textColor,
    );

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 48.0, vertical: 30.0), // More padding
      color: Color.fromRGBO(255, 245, 227, 1.0), // Ensure consistent background
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Align content to start
        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start, // Align content to top of row
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween, // Distribute space
            children: [
              // Column 1: Company Info
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tuto: AI Tutor', style: headingStyle),
                  // const SizedBox(height: 8),
                  // Text('Rapt Learn Private Ltd.', style: footerTextStyle),
                  Text('Solving education for grades 6-10.',
                      style: footerTextStyle),
                  const SizedBox(height: 8),
                  // Current Copyright
                  Text(
                    '© 2025 Rapt Learn Private Ltd.',
                    style: footerTextStyle,
                  ),
                ],
              ),

              // Column 2: Quick Links (e.g., About Us)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Quick Links', style: headingStyle),
                  const SizedBox(height: 8),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const AboutUsScreen()),
                        );
                      },
                      child: Text('About Us', style: footerLinkStyle),
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
              ),

              // Column 3: Contact Us
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Contact Us', style: headingStyle),
                  const SizedBox(height: 8),
                  MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => _launchURL(
                            'mailto:Anushank@trytuto.com?subject=Inquiry about Tuto'),
                        child: Text(
                          'Email: Anushank@trytuto.com',
                          style: footerLinkStyle,
                        ),
                      )),
                  const SizedBox(height: 4),
                  Text('Gurugram, Haryana, India', style: footerTextStyle),
                  // Add social media links if you have them
                  const SizedBox(height: 10),
                  Row(
                    children: [],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(255, 245, 227, 1.0),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(
                    left: 48.0, right: 48.0, top: 50.0, bottom: 40),
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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Left Column: Headline
                        Expanded(
                          flex: 1,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 32.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'A Personal Tutor For Everyone',
                                  style: GoogleFonts.raleway(
                                    fontSize: 48,
                                    fontWeight: FontWeight.w700,
                                    color: Color.fromRGBO(14, 42, 82, 1),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Pick your tutor. Learn your way.',
                                  style: GoogleFonts.raleway(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w600,
                                    color: Color.fromRGBO(14, 42, 82, 1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Right Column: Carousel
                        SizedBox(
                          width: 600,
                          child: FutureBuilder<List<Map<String, dynamic>>>(
                            future: fetchAITeachers(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              } else if (snapshot.hasError ||
                                  !snapshot.hasData ||
                                  snapshot.data!.isEmpty) {
                                return const Center(
                                    child:
                                        Text('No tutors available right now.'));
                              }

                              final tutors = snapshot.data!;

                              return CarouselSlider(
                                options: CarouselOptions(
                                  height: 400,
                                  enlargeCenterPage: true,
                                  enableInfiniteScroll: true,
                                  autoPlay: true,
                                  viewportFraction: 0.85,
                                ),
                                items: tutors.map((tutor) {
                                  return Builder(
                                    builder: (BuildContext context) {
                                      return TutorCard(
                                        imagePath: getTutorAvatar(
                                            tutor['avatar'])['imagePath']!,
                                        title: tutor['name'] ?? 'Unnamed',
                                        subtitle: tutor['styleSummary'] ?? '',
                                      );
                                    },
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),

                    // App Store Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        StoreBadge(
                          imagePath: 'lib/assets/appstore_badge.png',
                          link:
                              'https://apps.apple.com/us/app/glutaclass-ai-tutor-for-ncert/id6736943726',
                        ),
                        const SizedBox(width: 24),
                        StoreBadge(
                          imagePath: 'lib/assets/playstore_badge.png',
                          link:
                              'https://play.google.com/store/apps/details?id=com.gluta.glutafam',
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
            const Divider(
              color: Color.fromRGBO(
                  14, 42, 82, 0.2), // Light version of your primary color
              height: 1, // Minimal height
              thickness: 1, // Minimal thickness
              indent: 48.0, // Indent from left, matching your padding
              endIndent: 48.0, // Indent from right
            ),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }
}

class StoreBadge extends StatelessWidget {
  final String imagePath;
  final String link;

  const StoreBadge({
    super.key,
    required this.imagePath,
    required this.link,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _launchURL(link),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 210, // 👈 Fix width here
            height: 60,
            child: Image.asset(
              imagePath,
              fit: BoxFit.cover, // Fills the box while keeping proportions
            ),
          ),
        ),
      ),
    );
  }

  void _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
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
