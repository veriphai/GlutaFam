import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:flutter/foundation.dart';

enum NetworkQuality { excellent, good, poor, offline }

class SimpleNetworkService extends ChangeNotifier {
  static final SimpleNetworkService _instance =
      SimpleNetworkService._internal();
  factory SimpleNetworkService() => _instance;
  SimpleNetworkService._internal();

  NetworkQuality _currentQuality = NetworkQuality.offline;
  bool _isOnline = false;
  Timer? _monitoringTimer;
  int _timerCallCount = 0;

  NetworkQuality get currentQuality => _currentQuality;
  bool get isOnline => _isOnline;
  bool get isSlowConnection => _currentQuality == NetworkQuality.poor;
  bool get isTimerActive => _monitoringTimer?.isActive ?? false;
  int get timerCallCount => _timerCallCount;

  Future<void> initialize() async {
    debugPrint('🚀 Initializing SimpleNetworkService');

    // Initial check
    await _checkNetworkStatus();

    // Monitor every 15 seconds
    debugPrint('⏰ Setting up monitoring timer (15 seconds interval)');
    _monitoringTimer = Timer.periodic(
      const Duration(seconds: 15),
      (timer) {
        _timerCallCount++;
        debugPrint(
            '⏰ Timer triggered (#$_timerCallCount) - checking network status');
        _checkNetworkStatus();
      },
    );

    // Listen to connectivity changes
    Connectivity().onConnectivityChanged.listen((_) => _checkNetworkStatus());

    debugPrint('✅ SimpleNetworkService initialized');
    debugPrint(
        '📊 Timer active: ${isTimerActive}, Call count: $timerCallCount');
  }

  Future<void> _checkNetworkStatus() async {
    debugPrint('🔍 Checking network status at ${DateTime.now()}');
    try {
      final connectivityResults = await Connectivity().checkConnectivity();
      final hasInternet = await InternetConnection().hasInternetAccess;

      NetworkQuality newQuality;

      if (!hasInternet ||
          connectivityResults.contains(ConnectivityResult.none)) {
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

        debugPrint(
            '📡 Network Status: ${newQuality.name} (Online: $hasInternet)');
      }
    } catch (e) {
      debugPrint('❌ Network check failed: $e');
    }
  }

  // Public method to force network check
  Future<void> checkNetworkStatus() async {
    await _checkNetworkStatus();
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
