import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'feedback_cards.dart';

class CommonUIComponents {
  static Widget circleAction({
    required IconData icon,
    required VoidCallback onTap,
    bool dense = false,
    String? tooltip,
  }) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          height: dense ? 36 : 40,
          width: dense ? 36 : 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE7DEC9)),
          ),
          alignment: Alignment.center,
          child:
              Icon(icon, size: dense ? 18 : 20, color: const Color(0xFF0B1220)),
        ),
      ),
    );
  }

  static Widget menuItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE7DEC9)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF0B1220), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.raleway(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0B1220)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget languageOption(
    String id,
    String name,
    String selectedLanguage,
    Function(String) onLanguageSelected,
  ) {
    final isSelected = selectedLanguage == id;
    return InkWell(
      onTap: () => onLanguageSelected(id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected ? const Color(0xFF1D4ED8) : const Color(0xFFE7DEC9),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.raleway(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0B1220),
                    ),
                  ),
                  Text(
                    id,
                    style: GoogleFonts.raleway(
                      fontSize: 12,
                      color: const Color(0xFF70695B),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFF1D4ED8)),
          ],
        ),
      ),
    );
  }

  static Widget voiceOption(
    String id,
    String name,
    String selectedVoice,
    Function(String) onVoiceSelected,
  ) {
    final isSelected = selectedVoice == id;
    return InkWell(
      onTap: () => onVoiceSelected(id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected ? const Color(0xFF1D4ED8) : const Color(0xFFE7DEC9),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.raleway(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0B1220),
                    ),
                  ),
                  Text(
                    id,
                    style: GoogleFonts.raleway(
                      fontSize: 12,
                      color: const Color(0xFF70695B),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFF1D4ED8)),
          ],
        ),
      ),
    );
  }

  static void showLanguageBottomSheet(
    BuildContext context,
    Map<String, String> languageOptions,
    String selectedLanguage,
    Function(String) onLanguageSelected,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFFFBF2),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFE7DEC9),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Choose language',
                        style: GoogleFonts.raleway(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0B1220),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Color(0xFF70695B)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...languageOptions.entries.map((entry) => languageOption(
                        entry.key,
                        entry.value,
                        selectedLanguage,
                        (id) {
                          Navigator.pop(context);
                          onLanguageSelected(id);
                        },
                      )),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void showVoiceBottomSheet(
    BuildContext context,
    Map<String, String> voiceOptions,
    String selectedVoice,
    Function(String) onVoiceSelected,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFFFBF2),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFE7DEC9),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Choose voice',
                        style: GoogleFonts.raleway(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0B1220),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Color(0xFF70695B)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...voiceOptions.entries.map((entry) => voiceOption(
                        entry.key,
                        entry.value,
                        selectedVoice,
                        (id) {
                          Navigator.pop(context);
                          onVoiceSelected(id);
                        },
                      )),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void showMenuSheet(
    BuildContext context,
    VoidCallback onJumpToNext,
    VoidCallback onStartQuestions,
    VoidCallback onShowGaps,
    VoidCallback onShowCpFeedback,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFFFBF2),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 5,
                width: 60,
                decoration: BoxDecoration(
                    color: const Color(0xFFE7DEC9),
                    borderRadius: BorderRadius.circular(999)),
              ),
              const SizedBox(height: 12),
              menuItem(
                icon: Icons.psychology_outlined,
                text: "Show all gaps",
                onTap: () {
                  Navigator.pop(context);
                  onShowGaps();
                },
              ),
              const SizedBox(height: 8),
              menuItem(
                icon: Icons.skip_next,
                text: "Jump to next checkpoint",
                onTap: () {
                  Navigator.pop(context);
                  onJumpToNext();
                },
              ),
              // const SizedBox(height: 8),
              // menuItem(
              //   icon: Icons.checklist_rtl,
              //   text: "Start questions · +45 XP",
              //   onTap: () {
              //     Navigator.pop(context);
              //     onStartQuestions();
              //   },
              // ),
              // const SizedBox(height: 8),
              // menuItem(
              //   icon: Icons.analytics_outlined,
              //   text: "Show CP Feedback",
              //   onTap: () {
              //     Navigator.pop(context);
              //     onShowCpFeedback();
              //   },
              // ),
            ],
          ),
        );
      },
    );
  }

  static void showGapsSheet(
    BuildContext context,
    Map<int, List<Map<String, dynamic>>> conversationGaps,
    Set<String> resolvedGaps,
    Map<String, List<Map<String, dynamic>>> gapConversations,
    Map<String, bool> expandedGaps,
    Map<String, TextEditingController> gapTextControllers,
    Map<String, bool> gapLoadingStates,
    Function(String) onToggleGapExpansion,
    Function(String, String) onSendGapMessage,
    Function(String, File) onSendGapAudio,
    Function(Map<String, dynamic>) onDismissGap,
    String conceptId,
    String studentName,
    int checkpointNo,
    String conceptConversationsKey,
    int remainingTime,
    String language,
    String voice,
  ) {
    // Collect all gaps from conversationGaps
    List<Map<String, dynamic>> allGaps = [];
    conversationGaps.forEach((turnIndex, gaps) {
      for (var gap in gaps) {
        allGaps.add({
          ...gap,
          'turnIndex': turnIndex,
        });
      }
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Color(0xFFFFFBF2),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFE7DEC9),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'All Learning Gaps',
                    style: GoogleFonts.raleway(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0B1220),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Color(0xFF70695B)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: allGaps.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.psychology_outlined,
                            size: 64,
                            color: const Color(0xFF70695B),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No gaps identified yet',
                            style: GoogleFonts.raleway(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF70695B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Keep learning and gaps will appear here',
                            style: GoogleFonts.raleway(
                              fontSize: 14,
                              color: const Color(0xFF70695B),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                      itemCount: allGaps.length,
                      itemBuilder: (context, index) {
                        final gap = allGaps[index];
                        final turnIndex = gap['turnIndex'] as int;

                        // Create a gap without the turnIndex for the FeedbackCards.gapCard
                        final gapForCard = Map<String, dynamic>.from(gap);
                        gapForCard.remove('turnIndex');

                        return FeedbackCards.gapCard(
                          gapForCard,
                          turnIndex,
                          resolvedGaps,
                          (gapData) =>
                              onToggleGapExpansion(gapData['id'] ?? ''),
                          onDismissGap,
                          gapConversations: gapConversations,
                          expandedGaps: expandedGaps,
                          gapTextControllers: gapTextControllers,
                          gapLoadingStates: gapLoadingStates,
                          onSendGapMessage: onSendGapMessage,
                          onSendGapAudio: onSendGapAudio,
                          onToggleGapExpansion: onToggleGapExpansion,
                          conceptId: conceptId,
                          studentName: studentName,
                          checkpointNo: checkpointNo,
                          conceptConversationsKey: conceptConversationsKey,
                          remainingTime: remainingTime,
                          language: language,
                          voice: voice,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  static void showPromptSheet(
    BuildContext context,
    Function(String, String) onPromptSelected,
  ) {
    final Map<String, String> promptTypeToDisplay = {
      'give_examples': 'Give me examples',
      'explain_simple': 'Explain in simple way',
      'go_deeper': 'Go deeper',
      'give_hint': 'Give me a hint',
      'clarify_doubt': 'Clarify my doubt',
      'provide_analogy': 'Give me an analogy',
      'show_real_world_application': 'Show real-world applications',
      'break_down_steps': 'Break it down step by step',
      'visual_explanation': 'Explain visually',
      'practice_questions': 'Give me practice questions',
      'summarize': 'Summarize this topic',
      'connect_to_previous': 'How does this connect to what we learned before?'
    };

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFFFBF2),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Ask it your way",
                  style: GoogleFonts.raleway(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0B1220))),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: promptTypeToDisplay.entries.map((entry) {
                  final type = entry.key;
                  final label = entry.value;
                  return OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onPromptSelected(type, label);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0B1220),
                      side: const BorderSide(color: Color(0xFFE7DEC9)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child:
                        Text(label, style: GoogleFonts.raleway(fontSize: 13)),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  static void showCpFeedbackSheet(
    BuildContext context,
    Map<String, dynamic>? cpFeedback,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFFFBF2),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 5,
                    width: 60,
                    decoration: BoxDecoration(
                        color: const Color(0xFFE7DEC9),
                        borderRadius: BorderRadius.circular(999)),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'CP Feedback',
                        style: GoogleFonts.raleway(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0B1220),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Color(0xFF70695B)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: cpFeedback == null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.analytics_outlined,
                                  size: 48,
                                  color: const Color(0xFF70695B),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No CP Feedback available yet',
                                  style: GoogleFonts.raleway(
                                    fontSize: 16,
                                    color: const Color(0xFF70695B),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  Border.all(color: const Color(0xFFE7DEC9)),
                            ),
                            child: SingleChildScrollView(
                              controller: scrollController,
                              child: SelectableText(
                                _formatJson(cpFeedback),
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 12,
                                  color: const Color(0xFF0B1220),
                                ),
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static String _formatJson(Map<String, dynamic>? data) {
    if (data == null) return 'No data available';

    try {
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(data);
    } catch (e) {
      return data.toString();
    }
  }
}
