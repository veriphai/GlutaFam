import 'package:chiclet/chiclet.dart';
import 'package:eureka_app/utils/appHelperService.dart';
import 'package:eureka_app/utils/lifelinesManager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class LifelinesWidget extends StatefulWidget {
  final int lifelines;
  final Function(int lifelines, int credits)? onLifelinesUpdated;
  final bool isUnclosable;

  const LifelinesWidget({
    Key? key,
    required this.lifelines,
    this.onLifelinesUpdated,
    this.isUnclosable = false,
  }) : super(key: key);

  @override
  State<LifelinesWidget> createState() => LifelinesWidgetState();
}

class LifelinesWidgetState extends State<LifelinesWidget> {
  late int _lifelines;
  late LifelineManager lifelineManager;
  late int credits;

  Future<void> fetchData() async {
    int creditsAvailable = await getCredits();
    setState(() {
      credits = creditsAvailable;
    });
  }

  @override
  void initState() {
    super.initState();
    lifelineManager = LifelineManager();

    _lifelines = widget.lifelines;
    fetchData();
    // Initialize lifelines count
  }

  Future<void> _refillHearts(bool freeAvailed) async {
    // Start the refill process
    for (int i = _lifelines; i < 5; i++) {
      await Future.delayed(
          const Duration(milliseconds: 500)); // Delay for animation
      HapticFeedback.lightImpact(); // Haptic feedback on each refill
      setState(() {
        _lifelines++; // Increment the lifelines one by one
      });
    }
    lifelineManager.setLifelines(5);

    if (!freeAvailed) {
      final updatedCredits = credits - 300;
      updateCredits(updatedCredits);
    }
    if (widget.onLifelinesUpdated != null) {
      widget.onLifelinesUpdated!(_lifelines, credits);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // height: MediaQuery.of(context).size.height * 0.4, // Adjust height
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with title and close button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Lifelines",
                  style: GoogleFonts.raleway(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!widget.isUnclosable)
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Lifeline Icons Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                bool isActive = index < _lifelines; // Lifelines received
                return Icon(
                  Icons.favorite,
                  color: isActive
                      ? Colors.red
                      : Colors.grey, // Red if received, grey if not
                  size: 30,
                );
              }),
            ),
            Center(
                child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                        _lifelines == 5
                            ? "You have full hearts"
                            : "Next heart in 5 hours",
                        style: GoogleFonts.raleway(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        )))),

            const SizedBox(height: 20),

            // Refill Hearts Button
            SizedBox(
                width: double.infinity,
                child: ChicletOutlinedAnimatedButton(
                  onPressed: _lifelines < 5
                      ? () async {
                          HapticFeedback.lightImpact();
                          await _refillHearts(credits < 300 ? true : false);
                          Navigator.pop(context);
                        }
                      : () {},
                  buttonType: ChicletButtonTypes.roundedRectangle,
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  buttonColor: Colors.grey,
                  backgroundColor: Colors.black,
                  borderWidth: 1.0,
                  child: Row(
                    children: [
                      Icon(
                        Icons.favorite,
                        color: _lifelines < 5
                            ? Colors.red
                            : Colors.grey, // Red if received, grey if not
                        size: 30,
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Text(
                        credits < 300 ? "GET FREE HEARTS" : "REFILL HEARTS",
                        style: GoogleFonts.raleway(
                          color: _lifelines < 5 ? Colors.white : Colors.grey,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Spacer(),
                      if (credits > 300)
                        Row(
                          children: [
                            Image.asset(
                              'lib/assets/gemIcon.png',
                              height: 30,
                              width: 30,
                              color: _lifelines < 5 ? null : Colors.grey,
                            ),
                            SizedBox(width: 5),
                            Text("300",
                                style: TextStyle(
                                    color: _lifelines < 5
                                        ? Colors.white
                                        : Colors.grey))
                          ],
                        )
                    ],
                  ),
                )),

            const SizedBox(height: 16),

            // Unlimited Hearts Button
            // SizedBox(
            //   width: double.infinity,
            //   child: ChicletAnimatedButton(
            //       onPressed: () {
            //         HapticFeedback.lightImpact();
            //         // Add action logic here
            //       },
            //       buttonType: ChicletButtonTypes.roundedRectangle,
            //       height: 50,
            //       padding: const EdgeInsets.symmetric(horizontal: 10),
            //       buttonColor: Color.fromRGBO(61, 21, 204, 1),
            //       backgroundColor: Color.fromRGBO(90, 58, 207, 1),
            //       child: Row(
            //         children: [
            //           Icon(
            //             Icons.favorite,
            //             color: Colors.red,
            //             size: 30,
            //           ),
            //           SizedBox(
            //             width: 10,
            //           ),
            //           Text(
            //             "UNLIMITED HEARTS",
            //             style: GoogleFonts.raleway(
            //               color: Colors.white,
            //               fontWeight: FontWeight.w700,
            //             ),
            //           ),
            //           Spacer(),
            //           Row(
            //             children: [
            //               Image.asset(
            //                 'lib/assets/gemIcon.png',
            //                 height: 30,
            //                 width: 30,
            //               )
            //             ],
            //           )
            //         ],
            //       )),
            // ),
          ],
        ),
      ),
    );
  }
}
