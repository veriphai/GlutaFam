# AI Tutor Error States Implementation Guide

## Overview

This document outlines the comprehensive error handling system for the AI Tutor screen, including all possible error states, UI designs, and implementation details for a junior developer.

## 1. Identified Error States

### 1.1 Network & API Errors

1. **Tutor Response Generation Failure**

   - Initial greeting failure
   - Follow-up conversation failure
   - Hint request failure
   - Checkpoint transition failure

2. **Audio Processing Errors**

   - Transcription failure (user audio → text)
   - Audio generation failure (text → speech)
   - Audio playback failure
   - Recording permission denied
   - Recording device unavailable

3. **WebSocket Connection Errors**

   - Connection timeout
   - Connection lost during conversation
   - Message delivery failure
   - Subscription failure

4. **Gap Resolution Errors**

   - Gap conversation initialization failure
   - Gap message sending failure
   - Gap audio processing failure

5. **Checkpoint Feedback Errors**
   - Feedback loading failure
   - Feedback data corruption
   - Feedback service unavailable

### 1.2 Data & State Errors

6. **Concept Loading Errors**

   - Concept details fetch failure
   - Checkpoint data unavailable
   - Learning objectives missing

7. **Session Management Errors**

   - Session timeout
   - Authentication failure
   - Token refresh failure

8. **Local Storage Errors**
   - Preference saving failure
   - Cache corruption
   - Insufficient storage space

### 1.3 User Input Errors

9. **Input Validation Errors**

   - Empty message submission
   - Invalid audio format
   - Message too long

10. **Device Capability Errors**
    - Microphone unavailable
    - Speaker unavailable
    - Low battery affecting performance

## 2. Error State Data Structure

### 2.1 Enhanced AITutorState

```dart
class AITutorState {
  // ... existing fields ...

  // Error handling fields
  Map<String, ErrorState> errorStates = {};
  List<RetryableAction> retryQueue = [];
  bool hasNetworkConnection = true;
  DateTime? lastErrorTime;
  int consecutiveErrors = 0;
}

enum ErrorType {
  network,
  audio,
  transcription,
  websocket,
  authentication,
  validation,
  storage,
  device,
  timeout,
  serverError,
  unknown
}

enum ErrorSeverity {
  low,      // User can continue with limited functionality
  medium,   // Feature unavailable but lesson can continue
  high,     // Lesson cannot continue without resolution
  critical  // Must exit lesson
}

class ErrorState {
  final String id;
  final ErrorType type;
  final ErrorSeverity severity;
  final String title;
  final String message;
  final String? technicalDetails;
  final List<ErrorAction> actions;
  final DateTime timestamp;
  final bool isRetryable;
  final int retryCount;
  final Duration? retryDelay;

  ErrorState({
    required this.id,
    required this.type,
    required this.severity,
    required this.title,
    required this.message,
    this.technicalDetails,
    required this.actions,
    required this.timestamp,
    this.isRetryable = true,
    this.retryCount = 0,
    this.retryDelay,
  });
}

class ErrorAction {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;

  ErrorAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isPrimary = false,
  });
}

class RetryableAction {
  final String id;
  final String description;
  final Function action;
  final int maxRetries;
  final Duration delay;
  final int currentAttempt;

  RetryableAction({
    required this.id,
    required this.description,
    required this.action,
    this.maxRetries = 3,
    this.delay = const Duration(seconds: 2),
    this.currentAttempt = 0,
  });
}
```

## 3. Error Handling Implementation

### 3.1 Error Manager Class

```dart
class AITutorErrorManager {
  static const Map<ErrorType, ErrorConfig> errorConfigs = {
    ErrorType.network: ErrorConfig(
      maxRetries: 3,
      retryDelay: Duration(seconds: 2),
      exponentialBackoff: true,
    ),
    ErrorType.audio: ErrorConfig(
      maxRetries: 2,
      retryDelay: Duration(seconds: 1),
      exponentialBackoff: false,
    ),
    // ... other configurations
  };

  static ErrorState createError({
    required ErrorType type,
    required String context,
    String? technicalDetails,
    dynamic originalError,
  }) {
    // Implementation for creating standardized error states
  }

  static List<ErrorAction> getActionsForError(ErrorType type, String context) {
    // Implementation for generating appropriate actions
  }

  static bool shouldRetry(ErrorState error) {
    // Implementation for retry logic
  }
}
```

