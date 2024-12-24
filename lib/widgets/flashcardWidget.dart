import 'dart:ui';
import 'package:chiclet/chiclet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  int _currentCardIndex = 0;

  Color getProgressBarColor(double progress) {
    if (progress <= 0.25) {
      return Colors.red; // Below 25% progress
    } else if (progress <= 0.50) {
      return Colors.orange; // Between 25% and 50%
    } else if (progress <= 0.75) {
      return Colors.yellow; // Between 50% and 75%
    } else {
      return Colors.green; // Above 75%
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          child: Stack(
            children: [
              // Background Bar
              Container(
                height: 12.0,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(4.0),
                ),
              ),
              // Filled Bar
              FractionallySizedBox(
                widthFactor: (_currentCardIndex + 1) / widget.flashcards.length,
                child: Container(
                  height: 12.0,
                  decoration: BoxDecoration(
                    color: getProgressBarColor(
                        (_currentCardIndex + 1) / widget.flashcards.length),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: CardSwiper(
            cardsCount: widget.flashcards.length,
            controller: _controller,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            scale: 0.9,
            numberOfCardsDisplayed: widget.flashcards.length,
            onSwipe: (currentIndex, targetIndex, direction) {
              if (targetIndex != null) {
                setState(() {
                  // Increment or decrement based on swipe direction
                  if (direction == CardSwiperDirection.left) {
                    // Swiped to the next card
                    _currentCardIndex =
                        (_currentCardIndex + 1) % widget.flashcards.length;
                  } else if (direction == CardSwiperDirection.right) {
                    // Swiped to the previous card
                    _currentCardIndex =
                        (_currentCardIndex - 1 + widget.flashcards.length) %
                            widget.flashcards.length;
                  }
                });
              }
              return true; // Allow the swipe
            },
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
        SizedBox(
          height: 15,
        ),
        Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ChicletAnimatedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _controller.swipe(CardSwiperDirection.right);

                      // print('${concepts[index]['name']} clicked');
                    },
                    buttonType: ChicletButtonTypes.circle,
                    width: 80,
                    height: 40,
                    buttonHeight: 4,
                    padding: EdgeInsets.all(0),
                    buttonColor: Color.fromRGBO(187, 160, 2, 1),
                    backgroundColor: Color.fromRGBO(255, 217, 0, 1),
                    child: Icon(Icons.navigate_before_rounded,
                        color: Colors.black, size: 30)),
                ChicletAnimatedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _controller.swipe(CardSwiperDirection.left);

                      // print('${concepts[index]['name']} clicked');
                    },
                    buttonType: ChicletButtonTypes.circle,
                    width: 80,
                    height: 40,
                    buttonHeight: 4,
                    padding: EdgeInsets.all(0),
                    buttonColor: Color.fromRGBO(187, 160, 2, 1),
                    backgroundColor: Color.fromRGBO(255, 217, 0, 1),
                    child: Icon(Icons.navigate_next_rounded,
                        color: Colors.black, size: 30)),
              ],
            )),
        const SizedBox(height: 16),
      ],
    );
  }
}
