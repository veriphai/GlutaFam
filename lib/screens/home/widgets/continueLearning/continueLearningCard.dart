import 'package:eureka_app/screens/home/widgets/continueLearning/lessonItemLarge.dart';
import 'package:eureka_app/screens/home/widgets/continueLearning/rightEdgeSubjectTabs.dart';
import 'package:eureka_app/screens/home/widgets/continueLearning/sectionTabLabel.dart';
import 'package:flutter/material.dart';
import '../../models/lesson.dart';

class ContinueLearningCard extends StatelessWidget {
  const ContinueLearningCard({
    super.key,
    required this.lessons,
    required this.subjectTabs, // <-- NEW
    this.selectedSubjectId,
    this.onSelectSubject,
    this.onTapLesson,
  });

  final List<Lesson> lessons;
  final List<SubjectTabSpec> subjectTabs;
  final String? selectedSubjectId;
  final ValueChanged<String>? onSelectSubject;
  final ValueChanged<String>? onTapLesson;

  static const cardFill = Color.fromRGBO(255, 247, 209, 1); // sticky note card
  static const _cardLine = Color(0xFFB7A987);

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          right: 0,
          child: IgnorePointer(
            ignoring: onSelectSubject == null,
            child: RightEdgeSubjectTabs(
              tabs: subjectTabs,
              selectedId: selectedSubjectId,
              onSelect: onSelectSubject,
              cardFill: cardFill,
              size: const Size(64, 64),
              outset: 20,
            ),
          ),
        ),
        // The card itself
        Container(
          padding: EdgeInsets.only(top: 42),
          decoration: BoxDecoration(
            color: cardFill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _cardLine, width: 1.5),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black12, blurRadius: 10, offset: Offset(0, 3)),
            ],
          ),
          child: Column(
            children: List.generate(lessons.length, (i) {
              final l = lessons[i];
              return LessonItemLarge(
                lesson: l,
                cardFill: cardFill,
                showDivider: i != lessons.length - 1,
                onTap: onTapLesson == null ? null : () => onTapLesson!(l.id),
              );
            }),
          ),
        ),

        // Half-outside tab label (sticky note)
        const Positioned(
          top: -18,
          left: 0,
          right: 0,
          child: Center(child: SectionTabLabel(text: "Continue Learning")),
        ),

        // Right-edge subject selector tabs (independent of lessons)
        // Positioned.fill(
        //   right: 0,
        //   child: IgnorePointer(
        //     ignoring: onSelectSubject == null,
        //     child: RightEdgeSubjectTabs(
        //       tabs: subjectTabs,
        //       selectedId: selectedSubjectId,
        //       onSelect: onSelectSubject,
        //       cardFill: cardFill,
        //       size: const Size(30, 56),
        //       outset: 16,
        //     ),
        //   ),
        // ),
      ],
    );
  }
}
