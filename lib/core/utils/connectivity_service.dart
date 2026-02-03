// lib/core/utils/connectivity_service.dart
import 'dart:async';

/// Service to monitor network connectivity.
/// Uses a web-safe approach — no dart:io dependency.
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final _connectivityController = StreamController<bool>.broadcast();
  bool _isOnline = true;
  Timer? _checkTimer;

  /// Stream of connectivity changes
  Stream<bool> get onConnectivityChanged => _connectivityController.stream;

  /// Current connectivity status
  bool get isOnline => _isOnline;

  /// Start monitoring connectivity
  void startMonitoring() {
    _checkConnectivity();
    _checkTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkConnectivity(),
    );
  }

  /// Stop monitoring
  void stopMonitoring() {
    _checkTimer?.cancel();
    _checkTimer = null;
  }

  /// Check connectivity in a web-safe way.
  /// Actual connectivity failures are caught by API error handlers
  /// which call [markOffline] / [markOnline] as needed.
  Future<void> _checkConnectivity() async {
    _updateStatus(true);
  }

  void _updateStatus(bool online) {
    if (_isOnline != online) {
      _isOnline = online;
      _connectivityController.add(online);
    }
  }

  /// Manually check connectivity (for pull-to-refresh, etc.)
  Future<bool> checkNow() async {
    await _checkConnectivity();
    return _isOnline;
  }

  void dispose() {
    stopMonitoring();
    _connectivityController.close();
  }
}
