import 'package:eureka_app/screens/ncertPodcasts/cerScreen.dart';
import 'package:eureka_app/screens/ncertPodcasts/podcastScreen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'sectionsListingScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Chapterscreen extends StatefulWidget {
  final int standard = 8;

  const Chapterscreen({Key? key}) : super(key: key);

  @override
  _ChapterscreenState createState() => _ChapterscreenState();
}

class _ChapterscreenState extends State<Chapterscreen> {
  Set<String> bookmarkedChapters = {};
  int standard = 8; // Default standard
  List<dynamic> carouselData = [
    {
      "_id": "carousal_data_1",
      "title": "Interests",
      "type": "interest_led",
      "items": [
        {
          "_id": "interest_1",
          "name": "Technology",
          "image":
              "https://gluta.s3.ap-south-1.amazonaws.com/audio-podcasts/Class+8/Science/Chapter+1/Class8-Chapter1-Album.webp",
          "description": ""
        },
        {
          "_id": "interest_2",
          "name": "Space",
          "image":
              "https://gluta.s3.ap-south-1.amazonaws.com/audio-podcasts/Class+8/Science/Chapter+1/Class8-Chapter1-Album.webp",
          "description": ""
        },
        {
          "_id": "interest_3",
          "name": "Travelling",
          "image":
              "https://gluta.s3.ap-south-1.amazonaws.com/audio-podcasts/Class+8/Science/Chapter+1/Class8-Chapter1-Album.webp",
          "description": ""
        },
        {
          "_id": "interest_2",
          "name": "Space",
          "image":
              "https://gluta.s3.ap-south-1.amazonaws.com/audio-podcasts/Class+8/Science/Chapter+1/Class8-Chapter1-Album.webp",
          "description": ""
        },
        {
          "_id": "interest_2",
          "name": "Space",
          "image":
              "https://gluta.s3.ap-south-1.amazonaws.com/audio-podcasts/Class+8/Science/Chapter+1/Class8-Chapter1-Album.webp",
          "description": ""
        },
        {
          "_id": "interest_2",
          "name": "Space",
          "image":
              "https://gluta.s3.ap-south-1.amazonaws.com/audio-podcasts/Class+8/Science/Chapter+1/Class8-Chapter1-Album.webp",
          "description": ""
        },
        {
          "_id": "interest_2",
          "name": "Space",
          "image":
              "https://gluta.s3.ap-south-1.amazonaws.com/audio-podcasts/Class+8/Science/Chapter+1/Class8-Chapter1-Album.webp",
          "description": ""
        },
      ]
    },
    {
      "_id": "carousal_data_2",
      "title": "Scientists",
      "type": "scientist",
      "items": [
        {
          "_id": "scientist_1",
          "name": "Albert Einstein",
          "image":
              "https://gluta.s3.ap-south-1.amazonaws.com/audio-podcasts/Class+8/Science/Chapter+1/Class8-Chapter1-Album.webp",
          "description": ""
        },
        {
          "_id": "scientist_2",
          "name": "Sir Issac Newton",
          "image":
              "https://gluta.s3.ap-south-1.amazonaws.com/audio-podcasts/Class+8/Science/Chapter+1/Class8-Chapter1-Album.webp",
          "description": ""
        },
        {
          "_id": "scientist_3",
          "name": "Madam Curie",
          "image":
              "https://gluta.s3.ap-south-1.amazonaws.com/audio-podcasts/Class+8/Science/Chapter+1/Class8-Chapter1-Album.webp",
          "description": ""
        },
        {
          "_id": "scientist_3",
          "name": "Madam Curie",
          "image":
              "https://gluta.s3.ap-south-1.amazonaws.com/audio-podcasts/Class+8/Science/Chapter+1/Class8-Chapter1-Album.webp",
          "description": ""
        },
        {
          "_id": "scientist_3",
          "name": "Madam Curie",
          "image":
              "https://gluta.s3.ap-south-1.amazonaws.com/audio-podcasts/Class+8/Science/Chapter+1/Class8-Chapter1-Album.webp",
          "description": ""
        },
        {
          "_id": "scientist_3",
          "name": "Madam Curie",
          "image":
              "https://gluta.s3.ap-south-1.amazonaws.com/audio-podcasts/Class+8/Science/Chapter+1/Class8-Chapter1-Album.webp",
          "description": ""
        }
      ]
    },
    {
      "_id": "carousal_data_3",
      "title": "Episodes",
      "type": "episode",
      "items": [
        {
          "_id": "episode_1",
          "name": "Episode 1",
          "image":
              "https://gluta.s3.ap-south-1.amazonaws.com/audio-podcasts/Class+8/Science/Chapter+1/Class8-Chapter1-Album.webp",
          "description":
              "In the inaugural episode of \"The Learning Curve - by Glutaclass,\" host Jane welcomes guest Alex to explore the fundamentals of agriculture. They discuss Alex's experiences on his uncle's farm, the significance of crop production, the difference between Kharif and Rabi crops, and the essential role agriculture plays in feeding the population. This episode sets the stage for a deeper understanding of the various practices involved in crop production and management.",
          "chapterName": "Crop Production",
          "standard": 8,
          "subject": "Science",
          "audioUrl":
              "https://gluta.s3.ap-south-1.amazonaws.com/audio-podcasts/Class+8/Science/Chapter+1/Class8-Chapter1-1.mp3",
          "chapterId": "chapter_1",
          "chapterNo": 1,
          "cer": {
            "problemStatement":
                "Why are specific crops grown in different seasons?",
            "claimSelection": {
              "options": [
                {
                  "id": "option_1",
                  "text":
                      "The choice of crops depends mainly on soil type and has little to do with the season."
                },
                {
                  "id": "option_2",
                  "text":
                      "Crops are grown based on climate conditions like temperature, rainfall, and the season, which are crucial for their growth."
                },
                {
                  "id": "option_3",
                  "text":
                      "Any crop can be grown in any season if the soil is well prepared and fertilized."
                },
                {
                  "id": "option_4",
                  "text":
                      "Crops grow better when they are rotated frequently regardless of climate conditions."
                }
              ],
              "correctClaim": "option_2"
            },
            "observations": [
              {
                "id": "obs_1",
                "text":
                    "Kharif crops are sown with the onset of the monsoon and harvested by October, while Rabi crops are sown in winter and harvested in spring.",
                "relevanceScore": 9,
                "reasoning":
                    "This directly explains the dependence of crop types on seasonal conditions, supporting the claim."
              },
              {
                "id": "obs_2",
                "text":
                    "Paddy is grown in the rainy season because it requires a lot of water for growth.",
                "relevanceScore": 9,
                "reasoning":
                    "It provides a clear example of how climate conditions, like rainfall, are essential for certain crops, making it highly relevant."
              },
              {
                "id": "obs_3",
                "text":
                    "Farming tools like ploughs and sickles are used for various agricultural practices.",
                "relevanceScore": 5,
                "reasoning":
                    "This information is related to farming but less directly relevant to the claim about seasonal dependence of crops."
              },
              {
                "id": "obs_4",
                "text":
                    "Early humans transitioned from being hunters and gatherers to growing crops around 10,000 B.C.E., leading to settled communities.",
                "relevanceScore": 4,
                "reasoning":
                    "It provides historical context for agriculture but does not directly address the role of climate conditions in crop selection."
              },
              {
                "id": "obs_5",
                "text":
                    "Farming requires preparing soil, sowing, irrigation, adding fertilizers, and protecting crops from pests and weeds.",
                "relevanceScore": 7,
                "reasoning":
                    "It outlines essential agricultural practices, which is relevant but not as focused on seasonal factors."
              },
              {
                "id": "obs_6",
                "text":
                    "The success of agriculture depends on regular production, proper management, and effective food distribution.",
                "relevanceScore": 6,
                "reasoning":
                    "This is relevant to the broader concept of agriculture but not directly focused on the role of climate conditions."
              },
              {
                "id": "obs_7",
                "text":
                    "The birth of agriculture allowed the formation of societies and civilizations due to settled crop cultivation.",
                "relevanceScore": 4,
                "reasoning":
                    "It adds context but does not directly contribute to understanding the role of seasons in agriculture."
              },
              {
                "id": "obs_8",
                "text":
                    "Proper storage of harvested crops prevents food loss by protecting them from moisture and pests.",
                "relevanceScore": 6,
                "reasoning":
                    "While important to agriculture, this observation is not directly tied to the claim about seasonal crop growth."
              }
            ],
            "correctEvidences": ["obs_1", "obs_2"],
            "reasoning":
                "The choice of crops depends on the season, as different crops have varying requirements for temperature, rainfall, and humidity. Kharif crops are suited to the wet conditions of the monsoon, while Rabi crops grow well in cooler, drier winter conditions. These climate factors determine when and where specific crops can be grown. Understanding these seasonal dependencies allows farmers to plan their planting and harvesting cycles effectively, ensuring optimal growth and yield for each crop."
          }
        },
        {
          "_id": "episode_2",
          "name": "Episode 2",
          "image":
              "https://gluta.s3.ap-south-1.amazonaws.com/audio-podcasts/Class+8/Science/Chapter+1/Class8-Chapter1-Album.webp",
          "description":
              "In the inaugural episode of \"The Learning Curve - by Glutaclass,\" host Jane welcomes guest Alex to explore the fundamentals of agriculture. They discuss Alex's experiences on his uncle's farm, the significance of crop production, the difference between Kharif and Rabi crops, and the essential role agriculture plays in feeding the population. This episode sets the stage for a deeper understanding of the various practices involved in crop production and management.",
          "chapterName": "",
          "standard": 8,
          "subject": "Science",
          "chapterImage": "",
          "audioUrl": "",
          "cer": {
            "problemStatement":
                "Why are specific crops grown in different seasons?",
            "claimSelection": {
              "options": [
                {
                  "id": "option_1",
                  "text":
                      "The choice of crops depends mainly on soil type and has little to do with the season."
                },
                {
                  "id": "option_2",
                  "text":
                      "Crops are grown based on climate conditions like temperature, rainfall, and the season, which are crucial for their growth."
                },
                {
                  "id": "option_3",
                  "text":
                      "Any crop can be grown in any season if the soil is well prepared and fertilized."
                },
                {
                  "id": "option_4",
                  "text":
                      "Crops grow better when they are rotated frequently regardless of climate conditions."
                }
              ],
              "correctClaim": "option_2"
            },
            "observations": [
              {
                "id": "obs_1",
                "text":
                    "Kharif crops are sown with the onset of the monsoon and harvested by October, while Rabi crops are sown in winter and harvested in spring.",
                "relevanceScore": 9,
                "reasoning":
                    "This directly explains the dependence of crop types on seasonal conditions, supporting the claim."
              },
              {
                "id": "obs_2",
                "text":
                    "Paddy is grown in the rainy season because it requires a lot of water for growth.",
                "relevanceScore": 9,
                "reasoning":
                    "It provides a clear example of how climate conditions, like rainfall, are essential for certain crops, making it highly relevant."
              },
              {
                "id": "obs_3",
                "text":
                    "Farming tools like ploughs and sickles are used for various agricultural practices.",
                "relevanceScore": 5,
                "reasoning":
                    "This information is related to farming but less directly relevant to the claim about seasonal dependence of crops."
              },
              {
                "id": "obs_4",
                "text":
                    "Early humans transitioned from being hunters and gatherers to growing crops around 10,000 B.C.E., leading to settled communities.",
                "relevanceScore": 4,
                "reasoning":
                    "It provides historical context for agriculture but does not directly address the role of climate conditions in crop selection."
              },
              {
                "id": "obs_5",
                "text":
                    "Farming requires preparing soil, sowing, irrigation, adding fertilizers, and protecting crops from pests and weeds.",
                "relevanceScore": 7,
                "reasoning":
                    "It outlines essential agricultural practices, which is relevant but not as focused on seasonal factors."
              },
              {
                "id": "obs_6",
                "text":
                    "The success of agriculture depends on regular production, proper management, and effective food distribution.",
                "relevanceScore": 6,
                "reasoning":
                    "This is relevant to the broader concept of agriculture but not directly focused on the role of climate conditions."
              },
              {
                "id": "obs_7",
                "text":
                    "The birth of agriculture allowed the formation of societies and civilizations due to settled crop cultivation.",
                "relevanceScore": 4,
                "reasoning":
                    "It adds context but does not directly contribute to understanding the role of seasons in agriculture."
              },
              {
                "id": "obs_8",
                "text":
                    "Proper storage of harvested crops prevents food loss by protecting them from moisture and pests.",
                "relevanceScore": 6,
                "reasoning":
                    "While important to agriculture, this observation is not directly tied to the claim about seasonal crop growth."
              }
            ],
            "correctEvidences": ["obs_1", "obs_2"],
            "reasoning":
                "The choice of crops depends on the season, as different crops have varying requirements for temperature, rainfall, and humidity. Kharif crops are suited to the wet conditions of the monsoon, while Rabi crops grow well in cooler, drier winter conditions. These climate factors determine when and where specific crops can be grown. Understanding these seasonal dependencies allows farmers to plan their planting and harvesting cycles effectively, ensuring optimal growth and yield for each crop."
          }
        },
        {
          "_id": "episode_2",
          "name": "Episode 2",
          "image":
              "https://gluta.s3.ap-south-1.amazonaws.com/audio-podcasts/Class+8/Science/Chapter+1/Class8-Chapter1-Album.webp",
          "description":
              "In the inaugural episode of \"The Learning Curve - by Glutaclass,\" host Jane welcomes guest Alex to explore the fundamentals of agriculture. They discuss Alex's experiences on his uncle's farm, the significance of crop production, the difference between Kharif and Rabi crops, and the essential role agriculture plays in feeding the population. This episode sets the stage for a deeper understanding of the various practices involved in crop production and management.",
          "chapterName": "",
          "standard": 8,
          "subject": "Science",
          "chapterImage": "",
          "audioUrl": "",
          "cer": {
            "problemStatement":
                "Why are specific crops grown in different seasons?",
            "claimSelection": {
              "options": [
                {
                  "id": "option_1",
                  "text":
                      "The choice of crops depends mainly on soil type and has little to do with the season."
                },
                {
                  "id": "option_2",
                  "text":
                      "Crops are grown based on climate conditions like temperature, rainfall, and the season, which are crucial for their growth."
                },
                {
                  "id": "option_3",
                  "text":
                      "Any crop can be grown in any season if the soil is well prepared and fertilized."
                },
                {
                  "id": "option_4",
                  "text":
                      "Crops grow better when they are rotated frequently regardless of climate conditions."
                }
              ],
              "correctClaim": "option_2"
            },
            "observations": [
              {
                "id": "obs_1",
                "text":
                    "Kharif crops are sown with the onset of the monsoon and harvested by October, while Rabi crops are sown in winter and harvested in spring.",
                "relevanceScore": 9,
                "reasoning":
                    "This directly explains the dependence of crop types on seasonal conditions, supporting the claim."
              },
              {
                "id": "obs_2",
                "text":
                    "Paddy is grown in the rainy season because it requires a lot of water for growth.",
                "relevanceScore": 9,
                "reasoning":
                    "It provides a clear example of how climate conditions, like rainfall, are essential for certain crops, making it highly relevant."
              },
              {
                "id": "obs_3",
                "text":
                    "Farming tools like ploughs and sickles are used for various agricultural practices.",
                "relevanceScore": 5,
                "reasoning":
                    "This information is related to farming but less directly relevant to the claim about seasonal dependence of crops."
              },
              {
                "id": "obs_4",
                "text":
                    "Early humans transitioned from being hunters and gatherers to growing crops around 10,000 B.C.E., leading to settled communities.",
                "relevanceScore": 4,
                "reasoning":
                    "It provides historical context for agriculture but does not directly address the role of climate conditions in crop selection."
              },
              {
                "id": "obs_5",
                "text":
                    "Farming requires preparing soil, sowing, irrigation, adding fertilizers, and protecting crops from pests and weeds.",
                "relevanceScore": 7,
                "reasoning":
                    "It outlines essential agricultural practices, which is relevant but not as focused on seasonal factors."
              },
              {
                "id": "obs_6",
                "text":
                    "The success of agriculture depends on regular production, proper management, and effective food distribution.",
                "relevanceScore": 6,
                "reasoning":
                    "This is relevant to the broader concept of agriculture but not directly focused on the role of climate conditions."
              },
              {
                "id": "obs_7",
                "text":
                    "The birth of agriculture allowed the formation of societies and civilizations due to settled crop cultivation.",
                "relevanceScore": 4,
                "reasoning":
                    "It adds context but does not directly contribute to understanding the role of seasons in agriculture."
              },
              {
                "id": "obs_8",
                "text":
                    "Proper storage of harvested crops prevents food loss by protecting them from moisture and pests.",
                "relevanceScore": 6,
                "reasoning":
                    "While important to agriculture, this observation is not directly tied to the claim about seasonal crop growth."
              }
            ],
            "correctEvidences": ["obs_1", "obs_2"],
            "reasoning":
                "The choice of crops depends on the season, as different crops have varying requirements for temperature, rainfall, and humidity. Kharif crops are suited to the wet conditions of the monsoon, while Rabi crops grow well in cooler, drier winter conditions. These climate factors determine when and where specific crops can be grown. Understanding these seasonal dependencies allows farmers to plan their planting and harvesting cycles effectively, ensuring optimal growth and yield for each crop."
          }
        },
        {
          "_id": "episode_2",
          "name": "Episode 2",
          "image":
              "https://gluta.s3.ap-south-1.amazonaws.com/audio-podcasts/Class+8/Science/Chapter+1/Class8-Chapter1-Album.webp",
          "description":
              "In the inaugural episode of \"The Learning Curve - by Glutaclass,\" host Jane welcomes guest Alex to explore the fundamentals of agriculture. They discuss Alex's experiences on his uncle's farm, the significance of crop production, the difference between Kharif and Rabi crops, and the essential role agriculture plays in feeding the population. This episode sets the stage for a deeper understanding of the various practices involved in crop production and management.",
          "chapterName": "",
          "standard": 8,
          "subject": "Science",
          "chapterImage": "",
          "audioUrl": "",
          "cer": {}
        },
        {
          "_id": "episode_2",
          "name": "Episode 2",
          "image":
              "https://gluta.s3.ap-south-1.amazonaws.com/audio-podcasts/Class+8/Science/Chapter+1/Class8-Chapter1-Album.webp",
          "description":
              "In the inaugural episode of \"The Learning Curve - by Glutaclass,\" host Jane welcomes guest Alex to explore the fundamentals of agriculture. They discuss Alex's experiences on his uncle's farm, the significance of crop production, the difference between Kharif and Rabi crops, and the essential role agriculture plays in feeding the population. This episode sets the stage for a deeper understanding of the various practices involved in crop production and management.",
          "chapterName": "",
          "standard": 8,
          "subject": "Science",
          "chapterImage": "",
          "audioUrl": "",
          "cer": {}
        },
        {
          "_id": "episode_2",
          "name": "Episode 2",
          "image":
              "https://gluta.s3.ap-south-1.amazonaws.com/audio-podcasts/Class+8/Science/Chapter+1/Class8-Chapter1-Album.webp",
          "description":
              "In the inaugural episode of \"The Learning Curve - by Glutaclass,\" host Jane welcomes guest Alex to explore the fundamentals of agriculture. They discuss Alex's experiences on his uncle's farm, the significance of crop production, the difference between Kharif and Rabi crops, and the essential role agriculture plays in feeding the population. This episode sets the stage for a deeper understanding of the various practices involved in crop production and management.",
          "chapterName": "",
          "standard": 8,
          "subject": "Science",
          "chapterImage": "",
          "audioUrl": "",
          "cer": {}
        }
      ]
    }
  ];

