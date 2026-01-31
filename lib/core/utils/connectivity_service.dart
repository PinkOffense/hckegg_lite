// lib/core/utils/connectivity_service.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Service to monitor network connectivity
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

  /// Check connectivity by making a simple request
  Future<void> _checkConnectivity() async {
    if (kIsWeb) {
      // On web, assume online (browser handles offline)
      _updateStatus(true);
      return;
    }

    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      _updateStatus(result.isNotEmpty && result[0].rawAddress.isNotEmpty);
    } on SocketException catch (_) {
      _updateStatus(false);
    } on TimeoutException catch (_) {
      _updateStatus(false);
    } catch (_) {
      _updateStatus(false);
    }
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
