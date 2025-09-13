import 'package:eureka_app/homepageWeb/animatedBg.dart';
import 'package:eureka_app/homepageWeb/briefPeek.dart';
import 'package:eureka_app/homepageWeb/conversationVsQuiz.dart';
import 'package:eureka_app/homepageWeb/convoShowcase.dart';
import 'package:eureka_app/homepageWeb/faq.dart';
import 'package:eureka_app/homepageWeb/footer.dart';
import 'package:eureka_app/homepageWeb/founderSpotlight.dart';
import 'package:eureka_app/homepageWeb/getStarted.dart';
import 'package:eureka_app/homepageWeb/heroSection.dart';
import 'package:eureka_app/homepageWeb/homePAgeTheme.dart';
import 'package:eureka_app/homepageWeb/howItWorks.dart';
import 'package:eureka_app/homepageWeb/navBar.dart';
import 'package:eureka_app/homepageWeb/powerStack.dart';
import 'package:eureka_app/homepageWeb/resultsThatMatter.dart';
import 'package:eureka_app/homepageWeb/testimonials.dart';
import 'package:eureka_app/homepageWeb/trustedBar.dart';
import 'package:eureka_app/homepageWeb/valueGrid.dart';
import 'package:flutter/material.dart';

class TutoHomePage extends StatefulWidget {
  const TutoHomePage({super.key});
  @override
  State<TutoHomePage> createState() => _TutoHomePageState();
}

class _TutoHomePageState extends State<TutoHomePage> {
  final _scrollCtrl = ScrollController();

  // Anchors
  final _valueKey = GlobalKey(); // “Why Tuto”
  final _howKey = GlobalKey(); // “How it works”
  final _faqKey = GlobalKey(); // “FAQs”

  void _jumpTo(String id) {
    final key = switch (id) {
      'value' => _valueKey,
      'how' => _howKey,
      'faq' => _faqKey,
      _ => null,
    };
    final ctx = key?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
        alignment: 0, // 0 = top align, tweak if you keep a sticky navbar
      );
    }
    // (Optional on web) update the URL hash:
    // if (kIsWeb) html.window.history.replaceState(null, '', '#$id');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollCtrl,
            child: Column(
              children: [
                NavBar(onNav: _jumpTo), // 👈 pass the callback
                const SizedBox(height: 40),
                const HeroSection(),
                const SizedBox(height: 30),
                const TrustedBar(),
                const SizedBox(height: 30),

                // “Why Tuto”
                ValueGrid(key: _valueKey),
                const SizedBox(height: 30),

                // “How it works”
                HowItWorks(key: _howKey),
                const SizedBox(height: 30),

                const BriefPeek(),
                const SizedBox(height: 30),
                const ConversationVsQuiz(),
                const SizedBox(height: 30),
                const ResultsThatMatter(),
                const SizedBox(height: 30),
                const PowerStack(),
                const SizedBox(height: 30),
                const ConvoShowcase(),
                const SizedBox(height: 30),
                const FounderSpotlight(),
                const SizedBox(height: 30),
                const Testimonials(),
                const SizedBox(height: 30),
                const GetStarted(),
                const SizedBox(height: 30),

                // “FAQs”
                FAQ(key: _faqKey),
                const SizedBox(height: 30),
                const Footer(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
