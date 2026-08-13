import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/models/transaction_model.dart';
import '../../../core/models/budget_model.dart';
import '../../../core/services/currency_service.dart';
import '../../../core/services/transaction_intelligence_service.dart';
import '../../auth/auth_bloc.dart';
import '../../transaction/transaction_bloc.dart';
import '../../transaction/screens/edit_transaction_screen.dart';
import '../../transaction/screens/add_transaction_screen.dart';
import '../../transaction/screens/recurring_transactions_screen.dart';
import '../../budget/budget_bloc.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/page_transitions.dart';
import '../../../shared/widgets/skeleton_components.dart';
import 'transaction_tile.dart';
import '../../../core/utils/date_range_filter.dart';
import '../../../shared/widgets/app_bottom_sheet.dart';
import '../../../shared/widgets/empty_state_view.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

// ─── Filter enums ────────────────────────────────────────────────────────────

enum _TypeFilter { all, expenses, income }

// ─── Screen ──────────────────────────────────────────────────────────────────

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Selection mode
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  // Filters
  TimelineFilter _timelineFilter = TimelineFilter.lastMonth;
  _TypeFilter _typeFilter = _TypeFilter.all;
  String? _selectedBudgetId; // null = all budgets
  DateTimeRange? _customRange;
  String _searchQuery = '';
  final TransactionIntelligenceService _intelligence =
      TransactionIntelligenceService();

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    final user = context.read<AuthBloc>().state;
    if (user is AuthAuthenticated) {
      context.read<TransactionBloc>().add(LoadTransactions(user.user.id));
      context.read<BudgetBloc>().add(LoadBudgets(user.user.id));
      await Future.delayed(const Duration(milliseconds: 600));
    }
  }

  // ─── Date range helper ────────────────────────────────────────────────────

  DateTimeRange _getActiveRange() =>
      activeRangeFor(_timelineFilter, customRange: _customRange);

  Future<void> _pickCustomRange() async {
    final picked = await pickCustomRange(context, _customRange);
    if (picked != null) {
      setState(() {
        _customRange = picked;
        _timelineFilter = TimelineFilter.custom;
      });
    }
  }

  // ─── Filtering logic ──────────────────────────────────────────────────────

  List<Transaction> _applyFilters(List<Transaction> transactions) {
    final range = _getActiveRange();
    final result = <Transaction>[];
    for (final transaction in transactions) {
      if (!isWithinRange(transaction.date, range)) {
        continue;
      }
      if (_selectedBudgetId != null &&
          transaction.budgetId != _selectedBudgetId) {
        continue;
      }
      if (_typeFilter == _TypeFilter.expenses && !transaction.isExpense) {
        continue;
      }
      if (_typeFilter == _TypeFilter.income && !transaction.isIncome) {
        continue;
      }
      if (_searchQuery.trim().isNotEmpty) {
        final query = _searchQuery.trim().toLowerCase();
        final haystack = '${transaction.title} ${transaction.description} '
                '${transaction.category}'
            .toLowerCase();
        if (!haystack.contains(query)) continue;
      }
      result.add(transaction);
    }
    result.sort((a, b) {
      return b.date.compareTo(a.date);
    });

    return result;
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: AppTheme.pageBackground(context),
      appBar: _isSelectionMode
          ? AppBar(
              backgroundColor: AppTheme.pageBackground(context),
              foregroundColor: colorScheme.onSurface,
              elevation: 0,
              scrolledUnderElevation: 0,
              leading: IconButton(
                icon: const Icon(LucideIcons.x),
                onPressed: () => setState(() {
                  _isSelectionMode = false;
                  _selectedIds.clear();
                }),
              ),
              title: Text(
                '${_selectedIds.length} selected',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              actions: [
                TextButton.icon(
                  onPressed: _selectedIds.isEmpty ? null : _deleteSelectedItems,
                  icon: Icon(LucideIcons.trash2,
                      color: _selectedIds.isEmpty
                          ? colorScheme.onSurface.withValues(alpha: 0.3)
                          : AppColors.error),
                  label: Text(
                    'Delete',
                    style: TextStyle(
                      color: _selectedIds.isEmpty
                          ? colorScheme.onSurface.withValues(alpha: 0.3)
                          : AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            )
          : AppBar(
              automaticallyImplyLeading: false,
              title: const Text('Transactions'),
              centerTitle: false,
              backgroundColor: AppTheme.pageBackground(context),
              foregroundColor: colorScheme.onSurface,
              iconTheme: IconThemeData(color: colorScheme.onSurface),
              titleTextStyle: theme.textTheme.displaySmall?.copyWith(
                fontSize: 24,
                letterSpacing: -1,
              ),
              elevation: 0,
              scrolledUnderElevation: 0,
              actions: [
                IconButton(
                  icon: Icon(LucideIcons.repeat, color: colorScheme.onSurface),
                  onPressed: () => context.pushSmooth(
                    const RecurringTransactionsScreen(),
                  ),
                  tooltip: 'Recurring Transactions',
                ),
                IconButton(
                  icon: Icon(LucideIcons.plus, color: colorScheme.onSurface),
                  onPressed: () => context.pushSmooth(
                    const AddTransactionScreen(),
                    transitionType: PageTransitionType.slideFromBottom,
                  ),
                  tooltip: 'Add Transaction',
                ),
              ],
            ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<TransactionBloc, TransactionState>(
            listener: (context, state) {
              if (state is TransactionLoaded && state.message != null) {
                AppSnackbar.showSuccess(context, message: state.message!);
              }
              if (state is TransactionError) {
                AppSnackbar.showError(context, message: state.message);
              }
            },
          ),
        ],
        child: Builder(builder: (context) {
          final txState = context.watch<TransactionBloc>().state;
          final budgetState = context.watch<BudgetBloc>().state;

          if (txState is TransactionLoading) {
            return _buildLoadingState();
          }

          final transactions = txState is TransactionLoaded
              ? txState.transactions
              : <Transaction>[];
          final budgets =
              budgetState is BudgetLoaded ? budgetState.budgets : <Budget>[];

          final filtered = _applyFilters(transactions);

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_fadeController.status != AnimationStatus.completed) {
              _fadeController.forward();
            }
          });

          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSummaryBar(filtered),
                        _buildSearchField(),
                        _buildIntelligenceNotice(transactions),
                        _buildFilterRow(budgets),
                      ],
                    ),
                  ),
                  filtered.isEmpty
                      ? SliverFillRemaining(child: _buildEmptyState())
                      : SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                          sliver: _buildTransactionSliver(filtered),
                        ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSearchField() {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Search merchant, category, or note',
          prefixIcon: const Icon(LucideIcons.search, size: 19),
          suffixIcon: _searchQuery.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear search',
                  icon: const Icon(LucideIcons.x, size: 18),
                  onPressed: () => setState(() => _searchQuery = ''),
                ),
          filled: true,
          fillColor: AppTheme.cardSurface(context),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide:
                BorderSide(color: colorScheme.outline.withValues(alpha: 0.12)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide:
                BorderSide(color: colorScheme.outline.withValues(alpha: 0.12)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: colorScheme.primary),
          ),
        ),
      ),
    );
  }

  Widget _buildIntelligenceNotice(List<Transaction> transactions) {
    final recurring = _intelligence.findRecurring(transactions);
    final duplicates = _intelligence.findDuplicates(transactions);
    if (recurring.isEmpty && duplicates.isEmpty) {
      return const SizedBox.shrink();
    }

    final parts = <String>[];
    if (recurring.isNotEmpty) {
      parts.add(
          '${recurring.length} recurring pattern${recurring.length == 1 ? '' : 's'}');
    }
    if (duplicates.isNotEmpty) {
      parts.add(
          '${duplicates.length} possible duplicate${duplicates.length == 1 ? '' : 's'}');
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.14)),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.sparkles, size: 17, color: AppColors.primary),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                parts.join(' · '),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (recurring.isNotEmpty)
              TextButton(
                onPressed: () => context.pushSmooth(
                  const RecurringTransactionsScreen(),
                ),
                child: const Text('Review'),
              ),
          ],
        ),
      ),
    );
  }

  // ─── Summary bar ─────────────────────────────────────────────────────────

  Widget _buildSummaryBar(List<Transaction> items) {
    final totalIncome = items.totalIncome();
    final totalExpense = items.totalExpenses();
    final net = items.netBalance;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surface : Colors.black,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Balance',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.6),
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyService().formatAmount(net),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.scrollText,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              _modernSummaryItem(
                label: 'Income',
                amount: totalIncome,
                icon: LucideIcons.arrowDownToLine,
                color: AppColors.success,
              ),
              Container(
                width: 1,
                height: 40,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                color: Colors.white.withValues(alpha: 0.1),
              ),
              _modernSummaryItem(
                label: 'Expenses',
                amount: totalExpense,
                icon: LucideIcons.arrowUpFromLine,
                color: AppColors.error,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _modernSummaryItem({
    required String label,
    required double amount,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  CurrencyService().formatAmount(amount),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Filter row (timeline pills + filter chip) ────────────────────────────

  Widget _buildFilterRow(List<Budget> budgets) {
    final hasActiveSecondary =
        _typeFilter != _TypeFilter.all || _selectedBudgetId != null;
    final colorScheme = Theme.of(context).colorScheme;

    String customLabel = 'Custom';
    if (_timelineFilter == TimelineFilter.custom && _customRange != null) {
      final s = _customRange!.start;
      final e = _customRange!.end;
      customLabel = '${s.day}/${s.month}–${e.day}/${e.month}';
    }

    final timelinePills = [
      _timelinePill('Week', TimelineFilter.lastWeek),
      _timelinePill('Month', TimelineFilter.lastMonth),
      _timelinePill('3 Months', TimelineFilter.last3Months),
      _timelinePill(customLabel, TimelineFilter.custom,
          icon: LucideIcons.calendarRange, onCustomTap: _pickCustomRange),
    ];

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: AppTheme.surfaceDecoration(context,
            radius: AppTheme.cardRadius, subtle: true),
        child: SizedBox(
          height: 40,
          child: Row(
            children: [
              Expanded(
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(left: 12),
                  children: timelinePills
                      .map((p) => Padding(
                          padding: const EdgeInsets.only(right: 8), child: p))
                      .toList(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 4, right: 12),
                child: GestureDetector(
                  onTap: () => _showFilterSheet(budgets),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: hasActiveSecondary
                          ? AppColors.primary
                          : AppTheme.cardSurface(context),
                      border: Border.all(
                        color: hasActiveSecondary
                            ? AppColors.primary
                            : colorScheme.outline.withValues(alpha: 0.2),
                        width: hasActiveSecondary ? 1.5 : 1,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.sliders,
                          size: 15,
                          color: hasActiveSecondary
                              ? Colors.white
                              : colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                        if (hasActiveSecondary) ...[
                          const SizedBox(width: 5),
                          Text(
                            _activeFilterCount().toString(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _activeFilterCount() {
    int count = 0;
    if (_typeFilter != _TypeFilter.all) count++;
    if (_selectedBudgetId != null) count++;
    return count;
  }

  Widget _timelinePill(String label, TimelineFilter filter,
      {IconData? icon, VoidCallback? onCustomTap}) {
    final selected = _timelineFilter == filter;
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onCustomTap ?? () => setState(() => _timelineFilter = filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppTheme.cardSurface(context),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : colorScheme.outline.withValues(alpha: 0.4),
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 13,
                  color: selected
                      ? Colors.white
                      : colorScheme.onSurface.withValues(alpha: 0.7)),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                color: selected
                    ? Colors.white
                    : colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet(List<Budget> budgets) {
    AppBottomSheet.show(
      context,
      radius: AppTheme.cardRadius,
      isScrollControlled: false,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final colorScheme = Theme.of(ctx).colorScheme;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Filters',
                        style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            )),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _typeFilter = _TypeFilter.all;
                          _selectedBudgetId = null;
                        });
                        Navigator.pop(ctx);
                      },
                      child: Text('Reset',
                          style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Type section
                Text('Type',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface.withValues(alpha: 0.55))),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _sheetPill(
                      ctx: ctx,
                      label: 'All',
                      selected: _typeFilter == _TypeFilter.all,
                      onTap: () {
                        setState(() => _typeFilter = _TypeFilter.all);
                        setSheetState(() {});
                      },
                    ),
                    const SizedBox(width: 8),
                    _sheetPill(
                      ctx: ctx,
                      label: 'Expenses',
                      icon: LucideIcons.minus,
                      selected: _typeFilter == _TypeFilter.expenses,
                      onTap: () {
                        setState(() => _typeFilter = _TypeFilter.expenses);
                        setSheetState(() {});
                      },
                    ),
                    const SizedBox(width: 8),
                    _sheetPill(
                      ctx: ctx,
                      label: 'Income',
                      icon: LucideIcons.plus,
                      selected: _typeFilter == _TypeFilter.income,
                      onTap: () {
                        setState(() => _typeFilter = _TypeFilter.income);
                        setSheetState(() {});
                      },
                    ),
                  ],
                ),
                if (budgets.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text('Budget',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color:
                              colorScheme.onSurface.withValues(alpha: 0.55))),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _sheetPill(
                        ctx: ctx,
                        label: 'All Budgets',
                        selected: _selectedBudgetId == null,
                        onTap: () {
                          setState(() => _selectedBudgetId = null);
                          setSheetState(() {});
                        },
                      ),
                      ...budgets.map((b) => _sheetPill(
                            ctx: ctx,
                            label: b.name,
                            selected: _selectedBudgetId == b.id,
                            onTap: () {
                              setState(() => _selectedBudgetId =
                                  _selectedBudgetId == b.id ? null : b.id);
                              setSheetState(() {});
                            },
                          )),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Apply',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _sheetPill({
    required BuildContext ctx,
    required String label,
    required bool selected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    final colorScheme = Theme.of(ctx).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          border: Border.all(
            color: selected
                ? AppColors.primary
                : colorScheme.outline.withValues(alpha: 0.4),
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 13,
                  color: selected
                      ? Colors.white
                      : colorScheme.onSurface.withValues(alpha: 0.7)),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                color: selected
                    ? Colors.white
                    : colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Transaction list (sliver) ────────────────────────────────────────────

  Widget _buildTransactionSliver(List<Transaction> items) {
    // Group by date
    final grouped = <String, List<Transaction>>{};
    for (final item in items) {
      grouped.putIfAbsent(_formatDateKey(item.date), () => []).add(item);
    }
    final keys = grouped.keys.toList();

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => _buildGroup(keys[index], grouped[keys[index]]!),
        childCount: keys.length,
      ),
    );
  }

  Widget _buildGroup(String dateKey, List<Transaction> items) {
    final dayNet = items.fold(0.0, (sum, item) {
      return sum + (item.isIncome ? item.amount : -item.amount);
    });
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateKey,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface.withValues(alpha: 0.55),
                  letterSpacing: 0.4,
                ),
              ),
              Text(
                '${dayNet >= 0 ? '+' : ''}${CurrencyService().formatAmount(dayNet)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: AppTheme.surfaceDecoration(context,
              radius: AppTheme.cardRadius, subtle: false),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: colorScheme.outline.withValues(alpha: 0.15),
                  ),
                TransactionTile(
                  item: items[i],
                  showCard: false,
                  isSelectionMode: _isSelectionMode,
                  isSelected: _selectedIds.contains(items[i].id),
                  onTap: () => _isSelectionMode
                      ? _toggleSelection(items[i].id)
                      : _showEditDialog(items[i]),
                  onLongPress: () {
                    if (!_isSelectionMode) {
                      setState(() {
                        _isSelectionMode = true;
                        _selectedIds.add(items[i].id);
                      });
                    }
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ─── Loading / empty / error ──────────────────────────────────────────────

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 100, 16, 16),
      itemCount: 8,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: SkeletonComponents.transactionListItem(context: context),
      ),
    );
  }

  Widget _buildEmptyState() {
    return EmptyStateView(
      icon: LucideIcons.scrollText,
      iconColor: AppColors.primary,
      iconSize: 48,
      title: 'No transactions found',
      titleFontSize: 20,
      subtitle: 'Try adjusting your filters or add a new transaction.',
      actionLabel: 'Add Transaction',
      actionIcon: LucideIcons.plus,
      spacingBeforeAction: 24,
      actionStyle: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onAction: () => context.pushSmooth(
        const AddTransactionScreen(),
        transitionType: PageTransitionType.slideFromBottom,
      ),
    );
  }

  // ─── Selection delete ─────────────────────────────────────────────────────

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _deleteSelectedItems() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete selected?'),
        content: Text(
            'Delete ${_selectedIds.length} item${_selectedIds.length == 1 ? '' : 's'}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final user = context.read<AuthBloc>().state;
    if (user is! AuthAuthenticated) return;

    final txState = context.read<TransactionBloc>().state;
    final all =
        (txState is TransactionLoaded) ? txState.transactions : <Transaction>[];

    for (final id in _selectedIds) {
      final item = all.where((transaction) => transaction.id == id).firstOrNull;
      if (item != null) {
        context
            .read<TransactionBloc>()
            .add(DeleteTransaction(id, user.user.id));
      }
    }

    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
    });
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String _formatDateKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) return 'Today';
    if (d == yesterday) return 'Yesterday';
    return '${date.day} ${_monthName(date.month)} ${date.year}';
  }

  String _monthName(int m) => const [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ][m - 1];

  void _showEditDialog(Transaction item) {
    EditTransactionScreen.showEditTransactionPopup(context, item);
  }
}
