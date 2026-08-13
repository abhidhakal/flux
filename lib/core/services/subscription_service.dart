import 'dart:async';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  // Product IDs
  static const String _kMonthlySubscriptionId = 'premium_monthly';
  static const String _kYearlySubscriptionId = 'premium_yearly';

  static const Set<String> _kProductIds = {
    _kMonthlySubscriptionId,
    _kYearlySubscriptionId,
  };

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
        price: '\$5.99',
        rawPrice: 5.99,
        currencyCode: 'USD',
      ),
      ProductDetails(
        id: _kYearlySubscriptionId,
        title: 'Yearly Premium',
        description: 'Unlock all features',
        price: '\$39.99',
        rawPrice: 39.99,
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
      try {
        final platform = Platform.isIOS ? 'ios' : 'android';
        final verificationData = purchaseDetails.verificationData;
        final callable = FirebaseFunctions.instanceFor(
          region: 'us-central1',
        ).httpsCallable('verifySubscriptionPurchase');

        final response = await callable.call({
          'platform': platform,
          'productId': purchaseDetails.productID,
          if (platform == 'android')
            'purchaseToken': verificationData.serverVerificationData,
          if (platform == 'ios') 'transactionId': purchaseDetails.purchaseID,
        });

        final data = response.data;
        if (data is Map && data['isPremium'] == true) {
          _isPremium = true;
          _purchaseController.add(true);
        }
      } catch (error) {
        debugPrint('Subscription verification failed: $error');
      }
    }
  }

  Future<void> _checkPremiumStatus() async {
    _isPremium = false; // Reset first

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _isPremium = false;
      return;
    }

    final entitlement = await FirebaseFirestore.instance
        .collection('entitlements')
        .doc(user.uid)
        .get();
    final data = entitlement.data();
    final expiresAt = data?['expiresAt'];
    if (data?['status'] == 'active' &&
        expiresAt is Timestamp &&
        expiresAt.toDate().isAfter(DateTime.now())) {
      _isPremium = true;
    }
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _purchaseController.close();
    _isInitialized = false;
  }
}
