import 'package:eureka_app/screens/exploreSkillV2.dart';
import 'package:eureka_app/widgets/recommendedActivities.dart';
import 'package:flutter/material.dart';
import '../screens/exploreSkill.dart';

class SkillCard extends StatelessWidget {
  final String id;

  final String name;
  final String imageUrl;
  final BuildContext context;
  final Color colour;

  SkillCard(
      {required this.id,
      required this.name,
      required this.imageUrl,
      required this.context,
      required this.colour});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                SkillExplorationV2(skillName: name, skillId: id),
          ),
        );
      },
      child: Container(
        width: 130,
        // height: 150,
        child: Card(
          color: colour,
          elevation: 2,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
            // side: BorderSide(
            //   color: Color.fromRGBO(224, 224, 224, 1),
            //   width: 2.0,
            // ),
          ),
          clipBehavior: Clip
              .antiAlias, // Ensures the image does not bleed outside the border
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Image.network(
                imageUrl,
                width:
                    double.infinity, // Ensures the image covers the entire card
                height: double.infinity,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Center(child: Text('Could not load image'));
                },
              ),
              Container(
                // Dark overlay at the bottom of the card
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.9), Colors.transparent],
                  ),
                ),
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
