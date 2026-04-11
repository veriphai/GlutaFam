import 'dart:async';
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
  bool _wasOnline = false;
  bool _wasSlowConnection = false;
  bool _isInitialized = false;
  Timer? _offlineDebounceTimer;

  @override
  void initState() {
    super.initState();
    _wasOnline = false;
    _wasSlowConnection = false;
    _isInitialized = false;
    NetworkAlertManager.instance.resetState();
    debugPrint(
        '🔄 NetworkListener: initState - forcibly resetting all states to false');
  }

  @override
  void dispose() {
    _offlineDebounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SimpleNetworkProvider>(
      builder: (context, networkProvider, child) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleNetworkChange(context, networkProvider);
        });

        return widget.child;
      },
    );
  }

  void _showOfflineAlert(BuildContext context) {
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

    if (!_isInitialized) {
      _isInitialized = true;
      if (!isOnline) {
        debugPrint(
            '🚨 NetworkListener: Initial state is offline, showing alert immediately');
        _showOfflineAlert(context);
      }
    }
    // Going offline — debounce for 3 seconds to avoid false positives (e.g. phone lock/unlock)
    else if (_wasOnline && !isOnline) {
      debugPrint(
          '⏳ NetworkListener: Went offline, starting 3s debounce before showing alert');
      _offlineDebounceTimer?.cancel();
      _offlineDebounceTimer = Timer(const Duration(seconds: 3), () {
        if (!mounted) return;
        final currentProvider =
            Provider.of<SimpleNetworkProvider>(context, listen: false);
        if (!currentProvider.isOnline) {
          debugPrint(
              '🚨 NetworkListener: Still offline after 3s debounce, showing alert');
          _showOfflineAlert(context);
        } else {
          debugPrint(
              '✅ NetworkListener: Back online within 3s, skipping alert');
        }
      });
    }
    // Back online — cancel any pending debounce, dismiss alert if showing
    else if (!_wasOnline && isOnline) {
      _offlineDebounceTimer?.cancel();
      NetworkAlertManager.instance.dismissIfShowing(context);
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
