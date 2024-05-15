import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io' show Platform;
import 'dart:async';

class MoodTrackerScreen extends StatefulWidget {
  @override
  _MoodTrackerScreenState createState() => _MoodTrackerScreenState();
}

class _MoodTrackerScreenState extends State<MoodTrackerScreen> {
  final List<Map<String, dynamic>> emotionsList = [
    {"name": "Happy", "image": "lib/assets/happy.png"},
    {"name": "Sad", "image": "lib/assets/sad.png"},
    {"name": "Scared", "image": "lib/assets/scared.png"},
    {"name": "Worried", "image": "lib/assets/worried.png"},
    {"name": "Angry", "image": "lib/assets/angry.png"},
    {"name": "Tired", "image": "lib/assets/tired.png"},
    {"name": "Calm", "image": "lib/assets/calm.png"},
    {"name": "Silly", "image": "lib/assets/silly.png"},
    // {"name": "Confused", "image": "lib/assets/confused.png"},
    // {"name": "Sick", "image": "lib/assets/sick.png"}
  ];
  final Map<String, dynamic> instructions = {
    "heading": "How it works?",
    "subHeading":
        "App will guide you through step-by-step process, where you will:",
    "points": [
      {
        "heading": "Ask your child",
        "text": "'Think about how they are feeling inside?'"
      },
      {
        "heading": "Child picks and emotion",
        "text":
            "from the list of pictures, that is most similar to his/her mood."
      },
      {
        "heading": "Acknowledge child's feelings",
        "text":
            "e.g. 'Thats wonderful to hear that you are feeling calm right now!'"
      },
      {
        "heading": "Encourage to share more about his/her mood",
        "text": "e.g. 'Why might you feel this way?'"
      },
      {
        "heading": "Ask additionally",
        "text":
            "'If there's anything you'd like to talk about or share, I'm here to listen'"
      },
      {"heading": "Take Notes", "text": "Take notes for weekly summary."}
    ]
  };
  final Map<String, List<Map<String, dynamic>>> instructionsWrtEmotion = {
    "Happy": [
      {
        "heading": "Acknowledge feelings:",
        "points": [
          "Thats wonderful to hear that you are feeling happy!",
          "I am glad to hear that you're feeling happy",
          "Thats wonderful! I'm happy for you too."
        ]
      },
      {
        "heading": "Encourage to share more about his/her mood:",
        "points": [
          "Why might you feel this way!",
          "Would you like to share it with me?",
          "What happened that made you feel that way?"
        ]
      },
      {
        "heading": "Ask additionally:",
        "points": [
          "'If there's anything you would like to talk about or share, I'm here to listen'",
        ]
      }
    ],
    "Sad": [
      {
        "heading": "Acknowledge feelings:",
        "points": [
          "It is okay to feel sad sometimes.",
          "We all feel sad at times, and its important to talk about it.",
          "That can be really tough.",
          "I'm here for you, I love you, You are safe.",
          "I am here for a hug."
        ]
      },
      {
        "heading": "Encourage to share more about his/her mood:",
        "points": [
          "Why might you feel this way?",
          "Would you like to share it with me?",
          "What happened that made you feel that way?"
        ]
      },
      {
        "heading": "Ask additionally:",
        "points": [
          "'If there's anything you would like to talk about or share, I'm here to listen'",
        ]
      }
    ],
    "Scared": [
      {
        "heading": "Acknowledge feelings:",
        "points": [
          "This is really tough to feel this way.",
          "I am listening to you.",
          "I'm here for you, I love you, You are safe.",
        ]
      },
      {
        "heading": "Encourage to share more about his/her mood:",
        "points": [
          "Why might you feel this way?",
          "Would you like to share it with me?",
          "What happened that made you feel that way?"
        ]
      },
      {
        "heading": "Ask additionally:",
        "points": [
          "'If there's anything you would like to talk about or share, I'm here to listen'",
        ]
      }
    ],
    "Worried": [
      {
        "heading": "Acknowledge feelings:",
        "points": [
          "This is really tough to feel this way.",
          "I am listening to you.",
          "I'm here for you, I love you, You are safe.",
          "It sounds like you're worried about something. CAn you tell me more about what's been on your mind.",
          "Is there something specific that is bothering you?"
        ]
      },
      {
        "heading": "Encourage to share more about his/her mood:",
        "points": [
          "Why might you feel this way?",
          "Would you like to share it with me?",
          "What happened that made you feel that way?"
        ]
      },
      {
        "heading": "Ask additionally:",
        "points": [
          "'If there's anything you would like to talk about or share, I'm here to listen'",
        ]
      }
    ],
    "Angry": [
      {
        "heading": "Acknowledge feelings:",
        "points": [
          "This is really tough to feel this way.",
          "It's okay to feel angry sometimes. I have been there too."
              "I am listening to you.",
          "I'm here for you, I love you, You are safe.",
        ]
      },
      {
        "heading": "Encourage to share more about his/her mood:",
        "points": [
          "Why might you feel this way?",
          "Would you like to share it with me?",
          "What happened that made you feel that way?"
        ]
      },
      {
        "heading": "Ask additionally:",
        "points": [
          "'If there's anything you would like to talk about or share, I'm here to listen'",
        ]
      }
    ],
    "Tired": [
      {
        "heading": "Acknowledge feelings:",
        "points": [
          "I know how it feels to be tired. Our bodies need proper rest to be active all day."
              "This is really tough to feel this way.",
          "I am here for a hug."
        ]
      },
      {
        "heading": "Encourage to share more about his/her mood:",
        "points": [
          "Why might you feel this way?",
          "Would you like to share it with me?",
          "What happened that made you feel that way?"
        ]
      },
      {
        "heading": "Ask additionally:",
        "points": [
          "'If there's anything you would like to talk about or share, I'm here to listen'",
        ]
      }
    ],
    "Calm": [
      {
        "heading": "Acknowledge feelings:",
        "points": [
          "That's wonderful to hear that you are feeling calm.",
          "I am glad to hear that you are feeling calm.",
          "It's great that you feel calm right now.",
          "Feeling calm is a wonderful thing. It means that your mind and body are in a peaceful state, and it's good to take time to feel this way."
        ]
      },
      {
        "heading": "Encourage to share more about his/her mood:",
        "points": [
          "Why might you feel this way?",
          "Would you like to share it with me?",
          "What happened that made you feel that way?"
        ]
      },
      {
        "heading": "Ask additionally:",
        "points": [
          "'If there's anything you would like to talk about or share, I'm here to listen'",
        ]
      }
    ],
    "Silly": [
      {
        "heading": "Acknowledge feelings:",
        "points": [
          "That's wonderful to hear that you are feeling this way.",
        ]
      },
      {
        "heading": "Encourage to share more about his/her mood:",
        "points": [
          "Why might you feel this way?",
          "Would you like to share it with me?",
          "What happened that made you feel that way?"
        ]
      },
      {
        "heading": "Ask additionally:",
        "points": [
          "'If there's anything you would like to talk about or share, I'm here to listen'",
        ]
      }
    ],
  };
  final PageController _pageController = PageController();
  TimeOfDay? _selectedTime = TimeOfDay.now();
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  int _selectedEmojiIndex = -1;

