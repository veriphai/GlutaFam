import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'ai_tutor_helpers.dart';

class LessonStartComponents {
  static Widget buildGreetingBubble(
    List<Map<String, dynamic>> conversations,
    bool showDots,
    bool resumeLesson,
  ) {
    // Get the first assistant message if it exists
    var greetingMessage =
        conversations.isNotEmpty && conversations[0]['role'] == 'assistant'
            ? conversations[0]['text'] ?? ''
            : '';
    if (resumeLesson) {
      greetingMessage =
          conversations.isNotEmpty && conversations.last['role'] == 'assistant'
              ? conversations.last['text'] ?? ''
              : '';
    }

    // Show loading when conversations are empty or when dots are showing
    final isLoading = conversations.isEmpty || showDots;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7DEC9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                colors: [Color(0xFF22D3EE), Color(0xFF14B8A6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Color(0xFF0B1220),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE7DEC9)),
              ),
              child: isLoading
                  ? Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              const Color(0xFF70695B),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Loading greeting...',
                          style: GoogleFonts.raleway(
                            fontSize: 15,
                            color: const Color(0xFF70695B),
                            height: 1.4,
                          ),
                        ),
                      ],
                    )
                  : _buildGreetingText(greetingMessage),
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildLessonInfoCard(
      List<Map<String, dynamic>> conceptCheckpoints,
      Map<String, dynamic> conceptDetails,
      int completedCheckpoints) {
    final checkpointCount = conceptCheckpoints.length;
    final estimatedTime =
        AITutorHelpers.getEstimatedTime(conceptDetails, conceptCheckpoints);
    final currentLevel = AITutorHelpers.getCurrentDifficultyLevel();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7DEC9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildInfoTile('Checkpoints', '$checkpointCount'),
              const SizedBox(width: 12),
              _buildInfoTile('Time', '$estimatedTime min',
                  icon: Icons.schedule),
              const SizedBox(width: 12),
              _buildInfoTile('Level', currentLevel),
            ],
          ),
          const SizedBox(height: 12),
          _buildProgressBar(checkpointCount, completedCheckpoints),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildLevelButton('Easy', currentLevel),
              const SizedBox(width: 8),
              _buildLevelButton('Medium', currentLevel),
              const SizedBox(width: 8),
              _buildLevelButton('Hard', currentLevel),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Level adjusts time & objectives',
                  style: GoogleFonts.raleway(
                    fontSize: 11,
                    color: const Color(0xFF70695B),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget buildLearningObjectivesCard(
    List<Map<String, dynamic>> conceptCheckpoints,
    bool objectivesExpanded,
    Map<String, bool> expandedObjectives,
    VoidCallback onToggleObjectives,
    Function(bool) onToggleAllObjectives,
    Function(String, bool) onToggleObjectiveItem,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7DEC9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggleObjectives,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.flag, size: 16, color: const Color(0xFF2563EB)),
                  const SizedBox(width: 8),
                  Text(
                    'Learning objectives',
                    style: GoogleFonts.raleway(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0B1220),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE7DEC9)),
                    ),
                    child: Text(
                      '${AITutorHelpers.getTotalObjectivesCount(conceptCheckpoints)}',
                      style: GoogleFonts.raleway(
                        fontSize: 11,
                        color: const Color(0xFF70695B),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    objectivesExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 18,
                    color: const Color(0xFF70695B),
                  ),
                ],
              ),
            ),
          ),
          if (objectivesExpanded) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildToggleButton(
                          'Expand all', () => onToggleAllObjectives(true)),
                      const SizedBox(width: 8),
                      _buildToggleButton(
                          'Collapse all', () => onToggleAllObjectives(false)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...conceptCheckpoints.asMap().entries.map((entry) {
                    final index = entry.key;
                    final checkpoint = entry.value;
                    return _buildObjectiveItem(
                      index,
                      checkpoint,
                      expandedObjectives,
                      onToggleObjectiveItem,
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  static Widget buildTutorControlsCard(
      bool isLoadingLanguageVoice,
      Map<String, String> languageOptions,
      Map<String, String> voiceOptions,
      String selectedLanguage,
      String selectedVoice,
      bool tutorAudioEnabled,
      VoidCallback onShowLanguageSheet,
      VoidCallback onShowVoiceSheet,
      VoidCallback onTutorAudioToggle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7DEC9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.translate, size: 18, color: const Color(0xFF1D4ED8)),
              const SizedBox(width: 8),
              Text(
                'Tutor controls',
                style: GoogleFonts.raleway(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0B1220),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildControlTile(
                  'Language',
                  isLoadingLanguageVoice
                      ? 'Loading...'
                      : (languageOptions[selectedLanguage] ?? selectedLanguage),
                  onTap: isLoadingLanguageVoice ? null : onShowLanguageSheet),
              const SizedBox(width: 8),
              _buildControlTile(
                  'Voice',
                  isLoadingLanguageVoice
                      ? 'Loading...'
                      : (voiceOptions[selectedVoice] ?? selectedVoice),
                  onTap: isLoadingLanguageVoice ? null : onShowVoiceSheet),
              const SizedBox(width: 8),
              _buildControlTile('Tutor voice', tutorAudioEnabled ? 'On' : 'Off',
                  icon: Icons.volume_up, onTap: onTutorAudioToggle),
            ],
          ),
        ],
      ),
    );
  }

  static Widget buildBestPracticesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7DEC9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Best practices with Tuto',
            style: GoogleFonts.raleway(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0B1220),
            ),
          ),
          const SizedBox(height: 8),
          ...const [
            'Speak your first guess; we improve it together.',
            'Change one thing → predict the effect.',
            'Prefer voice; switch to text if it helps.',
          ].map((practice) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ',
                        style: GoogleFonts.raleway(
                            fontSize: 14, color: const Color(0xFF0B1220))),
                    Expanded(
                      child: Text(
                        practice,
                        style: GoogleFonts.raleway(
                          fontSize: 14,
                          color: const Color(0xFF0B1220),
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  static Widget buildStartButton(
    bool resumeLesson,
    VoidCallback onStartDiscussion,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6EDDA),
        border: Border(
          top: BorderSide(color: const Color(0xFFE7DEC9)),
        ),
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: onStartDiscussion,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1D4ED8),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            elevation: 0,
            shadowColor: const Color(0x401D4ED8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.mic, size: 18),
              const SizedBox(width: 8),
              Text(
                resumeLesson ? 'Resume discussion' : 'Start discussion',
                style: GoogleFonts.raleway(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget buildButtonsForLessonHistory(
    bool resumeLesson,
    VoidCallback onStartDiscussion,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6EDDA),
        border: Border(
          top: BorderSide(color: const Color(0xFFE7DEC9)),
        ),
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: onStartDiscussion,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1D4ED8),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            elevation: 0,
            shadowColor: const Color(0x401D4ED8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.mic, size: 18),
              const SizedBox(width: 8),
              Text(
                resumeLesson ? 'Resume discussion' : 'Start discussion',
                style: GoogleFonts.raleway(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to render greeting text with LaTeX support
  static Widget _buildGreetingText(String text) {
    // Convert $...$ to \(...\) for better compatibility
    final processedText = _convertDollarLatexToParentheses(text);

    // Check if text contains LaTeX
    final hasLatex = processedText.contains(r'\(') ||
        processedText.contains(r'\[') ||
        processedText.contains(r'$$');

    if (hasLatex) {
      return GptMarkdown(
        processedText,
        style: GoogleFonts.raleway(
          fontSize: 15,
          color: const Color(0xFF0B1220),
          height: 1.4,
        ),
      );
    } else {
      return Text(
        processedText,
        style: GoogleFonts.raleway(
          fontSize: 15,
          color: const Color(0xFF0B1220),
          height: 1.4,
        ),
      );
    }
  }

  // Convert $...$ LaTeX to \(...\) for better compatibility
  static String _convertDollarLatexToParentheses(String text) {
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

  // Helper widgets
  static Widget _buildProgressBar(
      int totalCheckpoints, int completedCheckpoints) {
    return Row(
      children: List.generate(totalCheckpoints, (index) {
        final isCompleted = index < completedCheckpoints;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(
              left: index > 0 ? 2 : 0,
              right: index < totalCheckpoints - 1 ? 2 : 0,
            ),
            height: 6,
            decoration: BoxDecoration(
              color: isCompleted
                  ? const Color(0xFF1D4ED8)
                  : const Color(0xFFE7DEC9),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }

  static Widget _buildInfoTile(String label, String value, {IconData? icon}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE7DEC9)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.raleway(
                fontSize: 11,
                color: const Color(0xFF70695B),
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 14, color: const Color(0xFF0B1220)),
                  const SizedBox(width: 4),
                ],
                Text(
                  value,
                  style: GoogleFonts.raleway(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0B1220),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildLevelButton(String level, String currentLevel) {
    final isSelected = level == currentLevel;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? const Color(0xFF1D4ED8) : const Color(0xFFE7DEC9),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Text(
        level,
        style: GoogleFonts.raleway(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: const Color(0xFF0B1220),
        ),
      ),
    );
  }

  static Widget _buildToggleButton(String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE7DEC9)),
        ),
        child: Text(
          text,
          style: GoogleFonts.raleway(
            fontSize: 11,
            color: const Color(0xFF0B1220),
          ),
        ),
      ),
    );
  }

  static Widget _buildObjectiveItem(
    int index,
    Map<String, dynamic> checkpoint,
    Map<String, bool> expandedObjectives,
    Function(String, bool) onToggleObjectiveItem,
  ) {
    final isExpanded = expandedObjectives[checkpoint['id']] ?? false;
    final objectives = AITutorHelpers.getObjectivesForCheckpoint(checkpoint);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7DEC9)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => onToggleObjectiveItem(checkpoint['id'], !isExpanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2563EB),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      checkpoint['name'] ?? 'Checkpoint ${index + 1}',
                      style: GoogleFonts.raleway(
                        fontSize: 15,
                        color: const Color(0xFF0B1220),
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${objectives.length}',
                      style: GoogleFonts.raleway(
                        fontSize: 11,
                        color: const Color(0xFF0B1220),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 16,
                    color: const Color(0xFF70695B),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                children: objectives
                    .map(
                      (objective) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('• ',
                                style: GoogleFonts.raleway(
                                    fontSize: 14,
                                    color: const Color(0xFF0B1220))),
                            Expanded(
                              child: Text(
                                objective,
                                style: GoogleFonts.raleway(
                                  fontSize: 14,
                                  color: const Color(0xFF0B1220),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static Widget _buildControlTile(String label, String value,
      {IconData? icon, VoidCallback? onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE7DEC9)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.raleway(
                  fontSize: 11,
                  color: const Color(0xFF70695B),
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 14, color: const Color(0xFF0B1220)),
                    const SizedBox(width: 4),
                  ],
                  Expanded(
                    child: Text(
                      value,
                      style: GoogleFonts.raleway(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0B1220),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
