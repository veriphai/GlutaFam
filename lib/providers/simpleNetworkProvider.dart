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