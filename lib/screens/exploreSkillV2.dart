import 'package:eureka_app/widgets/customBottomBar.dart';
import 'package:eureka_app/widgets/recommendedActivities.dart';
import 'package:flutter/material.dart';

class SkillExplorationV2 extends StatefulWidget {
  final String skillName;
  final String skillId;

  SkillExplorationV2({required this.skillName, required this.skillId});

  @override
  _SkillExplorationStateV2 createState() => _SkillExplorationStateV2();
}

class _SkillExplorationStateV2 extends State<SkillExplorationV2> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: appBar(),
        backgroundColor: Color.fromRGBO(59, 128, 185, 1),
        body: RecommendedActivities(widget.skillId),
        bottomNavigationBar: CustomBottomNavBar(
          currentIndex: 0,
        ));
  }

  AppBar appBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Text(
        widget.skillName,
        style: TextStyle(
            fontSize: 24.0, color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}
