import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class ProfileCreation extends StatefulWidget {
  @override
  _ProfileCreationState createState() => _ProfileCreationState();
}

class _ProfileCreationState extends State<ProfileCreation> {
  int currentPage = 1;
  Map<String, dynamic> inputs = {
    'name': '',
    'age': '',
    'mood': '',
    'school': '',
    'interests': '',
    'outcomes': [],
    'bondingOption': '',
    'timeForApp': ''
  };
  Map<int, Map<String, dynamic>> pages = {
    1: {
      'type': 'input',
      'question': 'What is your name? 🧑 👩',
      'helperText': 'Full name',
      'field': 'name',
      "image":
          "https://gluta.s3.ap-south-1.amazonaws.com/lessonPlans/dropCool.png"
    },
    2: {
      'type': 'options',
      'question': 'How would you like to bond? 🧑 👩',
      // 'helperText': 'Full name',
      'field': 'bondingOption',
      'options': [
        'Help in curriculum',
        'Discover Interests',
        'Develop Solft Skills',
        'DIY Activities'
      ],
      "image":
          "https://gluta.s3.ap-south-1.amazonaws.com/lessonPlans/dropCool.png"
    },
    3: {
      'type': 'multi-select',
      'question': 'What outcomes do you want from this app? 🧑 👩',
      // 'helperText': 'Full name',
      'field': 'outcomes',
      'options': [
        'Grow better bond',
        'Improved Life Outcomes',
        'Improved Academic Success',
        'Improved Social Skills',
        'Improved Cognitive Thinking'
      ],
      "image":
          "https://gluta.s3.ap-south-1.amazonaws.com/lessonPlans/dropCool.png"
    },
    4: {
      'type': 'options',
      'question': 'How much time can you give to your kid daily? 🧑 👩',
      // 'helperText': 'Full name',
      'field': 'timeForApp',
      'options': [
        '5 min / day',
        '10 min / day',
        '15 min / day',
        '30 min / day',
      ],
      "image":
          "https://gluta.s3.ap-south-1.amazonaws.com/lessonPlans/dropCool.png"
    },
  };

  void handleInputChange(String field, dynamic value,
      {bool isMultiSelect = false}) {
    setState(() {
      if (isMultiSelect) {
        List<dynamic> currentList = List.from(inputs[field]);
        if (currentList.contains(value)) {
          currentList.remove(value);
        } else {
          currentList.add(value);
        }
        inputs[field] = currentList;
      } else {
        inputs[field] = value;
      }
    });
  }

  void handleNext() {
    if (inputs[pages[currentPage]!['field']] != '') {
      if (currentPage < pages.length) {
        setState(() {
          currentPage++;
        });
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    }
  }

  void handlePrevious() {
    if (currentPage > 1) {
      setState(() {
        currentPage--;
      });
    }
  }

  Widget renderOptions(List<String> options, String field,
      {bool isMultiSelect = false}) {
    return Column(
      children: options.map((option) {
        bool isSelected = isMultiSelect
            ? inputs[field].contains(option)
            : inputs[field] == option;
        return Container(
          width: double
              .infinity, // Ensures the container takes all available horizontal space
          child: Row(
            children: [
              Expanded(
                child: isMultiSelect
                    ? FilterChip(
                        label: Align(
                          alignment:
                              Alignment.centerLeft, // Aligns text to the left
                          child: Text(option),
                        ),
                        selected: isSelected,
                        onSelected: (selected) => handleInputChange(
                            field, option,
                            isMultiSelect: true),
                        backgroundColor: isSelected
                            ? Color.fromRGBO(105, 73, 255, 0.08)
                            : Colors
                                .white, // Set background color based on selection
                        selectedColor: isSelected
                            ? Color.fromRGBO(105, 73, 255, 0.08)
                            : Colors.blue[100], // Set selected background color

                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                            side: BorderSide(
                                color: isSelected
                                    ? Color.fromRGBO(105, 73, 255, 0.08)
                                    : Color.fromRGBO(238, 238, 238, 1),
                                width: 4) // Custom border color and thickness
                            ),
                      )
                    : ChoiceChip(
                        label: Align(
                          alignment:
                              Alignment.centerLeft, // Aligns text to the left
                          child: Text(option),
                        ),
                        selected: isSelected,
                        onSelected: (selected) =>
                            handleInputChange(field, option),
                        backgroundColor: isSelected
                            ? Color.fromRGBO(105, 73, 255, 0.08)
                            : Colors
                                .white, // Set background color based on selection
                        selectedColor: isSelected
                            ? Color.fromRGBO(105, 73, 255, 0.08)
                            : Colors.blue[100], // Set selected background color

                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                                color: isSelected
                                    ? Color.fromRGBO(105, 73, 255, 1)
                                    : Colors.grey,
                                width: 2) // Custom border color and thickness
                            ),
                      ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget renderInputField() {
    final page = pages[currentPage]!;
    switch (page['type']) {
      case 'input':
      case 'numberInput':
        return TextField(
          onChanged: (value) => handleInputChange(page['field'], value),
          decoration: InputDecoration(hintText: page['helperText']),
        );
      case 'options':
      case 'multi-select':
        return renderOptions(page['options'], page['field']);
      default:
        return SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final page = pages[currentPage]!;
    return Scaffold(
      appBar: AppBar(
        leading:
            IconButton(icon: Icon(Icons.arrow_back), onPressed: handlePrevious),
        title: Padding(
          padding: const EdgeInsets.only(left: 20.0, right: 40.0),
          child: LinearProgressIndicator(
            value: currentPage / pages.length,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: <Widget>[
            Row(
              children: [
                Image.network(
                  page['image'],
                  width: 100,
                  height: 100,
                ),
                Flexible(
                  child: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.blue),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 5,
                          blurRadius: 7,
                          offset: Offset(0, 3),
                        )
                      ],
                    ),
                    child: Text(
                      page['question'],
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                )
              ],
            ),
            renderInputField(),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        surfaceTintColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton(
            onPressed: handleNext,
            child: Text('Continue'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color.fromRGBO(
                  105, 73, 255, 1), // Background color of the button
              foregroundColor: Colors.white,
              minimumSize:
                  Size(double.infinity, 50), // match_parent width, fixed height
            ),
          ),
        ),
      ),
    );
  }
}
