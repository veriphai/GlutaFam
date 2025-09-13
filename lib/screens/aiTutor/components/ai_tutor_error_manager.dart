import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Error Types
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

// Error Severity Levels
enum ErrorSeverity {
  low,      // User can continue with limited functionality
  medium,   // Feature unavailable but lesson can continue
  high,     // Lesson cannot continue without resolution
  critical  // Must exit lesson
}

// Error State Class
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

  ErrorState copyWith({
    String? id,
    ErrorType? type,
    ErrorSeverity? severity,
    String? title,
    String? message,
    String? technicalDetails,
    List<ErrorAction>? actions,
    DateTime? timestamp,
    bool? isRetryable,
    int? retryCount,
    Duration? retryDelay,
  }) {
    return ErrorState(
      id: id ?? this.id,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      title: title ?? this.title,
      message: message ?? this.message,
      technicalDetails: technicalDetails ?? this.technicalDetails,
      actions: actions ?? this.actions,
      timestamp: timestamp ?? this.timestamp,
      isRetryable: isRetryable ?? this.isRetryable,
      retryCount: retryCount ?? this.retryCount,
      retryDelay: retryDelay ?? this.retryDelay,
    );
  }
}

// Error Action Class
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

// Retryable Action Class
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

  RetryableAction copyWith({
    String? id,
    String? description,
    Function? action,
    int? maxRetries,
    Duration? delay,
    int? currentAttempt,
  }) {
    return RetryableAction(
      id: id ?? this.id,
      description: description ?? this.description,
      action: action ?? this.action,
      maxRetries: maxRetries ?? this.maxRetries,
      delay: delay ?? this.delay,
      currentAttempt: currentAttempt ?? this.currentAttempt,
    );
  }
}

// Error Configuration
class ErrorConfig {
  final int maxRetries;
  final Duration retryDelay;
  final bool exponentialBackoff;

  const ErrorConfig({
    required this.maxRetries,
    required this.retryDelay,
    this.exponentialBackoff = false,
  });
}

