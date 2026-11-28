import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyService {
  static final CurrencyService _instance = CurrencyService._internal();
  factory CurrencyService() => _instance;
  CurrencyService._internal();

  String _currency = 'USD';
  String _symbol = '\$';
  String _country = 'United States';
  SharedPreferences? _prefs;

  // Currency configurations
  final Map<String, Map<String, String>> _currencyConfig = {
    'USD': {'symbol': '\$', 'country': 'United States', 'code': 'USD'},
    'GBP': {'symbol': '£', 'country': 'United Kingdom', 'code': 'GBP'},
    'EUR': {'symbol': '€', 'country': 'European Union', 'code': 'EUR'},
    'JPY': {'symbol': '¥', 'country': 'Japan', 'code': 'JPY'},
    'CAD': {'symbol': 'C\$', 'country': 'Canada', 'code': 'CAD'},
    'AUD': {'symbol': 'A\$', 'country': 'Australia', 'code': 'AUD'},
    'INR': {'symbol': '₹', 'country': 'India', 'code': 'INR'},
    'CNY': {'symbol': '¥', 'country': 'China', 'code': 'CNY'},
    'BRL': {'symbol': 'R\$', 'country': 'Brazil', 'code': 'BRL'},
    'KRW': {'symbol': '₩', 'country': 'South Korea', 'code': 'KRW'},
    'NPR': {'symbol': 'Rs.', 'country': 'Nepal', 'code': 'NPR'},
    'MXN': {'symbol': '\$', 'country': 'Mexico', 'code': 'MXN'},
    'SGD': {'symbol': 'S\$', 'country': 'Singapore', 'code': 'SGD'},
    'CHF': {'symbol': 'CHF', 'country': 'Switzerland', 'code': 'CHF'},
    'NZD': {'symbol': 'NZ\$', 'country': 'New Zealand', 'code': 'NZD'},
  };

  // Initialize the service and load saved currency
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadSavedCurrency();
  }

  // Ensure service is initialized (for synchronous access)
  Future<void> ensureInitialized() async {
    if (_prefs == null) {
      await initialize();
    }
  }

  // Load saved currency from SharedPreferences
  Future<void> _loadSavedCurrency() async {
    if (_prefs != null) {
      final savedCurrency = _prefs!.getString('selected_currency') ?? 'USD';
      await setCurrency(savedCurrency, syncToAccount: false);
    }
  }

  // Getters
  String get currency => _currency;
  String get symbol => _symbol;
  String get country => _country;
  int get decimalPlaces => _currency == 'JPY' || _currency == 'KRW' ? 0 : 2;

  // Set currency. Saved on the device and, when signed in, on the user's
  // account (users/{uid}.preferences.currency) so it survives reinstalls and
  // new devices.
  Future<void> setCurrency(String currencyCode, {bool syncToAccount = true}) async {
    if (!_currencyConfig.containsKey(currencyCode)) return;
    _currency = currencyCode;
    _symbol = _currencyConfig[currencyCode]!['symbol']!;
    _country = _currencyConfig[currencyCode]!['country']!;

    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString('selected_currency', currencyCode);

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (syncToAccount && uid != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .update({'preferences.currency': currencyCode});
      } catch (e) {
        debugPrint('Could not save currency to account: $e');
      }
    }
  }

  /// Called on sign-in with the account's preferences. The account wins;
  /// if the account has none yet, the device's choice is uploaded once.
  Future<void> applyAccountCurrency(Map<String, dynamic> preferences) async {
    await ensureInitialized();
    final saved = preferences['currency'] as String?;
    if (saved != null && _currencyConfig.containsKey(saved)) {
      if (saved != _currency) await setCurrency(saved, syncToAccount: false);
    } else if (_prefs?.getString('selected_currency') != null) {
      await setCurrency(_currency);
    }
  }

  // Format amount with currency symbol
  String formatAmount(double amount) {
    // Handle different decimal places for different currencies
    final decimalPlaces = this.decimalPlaces;

    final isNegative = amount < 0;
    final normalizedAmount = isNegative ? amount.abs() : amount;
    String formattedAmount = normalizedAmount.toStringAsFixed(decimalPlaces);

    // Add thousand separators
    List<String> parts = formattedAmount.split('.');
    String integerPart = parts[0];
    String decimalPart = parts.length > 1 ? parts[1] : '';

    // Add commas for thousands
    String formattedInteger = _addThousandSeparators(integerPart);

    final signPrefix = isNegative ? '-' : '';

    if (decimalPart.isNotEmpty) {
      return '$signPrefix$_symbol$formattedInteger.$decimalPart';
    } else {
      return '$signPrefix$_symbol$formattedInteger';
    }
  }

  // Format amount, dropping a trailing ".00" for a more compact display
  // (chart labels/axes). Anchored to the end so it never strips a mid-string
  // ".00" from a larger formatted number.
  String formatAmountCompact(double amount) {
    return formatAmount(amount).replaceAll(RegExp(r'\.00$'), '');
  }

  // Add thousand separators
  String _addThousandSeparators(String number) {
    if (number.length <= 3) return number;

    String result = '';
    int count = 0;

    for (int i = number.length - 1; i >= 0; i--) {
      if (count == 3) {
        result = ',$result';
        count = 0;
      }
      result = '${number[i]}$result';
      count++;
    }

    return result;
  }

  // Get all available currencies
  List<Map<String, String>> getAvailableCurrencies() {
    return _currencyConfig.entries.map((entry) {
      return {
        'code': entry.key,
        'symbol': entry.value['symbol']!,
        'country': entry.value['country']!,
      };
    }).toList();
  }
}
