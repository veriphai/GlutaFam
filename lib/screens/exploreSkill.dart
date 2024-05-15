import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/widgets.dart';
import '../screens/activityScreen.dart';
import '../screens/allActivitiesScreen.dart';

class SkillExploration extends StatefulWidget {
  final String skillName; // Declare the variable in the StatefulWidget

  SkillExploration({Key? key, required this.skillName}) : super(key: key);

  @override
  _SkillExplorationState createState() => _SkillExplorationState();
}

class _SkillExplorationState extends State<SkillExploration> {
  final List<Map<String, dynamic>> recommended = [
    {
      "id": "card-1",
      "name": "What do Astronauts eat in space?",
      "type": "ACTIVITY",
      "ageGroup": "10-12",
      "skill": "Generating Solutions",
      "image":
          "https://gluta.s3.ap-south-1.amazonaws.com/lessonPlans/dropCool.png"
    },
    {
      "id": "card-2",
      "name":
          "Would you rather have a time machine to visit any historic era or a spaceship to explore new galaxies?",
      "type": "QUESTION",
      "ageGroup": "10-12",
      "skill": "Generating Solutions",
      "image":
          "https://gluta.s3.ap-south-1.amazonaws.com/lessonPlans/dropCool.png"
    },
    {
      "id": "card-4",
      "name":
          "Would you rather have a time machine to visit any historic era or a spaceship to explore new galaxies?",
      "type": "QUESTION",
      "ageGroup": "10-12",
      "skill": "Generating Solutions",
      "image":
          "https://gluta.s3.ap-south-1.amazonaws.com/lessonPlans/dropCool.png"
    }
  ];

  final List<Map<String, dynamic>> skillCategories = [
    {
      "id": "skill-1",
      "name": "Emotional Intelligence",
      "totalActivities": 12,
      "subCategories": [
        {
          "id": "skill-1",
          "name": "Emotion Charades",
          "totalActivities": 3,
          "image":
              "https://gluta.s3.ap-south-1.amazonaws.com/interest-images/all-interests.png"
        },
        {
          "id": "skill-2",
          "name": "Emotion Diary",
          "totalActivities": 5,
          "image":
              "https://gluta.s3.ap-south-1.amazonaws.com/interest-images/all-interests.png"
        },
        {
          "id": "skill-3",
          "name": "Role Playing",
          "totalActivities": 4,
          "image":
              "https://gluta.s3.ap-south-1.amazonaws.com/interest-images/all-interests.png"
        }
      ]
    },
    {
      "id": "skill-2",
      "name": " Leadership",
      "totalActivities": 5,
      "subCategories": [
        {
          "id": "skill-1",
          "name": "Vision Board Creation",
          "totalActivities": 1,
          "image":
              "https://gluta.s3.ap-south-1.amazonaws.com/interest-images/all-interests.png"
        },
        {
          "id": "skill-2",
          "name": "Goal-Setting Workshop",
          "totalActivities": 2,
          "image":
              "https://gluta.s3.ap-south-1.amazonaws.com/interest-images/all-interests.png"
        },
        {
          "id": "skill-3",
          "name": "Inspirational Talks",
          "totalActivities": 2,
          "image":
              "https://gluta.s3.ap-south-1.amazonaws.com/interest-images/all-interests.png"
        }
      ]
    }
  ];

  Color currentBackgroundColor =
      Color.fromRGBO(207, 87, 125, 1); // Default color

  // Function to change the background color
  void changeBackgroundColor(int index) {
    List<Color> colors = [
      Color.fromARGB(255, 143, 126, 82), // Example colors for different slides
      Color.fromRGBO(59, 128, 185, 1),
      Color.fromRGBO(79, 161, 82, 1),
      Color.fromRGBO(207, 87, 125, 1),
      Color.fromRGBO(170, 82, 186, 1),
    ];
    setState(() {
      currentBackgroundColor = colors[index % colors.length];
    });
  }

  @override
  Widget build(BuildContext context) {
    var screenHeight = MediaQuery.of(context).size.height;
    var carouselHeight = screenHeight * 0.7;
    return Scaffold(
        appBar: appBar(),
        backgroundColor: currentBackgroundColor,
        body: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 10),
              CarouselSlider(
                options: CarouselOptions(
                  height: carouselHeight,
                  enlargeCenterPage: true,
                  autoPlay: false,
                  onPageChanged: (index, reason) {
                    changeBackgroundColor(
                        index); // Change color on slide change
                  },
                ),
                items: recommended.map((activity) {
                  return Builder(
                    builder: (BuildContext context) {
                      return InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => ActivityScreen(
                                      activityName: activity['name'])),
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                                border: Border.all(
                                    width: 1.0,
                                    color: Color.fromRGBO(224, 224, 224, 1)),
                                borderRadius: BorderRadius.circular(15.0)),
                            child: Center(
                                child: Container(
                                    height: 100.0,
                                    child: Column(
                                      textDirection: TextDirection.ltr,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Container(
                                          // margin: EdgeInsets.only(
                                          //     top: 150.0, bottom: 10.0),
                                          child: Padding(
                                            padding: EdgeInsets.all(0.0),
                                            child: Text(
                                              '${activity['type']}',
                                              textAlign: TextAlign.left,
                                              style: TextStyle(
                                                  fontSize: 16.0,
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                        Divider(height: 1, thickness: 1),
                                        SizedBox(height: 10),
                                        Expanded(
                                          flex:
                                              2, // Adjust flex ratio to control space allocation between text and image
                                          child: Padding(
                                            padding: EdgeInsets.all(0.0),
                                            child: Text(
                                              '${activity['name']}',
                                              style: TextStyle(
                                                fontSize: 16.0,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ))),
                          ));
                    },
                  );
                }).toList(),
              ),
              SizedBox(height: 20),
              // buildSkillCategories()
            ],
          ),
        ));
  }

  Widget buildSkillCategories() {
    return Column(
      children: skillCategories
          .map((category) => buildCategoryCard(category))
          .toList(),
    );
  }

  Widget buildSubCategory(Map<String, dynamic> subCategory, bool last) {
    return InkWell(
        onTap: () {
          // Navigate to ActivityScreen when subcategory is tapped
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  AllActivitiesScreen(skillSubCategory: subCategory['name']),
            ),
          );
        },
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: Row(
                children: [
                  Image.network(subCategory['image'],
                      width: 100, height: 100, fit: BoxFit.cover),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 10),
                        Text(subCategory['name'],
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        Text("${subCategory['totalActivities']} Activities",
                            style: TextStyle(fontSize: 14)),
                        SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (!last)
              Divider(), // Only add a divider if it's not the last item
          ],
        ));
  }

  Widget buildCategoryCard(Map<String, dynamic> category) {
    List<Map<String, dynamic>> subCategories = category['subCategories'];
    return Card(
      margin: EdgeInsets.all(20.0),
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
        side: BorderSide(
            color: Color.fromRGBO(224, 224, 224, 1),
            width: 2.0), // Border color and width
      ),
      child: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(category['name'],
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text("${category['totalActivities']} Activities",
                    style: TextStyle(fontSize: 16)),
              ],
            ),
            Divider(),
            Column(
              children: List.generate(
                  subCategories.length,
                  (index) => buildSubCategory(
                      subCategories[index], index == subCategories.length - 1)),
            ),
          ],
        ),
      ),
    );
  }

  AppBar appBar() {
    return AppBar(
        backgroundColor: Colors.transparent,
        title: Text(widget.skillName,
            style: TextStyle(
                fontSize: 24.0,
                color: Colors.white,
                fontWeight: FontWeight.bold)));
  }
}
