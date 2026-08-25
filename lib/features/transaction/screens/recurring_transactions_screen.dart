import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_theme.dart';
import '../../../core/models/recurring_transaction_model.dart';
import '../../../core/models/transaction_model.dart';
import '../../../core/services/currency_service.dart';
import '../../../core/services/recurring_transaction_service.dart';
import '../../../core/utils/date_format_utils.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_icon_badge.dart';
import '../../../shared/widgets/app_status_pill.dart';
import '../../../shared/widgets/app_form_fields.dart';
import '../../auth/auth_bloc.dart';
import '../../transaction/transaction_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class RecurringTransactionsScreen extends StatefulWidget {
  const RecurringTransactionsScreen({super.key});

  @override
  State<RecurringTransactionsScreen> createState() =>
      _RecurringTransactionsScreenState();
}

class _RecurringTransactionsScreenState
    extends State<RecurringTransactionsScreen> {
  final RecurringTransactionService _recurringTransactionService =
      RecurringTransactionService();
  Future<List<RecurringTransaction>>? _recurringTransactionsFuture;
  TransactionType? _filterType;

  @override
  void initState() {
    super.initState();
    _loadRecurringTransactions();
  }

  void _loadRecurringTransactions() {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      return;
    }

    setState(() {
      _recurringTransactionsFuture =
          _recurringTransactionService.getUserRecurringTransactions(
        authState.user.id,
      );
    });
  }

  Future<void> _toggleStatus(RecurringTransaction recurring) async {
    final nextStatus = recurring.status == RecurringTransactionStatus.active
        ? RecurringTransactionStatus.paused
        : RecurringTransactionStatus.active;

    try {
      await _recurringTransactionService.updateRecurringTransaction(
        recurring.copyWith(status: nextStatus),
      );
      if (!mounted) {
        return;
      }
      _loadRecurringTransactions();
      AppSnackbar.showSuccess(
        context,
        message: nextStatus == RecurringTransactionStatus.active
            ? 'Recurring transaction resumed'
            : 'Recurring transaction paused',
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      AppSnackbar.showError(
        context,
        message: 'Failed to update recurring transaction: $e',
      );
    }
  }

  Future<void> _deleteRecurringTransaction(
      RecurringTransaction recurring) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete recurring transaction?'),
        content: Text(
          'Future auto-created entries for "${recurring.title}" will stop. Existing transactions will remain.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _recurringTransactionService
          .deleteRecurringTransaction(recurring.id);
      if (!mounted) {
        return;
      }
      _loadRecurringTransactions();
      AppSnackbar.showSuccess(
        context,
        message: 'Recurring transaction deleted',
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      AppSnackbar.showError(
        context,
        message: 'Failed to delete recurring transaction: $e',
      );
    }
  }

  Future<void> _skipNextOccurrence(RecurringTransaction recurring) async {
    try {
      await _recurringTransactionService.skipNextOccurrence(recurring);
      if (!mounted) return;
      _loadRecurringTransactions();
      AppSnackbar.showSuccess(context, message: 'Next occurrence skipped');
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(context, message: 'Failed to skip occurrence: $e');
    }
  }

  Future<void> _endRecurringTransaction(RecurringTransaction recurring) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End recurring transaction?'),
        content: Text(
          'No future entries will be created for "${recurring.title}". Existing transactions will remain.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('End recurrence'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _recurringTransactionService.endRecurringTransaction(recurring);
      if (!mounted) return;
      _loadRecurringTransactions();
      AppSnackbar.showSuccess(context, message: 'Recurrence ended');
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(context, message: 'Failed to end recurrence: $e');
    }
  }

  Future<void> _scheduleReminder(RecurringTransaction recurring) async {
    try {
      await _recurringTransactionService.scheduleReminder(recurring);
      if (!mounted) return;
      _loadRecurringTransactions();
      AppSnackbar.showSuccess(context,
          message: 'Reminder set for the day before');
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(context, message: 'Could not set reminder: $e');
    }
  }

  Future<void> _disableReminder(RecurringTransaction recurring) async {
    try {
      await _recurringTransactionService.disableReminder(recurring);
      if (!mounted) return;
      _loadRecurringTransactions();
      AppSnackbar.showSuccess(context, message: 'Reminder disabled');
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(context, message: 'Could not disable reminder: $e');
    }
  }

  Future<void> _editRecurringTransaction(RecurringTransaction recurring) async {
    final titleController = TextEditingController(text: recurring.title);
    final amountController =
        TextEditingController(text: recurring.amount.toStringAsFixed(2));
    var frequency = recurring.frequency;
    var nextRunAt = recurring.nextRunAt;

    final edited = await showDialog<RecurringTransaction>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
              'Edit recurring ${recurring.type == TransactionType.income ? 'income' : 'expense'}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  controller: titleController,
                  labelText: 'Title',
                  textInputAction: TextInputAction.next,
                ),
                AppNumberField(
                  controller: amountController,
                  hintText: 'Amount',
                ),
                const SizedBox(height: 12),
                AppDropdownField<RecurringTransactionFrequency>(
                  value: frequency,
                  hintText: 'Frequency',
                  items: RecurringTransactionFrequency.values
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(value.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setDialogState(() => frequency = value);
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Next run'),
                  subtitle: Text(formatShortDate(nextRunAt)),
                  trailing: const Icon(LucideIcons.calendar),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                      initialDate: nextRunAt.isBefore(DateTime.now())
                          ? DateTime.now()
                          : nextRunAt,
                    );
                    if (picked != null) {
                      setDialogState(() => nextRunAt = DateTime(
                            picked.year,
                            picked.month,
                            picked.day,
                            nextRunAt.hour,
                            nextRunAt.minute,
                          ));
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final amount = double.tryParse(amountController.text.trim());
                final title = titleController.text.trim();
                if (title.isEmpty || amount == null || amount <= 0) return;
                Navigator.pop(
                  dialogContext,
                  recurring.copyWith(
                    title: title,
                    amount: amount,
                    frequency: frequency,
                    nextRunAt: nextRunAt,
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    titleController.dispose();
    amountController.dispose();
    if (edited == null) return;

    try {
      await _recurringTransactionService.updateRecurringTransaction(edited);
      if (!mounted) return;
      _loadRecurringTransactions();
      AppSnackbar.showSuccess(
        context,
        message:
            'Recurring ${recurring.type == TransactionType.income ? 'income' : 'expense'} updated',
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(
        context,
        message:
            'Failed to edit recurring ${recurring.type == TransactionType.income ? 'income' : 'expense'}: $e',
      );
    }
  }

  Future<void> _refreshTransactions() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<TransactionBloc>().add(LoadTransactions(authState.user.id));
    }
    _loadRecurringTransactions();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: AppTheme.pageBackground(context),
      appBar: AppBar(
        title: const Text('Recurring'),
        centerTitle: false,
        backgroundColor: AppTheme.pageBackground(context),
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshTransactions,
        child: FutureBuilder<List<RecurringTransaction>>(
          future: _recurringTransactionsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 120),
                  const Icon(LucideIcons.cloudOff, size: 42),
                  const SizedBox(height: 16),
                  const Text(
                    'Could not load recurring income and expenses',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _loadRecurringTransactions,
                    child: const Text('Try again'),
                  ),
                ],
              );
            }

            final recurringTransactions = snapshot.data ?? [];
            if (recurringTransactions.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.16),
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      LucideIcons.repeat,
                      size: 36,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No recurring income or expenses',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create salary, bills, or other scheduled entries from Add Transaction using the repeat toggle.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.65),
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            }

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                _buildRecurringSummary(recurringTransactions),
                const SizedBox(height: 12),
                _buildTypeFilter(),
                const SizedBox(height: 12),
                if (_filteredRecurring(recurringTransactions).isEmpty)
                  _buildFilteredEmptyState()
                else
                  ..._filteredRecurring(recurringTransactions).map(
                    (recurring) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildRecurringTile(recurring),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<RecurringTransaction> _filteredRecurring(
      List<RecurringTransaction> recurringTransactions) {
    if (_filterType == null) return recurringTransactions;
    return recurringTransactions
        .where((item) => item.type == _filterType)
        .toList();
  }

  Widget _buildTypeFilter() {
    final colorScheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _filterChip('All', null, colorScheme),
          const SizedBox(width: 8),
          _filterChip('Income', TransactionType.income, colorScheme),
          const SizedBox(width: 8),
          _filterChip('Expenses', TransactionType.expense, colorScheme),
        ],
      ),
    );
  }

  Widget _filterChip(
    String label,
    TransactionType? type,
    ColorScheme colorScheme,
  ) {
    final selected = _filterType == type;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _filterType = type),
      selectedColor: colorScheme.primary.withValues(alpha: 0.14),
      labelStyle: TextStyle(
        color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
      side: BorderSide(
        color: selected
            ? colorScheme.primary.withValues(alpha: 0.35)
            : colorScheme.outline.withValues(alpha: 0.18),
      ),
      showCheckmark: false,
    );
  }

  Widget _buildFilteredEmptyState() {
    final label = _filterType == TransactionType.income ? 'income' : 'expenses';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
      child: Column(
        children: [
          Icon(
            _filterType == TransactionType.income
                ? LucideIcons.arrowUp
                : LucideIcons.arrowDown,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            size: 28,
          ),
          const SizedBox(height: 12),
          Text(
            'No recurring $label yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Use Add Transaction and enable Repeat this transaction.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecurringSummary(
      List<RecurringTransaction> recurringTransactions) {
    final colorScheme = Theme.of(context).colorScheme;
    final active = recurringTransactions
        .where((item) => item.status == RecurringTransactionStatus.active)
        .toList();
    final monthlyIncome = active
        .where((item) => item.type == TransactionType.income)
        .fold<double>(0, (total, item) => total + item.monthlyEquivalent);
    final monthlyExpenses = active
        .where((item) => item.type == TransactionType.expense)
        .fold<double>(0, (total, item) => total + item.monthlyEquivalent);
    final next = active.isEmpty
        ? null
        : (active..sort((a, b) => a.nextRunAt.compareTo(b.nextRunAt))).first;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.surfaceDecoration(context,
          radius: AppTheme.cardRadius, subtle: true),
      child: Row(
        children: [
          Expanded(
            child: _summaryMetric(
              'Monthly income',
              CurrencyService().formatAmount(monthlyIncome),
              color: AppColors.success,
            ),
          ),
          Container(
            width: 1,
            height: 42,
            color: colorScheme.outline.withValues(alpha: 0.18),
          ),
          Expanded(
            child: _summaryMetric(
              'Monthly expenses',
              CurrencyService().formatAmount(monthlyExpenses),
              color: AppColors.error,
            ),
          ),
          Container(
            width: 1,
            height: 42,
            color: colorScheme.outline.withValues(alpha: 0.18),
          ),
          Expanded(
            child: _summaryMetric(
              'Next run',
              next == null ? 'None' : formatShortDate(next.nextRunAt),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryMetric(String label, String value, {Color? color}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.58),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color ?? colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecurringTile(RecurringTransaction recurring) {
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = recurring.type == TransactionType.income
        ? AppColors.success
        : AppColors.error;
    final statusColor = switch (recurring.status) {
      RecurringTransactionStatus.active => AppColors.success,
      RecurringTransactionStatus.paused => Colors.orange,
      RecurringTransactionStatus.ended => colorScheme.outline,
    };

    return AppCard(
      subtle: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIconBadge(
                icon: recurring.type == TransactionType.income
                    ? LucideIcons.plus
                    : LucideIcons.minus,
                color: accentColor,
                size: AppIconBadgeSize.large,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recurring.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${recurring.frequency.label} • ${recurring.category}',
                      style: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.62),
                      ),
                    ),
                  ],
                ),
              ),
              AppStatusPill(
                label: recurring.status.name,
                color: statusColor,
              ),
              PopupMenuButton<String>(
                tooltip: 'More actions',
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _editRecurringTransaction(recurring);
                    case 'skip':
                      _skipNextOccurrence(recurring);
                    case 'remind':
                      _scheduleReminder(recurring);
                    case 'disable_remind':
                      _disableReminder(recurring);
                    case 'end':
                      _endRecurringTransaction(recurring);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(LucideIcons.pencil),
                      title: Text('Edit'),
                    ),
                  ),
                  if (recurring.status != RecurringTransactionStatus.ended)
                    const PopupMenuItem(
                      value: 'skip',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(LucideIcons.skipForward),
                        title: Text('Skip next'),
                      ),
                    ),
                  if (recurring.status == RecurringTransactionStatus.active &&
                      !recurring.reminderEnabled)
                    const PopupMenuItem(
                      value: 'remind',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(LucideIcons.bell),
                        title: Text('Set reminder'),
                      ),
                    ),
                  if (recurring.status == RecurringTransactionStatus.active &&
                      recurring.reminderEnabled)
                    const PopupMenuItem(
                      value: 'disable_remind',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(LucideIcons.bellOff),
                        title: Text('Disable reminder'),
                      ),
                    ),
                  if (recurring.status != RecurringTransactionStatus.ended)
                    const PopupMenuItem(
                      value: 'end',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(LucideIcons.square),
                        title: Text('End recurrence'),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _metaItem(
                  label: 'Amount',
                  value: CurrencyService().formatAmount(recurring.amount),
                ),
              ),
              Expanded(
                child: _metaItem(
                  label: 'Next run',
                  value: formatShortDate(recurring.nextRunAt),
                ),
              ),
              Expanded(
                child: _metaItem(
                  label: 'Last run',
                  value: recurring.lastRunAt == null
                      ? 'Never'
                      : formatShortDate(recurring.lastRunAt!),
                ),
              ),
            ],
          ),
          if (recurring.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              recurring.description,
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.72),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      recurring.status == RecurringTransactionStatus.ended
                          ? null
                          : () => _toggleStatus(recurring),
                  icon: Icon(
                    recurring.status == RecurringTransactionStatus.active
                        ? LucideIcons.pause
                        : LucideIcons.play,
                  ),
                  label: Text(
                    recurring.status == RecurringTransactionStatus.active
                        ? 'Pause'
                        : 'Resume',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _deleteRecurringTransaction(recurring),
                  icon: const Icon(LucideIcons.trash2),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metaItem({
    required String label,
    required String value,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