### 3.2 Error UI Components

#### 3.2.1 Inline Error Messages

```dart
class InlineErrorMessage extends StatelessWidget {
  final ErrorState error;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getErrorColor(error.severity).withOpacity(0.1),
        border: Border.all(color: _getErrorColor(error.severity)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getErrorIcon(error.type),
                color: _getErrorColor(error.severity),
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  error.title,
                  style: GoogleFonts.raleway(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0B1220),
                  ),
                ),
              ),
              if (onDismiss != null)
                IconButton(
                  onPressed: onDismiss,
                  icon: Icon(Icons.close, size: 18),
                ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            error.message,
            style: GoogleFonts.raleway(
              fontSize: 13,
              color: Color(0xFF70695B),
            ),
          ),
          if (error.actions.isNotEmpty) ...[
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: error.actions.map((action) =>
                _buildActionButton(action, error.severity)
              ).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
```

#### 3.2.2 Message Bubble Error States

```dart
class ErrorMessageBubble extends StatelessWidget {
  final ErrorState error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tutor avatar with error indicator
          Stack(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey.shade300,
                child: Icon(Icons.smart_toy, size: 18),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  child: Icon(
                    Icons.error,
                    size: 8,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.red.shade600,
                        size: 16,
                      ),
                      SizedBox(width: 4),
                      Text(
                        "Message failed to send",
                        style: GoogleFonts.raleway(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    error.message,
                    style: GoogleFonts.raleway(
                      fontSize: 13,
                      color: Color(0xFF70695B),
                    ),
                  ),
                  if (onRetry != null) ...[
                    SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: onRetry,
                      icon: Icon(Icons.refresh, size: 16),
                      label: Text("Retry"),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red.shade600,
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
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
}
```

#### 3.2.3 Transcription Error State

```dart
class TranscriptionErrorBubble extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback onSwitchToText;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Color(0xFF1D4ED8),
            child: Text(
              "You",
              style: GoogleFonts.raleway(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(12),
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
                      SizedBox(width: 4),
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
                  SizedBox(height: 8),
                  Text(
                    "We had trouble processing your voice message. Please try again or type your response.",
                    style: GoogleFonts.raleway(
                      fontSize: 13,
                      color: Color(0xFF70695B),
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: onRetry,
                        icon: Icon(Icons.mic, size: 16),
                        label: Text("Record Again"),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.orange.shade600,
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                      ),
                      SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: onSwitchToText,
                        icon: Icon(Icons.keyboard, size: 16),
                        label: Text("Type Instead"),
                        style: TextButton.styleFrom(
                          foregroundColor: Color(0xFF1D4ED8),
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
    );
  }
}
```

#### 3.2.4 Connection Error Overlay

```dart
class ConnectionErrorOverlay extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback onOfflineMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Container(
          margin: EdgeInsets.all(24),
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
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
              SizedBox(height: 16),
              Text(
                "Connection Lost",
                style: GoogleFonts.raleway(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0B1220),
                ),
              ),
              SizedBox(height: 8),
              Text(
                "We're having trouble connecting to our servers. Check your internet connection and try again.",
                textAlign: TextAlign.center,
                style: GoogleFonts.raleway(
                  fontSize: 14,
                  color: Color(0xFF70695B),
                ),
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onOfflineMode,
                      child: Text("Continue Offline"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Color(0xFF70695B),
                        side: BorderSide(color: Color(0xFFE7DEC9)),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onRetry,
                      child: Text("Retry"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF1D4ED8),
                        foregroundColor: Colors.white,
                      ),
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
```

### 3.3 Error Handling Methods

#### 3.3.1 Enhanced API Call Wrapper

