import 'package:chiclet/chiclet.dart';
import 'package:eureka_app/apis/claimAndGetReward.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class RewardScreen extends StatefulWidget {
  final String rewardFor;
  final String taskId;

  const RewardScreen({
    Key? key,
    required this.rewardFor,
    required this.taskId,
  }) : super(key: key);

  @override
  State<RewardScreen> createState() => _RewardScreenState();
}

class _RewardScreenState extends State<RewardScreen> {
  bool isLoading = true;
  Map<String, dynamic> rewardData = {};

  @override
  void initState() {
    super.initState();
    _fetchReward();
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(color: Colors.orange),
            )
          : rewardData.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Spacer(),
                        // Reward Image
                        Image.network(
                          rewardData["image"] ?? "",
                          height: 200,
                          width: 200,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            return progress == null
                                ? child
                                : CircularProgressIndicator(
                                    color: Colors.orange,
                                  );
                          },
                        ),
                        const SizedBox(height: 16),
                        // Reward Name
                        Text(
                          rewardData["name"] ?? "No Name",
                          style: GoogleFonts.raleway(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        // Reward Description
                        Text(
                          rewardData["description"] ?? "No Description",
                          style: GoogleFonts.raleway(
                            color: Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Spacer(),
                        // Close Button

                        ChicletAnimatedButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            Navigator.pop(context);
                          },
                          buttonType: ChicletButtonTypes.roundedRectangle,
                          width: double.infinity,
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
                      ],
                    ),
                  ),
                )
              : Center(
                  child: Text(
                    "No reward details available.",
                    style: GoogleFonts.raleway(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
    );
  }
}
