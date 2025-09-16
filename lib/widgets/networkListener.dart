import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/simpleNetworkProvider.dart';
import '../utils/networkAlertManager.dart';

class NetworkListener extends StatefulWidget {
  final Widget child;

  const NetworkListener({super.key, required this.child});

  @override
  State<NetworkListener> createState() => _NetworkListenerState();
}

class _NetworkListenerState extends State<NetworkListener> {
  bool _wasOnline = true;
  bool _wasSlowConnection = false;

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

  void _handleNetworkChange(BuildContext context, SimpleNetworkProvider provider) {
    final isOnline = provider.isOnline;
    final isSlowConnection = provider.isSlowConnection;

    // Show alert when going offline
    if (_wasOnline && !isOnline) {
      NetworkAlertManager.instance.showNetworkAlert(
        context,
        isOffline: true,
        isSlowConnection: false,
        onContinueOffline: () {
          // Handle offline mode if needed
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You are now in offline mode'),
              backgroundColor: Colors.orange,
            ),
          );
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
      ScaffoldMessenger.of(context).showSnackBar(
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }

    _wasOnline = isOnline;
    _wasSlowConnection = isSlowConnection;
  }
}