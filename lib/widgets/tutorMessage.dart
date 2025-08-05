// lib/screens/tutor/widgets/tutor_message.dart

import 'package:eureka_app/newEvents/aiTutorScreenEvents.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown_latex/flutter_markdown_latex.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

class TutorMessage extends StatefulWidget {
  final String conceptId;
  final int checkpointNo;
  final Map tutorResponse;
  final Widget Function(String) messageBuilder;

  const TutorMessage(
      {Key? key,
      required this.tutorResponse,
      required this.messageBuilder,
      required this.conceptId,
      required this.checkpointNo})
      : super(key: key);

  @override
  State<TutorMessage> createState() => _TutorMessageState();
}

class _TutorMessageState extends State<TutorMessage> {
  bool _showInsights = false;

  @override
  Widget build(BuildContext context) {
    final tutorResponse = widget.tutorResponse;
    final duration = (tutorResponse['thinkingDuration'] ?? 0).toDouble();

    if (duration == 0) {
      return widget.messageBuilder(tutorResponse['message']);
    }

    final durationInSeconds = duration ~/ 1000;

    final correct = tutorResponse['correct'];
    final wrong = tutorResponse['wrong'];
    final partiallyCorrect = tutorResponse['partiallyCorrect'];
    final doubt = tutorResponse['doubt'];
    final misconception = tutorResponse['misconception'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 48.0, bottom: 8),
          child: Container(
            decoration: BoxDecoration(
              color: const Color.fromRGBO(30, 42, 48, 1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.grey.shade700,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔹 Static header that doesn’t shift
                GestureDetector(
                  onTap: () {
                    logAITutorThoughtClicked(
                        widget.conceptId, widget.checkpointNo);
                    setState(() {
                      _showInsights = !_showInsights;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "Thought for ${durationInSeconds.toStringAsFixed(0)} seconds",
                          style: GoogleFonts.raleway(
                            fontSize: 14,
                            color: Colors.grey[300],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _showInsights ? Icons.expand_less : Icons.expand_more,
                          size: 18,
                          color: Colors.grey[300],
                        ),
                      ],
                    ),
                  ),
                ),

                // 🔹 Smoothly expanding insight section
                GestureDetector(
                    onTap: () {
                      setState(() {
                        _showInsights = !_showInsights;
                      });
                    },
                    child: AnimatedSize(
                      duration: Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      child: _showInsights
                          ? Padding(
                              padding: const EdgeInsets.only(
                                left: 12.0,
                                right: 12.0,
                                bottom: 12.0,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (correct?.isNotEmpty ?? false)
                                    _buildInsightRow("✅ Correct", correct),
                                  if (partiallyCorrect?.isNotEmpty ?? false)
                                    _buildInsightRow("🟡 Partially Correct",
                                        partiallyCorrect),
                                  if (wrong?.isNotEmpty ?? false)
                                    _buildInsightRow("❌ Wrong", wrong),
                                  if (misconception?.isNotEmpty ?? false)
                                    _buildInsightRow(
                                        "⚠️ Misconception", misconception),
                                  if (doubt?.isNotEmpty ?? false)
                                    _buildInsightRow("❓ Doubt", doubt),
                                ],
                              ),
                            )
                          : SizedBox.shrink(), // 🔹 Collapse smoothly
                    )),
              ],
            ),
          ),
        ),
        widget.messageBuilder(tutorResponse['message']),
      ],
    );
  }

  Widget _buildInsightRow(String label, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
              child: MarkdownBody(
            selectable: false,
            data: "**$label:** $text",
            builders: {
              'latex': LatexElementBuilder(
                textStyle: GoogleFonts.raleway(
                  color: Colors.white,
                  // fontSize: 16,
                ),
              ),
            },
            extensionSet: md.ExtensionSet(
              [LatexBlockSyntax()],
              [LatexInlineSyntax()],
            ),
            styleSheet: MarkdownStyleSheet(
              p: GoogleFonts.raleway(
                color: Colors.white,
                // fontSize: 16,
              ),
              blockSpacing: 8.0,
            ),
          ))
        ],
      ),
    );
  }
}
