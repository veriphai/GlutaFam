import 'package:flutter/material.dart';

class ActivityScreen extends StatefulWidget {
  final String activityName;

  ActivityScreen({Key? key, required this.activityName}) : super(key: key);

  @override
  _ActivityScreen createState() => _ActivityScreen();
}

class _ActivityScreen extends State<ActivityScreen> {
  int currentSection = -1;
  bool isLastSection = false;
  List<Widget> sectionWidgets = [];
  final ScrollController _scrollController = ScrollController();

  final Map<String, dynamic> activityDetails = {
    "activityName": "The Quest for the Crystal Key",
    "softskillFramework": "Problem Solving",
    "objective":
        "To enhance the child's problem-solving abilities through a collaborative and creative storytelling exercise, while allowing the parent to understand the child's thought process and guide them in developing effective problem-solving strategies.",
    "activityOverview":
        "The parent and child will co-create a story about a character's quest to find a magical Crystal Key. Throughout the story, they will encounter various challenges that require problem-solving. The parent will guide the child using strategic nudges to think through the problems and come up with creative solutions.",
    "sections": [
      {
        "name": "Materials Needed",
        "contentType": "list",
        "content": [
          "A comfortable and quiet space to sit and discuss",
          "Paper and pencils for jotting down ideas and story elements",
          "A timer (optional, to add a sense of urgency to some parts of the activity)"
        ],
        "order": 1
      },
      {
        "name": "Setting the Scene",
        "contentType": "list",
        "content": [
          "The parent begins the story by setting the scene and introducing a main character who is on a quest to find the Crystal Key, which has the power to unlock a hidden treasure that can save their village from an impending problem (e.g., drought, darkness).",
          "Example: 'In the land of Solara, a brave young adventurer named Alex sets out on a quest to find the Crystal Key, the only object capable of unlocking the Well of Rain that can save their village from the unending drought.'"
        ],
        "order": 2
      },
      {
        "name": "Introducing the First Challenge",
        "contentType": "list",
        "content": [
          "After a few sentences, the parent introduces the first challenge. For example, Alex needs to cross a wide river to continue the quest but cannot swim.",
          "The parent then asks the child, 'What could Alex do to solve this problem?'"
        ],
        "order": 3
      },
      {
        "name": "Child's Turn to Solve",
        "contentType": "list",
        "content": [
          "The child suggests a solution to the problem. If they struggle, the parent can offer nudges like, 'What tools might Alex have?' or 'Is there anything in the environment that could help?'",
          "Example Nudge: 'Could Alex build something to help cross the river, or maybe there's someone nearby who could help?'"
        ],
        "order": 4
      },
      {
        "name": "Building on the Solution",
        "contentType": "list",
        "content": [
          "Once the child suggests a solution, the parent encourages them to elaborate on how Alex implements it. This reinforces the child's problem-solving process and allows them to think through the steps involved.",
          "Example: 'Alex decides to build a raft using logs tied together with vines. How does Alex find the materials needed?'"
        ],
        "order": 5
      },
      {
        "name": "Continuing the Story",
        "contentType": "list",
        "content": [
          "The parent continues the story, incorporating the child's solution and leading to the next challenge.",
          "Example: 'With the raft built, Alex manages to cross the river. But upon reaching the other side, they encounter a dense forest with paths leading in multiple directions. Which path should Alex choose?'"
        ],
        "order": 6
      },
      {
        "name": "Further Challenges and Solutions",
        "contentType": "list",
        "content": [
          "Repeat steps 2-5, introducing new challenges such as puzzles, riddles, or obstacles that require different problem-solving skills.",
          "Encourage the child to think about the consequences of each decision and to consider multiple solutions before deciding on the best one."
        ],
        "order": 7
      },
      {
        "name": "Concluding the Quest",
        "contentType": "list",
        "content": [
          "As the story nears its end, the parent guides the child to develop a final challenge that tests all the skills Alex has used throughout the quest.",
          "Together, they resolve the final challenge and describe how Alex finds and uses the Crystal Key to save the village."
        ],
        "order": 8
      },
      {
        "name": "Reflection",
        "contentType": "list",
        "content": [
          "After completing the story, the parent discusses with the child what they learned about problem-solving. They reflect on the different strategies used by Alex and how they can apply these strategies in real life.",
          "Example: 'What was the hardest problem Alex faced, and why do you think the solution worked? Can you think of a time when you solved a problem like Alex did?'"
        ],
        "order": 9
      },
      {
        "name": "Tips for Parents",
        "contentType": "list",
        "content": [
          "Encourage open-ended thinking and validate all suggestions, guiding the child to refine their ideas.",
          "Use prompts to help the child consider different perspectives and outcomes.",
          "Praise the child's creativity and problem-solving efforts throughout the activity.",
          "Keep the activity light-hearted and fun to maintain the child's interest and engagement."
        ],
        "order": 10
      }
    ]
  };

  void _nextSection() {
    setState(() {
      var sections = activityDetails['sections'] as List;
      if (currentSection < sections.length - 1) {
        currentSection++;
        sectionWidgets.add(_buildSectionContent(currentSection));
        if (currentSection == sections.length - 1) {
          isLastSection = true;
        }
      }
    });
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 600,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    }
  }

  Widget _buildSectionContent(int index) {
    var section = activityDetails['sections'][index];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.all(10.0), child: Divider()),
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(section['name'],
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        Padding(
            padding: const EdgeInsets.only(left: 25.0, right: 10.0),
            child: _renderSection(section))
      ],
    );
  }

  Widget _renderSection(Map<String, dynamic> section) {
    if (section['contentType'] == 'list') {
      return Column(
        children: List<Widget>.generate(section['content'].length, (index) {
          return ListTile(
            title:
                Text(section['content'][index], style: TextStyle(fontSize: 18)),
          );
        }),
      );
    }
    return SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.activityName),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Text(activityDetails['activityName'],
                  style: TextStyle(
                    fontSize: 24,
                    height: 2,
                    fontWeight: FontWeight.bold,
                  )),
            ),
            Padding(padding: const EdgeInsets.all(10.0), child: Divider()),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(activityDetails['activityOverview'],
                  style: TextStyle(fontSize: 18, height: 2)),
            ),
            ...sectionWidgets, // Spread operator to include all widgets
            if (!isLastSection)
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: ElevatedButton(
                    onPressed: _nextSection,
                    child: Text('Continue'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
