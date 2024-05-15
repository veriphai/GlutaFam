import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class InterestLedScreen extends StatefulWidget {
  @override
  _InterestLedScreen createState() => _InterestLedScreen();
}

class _InterestLedScreen extends State<InterestLedScreen> {
  final List<Map<String, dynamic>> interestLedTopics = [
    {
      "id": "COF_Space_1711633145.6671305",
      "subject": "Science",
      "standard": 6,
      "chapterName": "Components of Food",
      "chapterNo": 1,
      "description":
          "The average length of an astronaut's mission is 182 days! But how do they get nutritions to stay healthy in space to survive this treacherous journey? ",
      "heroLine": "What do astronauts eat in space?",
      "primaryInterest": {
        "id": null,
        "name": "Space",
        "type": "PRIMARY",
        "imgUrl":
            "https://gluta.s3.ap-south-1.amazonaws.com/interest-images/music.svg"
      },
      "imgUrl":
          "https://gluta.s3.ap-south-1.amazonaws.com/lessonPlans/COF_Space.png",
      "classComponents": {
        "week": 1,
        "onlineClass": 2,
        "groupActivity": 1,
        "investigation": 1
      }
    },
    {
      "id": "COF_Sustainability_1711633145.66773",
      "subject": "Science",
      "standard": 6,
      "chapterName": "Components of Food",
      "chapterNo": 1,
      "description":
          "1% of the world population, and increasing, has taken a hard stance on not consuming animal products to avoid animal cruelty and global warming. But can plants alone provide the essential nutrients required by humans and why are humans omnivores?",
      "heroLine": "Settling the debate: Animal vs Plant-based Proteins.",
      "primaryInterest": {
        "id": null,
        "name": "Sustainability",
        "type": "PRIMARY",
        "imgUrl":
            "https://gluta.s3.ap-south-1.amazonaws.com/interest-images/music.svg"
      },
      "imgUrl":
          "https://gluta.s3.ap-south-1.amazonaws.com/lessonPlans/COF_Sustainability.png",
      "classComponents": {
        "week": 1,
        "onlineClass": 2,
        "groupActivity": 1,
        "investigation": 1
      }
    },
    {
      "id": "COF_Public Policy_1711633145.6681175",
      "subject": "Science",
      "standard": 6,
      "chapterName": "Components of Food",
      "chapterNo": 1,
      "description":
          "India ranks in the top 10 percentile of the world when it comes to child malnourishment. Malnourishment is a bane for a country and while the government has enforced a mid-day meal scheme across India, the quality of the meals in some areas remains questionable. let's Investigate.",
      "heroLine":
          "Mid-day meals: How does it impact the long-term health outcomes of our country?",
      "primaryInterest": {
        "id": null,
        "name": "Public Policy",
        "type": "PRIMARY",
        "imgUrl":
            "https://gluta.s3.ap-south-1.amazonaws.com/interest-images/music.svg"
      },
      "imgUrl":
          "https://gluta.s3.ap-south-1.amazonaws.com/lessonPlans/COF_PublicPolicy.png",
      "classComponents": {
        "week": 1,
        "onlineClass": 2,
        "groupActivity": 1,
        "investigation": 1
      }
    },
    {
      "id": "COF_Health_1711633145.6684186",
      "subject": "Science",
      "standard": 6,
      "chapterName": "Components of Food",
      "chapterNo": 1,
      "description":
          "Maggi vs Atta Maggi, Frooti vs Real Juice and many other brands today position themselves as a healthy choice but are these brands really healthy? How can we use nutritional labels to make healthier food choices?",
      "heroLine":
          "\"To eat or not to eat\": Why everyone should learn to read nutritional labels on packaged items.",
      "primaryInterest": {
        "id": null,
        "name": "Health",
        "type": "PRIMARY",
        "imgUrl":
            "https://gluta.s3.ap-south-1.amazonaws.com/interest-images/music.svg"
      },
      "imgUrl":
          "https://gluta.s3.ap-south-1.amazonaws.com/lessonPlans/COF_Health.png",
      "classComponents": {
        "week": 1,
        "onlineClass": 2,
        "groupActivity": 1,
        "investigation": 1
      }
    },
    {
      "id": "COF_Fantasy_1711633145.6686969",
      "subject": "Science",
      "standard": 6,
      "chapterName": "Components of Food",
      "chapterNo": 1,
      "description":
          "Ever wondered what Superman eats for breakfast or how The Flash fuels his speed? How can the nutritional needs of different superheroes teach us about the importance of a balanced diet?",
      "heroLine": "Super Diets for Super Heroes",
      "primaryInterest": {
        "id": null,
        "name": "Fantasy",
        "type": "PRIMARY",
        "imgUrl":
            "https://gluta.s3.ap-south-1.amazonaws.com/interest-images/music.svg"
      },
      "imgUrl":
          "https://gluta.s3.ap-south-1.amazonaws.com/lessonPlans/COF_Fantasy.png",
      "classComponents": {
        "week": 1,
        "onlineClass": 2,
        "groupActivity": 1,
        "investigation": 1
      }
    },
    {
      "id": "COF_Crisis Management_1711633145.672542",
      "subject": "Science",
      "standard": 6,
      "chapterName": "Components of Food",
      "chapterNo": 1,
      "description":
          "how your meal planning skills can become a lifeline in the aftermath of an earthquake, where nutrition and empathy become crucial.",
      "heroLine": "Emergency Eats: Meal Planning for Disaster Relief",
      "primaryInterest": {
        "id": null,
        "name": "Crisis Management",
        "type": "PRIMARY",
        "imgUrl":
            "https://gluta.s3.ap-south-1.amazonaws.com/interest-images/music.svg"
      },
      "imgUrl":
          "https://gluta.s3.ap-south-1.amazonaws.com/lessonPlans/COF_CrisisMgmt.png",
      "classComponents": {
        "week": 1,
        "onlineClass": 2,
        "groupActivity": 1,
        "investigation": 1
      }
    }
  ];
  Widget buildInterestLedCard(Map<String, dynamic> topic) {
    return Card(
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
          side: BorderSide(
              color: Color.fromRGBO(224, 224, 224, 1),
              width: 2.0), // Border color and width
        ),
        margin: EdgeInsets.all(8),
        child: InkWell(
            onTap: () async {
              final url =
                  Uri.parse("https://glutaclass.com/class/${topic['id']}");
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Could not launch $url")));
              }
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(
                        15.0), // Apply radius to the top-left corner
                    topRight: Radius.circular(
                        15.0), // Apply radius to the top-right corner
                  ),
                  child: Image.network(
                    topic['imgUrl'],
                    width: double
                        .infinity, // Image takes the full width of the card
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    "${topic['chapterName']}-X-${topic['primaryInterest']['name']}",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    topic['heroLine'],
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ),
                SizedBox(height: 20),
              ],
            )));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Interest-Led Topics'),
      ),
      body: ListView.builder(
        itemCount: interestLedTopics.length,
        itemBuilder: (context, index) {
          return buildInterestLedCard(interestLedTopics[index]);
        },
      ),
    );
  }
}
