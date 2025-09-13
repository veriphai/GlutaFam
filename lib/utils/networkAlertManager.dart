import 'package:flutter/material.dart';
import '../widgets/networkAlertDialog.dart';
import '../services/simpleNetworkService.dart';

class NetworkAlertManager {
  static NetworkAlertManager? _instance;
  static NetworkAlertManager get instance => _instance ??= NetworkAlertManager._();
  NetworkAlertManager._();

  bool _isShowingAlert = false;
  DateTime? _lastAlertShown;
  String? _lastAlertType;

  bool get isShowingAlert => _isShowingAlert;

  void showNetworkAlert(
    BuildContext context, {
    required bool isOffline,
    required bool isSlowConnection,
    VoidCallback? onContinueOffline,
    String? speedInfo,
  }) {
    // Prevent showing multiple alerts
    if (_isShowingAlert) return;

    // Prevent showing the same alert type too frequently (minimum 10 seconds between same type)
    final currentAlertType = isOffline ? 'offline' : 'slow';
    final now = DateTime.now();
    
    if (_lastAlertShown != null && 
        _lastAlertType == currentAlertType &&
        now.difference(_lastAlertShown!).inSeconds < 10) {
      return;
    }

    _isShowingAlert = true;
    _lastAlertShown = now;
    _lastAlertType = currentAlertType;

    // Add haptic feedback for better UX
    _triggerHapticFeedback();

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (dialogContext) => NetworkAlertDialog(
        isOffline: isOffline,
        isSlowConnection: isSlowConnection,
        speedInfo: speedInfo,
        onRetry: () async {
          _isShowingAlert = false;
          
          // Show loading indicator while retrying
          _showRetryingOverlay(context);
          
          // Force network check
          await SimpleNetworkService().forceNetworkCheck();
          
          // Hide loading indicator
          _hideRetryingOverlay();
          
          // Small delay for better UX
          await Future.delayed(const Duration(milliseconds: 500));
        },
        onContinueOffline: onContinueOffline != null ? () {
          _isShowingAlert = false;
          onContinueOffline();
        } : null,
      ),
    ).then((_) {
      _isShowingAlert = false;
    });
  }

  void _triggerHapticFeedback() {
    try {
      // Use light impact for network alerts
      // HapticFeedback.lightImpact();
    } catch (e) {
      // Ignore haptic feedback errors
    }
  }

  OverlayEntry? _retryingOverlay;

  void _showRetryingOverlay(BuildContext context) {
    if (_retryingOverlay != null) return;

    _retryingOverlay = OverlayEntry(
      builder: (context) => Material(
        color: Colors.black.withOpacity(0.3),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4299E1)),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Checking connection...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_retryingOverlay!);
  }

  void _hideRetryingOverlay() {
    _retryingOverlay?.remove();
    _retryingOverlay = null;
  }

  void hideAlert() {
    _isShowingAlert = false;
    _hideRetryingOverlay();
  }

  // Method to show a success message when connection is restored
  void showConnectionRestoredMessage(BuildContext context, {
    String? speedInfo,
  }) {
    // Don't show if we're already showing an alert
    if (_isShowingAlert) return;

    final messenger = ScaffoldMessenger.of(context);
    
    messenger.hideCurrentSnackBar();
    
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.white24,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Back online!',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  if (speedInfo != null)
                    Text(
                      speedInfo,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF38A169),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: '✓',
          textColor: Colors.white,
          onPressed: () => messenger.hideCurrentSnackBar(),
        ),
      ),
    );
  }

  // Reset alert timing (useful for testing or manual resets)
  void resetAlertTiming() {
    _lastAlertShown = null;
    _lastAlertType = null;
  }
}