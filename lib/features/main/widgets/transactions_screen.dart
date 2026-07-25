import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/models/transaction_model.dart';
import '../../../core/models/budget_model.dart';
import '../../../core/services/currency_service.dart';
import '../../auth/auth_bloc.dart';
import '../../transaction/transaction_bloc.dart';
import '../../transaction/screens/edit_transaction_screen.dart';
import '../../transaction/screens/add_transaction_screen.dart';
import '../../transaction/screens/recurring_transactions_screen.dart';
import '../../budget/budget_bloc.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/page_transitions.dart';
import '../../../shared/widgets/skeleton_components.dart';
import '../../../core/widgets/app_banner_ad.dart';
import 'transaction_tile.dart';
import '../../../core/utils/date_range_filter.dart';

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

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
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
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: _customRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 30)),
            end: now,
          ),
      builder: (context, child) => Theme(
        data: Theme.of(context),
        child: child!,
      ),
    );
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
      if (transaction.date.isBefore(range.start) || transaction.date.isAfter(range.end)) {
        continue;
      }
      if (_selectedBudgetId != null && transaction.budgetId != _selectedBudgetId) {
        continue;
      }
      if (_typeFilter == _TypeFilter.expenses && !transaction.isExpense) {
        continue;
      }
      if (_typeFilter == _TypeFilter.income && !transaction.isIncome) {
        continue;
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
              foregroundColor: colorScheme.onBackground,
              elevation: 0,
              scrolledUnderElevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => setState(() {
                  _isSelectionMode = false;
                  _selectedIds.clear();
                }),
              ),
              title: Text(
                '${_selectedIds.length} selected',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colorScheme.onBackground,
                  fontWeight: FontWeight.w600,
                ),
              ),
              actions: [
                TextButton.icon(
                  onPressed: _selectedIds.isEmpty ? null : _deleteSelectedItems,
                  icon: Icon(Icons.delete_outline_rounded,
                      color: _selectedIds.isEmpty ? colorScheme.onBackground.withOpacity(0.3) : AppColors.error),
                  label: Text(
                    'Delete',
                    style: TextStyle(
                      color: _selectedIds.isEmpty ? colorScheme.onBackground.withOpacity(0.3) : AppColors.error,
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
              foregroundColor: colorScheme.onBackground,
              iconTheme: IconThemeData(color: colorScheme.onBackground),
              titleTextStyle: theme.textTheme.displaySmall?.copyWith(
                fontSize: 24,
                letterSpacing: -1,
              ),
              elevation: 0,
              scrolledUnderElevation: 0,
              actions: [
                IconButton(
                  icon:
                      Icon(Icons.repeat_rounded, color: colorScheme.onBackground),
                  onPressed: () => context.pushSmooth(
                    const RecurringTransactionsScreen(),
                  ),
                  tooltip: 'Recurring Transactions',
                ),
                IconButton(
                  icon: Icon(Icons.add_rounded, color: colorScheme.onBackground),
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
              if (state is TransactionError) AppSnackbar.showError(context, message: state.message);
            },
          ),
        ],
        child: Builder(builder: (context) {
          final txState = context.watch<TransactionBloc>().state;
          final budgetState = context.watch<BudgetBloc>().state;

          if (txState is TransactionLoading) {
            return _buildLoadingState();
          }

          final transactions = txState is TransactionLoaded ? txState.transactions : <Transaction>[];
          final budgets = budgetState is BudgetLoaded ? budgetState.budgets : <Budget>[];

          final filtered = _applyFilters(transactions);

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_fadeController.status != AnimationStatus.completed) _fadeController.forward();
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
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: AppBannerAd(),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // ─── Summary bar ─────────────────────────────────────────────────────────

  Widget _buildSummaryBar(List<Transaction> items) {
    double totalIncome = 0;
    double totalExpense = 0;
    for (final item in items) {
      if (item.isIncome) {
        totalIncome += item.amount;
      } else if (item.isExpense) {
        totalExpense += item.amount;
      }
    }
    final net = totalIncome - totalExpense;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surface : Colors.black,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
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
                      color: Colors.white.withOpacity(0.6),
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
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
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
                icon: Icons.arrow_downward_rounded,
                color: AppColors.success,
              ),
              Container(
                width: 1,
                height: 40,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                color: Colors.white.withOpacity(0.1),
              ),
              _modernSummaryItem(
                label: 'Expenses',
                amount: totalExpense,
                icon: Icons.arrow_upward_rounded,
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
              color: color.withOpacity(0.15),
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
                    color: Colors.white.withOpacity(0.5),
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
    final hasActiveSecondary = _typeFilter != _TypeFilter.all || _selectedBudgetId != null;
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
      _timelinePill(customLabel, TimelineFilter.custom, icon: Icons.date_range_rounded, onCustomTap: _pickCustomRange),
    ];

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: AppTheme.surfaceDecoration(context, radius: 22, subtle: true),
        child: SizedBox(
          height: 40,
          child: Row(
            children: [
              Expanded(
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(left: 12),
                  children: timelinePills
                      .map((p) => Padding(padding: const EdgeInsets.only(right: 8), child: p))
                      .toList(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 4, right: 12),
                child: GestureDetector(
                  onTap: () => _showFilterSheet(budgets),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: hasActiveSecondary ? AppColors.primary : AppTheme.cardSurface(context),
                      border: Border.all(
                        color: hasActiveSecondary
                            ? AppColors.primary
                            : colorScheme.outline.withOpacity(0.2),
                        width: hasActiveSecondary ? 1.5 : 1,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          size: 15,
                          color: hasActiveSecondary
                              ? Colors.white
                              : colorScheme.onBackground.withOpacity(0.7),
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
            color: selected ? AppColors.primary : colorScheme.outline.withOpacity(0.4),
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
                      : colorScheme.onBackground.withOpacity(0.7)),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                color: selected
                    ? Colors.white
                    : colorScheme.onBackground.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet(List<Budget> budgets) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final colorScheme = Theme.of(ctx).colorScheme;
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorScheme.outline.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Filters',
                          style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onBackground,
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
                          color: colorScheme.onBackground.withOpacity(0.55))),
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
                        icon: Icons.remove_rounded,
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
                        icon: Icons.add_rounded,
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
                            color: colorScheme.onBackground.withOpacity(0.55))),
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
              ),
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
            color: selected ? AppColors.primary : colorScheme.outline.withOpacity(0.4),
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
                      : colorScheme.onBackground.withOpacity(0.7)),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                color: selected
                    ? Colors.white
                    : colorScheme.onBackground.withOpacity(0.8),
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
          padding: const EdgeInsets.only(top: 24, bottom: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateKey,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onBackground.withOpacity(0.55),
                  letterSpacing: 0.4,
                ),
              ),
              Text(
                '${dayNet >= 0 ? '+' : ''}${CurrencyService().formatAmount(dayNet)}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: dayNet >= 0 ? AppColors.success : AppColors.error,
                ),
              ),
            ],
          ),
        ),
        ...items.map((item) => TransactionTile(
              item: item,
              isSelectionMode: _isSelectionMode,
              isSelected: _selectedIds.contains(item.id),
              onTap: () => _isSelectionMode
                  ? _toggleSelection(item.id)
                  : _showEditDialog(item),
              onLongPress: () {
                if (!_isSelectionMode) {
                  setState(() {
                    _isSelectionMode = true;
                    _selectedIds.add(item.id);
                  });
                }
              },
            )),
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
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.receipt_long_rounded, size: 36, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text(
              'No transactions found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onBackground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters or add a new transaction.',
              style: TextStyle(fontSize: 14, color: colorScheme.onBackground.withOpacity(0.6)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.pushSmooth(
                const AddTransactionScreen(),
                transitionType: PageTransitionType.slideFromBottom,
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Transaction'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
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
        content: Text('Delete ${_selectedIds.length} item${_selectedIds.length == 1 ? '' : 's'}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final user = context.read<AuthBloc>().state;
    if (user is! AuthAuthenticated) return;

    final txState = context.read<TransactionBloc>().state;
    final all = (txState is TransactionLoaded) ? txState.transactions : <Transaction>[];

    for (final id in _selectedIds) {
      final item = all.where((transaction) => transaction.id == id).firstOrNull;
      if (item != null) {
        context.read<TransactionBloc>().add(DeleteTransaction(id, user.user.id));
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
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m - 1];

  void _showEditDialog(Transaction item) {
    EditTransactionScreen.showEditTransactionPopup(context, item);
  }
}
