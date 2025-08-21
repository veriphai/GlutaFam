import 'package:eureka_app/screens/home/models/subjectChipData.dart';
import 'package:eureka_app/screens/home/widgets/subjects/subjectChip.dart';
import 'package:flutter/material.dart';

class SubjectChipsRow extends StatelessWidget {
  const SubjectChipsRow({
    super.key,
    required this.subjects,
    required this.onSelect,
  });

  final List<SubjectChipData> subjects;
  final ValueChanged<String> onSelect;

  static const _trayFill = Color.fromRGBO(253, 241, 214, 1); // beige
  static const _trayLine = Color(0xFFB7A987);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: subjects.map((s) {
          return SubjectChip(
            data: s,
            onTap: () => onSelect(s.id),
          );
        }).toList(),
      ),
    );
  }
}
