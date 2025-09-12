import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_markdown_latex/flutter_markdown_latex.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:lottie/lottie.dart';
import 'package:eureka_app/utils/tutorAvatars.dart';
import 'text_highlighter.dart';
import 'ai_tutor_helpers.dart';

class MessageBubbles {
  static Widget assistantBubble(
    String text,
    int index,
    List<Map<String, dynamic>> conversations,
    List<Map<String, dynamic>> conceptCheckpoints,
    int currentCheckpointIndex,
    Map<String, dynamic> latestTutorResponse,
    Map<String, dynamic> selectedTutor,
    Function(int, String) onToggleNotes,
    Function(int, String) onToggleBoard,
  ) {
    // Check if this is a hint message
    final isHint = conversations[index]['isHint'] == true;
    final isLoading = conversations[index]['isLoading'] == true;

    if (isHint) {
      return _buildHintCard(text);
    }

    final notesOpen = conversations[index]['notesOpen'] == true;
    final boardOpen = conversations[index]['boardOpen'] == true;
    final Map<String, dynamic> notes =
        AITutorHelpers.extractTutorNotesFromMessage(conversations[index]);
    final String boardText = conceptCheckpoints.isNotEmpty
        ? (conceptCheckpoints[currentCheckpointIndex]['blackboardText'] ?? '')
        : '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8, left: 2),
            child: Image.asset(
              getTutorAvatar("tutoprime")["imagePath"]!,
              height: 32,
            ),
          ),
          Flexible(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBF2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE7DEC9)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isLoading)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: Lottie.asset(
                          "lib/assets/animations/3-dots.json",
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  else
                    _buildHighlightedMarkdownText(text, conversations[index]),
                  // Show color legend if there are highlighted terms
                  if (!isLoading && _hasHighlights(conversations[index])) ...[
                    const SizedBox(height: 8),
                    _buildHighlightLegend(conversations[index]),
                  ],
                  if (!isLoading) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (notes.isNotEmpty)
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFE7DEC9)),
                              foregroundColor: const Color(0xFF70695B),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999)),
                            ),
                            onPressed: () => onToggleNotes(
                                index, notesOpen ? 'hide' : 'show'),
                            child: Text(
                                notesOpen ? 'Hide notes' : 'Show tutor notes',
                                style: GoogleFonts.raleway(
                                    fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                        const SizedBox(width: 8),
                        if (boardText.isNotEmpty)
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFE7DEC9)),
                              foregroundColor: const Color(0xFF70695B),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999)),
                            ),
                            onPressed: () => onToggleBoard(
                                index, boardOpen ? 'hide' : 'show'),
                            child: Text(boardOpen ? 'Hide board' : 'Show board',
                                style: GoogleFonts.raleway(
                                    fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                      ],
                    ),
                    if (notesOpen && notes.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildNotesContainer(notes),
                    ],
                    if (boardOpen && boardText.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildBoardContainer(boardText),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget userBubble(String text,
      [Map<String, dynamic>? conversation,
      Function(int)? onToggleFeedback,
      int? messageIndex]) {
    final isTranscribing = conversation?['isTranscribing'] == true;
    final hasFeedback = conversation != null && _hasUserFeedback(conversation);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: GestureDetector(
              onTap: hasFeedback &&
                      onToggleFeedback != null &&
                      messageIndex != null
                  ? () => onToggleFeedback(messageIndex)
                  : null,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0x1A1D4ED8), Color(0x291D4ED8)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF1D4ED8)),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x401D4ED8),
                        blurRadius: 18,
                        offset: Offset(0, 6))
                  ],
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isTranscribing)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Transcribing',
                            style: GoogleFonts.raleway(
                              fontSize: 14,
                              color: const Color(0xFF0B1220).withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            height: 16,
                            width: 16,
                            child: Lottie.asset(
                              "lib/assets/animations/3-dots.json",
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],
                      )
                    else
                      RichText(
                        text: TextSpan(
                          children: conversation != null
                              ? TextHighlighter
                                  .buildUserFeedbackHighlightedText(
                                      text, conversation)
                              : [
                                  TextSpan(
                                      text: text,
                                      style: GoogleFonts.raleway(
                                          fontSize: 15,
                                          color: const Color(0xFF0B1220)))
                                ],
                        ),
                      ),
                    // Show feedback legend if there are highlighted terms
                    if (hasFeedback) ...[
                      const SizedBox(height: 8),
                      _buildMasteryAndVerdict(conversation),
                      const SizedBox(height: 8),
                      _buildUserFeedbackLegend(
                          conversation, onToggleFeedback, messageIndex),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildHintCard(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.45, 1.0],
            colors: [
              Color(0xFFFDFCFB), // #FDFCFB
              Color(0xFFE2F6FF), // #E2F6FF
              Color(0xFFE5ECFF), // #E5ECFF
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD7EAFE)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 16,
                  color: const Color(0xFF1D4ED8), // Accent color
                ),
                const SizedBox(width: 8),
                Text(
                  'Hint',
                  style: GoogleFonts.raleway(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1D4ED8), // Accent color
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              text,
              style: GoogleFonts.raleway(
                fontSize: 14,
                color: const Color(0xFF374151), // Ink color
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static bool _hasHighlights(Map<String, dynamic> conversation) {
    return (conversation['keywords'] as List?)?.isNotEmpty == true ||
        (conversation['phrases'] as List?)?.isNotEmpty == true ||
        (conversation['definitions'] as List?)?.isNotEmpty == true;
  }

  static bool _hasUserFeedback(Map<String, dynamic> conversation) {
    return conversation['correctEvidence'] != null ||
        conversation['incorrectEvidence'] != null;
  }

  // New method to handle both highlighting and markdown/LaTeX rendering
  static Widget _buildHighlightedMarkdownText(
      String text, Map<String, dynamic> conversation) {
    final String? extractedQuestion = conversation['extractedQuestion'];
    final bool isLoading = conversation['isLoading'] == true;

    if (isLoading) {
      // Use regular highlighting without question replacement during loading
      return _buildGptMarkdownWithHighlights(text, conversation);
    }

    // If there's no extracted question, just show the regular highlighted markdown text
    if (extractedQuestion == null || extractedQuestion.isEmpty) {
      return _buildGptMarkdownWithHighlights(text, conversation);
    }

    // Show the text with the question at the end
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Show the full original text with highlighting and markdown
        _buildGptMarkdownWithHighlights(text, conversation),

        const SizedBox(height: 8),

        // Show the question as a separate interactive section
        Container(
          decoration: BoxDecoration(
            color: const Color(0x1A1D4ED8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF1D4ED8)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your turn',
                  style: GoogleFonts.raleway(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1D4ED8))),
              _buildGptMarkdownWithHighlights(extractedQuestion, {}),
            ],
          ),
        ),
      ],
    );
  }

  // Helper method to build markdown with highlighting using gpt_markdown
  static Widget _buildGptMarkdownWithHighlights(
      String text, Map<String, dynamic> conversation) {
    // Get highlighting terms
    final List<String> keywords =
        (conversation['keywords'] as List?)?.cast<String>() ?? [];
    final List<String> phrases =
        (conversation['phrases'] as List?)?.cast<String>() ?? [];
    final List<String> definitions =
        (conversation['definitions'] as List?)?.cast<String>() ?? [];

    // If no highlighting needed, use simple GptMarkdown
    if (keywords.isEmpty && phrases.isEmpty && definitions.isEmpty) {
      return GptMarkdown(
        text,
        style: GoogleFonts.raleway(
          fontSize: 15,
          height: 1.4,
          color: const Color(0xFF0B1220),
        ),
      );
    }

    // For now, we'll create a hybrid approach:
    // Use GptMarkdown for LaTeX rendering, but apply highlighting manually
    // This is a temporary solution until we can better integrate both features

    // Create highlight map
    final Map<String, Color> highlightTerms = {};

    // Add keywords with blue highlighting
    for (final keyword in keywords) {
      if (keyword.trim().isNotEmpty) {
        highlightTerms[keyword.trim().toLowerCase()] = const Color(0xFF1D4ED8);
      }
    }

    // Add phrases with green highlighting
    for (final phrase in phrases) {
      if (phrase.trim().isNotEmpty) {
        highlightTerms[phrase.trim().toLowerCase()] = const Color(0xFF059669);
      }
    }

    // Add definitions with purple highlighting
    for (final definition in definitions) {
      if (definition.trim().isNotEmpty) {
        highlightTerms[definition.trim().toLowerCase()] =
            const Color(0xFF7C3AED);
      }
    }

    // Check if text contains LaTeX (simple heuristic)
    final hasLatex =
        text.contains(r'\(') || text.contains(r'\[') || text.contains(r'$$');

    if (hasLatex) {
      // Use GptMarkdown for LaTeX rendering (highlighting will be limited)
      return GptMarkdown(
        text,
        style: GoogleFonts.raleway(
          fontSize: 15,
          height: 1.4,
          color: const Color(0xFF0B1220),
        ),
      );
    } else {
      // Use custom highlighting for non-LaTeX text
      return RichText(
        text: TextSpan(
          children: _buildHighlightedTextSpans(
              text,
              highlightTerms,
              GoogleFonts.raleway(
                fontSize: 15,
                height: 1.4,
                color: const Color(0xFF0B1220),
              )),
        ),
      );
    }
  }

  // Helper method to build highlighted text spans
  static List<TextSpan> _buildHighlightedTextSpans(
      String text, Map<String, Color> highlightTerms, TextStyle? baseStyle) {
    if (highlightTerms.isEmpty) {
      return [TextSpan(text: text, style: baseStyle)];
    }

    // Sort terms by length (longest first) to handle overlapping matches correctly
    final sortedTerms = highlightTerms.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    final List<TextSpan> spans = [];
    int currentIndex = 0;

    while (currentIndex < text.length) {
      bool foundMatch = false;

      // Try to find a match at the current position
      for (final term in sortedTerms) {
        final lowerText = text.toLowerCase();
        final matchIndex = lowerText.indexOf(term, currentIndex);

        if (matchIndex == currentIndex) {
          // Found a match at current position
          final originalTerm =
              text.substring(matchIndex, matchIndex + term.length);

          spans.add(TextSpan(
            text: originalTerm,
            style: baseStyle?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              backgroundColor: highlightTerms[term]!.withOpacity(0.8),
              height: 1.0,
            ),
          ));

          currentIndex = matchIndex + term.length;
          foundMatch = true;
          break;
        }
      }

      if (!foundMatch) {
        // No match found, add the current character and move on
        final nextMatchIndex =
            _findNextHighlightMatch(text, currentIndex, sortedTerms);
        final endIndex = nextMatchIndex != -1 ? nextMatchIndex : text.length;

        if (endIndex > currentIndex) {
          spans.add(TextSpan(
            text: text.substring(currentIndex, endIndex),
            style: baseStyle,
          ));
          currentIndex = endIndex;
        }
      }
    }

    return spans;
  }

  // Helper method to find the next match position for highlighting
  static int _findNextHighlightMatch(
      String text, int startIndex, List<String> terms) {
    int nearestMatch = -1;
    final lowerText = text.toLowerCase();

    for (final term in terms) {
      final matchIndex = lowerText.indexOf(term, startIndex);
      if (matchIndex != -1) {
        if (nearestMatch == -1 || matchIndex < nearestMatch) {
          nearestMatch = matchIndex;
        }
      }
    }

    return nearestMatch;
  }

  static Widget _buildHighlightLegend(Map<String, dynamic> conversation) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.info_outline, size: 14, color: const Color(0xFF6B7280)),
          const SizedBox(width: 4),
          Text('Highlights: ',
              style: GoogleFonts.raleway(
                  fontSize: 11, color: const Color(0xFF6B7280))),
          if ((conversation['keywords'] as List?)?.isNotEmpty == true) ...[
            _buildLegendChip('Keywords', const Color(0xFF1D4ED8)),
            const SizedBox(width: 4),
          ],
          if ((conversation['phrases'] as List?)?.isNotEmpty == true) ...[
            _buildLegendChip('Phrases', const Color(0xFF059669)),
            const SizedBox(width: 4),
          ],
          if ((conversation['definitions'] as List?)?.isNotEmpty == true) ...[
            _buildLegendChip('Definitions', const Color(0xFF7C3AED)),
          ],
        ],
      ),
    );
  }

  static Widget _buildUserFeedbackLegend(Map<String, dynamic> conversation,
      Function(int)? onToggleFeedback, int? messageIndex) {
    final bool isExpanded = conversation['feedbackExpanded'] == true;

    final List<String> correctPoints =
        (conversation["conversationFeedback"]?['correctPoints'] as List?)
                ?.cast<String>() ??
            [];
    // final List<Map<String, dynamic>> correctEvidence =
    //     (conversation['correctEvidence'] as List?)
    //             ?.cast<Map<String, dynamic>>() ??
    //         [];
    final List<String> incorrectPoints =
        (conversation["conversationFeedback"]?['incorrectPoints'] as List?)
                ?.cast<String>() ??
            [];

    final List<String> missingPoints =
        (conversation["conversationFeedback"]?['missingPoints'] as List?)
                ?.cast<String>() ??
            [];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main feedback legend row (always visible)
          GestureDetector(
            onTap: () {
              if (onToggleFeedback != null && messageIndex != null) {
                onToggleFeedback(messageIndex);
              }
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 14, color: const Color(0xFF6B7280)),
                const SizedBox(width: 4),
                Text('Feedback: ',
                    style: GoogleFonts.raleway(
                        fontSize: 11, color: const Color(0xFF6B7280))),
                if (conversation['correctEvidence'] != null) ...[
                  _buildLegendChip('Correct', const Color(0xFF059669)),
                  const SizedBox(width: 4),
                ],
                if (conversation['incorrectEvidence'] != null) ...[
                  _buildLegendChip('Incorrect', const Color(0xFFDC2626)),
                ],
              ],
            ),
          ),
          // Expanded feedback details
          if (isExpanded) ...[
            const SizedBox(height: 8),
            _buildFeedbackDetails(
                correctPoints, incorrectPoints, missingPoints),
          ],
        ],
      ),
    );
  }

  static Widget _buildFeedbackDetails(List<String> correctPoints,
      List<String> incorrectPoints, List<String> missingPoints) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (correctPoints.isNotEmpty) ...[
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF059669),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text('Correct Points:',
                  style: GoogleFonts.raleway(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF059669))),
            ],
          ),
          const SizedBox(height: 4),
          ...correctPoints
              .map((evidence) => Padding(
                    padding: const EdgeInsets.only(left: 14, bottom: 2),
                    child: Text(
                      '• $evidence',
                      style: GoogleFonts.raleway(
                        fontSize: 10,
                        color: const Color(0xFF374151),
                      ),
                    ),
                  ))
              .toList(),
          if (incorrectPoints.isNotEmpty) const SizedBox(height: 8),
        ],
        if (incorrectPoints.isNotEmpty) ...[
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFDC2626),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text('Incorrect Points:',
                  style: GoogleFonts.raleway(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFDC2626))),
            ],
          ),
          const SizedBox(height: 4),
          ...incorrectPoints
              .map((evidence) => Padding(
                    padding: const EdgeInsets.only(left: 14, bottom: 2),
                    child: Text(
                      '• $evidence',
                      style: GoogleFonts.raleway(
                        fontSize: 10,
                        color: const Color(0xFF374151),
                      ),
                    ),
                  ))
              .toList(),
          if (missingPoints.isNotEmpty) const SizedBox(height: 8),
        ],
        if (missingPoints.isNotEmpty) ...[
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFDC2626),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text('Missing Points:',
                  style: GoogleFonts.raleway(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFDC2626))),
            ],
          ),
          const SizedBox(height: 4),
          ...missingPoints
              .map((evidence) => Padding(
                    padding: const EdgeInsets.only(left: 14, bottom: 2),
                    child: Text(
                      '• $evidence',
                      style: GoogleFonts.raleway(
                        fontSize: 10,
                        color: const Color(0xFF374151),
                      ),
                    ),
                  ))
              .toList(),
        ],
      ],
    );
  }

  static Widget _buildLegendChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withOpacity(0.8),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text,
          style: GoogleFonts.raleway(
              fontSize: 9, color: Colors.white, fontWeight: FontWeight.w600)),
    );
  }

  static Widget _buildNotesContainer(Map<String, dynamic> notes) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if ((notes['correct'] ?? '').toString().isNotEmpty)
            Row(children: [
              const Icon(Icons.check_circle,
                  size: 16, color: Color(0xFF065F46)),
              const SizedBox(width: 6),
              Expanded(
                  child: Text('Correct: ${notes['correct']}',
                      style: GoogleFonts.raleway(
                          fontSize: 13, color: const Color(0xFF065F46))))
            ]),
          if ((notes['partiallyCorrect'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.info_outline,
                  size: 16, color: Color(0xFF1D4ED8)),
              const SizedBox(width: 6),
              Expanded(
                  child: Text('Partially correct: ${notes['partiallyCorrect']}',
                      style: GoogleFonts.raleway(
                          fontSize: 13, color: Color(0xFF1D4ED8))))
            ]),
          ],
          if ((notes['wrong'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.warning_amber_rounded,
                  size: 16, color: Color(0xFFB91C1C)),
              const SizedBox(width: 6),
              Expanded(
                  child: Text('Needs fix: ${notes['wrong']}',
                      style: GoogleFonts.raleway(
                          fontSize: 13, color: const Color(0xFFB91C1C))))
            ]),
          ],
          if ((notes['doubt'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 22),
              child: Text('Doubt: ${notes['doubt']}',
                  style: GoogleFonts.raleway(
                      fontSize: 13, color: const Color(0xFF0B1220))),
            ),
          ],
          if ((notes['misconception'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 22),
              child: Text('Misconception: ${notes['misconception']}',
                  style: GoogleFonts.raleway(
                      fontSize: 13, color: const Color(0xFF0B1220))),
            ),
          ],
        ],
      ),
    );
  }

  static Widget _buildBoardContainer(String boardText) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7DEC9)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: MarkdownBody(
        selectable: false,
        data: boardText,
        builders: {
          'latex': LatexElementBuilder(
            textStyle: GoogleFonts.raleway(
              color: const Color(0xFF0B1220),
              fontSize: 14,
            ),
          ),
        },
        extensionSet: md.ExtensionSet(
          [LatexBlockSyntax()],
          [LatexInlineSyntax()],
        ),
        styleSheet: MarkdownStyleSheet(
          p: GoogleFonts.raleway(
            color: const Color(0xFF0B1220),
            fontSize: 14,
          ),
          h1: GoogleFonts.raleway(
            color: const Color(0xFF0B1220),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          h2: GoogleFonts.raleway(
            color: const Color(0xFF0B1220),
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
          listBullet: GoogleFonts.raleway(
            color: const Color(0xFF0B1220),
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  static Widget _buildMasteryAndVerdict(Map<String, dynamic> conversation) {
    final conversationFeedback = conversation["conversationFeedback"];
    if (conversationFeedback == null) return const SizedBox.shrink();

    final String? verdict = conversationFeedback['verdict'];
    final int? masteryScore = conversationFeedback['masteryScore'];

    if (verdict == null && masteryScore == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF6366F1).withOpacity(0.1),
            const Color(0xFF8B5CF6).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (verdict != null) ...[
            Expanded(
              child: Row(
                children: [
                  Icon(
                    _getVerdictIcon(verdict),
                    size: 16,
                    color: _getVerdictColor(verdict),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Verdict: ',
                    style: GoogleFonts.raleway(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF374151),
                    ),
                  ),
                  Text(
                    verdict.toUpperCase(),
                    style: GoogleFonts.raleway(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getVerdictColor(verdict),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (masteryScore != null) ...[
            if (verdict != null) const SizedBox(width: 16),
            Row(
              children: [
                Icon(
                  Icons.psychology,
                  size: 16,
                  color: _getMasteryColor(masteryScore),
                ),
                const SizedBox(width: 6),
                Text(
                  'Mastery: ',
                  style: GoogleFonts.raleway(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF374151),
                  ),
                ),
                Text(
                  '$masteryScore%',
                  style: GoogleFonts.raleway(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getMasteryColor(masteryScore),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static IconData _getVerdictIcon(String verdict) {
    switch (verdict.toLowerCase()) {
      case 'correct':
        return Icons.check_circle;
      case 'incorrect':
        return Icons.cancel;
      case 'partial':
        return Icons.adjust;
      default:
        return Icons.help;
    }
  }

  static Color _getVerdictColor(String verdict) {
    switch (verdict.toLowerCase()) {
      case 'correct':
        return const Color(0xFF059669);
      case 'incorrect':
        return const Color(0xFFDC2626);
      case 'partial':
        return Color.fromARGB(255, 255, 255, 255); // Orange for medium mastery
      default:
        return const Color(0xFF6B7280);
    }
  }

  static Color _getMasteryColor(int masteryScore) {
    if (masteryScore >= 80) {
      return const Color(0xFF059669); // Green for high mastery
    } else if (masteryScore >= 60) {
      return Color.fromARGB(255, 255, 255, 255); // Orange for medium mastery
    } else {
      return const Color(0xFFDC2626); // Red for low mastery
    }
  }
}
