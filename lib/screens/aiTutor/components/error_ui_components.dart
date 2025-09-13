import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ai_tutor_error_manager.dart';

// Inline Error Message Component
class InlineErrorMessage extends StatelessWidget {
  final ErrorState error;
  final VoidCallback? onDismiss;

  const InlineErrorMessage({
    Key? key,
    required this.error,
    this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ErrorAnimations.slideInError(
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ErrorColors.getColorForSeverity(error.severity).withOpacity(0.1),
          border: Border.all(
            color: ErrorColors.getColorForSeverity(error.severity).withOpacity(0.3),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  ErrorIcons.getIconForType(error.type),
                  color: ErrorColors.getColorForSeverity(error.severity),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    error.title,
                    style: GoogleFonts.raleway(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0B1220),
                    ),
                  ),
                ),
                if (onDismiss != null)
                  IconButton(
                    onPressed: onDismiss,
                    icon: const Icon(Icons.close, size: 18),
                    color: const Color(0xFF70695B),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              error.message,
              style: GoogleFonts.raleway(
                fontSize: 13,
                color: const Color(0xFF70695B),
              ),
            ),
            if (error.actions.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: error.actions
                    .map((action) => _buildActionButton(action, error.severity))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(ErrorAction action, ErrorSeverity severity) {
    final color = action.isPrimary
        ? const Color(0xFF1D4ED8)
        : ErrorColors.getColorForSeverity(severity);

    if (action.isPrimary) {
      return ElevatedButton.icon(
        onPressed: action.onTap,
        icon: Icon(action.icon, size: 16),
        label: Text(action.label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    } else {
      return TextButton.icon(
        onPressed: action.onTap,
        icon: Icon(action.icon, size: 16),
        label: Text(action.label),
        style: TextButton.styleFrom(
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      );
    }
  }
}

// Error Message Bubble Component
class ErrorMessageBubble extends StatelessWidget {
  final ErrorState error;
  final VoidCallback? onRetry;
  final bool isAssistant;

  const ErrorMessageBubble({
    Key? key,
    required this.error,
    this.onRetry,
    this.isAssistant = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ErrorAnimations.slideInError(
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAvatar(),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ErrorColors.getColorForSeverity(error.severity)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: ErrorColors.getColorForSeverity(error.severity)
                        .withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          ErrorIcons.getIconForType(error.type),
                          color: ErrorColors.getColorForSeverity(error.severity),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          error.title,
                          style: GoogleFonts.raleway(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: ErrorColors.getColorForSeverity(error.severity),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.message,
                      style: GoogleFonts.raleway(
                        fontSize: 13,
                        color: const Color(0xFF70695B),
                      ),
                    ),
                    if (error.actions.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: error.actions
                            .map((action) => _buildActionButton(action))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    if (isAssistant) {
      return Stack(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey.shade300,
            child: const Icon(Icons.smart_toy, size: 18),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: ErrorColors.getColorForSeverity(error.severity),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1),
              ),
              child: const Icon(
                Icons.error,
                size: 8,
                color: Colors.white,
              ),
            ),
          ),
        ],
      );
    } else {
      return CircleAvatar(
        radius: 16,
        backgroundColor: const Color(0xFF1D4ED8),
        child: Text(
          "You",
          style: GoogleFonts.raleway(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      );
    }
  }

  Widget _buildActionButton(ErrorAction action) {
    if (action.isPrimary) {
      return ElevatedButton.icon(
        onPressed: action.onTap,
        icon: Icon(action.icon, size: 14),
        label: Text(action.label),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1D4ED8),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          textStyle: GoogleFonts.raleway(fontSize: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      );
    } else {
      return TextButton.icon(
        onPressed: action.onTap,
        icon: Icon(action.icon, size: 14),
        label: Text(action.label),
        style: TextButton.styleFrom(
          foregroundColor: ErrorColors.getColorForSeverity(error.severity),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          textStyle: GoogleFonts.raleway(fontSize: 12),
        ),
      );
    }
  }
}

// Transcription Error Bubble Component
class TranscriptionErrorBubble extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback onSwitchToText;

  const TranscriptionErrorBubble({
    Key? key,
    required this.onRetry,
    required this.onSwitchToText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ErrorAnimations.slideInError(
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF1D4ED8),
              child: Text(
                "You",
                style: GoogleFonts.raleway(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.mic_off,
                          color: Colors.orange.shade600,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "Couldn't understand audio",
                          style: GoogleFonts.raleway(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "We had trouble processing your voice message. Please try again or type your response.",
                      style: GoogleFonts.raleway(
                        fontSize: 13,
                        color: const Color(0xFF70695B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: onRetry,
                          icon: const Icon(Icons.mic, size: 16),
                          label: const Text("Record Again"),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.orange.shade600,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            textStyle: GoogleFonts.raleway(fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: onSwitchToText,
                          icon: const Icon(Icons.keyboard, size: 16),
                          label: const Text("Type Instead"),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF1D4ED8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            textStyle: GoogleFonts.raleway(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Connection Error Overlay Component
class ConnectionErrorOverlay extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback? onOfflineMode;

  const ConnectionErrorOverlay({
    Key? key,
    required this.onRetry,
    this.onOfflineMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: ErrorAnimations.slideInError(
          Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.wifi_off,
                    size: 32,
                    color: Colors.red.shade600,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Connection Lost",
                  style: GoogleFonts.raleway(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0B1220),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "We're having trouble connecting to our servers. Check your internet connection and try again.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.raleway(
                    fontSize: 14,
                    color: const Color(0xFF70695B),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    if (onOfflineMode != null)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onOfflineMode,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF70695B),
                            side: const BorderSide(color: Color(0xFFE7DEC9)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            "Continue Offline",
                            style: GoogleFonts.raleway(fontSize: 14),
                          ),
                        ),
                      ),
                    if (onOfflineMode != null) const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onRetry,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1D4ED8),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          "Retry",
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
        ),
      ),
    );
  }
}

// Loading Error State Component
class LoadingErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const LoadingErrorState({
    Key? key,
    required this.message,
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            "Something went wrong",
            style: GoogleFonts.raleway(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0B1220),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.raleway(
              fontSize: 14,
              color: const Color(0xFF70695B),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text("Try Again"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1D4ED8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Error Animations
class ErrorAnimations {
  static Widget slideInError(Widget child) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  static Widget shakeError(Widget child, bool shouldShake) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: shouldShake ? 1.0 : 0.0),
      duration: const Duration(milliseconds: 500),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(sin(value * pi * 4) * 4, 0),
          child: child,
        );
      },
      child: child,
    );
  }

  static Widget pulseError(Widget child, bool shouldPulse) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: shouldPulse ? 1.0 : 0.0),
      duration: const Duration(milliseconds: 1000),
      builder: (context, value, child) {
        final scale = 1.0 + (sin(value * pi * 2) * 0.05);
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: child,
    );
  }
}

// Retry Progress Indicator
class RetryProgressIndicator extends StatefulWidget {
  final int currentAttempt;
  final int maxAttempts;
  final Duration delay;
  final VoidCallback onComplete;

  const RetryProgressIndicator({
    Key? key,
    required this.currentAttempt,
    required this.maxAttempts,
    required this.delay,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<RetryProgressIndicator> createState() => _RetryProgressIndicatorState();
}

class _RetryProgressIndicatorState extends State<RetryProgressIndicator>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.delay,
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    
    _controller.forward().then((_) {
      if (mounted) {
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border.all(color: Colors.blue.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return CircularProgressIndicator(
                  value: _animation.value,
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Retrying... (${widget.currentAttempt}/${widget.maxAttempts})',
                  style: GoogleFonts.raleway(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Please wait a moment',
                  style: GoogleFonts.raleway(
                    fontSize: 11,
                    color: const Color(0xFF70695B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}