import 'package:eureka_app/screens/homeScreen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChildAgeInputPage extends StatefulWidget {
  @override
  _ChildAgeInputPageState createState() => _ChildAgeInputPageState();
}

class _ChildAgeInputPageState extends State<ChildAgeInputPage> {
  List<int> childAges = [5];

  void addChild() {
    setState(() {
      childAges.add(5); // Default age when adding a new child
    });
  }

  void incrementAge(int index) {
    setState(() {
      if (childAges[index] < 18) {
        childAges[index]++;
      }
    });
  }

  void decrementAge(int index) {
    setState(() {
      if (childAges[index] > 0) {
        childAges[index]--;
      }
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
                          child: Text("How old is your kid?",
                              style: TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold))),
                      SizedBox(
                        height: 60,
                      ),
                      Image.asset(
                        'lib/assets/happy-kid.png',
                        scale: 1.5,
                      ),
                      ...childAges.asMap().entries.map((entry) {
                        int index = entry.key;
                        int age = entry.value;
                        return Card(
                          elevation: 8.0,
                          margin: EdgeInsets.only(bottom: 10),
                          surfaceTintColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            // side: BorderSide(
                            //   color: const Color.fromARGB(
                            //       255, 221, 221, 221), // Set border color
                            //   width: 1.0, // Set border width
                            // ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Text("Kid #${index + 1}",
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold)),
                                SizedBox(
                                  height: 4,
                                ),
                                Text("works best for kid above 5"),
                                SizedBox(
                                  height: 20,
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                        padding: EdgeInsets.all(5),
                                        decoration: BoxDecoration(
                                            color: Color.fromARGB(
                                                255, 253, 200, 120),
                                            borderRadius: BorderRadius.only(
                                                topLeft: Radius.circular(10),
                                                bottomLeft:
                                                    Radius.circular(10))),
                                        child: IconButton(
                                          icon: Icon(Icons.remove),
                                          onPressed: () => decrementAge(index),
                                        )),
                                    Card(
                                        elevation: 8.0,
                                        margin: EdgeInsets.only(bottom: 10),
                                        surfaceTintColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          // side: BorderSide(
                                          //   color: const Color.fromARGB(
                                          //       255, 221, 221, 221), // Set border color
                                          //   width: 1.0, // Set border width
                                          // ),
                                        ),
                                        child: Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 30, vertical: 10),
                                            child: Column(children: [
                                              Text("$age",
                                                  style: TextStyle(
                                                      fontSize: 48,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Color.fromARGB(
                                                          255, 253, 200, 120))),
                                              Text("years old",
                                                  style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Color.fromARGB(
                                                          255, 253, 200, 120)))
                                            ]))),
                                    Container(
                                        padding: EdgeInsets.all(5),
                                        decoration: BoxDecoration(
                                            color: Color.fromARGB(
                                                255, 253, 200, 120),
                                            borderRadius: BorderRadius.only(
                                                topRight: Radius.circular(10),
                                                bottomRight:
                                                    Radius.circular(10))),
                                        child: IconButton(
                                          icon: Icon(Icons.add),
                                          onPressed: () => incrementAge(index),
                                        )),
                                  ],
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
            backgroundColor: Color.fromARGB(255, 249, 172, 57)),
      ),
    );
  }

  Future<void> completeProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('firstLaunch', false);
    Navigator.pushReplacementNamed(context, '/home');
  }
}