```dart
Future<T?> _safeApiCall<T>(
  Future<T> Function() apiCall,
  String operation, {
  bool showErrorUI = true,
  int maxRetries = 3,
}) async {
  int attempts = 0;

  while (attempts < maxRetries) {
    try {
      return await apiCall();
    } catch (e) {
      attempts++;

      final errorState = AITutorErrorManager.createError(
        type: _getErrorTypeFromException(e),
        context: operation,
        technicalDetails: e.toString(),
        originalError: e,
      );

      if (attempts >= maxRetries) {
        if (showErrorUI) {
          _showError(errorState);
        }
        return null;
      }

      // Wait before retry with exponential backoff
      await Future.delayed(Duration(seconds: attempts * 2));
    }
  }

  return null;
}
```

#### 3.3.2 Enhanced Follow-up Conversation with Error Handling

```dart
Future<void> _followUpConversationWithErrorHandling(
  File? audioFile,
  String? text, {
  // ... existing parameters
}) async {
  final result = await _safeApiCall(
    () => _followUpConversation(audioFile, text, /* ... */),
    'follow_up_conversation',
  );

  if (result == null) {
    // Handle the error case
    setState(() {
      // Remove loading message
      if (_state.conversations.isNotEmpty &&
          _state.conversations.last['isLoading'] == true) {
        _state.conversations.removeLast();
      }

      // Add error message
      _state.conversations.add({
        'role': 'error',
        'errorType': 'tutor_response_failed',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'retryAction': () => _followUpConversationWithErrorHandling(
          audioFile, text, /* ... */
        ),
      });
    });
  }
}
```

#### 3.3.3 Transcription Error Handling

```dart
void _handleTranscriptionError(String conversationKey) {
  setState(() {
    // Find and update the transcribing message
    for (int i = 0; i < _state.conversations.length; i++) {
      if (_state.conversations[i]['role'] == 'user' &&
          _state.conversations[i]['isTranscribing'] == true) {
        _state.conversations[i] = {
          'role': 'user',
          'content': '',
          'text': '',
          'transcriptionFailed': true,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'retryRecording': () => _retryRecording(i),
          'switchToText': () => _switchToTextInput(i),
        };
        break;
      }
    }
  });
}

void _retryRecording(int messageIndex) {
  setState(() {
    // Remove the failed message
    _state.conversations.removeAt(messageIndex);
  });

  // Start new recording
  _startRecording();
}

void _switchToTextInput(int messageIndex) {
  setState(() {
    // Remove the failed message
    _state.conversations.removeAt(messageIndex);
    // Switch to typing mode
    _state.inputMode = InputMode.typing;
  });
}
```

## 4. UI Implementation Details

### 4.1 Error Color Scheme

```dart
class ErrorColors {
  static const Color lowSeverity = Color(0xFFFFA726);      // Orange
  static const Color mediumSeverity = Color(0xFFFF7043);   // Deep Orange
  static const Color highSeverity = Color(0xFFE53E3E);     // Red
  static const Color criticalSeverity = Color(0xFFB91C1C); // Dark Red

  static const Color networkError = Color(0xFF3B82F6);     // Blue
  static const Color audioError = Color(0xFF8B5CF6);       // Purple
  static const Color validationError = Color(0xFFFBBF24);  // Yellow
}
```

### 4.2 Error Icons

```dart
class ErrorIcons {
  static const Map<ErrorType, IconData> icons = {
    ErrorType.network: Icons.wifi_off,
    ErrorType.audio: Icons.volume_off,
    ErrorType.transcription: Icons.mic_off,
    ErrorType.websocket: Icons.sync_problem,
    ErrorType.authentication: Icons.lock,
    ErrorType.validation: Icons.warning,
    ErrorType.storage: Icons.storage,
    ErrorType.device: Icons.phone_android,
    ErrorType.timeout: Icons.timer_off,
    ErrorType.serverError: Icons.cloud_off,
    ErrorType.unknown: Icons.error_outline,
  };
}
```

### 4.3 Animation and Transitions

```dart
class ErrorAnimations {
  static Widget slideInError(Widget child) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300),
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
      duration: Duration(milliseconds: 500),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(sin(value * pi * 4) * 4, 0),
          child: child,
        );
      },
      child: child,
    );
  }
}
```

## 5. Backend Integration Requirements

### 5.1 Enhanced API Response Format