  int currentImageIndex = 0;
  late Timer _timer; // Timer object to handle automatic image switching

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    var kolkata = tz.getLocation('Asia/Kolkata');
    tz.setLocalLocation(kolkata);
    var initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    var initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    flutterLocalNotificationsPlugin.initialize(initializationSettings);

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        currentImageIndex = (currentImageIndex + 1) % emotionsList.length;
      });
    });
  }

  @override
  void dispose() {
    _timer
        .cancel(); // Important to cancel the timer when the widget is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 10,
        // title: Text('Mood Tracker'),
        // automaticallyImplyLeading: false, // Removes back button
      ),
      body: PageView(
        controller: _pageController,
        physics: NeverScrollableScrollPhysics(), // Disables swipe to navigate
        children: [
          _buildHowItWorksPage(),
          _buildGreetingPage(),
          _buildEmojiSelectionPage(),
          _buildConfirmationPage(),
          _buildAdvicePage(),
          _buildSetupReminderPage()
        ],
      ),
    );
  }

  Widget _buildHowItWorksPage() {
    return SingleChildScrollView(
      child: Column(
        // crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 20.0, top: 40),
            child: Column(
              // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              // crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(instructions['heading'],
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.0),
                    child: Text(instructions['subHeading'],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold))),
                SizedBox(height: 16),
                ...instructions['points'].map<Widget>((point) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 15.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.network(
                          "https://gluta.s3.ap-south-1.amazonaws.com/interest-images/all-interests.png", // Example image URL
                          width: 40,
                          height: 40,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(point['heading'],
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20)),
                              Text(point['text']),
                            ],
                          ),
                        )
                      ],
                    ),
                  );
                }).toList(),
                SizedBox(
                  height: 20,
                ),
                ElevatedButton(
                  onPressed: () => _pageController.nextPage(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut),
                  child: Text('Begin Mood Tracking',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                      // minimumSize: Size.fromHeight(50), // Set button height
                      padding:
                          EdgeInsets.symmetric(horizontal: 50, vertical: 10),
                      backgroundColor: Color.fromARGB(255, 249, 172, 57)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGreetingPage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Hey!",
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
          SizedBox(height: 20),
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 30.0, vertical: 0),
              child: Text("Think about how you are feeling inside?",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold))),
          SizedBox(height: 30),
          Container(
              padding: EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color.fromARGB(255, 222, 240, 255)),
              child: Image.asset(emotionsList[currentImageIndex]['image'],
                  width: 100, height: 100)),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
                horizontal: 20.0, vertical: 30.0), // Optional for padding
            child: ElevatedButton(
              onPressed: () => _pageController.nextPage(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut),
              child: Text('Pick Your Mood',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                  // minimumSize: Size.fromHeight(50), // Set button height
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 10),
                  backgroundColor: Color.fromARGB(255, 249, 172, 57)),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 60.0, vertical: 10.0),
            child: Text(
              "allow your kid to pick a mood by themselves",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildEmojiSelectionPage() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(20.0),
          child: Text(
            "Pick your mood",
            style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          // Use Expanded to fill the remaining space with the GridView
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1,
              crossAxisSpacing: 0, // Adjust spacing if needed
              mainAxisSpacing: 0, // Adjust spacing if needed
            ),
            itemCount: emotionsList.length,
            itemBuilder: (BuildContext context, int index) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedEmojiIndex = index;
                  });
                  _pageController.nextPage(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut);
                },
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 40.0, vertical: 10.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(emotionsList[index]['image'],
                          width: 120, height: 120),
                      SizedBox(height: 10),
                      Text(emotionsList[index]['name'],
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold)),
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

  Widget _buildConfirmationPage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(40),
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color.fromRGBO(235, 107, 107, 0.2)),
            child: Image.asset(
                emotionsList[_selectedEmojiIndex == -1
                    ? 0
                    : _selectedEmojiIndex]['image'],
                width: 200,
                height: 200),
          ),
          SizedBox(
            height: 10,
          ),
          Text(
            emotionsList[_selectedEmojiIndex == -1 ? 0 : _selectedEmojiIndex]
                ['name'],
            style: TextStyle(fontSize: 36.0, fontWeight: FontWeight.bold),
          ),
          SizedBox(
            height: 20,
          ),
          Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: ElevatedButton(
                onPressed: () => _pageController.nextPage(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut),
                child: Text('Continue',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                    // minimumSize: Size.fromHeight(50), // Set button height
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 10),
                    backgroundColor: Color.fromARGB(255, 249, 172, 57)),
              )),
        ],
      ),
    );
  }

  Widget _buildAdvicePage() {
    List<Map<String, dynamic>> moodAdvice = _selectedEmojiIndex > -1
        ? instructionsWrtEmotion[emotionsList[_selectedEmojiIndex]['name']] ??
            []
        : [];

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Container(
                      alignment: Alignment.center,
                      child: Image.asset(
                        emotionsList[_selectedEmojiIndex == -1
                            ? 0
                            : _selectedEmojiIndex]['image'],
                        width: 70,
                        height: 70,
                      )),
                  SizedBox(height: 10),
                  Text(
                    "What Should You Do",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  ...List.generate(moodAdvice.length, (index) {
                    final advice = moodAdvice[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  advice['heading'],
                                  style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...advice['points'].map<Widget>((point) {
                          return Padding(
                            padding: EdgeInsets.symmetric(
                                vertical: 8.0, horizontal: 30.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("• ",
                                    style: TextStyle(
                                        fontSize: 20,
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold)),
                                Expanded(
                                  child: Text(
                                    point,
                                    style: TextStyle(fontSize: 18),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
          Container(
            // color: Colors.grey[200],
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Take notes (for later)",
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(
                  height: 10,
                ),
                TextField(
                  decoration: InputDecoration(
                      hintText: "Notes...",
                      fillColor: Color.fromRGBO(234, 234, 234, 0.5),
                      filled: true,
                      border: InputBorder.none
                      // border: OutlineInputBorder(),
                      ),
                  maxLines: 3,
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => _pageController.nextPage(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut),
                  child: Text("What's Next",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                      minimumSize: Size.fromHeight(50), // Set button height
                      padding:
                          EdgeInsets.symmetric(horizontal: 50, vertical: 10),
                      backgroundColor: Color.fromARGB(255, 249, 172, 57)),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSetupReminderPage() {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Setup Daily Reminder",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            ListTile(
              title: Text(
                  "Reminder Time: ${_selectedTime?.format(context) ?? 'Not set'}"),
              trailing: Icon(Icons.timer),
              onTap: _selectTime,
            ),
            SizedBox(height: 40),
            ElevatedButton(
                onPressed: () async {
                  await _requestPermissionsAndSchedule();
                },
                child: Text('Done!',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                    // minimumSize: Size.fromHeight(50), // Set button height
                    padding: EdgeInsets.symmetric(horizontal: 70, vertical: 10),
                    minimumSize: Size.fromHeight(50), // Set button height

                    backgroundColor: Color.fromARGB(255, 249, 172, 57))),
          ],
        ),
      ),
    );
  }

  void _selectTime() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (pickedTime != null && pickedTime != _selectedTime) {
      setState(() {
        _selectedTime = pickedTime;
      });
    }
  }

  Future<void> _requestPermissionsAndSchedule() async {
    if (Platform.isAndroid && await _androidVersionIsAtLeast12()) {
      final bool hasPermission = await flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>()
              ?.requestPermission() ??
          false;
      if (hasPermission) {
        print("scheduling reminder");

        scheduleDailyReminder();
      } else {
        print("error a day");

        // Optionally, handle the case when permission is not granted
      }
    } else {
      // For iOS or other platforms, directly schedule the reminder
      scheduleDailyReminder();
    }
  }

  Future<bool> _androidVersionIsAtLeast12() async {
    var deviceInfo = DeviceInfoPlugin();
    var androidInfo = await deviceInfo.androidInfo;
    return androidInfo.version.sdkInt >= 31;
  }

  void scheduleDailyReminder() {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    print("Current time: $now");
    print("Originally scheduled for: $scheduledDate");

    // If scheduled time is already passed for today, schedule for next day
    if (scheduledDate.isBefore(now)) {
      print("adding a day");
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    var androidDetails = AndroidNotificationDetails(
        'daily_reminder_id', 'daily_reminder_name',
        channelDescription: 'Daily mood tracker reminder',
        importance: Importance.max);
    var details = NotificationDetails(android: androidDetails);
    flutterLocalNotificationsPlugin.zonedSchedule(0, 'Mood Tracker Reminder',
        'Time to track your mood!', scheduledDate, details,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time);

    print("Test notification scheduled for: $scheduledDate");
    Navigator.pushReplacementNamed(context, '/home');
  }
}
