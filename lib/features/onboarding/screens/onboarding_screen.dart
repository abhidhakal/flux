import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/constants/app_theme.dart';
import '../../../core/services/currency_service.dart';
import '../../../core/services/onboarding_service.dart';

class OnboardingScreen extends StatefulWidget {
  final String userId;
  final VoidCallback onCompleted;

  const OnboardingScreen({
    super.key,
    required this.userId,
    required this.onCompleted,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final CurrencyService _currencyService = CurrencyService();
  int _page = 0;
  String _selectedCurrency = 'USD';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedCurrency = _currencyService.currency;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (_saving) return;
    setState(() => _saving = true);
    await _currencyService.setCurrency(_selectedCurrency);
    await OnboardingService().markComplete(widget.userId);
    if (!mounted) return;
    widget.onCompleted();
  }

  void _next() {
    if (_page == 2) {
      _finish();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: AppTheme.pageBackground(context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Set up Flux',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          )),
                  TextButton(
                    onPressed: _saving ? null : _finish,
                    child: const Text('Skip for now'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: List.generate(
                  3,
                  (index) => Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 5,
                      margin: EdgeInsets.only(right: index == 2 ? 0 : 6),
                      decoration: BoxDecoration(
                        color: index <= _page
                            ? colorScheme.primary
                            : colorScheme.outline.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (page) => setState(() => _page = page),
                  children: [
                    _PageContent(
                      icon: LucideIcons.sparkles,
                      title: 'Make your money clearer',
                      body:
                          'Flux turns everyday transactions into a simple picture of where your money is going and what to do next.',
                    ),
                    _CurrencyPage(
                      selectedCurrency: _selectedCurrency,
                      currencies: _currencyService.getAvailableCurrencies(),
                      onChanged: (value) =>
                          setState(() => _selectedCurrency = value),
                    ),
                    _PageContent(
                      icon: LucideIcons.compass,
                      title: 'Start with one small step',
                      body:
                          'Add a transaction, create a budget, or set a goal. Flux will build useful insights as your picture grows.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _next,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_page == 2 ? 'Start using Flux' : 'Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageContent extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _PageContent({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 52, color: colorScheme.primary),
          ),
          const SizedBox(height: 30),
          Text(title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  )),
          const SizedBox(height: 14),
          Text(body,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: 1.5,
                    color: colorScheme.onSurfaceVariant,
                  )),
        ],
      ),
    );
  }
}

class _CurrencyPage extends StatelessWidget {
  final String selectedCurrency;
  final List<Map<String, String>> currencies;
  final ValueChanged<String> onChanged;

  const _CurrencyPage({
    required this.selectedCurrency,
    required this.currencies,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.coins, size: 58, color: AppColors.primary),
          const SizedBox(height: 24),
          Text('Choose your currency',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  )),
          const SizedBox(height: 10),
          Text(
            'You can change this later in your profile settings.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          DropdownButtonFormField<String>(
            initialValue: selectedCurrency,
            isExpanded: true,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            items: currencies
                .map((currency) => DropdownMenuItem<String>(
                      value: currency['code'],
                      child: Text(
                        '${currency['code']} · ${currency['symbol']} · ${currency['country']}',
                      ),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) onChanged(value);
            },
          ),
        ],
      ),
    );
  }
}
