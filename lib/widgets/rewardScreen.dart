import 'package:chiclet/chiclet.dart';
import 'package:eureka_app/apis/claimAndGetReward.dart';
import 'package:eureka_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

class RewardScreen extends StatefulWidget {
  final String rewardFor;
  final String taskId;
  final bool redirectToHomeScreen;

  const RewardScreen({
    Key? key,
    required this.rewardFor,
    required this.taskId,
    this.redirectToHomeScreen = false,
  }) : super(key: key);

  @override
  State<RewardScreen> createState() => _RewardScreenState();
}

class _RewardScreenState extends State<RewardScreen>
    with TickerProviderStateMixin {
  bool isLoading = true;
  Map<String, dynamic> rewardData = {};
  bool isChestOpening = true; // Controls chest animation visibility
  bool showReward = false; // Controls reward emergence

  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _positionAnimation;

  @override
  void initState() {
    super.initState();
    _fetchReward();

    // Initialize animation controller for reward emergence
    _controller = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _positionAnimation = Tween<double>(begin: 50, end: -50).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _startVibrationEffect();

    // Start chest animation, then reveal reward
    Future.delayed(Duration(seconds: 4), () {
      setState(() {
        isChestOpening = false;
        showReward = true;
      });

      _controller.forward();
    });
  }

  void _startVibrationEffect() {
    int duration = 50; // Start with a short vibration
    int step = 5; // Increase duration by 50ms each step
    int totalDuration = 4000; // Total 4 seconds

    Future.doWhile(() async {
      if (!isChestOpening) return false; // Stop when chest animation ends

      HapticFeedback.mediumImpact(); // Vibration effect
      await Future.delayed(Duration(milliseconds: duration));

      if (duration > 0) {
        duration -= step;
      }

      return true; // Keep looping
    });
  }

  Future<void> _fetchReward() async {
    final reward = await claimAndGetReward(
        rewardFor: widget.rewardFor, taskId: widget.taskId);
    setState(() {
      rewardData = reward;
      isLoading = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(19, 31, 36, 1),
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // **1️⃣ Chest Opening Animation (Lottie)**
            if (isChestOpening)
              Lottie.asset(
                "lib/assets/animations/treasureChest.json",
                width: 350,
                height: 350,
              ),

            // **2️⃣ Reward Emerges**
            if (showReward)
              Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Spacer(),
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _positionAnimation.value),
                          child: Transform.scale(
                            scale: _scaleAnimation.value,
                            child: Image.network(
                              rewardData["image"] ?? "",
                              height: 150,
                              width: 150,
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),
                    Spacer(),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      child: SizedBox(
                        width: double.infinity, // 🆕 Takes full width
                        child: ChicletAnimatedButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            if (widget.redirectToHomeScreen) {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => MainPage()),
                                (route) => false,
                              );
                            } else {
                              Navigator.pop(context);
                            }
                          },
                          buttonType: ChicletButtonTypes.roundedRectangle,
                          height: 50,
                          buttonHeight: 4,
                          padding: const EdgeInsets.all(8),
                          buttonColor: const Color.fromARGB(255, 187, 160, 2),
                          backgroundColor:
                              const Color.fromARGB(255, 255, 217, 0),
                          child: Text(
                            "CONTINUE",
                            style: GoogleFonts.raleway(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ]),
          ],
        ),
      ),
    );
  }
}
