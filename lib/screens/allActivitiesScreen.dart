import 'package:flutter/material.dart';

class AllActivitiesScreen extends StatefulWidget {
  final String skillSubCategory;

  AllActivitiesScreen({Key? key, required this.skillSubCategory})
      : super(key: key);

  @override
  _AllActivitiesScreen createState() => _AllActivitiesScreen();
}

class _AllActivitiesScreen extends State<AllActivitiesScreen> {
  final List<Map<String, dynamic>> allActivities = [
    {
      "type": "ACTIVITY",
      "activityName": "The Quest for the Crystal Key",
      "id": "activity-1"
    },
    {
      "type": "ACTIVITY",
      "activityName": "Unlocking the Secrets of the Old Library",
      "id": "activity-2"
    },
    {
      "type": "ACTIVITY",
      "activityName": "Mystery of the Lost Map",
      "id": "activity-3"
    },
    {
      "type": "ACTIVITY",
      "activityName": "Challenge of the Sphinx",
      "id": "activity-4"
    }
  ];

  Widget buildActivityCard(Map<String, dynamic> activity) {
    return Card(
      margin: EdgeInsets.all(10),
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
        side: BorderSide(
            color: Color.fromRGBO(224, 224, 224, 1),
            width: 2.0), // Border color and width
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(activity['type'],
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Divider(
                color: Color.fromRGBO(224, 224, 224, 1),
              )),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child:
                Text(activity['activityName'], style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('All Activities: ${widget.skillSubCategory}'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: allActivities
              .map((activity) => buildActivityCard(activity))
              .toList(),
        ),
      ),
    );
  }
}
