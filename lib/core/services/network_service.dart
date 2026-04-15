import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkService {
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  NetworkService._internal();

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectionController = StreamController<bool>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  // Stream to listen to connection changes
  Stream<bool> get connectionStream => _connectionController.stream;

  // Current connection status
  bool _isOnline = true;
  bool get isOnline => _isOnline;
  bool _isInitialized = false;

  // Initialize the network service
  Future<void> initialize() async {
    if (_isInitialized) {
      await _checkConnectivity();
      return;
    }

    // Check initial connectivity
    await _checkConnectivity();

    // Listen to connectivity changes (new API: List<ConnectivityResult>)
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.isNotEmpty) {
        _updateConnectionStatus(results.first);
      } else {
        _updateConnectionStatus(ConnectivityResult.none);
      }
    });
    _isInitialized = true;
  }

  // Check current connectivity status
  Future<void> _checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity(); // returns List<ConnectivityResult>
      if (results.isNotEmpty) {
        _updateConnectionStatus(results.first);
      } else {
        _updateConnectionStatus(ConnectivityResult.none);
      }
    } catch (e) {
      debugPrint('❌ NETWORK SERVICE: Error checking connectivity: $e');
      _isOnline = false;
      _connectionController.add(false);
    }
  }

  // Update connection status based on connectivity result
  void _updateConnectionStatus(ConnectivityResult result) {
    final wasOnline = _isOnline;
    _isOnline = result != ConnectivityResult.none;

    // Only emit if status changed
    if (wasOnline != _isOnline) {
      _connectionController.add(_isOnline);
      debugPrint('🌐 NETWORK SERVICE: Connection status changed - ${_isOnline ? "Online" : "Offline"}');
    }
  }

  // Check if device is online (synchronous)
  bool get isConnected => _isOnline;

  // Check if device is online (asynchronous)
  Future<bool> isOnlineAsync() async {
    try {
      final results = await _connectivity.checkConnectivity(); // List<ConnectivityResult>
      return results.any((r) => r != ConnectivityResult.none);
    } catch (e) {
      debugPrint('❌ NETWORK SERVICE: Error checking online status: $e');
      return false;
    }
  }

  // Get detailed connectivity info (new API returns a list)
  Future<List<ConnectivityResult>> getConnectivityResult() async {
    try {
      return await _connectivity.checkConnectivity();
    } catch (e) {
      debugPrint('❌ NETWORK SERVICE: Error getting connectivity result: $e');
      return [ConnectivityResult.none];
    }
  }

  // Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectionController.close();
    _isInitialized = false;
  }
}
