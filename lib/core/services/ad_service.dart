import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flux/core/services/subscription_service.dart';
import 'feature_flag_service.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  bool _isInitialized = false;
  bool _isInitializing = false;

  /// Lazily initialize the Mobile Ads SDK.
  /// This is called automatically when ads are first needed.
  Future<void> ensureInitialized() async {
    if (_isInitialized) return;
    if (_isInitializing) {
      // Wait for ongoing initialization to complete
      while (_isInitializing) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      return;
    }
    
    _isInitializing = true;
    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      debugPrint('✅ AdService: Mobile Ads SDK initialized successfully');
    } catch (e) {
      debugPrint('❌ AdService: Failed to initialize Mobile Ads SDK: $e');
    } finally {
      _isInitializing = false;
    }
  }

  /// Legacy initialize method - now calls ensureInitialized
  Future<void> initialize() async {
    await ensureInitialized();
  }

  bool get isInitialized => _isInitialized;

  bool get shouldShowAds {
    if (FeatureFlagService.forceShowAds) {
      return true;
    }

    if (SubscriptionService().isPremium) {
      return false;
    }
    return true;
  }

  String get bannerAdUnitId {
    if (kDebugMode) {
      if (Platform.isAndroid) {
        return 'ca-app-pub-3940256099942544/6300978111';
      } else if (Platform.isIOS) {
        return 'ca-app-pub-3940256099942544/2934735716';
      }
    }
    // Replace these with production IDs when releasing
    if (Platform.isAndroid) {
      return 'ca-app-pub-8194895103164797/4213340343';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716'; // Placeholder
    }
    throw UnsupportedError('Unsupported platform');
  }
}
