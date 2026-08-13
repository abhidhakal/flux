import 'dart:async';

import 'package:flutter/foundation.dart';

import 'network_service.dart';

enum SyncStatus { synced, syncing, offline }

/// Publishes the small amount of sync state the UI needs to explain
/// offline-first writes to the user.
class SyncStatusService extends ChangeNotifier {
  static final SyncStatusService _instance = SyncStatusService._internal();

  factory SyncStatusService() => _instance;

  SyncStatusService._internal() {
    _isOnline = NetworkService().isConnected;
    _connectionSubscription =
        NetworkService().connectionStream.listen((online) {
      _isOnline = online;
      notifyListeners();
    });
  }

  late bool _isOnline;
  int _pendingWrites = 0;
  late final StreamSubscription<bool> _connectionSubscription;

  bool get isOnline => _isOnline;
  int get pendingWrites => _pendingWrites;

  SyncStatus get status {
    if (!_isOnline) return SyncStatus.offline;
    if (_pendingWrites > 0) return SyncStatus.syncing;
    return SyncStatus.synced;
  }

  Future<T> track<T>(Future<T> Function() operation) async {
    _pendingWrites++;
    notifyListeners();
    try {
      return await operation();
    } finally {
      _pendingWrites--;
      if (_pendingWrites < 0) _pendingWrites = 0;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _connectionSubscription.cancel();
    super.dispose();
  }
}