```json
{
  "success": true,
  "data": {
    /* existing response data */
  },
  "error": {
    "code": "TRANSCRIPTION_FAILED",
    "message": "Unable to process audio",
    "details": "Audio quality too low",
    "retryable": true,
    "retryAfter": 2000
  },
  "metadata": {
    "requestId": "uuid",
    "timestamp": "2024-01-01T00:00:00Z",
    "processingTime": 1500
  }
}
```

### 5.2 Error Codes

```typescript
enum APIErrorCode {
  // Network errors
  NETWORK_TIMEOUT = "NETWORK_TIMEOUT",
  CONNECTION_LOST = "CONNECTION_LOST",

  // Audio errors
  TRANSCRIPTION_FAILED = "TRANSCRIPTION_FAILED",
  AUDIO_GENERATION_FAILED = "AUDIO_GENERATION_FAILED",
  UNSUPPORTED_AUDIO_FORMAT = "UNSUPPORTED_AUDIO_FORMAT",

  // Authentication errors
  TOKEN_EXPIRED = "TOKEN_EXPIRED",
  UNAUTHORIZED = "UNAUTHORIZED",

  // Validation errors
  INVALID_INPUT = "INVALID_INPUT",
  MESSAGE_TOO_LONG = "MESSAGE_TOO_LONG",

  // Server errors
  INTERNAL_SERVER_ERROR = "INTERNAL_SERVER_ERROR",
  SERVICE_UNAVAILABLE = "SERVICE_UNAVAILABLE",
  RATE_LIMIT_EXCEEDED = "RATE_LIMIT_EXCEEDED",
}
```

## 6. Implementation Steps

### Phase 1: Core Error Infrastructure (Week 1)

1. Create error state classes and enums
2. Implement AITutorErrorManager
3. Add error fields to AITutorState
4. Create basic error UI components

### Phase 2: API Error Handling (Week 2)

1. Implement \_safeApiCall wrapper
2. Update all API calls to use error handling
3. Add retry logic with exponential backoff
4. Implement connection monitoring

### Phase 3: UI Error States (Week 3)

1. Create all error UI components
2. Implement error animations
3. Add error states to message bubbles
4. Create connection error overlay

### Phase 4: Audio Error Handling (Week 4)

1. Implement transcription error handling
2. Add audio playback error states
3. Handle recording permission errors
4. Add device capability checks

### Phase 5: Testing and Polish (Week 5)

1. Test all error scenarios
2. Add error analytics
3. Implement offline mode
4. Performance optimization

## 7. Testing Scenarios

### 7.1 Network Error Testing

- Disconnect internet during conversation
- Simulate slow network conditions
- Test timeout scenarios
- Verify retry mechanisms

### 7.2 Audio Error Testing

- Test with poor quality audio
- Simulate microphone permission denial
- Test with unsupported audio formats
- Verify fallback to text input

### 7.3 Edge Case Testing

- Test with very long messages
- Simulate server errors
- Test concurrent error states
- Verify error recovery

## 8. Analytics and Monitoring

### 8.1 Error Tracking Events

```dart
void logError(ErrorState error) {
  logEvent('ai_tutor_error', {
    'error_type': error.type.toString(),
    'error_severity': error.severity.toString(),
    'error_message': error.message,
    'retry_count': error.retryCount,
    'concept_id': widget.conceptId,
    'checkpoint_index': _state.currentCheckpointIndex,
  });
}
```

### 8.2 Performance Metrics

- Error frequency by type
- Recovery success rate
- User abandonment after errors
- Average retry attempts

## 9. Accessibility Considerations

### 9.1 Screen Reader Support

- Add semantic labels for error states
- Provide audio descriptions for visual errors
- Ensure keyboard navigation works

### 9.2 Visual Accessibility

- High contrast error colors
- Large touch targets for retry buttons
- Clear visual hierarchy

## 10. Future Enhancements

### 10.1 Smart Error Recovery

- AI-powered error prediction
- Contextual error messages
- Adaptive retry strategies

### 10.2 Offline Mode

- Local conversation caching
- Offline transcription
- Sync when connection restored

This comprehensive implementation will provide a robust, user-friendly error handling system that maintains the premium feel of the AI Tutor while gracefully handling all possible failure scenarios.
