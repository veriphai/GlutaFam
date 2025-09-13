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
  double _lastSpeedMbps = 0.0;
  DateTime? _lastSpeedTest;

  NetworkQuality get currentQuality => _currentQuality;
  bool get isOnline => _isOnline;
  bool get isSlowConnection => _currentQuality == NetworkQuality.poor;
  double get lastSpeedMbps => _lastSpeedMbps;

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
        _lastSpeedMbps = 0.0;
      } else {
        // Only test speed every 30 seconds to avoid excessive data usage
        final now = DateTime.now();
        if (_lastSpeedTest == null || 
            now.difference(_lastSpeedTest!).inSeconds > 30) {
          final speed = await _testSpeed();
          _lastSpeedMbps = speed;
          _lastSpeedTest = now;
        }

        // Classify network quality based on speed
        if (_lastSpeedMbps > 2.0) {
          newQuality = NetworkQuality.excellent;
        } else if (_lastSpeedMbps > 0.5) {
          newQuality = NetworkQuality.good;
        } else {
          newQuality = NetworkQuality.poor;
        }
      }

      if (_currentQuality != newQuality || _isOnline != hasInternet) {
        _currentQuality = newQuality;
        _isOnline = hasInternet;
        notifyListeners();

        debugPrint('📡 Network Status: ${newQuality.name} (Online: $hasInternet, Speed: ${_lastSpeedMbps.toStringAsFixed(2)} Mbps)');
      }
    } catch (e) {
      debugPrint('❌ Network check failed: $e');
    }
  }

  Future<double> _testSpeed() async {
    try {
      final stopwatch = Stopwatch()..start();
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 3);
      
      final request = await client.getUrl(Uri.parse('https://httpbin.org/bytes/2048'));
      final response = await request.close();
      
      int totalBytes = 0;
      await for (var data in response) {
        totalBytes += data.length;
      }
      
      stopwatch.stop();
      client.close();

      final seconds = stopwatch.elapsedMilliseconds / 1000;
      final mbps = (totalBytes * 8) / (seconds * 1024 * 1024);

      return mbps.clamp(0.1, 100.0);
    } catch (e) {
      debugPrint('Speed test failed: $e');
      return 0.1; // Assume poor connection on error
    }
  }

  // Force a network check (useful for retry buttons)
  Future<void> forceNetworkCheck() async {
    _lastSpeedTest = null; // Force speed retest
    await _checkNetworkStatus();
  }

  String getNetworkQualityDescription() {
    switch (_currentQuality) {
      case NetworkQuality.excellent:
        return 'Excellent connection (${_lastSpeedMbps.toStringAsFixed(1)} Mbps)';
      case NetworkQuality.good:
        return 'Good connection (${_lastSpeedMbps.toStringAsFixed(1)} Mbps)';
      case NetworkQuality.poor:
        return 'Slow connection (${_lastSpeedMbps.toStringAsFixed(1)} Mbps)';
      case NetworkQuality.offline:
        return 'No internet connection';
    }
  }

  @override
  void dispose() {
    _monitoringTimer?.cancel();
    super.dispose();
  }
}