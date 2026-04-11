import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../providers/simpleNetworkProvider.dart';
import '../utils/networkAlertManager.dart';
import '../utils/navigation_utils.dart';

class NetworkListener extends StatefulWidget {
  final Widget child;

  const NetworkListener({super.key, required this.child});

  @override
  State<NetworkListener> createState() => _NetworkListenerState();
}

// Global function to reset network listener state (for debugging)
void resetNetworkListenerState() {
  NetworkAlertManager.instance.resetState();
}

class _NetworkListenerState extends State<NetworkListener> {
  bool _wasOnline = false; // Start with false to match service initial state
  bool _wasSlowConnection = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Explicitly reset all states on init
    _wasOnline = false;
    _wasSlowConnection = false;
    _isInitialized = false;
    NetworkAlertManager.instance.resetState();
    debugPrint(
        '🔄 NetworkListener: initState - forcibly resetting all states to false');
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SimpleNetworkProvider>(
      builder: (context, networkProvider, child) {
        // Check for network state changes
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleNetworkChange(context, networkProvider);
        });

        return widget.child;
      },
    );
  }

  void _handleNetworkChange(
      BuildContext context, SimpleNetworkProvider provider) {
    final isOnline = provider.isOnline;
    final isSlowConnection = provider.isSlowConnection;

    debugPrint('🔍 NetworkListener: _handleNetworkChange called');
    debugPrint(
        '📊 Current state: isOnline=$isOnline, isSlowConnection=$isSlowConnection');
    debugPrint(
        '📊 Previous state: _wasOnline=$_wasOnline, _wasSlowConnection=$_wasSlowConnection, _isInitialized=$_isInitialized');
    debugPrint(
        '🔍 State check: Should show offline alert? ${!_isInitialized && !isOnline} OR ${_wasOnline && !isOnline}');

    // If not initialized, show alert immediately if offline
    if (!_isInitialized) {
      _isInitialized = true;
      if (!isOnline) {
        debugPrint(
            '🚨 NetworkListener: Initial state is offline, showing alert immediately');
        NetworkAlertManager.instance.showNetworkAlert(
          context,
          isOffline: true,
          isSlowConnection: false,
          onContinueOffline: () {
            final scaffoldContext = navigatorKey.currentContext;
            if (scaffoldContext != null) {
              ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                const SnackBar(
                  content: Text('You are now in offline mode'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          },
        );
      } else if (isSlowConnection) {
        debugPrint(
            '🚨 NetworkListener: Initial state is slow connection, showing alert immediately');
        NetworkAlertManager.instance.showNetworkAlert(
          context,
          isOffline: false,
          isSlowConnection: true,
        );
      }
    }
    // Show alert when going offline
    else if (_wasOnline && !isOnline) {
      debugPrint('🚨 NetworkListener: Showing offline alert');
      NetworkAlertManager.instance.showNetworkAlert(
        context,
        isOffline: true,
        isSlowConnection: false,
        onContinueOffline: () {
          // Handle offline mode if needed
          final scaffoldContext = navigatorKey.currentContext;
          if (scaffoldContext != null) {
            ScaffoldMessenger.of(scaffoldContext).showSnackBar(
              const SnackBar(
                content: Text('You are now in offline mode'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        },
      );
    }
    // Show alert when connection becomes slow
    else if (isOnline && !_wasSlowConnection && isSlowConnection) {
      NetworkAlertManager.instance.showNetworkAlert(
        context,
        isOffline: false,
        isSlowConnection: true,
      );
    }
    // Show success message when connection improves
    else if (!_wasOnline && isOnline) {
      final scaffoldContext = navigatorKey.currentContext;
      if (scaffoldContext != null) {
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.wifi, color: Colors.white),
                SizedBox(width: 8),
                Text('Back online!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }

    _wasOnline = isOnline;
    _wasSlowConnection = isSlowConnection;
  }
}
