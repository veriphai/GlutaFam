import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'dart:io';
import 'ai_tutor_helpers.dart';

class FeedbackCards {
  static Widget gapCard(
    Map<String, dynamic> gap,
    int turnIndex,
    Set<String> resolvedGaps,
    Function(Map<String, dynamic>) onResolveGap,
    Function(Map<String, dynamic>) onDismissGap, {
    Map<String, List<Map<String, dynamic>>>? gapConversations,
    Map<String, bool>? expandedGaps,
    Map<String, TextEditingController>? gapTextControllers,
    Map<String, bool>? gapLoadingStates,
    Function(String, String)? onSendGapMessage,
    Function(String, File)? onSendGapAudio,
    Function(String)? onToggleGapExpansion,
    String? conceptId,
    String? studentName,
    int? checkpointNo,
    String? conceptConversationsKey,
    int? remainingTime,
    String? language,
    String? voice,
  }) {
    final String text = gap['text'] ?? '';
    final int severity = gap['severity'] ?? 0;
    final double confidence = (gap['confidence'] ?? 0.0) is num
        ? (gap['confidence'] as num).toDouble()
        : double.tryParse('${gap['confidence']}') ?? 0.0;

    // Check if gap is resolved
    final bool isResolved = AITutorHelpers.isGapResolved(gap, resolvedGaps);

    // Color coding based on resolved status and severity
    Color cardColor, borderColor, iconBgColor, titleColor;
    IconData iconData;
    String statusText;

    if (isResolved) {
      // Green theme for resolved gaps
      cardColor = const Color(0xFFF0FDF4); // Light green
      borderColor = const Color(0xFF84CC16); // Green border
      iconBgColor = const Color(0xFF16A34A); // Green background for icon
      titleColor = const Color(0xFF15803D); // Dark green for text
      iconData = Icons.check_circle;
      statusText = 'Gap resolved';
    } else if (severity == 1) {
      // Yellow theme for severity 1
      cardColor = const Color(0xFFFFFBEB); // Light yellow
      borderColor = const Color(0xFFFDE047); // Yellow border
      iconBgColor = const Color(0xFFEAB308); // Yellow background for icon
      titleColor = const Color(0xFFCA8A04); // Darker yellow for text
      iconData = Icons.warning;
      statusText = 'Gap identified';
    } else {
      // Red theme for severity 2+
      cardColor = const Color(0xFFFDF2F8); // Light pink
      borderColor = const Color(0xFFFDA4AF); // Pink border
      iconBgColor = const Color(0xFFDC2626); // Red background for icon
      titleColor = const Color(0xFFDC2626); // Red for text
      iconData = Icons.warning;
      statusText = 'Gap identified';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with warning icon and "Gap identified"
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    iconData,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  statusText,
                  style: GoogleFonts.raleway(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
                const Spacer(),
                // Severity indicator
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: iconBgColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Level $severity',
                    style: GoogleFonts.raleway(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: titleColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Gap description
            Text(
              text,
              style: GoogleFonts.raleway(
                fontSize: 14,
                color: const Color(0xFF374151),
                height: 1.4,
              ),
            ),

            // Confidence indicator
            if (confidence > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Confidence: ${(confidence * 100).toStringAsFixed(0)}%',
                style: GoogleFonts.raleway(
                  fontSize: 12,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Check if gap conversation is expanded
            ...() {
              if (expandedGaps == null || gapConversations == null) {
                return <Widget>[];
              }

              final String gapId = AITutorHelpers.getGapId(gap);
              final bool isExpanded = expandedGaps[gapId] ?? false;
              final List<Map<String, dynamic>> conversations =
                  gapConversations[gapId] ?? [];

              if (!isExpanded) {
                return <Widget>[];
              }

              return [
                // Conversation area
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor.withOpacity(0.3)),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Conversation header
                      Row(
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 16,
                            color: titleColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Gap Resolution Chat',
                            style: GoogleFonts.raleway(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: titleColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Conversation messages
                      if (conversations.isNotEmpty) ...[
                        Container(
                          constraints: const BoxConstraints(maxHeight: 300),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: conversations.length,
                            itemBuilder: (context, index) {
                              final conversation = conversations[index];
                              final role = conversation['role'];

                              if (role == 'assistant') {
                                return _buildGapAssistantBubble(
                                  conversation['text'] ?? '',
                                  conversation,
                                );
                              } else if (role == 'user') {
                                return _buildGapUserBubble(
                                  conversation['text'] ?? '',
                                  conversation,
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Input area
                      if (gapTextControllers != null &&
                          onSendGapMessage != null) ...[
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: gapTextControllers[gapId],
                                decoration: InputDecoration(
                                  hintText: 'Ask about this gap...',
                                  hintStyle: GoogleFonts.raleway(
                                    fontSize: 14,
                                    color: const Color(0xFF9CA3AF),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: BorderSide(
                                      color: borderColor,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: BorderSide(
                                      color: borderColor,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: BorderSide(
                                      color: iconBgColor,
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                                style: GoogleFonts.raleway(fontSize: 14),
                                maxLines: null,
                                textCapitalization:
                                    TextCapitalization.sentences,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Send button
                            Container(
                              decoration: BoxDecoration(
                                color: iconBgColor,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                onPressed: (gapLoadingStates?[gapId] ?? false)
                                    ? null
                                    : () {
                                        final text = gapTextControllers[gapId]
                                                ?.text
                                                .trim() ??
                                            '';
                                        if (text.isNotEmpty) {
                                          onSendGapMessage(gapId, text);
                                          gapTextControllers[gapId]?.clear();
                                        }
                                      },
                                icon: (gapLoadingStates?[gapId] ?? false)
                                    ? SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            Colors.white,
                                          ),
                                        ),
                                      )
                                    : const Icon(
                                        Icons.send,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ];
            }(),

            // Action buttons - different for resolved gaps
            if (!isResolved)
              Row(
                children: [
                  // Resolve now button - now toggles conversation
                  Expanded(
                    child: ElevatedButton(
                      onPressed: null, // Disabled button
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(0xFF9CA3AF), // Grayed out background
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        disabledBackgroundColor: const Color(0xFF9CA3AF),
                        disabledForegroundColor: Colors.white,
                      ),
                      child: Text(
                        'Resolve Now - Coming soon',
                        style: GoogleFonts.raleway(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Later button
                  // Expanded(
                  //   child: OutlinedButton(
                  //     onPressed: () => onDismissGap(gap),
                  //     style: OutlinedButton.styleFrom(
                  //       foregroundColor: const Color(0xFF6B7280),
                  //       side: const BorderSide(color: Color(0xFFD1D5DB)),
                  //       shape: RoundedRectangleBorder(
                  //         borderRadius: BorderRadius.circular(8),
                  //       ),
                  //       padding: const EdgeInsets.symmetric(vertical: 12),
                  //     ),
                  //     child: Text(
                  //       'Later',
                  //       style: GoogleFonts.raleway(
                  //         fontSize: 14,
                  //         fontWeight: FontWeight.w600,
                  //       ),
                  //     ),
                  //   ),
                  // ),
                ],
              )
            else
              // Resolved gap status message
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: const Color(0xFF16A34A),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'This gap has been resolved',
                          style: GoogleFonts.raleway(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF16A34A),
                          ),
                        ),
                      ],
                    ),
                    if (confidence > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Resolution confidence: ${(confidence * 100).toStringAsFixed(0)}%',
                        style: GoogleFonts.raleway(
                          fontSize: 12,
                          color: const Color(0xFF15803D),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  static Widget turnFeedbackCard(
    Map<String, dynamic> fb,
    Function(Map<String, dynamic>) onResolveFeedback,
    Function(Map<String, dynamic>) onDismissFeedback,
  ) {
    final List missingPts = (fb['missingPoints'] ?? []) as List;

    // Only show feedback if there are gaps (missing points)
    if (missingPts.isEmpty) {
      return const SizedBox.shrink();
    }

    // Combine all missing points into a single gap description
    final String gapDescription = missingPts.take(2).join(' ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFDF2F8), // Light pink background
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFDA4AF)), // Pink border
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with warning icon and "Gap identified"
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626), // Red background for icon
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.warning,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Gap identified',
                  style: GoogleFonts.raleway(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFDC2626),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Gap description
            Text(
              gapDescription,
              style: GoogleFonts.raleway(
                fontSize: 14,
                color: const Color(0xFF374151),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                // Resolve now button
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => onResolveFeedback(fb),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D4ED8),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                    child: Text(
                      'Resolve now',
                      style: GoogleFonts.raleway(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Later button
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => onDismissFeedback(fb),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF6B7280),
                      side: const BorderSide(color: Color(0xFFD1D5DB)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Later',
                      style: GoogleFonts.raleway(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget cumulativeFeedbackCard(
    Map<String, dynamic> cp,
    Function(Map<String, dynamic>) onResolveFeedback,
    Function(Map<String, dynamic>) onDismissFeedback,
  ) {
    final List unresolved = (cp['unresolvedGaps'] ?? []) as List;

    // Only show feedback if there are unresolved gaps
    if (unresolved.isEmpty) {
      return const SizedBox.shrink();
    }

    // Combine unresolved gaps into a single description
    final String gapDescription = unresolved
        .take(2)
        .map((g) => '${g['summary'] ?? g['text'] ?? g}')
        .join(' ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFDF2F8), // Light pink background
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFDA4AF)), // Pink border
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with warning icon and "Gap identified"
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626), // Red background for icon
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.warning,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Gap identified',
                  style: GoogleFonts.raleway(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFDC2626),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Gap description
            Text(
              gapDescription,
              style: GoogleFonts.raleway(
                fontSize: 14,
                color: const Color(0xFF374151),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                // Resolve now button
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => onResolveFeedback(cp),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D4ED8),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                    child: Text(
                      'Resolve now',
                      style: GoogleFonts.raleway(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Later button
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => onDismissFeedback(cp),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF6B7280),
                      side: const BorderSide(color: Color(0xFFD1D5DB)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Later',
                      style: GoogleFonts.raleway(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build assistant bubble for gap conversations
  static Widget _buildGapAssistantBubble(
    String text,
    Map<String, dynamic> conversation,
  ) {
    final isLoading = conversation['isLoading'] == true;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Small avatar
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFF1D4ED8),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.smart_toy,
              color: Colors.white,
              size: 14,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: isLoading
                  ? SizedBox(
                      height: 16,
                      width: 16,
                      child: Lottie.asset(
                        "lib/assets/animations/3-dots.json",
                        fit: BoxFit.cover,
                      ),
                    )
                  : Text(
                      text,
                      style: GoogleFonts.raleway(
                        fontSize: 13,
                        color: const Color(0xFF374151),
                        height: 1.3,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build user bubble for gap conversations
  static Widget _buildGapUserBubble(
    String text,
    Map<String, dynamic> conversation,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1D4ED8).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: const Color(0xFF1D4ED8).withOpacity(0.3)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Text(
                text,
                style: GoogleFonts.raleway(
                  fontSize: 13,
                  color: const Color(0xFF1E40AF),
                  height: 1.3,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Small user icon
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFF1D4ED8),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 14,
            ),
          ),
        ],
      ),
    );
  }

  static Widget checkpointFeedbackCard(
    int checkpointIndex,
    String feedbackState, // 'loading', 'ready', 'error', 'failed'
    dynamic feedbackData,
    Function() onViewFeedback, {
    bool showDismissButton = false,
    Function()? onDismiss,
    Function(int)? onRetryFeedback,
  }) {
    Widget cardContent;
    Color cardColor;
    Color borderColor;

    switch (feedbackState) {
      case 'loading':
        // Return the beautiful loading card directly
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: _buildLoadingFeedbackContent(checkpointIndex),
        );
      case 'ready':
        cardColor = const Color(0xFFE8F5E8); // Light green
        borderColor = const Color(0xFF4CAF50); // Green border
        cardContent = _buildReadyFeedbackContent(onViewFeedback, feedbackData);
        break;
      case 'error':
        cardColor = const Color(0xFFFFEBEE); // Light red
        borderColor = const Color(0xFFF44336); // Red border
        cardContent = _buildErrorFeedbackContent();
        break;
      case 'failed':
        cardColor = const Color(0xFFFFEBEE); // Light red
        borderColor = const Color(0xFFF44336); // Red border
        cardContent =
            _buildFailedFeedbackContent(checkpointIndex, onRetryFeedback);
        break;
      default:
        return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with checkpoint number and dismiss button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Text(
                    'Checkpoint ${checkpointIndex + 1}',
                    style: GoogleFonts.raleway(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF70695B),
                    ),
                  ),
                  const Spacer(),
                  if (showDismissButton && onDismiss != null)
                    GestureDetector(
                      onTap: onDismiss,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF70695B).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF70695B).withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Dismiss',
                              style: GoogleFonts.raleway(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF70695B),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.close,
                              size: 12,
                              color: const Color(0xFF70695B),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Main content
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: cardContent,
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildLoadingFeedbackContent([int? checkpointNumber]) {
    return LoadingFeedbackCard(checkpointNumber: checkpointNumber);
  }

  static Widget _buildReadyFeedbackContent(
      Function() onViewFeedback, dynamic feedbackData) {
    // Calculate mastery grade and learning gaps info
    String masteryGrade = 'B+';
    int totalGaps = 0;
    int resolvedGaps = 0;

    if (feedbackData != null) {
      try {
        // Calculate mastery grade from objectives score
        final objectives = feedbackData.objectives;
        if (objectives != null && objectives.isNotEmpty) {
          double totalScore = 0.0;
          for (var obj in objectives) {
            final score = obj.score;
            if (score != null) {
              totalScore += score.toDouble();
            }
          }
          final objectivesScore =
              ((totalScore / objectives.length) * 100).round();
          masteryGrade = objectivesScore >= 60 ? 'A+' : 'B+';
        }

        // Calculate learning gaps
        final gaps = feedbackData.gaps;
        if (gaps != null) {
          totalGaps = gaps.length;
          resolvedGaps = 0;
          for (var gap in gaps) {
            if (gap.resolved == true) {
              resolvedGaps++;
            }
          }
        }
      } catch (e) {
        // If there's any error accessing the data, use defaults
        print('Error processing feedback data: $e');
      }
    }

    return Column(
      children: [
        // Mastery grade row
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                masteryGrade,
                style: GoogleFonts.raleway(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: onViewFeedback,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'View Now',
                style: GoogleFonts.raleway(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Learning gaps row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.warning_amber,
                size: 16,
                color: const Color(0xFFD97706),
              ),
              const SizedBox(width: 6),
              Text(
                'Learning gaps',
                style: GoogleFonts.raleway(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFFD97706),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$resolvedGaps resolved · ${totalGaps - resolvedGaps} open',
                style: GoogleFonts.raleway(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFFB45309),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _buildErrorFeedbackContent() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFF44336),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(
            Icons.error_outline,
            color: Colors.white,
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Failed to generate feedback',
                style: GoogleFonts.raleway(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0B1220),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'We encountered an issue generating your feedback',
                style: GoogleFonts.raleway(
                  fontSize: 12,
                  color: const Color(0xFF70695B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _buildFailedFeedbackContent(
      int checkpointIndex, Function(int)? onRetryFeedback) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF44336),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.error_outline,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Feedback generation failed',
                    style: GoogleFonts.raleway(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0B1220),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Unable to generate feedback. Please try again.',
                    style: GoogleFonts.raleway(
                      fontSize: 12,
                      color: const Color(0xFF70695B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (onRetryFeedback != null)
          ElevatedButton.icon(
            onPressed: () => onRetryFeedback(checkpointIndex),
            icon: const Icon(Icons.refresh, size: 16),
            label: Text(
              'Retry Feedback',
              style: GoogleFonts.raleway(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D4ED8),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
      ],
    );
  }
}

// Beautiful Loading Feedback Card with skeleton animations
class LoadingFeedbackCard extends StatefulWidget {
  final int? checkpointNumber;

  const LoadingFeedbackCard({
    Key? key,
    this.checkpointNumber,
  }) : super(key: key);

  @override
  State<LoadingFeedbackCard> createState() => _LoadingFeedbackCardState();
}

class _LoadingFeedbackCardState extends State<LoadingFeedbackCard>
    with TickerProviderStateMixin {
  late AnimationController _shimmerController;
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Shimmer animation for skeleton effect
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOutSine,
    ));

    // Pulse animation for the loading indicator
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Fade animation for entrance
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    // Start animations
    _shimmerController.repeat();
    _pulseController.repeat(reverse: true);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFF8FAFC),
              const Color(0xFFF1F5F9),
              const Color(0xFFE2E8F0).withOpacity(0.3),
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF1D4ED8).withOpacity(0.12),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1D4ED8).withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
              spreadRadius: -4,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
              spreadRadius: -8,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Animated gradient overlay for shimmer effect
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _shimmerAnimation,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment(_shimmerAnimation.value - 1, 0),
                        end: Alignment(_shimmerAnimation.value, 0),
                        colors: [
                          Colors.transparent,
                          const Color(0xFF1D4ED8).withOpacity(0.06),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Accent line on left with gradient
            Positioned(
              left: 0,
              top: 20,
              bottom: 20,
              child: Container(
                width: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF1D4ED8),
                      const Color(0xFF1D4ED8).withOpacity(0.6),
                      const Color(0xFF1D4ED8).withOpacity(0.2),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(2),
                    bottomRight: Radius.circular(2),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with animated loading indicator
                  Row(
                    children: [
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF1D4ED8),
                                    const Color(0xFF3B82F6),
                                  ],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF1D4ED8)
                                        .withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.auto_awesome,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Hero text
                            ShaderMask(
                              shaderCallback: (bounds) => LinearGradient(
                                colors: [
                                  const Color(0xFF1D4ED8),
                                  const Color(0xFF3B82F6),
                                ],
                              ).createShader(bounds),
                              child: Text(
                                'Creating Feedback for Checkpoint ${(widget.checkpointNumber ?? 0) + 1}',
                                style: GoogleFonts.raleway(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  height: 1.2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Continue learning, we will notify once the feedback is created.',
                              style: GoogleFonts.raleway(
                                fontSize: 13,
                                color: const Color(0xFF64748B),
                                height: 1.3,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Skeleton content with shimmer effect
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Skeleton mastery section
                      Row(
                        children: [
                          _buildSkeletonBox(60, 40, isCircular: true),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSkeletonBox(100, 16),
                                const SizedBox(height: 8),
                                _buildSkeletonBox(140, 12),
                              ],
                            ),
                          ),
                          _buildSkeletonBox(80, 28, isCircular: true),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Skeleton metrics row
                      Row(
                        children: [
                          _buildSkeletonMetricBox(),
                          const SizedBox(width: 16),
                          _buildSkeletonMetricBox(),
                          const Spacer(),
                          _buildSkeletonBox(70, 36, isCircular: true),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Skeleton summary text
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSkeletonBox(double.infinity, 12),
                          const SizedBox(height: 6),
                          _buildSkeletonBox(280, 12),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Skeleton tags
                      Row(
                        children: [
                          _buildSkeletonBox(120, 24, isCircular: true),
                          const SizedBox(width: 12),
                          _buildSkeletonBox(100, 24, isCircular: true),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Progress indicator
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D4ED8).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF1D4ED8).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              const Color(0xFF1D4ED8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Analyzing your responses and generating insights...',
                          style: GoogleFonts.raleway(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1D4ED8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonBox(double width, double height,
      {bool isCircular = false}) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(_shimmerAnimation.value - 1, 0),
              end: Alignment(_shimmerAnimation.value, 0),
              colors: [
                const Color(0xFFE2E8F0).withOpacity(0.4),
                const Color(0xFFF1F5F9).withOpacity(0.8),
                const Color(0xFFE2E8F0).withOpacity(0.4),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
            borderRadius: BorderRadius.circular(isCircular ? height / 2 : 8),
          ),
        );
      },
    );
  }

  Widget _buildSkeletonMetricBox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xFFE2E8F0).withOpacity(0.6),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSkeletonBox(30, 16),
          const SizedBox(height: 6),
          _buildSkeletonBox(50, 12),
        ],
      ),
    );
  }
}
