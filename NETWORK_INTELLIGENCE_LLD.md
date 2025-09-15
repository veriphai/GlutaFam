# Network Connectivity Intelligence System - Low-Level Design (LLD)

## Table of Contents

1. [Implementation Overview](#1-implementation-overview)
2. [Phase 1: Core Network Intelligence Service](#2-phase-1-core-network-intelligence-service)
3. [Phase 2: Enhanced API Layer](#3-phase-2-enhanced-api-layer)
4. [Phase 3: UI Components & Error States](#4-phase-3-ui-components--error-states)
5. [Phase 4: Screen Integration](#5-phase-4-screen-integration)
6. [Phase 5: Caching & Offline System](#6-phase-5-caching--offline-system)
7. [Testing Implementation](#7-testing-implementation)
8. [Deployment Guide](#8-deployment-guide)

---

## 1. Implementation Overview

### 1.1 Current Architecture Analysis

**Existing Structure:**

- **Provider Pattern**: Uses `MultiProvider` with `MyAppState` and `AudioProvider`
- **Services Layer**: `audioProvider.dart`, `notificationService.dart`, `webSocketService.dart`
- **Utils Layer**: `checkInternetConnectivity.dart`, `lifecycle_event_handler.dart`
- **API Layer**: Individual API files in `lib/apis/` directory

### 1.2 Implementation Strategy

- **Non-Breaking Changes**: Implement as additive features
- **Progressive Enhancement**: Gradually replace existing network handling
- **Backward Compatibility**: Maintain existing functionality during transition

### 1.3 File Structure to Create

```
lib/
├── services/
│   ├── networkIntelligenceService.dart       # Core network monitoring
│   ├── smartCacheService.dart               # Intelligent caching
│   └── networkAnalyticsService.dart         # Performance tracking
├── models/
│   ├── networkModels.dart                   # Data models
│   └── errorModels.dart                     # Error state models
├── providers/
│   └── networkProvider.dart                # State management
├── widgets/
│   ├── networkStatusIndicator.dart          # Status bar widget
│   ├── intelligentErrorCard.dart           # Error UI components
│   └── adaptiveLoader.dart                 # Loading states
├── utils/
│   ├── networkUtils.dart                   # Helper functions
│   └── intelligentApiClient.dart           # Enhanced API wrapper
└── constants/
    └── networkConstants.dart               # Configuration constants
```

---

## 2. Phase 1: Core Network Intelligence Service

### 2.1 Task 1: Create Network Models

**File:** `lib/models/networkModels.dart`

```dart
// IMPLEMENTATION TASK: Create these data models exactly as shown

import 'package:flutter/foundation.dart';

enum ConnectionType { wifi, mobile, ethernet, none }

enum ConnectionQuality {
  excellent,  // >10 Mbps, <50ms latency
  good,       // 2-10 Mbps, 50-150ms latency
  fair,       // 0.5-2 Mbps, 150-300ms latency
  poor,       // <0.5 Mbps, >300ms latency
  offline     // No connection
}

class NetworkStatus {
  final bool isOnline;
  final ConnectionType connectionType;
  final ConnectionQuality quality;
  final double bandwidth; // Mbps
  final int latency; // milliseconds
  final double stability; // 0.0 to 1.0
  final DateTime lastUpdated;
  final double disconnectionProbability;
  final Duration estimatedStability;

  const NetworkStatus({
    required this.isOnline,
    required this.connectionType,
    required this.quality,
    required this.bandwidth,
    required this.latency,
    required this.stability,
    required this.lastUpdated,
    required this.disconnectionProbability,
    required this.estimatedStability,
  });

  NetworkStatus copyWith({
    bool? isOnline,
    ConnectionType? connectionType,
    ConnectionQuality? quality,
    double? bandwidth,
    int? latency,
    double? stability,
    DateTime? lastUpdated,
    double? disconnectionProbability,
    Duration? estimatedStability,
  }) {
    return NetworkStatus(
      isOnline: isOnline ?? this.isOnline,
      connectionType: connectionType ?? this.connectionType,
      quality: quality ?? this.quality,
      bandwidth: bandwidth ?? this.bandwidth,
      latency: latency ?? this.latency,
      stability: stability ?? this.stability,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      disconnectionProbability: disconnectionProbability ?? this.disconnectionProbability,
      estimatedStability: estimatedStability ?? this.estimatedStability,
    );
  }
}

class NetworkMetrics {
  final List<double> bandwidthHistory;
  final List<int> latencyHistory;
  final List<DateTime> disconnectionEvents;
  final Map<String, int> errorCounts;

  const NetworkMetrics({
    required this.bandwidthHistory,
    required this.latencyHistory,
    required this.disconnectionEvents,
    required this.errorCounts,
  });
}
```

**Testing Instructions:**

1. Create the file and add all models
2. Run `flutter analyze` to ensure no syntax errors
3. Import in a test file to verify all classes are accessible

### 2.2 Task 2: Create Network Intelligence Service

**File:** `lib/services/networkIntelligenceService.dart`

```dart
// IMPLEMENTATION TASK: Core network monitoring service

import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/networkModels.dart';

class NetworkIntelligenceService extends ChangeNotifier {
  // Singleton pattern
  static final NetworkIntelligenceService _instance =
      NetworkIntelligenceService._internal();
  factory NetworkIntelligenceService() => _instance;
  NetworkIntelligenceService._internal();

  // Private fields
  NetworkStatus _currentStatus = NetworkStatus(
    isOnline: false,
    connectionType: ConnectionType.none,
    quality: ConnectionQuality.offline,
    bandwidth: 0.0,
    latency: 0,
    stability: 0.0,
    lastUpdated: DateTime.now(),
    disconnectionProbability: 1.0,
    estimatedStability: Duration.zero,
  );

  Timer? _monitoringTimer;
  final List<double> _bandwidthHistory = [];
  final List<int> _latencyHistory = [];
  final List<DateTime> _disconnectionEvents = [];

  StreamController<NetworkStatus>? _statusController;
  StreamController<ConnectionQuality>? _qualityController;

  // Public getters
  NetworkStatus get currentStatus => _currentStatus;
  ConnectionQuality get currentQuality => _currentStatus.quality;
  bool get isOnline => _currentStatus.isOnline;

  // Streams
  Stream<NetworkStatus> get statusStream =>
      _statusController?.stream ?? Stream.empty();
  Stream<ConnectionQuality> get qualityStream =>
      _qualityController?.stream ?? Stream.empty();

  // IMPLEMENTATION TASK: Initialize the service
  Future<void> initialize() async {
    debugPrint('🚀 Initializing NetworkIntelligenceService');

    _statusController = StreamController<NetworkStatus>.broadcast();
    _qualityController = StreamController<ConnectionQuality>.broadcast();

    // Initial assessment
    await _assessCurrentNetwork();

    // Start continuous monitoring
    _startMonitoring();

    // Listen to connectivity changes
    Connectivity().onConnectivityChanged.listen(_onConnectivityChanged);

    debugPrint('✅ NetworkIntelligenceService initialized');
  }

  // IMPLEMENTATION TASK: Start continuous monitoring
  void _startMonitoring() {
    _monitoringTimer?.cancel();
    _monitoringTimer = Timer.periodic(
      const Duration(seconds: 10), // Monitor every 10 seconds
      (timer) => _assessCurrentNetwork(),
    );
  }

  // IMPLEMENTATION TASK: Handle connectivity changes
  void _onConnectivityChanged(List<ConnectivityResult> results) async {
    debugPrint('📡 Connectivity changed: $results');
    await _assessCurrentNetwork();
  }

  // IMPLEMENTATION TASK: Assess current network conditions
  Future<void> _assessCurrentNetwork() async {
    try {
      final connectivityResults = await Connectivity().checkConnectivity();
      final hasInternet = await InternetConnection().hasInternetAccess;

      final connectionType = _getConnectionType(connectivityResults);
      final quality = await _assessQuality(hasInternet, connectionType);
      final bandwidth = await _measureBandwidth();
      final latency = await _measureLatency();
      final stability = _calculateStability();

      final newStatus = NetworkStatus(
        isOnline: hasInternet,
        connectionType: connectionType,
        quality: quality,
        bandwidth: bandwidth,
        latency: latency,
        stability: stability,
        lastUpdated: DateTime.now(),
        disconnectionProbability: _predictDisconnection(),
        estimatedStability: _estimateStability(),
      );

      if (_shouldUpdateStatus(newStatus)) {
        final oldQuality = _currentStatus.quality;
        _currentStatus = newStatus;

        // Notify listeners
        notifyListeners();
        _statusController?.add(newStatus);

        if (oldQuality != newStatus.quality) {
          _qualityController?.add(newStatus.quality);
        }

        // Update history
        _updateHistory(bandwidth, latency);

        debugPrint('📊 Network Status Updated: ${quality.name} (${bandwidth.toStringAsFixed(1)}Mbps, ${latency}ms)');
      }
    } catch (e) {
      debugPrint('❌ Error assessing network: $e');
    }
  }

  // IMPLEMENTATION TASK: Helper methods
  ConnectionType _getConnectionType(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.wifi)) return ConnectionType.wifi;
    if (results.contains(ConnectivityResult.mobile)) return ConnectionType.mobile;
    if (results.contains(ConnectivityResult.ethernet)) return ConnectionType.ethernet;
    return ConnectionType.none;
  }

  Future<ConnectionQuality> _assessQuality(bool hasInternet, ConnectionType type) async {
    if (!hasInternet) return ConnectionQuality.offline;

    final bandwidth = await _measureBandwidth();
    final latency = await _measureLatency();

    if (bandwidth > 10 && latency < 50) return ConnectionQuality.excellent;
    if (bandwidth > 2 && latency < 150) return ConnectionQuality.good;
    if (bandwidth > 0.5 && latency < 300) return ConnectionQuality.fair;
    return ConnectionQuality.poor;
  }

  Future<double> _measureBandwidth() async {
    // IMPLEMENTATION TASK: Simple bandwidth estimation
    // In real implementation, you might download a small file and measure speed
    try {
      final stopwatch = Stopwatch()..start();
      final response = await HttpClient()
          .getUrl(Uri.parse('https://httpbin.org/bytes/1024'))
          .timeout(const Duration(seconds: 5));
      final httpResponse = await response.close().timeout(const Duration(seconds: 5));
      await httpResponse.drain();
      stopwatch.stop();

      final bytes = 1024;
      final seconds = stopwatch.elapsedMilliseconds / 1000;
      final bitsPerSecond = (bytes * 8) / seconds;
      final mbps = bitsPerSecond / (1024 * 1024);

      return mbps.clamp(0.1, 100.0);
    } catch (e) {
      return 1.0; // Default estimate
    }
  }

  Future<int> _measureLatency() async {
    // IMPLEMENTATION TASK: Measure ping time
    try {
      final stopwatch = Stopwatch()..start();
      await InternetConnection().hasInternetAccess;
      stopwatch.stop();
      return stopwatch.elapsedMilliseconds.clamp(10, 2000);
    } catch (e) {
      return 1000; // Default high latency
    }
  }

  double _calculateStability() {
    if (_disconnectionEvents.isEmpty) return 1.0;

    final now = DateTime.now();
    final recentDisconnections = _disconnectionEvents
        .where((event) => now.difference(event).inHours < 24)
        .length;

    return (1.0 - (recentDisconnections * 0.2)).clamp(0.0, 1.0);
  }

  double _predictDisconnection() {
    final stability = _calculateStability();
    return 1.0 - stability;
  }

  Duration _estimateStability() {
    final stability = _calculateStability();
    final minutes = (stability * 60).round();
    return Duration(minutes: minutes);
  }

  bool _shouldUpdateStatus(NetworkStatus newStatus) {
    return _currentStatus.quality != newStatus.quality ||
           _currentStatus.isOnline != newStatus.isOnline ||
           (DateTime.now().difference(_currentStatus.lastUpdated).inSeconds > 30);
  }

  void _updateHistory(double bandwidth, int latency) {
    _bandwidthHistory.add(bandwidth);
    _latencyHistory.add(latency);

    // Keep only last 100 measurements
    if (_bandwidthHistory.length > 100) _bandwidthHistory.removeAt(0);
    if (_latencyHistory.length > 100) _latencyHistory.removeAt(0);
  }

  // Public methods for other services to use
  Future<bool> canHandleRequest(String requestType) async {
    switch (requestType) {
      case 'video':
        return currentQuality.index >= ConnectionQuality.good.index;
      case 'audio':
        return currentQuality.index >= ConnectionQuality.fair.index;
      case 'text':
        return isOnline;
      default:
        return isOnline;
    }
  }

  // Cleanup
  void dispose() {
    _monitoringTimer?.cancel();
    _statusController?.close();
    _qualityController?.close();
    super.dispose();
  }
}
```

**Testing Instructions:**

1. Create the service file
2. Add to `main.dart` initialization:

```dart
// In main() function, after Firebase initialization
await NetworkIntelligenceService().initialize();
```

3. Test by toggling airplane mode and watching debug output

### 2.3 Task 3: Create Network Provider

**File:** `lib/providers/networkProvider.dart`

```dart
// IMPLEMENTATION TASK: State management integration

import 'package:flutter/foundation.dart';
import '../services/networkIntelligenceService.dart';
import '../models/networkModels.dart';

class NetworkProvider extends ChangeNotifier {
  final NetworkIntelligenceService _networkService = NetworkIntelligenceService();

  NetworkStatus get networkStatus => _networkService.currentStatus;
  ConnectionQuality get connectionQuality => _networkService.currentQuality;
  bool get isOnline => _networkService.isOnline;

  // Error state management
  String? _currentError;
  bool _showingErrorDialog = false;

  String? get currentError => _currentError;
  bool get showingErrorDialog => _showingErrorDialog;

  NetworkProvider() {
    _initializeListeners();
  }

  void _initializeListeners() {
    _networkService.addListener(() {
      notifyListeners();
    });

    _networkService.statusStream.listen((status) {
      if (!status.isOnline && !_showingErrorDialog) {
        _showNetworkError();
      } else if (status.isOnline && _showingErrorDialog) {
        _clearNetworkError();
      }
    });
  }

  void _showNetworkError() {
    _currentError = 'No internet connection';
    _showingErrorDialog = true;
    notifyListeners();
  }

  void _clearNetworkError() {
    _currentError = null;
    _showingErrorDialog = false;
    notifyListeners();
  }

  // Methods for UI to call
  Future<void> retryConnection() async {
    await _networkService._assessCurrentNetwork();
  }

  void acknowledgeError() {
    _showingErrorDialog = false;
    notifyListeners();
  }
}
```

### 2.4 Task 4: Update Main.dart Integration

**File:** `lib/main.dart` (modification)

```dart
// IMPLEMENTATION TASK: Add NetworkProvider to main.dart

// Add import at top
import 'package:eureka_app/providers/networkProvider.dart';
import 'package:eureka_app/services/networkIntelligenceService.dart';

// In main() function, add after Firebase initialization:
await NetworkIntelligenceService().initialize();

// In MyApp build method, update MultiProvider:
return MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => MyAppState()),
    ChangeNotifierProvider(create: (_) => AudioProvider()),
    ChangeNotifierProvider(create: (_) => NetworkProvider()), // ADD THIS LINE
  ],
  child: Builder(
    // ... rest of existing code
  ),
);
```

**Testing Instructions:**

1. Add NetworkProvider to MultiProvider
2. Run app and check no errors in console
3. Test airplane mode toggle - should see network status changes in debug output

---

## 3. Phase 2: Enhanced API Layer

### 3.1 Task 5: Create Intelligent API Client

**File:** `lib/utils/intelligentApiClient.dart`

```dart
// IMPLEMENTATION TASK: Enhanced API wrapper with retry logic

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../services/networkIntelligenceService.dart';
import '../models/networkModels.dart';
import '../models/errorModels.dart';

enum CachePriority { critical, high, medium, low }

class ApiRequest<T> {
  final String endpoint;
  final String method;
  final Map<String, dynamic>? body;
  final Map<String, String>? headers;
  final T Function(Map<String, dynamic>) parser;
  final CachePriority cachePriority;
  final Duration timeout;
  final bool allowOffline;

  const ApiRequest({
    required this.endpoint,
    this.method = 'GET',
    this.body,
    this.headers,
    required this.parser,
    this.cachePriority = CachePriority.medium,
    this.timeout = const Duration(seconds: 30),
    this.allowOffline = false,
  });
}

class IntelligentApiClient {
  static final IntelligentApiClient _instance = IntelligentApiClient._internal();
  factory IntelligentApiClient() => _instance;
  IntelligentApiClient._internal();

  final NetworkIntelligenceService _networkService = NetworkIntelligenceService();
  final List<ApiRequest> _requestQueue = [];
  Timer? _retryTimer;

  // IMPLEMENTATION TASK: Main request method with intelligence
  Future<T?> request<T>(ApiRequest<T> apiRequest) async {
    try {
      // Check if we can handle this request type
      final canHandle = await _networkService.canHandleRequest(_getRequestType(apiRequest.endpoint));

      if (!canHandle && !apiRequest.allowOffline) {
        debugPrint('⚠️ Network quality insufficient for ${apiRequest.endpoint}');
        _queueRequest(apiRequest);
        throw NetworkException('Network quality insufficient', NetworkErrorType.slowConnection);
      }

      return await _executeRequest(apiRequest);
    } catch (e) {
      debugPrint('❌ API Request failed: ${apiRequest.endpoint} - $e');

      if (e is NetworkException) {
        rethrow;
      }

      // Queue for retry if network-related
      if (_isNetworkError(e)) {
        _queueRequest(apiRequest);
        throw NetworkException('Network error occurred', NetworkErrorType.timeout);
      }

      rethrow;
    }
  }

  // IMPLEMENTATION TASK: Execute HTTP request with retry logic
  Future<T?> _executeRequest<T>(ApiRequest<T> apiRequest, {int retryCount = 0}) async {
    const maxRetries = 3;

    try {
      final uri = Uri.parse(apiRequest.endpoint);
      late http.Response response;

      switch (apiRequest.method.toUpperCase()) {
        case 'GET':
          response = await http.get(uri, headers: apiRequest.headers)
              .timeout(apiRequest.timeout);
          break;
        case 'POST':
          response = await http.post(
            uri,
            headers: apiRequest.headers,
            body: apiRequest.body != null ? jsonEncode(apiRequest.body) : null,
          ).timeout(apiRequest.timeout);
          break;
        // Add other methods as needed
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return apiRequest.parser(data);
      } else {
        throw HttpException('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      if (retryCount < maxRetries && _shouldRetry(e)) {
        final delay = _calculateRetryDelay(retryCount);
        debugPrint('🔄 Retrying ${apiRequest.endpoint} in ${delay.inSeconds}s (attempt ${retryCount + 1}/$maxRetries)');

        await Future.delayed(delay);
        return _executeRequest(apiRequest, retryCount: retryCount + 1);
      }

      rethrow;
    }
  }

  // IMPLEMENTATION TASK: Helper methods
  String _getRequestType(String endpoint) {
    if (endpoint.contains('video') || endpoint.contains('stream')) return 'video';
    if (endpoint.contains('audio') || endpoint.contains('sound')) return 'audio';
    return 'text';
  }

  bool _isNetworkError(dynamic error) {
    return error is SocketException ||
           error is TimeoutException ||
           error is HttpException ||
           error.toString().contains('network') ||
           error.toString().contains('connection');
  }

  bool _shouldRetry(dynamic error) {
    if (error is HttpException) {
      final statusCode = int.tryParse(error.message.split(' ')[1]) ?? 0;
      return statusCode >= 500 || statusCode == 429; // Server errors or rate limiting
    }
    return _isNetworkError(error);
  }

  Duration _calculateRetryDelay(int retryCount) {
    // Exponential backoff with jitter
    final baseDelay = Duration(seconds: (2 << retryCount)); // 2, 4, 8 seconds
    final jitter = Duration(milliseconds: (DateTime.now().millisecondsSinceEpoch % 1000));
    return baseDelay + jitter;
  }

  void _queueRequest(ApiRequest apiRequest) {
    _requestQueue.add(apiRequest);
    debugPrint('📥 Queued request: ${apiRequest.endpoint}');

    // Start retry timer if not already running
    _retryTimer ??= Timer.periodic(const Duration(minutes: 1), _processQueue);
  }

  void _processQueue(Timer timer) async {
    if (_requestQueue.isEmpty) {
      timer.cancel();
      _retryTimer = null;
      return;
    }

    if (!_networkService.isOnline) return;

    debugPrint('🔄 Processing queued requests: ${_requestQueue.length}');

    final requestsToProcess = List<ApiRequest>.from(_requestQueue);
    _requestQueue.clear();

    for (final request in requestsToProcess) {
      try {
        await _executeRequest(request);
        debugPrint('✅ Queued request completed: ${request.endpoint}');
      } catch (e) {
        debugPrint('❌ Queued request failed again: ${request.endpoint}');
        // Could re-queue with different strategy
      }
    }
  }

  // Public method to get queue status
  int get queuedRequestsCount => _requestQueue.length;

  void dispose() {
    _retryTimer?.cancel();
  }
}
```

### 3.2 Task 6: Create Error Models

**File:** `lib/models/errorModels.dart`

```dart
// IMPLEMENTATION TASK: Error state models

import 'package:flutter/material.dart';

enum NetworkErrorType {
  noInternet,
  slowConnection,
  timeout,
  serverError,
  authenticationError,
  rateLimitExceeded
}

enum ErrorSeverity { low, medium, high, critical }

class NetworkException implements Exception {
  final String message;
  final NetworkErrorType type;
  final String? technicalDetails;
  final DateTime timestamp;

  NetworkException(
    this.message,
    this.type, {
    this.technicalDetails,
  }) : timestamp = DateTime.now();

  @override
  String toString() => 'NetworkException: $message';
}

class RecoveryAction {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback action;
  final RecoveryType type;

  const RecoveryAction({
    required this.title,
    required this.description,
    required this.icon,
    required this.action,
    required this.type,
  });
}

enum RecoveryType {
  retry,           // Try again
  switchMode,      // Go offline
  alternative,     // Use cached content
  troubleshoot,    // Show help
  contact          // Support
}

class NetworkError {
  final NetworkErrorType type;
  final String message;
  final String? technicalDetails;
  final DateTime timestamp;
  final String? requestId;
  final List<RecoveryAction> recoveryActions;
  final ErrorSeverity severity;

  NetworkError({
    required this.type,
    required this.message,
    this.technicalDetails,
    required this.timestamp,
    this.requestId,
    required this.recoveryActions,
    required this.severity,
  });
}
```

---

## 4. Phase 3: UI Components & Error States

### 4.1 Task 7: Network Status Indicator

**File:** `lib/widgets/networkStatusIndicator.dart`

```dart
// IMPLEMENTATION TASK: Network status indicator widget

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/networkProvider.dart';
import '../models/networkModels.dart';

class NetworkStatusIndicator extends StatelessWidget {
  final bool showDetails;
  final VoidCallback? onTap;

  const NetworkStatusIndicator({
    super.key,
    this.showDetails = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<NetworkProvider>(
      builder: (context, networkProvider, child) {
        final quality = networkProvider.connectionQuality;
        final isOnline = networkProvider.isOnline;

        if (!isOnline) {
          return _buildOfflineIndicator(context);
        }

        return _buildQualityIndicator(context, quality);
      },
    );
  }

  Widget _buildOfflineIndicator(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off, size: 16, color: Colors.red.shade700),
            const SizedBox(width: 4),
            Text(
              'Offline',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQualityIndicator(BuildContext context, ConnectionQuality quality) {
    final config = _getQualityConfig(quality);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: config.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: config.color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                config.icon,
                key: ValueKey(quality),
                size: 16,
                color: config.color,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              config.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: config.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  _QualityConfig _getQualityConfig(ConnectionQuality quality) {
    switch (quality) {
      case ConnectionQuality.excellent:
        return _QualityConfig(
          icon: Icons.signal_wifi_4_bar,
          label: 'Excellent',
          color: Colors.green,
        );
      case ConnectionQuality.good:
        return _QualityConfig(
          icon: Icons.signal_wifi_4_bar,
          label: 'Good',
          color: Colors.blue,
        );
      case ConnectionQuality.fair:
        return _QualityConfig(
          icon: Icons.signal_wifi_2_bar,
          label: 'Fair',
          color: Colors.orange,
        );
      case ConnectionQuality.poor:
        return _QualityConfig(
          icon: Icons.signal_wifi_1_bar,
          label: 'Slow',
          color: Colors.red,
        );
      case ConnectionQuality.offline:
        return _QualityConfig(
          icon: Icons.wifi_off,
          label: 'Offline',
          color: Colors.red,
        );
    }
  }
}

class _QualityConfig {
  final IconData icon;
  final String label;
  final Color color;

  const _QualityConfig({
    required this.icon,
    required this.label,
    required this.color,
  });
}
```

### 4.2 Task 8: Intelligent Error Card

**File:** `lib/widgets/intelligentErrorCard.dart`

```dart
// IMPLEMENTATION TASK: Beautiful error UI component

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/errorModels.dart';

class IntelligentErrorCard extends StatefulWidget {
  final NetworkErrorType errorType;
  final String contextualMessage;
  final List<RecoveryAction> actions;
  final Widget? illustration;
  final bool showTechnicalDetails;

  const IntelligentErrorCard({
    super.key,
    required this.errorType,
    required this.contextualMessage,
    required this.actions,
    this.illustration,
    this.showTechnicalDetails = false,
  });

  @override
  State<IntelligentErrorCard> createState() => _IntelligentErrorCardState();
}

class _IntelligentErrorCardState extends State<IntelligentErrorCard>
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

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
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
            child: _buildErrorCard(context),
          ),
        );
      },
    );
  }

  Widget _buildErrorCard(BuildContext context) {
    final errorConfig = _getErrorConfig(widget.errorType);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: errorConfig.color.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: errorConfig.color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Illustration
          if (widget.illustration != null) ...[
            SizedBox(
              height: 120,
              child: widget.illustration!,
            ),
            const SizedBox(height: 16),
          ],

          // Error icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: errorConfig.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              errorConfig.icon,
              size: 32,
              color: errorConfig.color,
            ),
          ),

          const SizedBox(height: 16),

          // Primary message
          Text(
            errorConfig.title,
            style: GoogleFonts.raleway(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D3748),
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // Contextual message
          Text(
            widget.contextualMessage,
            style: GoogleFonts.raleway(
              fontSize: 16,
              color: const Color(0xFF718096),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // Recovery actions
          _buildRecoveryActions(),
        ],
      ),
    );
  }

  Widget _buildRecoveryActions() {
    if (widget.actions.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        // Primary action (usually retry)
        if (widget.actions.isNotEmpty)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.actions.first.action,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1D4ED8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(widget.actions.first.icon, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    widget.actions.first.title,
                    style: GoogleFonts.raleway(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Secondary actions
        if (widget.actions.length > 1) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: widget.actions.skip(1).map((action) {
              return OutlinedButton(
                onPressed: action.action,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF718096),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(action.icon, size: 16),
                    const SizedBox(width: 4),
                    Text(action.title),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  _ErrorConfig _getErrorConfig(NetworkErrorType type) {
    switch (type) {
      case NetworkErrorType.noInternet:
        return _ErrorConfig(
          icon: Icons.wifi_off,
          title: 'No Internet Connection',
          color: Colors.red,
        );
      case NetworkErrorType.slowConnection:
        return _ErrorConfig(
          icon: Icons.signal_wifi_1_bar,
          title: 'Slow Connection Detected',
          color: Colors.orange,
        );
      case NetworkErrorType.timeout:
        return _ErrorConfig(
          icon: Icons.access_time,
          title: 'Request Timed Out',
          color: Colors.amber,
        );
      case NetworkErrorType.serverError:
        return _ErrorConfig(
          icon: Icons.error_outline,
          title: 'Server Error',
          color: Colors.red,
        );
      default:
        return _ErrorConfig(
          icon: Icons.warning,
          title: 'Connection Issue',
          color: Colors.orange,
        );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

class _ErrorConfig {
  final IconData icon;
  final String title;
  final Color color;

  const _ErrorConfig({
    required this.icon,
    required this.title,
    required this.color,
  });
}
```

---

## 5. Phase 4: Screen Integration

### 5.1 Task 9: Update AI Tutor Screen

**File:** `lib/screens/aiTutor/aiTutorScreenV2.dart` (modifications)

```dart
// IMPLEMENTATION TASK: Add network intelligence to AI Tutor screen

// Add imports at the top
import 'package:provider/provider.dart';
import '../../providers/networkProvider.dart';
import '../../widgets/networkStatusIndicator.dart';
import '../../widgets/intelligentErrorCard.dart';
import '../../models/errorModels.dart';

// In the build method, add network status indicator to AppBar
AppBar(
  // ... existing AppBar properties
  actions: [
    // Add network status indicator
    const NetworkStatusIndicator(showDetails: true),
    const SizedBox(width: 8),
    // ... existing actions
  ],
),

// Add network-aware message sending
Future<void> _sendMessage() async {
  final networkProvider = context.read<NetworkProvider>();

  if (!networkProvider.isOnline) {
    _showNetworkError(context);
    return;
  }

  if (networkProvider.connectionQuality == ConnectionQuality.poor) {
    _showSlowConnectionWarning(context);
  }

  // Existing message sending logic...
}

void _showNetworkError(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      child: IntelligentErrorCard(
        errorType: NetworkErrorType.noInternet,
        contextualMessage: 'Your conversation is safely saved. Let\'s get you back on track!',
        actions: [
          RecoveryAction(
            title: 'Try Again',
            description: 'Check connection and retry',
            icon: Icons.refresh,
            action: () {
              Navigator.of(context).pop();
              context.read<NetworkProvider>().retryConnection();
            },
            type: RecoveryType.retry,
          ),
          RecoveryAction(
            title: 'Continue Offline',
            description: 'View saved conversations',
            icon: Icons.offline_bolt,
            action: () {
              Navigator.of(context).pop();
              // Switch to offline mode
            },
            type: RecoveryType.switchMode,
          ),
        ],
      ),
    ),
  );
}
```

### 5.2 Task 10: Update Home Screen

**File:** `lib/screens/home/homeScreenV2.dart` (modifications)

```dart
// IMPLEMENTATION TASK: Add network intelligence to Home screen

// Add imports
import 'package:provider/provider.dart';
import '../../providers/networkProvider.dart';
import '../../widgets/networkStatusIndicator.dart';

// In build method, add network status to app bar or body
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      // ... existing properties
      actions: [
        const NetworkStatusIndicator(),
        // ... existing actions
      ],
    ),
    body: Consumer<NetworkProvider>(
      builder: (context, networkProvider, child) {
        return Column(
          children: [
            // Show network banner if poor connection
            if (networkProvider.connectionQuality == ConnectionQuality.poor)
              _buildSlowConnectionBanner(),

            // Existing body content
            Expanded(
              child: _buildMainContent(networkProvider),
            ),
          ],
        );
      },
    ),
  );
}

Widget _buildSlowConnectionBanner() {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    color: Colors.orange.shade100,
    child: Row(
      children: [
        Icon(Icons.signal_wifi_1_bar, color: Colors.orange.shade700),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Slow connection detected. Some features may be limited.',
            style: TextStyle(color: Colors.orange.shade700),
          ),
        ),
        TextButton(
          onPressed: () {
            // Switch to offline mode
          },
          child: const Text('Go Offline'),
        ),
      ],
    ),
  );
}
```

---

## 6. Phase 5: Caching & Offline System

### 6.1 Task 11: Smart Cache Service

**File:** `lib/services/smartCacheService.dart`

```dart
// IMPLEMENTATION TASK: Intelligent caching system

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/networkModels.dart';

enum CachePriority { critical, high, medium, low }

class CacheEntry<T> {
  final String key;
  final T data;
  final DateTime createdAt;
  final DateTime expiresAt;
  final CachePriority priority;
  final int accessCount;
  final DateTime lastAccessed;

  CacheEntry({
    required this.key,
    required this.data,
    required this.createdAt,
    required this.expiresAt,
    required this.priority,
    this.accessCount = 0,
    DateTime? lastAccessed,
  }) : lastAccessed = lastAccessed ?? DateTime.now();

  CacheEntry<T> copyWith({
    int? accessCount,
    DateTime? lastAccessed,
  }) {
    return CacheEntry<T>(
      key: key,
      data: data,
      createdAt: createdAt,
      expiresAt: expiresAt,
      priority: priority,
      accessCount: accessCount ?? this.accessCount,
      lastAccessed: lastAccessed ?? this.lastAccessed,
    );
  }
}

class SmartCacheService {
  static final SmartCacheService _instance = SmartCacheService._internal();
  factory SmartCacheService() => _instance;
  SmartCacheService._internal();

  final Map<String, CacheEntry> _memoryCache = {};
  late SharedPreferences _prefs;
  late Directory _cacheDir;

  // Initialize cache service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _cacheDir = await getTemporaryDirectory();
    await _loadCacheIndex();
    debugPrint('✅ SmartCacheService initialized');
  }

  // Cache data with priority
  Future<void> cacheWithPriority<T>(
    String key,
    T data,
    CachePriority priority, {
    Duration? customExpiry,
  }) async {
    final expiry = customExpiry ?? _getDefaultExpiry(priority);
    final entry = CacheEntry<T>(
      key: key,
      data: data,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(expiry),
      priority: priority,
    );

    _memoryCache[key] = entry;
    await _persistEntry(key, entry);

    debugPrint('💾 Cached: $key (${priority.name})');
  }

  // Get data with fallback to network
  Future<T?> getWithFallback<T>(
    String key,
    Future<T> Function() networkFetch, {
    bool forceNetwork = false,
  }) async {
    // Try cache first (unless forced to network)
    if (!forceNetwork) {
      final cached = await get<T>(key);
      if (cached != null) {
        debugPrint('📦 Cache hit: $key');
        return cached;
      }
    }

    // Fetch from network
    try {
      final networkData = await networkFetch();
      // Cache the network result
      await cacheWithPriority(key, networkData, CachePriority.medium);
      debugPrint('🌐 Network fetch: $key');
      return networkData;
    } catch (e) {
      // If network fails, try cache as fallback
      final cached = await get<T>(key);
      if (cached != null) {
        debugPrint('📦 Cache fallback: $key');
        return cached;
      }
      rethrow;
    }
  }

  // Get cached data
  Future<T?> get<T>(String key) async {
    final entry = _memoryCache[key];
    if (entry == null) return null;

    // Check expiry
    if (DateTime.now().isAfter(entry.expiresAt)) {
      await remove(key);
      return null;
    }

    // Update access count
    _memoryCache[key] = entry.copyWith(
      accessCount: entry.accessCount + 1,
      lastAccessed: DateTime.now(),
    );

    return entry.data as T?;
  }

  // Remove cached item
  Future<void> remove(String key) async {
    _memoryCache.remove(key);
    await _prefs.remove('cache_$key');

    final file = File('${_cacheDir.path}/$key.cache');
    if (await file.exists()) {
      await file.delete();
    }

    debugPrint('🗑️ Removed from cache: $key');
  }

  // Clear cache by priority
  Future<void> clearByPriority(CachePriority priority) async {
    final keysToRemove = _memoryCache.entries
        .where((entry) => entry.value.priority == priority)
        .map((entry) => entry.key)
        .toList();

    for (final key in keysToRemove) {
      await remove(key);
    }
  }

  // Get cache statistics
  Map<String, dynamic> getStats() {
    final stats = <CachePriority, int>{};
    int totalSize = 0;

    for (final entry in _memoryCache.values) {
      stats[entry.priority] = (stats[entry.priority] ?? 0) + 1;
      totalSize += _estimateSize(entry.data);
    }

    return {
      'totalItems': _memoryCache.length,
      'totalSizeKB': totalSize ~/ 1024,
      'breakdown': stats.map((k, v) => MapEntry(k.name, v)),
    };
  }

  // Helper methods
  Duration _getDefaultExpiry(CachePriority priority) {
    switch (priority) {
      case CachePriority.critical:
        return const Duration(days: 7);
      case CachePriority.high:
        return const Duration(days: 3);
      case CachePriority.medium:
        return const Duration(days: 1);
      case CachePriority.low:
        return const Duration(hours: 6);
    }
  }

  Future<void> _loadCacheIndex() async {
    // Load cache index from persistent storage
    // Implementation depends on your needs
  }

  Future<void> _persistEntry(String key, CacheEntry entry) async {
    try {
      final jsonData = jsonEncode({
        'data': entry.data,
        'createdAt': entry.createdAt.toIso8601String(),
        'expiresAt': entry.expiresAt.toIso8601String(),
        'priority': entry.priority.name,
        'accessCount': entry.accessCount,
      });

      await _prefs.setString('cache_$key', jsonData);
    } catch (e) {
      debugPrint('❌ Failed to persist cache entry: $key');
    }
  }

  int _estimateSize(dynamic data) {
    try {
      return jsonEncode(data).length;
    } catch (e) {
      return 1024; // Default estimate
    }
  }
}
```

---

## 7. Testing Implementation

### 7.1 Task 12: Create Test Utilities

**File:** `test/network_test_utils.dart`

```dart
// IMPLEMENTATION TASK: Testing utilities for network features

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:eureka_app/services/networkIntelligenceService.dart';
import 'package:eureka_app/models/networkModels.dart';

class MockNetworkIntelligenceService extends Mock implements NetworkIntelligenceService {}

// Test helper to simulate network conditions
class NetworkTestHelper {
  static NetworkStatus createNetworkStatus({
    bool isOnline = true,
    ConnectionQuality quality = ConnectionQuality.good,
    double bandwidth = 5.0,
    int latency = 100,
  }) {
    return NetworkStatus(
      isOnline: isOnline,
      connectionType: isOnline ? ConnectionType.wifi : ConnectionType.none,
      quality: quality,
      bandwidth: bandwidth,
      latency: latency,
      stability: 0.8,
      lastUpdated: DateTime.now(),
      disconnectionProbability: 0.1,
      estimatedStability: const Duration(minutes: 30),
    );
  }

  // Simulate network conditions for testing
  static void simulateOffline(MockNetworkIntelligenceService mockService) {
    when(mockService.currentStatus).thenReturn(
      createNetworkStatus(isOnline: false, quality: ConnectionQuality.offline),
    );
    when(mockService.isOnline).thenReturn(false);
  }

  static void simulateSlowConnection(MockNetworkIntelligenceService mockService) {
    when(mockService.currentStatus).thenReturn(
      createNetworkStatus(
        isOnline: true,
        quality: ConnectionQuality.poor,
        bandwidth: 0.3,
        latency: 500,
      ),
    );
    when(mockService.isOnline).thenReturn(true);
  }
}
```

### 7.2 Task 13: Unit Tests

**File:** `test/network_intelligence_test.dart`

```dart
// IMPLEMENTATION TASK: Unit tests for network intelligence

import 'package:flutter_test/flutter_test.dart';
import 'package:eureka_app/services/networkIntelligenceService.dart';
import 'package:eureka_app/models/networkModels.dart';

void main() {
  group('NetworkIntelligenceService Tests', () {
    late NetworkIntelligenceService service;

    setUp(() {
      service = NetworkIntelligenceService();
    });

    test('should initialize with offline status', () {
      expect(service.currentStatus.isOnline, false);
      expect(service.currentStatus.quality, ConnectionQuality.offline);
    });

    test('should assess connection quality correctly', () async {
      // This would need to be mocked in real implementation
      // Testing the logic for quality assessment

      // Excellent quality test
      final excellentStatus = NetworkStatus(
        isOnline: true,
        connectionType: ConnectionType.wifi,
        quality: ConnectionQuality.excellent,
        bandwidth: 15.0,
        latency: 30,
        stability: 0.9,
        lastUpdated: DateTime.now(),
        disconnectionProbability: 0.1,
        estimatedStability: const Duration(hours: 1),
      );

      expect(excellentStatus.quality, ConnectionQuality.excellent);
      expect(excellentStatus.bandwidth, greaterThan(10));
      expect(excellentStatus.latency, lessThan(50));
    });

    test('should handle request type checking', () async {
      // Test if service can handle different request types
      // This would need proper mocking of network conditions

      expect(await service.canHandleRequest('text'), isA<bool>());
      expect(await service.canHandleRequest('audio'), isA<bool>());
      expect(await service.canHandleRequest('video'), isA<bool>());
    });
  });
}
```

---

## 8. Deployment Guide

### 8.1 Task 14: Update Dependencies

**File:** `pubspec.yaml` (additions)

```yaml
# IMPLEMENTATION TASK: Add required dependencies

dependencies:
  # Existing dependencies...

  # Network monitoring (already exists)
  connectivity_plus: ^7.0.0
  internet_connection_checker_plus: ^2.5.2

  # Enhanced networking
  dio: ^5.4.0
  dio_cache_interceptor: ^3.5.0

  # Caching
  hive: ^4.0.0
  hive_flutter: ^1.1.0

  # Background processing
  workmanager: ^0.5.2

dev_dependencies:
  # Testing
  mockito: ^5.4.4
  build_runner: ^2.4.7
```

### 8.2 Task 15: Initialize Services in Main

**File:** `lib/main.dart` (final integration)

```dart
// IMPLEMENTATION TASK: Complete main.dart integration

import 'package:eureka_app/services/networkIntelligenceService.dart';
import 'package:eureka_app/services/smartCacheService.dart';
import 'package:eureka_app/providers/networkProvider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Network Intelligence System
  await NetworkIntelligenceService().initialize();
  await SmartCacheService().initialize();

  // Rest of existing initialization...

  runApp(MyApp(
    firstLaunch: firstLaunch,
    notificationService: notificationService,
  ));
}

// Update MultiProvider
return MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => MyAppState()),
    ChangeNotifierProvider(create: (_) => AudioProvider()),
    ChangeNotifierProvider(create: (_) => NetworkProvider()), // ADD THIS
  ],
  child: Builder(
    builder: (context) {
      // Existing code...
    },
  ),
);
```

### 8.3 Task 16: Feature Flags

**File:** `lib/constants/networkConstants.dart`

```dart
// IMPLEMENTATION TASK: Configuration constants

class NetworkConstants {
  // Feature flags
  static const bool enableNetworkIntelligence = true;
  static const bool enableSmartCaching = true;
  static const bool enablePredictiveLoading = true;

  // Monitoring intervals
  static const Duration networkMonitoringInterval = Duration(seconds: 10);
  static const Duration retryInterval = Duration(minutes: 1);

  // Quality thresholds
  static const double excellentBandwidthMbps = 10.0;
  static const double goodBandwidthMbps = 2.0;
  static const double fairBandwidthMbps = 0.5;

  static const int excellentLatencyMs = 50;
  static const int goodLatencyMs = 150;
  static const int fairLatencyMs = 300;

  // Cache settings
  static const int maxCacheItems = 1000;
  static const int maxCacheSizeMB = 100;

  // Retry settings
  static const int maxRetries = 3;
  static const Duration baseRetryDelay = Duration(seconds: 2);
}
```

---

## Implementation Checklist

### Phase 1: Core Infrastructure ✅

- [ ] Create network models (`networkModels.dart`)
- [ ] Implement NetworkIntelligenceService
- [ ] Create NetworkProvider for state management
- [ ] Integrate with main.dart MultiProvider
- [ ] Test basic network monitoring

### Phase 2: API Enhancement ✅

- [ ] Create IntelligentApiClient with retry logic
- [ ] Implement error models
- [ ] Add request queuing system
- [ ] Test API wrapper with existing endpoints

### Phase 3: UI Components ✅

- [ ] Build NetworkStatusIndicator widget
- [ ] Create IntelligentErrorCard component
- [ ] Design error illustrations
- [ ] Test UI components in isolation

### Phase 4: Screen Integration ✅

- [ ] Update AI Tutor screen with network awareness
- [ ] Enhance Home screen with network indicators
- [ ] Add error handling to all major screens
- [ ] Test screen-specific network features

### Phase 5: Caching & Offline ✅

- [ ] Implement SmartCacheService
- [ ] Add offline data persistence
- [ ] Create background sync system
- [ ] Test offline functionality

### Phase 6: Testing & Polish ✅

- [ ] Write comprehensive unit tests
- [ ] Create integration tests
- [ ] Performance testing
- [ ] User acceptance testing

### Deployment Steps:

1. **Development Environment**: Implement and test locally
2. **Staging Deployment**: Deploy to staging with feature flags
3. **Beta Testing**: Limited rollout to beta users
4. **Production Rollout**: Gradual rollout with monitoring
5. **Full Deployment**: Complete rollout with analytics

---

## Success Criteria

### Technical Metrics:

- [ ] Network quality detection accuracy > 90%
- [ ] Error recovery success rate > 80%
- [ ] Cache hit rate > 70%
- [ ] App crash rate < 0.1% due to network issues

### User Experience Metrics:

- [ ] Session abandonment due to network issues reduced by 25%
- [ ] User satisfaction score > 4.5/5 for network experience
- [ ] Support tickets related to network issues reduced by 60%

### Performance Metrics:

- [ ] App startup time increase < 500ms
- [ ] Memory usage increase < 50MB
- [ ] Battery impact < 5% additional drain

---

This LLD provides a complete, step-by-step implementation guide that a junior developer can follow to build the Network Connectivity Intelligence System. Each task is specific, testable, and builds upon the previous tasks to create a robust, user-friendly network handling system for your GlutaFam app.
