import 'package:eureka_app/screens/home/widgets/timetableEditor/editorModels.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PeriodEditorRow extends StatelessWidget {
  const PeriodEditorRow({
    super.key,
    required this.draft,
    required this.subjects,
    required this.chapters,
    required this.onChanged,
    required this.onDelete,
    this.canDelete = true,
  });

  final PeriodDraft draft;
  final List<Subject> subjects;
  final List<Chapter> chapters;
  final ValueChanged<PeriodDraft> onChanged;
  final VoidCallback onDelete;
  final bool canDelete;

  static const _inkBlue = Color(0xFF1E4B7A);
  static const _trayLine = Color(0xFFCCBE9C);
  static const _noteFill = Color(0xFFFFF7E3);

  List<Chapter> get _chaptersForSelected {
    if (draft.subjectId == null) return const [];
    return chapters.where((c) => c.subjectId == draft.subjectId).toList();
  }

  @override
  Widget build(BuildContext context) {
    final hasSubject = (draft.subjectId != null && draft.subjectId!.isNotEmpty);
    final subj = hasSubject
        ? subjects.firstWhere((s) => s.id == draft.subjectId,
            orElse: () => subjects.first)
        : null;

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: _noteFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _trayLine, width: 1),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          // Period chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: const ShapeDecoration(
              color: Color.fromRGBO(253, 233, 137, 1),
              shape: StadiumBorder(
                side: BorderSide(
                    color: Color.fromRGBO(228, 204, 109, 1), width: 1.2),
              ),
              shadows: [
                BoxShadow(
                    color: Colors.black12, blurRadius: 4, offset: Offset(0, 1))
              ],
            ),
            child: Text('Period ${draft.index}',
                style: GoogleFonts.kalam(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _inkBlue)),
          ),
          const SizedBox(width: 10),

          // Main editor area (subject-first flow)
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: hasSubject
                  ? Row(
                      key: const ValueKey('withSubject'),
                      children: [
                        // Subject pill (locked)
                        _SubjectPill(
                          icon: subj!.icon,
                          label: subj.name,
                          color: subj.color,
                          onChange: () {
                            // reset subject -> chapter cleared
                            onChanged(draft.copyWith(
                                subjectId: null, chapterId: null));
                          },
                        ),
                        const SizedBox(width: 10),

                        // Chapter dropdown
                        Expanded(
                          child: _DropdownField<String>(
                            value: (draft.chapterId?.isNotEmpty ?? false)
                                ? draft.chapterId
                                : null,
                            hint: 'Select chapter',
                            items: _chaptersForSelected
                                .map((c) => DropdownMenuItem<String>(
                                      value: c.id,
                                      child: Text(c.name,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              color: _inkBlue)),
                                    ))
                                .toList(),
                            onChanged: (val) =>
                                onChanged(draft.copyWith(chapterId: val)),
                          ),
                        ),
                      ],
                    )
                  : _DropdownField<String>(
                      value: null,
                      hint: 'Select subject',
                      items: subjects
                          .map((s) => DropdownMenuItem<String>(
                                value: s.id,
                                child: Row(
                                  children: [
                                    Icon(s.icon, size: 18, color: _inkBlue),
                                    const SizedBox(width: 8),
                                    Text(s.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            color: _inkBlue)),
                                  ],
                                ),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val == null) return;
                        // set subject, keep chapter empty (will show chapter picker next)
                        onChanged(
                            draft.copyWith(subjectId: val, chapterId: null));
                      },
                    ),
            ),
          ),

          const SizedBox(width: 8),

          // Delete (disabled if only one row left)
          IconButton(
            onPressed: canDelete ? onDelete : null,
            icon: Icon(Icons.close_rounded,
                color: canDelete ? _inkBlue : _inkBlue.withOpacity(0.35)),
            tooltip:
                canDelete ? 'Remove period' : 'At least one period required',
          ),
        ],
      ),
    );
  }
}

class _SubjectPill extends StatelessWidget {
  const _SubjectPill({
    required this.icon,
    required this.label,
    required this.color,
    required this.onChange,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onChange;

  static const _inkBlue = Color(0xFF1E4B7A);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFE3EEF7),
      shape: const StadiumBorder(
        side: BorderSide(color: Color(0xFFCCBE9C), width: 1.2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: _inkBlue),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                  fontSize: 13.5, fontWeight: FontWeight.w900, color: _inkBlue),
            ),
            const SizedBox(width: 6),
            InkWell(
              onTap: onChange,
              customBorder: const CircleBorder(),
              child: const Padding(
                padding: EdgeInsets.all(2),
                child:
                    Icon(Icons.swap_horiz_rounded, size: 16, color: _inkBlue),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
    this.enabled = true,
  });

  final T? value;
  final String hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final bool enabled;

  static const _inkBlue = Color(0xFF1E4B7A);
  static const _trayLine = Color(0xFFCCBE9C);

  @override
  Widget build(BuildContext context) {
    final content = DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        isExpanded: true,
        value: value,
        hint: Text(hint,
            style: TextStyle(
                color: _inkBlue.withOpacity(0.5), fontWeight: FontWeight.w700)),
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _inkBlue),
        items: items,
        onChanged: enabled ? onChanged : null,
      ),
    );

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _trayLine, width: 1.2),
      ),
      alignment: Alignment.centerLeft,
      child: content,
    );

    // If you want the scribbly outline instead of a clean border:
    // return Stack(
    //   children: [
    //     Container(... same as above but without `border:` ...),
    //     Positioned.fill(
    //       child: IgnorePointer(
    //         child: CustomPaint(
    //           painter: ScribbleBorderPainter(
    //             color: _trayLine, radius: 10, strokeWidth: 1.2, step: 6, jitter: 1.2,
    //             seed: Object.hash(hint, 'dropdown'), doubleStroke: true,
    //             drawTop: true, drawRight: true, drawBottom: true, drawLeft: true,
    //           ),
    //         ),
    //       ),
    //     ),
    //   ],
    // );
  }
}
