import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/constants/app_theme.dart';
import '../../../core/services/currency_service.dart';
import '../../../core/services/onboarding_service.dart';
import '../../auth/widgets/flux_preview.dart';

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

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  static const _pageCount = 3;

  final PageController _pageController = PageController();
  final CurrencyService _currencyService = CurrencyService();
  late final AnimationController _heroController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();
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
    _heroController.dispose();
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

  void _goTo(int page) => _pageController.animateToPage(
        page,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );

  void _next() => _page == _pageCount - 1 ? _finish() : _goTo(_page + 1);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isLast = _page == _pageCount - 1;

    return Scaffold(
      backgroundColor: AppTheme.pageBackground(context),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: SizedBox(
                height: 48,
                child: Row(
                  children: [
                    AnimatedOpacity(
                      opacity: _page > 0 ? 1 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: IconButton(
                        onPressed: _page > 0 ? () => _goTo(_page - 1) : null,
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _pageCount,
                          (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOutCubic,
                            width: i == _page ? 24 : 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              color: i <= _page
                                  ? AppColors.primary
                                  : cs.outline.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _saving ? null : _finish,
                      child: Text('Skip',
                          style: TextStyle(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _page = page),
                children: [
                  _Page(
                    eyebrow: 'Welcome to Flux',
                    title: 'Your money,\nfinally clear.',
                    body:
                        'Every transaction rolls up into one simple picture: what came in, what went out, and what is left.',
                    top: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: FluxPreview(t: _heroController),
                    ),
                  ),
                  _CurrencyPage(
                    selected: _selectedCurrency,
                    currencies: _currencyService.getAvailableCurrencies(),
                    onChanged: (v) => setState(() => _selectedCurrency = v),
                  ),
                  const _Page(
                    eyebrow: 'You are all set',
                    title: 'Start with\none small step.',
                    body:
                        'Flux gets smarter as your picture grows. Any of these is a great first move:',
                    bottom: Column(
                      children: [
                        _StepRow(
                          icon: LucideIcons.receipt,
                          color: AppColors.primary,
                          title: 'Log a transaction',
                          subtitle: 'Tap + on the home screen',
                        ),
                        _StepRow(
                          icon: LucideIcons.chartPie,
                          color: AppColors.success,
                          title: 'Create a budget',
                          subtitle: 'Cap a category like groceries',
                        ),
                        _StepRow(
                          icon: LucideIcons.target,
                          color: AppColors.warning,
                          title: 'Set a savings goal',
                          subtitle: 'A trip, a fund, anything',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: ElevatedButton(
                onPressed: _saving ? null : _next,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      AppColors.primary.withValues(alpha: 0.5),
                  minimumSize: const Size.fromHeight(56),
                  shape: const StadiumBorder(),
                  elevation: 0,
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white),
                      )
                    : Text(isLast ? 'Start using Flux' : 'Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Page extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String body;
  final Widget? top;
  final Widget? bottom;

  const _Page({
    required this.eyebrow,
    required this.title,
    required this.body,
    this.top,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (top != null) ...[top!, const SizedBox(height: 40)],
          _Heading(eyebrow: eyebrow, title: title),
          const SizedBox(height: 12),
          Text(body,
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.5,
                color: theme.colorScheme.onSurfaceVariant,
              )),
          if (bottom != null) ...[const SizedBox(height: 24), bottom!],
        ],
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  final String eyebrow;
  final String title;
  const _Heading({required this.eyebrow, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(eyebrow.toUpperCase(),
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            )),
        const SizedBox(height: 10),
        Text(title,
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
              height: 1.08,
            )),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _StepRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style:
                        TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrencyPage extends StatefulWidget {
  final String selected;
  final List<Map<String, String>> currencies;
  final ValueChanged<String> onChanged;

  const _CurrencyPage({
    required this.selected,
    required this.currencies,
    required this.onChanged,
  });

  @override
  State<_CurrencyPage> createState() => _CurrencyPageState();
}

class _CurrencyPageState extends State<_CurrencyPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final q = _query.toLowerCase();
    final list = widget.currencies
        .where((c) =>
            c['code']!.toLowerCase().contains(q) ||
            c['country']!.toLowerCase().contains(q))
        .toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Heading(
              eyebrow: 'Step 2 of 3', title: 'Pick your\ncurrency.'),
          const SizedBox(height: 8),
          Text('You can change this anytime in settings.',
              style: theme.textTheme.bodyLarge
                  ?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 20),
          TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Search currency or country',
              prefixIcon: const Icon(LucideIcons.search, size: 20),
              filled: true,
              fillColor: cs.surface,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 8),
              itemCount: list.length,
              itemBuilder: (context, i) {
                final c = list[i];
                final selected = c['code'] == widget.selected;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: selected
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : cs.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color:
                            selected ? AppColors.primary : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => widget.onChanged(c['code']!),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerHighest
                                    .withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(c['symbol']!,
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800)),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(c['code']!,
                                      style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800)),
                                  Text(c['country']!,
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: cs.onSurfaceVariant)),
                                ],
                              ),
                            ),
                            if (selected)
                              const Icon(Icons.check_circle_rounded,
                                  color: AppColors.primary),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