  Map<String, List<Map<String, dynamic>>> subjectChapters = {
    'Science': [],
    'Maths': [],
    'History': [],
    'Geography': [],
  };

  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _loadSelectedClass(); // Fetch the selected class before fetching chapters
  }

  // Fetch the selected class from SharedPreferences
  Future<void> _loadSelectedClass() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      standard = prefs.getInt('selected_class') ??
          8; // Default to class 8 if not found
      print(standard);
    });
    // Now that the standard is loaded, fetch the chapters
    fetchAllChapters();
  }

  Future<void> fetchAllChapters() async {
    try {
      // Fetch chapters for each subject
      await Future.wait([
        fetchChapterList('Science'),
        fetchChapterList('Maths'),
        fetchChapterList('History'),
        fetchChapterList('Geography'),
      ]);
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        hasError = true;
      });
    }
  }

  Future<void> fetchChapterList(String subject) async {
    final String url =
        'https://glutaclass.com:8080/gluta/fam/chapters?subject=$subject&standard=$standard';

    try {
      print("Fetching data for $subject from API: $url");

      final response = await http.get(Uri.parse(url));
      print("response for $subject: $response");

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        List<Map<String, dynamic>> sortedChapters = data
            .map((e) => e as Map<String, dynamic>)
            .toList()
          ..sort((a, b) => a['chapterNo'].compareTo(b['chapterNo']));

        setState(() {
          subjectChapters[subject] = sortedChapters;
        });
      } else {
        setState(() {
          hasError = true;
        });
      }
    } catch (e) {
      setState(() {
        hasError = true;
      });
    }
  }

  // Function to open the bottom sheet for class selection
  void _showClassSelectionBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(6, (index) {
              int classNumber = index + 5;

              return Column(
                children: [
                  ListTile(
                    title: Text(
                      'Class $classNumber',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: classNumber == standard
                            ? Color.fromRGBO(255, 217, 0, 1)
                            : Colors.white,
                      ),
                    ),
                    onTap: () async {
                      // Update selected class and refresh chapter list
                      // SharedPreferences prefs =
                      //     await SharedPreferences.getInstance();
                      // await prefs.setInt('selected_class', classNumber);

                      setState(() {
                        standard = classNumber;
                        isLoading = true;
                      });

                      // Fetch updated chapters for the new class
                      fetchAllChapters();

                      // Close the bottom sheet
                      Navigator.pop(context);
                    },
                  ),
                  if (index < 5)
                    Divider(
                        color: Colors.grey[800]), // Divider between ListTiles
                ],
              );
            }),
          ),
        );
      },
    );
  }

  // Fetch carousel data from API
  Future<void> fetchCarouselData() async {
    final String url =
        'https://your-api-url.com/carousal-data'; // Replace with your actual API URL
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          carouselData = json.decode(response.body);
        });
      } else {
        setState(() {
          hasError = true;
        });
      }
    } catch (e) {
      setState(() {
        hasError = true;
      });
    }
  }

  // Carousel Widget for Interest and Scientist
  Widget buildCarousel(String title, List<dynamic> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Container(
                  width:
                      100, // Fixed width for each item to maintain consistent spacing
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Circular container for the image
                      ClipOval(
                        child: Image.network(
                          item['image'],
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Name of the item (Scientist or Interest)
                      Text(
                        item['name'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1, // Ensures single line for the name
                        overflow:
                            TextOverflow.ellipsis, // Truncates if too long
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget buildEpisodeCarousel(List<dynamic> episodes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Episodes',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 230, // Adjust the height of the card
          child: PageView.builder(
            controller:
                PageController(viewportFraction: 0.9), // Adjusts the page view
            itemCount: episodes.length,
            itemBuilder: (context, index) {
              final episode = episodes[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0.0),
                child: Transform.translate(
                  offset: Offset(
                      -20, 0), // Slight offset to ensure center alignment
                  child: buildEpisodeCard(episode, index),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget buildEpisodeCard(Map<String, dynamic> episode, int index) {
    // Define a list of gradients to use for the background of the cards.
    final List<LinearGradient> gradients = [
      LinearGradient(
        colors: [Colors.blueGrey[900]!, Colors.blueGrey[700]!],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      LinearGradient(
        colors: [Colors.deepPurple[900]!, Colors.deepPurple[700]!],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      LinearGradient(
        colors: [Colors.teal[900]!, Colors.teal[700]!],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      // LinearGradient(
      //   colors: [Colors.orange[900]!, Colors.orange[700]!],
      //   begin: Alignment.topLeft,
      //   end: Alignment.bottomRight,
      // ),
      LinearGradient(
        colors: [Colors.brown[900]!, Colors.brown[700]!],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      LinearGradient(
        colors: [Colors.indigo[900]!, Colors.indigo[700]!],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ];

    // Choose a gradient based on the index.
    final cardBackgroundGradient = gradients[index % gradients.length];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PodcastScreen(
              title: episode['name'],
              description: episode['description'] ?? "No description available",
              imageUrl: episode['image'],
              audioUrl: episode['audioUrl'] ?? "",
              duration: episode['timeToComplete'] ?? 20,
              chapterName: episode['chapterName'],
              chapterNo: episode['chapterNo'],
              cerData: episode['cer'] ?? <String, dynamic>{},
              chapterId: episode['chapterId'],
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            width: 300, // Set the width to 90% of the available width
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: cardBackgroundGradient, // Set the gradient background
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Episode image and name
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          episode['image'], // Replace with your image URL field
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Flexible(
                        child: Text(
                          episode[
                              'name'], // Replace with your episode name field
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Description
                  Text(
                    episode['description'] ?? 'No description available',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[200],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),

                  // Time and action buttons row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.bookmark_outline,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            // Handle bookmark functionality
                          },
                        ),
                        // Share Button
                        IconButton(
                          icon: const Icon(
                            Icons.share_outlined,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            // Handle share functionality
                          },
                        ),
                        const Spacer(flex: 1),

                        // "Go to Case" Button (if CER data exists)
                        if (episode['cer'] != null && episode['cer'].isNotEmpty)
                          TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor:
                                  const Color.fromRGBO(255, 217, 0, 1),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              minimumSize: const Size(20, 20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CERPage(
                                    data: episode['cer'],
                                    chapterId: episode['chapterId'],
                                  ),
                                ),
                              );
                            },
                            child: const Text(
                              'Go to Case',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 12,
                              ),
                            ),
                          ),

                        // Play Button
                        IconButton(
                          icon: const Icon(
                            Icons.play_circle_fill,
                            color: Color.fromRGBO(255, 217, 0, 1),
                            size: 40,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PodcastScreen(
                                  title: episode['name'],
                                  description: episode['description'] ??
                                      "No description available",
                                  imageUrl: episode['image'],
                                  audioUrl: episode['audioUrl'] ?? "",
                                  duration: episode['timeToComplete'] ?? 20,
                                  chapterName: episode['chapterName'],
                                  chapterNo: episode['chapterNo'],
                                  cerData:
                                      episode['cer'] ?? <String, dynamic>{},
                                  chapterId: episode['chapterId'],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : hasError
                ? Center(
                    child: Text(
                      'Failed to load chapters',
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildChapterContent(),
                        const SizedBox(height: 20),
                        // Iterate over carousel data and create carousel for "interest_led" and "scientist"
                        ...carouselData.map((carousel) {
                          if (carousel['type'] == 'interest_led' ||
                              carousel['type'] == 'scientist') {
                            return buildCarousel(
                                carousel['title'], carousel['items']);
                          } else if (carousel['type'] == 'episode') {
                            return buildEpisodeCarousel(carousel['items']);
                          }
                          return SizedBox
                              .shrink(); // In case the type doesn't match anything
                        }).toList(),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildChapterContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: subjectChapters.keys.map((subject) {
        final chapters = subjectChapters[subject] ?? [];
        if (chapters.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                subject,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 350, // Giving a constrained height to the PageView
              child: PageView.builder(
                controller: PageController(viewportFraction: 0.9),
                itemCount: (chapters.length / 4).ceil(),
                itemBuilder: (context, pageIndex) {
                  final pageChapters =
                      chapters.skip(pageIndex * 4).take(4).toList();
                  return Transform.translate(
                    offset: Offset(-16, 0),
                    child: ListView.builder(
                      shrinkWrap: true, // Ensures height does not overflow
                      physics:
                          NeverScrollableScrollPhysics(), // Disable scrolling in this ListView
                      itemCount: pageChapters.length,
                      itemBuilder: (context, index) {
                        final chapter = pageChapters[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Sectionscreen(
                                  chapterId: chapter['id'],
                                ),
                              ),
                            );
                          },
                          child: _buildChapterItem(chapter),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        );
      }).toList(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false,
      elevation: 0,
      title: const Text("GlutaClass",
          style: TextStyle(
            fontSize: 24,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          )),
      actions: [
        // Display selected class on the right side of the app bar
        TextButton(
          onPressed: _showClassSelectionBottomSheet, // Open bottom sheet
          child: Row(
            children: [
              Text(
                'Class $standard',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
              const Icon(Icons.arrow_drop_down, color: Colors.white),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChapterItem(Map<String, dynamic> chapter) {
    return Card(
      color: Colors.transparent,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                chapter['image'],
                fit: BoxFit.cover,
                width: 60,
                height: 60,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chapter['name'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Chapter ${chapter['chapterNo']} • ${chapter['sections'].length} Sections • ${chapter['timeToComplete']} mins",
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(
                Icons.more_vert,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () {
                _showBottomSheet(context, chapter);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showBottomSheet(BuildContext context, Map<String, dynamic> chapter) {
    bool isBookmarked = bookmarkedChapters.contains(chapter['id']);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    chapter['image'],
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
                title: Text(
                  chapter['name'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  "Chapter ${chapter['chapterNo']} • ${chapter['sections'].length} Sections • ${chapter['timeToComplete']} mins",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Divider(color: Colors.grey),
              ListTile(
                leading: Icon(Icons.play_circle_outline_rounded,
                    color: Colors.white),
                title: Text(
                  "Go To Chapter",
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Sectionscreen(
                        chapterId: chapter['id'],
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(
                  isBookmarked
                      ? Icons.bookmark
                      : Icons
                          .bookmark_outline, // Toggle between outline and filled
                  color: Colors.white,
                ),
                title: Text(
                  isBookmarked ? "Bookmarked" : "Bookmark",
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  setState(() {
                    if (isBookmarked) {
                      bookmarkedChapters.remove(chapter['id']);
                    } else {
                      bookmarkedChapters.add(chapter['id']);
                    }
                  });
                  Navigator.pop(context); // Close the bottom sheet
                },
              ),
              // ListTile(
              //   leading: Icon(Icons.share_outlined, color: Colors.white),
              //   title: Text(
              //     "Share",
              //     style: TextStyle(color: Colors.white),
              //   ),
              //   onTap: () {
              //     Navigator.pop(context);
              //     // Handle Share Action
              //   },
              // ),
            ],
          ),
        );
      },
    );
  }
}
