import 'package:chiclet/chiclet.dart';
import 'package:eureka_app/apis/fetchCities.dart';
import 'package:eureka_app/apis/fetchSchools.dart';
import 'package:eureka_app/apis/fetchStates.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SchoolSelectionWidget extends StatefulWidget {
  final Function(String state, String city, String school, String schoolId)
      onSelectionChanged;

  const SchoolSelectionWidget({Key? key, required this.onSelectionChanged})
      : super(key: key);

  @override
  _SchoolSelectionWidgetState createState() => _SchoolSelectionWidgetState();
}

class _SchoolSelectionWidgetState extends State<SchoolSelectionWidget> {
  String? selectedState;
  String? selectedCity;
  Map<String, dynamic>? selectedSchool; // {"name": "School 1", "id": "123"}

  List<dynamic> states = [];
  List<dynamic> cities = [];
  List<Map<String, dynamic>> schools =
      []; // [{"name": "School 1", "id": "123"}]

  bool isLoadingStates = false;
  bool isLoadingCities = false;
  bool isLoadingSchools = false;

  @override
  void initState() {
    super.initState();
    _fetchStates();
  }

  Future<void> _fetchStates() async {
    setState(() => isLoadingStates = true);
    try {
      states = await fetchStates();
    } catch (error) {
      _showError("Failed to fetch states");
    } finally {
      setState(() => isLoadingStates = false);
    }
  }

  Future<void> _fetchCities(String state) async {
    setState(() => isLoadingCities = true);
    try {
      cities = await fetchCities(state: state);
    } catch (error) {
      _showError("Failed to fetch cities");
    } finally {
      setState(() => isLoadingCities = false);
    }
  }

  Future<void> _fetchSchools(String state, String city) async {
    setState(() => isLoadingSchools = true);
    try {
      schools = await fetchSchools(state: state, city: city);
    } catch (error) {
      _showError("Failed to fetch schools");
    } finally {
      setState(() => isLoadingSchools = false);
    }
  }

  void _updateSelection() {
    if (selectedState != null &&
        selectedCity != null &&
        selectedSchool != null) {
      widget.onSelectionChanged(
        selectedState!,
        selectedCity!,
        selectedSchool!['schoolName']!,
        selectedSchool!['id']!,
      );
    }
  }

  void _showBottomSheetWithSearch({
    required BuildContext context,
    required String title,
    required List<dynamic> options,
    required String? selectedValue,
    required ValueChanged<dynamic> onSelect,
    required bool isLoading,
  }) {
    TextEditingController searchController = TextEditingController();
    List<dynamic> filteredOptions = List.from(options);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          title,
                          style: GoogleFonts.raleway(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          style: GoogleFonts.raleway(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                          controller: searchController,
                          decoration: InputDecoration(
                            hintText: "Search",
                            hintStyle: GoogleFonts.raleway(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                            isDense: true,
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              filteredOptions = options
                                  .where((option) => (option is String
                                          ? option.toLowerCase()
                                          : option['schoolName'].toLowerCase())
                                      .contains(value.toLowerCase()))
                                  .toList();
                            });
                          },
                        ),
                      ),
                      const Divider(),
                      Expanded(
                        child: ListView.builder(
                          itemCount: filteredOptions.length,
                          itemBuilder: (context, index) {
                            final option = filteredOptions[index];
                            final optionName = option is String
                                ? option
                                : option['schoolName'];
                            return ListTile(
                              title: Text(
                                optionName,
                                style: GoogleFonts.raleway(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              trailing: selectedValue == optionName
                                  ? const Icon(Icons.check, color: Colors.green)
                                  : null,
                              onTap: () {
                                onSelect(option);
                                Navigator.pop(
                                    context); // Close the bottom sheet
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  );
          },
        );
      },
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          "In which school do you study?",
          style: GoogleFonts.raleway(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),

        // State Button
        ChicletOutlinedAnimatedButton(
          onPressed: () {
            _showBottomSheetWithSearch(
              context: context,
              title: "Select State",
              options: states,
              selectedValue: selectedState,
              onSelect: (value) async {
                setState(() {
                  selectedState = value;
                  selectedCity = null;
                  selectedSchool = null;
                  cities = [];
                  schools = [];
                });
                await _fetchCities(value);
                _updateSelection();
              },
              isLoading: isLoadingStates,
            );
          },
          width: double.infinity,
          height: 50,
          borderWidth: 1,
          borderRadius: 12,
          borderColor: selectedState != null ? Colors.blue : Colors.grey[700]!,
          backgroundColor: const Color.fromRGBO(19, 31, 36, 1),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                selectedState ?? "Select State",
                style: GoogleFonts.raleway(
                  color: selectedState != null ? Colors.blue : Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // City Button
        ChicletOutlinedAnimatedButton(
          onPressed: selectedState != null
              ? () {
                  _showBottomSheetWithSearch(
                    context: context,
                    title: "Select City",
                    options: cities,
                    selectedValue: selectedCity,
                    onSelect: (value) async {
                      setState(() {
                        selectedCity = value;
                        selectedSchool = null;
                        schools = [];
                      });
                      await _fetchSchools(selectedState!, value);
                      _updateSelection();
                    },
                    isLoading: isLoadingCities,
                  );
                }
              : null,
          width: double.infinity,
          height: 50,
          borderWidth: 1,
          borderRadius: 12,
          borderColor: selectedCity != null ? Colors.blue : Colors.grey[700]!,
          backgroundColor: const Color.fromRGBO(19, 31, 36, 1),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                selectedCity ?? "Select City",
                style: GoogleFonts.raleway(
                  color: selectedCity != null ? Colors.blue : Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // School Button
        ChicletOutlinedAnimatedButton(
          onPressed: selectedCity != null
              ? () {
                  _showBottomSheetWithSearch(
                    context: context,
                    title: "Select School",
                    options: schools,
                    selectedValue: selectedSchool?['schoolName'],
                    onSelect: (value) {
                      setState(() {
                        selectedSchool = value;
                      });
                      _updateSelection();
                    },
                    isLoading: isLoadingSchools,
                  );
                }
              : null,
          width: double.infinity,
          height: 50,
          borderWidth: 1,
          borderRadius: 12,
          borderColor: selectedSchool != null ? Colors.blue : Colors.grey[700]!,
          backgroundColor: const Color.fromRGBO(19, 31, 36, 1),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                selectedSchool?['schoolName'] ?? "Select School",
                style: GoogleFonts.raleway(
                  color: selectedSchool != null ? Colors.blue : Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
