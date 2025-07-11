import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown_latex/flutter_markdown_latex.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

class LessonCheckpoints extends StatelessWidget {
  final List<Map<String, dynamic>> conceptCheckpoints;

  const LessonCheckpoints({
    super.key,
    required this.conceptCheckpoints,
  });

  @override
  Widget build(BuildContext context) {
    if (conceptCheckpoints.isEmpty) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "What You’ll Learn",
          style: GoogleFonts.raleway(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),

        // Loop over each checkpoint
        ...conceptCheckpoints.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final data = entry.value;
          final learningObjectives =
              List<String>.from(data['learningObjective'] ?? []);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(30, 36, 41, 1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[800]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.flag,
                        color: Color.fromRGBO(255, 217, 0, 1), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Checkpoint $index",
                        style: GoogleFonts.raleway(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 8),
                ...learningObjectives.map((point) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle,
                              color: Color.fromRGBO(255, 217, 0, 1), size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: MarkdownBody(
                              selectable: false,
                              data: point,
                              builders: {
                                'latex': LatexElementBuilder(
                                  textStyle: GoogleFonts.raleway(
                                      color: Colors.white70, fontSize: 14),
                                ),
                              },
                              extensionSet: md.ExtensionSet(
                                [LatexBlockSyntax()],
                                [LatexInlineSyntax()],
                              ),
                              styleSheet: MarkdownStyleSheet(
                                p: GoogleFonts.notoSans(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                                blockSpacing: 8.0,
                              ),
                            ),
                          )
                        ],
                      ),
                    )),
              ],
            ),
          );
        }),
      ],
    );
  }
}
