import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_theme.dart';
import '../../../core/models/recurring_transaction_model.dart';
import '../../../core/models/transaction_model.dart';
import '../../../core/services/currency_service.dart';
import '../../../core/services/recurring_transaction_service.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../auth/auth_bloc.dart';
import '../../transaction/transaction_bloc.dart';

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

  Future<void> _deleteRecurringTransaction(RecurringTransaction recurring) async {
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
      await _recurringTransactionService.deleteRecurringTransaction(recurring.id);
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
        foregroundColor: colorScheme.onBackground,
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
                      Icons.repeat_rounded,
                      size: 36,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No recurring transactions',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create one from the Add Transaction form using the repeat toggle.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.65),
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              itemBuilder: (context, index) {
                final recurring = recurringTransactions[index];
                return _buildRecurringTile(recurring);
              },
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemCount: recurringTransactions.length,
            );
          },
        ),
      ),
    );
  }

  Widget _buildRecurringTile(RecurringTransaction recurring) {
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor =
        recurring.type == TransactionType.income ? AppColors.success : AppColors.error;
    final statusColor = switch (recurring.status) {
      RecurringTransactionStatus.active => AppColors.success,
      RecurringTransactionStatus.paused => Colors.orange,
      RecurringTransactionStatus.ended => colorScheme.outline,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.surfaceDecoration(context, radius: 20, subtle: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  recurring.type == TransactionType.income
                      ? Icons.add_rounded
                      : Icons.remove_rounded,
                  color: accentColor,
                ),
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
                      '${_frequencyLabel(recurring.frequency)} • ${recurring.category}',
                      style: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.62),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  recurring.status.name,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
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
                  value: _formatDate(recurring.nextRunAt),
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
                  onPressed: recurring.status == RecurringTransactionStatus.ended
                      ? null
                      : () => _toggleStatus(recurring),
                  icon: Icon(
                    recurring.status == RecurringTransactionStatus.active
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
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
                  icon: const Icon(Icons.delete_outline_rounded),
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

  String _frequencyLabel(RecurringTransactionFrequency frequency) {
    return switch (frequency) {
      RecurringTransactionFrequency.daily => 'Daily',
      RecurringTransactionFrequency.weekly => 'Weekly',
      RecurringTransactionFrequency.monthly => 'Monthly',
      RecurringTransactionFrequency.yearly => 'Yearly',
    };
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
