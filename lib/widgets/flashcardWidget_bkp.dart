import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';

class FlashcardWidget extends StatefulWidget {
  final List<Map<String, dynamic>> flashcards;

  const FlashcardWidget({
    Key? key,
    required this.flashcards,
  }) : super(key: key);

  @override
  State<FlashcardWidget> createState() => _FlashcardWidgetState();
}

class _FlashcardWidgetState extends State<FlashcardWidget> {
  final CardSwiperController _controller = CardSwiperController();

  // @override
  // Widget build(BuildContext context) {
  //   return Column(
  //     children: [
  //       Expanded(
  //         child: CardSwiper(
  //           cardsCount: widget.flashcards.length,
  //           controller: _controller,
  //           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
  //           scale: 0.9,
  //           numberOfCardsDisplayed: widget.flashcards.length,
  //           cardBuilder: (context, index, direction, progress) {
  //             final card = widget.flashcards[index];
  //             return Card(
  //               elevation: 5,
  //               shape: RoundedRectangleBorder(
  //                 borderRadius: BorderRadius.circular(16),
  //               ),
  //               child: Stack(
  //                 children: [
  //                   // Background Image
  //                   Container(
  //                     decoration: BoxDecoration(
  //                       borderRadius: BorderRadius.circular(16),
  //                       image: DecorationImage(
  //                         image: NetworkImage(card['img']),
  //                         fit: BoxFit.cover,
  //                       ),
  //                     ),
  //                   ),
  //                   // Blurred Overlay with Text
  //                   Padding(
  //                       padding: EdgeInsets.symmetric(horizontal: 0),
  //                       child: Center(
  //                         child: ClipRRect(
  //                           borderRadius: BorderRadius.all(Radius.circular(8)),
  //                           // borderRadius: BorderRadius.only(
  //                           //   bottomLeft: Radius.circular(16),
  //                           //   bottomRight: Radius.circular(16),
  //                           // ),
  //                           child: BackdropFilter(
  //                             filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
  //                             child: Container(
  //                               color: Colors.black.withOpacity(0.5),
  //                               padding: const EdgeInsets.all(16.0),
  //                               child: Column(
  //                                 mainAxisSize: MainAxisSize.min,
  //                                 crossAxisAlignment: CrossAxisAlignment.start,
  //                                 children: [
  //                                   Spacer(),
  //                                   Text(
  //                                     card['heading'],
  //                                     style: GoogleFonts.raleway(
  //                                       color: Colors.white,
  //                                       fontSize: 24,
  //                                       fontWeight: FontWeight.bold,
  //                                     ),
  //                                   ),
  //                                   SizedBox(height: 8),
  //                                   Text(
  //                                     "Definition: ${card['definition']}",
  //                                     style: GoogleFonts.raleway(
  //                                       color: Colors.white,
  //                                       fontSize: 16,
  //                                     ),
  //                                   ),
  //                                   SizedBox(height: 8),
  //                                   Text(
  //                                     "Pronunciation: ${card['pronunciation']}",
  //                                     style: GoogleFonts.raleway(
  //                                       color: Colors.yellowAccent,
  //                                       fontSize: 16,
  //                                     ),
  //                                   ),
  //                                   SizedBox(height: 8),
  //                                   Text(
  //                                     "Memory Trick: ${card['memoryTrick']}",
  //                                     style: GoogleFonts.raleway(
  //                                       color: Colors.lightBlueAccent,
  //                                       fontSize: 16,
  //                                     ),
  //                                   ),
  //                                   Spacer(),
  //                                 ],
  //                               ),
  //                             ),
  //                           ),
  //                         ),
  //                       )),
  //                 ],
  //               ),
  //             );
  //           },
  //         ),
  //       ),
  //       Padding(
  //           padding: EdgeInsets.symmetric(horizontal: 20),
  //           child: Row(
  //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //             children: [
  //               ElevatedButton(
  //                 onPressed: () {
  //                   _controller.swipe(CardSwiperDirection
  //                       .right); // Swipe to the previous card
  //                 },
  //                 style: ElevatedButton.styleFrom(
  //                   backgroundColor: Colors.red,
  //                   shape: RoundedRectangleBorder(
  //                     borderRadius: BorderRadius.circular(8),
  //                   ),
  //                 ),
  //                 child: const Text("Previous"),
  //               ),
  //               ElevatedButton(
  //                 onPressed: () {
  //                   _controller.swipe(
  //                       CardSwiperDirection.left); // Swipe to the next card
  //                 },
  //                 style: ElevatedButton.styleFrom(
  //                   backgroundColor: Colors.green,
  //                   shape: RoundedRectangleBorder(
  //                     borderRadius: BorderRadius.circular(8),
  //                   ),
  //                 ),
  //                 child: const Text("Next"),
  //               ),
  //             ],
  //           )),
  //       const SizedBox(height: 16),
  //     ],
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: CardSwiper(
            cardsCount: widget.flashcards.length,
            controller: _controller,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            scale: 0.9,
            numberOfCardsDisplayed: widget.flashcards.length,
            cardBuilder: (context, index, direction, progress) {
              final card = widget.flashcards[index];
              return Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  children: [
                    // Background Image
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        image: DecorationImage(
                          image: NetworkImage(card['background']),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    // Blurred Overlay with Text
                    Padding(
                        padding: EdgeInsets.symmetric(horizontal: 0),
                        child: ClipRRect(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                            // borderRadius: BorderRadius.only(
                            //   bottomLeft: Radius.circular(16),
                            //   bottomRight: Radius.circular(16),
                            // ),
                            child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                child: Container(
                                    color: Colors.black.withOpacity(0.5),
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              image: DecorationImage(
                                                image: NetworkImage(
                                                    card['background']),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                        ]))))),
                    Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                            // borderRadius: BorderRadius.only(
                            //   bottomLeft: Radius.circular(16),
                            //   bottomRight: Radius.circular(16),
                            // ),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                              child: Container(
                                color: Colors.black.withOpacity(0.2),
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Text content
                                    // Spacer(),
                                    Text(
                                      card['heading'],
                                      style: GoogleFonts.raleway(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      "Definition: ${card['definition']}",
                                      style: GoogleFonts.raleway(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      "Pronunciation: ${card['pronunciation']}",
                                      style: GoogleFonts.raleway(
                                        color: Colors.yellow,
                                        fontSize: 16,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      "Memory Trick: ${card['memoryTrick']}",
                                      style: GoogleFonts.raleway(
                                        color:
                                            Color.fromARGB(255, 118, 183, 239),
                                        fontSize: 16,
                                      ),
                                    ),
                                    // Image
                                    SizedBox(height: 40),
                                    Container(
                                        decoration: BoxDecoration(
                                            color: Color.fromRGBO(
                                                255, 255, 255, 0.3),
                                            borderRadius:
                                                BorderRadius.circular(16)),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          child: Image.network(
                                            card['img'],
                                            fit: BoxFit.cover,
                                            height: 150,
                                            width: double.infinity,
                                          ),
                                        )),
                                    // Spacer(),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )),
                  ],
                ),
              );
            },
          ),
        ),
        Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () {
                    _controller.swipe(CardSwiperDirection
                        .right); // Swipe to the previous card
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text("Previous"),
                ),
                ElevatedButton(
                  onPressed: () {
                    _controller.swipe(
                        CardSwiperDirection.left); // Swipe to the next card
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text("Next"),
                ),
              ],
            )),
        const SizedBox(height: 16),
      ],
    );
  }

  // @override
  // Widget build(BuildContext context) {
  //   return Column(
  //     children: [
  //       Expanded(
  //         child: CardSwiper(
  //           cardsCount: widget.flashcards.length,
  //           controller: CardSwiperController(),
  //           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
  //           scale: 0.9,
  //           numberOfCardsDisplayed: widget.flashcards.length,
  //           cardBuilder: (context, index, direction, progress) {
  //             final card = widget.flashcards[index];
  //             return Card(
  //               elevation: 5,
  //               shape: RoundedRectangleBorder(
  //                 borderRadius: BorderRadius.circular(16),
  //               ),
  //               child: Container(
  //                 decoration: BoxDecoration(
  //                   borderRadius: BorderRadius.circular(16),
  //                   color: Color.fromARGB(
  //                       255, 156, 210, 94), // Solid color background
  //                 ),
  //                 child: Padding(
  //                   padding: const EdgeInsets.all(16.0),
  //                   child: Column(
  //                     mainAxisSize: MainAxisSize.min,
  //                     mainAxisAlignment: MainAxisAlignment.center,
  //                     crossAxisAlignment: CrossAxisAlignment.start,
  //                     children: [
  //                       // Text content
  //                       Text(
  //                         card['heading'],
  //                         style: GoogleFonts.raleway(
  //                           color: Colors.black,
  //                           fontSize: 24,
  //                           fontWeight: FontWeight.bold,
  //                         ),
  //                       ),
  //                       SizedBox(height: 8),
  //                       Text(
  //                         "Definition: ${card['definition']}",
  //                         style: GoogleFonts.raleway(
  //                           color: Colors.black,
  //                           fontSize: 16,
  //                         ),
  //                       ),
  //                       SizedBox(height: 8),
  //                       Text(
  //                         "Pronunciation: ${card['pronunciation']}",
  //                         style: GoogleFonts.raleway(
  //                           color: Color.fromARGB(255, 76, 63, 195),
  //                           fontSize: 16,
  //                         ),
  //                       ),
  //                       SizedBox(height: 8),
  //                       Text(
  //                         "Memory Trick: ${card['memoryTrick']}",
  //                         style: GoogleFonts.raleway(
  //                           color: Color.fromARGB(255, 230, 89, 195),
  //                           fontSize: 16,
  //                         ),
  //                       ),
  //                       // Image
  //                       SizedBox(height: 40),
  //                       ClipRRect(
  //                         borderRadius: BorderRadius.circular(8),
  //                         child: Image.network(
  //                           card['img'],
  //                           fit: BoxFit.cover,
  //                           height: 150,
  //                           width: double.infinity,
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //               ),
  //             );
  //           },
  //         ),
  //       ),
  //       Padding(
  //         padding: const EdgeInsets.symmetric(horizontal: 20),
  //         child: Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //           children: [
  //             ElevatedButton(
  //               onPressed: () {
  //                 // Swipe to the previous card
  //               },
  //               style: ElevatedButton.styleFrom(
  //                 backgroundColor: Colors.red,
  //                 shape: RoundedRectangleBorder(
  //                   borderRadius: BorderRadius.circular(8),
  //                 ),
  //               ),
  //               child: const Text("Previous"),
  //             ),
  //             ElevatedButton(
  //               onPressed: () {
  //                 // Swipe to the next card
  //               },
  //               style: ElevatedButton.styleFrom(
  //                 backgroundColor: Colors.green,
  //                 shape: RoundedRectangleBorder(
  //                   borderRadius: BorderRadius.circular(8),
  //                 ),
  //               ),
  //               child: const Text("Next"),
  //             ),
  //           ],
  //         ),
  //       ),
  //       const SizedBox(height: 16),
  //     ],
  //   );
  // }
}
