class AITutorHelpers {
  static String formatTime(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return "$m:$sec";
  }

  static double calculateProgress(int currentIndex, int totalCheckpoints) {
    if (totalCheckpoints == 0) return 0.0;
    return (currentIndex + 1) / totalCheckpoints;
  }

  static String makeHint() {
    return "Start from what you already know → define terms in your own words → make one small prediction. If unsure, compare two tiny examples.";
  }

  // Helper method to remove extracted question from original message text
  static String removeQuestionFromText(
      String originalText, String questionToRemove) {
    if (originalText.isEmpty || questionToRemove.isEmpty) {
      return originalText;
    }

    // Try exact match removal first
    String cleanedText = originalText.replaceAll(questionToRemove, '').trim();

    // If exact match didn't work, try fuzzy matching
    if (cleanedText == originalText) {
      // Split question into words and try to find and remove the longest matching substring
      final questionWords =
          questionToRemove.toLowerCase().split(RegExp(r'\s+'));
      final originalWords = originalText.toLowerCase().split(RegExp(r'\s+'));

      // Find the longest consecutive match
      int bestStart = -1;
      int bestLength = 0;

      for (int i = 0; i <= originalWords.length - questionWords.length; i++) {
        int matchLength = 0;
        for (int j = 0;
            j < questionWords.length && i + j < originalWords.length;
            j++) {
          if (originalWords[i + j].contains(questionWords[j]) ||
              questionWords[j].contains(originalWords[i + j])) {
            matchLength++;
          } else {
            break;
          }
        }

        if (matchLength > bestLength &&
            matchLength >= questionWords.length * 0.7) {
          bestStart = i;
          bestLength = matchLength;
        }
      }

      if (bestStart != -1) {
        final originalWordsList = originalText.split(RegExp(r'\s+'));
        originalWordsList.removeRange(bestStart, bestStart + bestLength);
        cleanedText = originalWordsList.join(' ').trim();
      }
    }

    // Clean up any double spaces or punctuation issues
    cleanedText = cleanedText
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'\s+([.!?])'), r'$1')
        .trim();

    return cleanedText.isNotEmpty ? cleanedText : originalText;
  }

  // Helper method to get unique gap ID
  static String getGapId(Map<String, dynamic> gap) {
    return gap['id'] ?? '';
    // final text = gap['text'] ?? '';
    // final severity = gap['severity'] ?? 0;
    // return '${text}_$severity';
  }

  // Helper method to check if gap is resolved
  static bool isGapResolved(
      Map<String, dynamic> gap, Set<String> resolvedGaps) {
    return resolvedGaps.contains(getGapId(gap));
  }

  // Helper method to get gaps for current conversation turn
  static List<Map<String, dynamic>> getActiveGapsForTurn(
      int turnIndex,
      Map<int, List<Map<String, dynamic>>> conversationGaps,
      Set<String> resolvedGaps) {
    final gaps = conversationGaps[turnIndex] ?? [];
    return gaps.where((gap) => !isGapResolved(gap, resolvedGaps)).toList();
  }

  // Helper method to store gaps for a conversation turn
  static void storeGapsForTurn(int turnIndex, List<Map<String, dynamic>> gaps,
      Map<int, List<Map<String, dynamic>>> conversationGaps) {
    if (gaps.isNotEmpty) {
      conversationGaps[turnIndex] = gaps;
    }
  }

  // Helper method to find the next match position
  static int findNextMatch(String text, int startIndex, List<String> terms) {
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

  // Helper method to extract tutor notes from latest response
  static Map<String, dynamic> extractTutorNotesFromLatest(
      Map<String, dynamic> latestTutorResponse) {
    if (latestTutorResponse.isEmpty) return {};

    // Get tutorThoughts object, return empty if it doesn't exist
    final tutorThoughts = latestTutorResponse['tutorThoughts'];
    if (tutorThoughts == null || tutorThoughts is! Map<String, dynamic>) {
      return {};
    }

    final correct = tutorThoughts['correct'];
    final wrong = tutorThoughts['wrong'];
    final partiallyCorrect = tutorThoughts['partially'];
    final doubt = tutorThoughts['doubt'];
    final misconception = tutorThoughts['misconception'];
    final notes = <String, dynamic>{
      'correct': correct,
      'wrong': wrong,
      'partiallyCorrect': partiallyCorrect,
      'doubt': doubt,
      'misconception': misconception,
    };
    notes.removeWhere((key, value) {
      if (value == null) return true;
      if (value is String) return value.trim().isEmpty;
      return false;
    });
    return notes;
  }

  // Helper method to extract tutor notes from individual conversation message
  static Map<String, dynamic> extractTutorNotesFromMessage(
      Map<String, dynamic> conversationMessage) {
    if (conversationMessage.isEmpty) return {};

    // First check if notes are already stored in the message
    if (conversationMessage.containsKey('tutorNotes')) {
      final existingNotes = conversationMessage['tutorNotes'];
      if (existingNotes is Map<String, dynamic>) {
        return Map<String, dynamic>.from(existingNotes);
      }
    }

    // If no stored notes, try to extract from tutorThoughts in the message
    final tutorThoughts = conversationMessage['tutorThoughts'];
    if (tutorThoughts == null || tutorThoughts is! Map<String, dynamic>) {
      return {};
    }

    final correct = tutorThoughts['correct'];
    final wrong = tutorThoughts['wrong'];
    final partiallyCorrect = tutorThoughts['partially'];
    final doubt = tutorThoughts['doubt'];
    final misconception = tutorThoughts['misconception'];
    final notes = <String, dynamic>{
      'correct': correct,
      'wrong': wrong,
      'partiallyCorrect': partiallyCorrect,
      'doubt': doubt,
      'misconception': misconception,
    };
    notes.removeWhere((key, value) {
      if (value == null) return true;
      if (value is String) return value.trim().isEmpty;
      return false;
    });
    return notes;
  }

  // Helper method to store tutor notes permanently in a conversation message
  static void storeTutorNotesInMessage(
      Map<String, dynamic> conversationMessage) {
    if (conversationMessage['role'] != 'assistant') return;

    final notes = extractTutorNotesFromMessage(conversationMessage);
    if (notes.isNotEmpty) {
      conversationMessage['tutorNotes'] = notes;
    }
  }

  // Helper method to store board text permanently in a conversation message
  static void storeBoardTextInMessage(
      Map<String, dynamic> conversationMessage,
      List<Map<String, dynamic>> conceptCheckpoints,
      int currentCheckpointIndex) {
    if (conversationMessage['role'] != 'assistant') return;

    // Get the board text from the current checkpoint when the message is created
    final String boardText = conceptCheckpoints.isNotEmpty &&
            currentCheckpointIndex < conceptCheckpoints.length
        ? (conceptCheckpoints[currentCheckpointIndex]['blackboardText'] ?? '')
        : '';

    if (boardText.isNotEmpty) {
      conversationMessage['boardText'] = boardText;
    }
  }

  // Helper method to extract board text from a conversation message
  static String extractBoardTextFromMessage(
      Map<String, dynamic> conversationMessage) {
    if (conversationMessage['role'] != 'assistant') return '';

    // Return stored board text or empty string
    return conversationMessage['boardText'] ?? '';
  }

  // Helper method to get objectives for checkpoint
  static List<String> getObjectivesForCheckpoint(
      Map<String, dynamic> checkpoint) {
    // First try checkpoint-specific learning objectives
    final checkpointObjectives =
        checkpoint['learningObjective'] as List<dynamic>?;
    if (checkpointObjectives != null && checkpointObjectives.isNotEmpty) {
      return checkpointObjectives
          .map((obj) => obj.toString())
          .where((obj) => obj.isNotEmpty)
          .toList();
    }

    // Then try checkpoint's learning objective properties
    final List<String> objectives = [];

    // Check for specific learning objective fields in the checkpoint
    final fields = ['learningObjective', 'objective', 'description', 'summary'];
    for (final field in fields) {
      final value = checkpoint[field];
      if (value != null && value.toString().trim().isNotEmpty) {
        objectives.add(value.toString().trim());
      }
    }

    if (objectives.isNotEmpty) {
      return objectives;
    }

    // Fallback to checkpoint name
    final name = checkpoint['name'] ?? '';
    if (name.isNotEmpty) {
      return [name];
    }

    // Default objectives if no data available
    return ['Complete this checkpoint successfully'];
  }

  // Helper method to get total objectives count
  static int getTotalObjectivesCount(
      List<Map<String, dynamic>> conceptCheckpoints) {
    int total = 0;
    for (var checkpoint in conceptCheckpoints) {
      total += getObjectivesForCheckpoint(checkpoint).length;
    }
    return total;
  }

  // Helper method to get estimated time
  static int getEstimatedTime(Map<String, dynamic> conceptDetails,
      List<Map<String, dynamic>> conceptCheckpoints) {
    // Use actual expectedCompletionTime from concept details
    final expectedTime = conceptDetails["expectedCompletionTime"];
    if (expectedTime != null && expectedTime is int) {
      return expectedTime; // Already in minutes
    }

    // Fallback calculation if no expected time
    if (conceptCheckpoints.isEmpty) return 15;
    return conceptCheckpoints.length * 5; // 5 minutes per checkpoint
  }

  // Helper method to get current difficulty level
  static String getCurrentDifficultyLevel() {
    // For now, default to Medium. You can implement level selection logic here
    return 'Medium';
  }
}
