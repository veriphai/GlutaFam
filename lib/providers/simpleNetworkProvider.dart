import 'package:flutter/foundation.dart';
import '../services/simpleNetworkService.dart';

class SimpleNetworkProvider extends ChangeNotifier {
  final SimpleNetworkService _networkService = SimpleNetworkService();

  bool get isOnline => _networkService.isOnline;
  bool get isSlowConnection => _networkService.isSlowConnection;
  NetworkQuality get networkQuality => _networkService.currentQuality;
  double get lastSpeedMbps => _networkService.lastSpeedMbps;
  
  String get networkDescription => _networkService.getNetworkQualityDescription();
  
  SimpleNetworkProvider() {
    _networkService.addListener(_onNetworkChanged);
  }

  void _onNetworkChanged() {
    notifyListeners();
  }

  // Force a network check (useful for retry functionality)
  Future<void> forceNetworkCheck() async {
    await _networkService.forceNetworkCheck();
  }

  // Helper methods for UI
  bool get hasGoodConnection => networkQuality == NetworkQuality.excellent || networkQuality == NetworkQuality.good;
  bool get hasPoorConnection => networkQuality == NetworkQuality.poor;
  bool get isOffline => networkQuality == NetworkQuality.offline;

  @override
  void dispose() {
    _networkService.removeListener(_onNetworkChanged);
    super.dispose();
  }
}