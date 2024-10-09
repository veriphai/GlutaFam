import 'package:eureka_app/screens/homeScreen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChildGradeInputPage extends StatefulWidget {
  @override
  _ChildGradeInputPageState createState() => _ChildGradeInputPageState();
}

class _ChildGradeInputPageState extends State<ChildGradeInputPage> {
  List<String?> childGrades = [null];

  void addChild() {
    setState(() {
      childGrades.add(null); // Default grade when adding a new child
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 30.0, vertical: 10.0),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "What is your child's grade?",
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                      SizedBox(height: 60),
                      Image.asset(
                        'lib/assets/happy-kid.png',
                        scale: 1.5,
                      ),
                      ...childGrades.asMap().entries.map((entry) {
                        int index = entry.key;
                        String? selectedGrade = entry.value;
                        return Card(
                          elevation: 8.0,
                          margin: EdgeInsets.only(bottom: 10),
                          surfaceTintColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Text("Kid #${index + 1}",
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold)),
                                SizedBox(height: 4),
                                Text("Select the appropriate grade"),
                                SizedBox(height: 20),
                                DropdownButtonFormField<String>(
                                  value: selectedGrade,
                                  items: [
                                    '6th',
                                    '7th',
                                    '8th',
                                    '9th',
                                    '10th',
                                    '11th',
                                    '12th'
                                  ].map((grade) {
                                    return DropdownMenuItem<String>(
                                      value: grade,
                                      child: Text(grade),
                                    );
                                  }).toList(),
                                  onChanged: (newValue) {
                                    setState(() {
                                      childGrades[index] = newValue;
                                    });
                                  },
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.grey[200],
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    hintText: "Select grade",
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: ElevatedButton(
                          onPressed: addChild,
                          child: Text("Add Child"),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _buildNextButton(),
        ],
      ),
    );
  }

  Widget _buildNextButton() {
    return Padding(
      padding: EdgeInsets.all(20.0),
      child: ElevatedButton(
        onPressed: () {
          completeProfile();
        },
        child: Text('Get Started',
            style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          minimumSize: Size.fromHeight(50), // Set button height
          backgroundColor: Color.fromARGB(255, 249, 172, 57),
        ),
      ),
    );
  }

  Future<void> completeProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('firstLaunch', false);
    Navigator.pushReplacementNamed(context, '/home');
  }
}
