# Simple Network Detection & Beautiful Alerts - Implementation Guide

## Overview

A lightweight implementation to detect low bandwidth/no internet across the entire app and show beautiful, intelligent alerts to users.

---

## Implementation Tasks

### Task 1: Create Network Detection Service

**File:** `lib/services/simpleNetworkService.dart`

```dart
import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:flutter/foundation.dart';

enum NetworkQuality { excellent, good, poor, offline }

class SimpleNetworkService extends ChangeNotifier {
  static final SimpleNetworkService _instance = SimpleNetworkService._internal();
  factory SimpleNetworkService() => _instance;
  SimpleNetworkService._internal();

  NetworkQuality _currentQuality = NetworkQuality.offline;
  bool _isOnline = false;
  Timer? _monitoringTimer;

  NetworkQuality get currentQuality => _currentQuality;
  bool get isOnline => _isOnline;
  bool get isSlowConnection => _currentQuality == NetworkQuality.poor;

  Future<void> initialize() async {
    debugPrint('🚀 Initializing SimpleNetworkService');

    // Initial check
    await _checkNetworkStatus();

    // Monitor every 15 seconds
    _monitoringTimer = Timer.periodic(
      const Duration(seconds: 15),
      (timer) => _checkNetworkStatus(),
    );

    // Listen to connectivity changes
    Connectivity().onConnectivityChanged.listen((_) => _checkNetworkStatus());

    debugPrint('✅ SimpleNetworkService initialized');
  }

  Future<void> _checkNetworkStatus() async {
    try {
      final connectivityResults = await Connectivity().checkConnectivity();
      final hasInternet = await InternetConnection().hasInternetAccess;

      NetworkQuality newQuality;

      if (!hasInternet || connectivityResults.contains(ConnectivityResult.none)) {
        newQuality = NetworkQuality.offline;
      } else {
        // Simple bandwidth test
        final speed = await _testSpeed();
        if (speed > 2.0) {
          newQuality = NetworkQuality.excellent;
        } else if (speed > 0.5) {
          newQuality = NetworkQuality.good;
        } else {
          newQuality = NetworkQuality.poor;
        }
      }

      if (_currentQuality != newQuality || _isOnline != hasInternet) {
        _currentQuality = newQuality;
        _isOnline = hasInternet;
        notifyListeners();

        debugPrint('📡 Network Status: ${newQuality.name} (Online: $hasInternet)');
      }
    } catch (e) {
      debugPrint('❌ Network check failed: $e');
    }
  }

  Future<double> _testSpeed() async {
    try {
      final stopwatch = Stopwatch()..start();
      final response = await HttpClient()
          .getUrl(Uri.parse('https://httpbin.org/bytes/1024'))
          .timeout(const Duration(seconds: 3));
      final httpResponse = await response.close();
      await httpResponse.drain();
      stopwatch.stop();

      final bytes = 1024;
      final seconds = stopwatch.elapsedMilliseconds / 1000;
      final mbps = (bytes * 8) / (seconds * 1024 * 1024);

      return mbps.clamp(0.1, 100.0);
    } catch (e) {
      return 0.1; // Assume poor connection on error
    }
  }

  void dispose() {
    _monitoringTimer?.cancel();
    super.dispose();
  }
}
```

### Task 2: Create Network Provider

**File:** `lib/providers/simpleNetworkProvider.dart`

```dart
import 'package:flutter/foundation.dart';
import '../services/simpleNetworkService.dart';

class SimpleNetworkProvider extends ChangeNotifier {
  final SimpleNetworkService _networkService = SimpleNetworkService();

  bool get isOnline => _networkService.isOnline;
  bool get isSlowConnection => _networkService.isSlowConnection;
  NetworkQuality get networkQuality => _networkService.currentQuality;

  SimpleNetworkProvider() {
    _networkService.addListener(_onNetworkChanged);
  }

  void _onNetworkChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    _networkService.removeListener(_onNetworkChanged);
    super.dispose();
  }
}
```

### Task 3: Create Beautiful Alert Widget

**File:** `lib/widgets/networkAlertDialog.dart`

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NetworkAlertDialog extends StatefulWidget {
  final bool isOffline;
  final bool isSlowConnection;
  final VoidCallback onRetry;
  final VoidCallback? onContinueOffline;

  const NetworkAlertDialog({
    super.key,
    required this.isOffline,
    required this.isSlowConnection,
    required this.onRetry,
    this.onContinueOffline,
  });

  @override
  State<NetworkAlertDialog> createState() => _NetworkAlertDialogState();
}

