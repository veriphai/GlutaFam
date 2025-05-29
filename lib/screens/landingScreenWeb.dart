import 'package:carousel_slider/carousel_slider.dart';
import 'package:eureka_app/apis/fetchAiTeachers.dart';
import 'package:eureka_app/screens/aboutUs.dart';
import 'package:eureka_app/utils/tutorAvatars.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui';

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
    final Color textColor = Color.fromRGBO(254, 245, 229, 1);
    final TextStyle footerTextStyle = GoogleFonts.raleway(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: textColor,
    );
    final TextStyle footerLinkStyle = GoogleFonts.raleway(
      fontSize: 14,
      fontWeight: FontWeight.w600, // Slightly bolder for links
      color: textColor,
    );
    final TextStyle headingStyle = GoogleFonts.raleway(
      fontSize: 16,
      fontWeight: FontWeight.w700, // Bolder for headings
      color: textColor,
    );

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 48.0, vertical: 30.0), // More padding
      color: Color.fromRGBO(19, 31, 36, 1), // Ensure consistent background
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

  Widget _buildPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: Color.fromRGBO(19, 31, 36, 1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Color.fromRGBO(65, 84, 103, 1)),
      ),
      child: Text(
        text,
        style: GoogleFonts.raleway(
          color: Color.fromRGBO(254, 245, 229, 1),
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ',
              style: GoogleFonts.raleway(
                fontSize: 18,
                color: Color.fromRGBO(254, 245, 229, 1),
                fontWeight: FontWeight.w800,
              )),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.raleway(
                fontSize: 16,
                color: Color.fromRGBO(254, 245, 229, 1),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPedagogyTag(String text,
      {required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.7)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.raleway(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlossyCard({
    required String imagePath,
    required String name,
    required String styleSummary,
    required List<dynamic> tags,
    required List<dynamic> bulletPoints,
    required List<dynamic> pedagogyTags,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
              width: 480,
              padding: const EdgeInsets.fromLTRB(28, 28, 28, 32),
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center:
                      Alignment.center, // Center of the gradient (can tweak)
                  radius: 1,
                  colors: [
                    Color.fromRGBO(64, 125, 184, 0.15), // Top color (start)
                    Color.fromRGBO(84, 167, 251, 0.15), // Bottom color (end)
                  ],
                  stops: [0.0, 1.0],
                ),
                borderRadius: BorderRadius.circular(28),
                // boxShadow: [
                //   BoxShadow(
                //     color: const Color(0xFF44A9FF).withOpacity(0.22),
                //     blurRadius: 24,
                //     spreadRadius: 3,
                //   ),
                // ],
                border: Border.all(
                  color: Color.fromRGBO(114, 138, 208, 1),
                  width: 2.2,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Avatar
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color.fromRGBO(3, 97, 149, 1),
                          blurRadius: 24,
                          spreadRadius: 16,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 80,
                      backgroundColor: Colors.transparent,
                      backgroundImage: AssetImage(imagePath), // Use your asset!
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  Text(
                    name,
                    style: GoogleFonts.raleway(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: Color.fromRGBO(254, 245, 229, 1),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Subtitle
                  Text(
                    styleSummary,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.raleway(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color.fromRGBO(254, 245, 229, 0.86),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tags (pills)
                  Align(
                      alignment: Alignment.topLeft,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: tags.map((tag) => _buildPill(tag)).toList(),
                      )),
                  const SizedBox(height: 22),

                  // Bullet Points
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: bulletPoints
                        .map((point) => _buildBullet(point))
                        .toList(),
                  ),
                  const SizedBox(height: 22),

                  // Pedagogy tags
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'LEARNING PEDAGOGY FOLLOWED',
                      style: GoogleFonts.raleway(
                        color: Colors.white.withOpacity(0.55),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                      alignment: Alignment.topLeft,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            pedagogyTags.map((tag) => _buildPill(tag)).toList(),
                      )),
                ],
              ))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(19, 31, 36, 1),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                  left: 48.0, right: 48.0, top: 50.0, bottom: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo

                  // Headline
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Left Column: Headline
                      // LEFT SECTION of Hero
                      Expanded(
                        flex: 1,
                        child: Padding(
                          padding: const EdgeInsets.only(
                              right: 48.0, left: 0, top: 24.0, bottom: 24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Headline
                              Image.asset(
                                'lib/assets/tuto-text-logo-website.png',
                                height: 60,
                              ),
                              SizedBox(height: 40),
                              Text(
                                'Your Personal\nAI Tutor',
                                style: GoogleFonts.raleway(
                                  fontSize: 56,
                                  fontWeight: FontWeight.w700,
                                  color: Color.fromRGBO(
                                      254, 245, 229, 1), // White headline
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Subheading (blue)
                              Text(
                                'In the style that works for you',
                                style: GoogleFonts.raleway(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w700,
                                  color: Color.fromRGBO(
                                      84, 167, 251, 1), // Use your blue
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Paragraph (white, softer)
                              Text(
                                'Most tutors teach their way. Tuto learns how you think — whether you love stories, step-by-steps, or asking “why” on loop. Built for Classes 6–10, it makes every concept click by teaching in your style. Studying won’t feel like guessing anymore.',
                                style: GoogleFonts.raleway(
                                  fontSize: 18,
                                  color: Color.fromRGBO(254, 245, 229, 1),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 32),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
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
                            ],
                          ),
                        ),
                      ),

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
                                  height: 700,
                                  enlargeCenterPage: true,
                                  enableInfiniteScroll: true,
                                  autoPlay: true,
                                  viewportFraction: 0.85,
                                ),
                                items: tutors.map((tutor) {
                                  return Builder(
                                    builder: (BuildContext context) {
                                      return _buildGlossyCard(
                                          imagePath: getTutorAvatar(
                                              tutor['avatar'])['imagePath']!,
                                          name: tutor['name'] ?? 'Unnamed',
                                          styleSummary:
                                              tutor['styleSummary'] ?? '',
                                          tags: tutor["moodMatch"],
                                          bulletPoints: tutor['goodFor'],
                                          pedagogyTags: tutor[
                                              'learningPedagogyFollowed']);
                                    },
                                  );
                                }).toList(),
                              );
                            },
                          )),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
            const Divider(
              color: Color.fromRGBO(
                  254, 245, 229, 1), // Light version of your primary color
              height: 1, // Minimal height
              thickness: 0.5, // Minimal thickness
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
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            // width: 210, // 👈 Fix width here
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
