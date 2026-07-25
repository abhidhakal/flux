import 'package:flux/core/constants/categories.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/models/transaction_model.dart';
import '../../../core/utils/date_format_utils.dart';
import '../../../core/models/budget_model.dart';
import '../../../core/services/currency_service.dart';
import '../../auth/auth_bloc.dart';
import '../../transaction/transaction_bloc.dart';
import '../../budget/budget_bloc.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/app_bottom_sheet.dart';
import '../../../shared/widgets/field_label.dart';
import 'package:lucide_icons/lucide_icons.dart';

class EditTransactionScreen {
  const EditTransactionScreen._();

  // Static method to show edit transaction popup
  static void showEditTransactionPopup(
      BuildContext context, Transaction transaction) {
    AppBottomSheet.show(
      context,
      radius: 20,
      isScrollControlled: true,
      padding: EdgeInsets.zero,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.9,
        child: SafeArea(
          bottom: true,
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      'Edit Transaction',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              // Form content
              Expanded(
                child: _EditTransactionForm(transaction: transaction),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Separate form widget for the popup
class _EditTransactionForm extends StatefulWidget {
  final Transaction transaction;

  const _EditTransactionForm({required this.transaction});

  @override
  State<_EditTransactionForm> createState() => _EditTransactionFormState();
}

class _EditTransactionFormState extends State<_EditTransactionForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  TransactionType _selectedType = TransactionType.expense;
  String _selectedCategory = 'Food & Dining';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  List<Budget> _availableBudgets = [];
  Budget? _selectedBudget;

  List<String> get _expenseCategories => AppCategories.expenseCategories;

  List<String> get _incomeCategories => AppCategories.incomeCategories;

  @override
  void initState() {
    super.initState();
    _initializeForm();
    // Load budgets when form initializes
    final user = context.read<AuthBloc>().state;
    if (user is AuthAuthenticated) {
      context.read<BudgetBloc>().add(LoadBudgets(user.user.id));
    }
  }

  void _initializeForm() {
    _titleController.text = widget.transaction.title;
    _descriptionController.text = widget.transaction.description;
    _amountController.text = widget.transaction.amount.toString();
    _selectedType = widget.transaction.type;
    _selectedCategory = widget.transaction.category;
    _selectedDate = widget.transaction.date;
    // Initialize budget selection if transaction has budgetId
    if (widget.transaction.budgetId != null &&
        widget.transaction.budgetId!.isNotEmpty) {
      // Will be set when budgets are loaded
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocListener<BudgetBloc, BudgetState>(
      listener: (context, state) {
        if (state is BudgetLoaded) {
          setState(() {
            _availableBudgets =
                state.budgets.where((budget) => budget.isActive).toList();
            // Set selected budget if transaction has budgetId
            if (widget.transaction.budgetId != null &&
                widget.transaction.budgetId!.isNotEmpty) {
              _selectedBudget = _availableBudgets
                  .where((b) => b.id == widget.transaction.budgetId)
                  .firstOrNull;
            }
          });
        }
      },
      child: BlocListener<TransactionBloc, TransactionState>(
        listener: (context, state) {
          if (state is TransactionLoaded && state.message != null) {
            AppSnackbar.showSuccess(context, message: state.message!);
            Navigator.pop(context);
          }

          if (state is TransactionError) {
            AppSnackbar.showError(context, message: state.message);
          }

          setState(() {
            _isLoading = state is TransactionLoading;
          });
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Transaction Type
                _buildSectionTitle('Transaction Type'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildTypeButton(
                        TransactionType.expense,
                        'Expense',
                        LucideIcons.minusCircle,
                        AppColors.error,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildTypeButton(
                        TransactionType.income,
                        'Income',
                        LucideIcons.plusCircle,
                        AppColors.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Title
                _buildSectionTitle('Title', icon: LucideIcons.type),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: 'Enter transaction title',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Description
                _buildSectionTitle('Description', icon: LucideIcons.fileText),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    hintText: 'Enter description (optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                // Amount
                _buildSectionTitle('Amount', icon: LucideIcons.dollarSign),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Enter amount',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 14, right: 4),
                      child: Align(
                        widthFactor: 1,
                        child: Text(
                          CurrencyService().symbol,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                    prefixIconConstraints:
                        const BoxConstraints(minWidth: 0, minHeight: 0),
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
                const SizedBox(height: 16),

                // Category
                _buildSectionTitle('Category', icon: LucideIcons.tag),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: (_selectedType == TransactionType.income
                          ? _incomeCategories
                          : _expenseCategories)
                      .map((category) => DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Date
                _buildSectionTitle('Date'),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _selectDate,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: colorScheme.outline),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(LucideIcons.calendar,
                            color: colorScheme.onBackground),
                        const SizedBox(width: 12),
                        Text(
                          formatShortDate(_selectedDate),
                          style: TextStyle(
                              fontSize: 16, color: colorScheme.onBackground),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Budget Selector
                _buildBudgetSelector(),
                const SizedBox(height: 24),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveTransaction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator(
                            color: Theme.of(context).colorScheme.onPrimary)
                        : Text(
                            'Update Transaction',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                  ),
                ),
                // Bottom padding for safe area
                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, {IconData? icon}) {
    if (icon != null) return FieldLabel(icon: icon, label: title);
    final colorScheme = Theme.of(context).colorScheme;
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: colorScheme.onBackground,
      ),
    );
  }

  Widget _buildTypeButton(
    TransactionType type,
    String label,
    IconData icon,
    Color color,
  ) {
    final isSelected = _selectedType == type;

    return InkWell(
      onTap: () {
        if (isSelected) return;
        AppHaptics.selection();
        setState(() {
          _selectedType = type;
          // Reset category when changing type
          _selectedCategory = type == TransactionType.income
              ? _incomeCategories.first
              : _expenseCategories.first;
        });
      },
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.standard,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
          border: Border.all(
            color: isSelected ? color : Theme.of(context).colorScheme.onSurface,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color:
                  isSelected ? color : Theme.of(context).colorScheme.onSurface,
              size: 26,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? color
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Widget _buildBudgetSelector() {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 2,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outline,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Budget',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            if (_availableBudgets.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colorScheme.error.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.alertTriangle, color: colorScheme.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No budgets available. Create a budget first!',
                        style: TextStyle(color: colorScheme.error),
                      ),
                    ),
                  ],
                ),
              )
            else
              DropdownButtonFormField<Budget>(
                initialValue: _selectedBudget,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  hintText: 'Select a budget',
                ),
                items: _availableBudgets.map((budget) {
                  final remainingAmount = budget.remaining;
                  final isOverBudget = remainingAmount < 0;

                  return DropdownMenuItem<Budget>(
                    value: budget,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            budget.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${budget.category} • ${CurrencyService().formatAmount(remainingAmount)} remaining',
                            style: TextStyle(
                              fontSize: 11,
                              color: isOverBudget
                                  ? colorScheme.error
                                  : colorScheme.onSurface.withOpacity(0.7),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (budget) {
                  setState(() {
                    _selectedBudget = budget;
                    // Don't auto-change category - let user choose independently
                  });
                },
              ),
            if (_selectedBudget != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _selectedBudget!.isOverBudget
                          ? LucideIcons.alertTriangle
                          : LucideIcons.info,
                      color: _selectedBudget!.isOverBudget
                          ? colorScheme.error
                          : colorScheme.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedBudget!.isOverBudget
                            ? 'Budget is over by ${CurrencyService().formatAmount(-_selectedBudget!.remaining)}'
                            : 'Remaining: ${CurrencyService().formatAmount(_selectedBudget!.remaining)} of ${CurrencyService().formatAmount(_selectedBudget!.totalAvailable)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: _selectedBudget!.isOverBudget
                              ? colorScheme.error
                              : colorScheme.onSurface.withOpacity(0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _saveTransaction() {
    if (_formKey.currentState!.validate()) {
      final user = context.read<AuthBloc>().state;
      if (user is AuthAuthenticated) {
        final updatedTransaction = widget.transaction.copyWith(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          amount: double.parse(_amountController.text),
          type: _selectedType,
          category: _selectedCategory,
          budgetId: _selectedBudget?.id, // Include budgetId in update
          date: _selectedDate,
        );

        context
            .read<TransactionBloc>()
            .add(UpdateTransaction(updatedTransaction));
      }
    } else {
      AppHaptics.error();
    }
  }
}
