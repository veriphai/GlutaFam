import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chiclet/chiclet.dart';

class ConceptResultScreen extends StatelessWidget {
  final String conceptName;
  final int totalXp; // XP learned
  final String timeTaken; // Time taken
  final double accuracy; // Accuracy percentage

  const ConceptResultScreen({
    Key? key,
    required this.conceptName,
    required this.totalXp,
    required this.timeTaken,
    required this.accuracy,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          conceptName,
          style: GoogleFonts.raleway(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      backgroundColor: Colors.black,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Main Content
          Expanded(
              child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // GIF
              SizedBox(
                height: 200,
                width: 200,
                child: Image.network(
                  'https://media.giphy.com/media/5GoVLqeAOo6PK/giphy.gif', // Example GIF
                  fit: BoxFit.cover,
                ),
              ),

              // Lesson Completed Text
              const SizedBox(height: 30),
              Text(
                'Lesson Complete!',
                style: GoogleFonts.raleway(
                  color: Color.fromRGBO(255, 217, 0, 1),
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),

              // Tiles Row
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatTile(
                      context: context,
                      title: 'Total XP',
                      value: '$totalXp XP',
                      icon: Icons.star,
                      color: Colors.green,
                    ),
                    _buildStatTile(
                      context: context,
                      title: 'Time Taken',
                      value: timeTaken,
                      icon: Icons.timer,
                      color: Color.fromRGBO(255, 217, 0, 1),
                    ),
                    _buildStatTile(
                      context: context,
                      title: 'Accuracy',
                      value: '${accuracy.toStringAsFixed(1)}%',
                      icon: Icons.check_circle,
                      color: Colors.orange,
                    ),
                  ],
                ),
              ),
            ],
          )),

          // Button at the Bottom
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ChicletAnimatedButton(
              onPressed: () {
                Navigator.pop(context); // Go back to the chapter
              },
              buttonType: ChicletButtonTypes.roundedRectangle,
              height: 50,
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              buttonColor: const Color.fromRGBO(187, 160, 2, 1),
              backgroundColor: const Color.fromRGBO(255, 217, 0, 1),
              child: Text(
                'Back to Chapter',
                style: GoogleFonts.raleway(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title Container
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              width: double.infinity,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
              ),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.raleway(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Icon and Value
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  value,
                  style: GoogleFonts.arOneSans(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
