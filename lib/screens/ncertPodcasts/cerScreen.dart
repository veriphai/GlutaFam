import 'package:eureka_app/screens/ncertPodcasts/cerEvaluationScreen.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:async';

class CERPage extends StatefulWidget {
  final Map<String, dynamic> data;
  final String chapterId;

  const CERPage({
    Key? key,
    required this.data,
    required this.chapterId,
  }) : super(key: key);

  @override
  _CERPageState createState() => _CERPageState();
}

class _CERPageState extends State<CERPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? selectedClaim;
  Set<String> selectedEvidence = {};
  bool isClaimCompleted = false;
  bool isEvidenceCompleted = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    _tabController.addListener(() {
      if (_tabController.index == 1 && !isClaimCompleted) {
        Timer(Duration(milliseconds: 100), () {
          Fluttertoast.showToast(
            msg: "Please submit your claim before proceeding",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0,
          );
        });
        _tabController.animateTo(0);
      } else if (_tabController.index == 2 && !isEvidenceCompleted) {
        Timer(Duration(milliseconds: 100), () {
          Fluttertoast.showToast(
            msg: "Please submit your evidence before proceeding",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0,
          );
        });
        _tabController.animateTo(1);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        title: Text(
          "CER",
          style: const TextStyle(
            fontSize: 24,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Padding(
          //   padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
          //   child: Text(
          //     "Chapter 1: Crop Production and Management",
          //     style: const TextStyle(
          //       color: Colors.grey,
          //       fontSize: 14,
          //     ),
          //     maxLines: 3,
          //     overflow: TextOverflow.ellipsis,
          //   ),
          // ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
            child: Text(
              "Section 1: Seeds of Knowledge: Introduction to Crop Production",
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              widget.data['problemStatement'],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TabBar(
              controller: _tabController,
              indicatorColor: Color.fromRGBO(255, 217, 0, 1),
              indicatorWeight: 2.0,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey,
              labelStyle:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              unselectedLabelStyle:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
              tabs: const [
                Tab(text: 'Claim'),
                Tab(text: 'Evidence'),
                Tab(text: 'Reasoning'),
              ],
              dividerColor: Colors.transparent,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics:
                  NeverScrollableScrollPhysics(), // Disable swipe navigation

              children: [
                _buildClaimTab(),
                _buildEvidenceTab(),
                _buildReasoningTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClaimTab() {
    final options = widget.data['claimSelection']['options'] as List<dynamic>;
    final List<Color> claimColors = [
      Colors.blue,
      Color.fromRGBO(220, 21, 140, 1),
      Colors.green,
      Colors.purple,
    ];

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: options.length,
            itemBuilder: (context, index) {
              final option = options[index];
              final color = claimColors[index % claimColors.length];

              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedClaim = option['id'];
                      // isClaimCompleted = true; // Mark the claim as completed.
                    });
                  },
                  child: Card(
                    color: color,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 16, bottom: 16, top: 16, right: 30),
                          child: Text(
                            option['text'],
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                        if (selectedClaim == option['id'])
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.green,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: selectedClaim != null
                    ? () {
                        isClaimCompleted = true;
                        _tabController.animateTo(1);
                      }
                    : null, // Disable the button if no claim is selected
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.resolveWith<Color>(
                    (Set<MaterialState> states) {
                      if (states.contains(MaterialState.disabled)) {
                        return Colors.grey; // Color when the button is disabled
                      }
                      return Color.fromRGBO(
                          255, 217, 0, 1); // Color when the button is enabled
                    },
                  ),
                  shape: MaterialStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                child: const Text(
                  'Submit',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )),
        ),
      ],
    );
  }

  Widget _buildEvidenceTab() {
    final observations = widget.data['observations'] as List<dynamic>;
    final List<Color> evidenceColors = [
      Color.fromRGBO(220, 21, 140, 1),
      Colors.green,
      Colors.purple,
      Color.fromRGBO(71, 125, 148, 1),
      Colors.teal,
      Colors.red,
    ];

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: observations.length,
            itemBuilder: (context, index) {
              final observation = observations[index];
              final isSelected = selectedEvidence.contains(observation['id']);
              final color = evidenceColors[index % evidenceColors.length];

              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        selectedEvidence.remove(observation['id']);
                      } else {
                        selectedEvidence.add(observation['id']);
                      }
                    });
                  },
                  child: Card(
                    color: color,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 16, bottom: 16, top: 16, right: 30),
                          child: Text(
                            observation['text'],
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                        if (isSelected)
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.green,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: selectedEvidence.isNotEmpty
                    ? () {
                        isEvidenceCompleted = selectedEvidence.isNotEmpty;
                        _tabController
                            .animateTo(2); // Move to the "Reasoning" tab
                      }
                    : null, // Disable the button if no evidence is selected
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.resolveWith<Color>(
                    (Set<MaterialState> states) {
                      if (states.contains(MaterialState.disabled)) {
                        return Colors.grey; // Color when the button is disabled
                      }
                      return Color.fromRGBO(
                          255, 217, 0, 1); // Color when the button is enabled
                    },
                  ),
                  shape: MaterialStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                child: const Text(
                  'Submit',
                  style: TextStyle(color: Colors.black, fontSize: 16),
                ),
              )),
        ),
      ],
    );
  }

  Widget _buildReasoningTab() {
    final TextEditingController reasoningController = TextEditingController();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(4),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: reasoningController,
              maxLines: 5,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Write your reasoning here...',
                hintStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final userReasoning = reasoningController.text;
                final List<String> selectedEvidencesTexts = widget
                    .data['observations']
                    .where((observation) =>
                        selectedEvidence.contains(observation['id']))
                    .map<String>(
                        (observation) => observation['text'].toString())
                    .toList();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CEREvaluationScreen(
                        problemStatement: widget.data['problemStatement'],
                        selectedClaim: widget.data['claimSelection']['options'].firstWhere(
                            (option) => option['id'] == selectedClaim)['text'],
                        selectedEvidences: selectedEvidencesTexts,
                        studentReasoning: userReasoning,
                        correctClaim: widget.data['claimSelection']['options']
                                .firstWhere((option) => option['id'] == widget.data['claimSelection']['correctClaim'])[
                            'text'],
                        correctEvidences: widget.data['correctEvidences']
                            .map<String>((id) => widget.data['observations']
                                .firstWhere((observation) => observation['id'] == id)['text']
                                .toString())
                            .toList(),
                        correctReasoning: widget.data['reasoning'],
                        chapterId: widget.chapterId),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromRGBO(255, 217, 0, 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                // padding: const EdgeInsets.all(16),
              ),
              child: const Text(
                'Submit',
                style: TextStyle(color: Colors.black, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
