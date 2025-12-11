import 'dart:async';
import 'dart:io';
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
      await _setPremiumStatus(true);
      _purchaseController.add(true);
    }
  }

  Future<void> _setPremiumStatus(bool status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_premium', status);
    _isPremium = status;
  }

  Future<void> _checkPremiumStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _isPremium = prefs.getBool('is_premium') ?? false;
    
    // In a real app, you might want to verify the receipt with your backend here
    // to ensure the subscription is still valid.
    // For this implementation, we rely on local storage and restore purchases.
  }
  
  void dispose() {
    _subscription.cancel();
    _purchaseController.close();
  }
}
