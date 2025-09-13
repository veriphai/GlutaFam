import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ai_tutor_types.dart';

class InputIsland extends StatelessWidget {
  final InputMode inputMode;
  final bool isLoading;
  final int recordingSeconds;
  final TextEditingController messageController;
  final VoidCallback onStartRecording;
  final VoidCallback onSendRecording;
  final VoidCallback onCancelRecording;
  final VoidCallback onSwitchToTyping;
  final VoidCallback onSwitchToCompact;
  final VoidCallback onSendText;

  const InputIsland({
    Key? key,
    required this.inputMode,
    required this.isLoading,
    required this.recordingSeconds,
    required this.messageController,
    required this.onStartRecording,
    required this.onSendRecording,
    required this.onCancelRecording,
    required this.onSwitchToTyping,
    required this.onSwitchToCompact,
    required this.onSendText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    switch (inputMode) {
      case InputMode.compact:
        return _buildCompactIsland();
      case InputMode.recording:
        return _buildRecordingIsland();
      case InputMode.typing:
        return _buildTypingIsland();
    }
  }

  Widget _buildCompactIsland() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFE7DEC9)),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 14,
                    offset: Offset(0, 4))
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Primary mic button (larger)
                GestureDetector(
                  onTap: isLoading ? null : onStartRecording,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D4ED8),
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(
                            color: Color(0x401D4ED8),
                            blurRadius: 8,
                            offset: Offset(0, 2))
                      ],
                    ),
                    child: const Icon(
                      Icons.mic,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Secondary keyboard button (smaller)
                GestureDetector(
                  onTap: isLoading ? null : onSwitchToTyping,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: const Icon(
                      Icons.keyboard,
                      color: Color(0xFF6B7280),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingIsland() {
    String formattedTime =
        '${(recordingSeconds ~/ 60).toString().padLeft(2, '0')}:${(recordingSeconds % 60).toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFE7DEC9)),
          boxShadow: const [
            BoxShadow(
                color: Color(0x1A000000), blurRadius: 14, offset: Offset(0, 4))
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // Recording mic button
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626),
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x40DC2626),
                      blurRadius: 8,
                      offset: Offset(0, 2))
                ],
              ),
              child: const Icon(
                Icons.mic,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            // Recording content
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFFDC2626),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Recording...',
                        style: GoogleFonts.raleway(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0B1220),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formattedTime,
                        style: GoogleFonts.raleway(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1D4ED8),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: onSendRecording,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1D4ED8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Send',
                            style: GoogleFonts.raleway(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: onCancelRecording,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: const Icon(Icons.close,
                              color: Color(0xFF6B7280), size: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIsland() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFE7DEC9)),
          boxShadow: const [
            BoxShadow(
                color: Color(0x1A000000), blurRadius: 14, offset: Offset(0, 4))
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // Switch back to mic button
            GestureDetector(
              onTap: isLoading ? null : onSwitchToCompact,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: const Icon(
                  Icons.mic,
                  color: Color(0xFF6B7280),
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                enabled: !isLoading,
                controller: messageController,
                decoration: InputDecoration(
                  hintText: "Type your message…",
                  hintStyle: GoogleFonts.raleway(
                    color: const Color(0xFF9CA3AF),
                    fontSize: 15,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
                style: GoogleFonts.raleway(
                  fontSize: 15,
                  color: const Color(0xFF0B1220),
                ),
                onSubmitted: (_) => onSendText(),
                autofocus: true,
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: isLoading ? null : onSendText,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: messageController.text.trim().isNotEmpty
                      ? const Color(0xFF1D4ED8)
                      : const Color(0xFFF3F4F6),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.send,
                  color: messageController.text.trim().isNotEmpty
                      ? Colors.white
                      : const Color(0xFF9CA3AF),
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
