import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/constants/categories.dart';
import '../../../core/models/budget_model.dart';
import '../../../core/services/currency_service.dart';
import '../../../core/services/transaction_service.dart';
import '../../budget/budget_bloc.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/app_bottom_sheet.dart';
import '../../../shared/widgets/field_label.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class EditBudgetScreen {
  const EditBudgetScreen._();

  /// Show the edit budget bottom sheet — matches the edit transaction slider pattern.
  static void showEditBudgetSheet(BuildContext context, Budget budget) {
    AppBottomSheet.show(
      context,
      radius: 20,
      isScrollControlled: true,
      padding: EdgeInsets.zero,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.9,
        child: SafeArea(
          bottom: true,
          child: Builder(
            builder: (context) {
              final theme = Theme.of(context);
              final colorScheme = theme.colorScheme;
              final isDark = theme.brightness == Brightness.dark;
              final actionColor = isDark ? Colors.white : colorScheme.onSurface;
              return Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Text(
                          'Edit Budget',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Cancel',
                            style: TextStyle(color: actionColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: _EditBudgetForm(budget: budget),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _EditBudgetForm extends StatefulWidget {
  final Budget budget;

  const _EditBudgetForm({required this.budget});

  @override
  State<_EditBudgetForm> createState() => _EditBudgetFormState();
}

class _EditBudgetFormState extends State<_EditBudgetForm> {
  final TransactionService _transactionService = TransactionService();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  late final TextEditingController _weeklyTargetController;
  late final TextEditingController _adjustmentController;

  late BudgetPeriod _selectedPeriod;
  late String _selectedCategory;
  late bool _enableRollover;
  late bool _isActive;
  late DateTime? _adjustmentExpiresAt;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.budget.name);
    _amountController =
        TextEditingController(text: widget.budget.amount.toStringAsFixed(2));
    _weeklyTargetController = TextEditingController(
      text: widget.budget.weeklyTarget > 0
          ? widget.budget.weeklyTarget.toStringAsFixed(2)
          : '',
    );
    _adjustmentController = TextEditingController(
      text: widget.budget.temporaryAdjustment != 0
          ? widget.budget.temporaryAdjustment.toStringAsFixed(2)
          : '',
    );
    _selectedPeriod = widget.budget.period;
    _selectedCategory = widget.budget.category;
    _enableRollover = widget.budget.enableRollover;
    _isActive = widget.budget.isActive;
    _adjustmentExpiresAt = widget.budget.adjustmentExpiresAt;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _weeklyTargetController.dispose();
    _adjustmentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BudgetBloc, BudgetState>(
      listener: (context, state) {
        if (state is BudgetLoading) {
          setState(() => _isLoading = true);
        } else {
          setState(() => _isLoading = false);
        }

        if (state is BudgetSuccess) {
          AppSnackbar.showSuccess(context, message: state.message);
          Navigator.pop(context);
        }

        if (state is BudgetError) {
          AppSnackbar.showError(context, message: state.message);
        }
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionTitle('Budget Name', icon: LucideIcons.type),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'e.g., Monthly Food Budget',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a budget name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildSectionTitle('Amount', icon: LucideIcons.dollarSign),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Enter amount',
                  prefixText: '${CurrencyService().symbol} ',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildSectionTitle('Weekly Target', icon: LucideIcons.target),
              const SizedBox(height: 8),
              TextFormField(
                controller: _weeklyTargetController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  hintText: 'Optional spending limit per week',
                  prefixText: '${CurrencyService().symbol} ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return null;
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Enter a valid weekly target';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildSectionTitle('Category', icon: LucideIcons.tag),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                items: AppCategories.expenseCategories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.circle,
                          size: 10,
                          color: Color(AppCategories.getColor(category)),
                        ),
                        const SizedBox(width: 8),
                        Text(category),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) =>
                    setState(() => _selectedCategory = value!),
              ),
              const SizedBox(height: 20),
              _buildSectionTitle('Period'),
              const SizedBox(height: 8),
              _buildPeriodSelector(),
              const SizedBox(height: 20),
              _buildToggle(
                title: 'Active',
                subtitle: 'Inactive budgets are hidden from most lists',
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
              ),
              const SizedBox(height: 12),
              _buildToggle(
                title: 'Enable Rollover',
                subtitle: 'Unused budget carries over to next period',
                value: _enableRollover,
                onChanged: (v) => setState(() => _enableRollover = v),
              ),
              const SizedBox(height: 12),
              _buildTemporaryAdjustment(),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Save Changes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, {IconData? icon}) {
    if (icon != null) return FieldLabel(icon: icon, label: title);
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Row(
      children: BudgetPeriod.values.map((period) {
        final isSelected = _selectedPeriod == period;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              if (isSelected) return;
              AppHaptics.selection();
              setState(() => _selectedPeriod = period);
            },
            child: AnimatedContainer(
              duration: AppMotion.fast,
              curve: AppMotion.standard,
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : Theme.of(context)
                          .colorScheme
                          .outline
                          .withValues(alpha: 0.4),
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                period.name[0].toUpperCase() + period.name.substring(1),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                  color: isSelected
                      ? AppColors.primary
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildToggle({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: TextStyle(
              fontWeight: FontWeight.w600, color: colorScheme.onSurface),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6)),
        ),
        value: value,
        onChanged: (v) {
          AppHaptics.selection();
          onChanged(v);
        },
        activeThumbColor: AppColors.primary,
      ),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      AppHaptics.error();
      return;
    }

    final selectedStatus = _isActive;
    final wasActive = widget.budget.isActive;
    final weeklyTarget =
        double.tryParse(_weeklyTargetController.text.trim()) ?? 0;
    final temporaryAdjustment =
        double.tryParse(_adjustmentController.text.trim()) ?? 0;

    bool keepLinkedTransactions = true;
    if (wasActive && !selectedStatus) {
      final decision = await _showTransactionSyncSheet();
      if (decision == null) return;
      keepLinkedTransactions = decision == _BudgetTransactionChoice.keepLinked;
    }

    if (wasActive != selectedStatus) {
      setState(() => _isLoading = true);
      try {
        await _transactionService.syncBudgetTransactionLinks(
          userId: widget.budget.userId,
          budgetId: widget.budget.id,
          newBudgetIsActive: selectedStatus,
          keepLinkedToBudget: selectedStatus ? true : keepLinkedTransactions,
        );
      } catch (e) {
        if (mounted) {
          AppSnackbar.showError(
            context,
            message: 'Failed to update linked transactions: $e',
          );
          setState(() => _isLoading = false);
        }
        return;
      }
    }

    final updated = widget.budget.copyWith(
      name: _nameController.text.trim(),
      amount: double.parse(_amountController.text.trim()),
      period: _selectedPeriod,
      category: _selectedCategory,
      enableRollover: _enableRollover,
      weeklyTarget: weeklyTarget,
      temporaryAdjustment: temporaryAdjustment,
      adjustmentExpiresAt:
          temporaryAdjustment == 0 ? null : _adjustmentExpiresAt,
      isActive: _isActive,
      spent: (!selectedStatus && !keepLinkedTransactions)
          ? 0
          : widget.budget.spent,
    );

    if (!mounted) return;
    context.read<BudgetBloc>().add(UpdateBudget(updated));
  }

  Widget _buildTemporaryAdjustment() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Temporary adjustment',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Add or subtract spending room for a short-term change.',
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.62),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _adjustmentController,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            decoration: InputDecoration(
              hintText: 'e.g. 50 or -25',
              prefixText: '${CurrencyService().symbol} ',
              border: const OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return null;
              if (double.tryParse(value) == null) {
                return 'Enter a valid adjustment';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Adjustment expires'),
            subtitle: Text(
              _adjustmentExpiresAt == null
                  ? 'Until this budget period ends'
                  : '${_adjustmentExpiresAt!.day}/${_adjustmentExpiresAt!.month}/${_adjustmentExpiresAt!.year}',
            ),
            trailing: const Icon(LucideIcons.calendarClock),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                firstDate: DateTime.now(),
                lastDate: widget.budget.endDate,
                initialDate: _adjustmentExpiresAt ?? widget.budget.endDate,
              );
              if (picked != null) {
                setState(() => _adjustmentExpiresAt = picked);
              }
            },
          ),
        ],
      ),
    );
  }

  Future<_BudgetTransactionChoice?> _showTransactionSyncSheet() {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return showModalBottomSheet<_BudgetTransactionChoice>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outline.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Linked Transactions',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Do you want transactions linked to this budget to become inactive too?',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'If not, transaction-to-budget links will be removed and that connection data is lost.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(
                    sheetContext,
                    _BudgetTransactionChoice.keepLinked,
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  child:
                      const Text('Yes, keep links and inactivate transactions'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(
                    sheetContext,
                    _BudgetTransactionChoice.removeLinks,
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  child:
                      const Text('No, remove budget links from transactions'),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _BudgetTransactionChoice { keepLinked, removeLinks }
