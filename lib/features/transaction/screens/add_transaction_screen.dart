import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/constants/categories.dart';
import '../../../core/models/transaction_model.dart';
import '../../../core/models/budget_model.dart';
import '../../../core/services/currency_service.dart';
import '../../transaction/transaction_bloc.dart';

import '../../auth/auth_bloc.dart';
import '../../budget/budget_bloc.dart';
import '../../income/income_bloc.dart';
import '../../../core/models/income_model.dart';
import '../../../core/services/income_service.dart';
import '../../../shared/widgets/app_snackbar.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  
  TransactionType _selectedType = TransactionType.expense;
  String _selectedCategory = 'Food & Dining';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  bool _isEssential = false;
  List<Budget> _availableBudgets = [];
  Budget? _selectedBudget;

  @override
  void initState() {
    super.initState();
    // Load budgets when screen initializes
    final user = context.read<AuthBloc>().state;
    if (user is AuthAuthenticated) {
      context.read<BudgetBloc>().add(LoadBudgets(user.user.id));
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
    
    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: const Text('Add Transaction'),
        centerTitle: false,
        backgroundColor: colorScheme.background,
        foregroundColor: colorScheme.onBackground,
        iconTheme: IconThemeData(color: colorScheme.onBackground),
        titleTextStyle: TextStyle(
          color: colorScheme.onBackground,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.save_rounded, color: colorScheme.primary),
            onPressed: _isLoading ? null : _handleSave,
          ),
        ],
      ),
      body: BlocListener<BudgetBloc, BudgetState>(
        listener: (context, state) {
          if (state is BudgetLoaded) {
            setState(() {
              _availableBudgets = state.budgets
                  .where((budget) => budget.isActive)
                  .toList();
              // Auto-select budget if category matches
              if (_selectedBudget == null && _availableBudgets.isNotEmpty) {
                _selectedBudget = _availableBudgets
                    .where((b) => b.category.toLowerCase() == _selectedCategory.toLowerCase())
                    .firstOrNull;
              }
            });
          }
        },
        child: BlocListener<IncomeBloc, IncomeState>(
          listener: (context, state) {
            if (state is IncomeLoading) {
              setState(() => _isLoading = true);
            } else {
              setState(() => _isLoading = false);
            }

            if (state is IncomeSuccess) {
              AppSnackbar.showSuccess(context, message: state.message);
              Navigator.pop(context);
            }

            if (state is IncomeError) {
              AppSnackbar.showError(context, message: state.message);
            }
          },
          child: BlocListener<TransactionBloc, TransactionState>(
            listener: (context, state) {
              if (state is TransactionLoading) {
                setState(() => _isLoading = true);
              } else {
                setState(() => _isLoading = false);
              }

              if (state is TransactionLoaded && state.message != null) {
                AppSnackbar.showSuccess(context, message: state.message!);
                // Reload budgets to update spent amounts
                final user = context.read<AuthBloc>().state;
                if (user is AuthAuthenticated) {
                  context.read<BudgetBloc>().add(LoadBudgets(user.user.id));
                }
                Navigator.pop(context);
              }

          if (state is TransactionError) {
            AppSnackbar.showError(context, message: state.message);
          }
        },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTransactionTypeSelector(),
                  const SizedBox(height: 24),
                  _buildTitleField(),
                  const SizedBox(height: 16),
                  _buildDescriptionField(),
                  const SizedBox(height: 16),
                  _buildAmountField(),
                  const SizedBox(height: 16),
                  _buildCategorySelector(),
                  const SizedBox(height: 16),
                  const SizedBox(height: 16),
                  _buildBudgetSelector(),
                  const SizedBox(height: 16),
                  if (_selectedType == TransactionType.expense) ...[
                    _buildEssentialToggle(),
                    const SizedBox(height: 16),
                  ],
                  _buildDateSelector(),
                  const SizedBox(height: 24),
                  _buildSaveButton(),
                ],
              ),
            ),
          ),
      ),
    ),
  ),
);
  }

  Widget _buildTransactionTypeSelector() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Transaction Type',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTypeButton(
                    TransactionType.expense,
                    'Expense',
                    Icons.remove_circle_outline,
                    AppColors.error,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTypeButton(
                    TransactionType.income,
                    'Income',
                    Icons.add_circle_outline,
                    AppColors.success,
                  ),
                ),
              ],
            ),
          ],
        ),
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
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
          // Update category based on type
          if (type == TransactionType.income) {
            _selectedCategory = 'Salary';
          } else {
            _selectedCategory = 'Food & Dining';
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Theme.of(context).colorScheme.surface,
          border: Border.all(
            color: isSelected ? color : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : Theme.of(context).colorScheme.onSurface,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Theme.of(context).colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      decoration: InputDecoration(
        labelText: 'Title',
        hintText: 'Enter transaction title',
        prefixIcon: const Icon(Icons.title_rounded),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a title';
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: InputDecoration(
        labelText: 'Description',
        hintText: 'Enter transaction description (optional)',
        prefixIcon: const Icon(Icons.description_rounded),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      maxLines: 2,
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'Amount',
        hintText: 'Enter amount',
        prefixText: CurrencyService().symbol + ' ',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter an amount';
        }
        final amount = double.tryParse(value);
        if (amount == null || amount <= 0) {
          return 'Please enter a valid amount';
        }
        return null;
      },
    );
  }

  Widget _buildCategorySelector() {
    final categories = _selectedType == TransactionType.income
        ? AppCategories.incomeCategories
        : AppCategories.expenseCategories;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
          value: _selectedCategory,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Row(
                    children: [
                      Icon(
                        Icons.category_rounded,
                        color: Color(AppCategories.getColor(category)),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        category,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Date',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 1)),
                );
                if (date != null) {
                  setState(() {
                    _selectedDate = date;
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _handleSave,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.textInverse),
              ),
            )
          : const Text(
              'Save Transaction',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }

  Widget _buildBudgetSelector() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Budget',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
            const SizedBox(height: 12),
            if (_availableBudgets.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: AppColors.error),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'No budgets available. Create a budget first!',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // Navigate to budgets screen
                      },
                      child: Text(
                        'Create Budget',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              DropdownButtonFormField<Budget?>(
                value: _selectedBudget,
                isExpanded: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  hintText: 'Select a budget (Optional)',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  suffixIcon: _selectedBudget != null 
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => setState(() => _selectedBudget = null),
                      )
                    : null,
                ),
                items: [
                  const DropdownMenuItem<Budget?>(
                    value: null,
                    child: Text('No Budget'),
                  ),
                  ..._availableBudgets.map((budget) {
                    return DropdownMenuItem<Budget?>(
                      value: budget,
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 48),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              budget.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Total: ${CurrencyService().formatAmount(budget.amount)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
                selectedItemBuilder: (BuildContext context) {
                  return [
                    const Text('No Budget'),
                    ..._availableBudgets.map((budget) {
                      return Text(
                        budget.name,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      );
                    }),
                  ];
                },
                onChanged: (budget) {
                  setState(() {
                    _selectedBudget = budget;
                  });
                },
                validator: (value) => null, // Optional
              ),
            if (_selectedBudget != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _selectedBudget!.isOverBudget ? Icons.warning : Icons.info_outline,
                      color: _selectedBudget!.isOverBudget ? AppColors.error : AppColors.primary,
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
                          color: _selectedBudget!.isOverBudget ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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


  Widget _buildEssentialToggle() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SwitchListTile(
        title: const Text(
          'Mark as Essential',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: const Text('Is this a "Need" (Housing, Bills) or a "Want"?'),
        value: _isEssential,
        activeColor: AppColors.primary,
        onChanged: (value) {
          setState(() {
            _isEssential = value;
          });
        },
        secondary: Icon(
          _isEssential ? Icons.fact_check_rounded : Icons.shopping_bag_outlined,
          color: _isEssential ? AppColors.success : AppColors.primary,
        ),
      ),
    );
  }

  void _handleSave() {
    if (_formKey.currentState!.validate()) {
      // Budget validation for expenses
      if (_selectedType == TransactionType.expense && _selectedBudget != null) {
        // Check if this expense would exceed the budget
        final expenseAmount = double.parse(_amountController.text);
        final remainingBudget = _selectedBudget!.remaining;
        
        if (expenseAmount > remainingBudget) {
          // Show warning but allow the transaction
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(
                'Budget Warning',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              content: Text(
                'This expense (${CurrencyService().formatAmount(expenseAmount)}) exceeds your remaining budget (${CurrencyService().formatAmount(remainingBudget)}) for ${_selectedBudget!.category}.\n\nDo you want to proceed anyway?',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _createTransaction();
                  },
                  child: Text(
                    'Proceed',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
          );
          return;
        }
      }
      
      _createTransaction();
    }
  }

  void _createTransaction() {
    final user = context.read<AuthBloc>().state;
    if (user is AuthAuthenticated) {
      if (_selectedType == TransactionType.income) {
        final income = Income(
          id: '',
          userId: user.user.id,
          amount: double.parse(_amountController.text),
          date: _selectedDate,
          notes: _descriptionController.text.trim(),
          category: _selectedCategory,
          budgetId: _selectedBudget?.id,
          createdAt: DateTime.now(),
        );
        context.read<IncomeBloc>().add(AddIncome(income));
      } else {
        final transaction = Transaction(
          id: '', 
          userId: user.user.id,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          amount: double.parse(_amountController.text),
          type: TransactionType.expense, // Force expense
          category: _selectedCategory, 
          budgetId: _selectedBudget?.id, 
          isEssential: _isEssential,
          date: _selectedDate,
          createdAt: DateTime.now(),
        );

        context.read<TransactionBloc>().add(AddTransaction(transaction));
      }
    }
  }
  }