class _NetworkAlertDialogState extends State<NetworkAlertDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Dialog(
              backgroundColor: Colors.transparent,
              child: _buildAlertContent(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAlertContent() {
    final isOffline = widget.isOffline;
    final config = isOffline ? _getOfflineConfig() : _getSlowConfig();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: config.color.withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated Icon
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.8 + (0.2 * value),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: config.color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    config.icon,
                    size: 40,
                    color: config.color,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          // Title
          Text(
            config.title,
            style: GoogleFonts.raleway(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D3748),
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),

          // Description
          Text(
            config.description,
            style: GoogleFonts.raleway(
              fontSize: 16,
              color: const Color(0xFF718096),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // Action Buttons
          _buildActionButtons(config),
        ],
      ),
    );
  }

  Widget _buildActionButtons(_AlertConfig config) {
    return Column(
      children: [
        // Primary Action (Retry)
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onRetry();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: config.color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.refresh, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Try Again',
                  style: GoogleFonts.raleway(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Secondary Action (Continue Offline) - only for offline
        if (widget.isOffline && widget.onContinueOffline != null) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onContinueOffline!();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF718096),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.offline_bolt, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Continue Offline',
                    style: GoogleFonts.raleway(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        // Dismiss button
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Dismiss',
            style: GoogleFonts.raleway(
              fontSize: 14,
              color: const Color(0xFF718096),
            ),
          ),
        ),
      ],
    );
  }

  _AlertConfig _getOfflineConfig() {
    return _AlertConfig(
      icon: Icons.wifi_off_rounded,
      title: 'No Internet Connection',
      description: 'Please check your connection and try again. Some features may be limited in offline mode.',
      color: const Color(0xFFE53E3E), // Red
    );
  }

  _AlertConfig _getSlowConfig() {
    return _AlertConfig(
      icon: Icons.signal_wifi_1_bar_rounded,
      title: 'Slow Connection Detected',
      description: 'Your internet seems slow. This might affect your learning experience.',
      color: const Color(0xFFED8936), // Orange
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

class _AlertConfig {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _AlertConfig({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}
```

### Task 4: Create Network Alert Manager

**File:** `lib/utils/networkAlertManager.dart`

```dart
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
          // Force network check
          await SimpleNetworkService()._checkNetworkStatus();
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
```

### Task 5: Create Network Listener Widget

**File:** `lib/widgets/networkListener.dart`

```dart
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
```

### Task 6: Update Main.dart

**File:** `lib/main.dart` (modifications)

```dart
// Add these imports at the top
import 'package:eureka_app/services/simpleNetworkService.dart';
import 'package:eureka_app/providers/simpleNetworkProvider.dart';
import 'package:eureka_app/widgets/networkListener.dart';

// In main() function, add after Firebase initialization:
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Existing Firebase initialization...
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Network Service
  await SimpleNetworkService().initialize();

  // Rest of existing code...
  runApp(MyApp(
    firstLaunch: firstLaunch,
    notificationService: notificationService,
  ));
}

// Update MultiProvider in MyApp build method:
@override
Widget build(BuildContext context) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => MyAppState()),
      ChangeNotifierProvider(create: (_) => AudioProvider()),
      ChangeNotifierProvider(create: (_) => SimpleNetworkProvider()), // ADD THIS
    ],
    child: Builder(
      builder: (context) {
        WidgetsBinding.instance.addObserver(LifecycleEventHandler(
            context: context, firstLaunch: firstLaunch));

        return NetworkListener( // WRAP MaterialApp with NetworkListener
          child: MaterialApp(
            title: "Tuto: AI Tutor for Class 6-12",
            navigatorKey: navigatorKey,
            // ... rest of existing MaterialApp properties
          ),
        );
      },
    ),
  );
}
```

### Task 7: Add Network Status Indicator (Optional)

**File:** `lib/widgets/simpleNetworkIndicator.dart`

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/simpleNetworkProvider.dart';

class SimpleNetworkIndicator extends StatelessWidget {
  const SimpleNetworkIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SimpleNetworkProvider>(
      builder: (context, provider, child) {
        if (provider.isOnline && !provider.isSlowConnection) {
          return const SizedBox.shrink(); // Hide when connection is good
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: provider.isOnline
                ? Colors.orange.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: provider.isOnline
                  ? Colors.orange.withOpacity(0.3)
                  : Colors.red.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                provider.isOnline ? Icons.signal_wifi_1_bar : Icons.wifi_off,
                size: 14,
                color: provider.isOnline ? Colors.orange : Colors.red,
              ),
              const SizedBox(width: 4),
              Text(
                provider.isOnline ? 'Slow' : 'Offline',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: provider.isOnline ? Colors.orange : Colors.red,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
```

---

## Quick Integration Guide

### Step 1: Add Files

1. Create all the files above in their respective directories
2. Make sure to import the required packages

### Step 2: Update Dependencies (if needed)

```yaml
# These should already exist in your pubspec.yaml
dependencies:
  connectivity_plus: ^7.0.0
  internet_connection_checker_plus: ^2.5.2
  provider: ^6.0.0
  google_fonts: ^6.2.1
```

### Step 3: Update Main.dart

- Add the network service initialization
- Add SimpleNetworkProvider to MultiProvider
- Wrap MaterialApp with NetworkListener

### Step 4: Test

1. Run the app
2. Turn on airplane mode → Should show offline alert
3. Turn on mobile data with poor signal → Should show slow connection alert
4. Restore good connection → Should show "Back online!" snackbar

---

## How It Works

1. **SimpleNetworkService** continuously monitors network status every 15 seconds
2. **SimpleNetworkProvider** provides network state to the entire app
3. **NetworkListener** wraps the entire app and automatically shows alerts when network changes
4. **NetworkAlertDialog** shows beautiful, animated alerts with retry options
5. **SimpleNetworkIndicator** (optional) can be added to any screen's AppBar

The system is completely automatic - no need to add anything to individual screens. It will detect network issues anywhere in the app and show appropriate alerts with your app's theme and styling.

## Features

- ✅ Automatic network detection across entire app
- ✅ Beautiful, animated alerts with app theme
- ✅ Smart retry mechanism
- ✅ Offline mode support
- ✅ Slow connection warnings
- ✅ Success notifications when back online
- ✅ Non-intrusive status indicator
- ✅ Minimal performance impact

This is a much simpler, focused solution that gives you exactly what you need!
