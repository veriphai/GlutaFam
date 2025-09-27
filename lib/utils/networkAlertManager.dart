import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../widgets/networkAlertDialog.dart';
import '../services/simpleNetworkService.dart';
import '../utils/navigation_utils.dart';

class NetworkAlertManager {
  static NetworkAlertManager? _instance;
  static NetworkAlertManager get instance =>
      _instance ??= NetworkAlertManager._();
  NetworkAlertManager._();

  bool _isShowingAlert = false;
  OverlayEntry? _overlayEntry;

  // Method to reset state if needed
  void resetState() {
    debugPrint('🔄 NetworkAlertManager: Resetting state');
    _isShowingAlert = false;
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void showNetworkAlert(
    BuildContext context, {
    required bool isOffline,
    required bool isSlowConnection,
    VoidCallback? onContinueOffline,
  }) {
    debugPrint(
        '🚨 NetworkAlertManager: showNetworkAlert called - isOffline=$isOffline, isSlowConnection=$isSlowConnection');

    if (_isShowingAlert) {
      debugPrint(
          '⚠️ NetworkAlertManager: Alert state says showing, but forcing reset and retry');
      // Reset state and try again - this handles cases where dialog was dismissed unexpectedly
      resetState();
    }

    debugPrint('✅ NetworkAlertManager: Showing dialog');
    _isShowingAlert = true;

    // Use navigatorKey context to ensure MaterialLocalizations are available
    final navigatorContext = navigatorKey.currentContext;
    if (navigatorContext == null) {
      debugPrint('❌ NetworkAlertManager: No navigator context available');
      _isShowingAlert = false;
      return;
    }

    showDialog(
      context: navigatorContext,
      barrierDismissible: false,
      builder: (context) => NetworkAlertDialog(
        isOffline: isOffline,
        isSlowConnection: isSlowConnection,
        onRetry: () async {
          _isShowingAlert = false;
          // Force network check - we'll create a public method for this
          await SimpleNetworkService().checkNetworkStatus();
        },
        onContinueOffline: onContinueOffline != null
            ? () {
                _isShowingAlert = false;
                onContinueOffline();
              }
            : null,
      ),
    ).then((_) {
      _isShowingAlert = false;
    });
  }

  void hideAlert() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isShowingAlert = false;
  }
}
