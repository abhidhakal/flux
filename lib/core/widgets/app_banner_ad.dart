import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flux/core/services/ad_service.dart';
import 'package:flux/core/services/subscription_service.dart';

class AppBannerAd extends StatefulWidget {
  const AppBannerAd({super.key});

  @override
  State<AppBannerAd> createState() => _AppBannerAdState();
}

class _AppBannerAdState extends State<AppBannerAd> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  
  @override
  void initState() {
    super.initState();
    _loadAd();
    
    // Listen for premium purchase updates to hide ads dynamically
    SubscriptionService().purchaseStream.listen((_) {
      if (mounted) {
        setState(() {}); // Rebuild to check showAds condition
      }
    });
  }

  Future<void> _loadAd() async {
    if (!AdService().shouldShowAds) return;

    final AnchoredAdaptiveBannerAdSize? size = switch (Platform.isAndroid || Platform.isIOS) {
       true => await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
        MediaQuery.of(context).size.width.truncate(),
      ),
      _ => null,
    };

    if (size == null) return;

    _bannerAd = BannerAd(
      adUnitId: AdService().bannerAdUnitId,
      request: const AdRequest(),
      size: size,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AdService().shouldShowAds || !_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
