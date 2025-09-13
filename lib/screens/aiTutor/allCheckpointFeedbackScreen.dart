import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eureka_app/services/checkpointFeedbackService.dart';
import 'package:eureka_app/screens/checkpointFeedbackScreen.dart';
import 'package:eureka_app/main.dart';
import 'components/feedback_cards.dart';
import 'components/compact_feedback_card.dart';

class AllCheckpointFeedbackScreen extends StatefulWidget {
  final String conceptConversationsKey;
  final int totalCheckpoints;
  final Map<int, String> checkpointFeedbackStates;
  final Map<int, dynamic> checkpointFeedbackData;
  final String conceptId;

  const AllCheckpointFeedbackScreen({
    Key? key,
    required this.conceptConversationsKey,
    required this.totalCheckpoints,
    required this.checkpointFeedbackStates,
    required this.checkpointFeedbackData,
    required this.conceptId,
  }) : super(key: key);

  @override
  State<AllCheckpointFeedbackScreen> createState() =>
      _AllCheckpointFeedbackScreenState();
}

class _AllCheckpointFeedbackScreenState
    extends State<AllCheckpointFeedbackScreen> {
  late Map<int, String> _feedbackStates;
  late Map<int, dynamic> _feedbackData;

  @override
  void initState() {
    super.initState();
    _feedbackStates = Map.from(widget.checkpointFeedbackStates);
    _feedbackData = Map.from(widget.checkpointFeedbackData);

    // Load feedback for the last checkpoint if not already loaded
    final lastCheckpointIndex = widget.totalCheckpoints - 1;
    if (!_feedbackStates.containsKey(lastCheckpointIndex) ||
        _feedbackStates[lastCheckpointIndex] == 'loading') {
      _feedbackStates[lastCheckpointIndex] = 'loading';
      _loadCheckpointFeedback(lastCheckpointIndex);
    }
  }

  Future<void> _loadCheckpointFeedback(int checkpointIndex) async {
    try {
      final feedbackData =
          await CheckpointFeedbackService.getCheckpointFeedback(
        conceptConversations: widget.conceptConversationsKey,
        checkpointNumber: checkpointIndex,
      );

      setState(() {
        _feedbackStates[checkpointIndex] = 'ready';
        _feedbackData[checkpointIndex] = feedbackData;
      });
    } catch (e) {
      debugPrint('Error loading checkpoint feedback: $e');
      setState(() {
        _feedbackStates[checkpointIndex] = 'error';
      });
    }
  }

  void _viewCheckpointFeedback(int checkpointIndex) {
    final feedbackData = _feedbackData[checkpointIndex];
    if (feedbackData != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CheckpointFeedbackScreen(
            conceptConversations: widget.conceptConversationsKey,
            checkpointNumber: checkpointIndex,
            initialReport: feedbackData,
          ),
        ),
      );
    }
  }

  void _endDiscussion() {
    // Navigate to home screen
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const MainPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6EDDA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6EDDA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0B1220)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Checkpoint Feedback',
          style: GoogleFonts.raleway(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0B1220),
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Checkpoint Feedback',
                  style: GoogleFonts.raleway(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0B1220),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'View mastery grades and learning gaps for each checkpoint',
                  style: GoogleFonts.raleway(
                    fontSize: 14,
                    color: const Color(0xFF70695B),
                  ),
                ),
              ],
            ),
          ),

          // Feedback cards list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              itemCount: widget.totalCheckpoints,
              itemBuilder: (context, index) {
                final checkpointIndex = index;
                final feedbackState =
                    _feedbackStates[checkpointIndex] ?? 'loading';
                final feedbackData = _feedbackData[checkpointIndex];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: feedbackState == 'ready' && feedbackData != null
                      ? CompactFeedbackCard(
                          report: feedbackData,
                          checkpointNumber: checkpointIndex,
                          onTap: () => _viewCheckpointFeedback(checkpointIndex),
                        )
                      : FeedbackCards.checkpointFeedbackCard(
                          checkpointIndex,
                          feedbackState,
                          feedbackData,
                          () => _viewCheckpointFeedback(checkpointIndex),
                          showDismissButton:
                              false, // No dismiss button in this screen
                        ),
                );
              },
            ),
          ),
        ],
      ),

      // Bottom button
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Color(0xFFF6EDDA),
          border: Border(
            top: BorderSide(color: Color(0xFFE7DEC9), width: 1),
          ),
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _endDiscussion,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1D4ED8),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                'End Discussion',
                style: GoogleFonts.raleway(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
