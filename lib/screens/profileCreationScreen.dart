import 'package:eureka_app/widgets/childAgeInput.dart';
import 'package:eureka_app/widgets/childGradeInput.dart';
import 'package:flutter/material.dart';

class ProfileCreationScreen extends StatefulWidget {
  @override
  _ProfileCreationScreenState createState() => _ProfileCreationScreenState();
}

class _ProfileCreationScreenState extends State<ProfileCreationScreen> {
  final PageController _pageController = PageController();
  int _selectedUserRoleIndex = -1;
  int _selectedJobTypeIndex = -1;
  int _selectedHelpOptionIndex = -1;

  final List<Map<String, String>> userRoles = [
    {"name": "Mom", "image": "lib/assets/mother.png"},
    {"name": "Dad", "image": "lib/assets/father.png"},
    {"name": "Grandparents", "image": "lib/assets/grandparents.png"},
    {"name": "Siblings", "image": "lib/assets/siblings.png"},
    {"name": "Teachers", "image": "lib/assets/teachers.png"},
  ];

  final List<Map<String, String>> jobTypes = [
    {"name": "Full-time job", "image": "lib/assets/full-time.png"},
    {"name": "Part-time job", "image": "lib/assets/part-time.png"},
    {"name": "I'm a full-time parent", "image": "lib/assets/full-parent.png"},
    {"name": "Other", "image": "lib/assets/other.png"}
  ];

  final List<Map<String, String>> helpOptions = [
    {
      "name": "Master my kid’s soft skills",
      "image": "lib/assets/holderImg.png"
    },
    {
      "name": "⁠Parenting tips for behaviour management",
      "image": "lib/assets/holderImg.png"
    },
    {
      "name": "Understanding psyche of my child",
      "image": "lib/assets/holderImg.png"
    },
    {
      "name": "Spend more quality time with my child",
      "image": "lib/assets/holderImg.png"
    },
    {
      "name": "Activities and DIY activities for my child",
      "image": "lib/assets/holderImg.png"
    },
  ];

  final int _totalPages = 4;
  double _currentPageValue = 0.0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {
        _currentPageValue = _pageController.page!;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Padding(padding: const EdgeInsets.only(left: 30.0, right: 30.0)
              // child: _buildSegmentedProgressBar(),
              )),
      body: PageView(
        controller: _pageController,
        physics: NeverScrollableScrollPhysics(), // Disable swiping
        children: [
          // _buildFirstPage(),
          // _buildSecondPage(),
          // _buildThirdPage(),
          ChildGradeInputPage()
        ],
      ),
    );
  }

  Widget _buildSegmentedProgressBar() {
    int currentPage = (_currentPageValue + 1).round();
    return Container(
      height: 6.0,
      child: Row(
        children: List.generate(_totalPages, (index) {
          return Expanded(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 4.0),
              decoration: BoxDecoration(
                  color: index < currentPage
                      ? Color.fromARGB(255, 249, 172, 57)
                      : Colors.grey[300],
                  borderRadius: BorderRadius.circular(4)),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildFirstPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // SizedBox(
        //   height: 20,
        // ),
        _buildHeading('I am a :'),
        Expanded(
          child: _buildGrid(userRoles, _selectedUserRoleIndex, (index) {
            setState(() {
              _selectedUserRoleIndex = index;
            });
          }),
        ),
        _buildNextButton(_selectedUserRoleIndex != -1),
      ],
    );
  }

  Widget _buildSecondPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeading('How busy is your day?'),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 30.0),
          child: Text(
            'GlutaFam will adapt recommendations according to your schedule.',
            style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                color: Colors.grey),
          ),
        ),
        SizedBox(
          height: 10,
        ),
        Expanded(
          child: ListView.builder(
            itemCount: jobTypes.length,
            itemBuilder: (context, index) {
              return Container(
                  decoration: BoxDecoration(
                    color: _selectedJobTypeIndex == index
                        ? Color.fromARGB(255, 253, 200, 120)
                        : Color.fromARGB(255, 238, 238, 238),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  margin: EdgeInsets.symmetric(horizontal: 30, vertical: 5),
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: _buildListTile(
                      jobTypes[index], _selectedJobTypeIndex, index, () {
                    setState(() {
                      _selectedJobTypeIndex = index;
                    });
                  }));
            },
          ),
        ),
        _buildNextButton(_selectedJobTypeIndex != -1),
      ],
    );
  }

  Widget _buildThirdPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeading('How can GlutaFam help?'),
        Expanded(
          child: ListView.builder(
            itemCount: helpOptions.length,
            itemBuilder: (context, index) {
              return Container(
                  decoration: BoxDecoration(
                    color: _selectedHelpOptionIndex == index
                        ? Color.fromARGB(255, 253, 200, 120)
                        : Color.fromARGB(255, 238, 238, 238),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  margin: EdgeInsets.symmetric(horizontal: 30, vertical: 5),
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: _buildListTile(
                      helpOptions[index], _selectedHelpOptionIndex, index, () {
                    setState(() {
                      _selectedHelpOptionIndex = index;
                    });
                  }));
            },
          ),
        ),
        _buildNextButton(_selectedHelpOptionIndex != -1),
      ],
    );
  }

  Widget _buildHeading(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 30.0, vertical: 10),
      child: Text(
        text,
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildGrid(
      List<Map<String, String>> items, int selectedIndex, Function(int) onTap) {
    return GridView.builder(
      padding: EdgeInsets.symmetric(horizontal: 30),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            onTap(index);
          },
          child: Container(
            decoration: BoxDecoration(
              color: selectedIndex == index
                  ? Color.fromARGB(255, 253, 200, 120)
                  : Color.fromARGB(255, 238, 238, 238),
              // border: Border.all(
              //     color: selectedIndex == index
              //         ? Theme.of(context).primaryColor
              //         : Colors.grey,
              //     ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  items[index]['image']!,
                  width: 100,
                  height: 100,
                ),
                SizedBox(height: 10),
                Text(items[index]['name']!,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    )),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildListTile(Map<String, String> item, int selectedIndex, int index,
      Function() onTap) {
    return ListTile(
      leading: Image.asset(item['image']!, width: 50, height: 50),
      title: Text(
        item['name']!,
        style: TextStyle(
            fontSize: 20.0, fontWeight: FontWeight.bold, color: Colors.black),
      ),
      tileColor:
          selectedIndex == index ? Colors.grey.shade200 : Colors.transparent,
      onTap: onTap,
    );
  }

  Widget _buildNextButton(bool isSelected) {
    return Padding(
      padding: EdgeInsets.all(20.0),
      child: ElevatedButton(
        onPressed: isSelected
            ? () {
                _pageController.nextPage(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            : null, // Disable the button if no selection is made
        child: Text('Next',
            style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          minimumSize: Size.fromHeight(50), // Set button height
          backgroundColor: isSelected
              ? Color.fromARGB(255, 249, 172, 57)
              : Colors.grey, // Change color based on selection
        ),
      ),
    );
  }
}
