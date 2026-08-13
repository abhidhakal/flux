import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'feature_flag_service.dart';

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  // Product IDs
  static const String _kMonthlySubscriptionId = 'premium_monthly';
  static const String _kYearlySubscriptionId = 'premium_yearly';
  static const String _kLifetimeSubscriptionId = 'premium_lifetime';

  static const Set<String> _kProductIds = {
    _kMonthlySubscriptionId,
    _kYearlySubscriptionId,
    _kLifetimeSubscriptionId,
  };

  static const String _kPremiumExpiryKey = 'premium_expiry';

  bool _isAvailable = false;
  List<ProductDetails> _products = [];
  bool _isPremium = false;

  bool get isPremium => _isPremium;
  List<ProductDetails> get products => _products;

  final _purchaseController = StreamController<bool>.broadcast();
  Stream<bool> get purchaseStream => _purchaseController.stream;

  bool _isInitialized = false;
  Future<void>? _initialization;

  Future<void> initialize() async {
    if (_isInitialized) {
      await _checkPremiumStatus();
      return;
    }

    if (_initialization != null) {
      await _initialization;
      await _checkPremiumStatus();
      return;
    }

    _initialization = _initializeInternal();
    try {
      await _initialization;
    } finally {
      _initialization = null;
    }
  }

  Future<void> _initializeInternal() async {
    _isAvailable = await _inAppPurchase.isAvailable();

    final Stream<List<PurchaseDetails>> purchaseUpdated =
        _inAppPurchase.purchaseStream;
    _subscription ??= purchaseUpdated.listen(
      _listenToPurchaseUpdated,
      onDone: () {
        _subscription?.cancel();
        _subscription = null;
      },
      onError: (error) {
        // handle error here.
      },
    );

    await _loadProducts();
    await _checkPremiumStatus();
    _isInitialized = true;
  }

  Future<void> _loadProducts() async {
    if (!_isAvailable) {
      _products = _getMockProducts();
      return;
    }

    final ProductDetailsResponse response =
        await _inAppPurchase.queryProductDetails(_kProductIds);

    if (response.notFoundIDs.isNotEmpty) {
      // Handle the error.
    }

    _products = response.productDetails;

    // Fallback for testing/simulator if store returns nothing
    if (_products.isEmpty) {
      _products = _getMockProducts();
    }
  }

  List<ProductDetails> _getMockProducts() {
    return [
      ProductDetails(
        id: _kMonthlySubscriptionId,
        title: 'Monthly Premium',
        description: 'Unlock all features',
        price: '\$1.49',
        rawPrice: 1.49,
        currencyCode: 'USD',
      ),
      ProductDetails(
        id: _kYearlySubscriptionId,
        title: 'Yearly Premium',
        description: 'Unlock all features',
        price: '\$11.99',
        rawPrice: 11.99,
        currencyCode: 'USD',
      ),
      ProductDetails(
        id: _kLifetimeSubscriptionId,
        title: 'Lifetime Access',
        description: 'Pay once, keep forever',
        price: '\$34.99',
        rawPrice: 34.99,
        currencyCode: 'USD',
      ),
    ];
  }

  Future<void> buyProduct(ProductDetails productDetails) async {
    final PurchaseParam purchaseParam =
        PurchaseParam(productDetails: productDetails);

    if (_kProductIds.contains(productDetails.id)) {
      if (_isAvailable) {
        try {
          // Attempt a real store purchase. This will throw errors in debug
          // if products are not configured in Play/App Store consoles.
          await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
        } catch (e) {
          debugPrint('Purchase attempt failed: $e');
          rethrow; // Propagate the error so the UI can show the failure
        }
      } else {
        throw Exception(
            'The store is currently unavailable. Please try again later.');
      }
    }
  }

  Future<void> restorePurchases() async {
    if (_isAvailable) {
      await _inAppPurchase.restorePurchases();
    }
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
    if (_kProductIds.contains(purchaseDetails.productID)) {
      await _setPremiumStatusForProduct(purchaseDetails.productID);
      _purchaseController.add(true);
    }
  }

  Future<void> _setPremiumStatusForProduct(String productId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    DateTime expiryDate;

    switch (productId) {
      case _kMonthlySubscriptionId:
        expiryDate = DateTime.now().add(const Duration(days: 30));
        break;
      case _kYearlySubscriptionId:
        expiryDate = DateTime.now().add(const Duration(days: 365));
        break;
      case _kLifetimeSubscriptionId:
        expiryDate =
            DateTime.now().add(const Duration(days: 365 * 100)); // 100 years
        break;
      default:
        expiryDate = DateTime.now().add(const Duration(days: 30));
    }

    await prefs.setString(
        _getExpiryKey(user.uid), expiryDate.toIso8601String());

    // Clear legacy key
    if (prefs.containsKey('is_premium')) {
      await prefs.remove('is_premium');
    }

    _isPremium = true;
  }

  static const List<String> _developerEmails = [
    'dhakalabhinav4@gmail.com',
    'subhishrestha08@gmail.com',
  ];

  static String _getExpiryKey(String uid) => '${_kPremiumExpiryKey}_$uid';

  Future<void> _checkPremiumStatus() async {
    // During development, disabling subscriptions grants access to all
    // premium features without involving the store.
    if (!FeatureFlagService.isSubscriptionEnabled) {
      _isPremium = true;
      return;
    }

    _isPremium = false; // Reset first

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _isPremium = false;
      return;
    }

    // Developer Bypass
    if (user.email != null && _developerEmails.contains(user.email)) {
      _isPremium = true;
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final userExpiryKey = _getExpiryKey(user.uid);

    // Check for legacy device-wide key first and clear it
    if (prefs.containsKey('is_premium')) {
      await prefs.remove('is_premium');
    }
    if (prefs.containsKey(_kPremiumExpiryKey)) {
      // This was the old global expiry key, we should probably remove it to be safe
      // but we don't want to accidentally remove a legit purchase that hasn't migrated.
      // However, since this is "mocking" mostly and real IAP should be restored, it's safer to use user-specific keys.
    }

    final expiryString = prefs.getString(userExpiryKey);
    if (expiryString != null) {
      final expiryDate = DateTime.tryParse(expiryString);
      if (expiryDate != null && expiryDate.isAfter(DateTime.now())) {
        _isPremium = true;
      } else {
        // Expired
        await prefs.remove(userExpiryKey);
      }
    }
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _purchaseController.close();
    _isInitialized = false;
  }
}
