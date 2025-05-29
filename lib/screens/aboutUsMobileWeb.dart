// lib/screens/about_us_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutUsMobileScreen extends StatelessWidget {
  const AboutUsMobileScreen({super.key});

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
    // final Color backgroundColor = Color.fromRGBO(19, 31, 36, 1);
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
                  MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () {
                          // Navigate to the new About Us screen
                          Navigator.pop(context);
                        },
                        child: Text('Tuto: AI Tutor', style: headingStyle),
                      )),
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

  @override
  Widget build(BuildContext context) {
    final Color textColor = Color.fromRGBO(254, 245, 229, 1);
    final Color backgroundColor = Color.fromRGBO(19, 31, 36, 1);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Align(
                    alignment: Alignment.topLeft,
                    child: Image.asset(
                      'lib/assets/tuto-text-logo-website.png',
                      height: 40,
                    ))),

            // --- Content Section 1: Our Belief ---
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10.0, vertical: 0.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Why We Built Tuto',
                          textAlign: TextAlign.left,
                          style: GoogleFonts.raleway(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: textColor),
                        ),
                        const SizedBox(height: 30),
                        Text(
                          'Every student deserves a personal tutor — someone who listens, understands how they think, and never judges their questions. That’s why we built Tuto: an AI tutor that adapts to your mood, your pace, and your style. Whether you prefer detailed explanations, playful banter, or quick nudges, Tuto’s got your back — just like your favorite teacher would.\n\n'
                          'But learning shouldn’t just be personal. It should be fun. Exciting. Even addictive. At Tuto, we’ve gamified the entire learning journey — from XP and streaks to quest-based challenges and tutor personalities that match how you like to learn. Because when learning feels like play, you don’t just learn more — you actually want to come back.',
                          textAlign: TextAlign.left,
                          style: GoogleFonts.raleway(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                            height: 1.6,
                          ),
                        ),
                        // const SizedBox(height: 60),
                      ],
                    ),
                  ),

                  const SizedBox(height: 60),

                  // --- Meet Our Founders Section ---
                  Center(
                      child: Text(
                    'Meet Our Founders',
                    style: GoogleFonts.raleway(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  )),
                  const SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 0.0),
                          child: _buildFounderCard(
                            imagePath: 'lib/assets/dagar-profile-img.jpeg',
                            name: 'Anushank Dagar',
                            role: 'CEO & Co-founder',
                            bio:
                                'Anushank is a Mathematics and Computing graduate from Delhi Technological University (formerly DCE).\n\n'
                                'He previously worked as a Product Manager at Jio Embibe, where he explored what makes students learn best. From pedagogy to learning psychology, he gained hands-on experience designing engaging and effective learning systems. He combines an educator’s empathy with a builder’s clarity.',
                            linkedinUrl:
                                'https://www.linkedin.com/in/anushank-dagar-a59460a8/',
                            textColor: textColor,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 0.0),
                          child: _buildFounderCard(
                            imagePath: 'lib/assets/sahu-profile-img.jpeg',
                            name: 'Shubham Sahu',
                            role: 'CTO & Co-founder',
                            bio:
                                'Shubham is an Information Technology graduate from Delhi Technological University (formerly DCE).\n\n'
                                'He has worked at Amdocs, Airtel, and Certa as a Software Developer, building scalable systems and AI-powered tools. With strong engineering instincts and a love for clean architecture, he ensures the tech is as seamless and smart as the learning experience.',
                            linkedinUrl:
                                'https://www.linkedin.com/in/shubham-sahu-a26a07107',
                            textColor: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 60),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'Ready for a tutor who truly gets it?',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.raleway(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 20),
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(
              color: Color.fromRGBO(
                  254, 245, 229, 1), // Light version of your primary color
              height: 1, // Minimal height
              thickness: 0.5, // Minimal thickness
              indent: 0.0, // Indent from left, matching your padding
              endIndent: 0.0, // Indent from right
            ),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  // Helper widget for navigation links in the About section
  Widget _buildAboutNavLink(String text, Color textColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 5.0),
        child: Text(
          text,
          style: GoogleFonts.raleway(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textColor,
            decoration: TextDecoration.none, // No underline by default
          ),
        ),
      ),
    );
  }

  // Helper widget for Founder Card (remains the same)
  Widget _buildFounderCard({
    required String imagePath,
    required String name,
    required String role,
    required String bio,
    required String linkedinUrl,
    required Color textColor,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Color.fromRGBO(19, 31, 36, 1),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1,
            colors: [
              Color.fromRGBO(64, 125, 184, 0.15),
              Color.fromRGBO(84, 167, 251, 0.15),
            ],
            stops: [0.0, 1.0],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Color.fromRGBO(114, 138, 208, 1),
            width: 2.2,
          ),
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage(imagePath),
              backgroundColor: Color.fromRGBO(255, 245, 227, 1.0),
            ),
            const SizedBox(height: 16),
            Text(
              name,
              style: GoogleFonts.raleway(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              role,
              style: GoogleFonts.raleway(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              bio,
              style: GoogleFonts.raleway(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textColor,
                height: 1.4,
              ),
              // textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _launchURL(linkedinUrl),
              icon: Image.asset(
                'lib/assets/LinkedIn_logo.png',
                height: 20,
                // color: Colors.white,
              ),
              label: Text(
                'Connect on LinkedIn',
                style: GoogleFonts.raleway(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0077B5),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
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
            // width: 180, // 👈 Fix width here
            height: 50,
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
