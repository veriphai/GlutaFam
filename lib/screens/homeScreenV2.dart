import 'package:eureka_app/screens/ncertPodcasts/chapterListingScreen.dart';
import 'package:flutter/material.dart';

class HomePageV2 extends StatelessWidget {
  final List<String> subjectList = ["Science", "Maths", "English", "History"];
  final List<Color> subjectColors = [
    Colors.blueAccent,
    Colors.green,
    Colors.redAccent,
    Colors.purpleAccent
  ];
  HomePageV2({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        elevation: 0,
        title: const Text("Fuel Your Curiosity",
            style: TextStyle(
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            )),
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.8,
            ),
            itemCount: subjectList.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Chapterscreen(),
                    ),
                  );
                },
                child: buildSubjectCard(subjectList[index], index),
              );
            }),
      ),
    );
  }

  Widget buildSubjectCard(String subject, int index) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: subjectColors[
          index % subjectColors.length], // Assign color based on index
      child: Center(
        // Center the text
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            subject,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white, // Text color set to white
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
