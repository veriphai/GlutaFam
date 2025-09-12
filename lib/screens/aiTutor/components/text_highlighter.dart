import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ai_tutor_helpers.dart';

class TextHighlighter {
  // Helper method to build highlighted text spans
  static List<TextSpan> buildHighlightedText(
      String text, Map<String, dynamic> conversation) {
    final List<String> keywords =
        (conversation['keywords'] as List?)?.cast<String>() ?? [];
    final List<String> phrases =
        (conversation['phrases'] as List?)?.cast<String>() ?? [];
    final List<String> definitions =
        (conversation['definitions'] as List?)?.cast<String>() ?? [];

    // Combine all terms to highlight, with their respective colors
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

    if (highlightTerms.isEmpty) {
      // No highlighting needed
      return [
        TextSpan(
            text: text,
            style: GoogleFonts.raleway(
                fontSize: 15, height: 1.4, color: const Color(0xFF0B1220)))
      ];
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
            style: GoogleFonts.raleway(
              fontSize: 15,
              height: 1.0, // Tight height to reduce background coverage
              color: Colors.white,
              fontWeight: FontWeight.w600,
              backgroundColor: highlightTerms[term]!.withOpacity(0.8),
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
            AITutorHelpers.findNextMatch(text, currentIndex, sortedTerms);
        final endIndex = nextMatchIndex != -1 ? nextMatchIndex : text.length;

        if (endIndex > currentIndex) {
          spans.add(TextSpan(
              text: text.substring(currentIndex, endIndex),
              style: GoogleFonts.raleway(
                  fontSize: 15, height: 1.4, color: const Color(0xFF0B1220))));
          currentIndex = endIndex;
        }
      }
    }

    return spans;
  }

  // Helper method to build highlighted text with inline question display
  static Widget buildHighlightedTextWithInlineQuestion(
      String text, Map<String, dynamic> conversation) {
    final String? extractedQuestion = conversation['extractedQuestion'];
    final bool isLoading = conversation['isLoading'] == true;

    if (isLoading) {
      // Use regular highlighting without question replacement during loading
      return RichText(
        text: TextSpan(
          children: buildHighlightedText(text, conversation),
        ),
      );
    }

    // If there's no extracted question, just show the regular highlighted text
    if (extractedQuestion == null || extractedQuestion.isEmpty) {
      return RichText(
        text: TextSpan(
          children: buildHighlightedText(text, conversation),
        ),
      );
    }

    // Simple approach: show the text with the question at the end for now
    // We can make this more sophisticated later once we understand the data better
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Show the full original text with highlighting
        RichText(
          text: TextSpan(
            children: buildHighlightedText(text, conversation),
          ),
        ),

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
              Text(extractedQuestion, style: GoogleFonts.raleway(fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }

  // Helper method to build highlighted text spans for user messages with feedback
  static List<TextSpan> buildUserFeedbackHighlightedText(
      String text, Map<String, dynamic> conversation) {
    final List<Map<String, dynamic>> correctEvidence =
        (conversation['correctEvidence'] as List?)
                ?.cast<Map<String, dynamic>>() ??
            [];
    final List<Map<String, dynamic>> incorrectEvidence =
        (conversation['incorrectEvidence'] as List?)
                ?.cast<Map<String, dynamic>>() ??
            [];

    // Combine all evidence to highlight with their respective colors
    final Map<String, Color> highlightTerms = {};

    // Add correct evidence with green highlighting
    for (final evidence in correctEvidence) {
      final text = evidence['text']?.toString().trim() ?? '';
      if (text.isNotEmpty) {
        highlightTerms[text.toLowerCase()] = const Color(0xFF059669);
      }
    }

    // Add incorrect evidence with red highlighting
    for (final evidence in incorrectEvidence) {
      final text = evidence['text']?.toString().trim() ?? '';
      if (text.isNotEmpty) {
        highlightTerms[text.toLowerCase()] = const Color(0xFFDC2626);
      }
    }

    if (highlightTerms.isEmpty) {
      // No highlighting needed
      return [
        TextSpan(
            text: text,
            style: GoogleFonts.raleway(
                fontSize: 15, height: 1.4, color: const Color(0xFF0B1220)))
      ];
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
            style: GoogleFonts.raleway(
              fontSize: 15,
              color: Colors.white,
              fontWeight: FontWeight.w600,
              height: 1.0,
              backgroundColor: highlightTerms[term]!.withOpacity(0.8),
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
            _findNextUserMatch(text, currentIndex, sortedTerms);
        final endIndex = nextMatchIndex != -1 ? nextMatchIndex : text.length;

        if (endIndex > currentIndex) {
          spans.add(TextSpan(
              text: text.substring(currentIndex, endIndex),
              style: GoogleFonts.raleway(
                  fontSize: 15, height: 1.4, color: const Color(0xFF0B1220))));
          currentIndex = endIndex;
        }
      }
    }

    return spans;
  }

  // Helper method to find the next match position for user feedback
  static int _findNextUserMatch(
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
}
