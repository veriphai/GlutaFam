import 'package:chiclet/chiclet.dart';
import 'package:eureka_app/apis/fetchAiTeachers.dart';
import 'package:eureka_app/utils/avatars.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

class AITeacherSelection extends StatefulWidget {
  final String? initialAITeacherSelected;
  final List<Map<String, dynamic>> aiTeachers;
  final void Function(Map<String, dynamic> selectedTeacher)? onSelectionChanged;

  const AITeacherSelection(
      {Key? key,
      this.initialAITeacherSelected,
      this.onSelectionChanged,
      required this.aiTeachers})
      : super(key: key);

  @override
  _AITeacherSelectionState createState() => _AITeacherSelectionState();
}

class _AITeacherSelectionState extends State<AITeacherSelection> {
  String? selectedTeacherId;
  List<Map<String, dynamic>> aiTeachers = [];
  bool isLoading = true;

  Future<void> getAITeachers() async {
    try {
      // final aiTeachersData = await fetchAITeachers();
      setState(() {
        aiTeachers = widget.aiTeachers;
        selectedTeacherId = widget.initialAITeacherSelected ??
            (aiTeachers.isNotEmpty ? aiTeachers[0]["id"] : null);
        isLoading = false;
      });
    } catch (error) {
      print("❌ Error fetching AI teachers: $error");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    getAITeachers();
  }

  void _showTeacherInfoBottomSheet(Map<String, dynamic> teacher) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color.fromRGBO(19, 31, 36, 1),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Avatar
                Row(
                  // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Image.asset(
                      getAvatar(teacher["avatar"])["imagePath"]!,
                      height: 100,
                      fit: BoxFit.contain,
                    ),
                    SizedBox(
                      width: 20,
                    ),
                    // Name
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            teacher["name"] ?? "",
                            style: GoogleFonts.raleway(
                              fontSize: 22,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            teacher["styleSummary"] ?? "",
                            textAlign: TextAlign.left,
                            style: GoogleFonts.raleway(
                              fontSize: 16,
                              color: Colors.grey[300],
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // const SizedBox(height: 8),

                // Style Summary
                // Text(
                //   teacher["styleSummary"] ?? "",
                //   textAlign: TextAlign.center,
                //   style: GoogleFonts.raleway(
                //     fontSize: 16,
                //     color: Colors.grey[300],
                //   ),
                // ),

                const SizedBox(height: 24),

                // Good For
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "🌼 Good For",
                    style: GoogleFonts.raleway(
                      fontSize: 16,
                      color: Colors.yellow[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 0,
                      runSpacing: 8,
                      children: List<Widget>.from(
                        (teacher["goodFor"] ?? []).map<Widget>(
                          (item) => Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 6, horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.blueGrey.shade700,
                              borderRadius:
                                  BorderRadius.circular(8), // Match Chip shape
                              border: Border.all(
                                color: Colors.blueGrey
                                    .shade600, // Matches Chip border tone
                                width: 1,
                              ),
                            ),
                            child: Text(
                              item,
                              style: GoogleFonts.raleway(
                                fontSize: 13,
                                color: Colors.white,
                                fontWeight:
                                    FontWeight.w400, // Match Chip text weight
                              ),
                            ),
                          ),
                        ),
                      ),
                    )),

                const SizedBox(height: 24),

                // Mood Match
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "😊 Mood Match",
                    style: GoogleFonts.raleway(
                      fontSize: 16,
                      color: Colors.lightGreenAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 0,
                      alignment: WrapAlignment.start,
                      children: List<Widget>.from(
                        (teacher["moodMatch"] ?? []).map<Widget>(
                          (item) => Chip(
                            label: Text(
                              item,
                              style: GoogleFonts.raleway(fontSize: 13),
                            ),
                            backgroundColor: Colors.blueGrey[700],
                            labelStyle: const TextStyle(color: Colors.white),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    )),

                const SizedBox(height: 24),

                // Teaching Style
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "🎓 Teaching Style",
                    style: GoogleFonts.raleway(
                      fontSize: 16,
                      color: Colors.blue[300],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 0,
                      alignment: WrapAlignment.start,
                      children: List<Widget>.from(
                        (teacher["learningPedagogyFollowed"] ?? []).map<Widget>(
                          (item) => Chip(
                            label: Text(
                              item,
                              style: GoogleFonts.raleway(fontSize: 13),
                            ),
                            backgroundColor: Colors.blueGrey[700],
                            labelStyle: const TextStyle(color: Colors.white),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    )),

                const SizedBox(height: 24),

                // Confirm Button
                ChicletAnimatedButton(
                  onPressed: () {
                    setState(() {
                      selectedTeacherId = teacher["id"];
                    });
                    if (widget.onSelectionChanged != null) {
                      widget.onSelectionChanged!(teacher);
                    }
                    Navigator.pop(context);
                  },
                  buttonType: ChicletButtonTypes.roundedRectangle,
                  height: 50,
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  buttonColor: const Color.fromRGBO(187, 160, 2, 1),
                  backgroundColor: const Color.fromRGBO(255, 217, 0, 1),
                  child: Text(
                    "CONFIRM SELECTION",
                    style: GoogleFonts.raleway(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(19, 31, 36, 1),
      // appBar: AppBar(
      //   title: Align(
      //     alignment: Alignment.centerLeft,
      //     child: Text(
      //       "Choose Your AI Tutor",
      //       style: GoogleFonts.raleway(
      //         color: Colors.white,
      //         fontSize: 20,
      //         fontWeight: FontWeight.w700,
      //       ),
      //     ),
      //   ),
      //   backgroundColor: const Color.fromRGBO(19, 31, 36, 1),
      //   iconTheme: const IconThemeData(color: Colors.white),
      // ),
      body: isLoading
          ? _buildShimmerLoader()
          : Padding(
              padding: const EdgeInsets.all(0.0),
              child: Column(
                children: [
                  Expanded(
                    child: GridView.builder(
                      itemCount: aiTeachers.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 0.8,
                      ),
                      itemBuilder: (context, index) {
                        final teacher = aiTeachers[index];
                        final bool isSelected =
                            selectedTeacherId == teacher["id"];

                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            setState(() {
                              selectedTeacherId = teacher["id"];
                            });
                            if (widget.onSelectionChanged != null) {
                              widget.onSelectionChanged!(teacher);
                            }
                          },
                          child: Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color.fromRGBO(255, 217, 0, 1)
                                        : Colors.transparent,
                                    width: 3,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.grey[850],
                                ),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 8),
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: Image.asset(
                                        getAvatar(
                                            teacher["avatar"])["imagePath"]!,
                                        fit: BoxFit.contain,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Icon(Icons.person),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      teacher["name"] ?? "",
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.raleway(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14),
                                    ),
                                    // Text(
                                    //   teacher["styleSummary"] ?? "",
                                    //   textAlign: TextAlign.center,
                                    //   style: GoogleFonts.raleway(
                                    //     color: Colors.grey[400],
                                    //     fontSize: 13,
                                    //   ),
                                    // ),
                                  ],
                                ),
                              ),

                              // Info button
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () =>
                                      _showTeacherInfoBottomSheet(teacher),
                                  child: const Icon(
                                    Icons.info,
                                    size: 24,
                                    color: Color.fromRGBO(255, 217, 0, 1),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildShimmerLoader() {
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: 6,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[700]!,
          highlightColor: Colors.grey[500]!,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
    );
  }
}
