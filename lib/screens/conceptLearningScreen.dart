import 'package:eureka_app/widgets/flashcardWidget.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ConceptLearningScreen extends StatefulWidget {
  final String conceptId;
  final String conceptName;

  const ConceptLearningScreen({
    Key? key,
    required this.conceptId,
    required this.conceptName,
  }) : super(key: key);

  @override
  _ConceptLearningScreenState createState() => _ConceptLearningScreenState();
}

class _ConceptLearningScreenState extends State<ConceptLearningScreen> {
  // Mock Data
  final List<Map<String, dynamic>> flashcards = [
    {
      "id": "flashcard-1",
      "heading": "Autotrophs",
      "definition":
          "Organisms that can make their own food using simple substances like carbon dioxide, water, and sunlight. Examples include green plants and some bacteria.",
      "pronunciation": "aw-tuh-trofs",
      "think": " \"Auto\" = self, \"troph\" = nourishment",
      "memoryTrick":
          "Picture a \"self-driving car\" that doesn’t need a driver to fuel it. Similarly, autotrophs don’t need to get food from other organisms—they make their own using sunlight!",
      "img": "https://gluta.s3.ap-south-1.amazonaws.com/autotrophs.webp",
      "background": "https://gluta.s3.ap-south-1.amazonaws.com/autotrophs.webp"
    },
    {
      "id": "flashcard-2",
      "heading": "Heterotrophs",
      "definition":
          "Organisms that cannot make their own food. They depend on plants or other animals for nourishment. Examples include animals, most bacteria, and fungi.",
      "pronunciation": "heh-tuh-roh-trofs",
      "think": " \"Hetero\" = different, \"troph\" = nourishment",
      "memoryTrick":
          "Picture a \"hungry squirrel\" scavenging for nuts in a forest. It can’t make nuts on its own, so it must gather them from trees. This is what heterotrophs do—they get their food from different sources, instead of making it themselves!",
      "img": "https://gluta.s3.ap-south-1.amazonaws.com/heterotrophs.webp",
      "background":
          "https://gluta.s3.ap-south-1.amazonaws.com/heterotrophs.webp"
    },
    {
      "id": "flashcard-1",
      "heading": "Autotrophs",
      "definition":
          "Organisms that can make their own food using simple substances like carbon dioxide, water, and sunlight. Examples include green plants and some bacteria.",
      "pronunciation": "aw-tuh-trofs",
      "think": " \"Auto\" = self, \"troph\" = nourishment",
      "memoryTrick":
          "Picture a \"self-driving car\" that doesn’t need a driver to fuel it. Similarly, autotrophs don’t need to get food from other organisms—they make their own using sunlight!",
      "img": "https://gluta.s3.ap-south-1.amazonaws.com/sketchImage.png",
      "background": "https://gluta.s3.ap-south-1.amazonaws.com/autotrophs.webp"
    },
    {
      "id": "flashcard-2",
      "heading": "Heterotrophs",
      "definition":
          "Organisms that cannot make their own food. They depend on plants or other animals for nourishment. Examples include animals, most bacteria, and fungi.",
      "pronunciation": "heh-tuh-roh-trofs",
      "think": " \"Hetero\" = different, \"troph\" = nourishment",
      "memoryTrick":
          "Picture a \"hungry squirrel\" scavenging for nuts in a forest. It can’t make nuts on its own, so it must gather them from trees. This is what heterotrophs do—they get their food from different sources, instead of making it themselves!",
      "img": "https://gluta.s3.ap-south-1.amazonaws.com/sketchImage.png",
      "background": "https://gluta.s3.ap-south-1.amazonaws.com/autotrophs.webp"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          widget.conceptName,
          style: GoogleFonts.raleway(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      backgroundColor: Colors.black,
      body: FlashcardWidget(flashcards: flashcards),
    );
  }
}