// AI Tutor Error Manager
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
    ErrorType.transcription: ErrorConfig(
      maxRetries: 2,
      retryDelay: Duration(seconds: 1),
      exponentialBackoff: false,
    ),
    ErrorType.websocket: ErrorConfig(
      maxRetries: 3,
      retryDelay: Duration(seconds: 3),
      exponentialBackoff: true,
    ),
    ErrorType.authentication: ErrorConfig(
      maxRetries: 1,
      retryDelay: Duration(seconds: 1),
      exponentialBackoff: false,
    ),
    ErrorType.validation: ErrorConfig(
      maxRetries: 0,
      retryDelay: Duration.zero,
      exponentialBackoff: false,
    ),
    ErrorType.storage: ErrorConfig(
      maxRetries: 2,
      retryDelay: Duration(seconds: 1),
      exponentialBackoff: false,
    ),
    ErrorType.device: ErrorConfig(
      maxRetries: 1,
      retryDelay: Duration(seconds: 2),
      exponentialBackoff: false,
    ),
    ErrorType.timeout: ErrorConfig(
      maxRetries: 3,
      retryDelay: Duration(seconds: 5),
      exponentialBackoff: true,
    ),
    ErrorType.serverError: ErrorConfig(
      maxRetries: 2,
      retryDelay: Duration(seconds: 3),
      exponentialBackoff: true,
    ),
    ErrorType.unknown: ErrorConfig(
      maxRetries: 1,
      retryDelay: Duration(seconds: 2),
      exponentialBackoff: false,
    ),
  };

  static ErrorState createError({
    required ErrorType type,
    required String context,
    String? technicalDetails,
    dynamic originalError,
    List<ErrorAction>? customActions,
  }) {
    final config = errorConfigs[type] ?? errorConfigs[ErrorType.unknown]!;
    final String errorId = '${type.toString()}_${DateTime.now().millisecondsSinceEpoch}';
    
    Map<String, dynamic> errorInfo = _getErrorInfo(type, context);
    
    return ErrorState(
      id: errorId,
      type: type,
      severity: errorInfo['severity'] as ErrorSeverity,
      title: errorInfo['title'] as String,
      message: errorInfo['message'] as String,
      technicalDetails: technicalDetails ?? originalError?.toString(),
      actions: customActions ?? _getDefaultActions(type, context),
      timestamp: DateTime.now(),
      isRetryable: config.maxRetries > 0,
      retryCount: 0,
      retryDelay: config.retryDelay,
    );
  }

  static Map<String, dynamic> _getErrorInfo(ErrorType type, String context) {
    switch (type) {
      case ErrorType.network:
        return {
          'severity': ErrorSeverity.high,
          'title': 'Connection Problem',
          'message': 'We\'re having trouble connecting to our servers. Please check your internet connection.',
        };
      case ErrorType.audio:
        return {
          'severity': ErrorSeverity.medium,
          'title': 'Audio Issue',
          'message': 'There was a problem with audio processing. You can continue using text.',
        };
      case ErrorType.transcription:
        return {
          'severity': ErrorSeverity.medium,
          'title': 'Speech Recognition Failed',
          'message': 'We couldn\'t understand your audio. Please try speaking more clearly or use text.',
        };
      case ErrorType.websocket:
        return {
          'severity': ErrorSeverity.high,
          'title': 'Real-time Connection Lost',
          'message': 'Lost connection to the tutor. Attempting to reconnect...',
        };
      case ErrorType.authentication:
        return {
          'severity': ErrorSeverity.critical,
          'title': 'Session Expired',
          'message': 'Your session has expired. Please sign in again to continue.',
        };
      case ErrorType.validation:
        return {
          'severity': ErrorSeverity.low,
          'title': 'Invalid Input',
          'message': 'Please check your input and try again.',
        };
      case ErrorType.storage:
        return {
          'severity': ErrorSeverity.medium,
          'title': 'Storage Error',
          'message': 'Unable to save your progress. Please try again.',
        };
      case ErrorType.device:
        return {
          'severity': ErrorSeverity.medium,
          'title': 'Device Issue',
          'message': 'There\'s an issue with your device. Please check permissions and try again.',
        };
      case ErrorType.timeout:
        return {
          'severity': ErrorSeverity.high,
          'title': 'Request Timeout',
          'message': 'The request is taking too long. Please try again.',
        };
      case ErrorType.serverError:
        return {
          'severity': ErrorSeverity.high,
          'title': 'Server Error',
          'message': 'Our servers are experiencing issues. Please try again in a moment.',
        };
      case ErrorType.unknown:
      default:
        return {
          'severity': ErrorSeverity.medium,
          'title': 'Something Went Wrong',
          'message': 'An unexpected error occurred. Please try again.',
        };
    }
  }

  static List<ErrorAction> _getDefaultActions(ErrorType type, String context) {
    // Return empty list by default - actions will be set by the calling component
    // This allows for proper context-aware callback handling
    return [];
  }

  static bool shouldRetry(ErrorState error) {
    final config = errorConfigs[error.type] ?? errorConfigs[ErrorType.unknown]!;
    return error.isRetryable && error.retryCount < config.maxRetries;
  }

  static Duration getRetryDelay(ErrorState error) {
    final config = errorConfigs[error.type] ?? errorConfigs[ErrorType.unknown]!;
    
    if (config.exponentialBackoff) {
      return Duration(
        milliseconds: (config.retryDelay.inMilliseconds * 
                      pow(2, error.retryCount)).toInt(),
      );
    }
    
    return config.retryDelay;
  }
}

// Error Colors
class ErrorColors {
  static const Color lowSeverity = Color(0xFFFFA726);      // Orange
  static const Color mediumSeverity = Color(0xFFFF7043);   // Deep Orange
  static const Color highSeverity = Color(0xFFE53E3E);     // Red
  static const Color criticalSeverity = Color(0xFFB91C1C); // Dark Red

  static const Color networkError = Color(0xFF3B82F6);     // Blue
  static const Color audioError = Color(0xFF8B5CF6);       // Purple
  static const Color validationError = Color(0xFFFBBF24);  // Yellow

  static Color getColorForSeverity(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.low:
        return lowSeverity;
      case ErrorSeverity.medium:
        return mediumSeverity;
      case ErrorSeverity.high:
        return highSeverity;
      case ErrorSeverity.critical:
        return criticalSeverity;
    }
  }

  static Color getColorForType(ErrorType type) {
    switch (type) {
      case ErrorType.network:
      case ErrorType.websocket:
      case ErrorType.timeout:
        return networkError;
      case ErrorType.audio:
      case ErrorType.transcription:
        return audioError;
      case ErrorType.validation:
        return validationError;
      default:
        return mediumSeverity;
    }
  }
}

// Error Icons
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

  static IconData getIconForType(ErrorType type) {
    return icons[type] ?? Icons.error_outline;
  }
}