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
      setCurrency(savedCurrency);
    }
  }

  // Getters
  String get currency => _currency;
  String get symbol => _symbol;
  String get country => _country;

  // Set currency
  Future<void> setCurrency(String currencyCode) async {
    if (_currencyConfig.containsKey(currencyCode)) {
      _currency = currencyCode;
      _symbol = _currencyConfig[currencyCode]!['symbol']!;
      _country = _currencyConfig[currencyCode]!['country']!;

      // Save to SharedPreferences
      if (_prefs != null) {
        await _prefs!.setString('selected_currency', currencyCode);
      }
    }
  }

  // Format amount with currency symbol
  String formatAmount(double amount) {
    // Handle different decimal places for different currencies
    int decimalPlaces = 2;
    if (_currency == 'JPY' || _currency == 'KRW') {
      decimalPlaces = 0; // These currencies typically don't use decimal places
    }

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

  // Format amount without symbol (for input fields)
  String formatAmountWithoutSymbol(double amount) {
    int decimalPlaces = 2;
    if (_currency == 'JPY' || _currency == 'KRW') {
      decimalPlaces = 0;
    }
    return amount.toStringAsFixed(decimalPlaces);
  }

  // Parse amount from string
  double parseAmount(String amountString) {
    // Remove currency symbol and commas
    String cleanAmount =
        amountString.replaceAll(_symbol, '').replaceAll(',', '').trim();

    return double.tryParse(cleanAmount) ?? 0.0;
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

  // Get currency info by code
  Map<String, String>? getCurrencyInfo(String currencyCode) {
    return _currencyConfig[currencyCode];
  }

  // Check if currency code is valid
  bool isValidCurrency(String currencyCode) {
    return _currencyConfig.containsKey(currencyCode);
  }
}
