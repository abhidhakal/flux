import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  
  // Product ID for the monthly subscription
  static const String _kMonthlySubscriptionId = 'premium_monthly';
  static const Set<String> _kProductIds = {_kMonthlySubscriptionId};
  static const String _kPremiumExpiryKey = 'premium_expiry';

  bool _isAvailable = false;
  List<ProductDetails> _products = [];
  bool _isPremium = false;

  bool get isPremium => _isPremium;
  List<ProductDetails> get products => _products;

  final _purchaseController = StreamController<bool>.broadcast();
  Stream<bool> get purchaseStream => _purchaseController.stream;

  Future<void> initialize() async {
    _isAvailable = await _inAppPurchase.isAvailable();
    if (!_isAvailable) {
      return;
    }

    final Stream<List<PurchaseDetails>> purchaseUpdated =
        _inAppPurchase.purchaseStream;
    _subscription = purchaseUpdated.listen(
      _listenToPurchaseUpdated,
      onDone: () {
        _subscription.cancel();
      },
      onError: (error) {
        // handle error here.
      },
    );

    await _loadProducts();
    await _checkPremiumStatus();
  }

  Future<void> _loadProducts() async {
    final ProductDetailsResponse response =
        await _inAppPurchase.queryProductDetails(_kProductIds);
    if (response.notFoundIDs.isNotEmpty) {
      // Handle the error.
    }
    _products = response.productDetails;
  }

  Future<void> buyProduct(ProductDetails productDetails) async {
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);
    
    if (_kProductIds.contains(productDetails.id)) {
      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    }
  }

  Future<void> restorePurchases() async {
    await _inAppPurchase.restorePurchases();
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // Show pending UI if needed
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          // Handle error
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          _deliverProduct(purchaseDetails);
        }
        
        if (purchaseDetails.pendingCompletePurchase) {
          _inAppPurchase.completePurchase(purchaseDetails);
        }
      }
    }
  }

  Future<void> _deliverProduct(PurchaseDetails purchaseDetails) async {
    if (purchaseDetails.productID == _kMonthlySubscriptionId) {
      await _setPremiumStatus(purchaseDetails);
      _purchaseController.add(true);
    }
  }

  Future<void> _setPremiumStatus(PurchaseDetails purchaseDetails) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Calculate expiry (default 30 days from purchase)
    // In a real app, this should come from detailed receipt validation
    final expiryDate = DateTime.now().add(const Duration(days: 30));
    
    await prefs.setString(_kPremiumExpiryKey, expiryDate.toIso8601String());
    
    // Clear legacy key to avoid conflicts
    await prefs.remove('is_premium');
    
    _isPremium = true;
  }

  Future<void> _checkPremiumStatus() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check for legacy key first and clear it if it exists
    if (prefs.containsKey('is_premium')) {
       await prefs.remove('is_premium');
       // Don't carry over legacy status as it might be invalid/stale
    }

    final expiryString = prefs.getString(_kPremiumExpiryKey);
    if (expiryString != null) {
      final expiryDate = DateTime.tryParse(expiryString);
      if (expiryDate != null && expiryDate.isAfter(DateTime.now())) {
        _isPremium = true;
      } else {
        // Expired
        _isPremium = false;
        await prefs.remove(_kPremiumExpiryKey);
      }
    } else {
      _isPremium = false;
    }
  }
  
  void dispose() {
    _subscription.cancel();
    _purchaseController.close();
  }
}
