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

class _NetworkListenerState extends State<NetworkListener> with WidgetsBindingObserver {
  bool _wasOnline = true;
  bool _wasSlowConnection = false;
  NetworkQuality? _previousQuality;
  bool _isFirstCheck = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Force network check when app comes back to foreground
    if (state == AppLifecycleState.resumed) {
      final networkProvider = Provider.of<SimpleNetworkProvider>(context, listen: false);
      networkProvider.forceNetworkCheck();
    }
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

  void _handleNetworkChange(BuildContext context, SimpleNetworkProvider provider) {
    final isOnline = provider.isOnline;
    final isSlowConnection = provider.isSlowConnection;
    final currentQuality = provider.networkQuality;

    // Skip handling on first check to avoid showing alerts immediately on app start
    if (_isFirstCheck) {
      _wasOnline = isOnline;
      _wasSlowConnection = isSlowConnection;
      _previousQuality = currentQuality;
      _isFirstCheck = false;
      return;
    }

    // Handle offline state
    if (_wasOnline && !isOnline) {
      debugPrint('🔴 Network: Going offline');
      NetworkAlertManager.instance.showNetworkAlert(
        context,
        isOffline: true,
        isSlowConnection: false,
        speedInfo: provider.networkDescription,
        onContinueOffline: () {
          _showOfflineModeSnackBar(context);
        },
      );
    }
    
    // Handle slow connection (only if online and wasn't slow before)
    else if (isOnline && !_wasSlowConnection && isSlowConnection) {
      debugPrint('🟡 Network: Connection became slow');
      NetworkAlertManager.instance.showNetworkAlert(
        context,
        isOffline: false,
        isSlowConnection: true,
        speedInfo: provider.networkDescription,
      );
    }
    
    // Handle connection restored (from offline to online)
    else if (!_wasOnline && isOnline) {
      debugPrint('🟢 Network: Connection restored');
      NetworkAlertManager.instance.showConnectionRestoredMessage(
        context,
        speedInfo: provider.networkDescription,
      );
    }
    
    // Handle connection improved (from slow to good)
    else if (isOnline && _wasSlowConnection && !isSlowConnection && 
             (_previousQuality == NetworkQuality.poor && 
              (currentQuality == NetworkQuality.good || currentQuality == NetworkQuality.excellent))) {
      debugPrint('🟢 Network: Connection improved');
      _showConnectionImprovedSnackBar(context, provider.networkDescription);
    }

    // Update previous state
    _wasOnline = isOnline;
    _wasSlowConnection = isSlowConnection;
    _previousQuality = currentQuality;
  }

  void _showOfflineModeSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.offline_bolt_outlined,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Offline Mode Active',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    'Limited features available',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFED8936), // Orange
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showConnectionImprovedSnackBar(BuildContext context, String speedInfo) {
    ScaffoldMessenger.of(context).showSnackBar(
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
                Icons.signal_wifi_4_bar,
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
                    'Connection Improved!',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
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
        backgroundColor: const Color(0xFF48BB78), // Green
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: '✓',
          textColor: Colors.white,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }
}