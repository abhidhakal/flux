import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  
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

  Future<void> initialize() async {
    _isAvailable = await _inAppPurchase.isAvailable();
    
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
        price: '\$4.99',
        rawPrice: 4.99,
        currencyCode: 'USD',
      ),
      ProductDetails(
        id: _kYearlySubscriptionId,
        title: 'Yearly Premium',
        description: 'Unlock all features',
        price: '\$49.99',
        rawPrice: 49.99,
        currencyCode: 'USD',
      ),
      ProductDetails(
        id: _kLifetimeSubscriptionId,
        title: 'Lifetime Access',
        description: 'Pay once, keep forever',
        price: '\$149.99',
        rawPrice: 149.99,
        currencyCode: 'USD',
      ),
    ];
  }

  Future<void> buyProduct(ProductDetails productDetails) async {
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);
    
    if (_kProductIds.contains(productDetails.id)) {
      if (_isAvailable && !_products.any((p) => p == productDetails && _getMockProducts().contains(p))) {
         await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      } else {
        // Mock purchase for testing
        await Future.delayed(const Duration(seconds: 1));
        await _setPremiumStatusForProduct(productDetails.id);
        _purchaseController.add(true);
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
        expiryDate = DateTime.now().add(const Duration(days: 365 * 100)); // 100 years
        break;
      default:
        expiryDate = DateTime.now().add(const Duration(days: 30));
    }
    
    await prefs.setString(_kPremiumExpiryKey, expiryDate.toIso8601String());
    
    // Clear legacy key
    if (prefs.containsKey('is_premium')) {
      await prefs.remove('is_premium');
    }
    
    _isPremium = true;
  }

  Future<void> _checkPremiumStatus() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check for legacy key first and clear it if it exists
    if (prefs.containsKey('is_premium')) {
       await prefs.remove('is_premium');
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
