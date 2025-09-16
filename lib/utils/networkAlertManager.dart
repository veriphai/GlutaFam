import 'package:flutter/material.dart';
import '../widgets/networkAlertDialog.dart';
import '../services/simpleNetworkService.dart';

class NetworkAlertManager {
  static NetworkAlertManager? _instance;
  static NetworkAlertManager get instance => _instance ??= NetworkAlertManager._();
  NetworkAlertManager._();

  bool _isShowingAlert = false;
  OverlayEntry? _overlayEntry;

  void showNetworkAlert(BuildContext context, {
    required bool isOffline,
    required bool isSlowConnection,
    VoidCallback? onContinueOffline,
  }) {
    if (_isShowingAlert) return;

    _isShowingAlert = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => NetworkAlertDialog(
        isOffline: isOffline,
        isSlowConnection: isSlowConnection,
        onRetry: () async {
          _isShowingAlert = false;
          // Force network check - we'll create a public method for this
          await SimpleNetworkService().checkNetworkStatus();
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

  void hideAlert() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isShowingAlert = false;
  }
}