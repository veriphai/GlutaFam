import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_markdown_latex/flutter_markdown_latex.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';
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
    final String boardText =
        AITutorHelpers.extractBoardTextFromMessage(conversations[index]);

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
                    _buildAssistantLoadingState()
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
                            child: Text(boardOpen ? 'Hide Hint' : 'Show Hint',
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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBF2),

                // gradient: const LinearGradient(
                //   colors: [Color(0x1A1D4ED8), Color(0x291D4ED8)],
                // ),
                borderRadius: BorderRadius.circular(16),
                // border: Border.all(color: const Color(0xFF1D4ED8)),
                border: Border.all(color: const Color(0xFFE7DEC9)),

                // boxShadow: const [
                //   BoxShadow(
                //       color: Color(0x401D4ED8),
                //       blurRadius: 18,
                //       offset: Offset(0, 6))
                // ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User message content
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isTranscribing)
                          _buildTranscribingLoadingState()
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
                      ],
                    ),
                  ),
                  // Separator and feedback section
                  if (!isTranscribing) ...[
                    _FeedbackSectionWithDivider(
                      conversation: conversation,
                      onToggleFeedback: onToggleFeedback,
                      messageIndex: messageIndex,
                    ),
                  ],
                ],
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
    // Removed extractedQuestion from highlights check since using inline box instead
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

    // Get the original text if available, otherwise use current text
    final String originalText = conversation['originalText'] ?? text;

    // Split text around the question and show inline question box
    return _buildTextWithInlineQuestionBox(
        originalText, extractedQuestion, conversation);
  }

  // Helper method to build markdown with highlighting using gpt_markdown
  static Widget _buildGptMarkdownWithHighlights(
      String text, Map<String, dynamic> conversation) {
    // Preprocess: Convert $...$ to \(...\) for better compatibility
    text = _convertDollarLatexToParentheses(text);

    // Get highlighting terms
    final List<String> keywords =
        (conversation['keywords'] as List?)?.cast<String>() ?? [];
    final List<String> phrases =
        (conversation['phrases'] as List?)?.cast<String>() ?? [];
    final List<String> definitions =
        (conversation['definitions'] as List?)?.cast<String>() ?? [];
    final String? extractedQuestion = conversation['extractedQuestion'];

    // Check if text contains LaTeX (simple heuristic)
    final hasLatex =
        text.contains(r'\(') || text.contains(r'\[') || text.contains(r'$$');

    // If no highlighting needed, use appropriate renderer
    if (keywords.isEmpty &&
        phrases.isEmpty &&
        definitions.isEmpty &&
        (extractedQuestion == null || extractedQuestion.isEmpty)) {
      if (hasLatex) {
        return GptMarkdown(
          text,
          style: GoogleFonts.raleway(
            fontSize: 15,
            height: 1.4,
            color: const Color(0xFF0B1220),
          ),
        );
      } else {
        return MarkdownBody(
          data: text,
          styleSheet: MarkdownStyleSheet(
            p: GoogleFonts.raleway(
              fontSize: 15,
              height: 1.4,
              color: const Color(0xFF0B1220),
            ),
          ),
        );
      }
    }

    // Create highlight terms map
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

    // Add extracted question with special highlighting (orange/amber)
    // Commented out for now - using inline question box instead
    // if (extractedQuestion != null && extractedQuestion.trim().isNotEmpty) {
    //   highlightTerms[extractedQuestion.trim().toLowerCase()] =
    //       const Color(0xFFF59E0B);
    // }

    // If we have LaTeX content WITH highlighting, use hybrid approach
    if (hasLatex) {
      return _buildHybridLatexWithHighlighting(text, highlightTerms);
    }

    // For non-LaTeX content with highlighting, use custom highlighting with RichText
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

  // Hybrid approach: LaTeX rendering + text highlighting
  static Widget _buildHybridLatexWithHighlighting(
      String text, Map<String, Color> highlightTerms) {
    // Parse text into segments: LaTeX expressions and regular text
    final segments = _parseTextWithLatex(text);

    // If parsing fails or no segments, fallback to GptMarkdown
    if (segments.isEmpty) {
      return GptMarkdown(
        text,
        style: GoogleFonts.raleway(
          fontSize: 15,
          height: 1.4,
          color: const Color(0xFF0B1220),
        ),
      );
    }

    // Group segments by lines (separate by block LaTeX or newlines)
    final lines = _groupSegmentsByLines(segments);

    // Build widgets for each line
    final List<Widget> lineWidgets = [];

    for (final line in lines) {
      if (line.length == 1 && line[0]['isBlockLatex'] == true) {
        // Single block LaTeX segment - render as separate widget
        lineWidgets.add(
          GptMarkdown(
            line[0]['text'],
            style: GoogleFonts.raleway(
              fontSize: 15,
              height: 1.4,
              color: const Color(0xFF0B1220),
            ),
          ),
        );
      } else {
        // Mixed content line - render inline
        final List<InlineSpan> inlineSpans = [];

        for (final segment in line) {
          if (segment['isLatex'] == true && segment['isBlockLatex'] != true) {
            // Inline LaTeX - use GptMarkdown wrapped in WidgetSpan
            inlineSpans.add(
              WidgetSpan(
                child: GptMarkdown(
                  segment['text'],
                  style: GoogleFonts.raleway(
                    fontSize: 15,
                    height: 1.4,
                    color: const Color(0xFF0B1220),
                  ),
                ),
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
              ),
            );
          } else {
            // Regular text with highlighting
            inlineSpans.addAll(
              _buildHighlightedTextSpans(
                segment['text'],
                highlightTerms,
                GoogleFonts.raleway(
                  fontSize: 15,
                  height: 1.4,
                  color: const Color(0xFF0B1220),
                ),
              ),
            );
          }
        }

        lineWidgets.add(
          RichText(
            text: TextSpan(children: inlineSpans),
          ),
        );
      }
    }

    // Combine all line widgets
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lineWidgets,
    );
  }

  // Group segments by lines for proper inline/block rendering
  static List<List<Map<String, dynamic>>> _groupSegmentsByLines(
      List<Map<String, dynamic>> segments) {
    final List<List<Map<String, dynamic>>> lines = [];
    List<Map<String, dynamic>> currentLine = [];

    for (final segment in segments) {
      // Check if this is a block LaTeX expression
      final isBlockLatex = segment['isLatex'] == true &&
          (segment['text'].contains(r'$$') || segment['text'].contains(r'\['));

      segment['isBlockLatex'] = isBlockLatex;

      if (isBlockLatex) {
        // Block LaTeX - finish current line and start new one
        if (currentLine.isNotEmpty) {
          lines.add(List.from(currentLine));
          currentLine.clear();
        }
        lines.add([segment]);
      } else {
        // Inline content - add to current line
        currentLine.add(segment);
      }
    }

    // Add remaining segments as final line
    if (currentLine.isNotEmpty) {
      lines.add(currentLine);
    }

    return lines;
  }

  // Convert $...$ LaTeX to \(...\) for better compatibility
  static String _convertDollarLatexToParentheses(String text) {
    // Replace single dollar signs with parentheses format
    // Be careful to handle $$...$$ (block) vs $...$ (inline)

    // First, temporarily replace $$...$$ with placeholders to avoid conflicts
    final Map<String, String> blockLatexPlaceholders = {};
    int placeholderIndex = 0;

    // Find and replace $$...$$ with placeholders
    text = text.replaceAllMapped(RegExp(r'\$\$([^$]*?)\$\$'), (match) {
      final placeholder = '___BLOCK_LATEX_${placeholderIndex}___';
      blockLatexPlaceholders[placeholder] = match.group(0)!;
      placeholderIndex++;
      return placeholder;
    });

    // Now replace remaining single $...$ with \(...\)
    text = text.replaceAllMapped(RegExp(r'\$([^$\n]+?)\$'), (match) {
      final content = match.group(1)!;
      return '\\($content\\)';
    });

    // Restore the $$...$$ blocks
    blockLatexPlaceholders.forEach((placeholder, original) {
      text = text.replaceAll(placeholder, original);
    });

    return text;
  }

  // Parse text into LaTeX and non-LaTeX segments
  static List<Map<String, dynamic>> _parseTextWithLatex(String text) {
    final List<Map<String, dynamic>> segments = [];

    // Regex patterns for different LaTeX expressions
    // Note: $...$ is converted to \(...\) before this step
    final latexPatterns = [
      RegExp(r'\$\$[\s\S]*?\$\$'), // Block math $$...$$
      RegExp(r'\\\[[\s\S]*?\\\]'), // Block math \[...\]
      RegExp(r'\\\([\s\S]*?\\\)'), // Inline math \(...\)
    ];

    int currentIndex = 0;

    while (currentIndex < text.length) {
      int nearestLatexStart = text.length;
      RegExp? matchingPattern;
      RegExpMatch? nearestMatch;

      // Find the nearest LaTeX expression
      for (final pattern in latexPatterns) {
        final remainingText = text.substring(currentIndex);
        final match = pattern.firstMatch(remainingText);
        if (match != null) {
          final matchStart = currentIndex + match.start;
          if (matchStart < nearestLatexStart) {
            nearestLatexStart = matchStart;
            matchingPattern = pattern;
            nearestMatch = match;
          }
        }
      }

      // If no LaTeX found, add remaining text as regular segment
      if (matchingPattern == null || nearestMatch == null) {
        if (currentIndex < text.length) {
          final remainingText = text.substring(currentIndex);
          if (remainingText.trim().isNotEmpty) {
            segments.add({
              'text': remainingText,
              'isLatex': false,
            });
          }
        }
        break;
      }

      // Add text before LaTeX as regular segment
      if (nearestLatexStart > currentIndex) {
        final beforeLatex = text.substring(currentIndex, nearestLatexStart);
        if (beforeLatex.isNotEmpty) {
          segments.add({
            'text': beforeLatex,
            'isLatex': false,
          });
        }
      }

      // Add LaTeX segment
      final latexText = nearestMatch.group(0)!;
      segments.add({
        'text': latexText,
        'isLatex': true,
      });

      currentIndex = nearestLatexStart + latexText.length;
    }

    return segments;
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

  // Method to build text with inline question box at the exact position
  static Widget _buildTextWithInlineQuestionBox(String originalText,
      String extractedQuestion, Map<String, dynamic> conversation) {
    // Find the position of the question in the original text
    final questionIndex =
        originalText.toLowerCase().indexOf(extractedQuestion.toLowerCase());

    if (questionIndex == -1) {
      // If question not found exactly, try fuzzy matching
      final fuzzyMatch = _findQuestionInText(originalText, extractedQuestion);
      if (fuzzyMatch != null) {
        return _buildSplitTextWithQuestionFromOriginal(
            originalText,
            fuzzyMatch['start']!,
            fuzzyMatch['end']!,
            extractedQuestion,
            conversation);
      }
      // If still not found, show the cleaned text with question at the end (fallback)
      final cleanedText = conversation['text'] ?? originalText;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGptMarkdownWithHighlights(cleanedText, conversation),
          const SizedBox(height: 8),
          _buildQuestionBox(extractedQuestion),
        ],
      );
    }

    // Split text at the exact question position
    return _buildSplitTextWithQuestionFromOriginal(
        originalText,
        questionIndex,
        questionIndex + extractedQuestion.length,
        extractedQuestion,
        conversation);
  }

  // Helper method to find question in text using fuzzy matching
  static Map<String, int>? _findQuestionInText(String text, String question) {
    final questionWords = question.toLowerCase().split(RegExp(r'\s+'));
    final textWords = text.toLowerCase().split(RegExp(r'\s+'));

    // Find the longest consecutive match
    int bestStart = -1;
    int bestEnd = -1;
    int bestMatchLength = 0;

    for (int i = 0; i <= textWords.length - questionWords.length; i++) {
      int matchLength = 0;
      int currentEnd = i;

      for (int j = 0;
          j < questionWords.length && i + j < textWords.length;
          j++) {
        if (textWords[i + j].contains(questionWords[j]) ||
            questionWords[j].contains(textWords[i + j]) ||
            _calculateSimilarity(textWords[i + j], questionWords[j]) > 0.7) {
          matchLength++;
          currentEnd = i + j + 1;
        } else {
          break;
        }
      }

      if (matchLength > bestMatchLength &&
          matchLength >= questionWords.length * 0.7) {
        bestStart = i;
        bestEnd = currentEnd;
        bestMatchLength = matchLength;
      }
    }

    if (bestStart != -1) {
      // Convert word indices back to character indices
      final beforeWords = textWords.take(bestStart).toList();
      final matchWords =
          textWords.skip(bestStart).take(bestEnd - bestStart).toList();

      final startIndex = beforeWords.isEmpty
          ? 0
          : text.toLowerCase().indexOf(textWords[bestStart]);
      final endIndex = startIndex + matchWords.join(' ').length;

      return {'start': startIndex, 'end': endIndex};
    }

    return null;
  }

  // Helper method to calculate string similarity
  static double _calculateSimilarity(String s1, String s2) {
    if (s1 == s2) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    final longer = s1.length > s2.length ? s1 : s2;
    final shorter = s1.length > s2.length ? s2 : s1;

    if (longer.length == 0) return 1.0;

    return (longer.length - _levenshteinDistance(longer, shorter)) /
        longer.length;
  }

  // Helper method to calculate Levenshtein distance
  static int _levenshteinDistance(String s1, String s2) {
    final matrix =
        List.generate(s1.length + 1, (i) => List.filled(s2.length + 1, 0));

    for (int i = 0; i <= s1.length; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j <= s2.length; j++) {
      matrix[0][j] = j;
    }

    for (int i = 1; i <= s1.length; i++) {
      for (int j = 1; j <= s2.length; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + cost
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[s1.length][s2.length];
  }

  // Method to build split text with question box in between (from original text)
  static Widget _buildSplitTextWithQuestionFromOriginal(
      String originalText,
      int questionStart,
      int questionEnd,
      String extractedQuestion,
      Map<String, dynamic> conversation) {
    final beforeText = originalText.substring(0, questionStart).trim();
    final afterText = originalText.substring(questionEnd).trim();

    final List<Widget> widgets = [];

    // Add text before question
    if (beforeText.isNotEmpty) {
      widgets.add(_buildGptMarkdownWithHighlights(beforeText, conversation));
      widgets.add(const SizedBox(height: 8));
    }

    // Add question box
    widgets.add(_buildQuestionBox(extractedQuestion));

    // Add text after question
    if (afterText.isNotEmpty) {
      widgets.add(const SizedBox(height: 8));
      widgets.add(_buildGptMarkdownWithHighlights(afterText, conversation));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  // Method to build the question box
  static Widget _buildQuestionBox(String question) {
    // Convert $...$ to \(...\) for better compatibility
    final processedQuestion = _convertDollarLatexToParentheses(question);

    // Check if question contains LaTeX
    final hasLatex = processedQuestion.contains(r'\(') ||
        processedQuestion.contains(r'\[') ||
        processedQuestion.contains(r'$$');

    return Container(
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
          const SizedBox(height: 4),
          // Render question with LaTeX support if needed
          hasLatex
              ? GptMarkdown(
                  processedQuestion,
                  style: GoogleFonts.raleway(
                    fontSize: 14,
                    color: const Color(0xFF0B1220),
                  ),
                )
              : Text(processedQuestion,
                  style: GoogleFonts.raleway(
                      fontSize: 14, color: const Color(0xFF0B1220))),
        ],
      ),
    );
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
            const SizedBox(width: 4),
          ],
          // Commented out for now - using inline question box instead
          // if (conversation['extractedQuestion'] != null &&
          //     conversation['extractedQuestion']
          //         .toString()
          //         .trim()
          //         .isNotEmpty) ...[
          //   _buildLegendChip('Question', const Color(0xFFF59E0B)),
          // ],
        ],
      ),
    );
  }

  static Widget _buildUserFeedbackSection(Map<String, dynamic>? conversation,
      Function(int)? onToggleFeedback, int? messageIndex) {
    final List<String> correctPoints =
        (conversation?["conversationFeedback"]?['correctPoints'] as List?)
                ?.cast<String>() ??
            [];
    final List<String> incorrectPoints =
        (conversation?["conversationFeedback"]?['incorrectPoints'] as List?)
                ?.cast<String>() ??
            [];
    final List<String> missingPoints =
        (conversation?["conversationFeedback"]?['missingPoints'] as List?)
                ?.cast<String>() ??
            [];

    // Check if feedback data exists
    final bool hasFeedbackData = correctPoints.isNotEmpty ||
        incorrectPoints.isNotEmpty ||
        missingPoints.isNotEmpty ||
        conversation?['correctEvidence'] != null ||
        conversation?['incorrectEvidence'] != null;

    // If no feedback data, show loading state with timeout
    if (!hasFeedbackData) {
      return _FeedbackLoadingWithTimeout(
        messageIndex: messageIndex,
        onTimeout: () => const SizedBox.shrink(),
      );
    }

    // Default to expanded (true) unless explicitly set to false
    final bool isExpanded = conversation?['feedbackExpanded'] != false;

    return GestureDetector(
      onTap: () {
        if (onToggleFeedback != null && messageIndex != null) {
          onToggleFeedback(messageIndex);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        // padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color.fromARGB(255, 163, 216, 29).withOpacity(0.46),
              const Color.fromARGB(255, 246, 59, 171).withOpacity(0.50),
            ],
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
          // border: isExpanded
          //     ? null
          //     : Border.all(
          //         color: const Color(0xFF1D4ED8).withOpacity(0.25),
          //         width: 1,
          //       ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Feedback header (always visible)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left side: Feedback indicators
                  Expanded(
                    child: Row(
                      children: [
                        Text('Mastery Evaluation ',
                            style: GoogleFonts.raleway(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black)),
                        const SizedBox(width: 12),

                        // Correct points indicator

                        if (correctPoints.isNotEmpty) ...[
                          _buildFeedbackIndicator(
                            correctPoints.length,
                            Icons.check_circle,
                            const Color(0xFF059669),
                          ),
                          const SizedBox(width: 12),
                        ],
                        // Incorrect points indicator
                        if (incorrectPoints.isNotEmpty) ...[
                          _buildFeedbackIndicator(
                            incorrectPoints.length,
                            Icons.cancel,
                            const Color(0xFFDC2626),
                          ),
                          const SizedBox(width: 12),
                        ],
                        // Missing points indicator (using doubt/question icon)
                        if (missingPoints.isNotEmpty) ...[
                          _buildFeedbackIndicator(
                            missingPoints.length,
                            Icons.bolt,
                            const Color.fromARGB(246, 242, 138, 10),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Right side: Expand/collapse arrow
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 20,
                    color: const Color(0xFF1D4ED8),
                  ),
                ],
              ),
            ),
            // Expanded feedback details
            if (isExpanded) ...[
              // Subtle separator
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF1D4ED8).withOpacity(0.1),
                      const Color(0xFF1D4ED8).withOpacity(0.3),
                      const Color(0xFF1D4ED8).withOpacity(0.1),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: _buildFeedbackDetails(
                    correctPoints, incorrectPoints, missingPoints),
              ),
            ],
          ],
        ),
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
                      fontSize: 12,
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
                        fontSize: 12,
                        color: Colors.black,
                      ),
                    ),
                  ))
              .toList(),
        ],
        if (incorrectPoints.isNotEmpty) ...[
          const SizedBox(height: 8),
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
                      fontSize: 12,
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
                        fontSize: 12,
                        color: Colors.black,
                      ),
                    ),
                  ))
              .toList(),
        ],
        if (missingPoints.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: const Color.fromARGB(246, 242, 138, 10),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text('Quick Improvements:',
                  style: GoogleFonts.raleway(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color.fromARGB(246, 242, 138, 10),
                  )),
            ],
          ),
          const SizedBox(height: 4),
          ...missingPoints
              .map((evidence) => Padding(
                    padding: const EdgeInsets.only(left: 14, bottom: 2),
                    child: Text(
                      '• $evidence',
                      style: GoogleFonts.raleway(
                        fontSize: 12,
                        color: Colors.black,
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

  static Widget _buildFeedbackIndicator(int count, IconData icon, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '$count',
          style: GoogleFonts.raleway(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: color,
            // height: 1.0, // This ensures consistent text height
          ),
        ),
        const SizedBox(width: 2),
        Icon(
          icon,
          size: 18,
          color: color,
        ),
      ],
    );
  }

  static Widget _buildAssistantLoadingState() {
    return Shimmer.fromColors(
      baseColor: Colors.black,
      highlightColor: const Color(0xFFFFFBF2).withOpacity(0.8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Text(
              'Generating response',
              style: GoogleFonts.raleway(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 8),
            // SizedBox(
            //   height: 16,
            //   width: 16,
            //   child: Lottie.asset(
            //     "lib/assets/animations/3-dots.json",
            //     fit: BoxFit.cover,
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  static Widget _buildTranscribingLoadingState() {
    return Shimmer.fromColors(
      baseColor: Colors.black,
      highlightColor: const Color(0xFFFFFBF2).withOpacity(0.8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Transcribing',
              style: GoogleFonts.raleway(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black,
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
        ),
      ),
    );
  }

  static Widget _buildFeedbackLoadingState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color.fromARGB(255, 163, 216, 29).withOpacity(0.46),
            const Color.fromARGB(255, 246, 59, 171).withOpacity(0.50),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
        // border: isExpanded
        //     ? null
        //     : Border.all(
        //         color: const Color(0xFF1D4ED8).withOpacity(0.25),
        //         width: 1,
        //       ),
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.black,
        highlightColor: const Color(0xFFFFFBF2).withOpacity(0.8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: Row(
            children: [
              Text(
                'Evaluating mastery',
                style: GoogleFonts.raleway(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const Spacer(),
              SizedBox(
                height: 16,
                width: 16,
                child: Lottie.asset(
                  "lib/assets/animations/3-dots.json",
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ),
        ),
      ),
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
    // Check if boardText contains LaTeX
    final hasLatex = boardText.contains(r'\(') ||
        boardText.contains(r'\[') ||
        boardText.contains(r'$$');

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7DEC9)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: hasLatex
          ? GptMarkdown(
              boardText,
              style: GoogleFonts.raleway(
                color: const Color(0xFF0B1220),
                fontSize: 14,
              ),
            )
          : MarkdownBody(
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
}

class _FeedbackSectionWithDivider extends StatefulWidget {
  final Map<String, dynamic>? conversation;
  final Function(int)? onToggleFeedback;
  final int? messageIndex;

  const _FeedbackSectionWithDivider({
    required this.conversation,
    required this.onToggleFeedback,
    required this.messageIndex,
  });

  @override
  State<_FeedbackSectionWithDivider> createState() =>
      _FeedbackSectionWithDividerState();
}

class _FeedbackSectionWithDividerState
    extends State<_FeedbackSectionWithDivider> {
  static final Map<int, bool> _messageTimeouts = {};
  bool _showContent = false;

  @override
  void initState() {
    super.initState();
    _initializeTimeout();
    _checkForContent();
  }

  void _initializeTimeout() {
    final messageIndex = widget.messageIndex;
    if (messageIndex != null && !_messageTimeouts.containsKey(messageIndex)) {
      // Only start timer if this message doesn't have one yet
      _messageTimeouts[messageIndex] = false; // false = not timed out yet

      Future.delayed(const Duration(seconds: 10), () {
        _messageTimeouts[messageIndex] = true; // true = timed out
        if (mounted) {
          setState(() {
            _checkForContent();
          });
        }
      });
    }
  }

  void _checkForContent() {
    final List<String> correctPoints =
        (widget.conversation?["conversationFeedback"]?['correctPoints']
                    as List?)
                ?.cast<String>() ??
            [];
    final List<String> incorrectPoints =
        (widget.conversation?["conversationFeedback"]?['incorrectPoints']
                    as List?)
                ?.cast<String>() ??
            [];
    final List<String> missingPoints =
        (widget.conversation?["conversationFeedback"]?['missingPoints']
                    as List?)
                ?.cast<String>() ??
            [];

    final bool hasFeedbackData = correctPoints.isNotEmpty ||
        incorrectPoints.isNotEmpty ||
        missingPoints.isNotEmpty ||
        widget.conversation?['correctEvidence'] != null ||
        widget.conversation?['incorrectEvidence'] != null;

    final messageIndex = widget.messageIndex;
    final bool hasTimedOut =
        messageIndex != null && (_messageTimeouts[messageIndex] ?? false);

    setState(() {
      // Always show content if there's feedback data, regardless of timeout
      // Only hide if there's no feedback data AND timeout has occurred
      _showContent = hasFeedbackData || (!hasTimedOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_showContent) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        // Subtle separator
        Container(
          height: 1,
          margin: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF1D4ED8).withOpacity(0.2),
                const Color(0xFF1D4ED8).withOpacity(0.05),
                const Color(0xFF1D4ED8).withOpacity(0.2),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        MessageBubbles._buildUserFeedbackSection(
          widget.conversation,
          widget.onToggleFeedback,
          widget.messageIndex,
        ),
      ],
    );
  }
}

class _FeedbackLoadingWithTimeout extends StatefulWidget {
  final int? messageIndex;
  final Widget Function() onTimeout;

  const _FeedbackLoadingWithTimeout({
    required this.messageIndex,
    required this.onTimeout,
  });

  @override
  State<_FeedbackLoadingWithTimeout> createState() =>
      _FeedbackLoadingWithTimeoutState();
}

class _FeedbackLoadingWithTimeoutState
    extends State<_FeedbackLoadingWithTimeout> {
  bool _showLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeTimeout();
  }

  void _initializeTimeout() {
    final messageIndex = widget.messageIndex;
    if (messageIndex != null) {
      // Check if this message has already timed out
      final hasTimedOut =
          _FeedbackSectionWithDividerState._messageTimeouts[messageIndex] ??
              false;
      if (hasTimedOut) {
        _showLoading = false;
        return;
      }

      // If not timed out yet, listen for timeout
      Future.delayed(const Duration(seconds: 7), () {
        if (mounted) {
          setState(() {
            _showLoading = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_showLoading) {
      return const SizedBox.shrink();
    }

    return MessageBubbles._buildFeedbackLoadingState();
  }
}
