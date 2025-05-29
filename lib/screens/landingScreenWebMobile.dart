import 'dart:ui';

import 'package:eureka_app/apis/fetchAiTeachers.dart';
import 'package:eureka_app/screens/aboutUsMobileWeb.dart';
import 'package:eureka_app/utils/tutorAvatars.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:url_launcher/url_launcher.dart';

class LandingScreenMobile extends StatelessWidget {
  const LandingScreenMobile({super.key});

  void _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }

  Widget _buildFooter(BuildContext context) {
    // Define your primary text color for consistency
    final Color textColor = Color.fromRGBO(254, 245, 229, 1);
    final TextStyle footerTextStyle = GoogleFonts.raleway(
      fontSize: 12,
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
          horizontal: 20.0, vertical: 20.0), // More padding
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
                              builder: (context) =>
                                  const AboutUsMobileScreen()),
                        );
                      },
                      child: Text('About Us', style: footerLinkStyle),
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
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
            fontSize: 12),
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
                fontSize: 14,
                color: Color.fromRGBO(254, 245, 229, 1),
                fontWeight: FontWeight.w800,
              )),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.raleway(
                fontSize: 12,
                color: Color.fromRGBO(254, 245, 229, 1),
                fontWeight: FontWeight.w500,
              ),
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
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 32),
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
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.transparent,
                      backgroundImage: AssetImage(imagePath), // Use your asset!
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  Text(
                    name,
                    style: GoogleFonts.raleway(
                      fontSize: 20,
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
                        spacing: 4,
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
                        spacing: 4,
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
    final Color textColor = Color.fromRGBO(254, 245, 229, 1);
    return Scaffold(
      backgroundColor: Color.fromRGBO(19, 31, 36, 1),
      body: LayoutBuilder(builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: IntrinsicHeight(
                  child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 0.0, vertical: 0.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10.0, vertical: 24.0),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Center(
                                child: Image.asset(
                                  'lib/assets/tuto-text-logo-website.png',
                                  height: 40,
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Headline
                              Text(
                                'Your Personal\nAI Tutor',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.raleway(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Subtext
                              Text(
                                'In the style that works for you',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.raleway(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 20),

                              SizedBox(
                                  width: 600,
                                  child:
                                      FutureBuilder<List<Map<String, dynamic>>>(
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
                                            child: Text(
                                                'No tutors available right now.'));
                                      }

                                      final tutors = snapshot.data!;

                                      return CarouselSlider(
                                        options: CarouselOptions(
                                          height: 620,
                                          enlargeCenterPage: true,
                                          enableInfiniteScroll: true,
                                          autoPlay: true,
                                          viewportFraction: 1,
                                        ),
                                        items: tutors.map((tutor) {
                                          return Builder(
                                            builder: (BuildContext context) {
                                              return _buildGlossyCard(
                                                  imagePath: getTutorAvatar(
                                                          tutor['avatar'])[
                                                      'imagePath']!,
                                                  name: tutor['name'] ??
                                                      'Unnamed',
                                                  styleSummary:
                                                      tutor['styleSummary'] ??
                                                          '',
                                                  tags: tutor["moodMatch"],
                                                  bulletPoints:
                                                      tutor['goodFor'],
                                                  pedagogyTags: tutor[
                                                      'learningPedagogyFollowed']);
                                            },
                                          );
                                        }).toList(),
                                      );
                                    },
                                  )),

                              const SizedBox(height: 40),

                              // App Store Buttons
                              Text(
                                'Most tutors teach their way. Tuto learns how you think — whether you love stories, step-by-steps, or asking “why” on loop. Built for Classes 6–10, it makes every concept click by teaching in your style. Studying won’t feel like guessing anymore.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.raleway(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 40),

                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 8,
                                runSpacing: 16,
                                children: [
                                  StoreBadge(
                                    imagePath: 'lib/assets/appstore_badge.png',
                                    link:
                                        'https://apps.apple.com/us/app/glutaclass-ai-tutor-for-ncert/id6736943726',
                                  ),
                                  StoreBadge(
                                    imagePath: 'lib/assets/playstore_badge.png',
                                    link:
                                        'https://play.google.com/store/apps/details?id=com.gluta.glutafam',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                            ])),
                    // Logo

                    const Divider(
                      color: Color.fromRGBO(254, 245, 229,
                          1), // Light version of your primary color
                      height: 1, // Minimal height
                      thickness: 0.5, // Minimal thickness
                      indent: 0.0, // Indent from left, matching your padding
                      endIndent: 0.0, // Indent from right
                    ),
                    _buildFooter(context),
                  ],
                ),
              ))),
        );
      }),
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
        width: 180,
        padding: const EdgeInsets.only(right: 0, top: 4, bottom: 4),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
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
                    color: Colors.white,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.raleway(
                    fontSize: 20,
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
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // The Card
        Container(
          width: 300,
          margin: const EdgeInsets.only(top: 60),
          padding: const EdgeInsets.fromLTRB(24, 170, 24, 24),
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
              SizedBox(
                height: 20,
              ),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.raleway(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: const Color.fromRGBO(14, 42, 82, 1),
                ),
              ),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.raleway(
                  fontSize: 18,
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
              width: 250,
              height: 250,
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
            // width: 180, // 👈 Fix width here
            height: 50,
            child: Image.asset(imagePath, fit: BoxFit.cover),
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
