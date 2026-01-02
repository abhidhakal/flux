import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flux/core/services/subscription_service.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  bool get shouldShowAds {
    // If user is premium, don't show ads
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
      return 'ca-app-pub-3940256099942544/6300978111'; // Placeholder
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716'; // Placeholder
    }
    throw UnsupportedError('Unsupported platform');
  }
}
