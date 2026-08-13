import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/constants/categories.dart';
import '../../../core/utils/date_format_utils.dart';
import '../../../core/models/recurring_transaction_model.dart';
import '../../../core/models/transaction_model.dart';
import '../../../core/models/budget_model.dart';
import '../../../core/services/currency_service.dart';
import '../../../core/services/recurring_transaction_service.dart';
import '../../../core/services/transaction_intelligence_service.dart';
import '../../transaction/transaction_bloc.dart';
import '../../auth/auth_bloc.dart';
import '../../budget/budget_bloc.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/field_label.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AddTransactionScreen extends StatefulWidget {
  final TransactionType? initialType;

  const AddTransactionScreen({super.key, this.initialType});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  TransactionType _selectedType = TransactionType.expense;
  String _selectedCategory = 'Food & Dining';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  bool _isEssential = false;
  String? _suggestedCategory;
  bool _categoryWasManuallySelected = false;
  bool _isRecurring = false;
  RecurringTransactionFrequency _recurringFrequency =
      RecurringTransactionFrequency.monthly;
  List<Budget> _availableBudgets = [];
  Budget? _selectedBudget;
  final RecurringTransactionService _recurringTransactionService =
      RecurringTransactionService();
  final TransactionIntelligenceService _intelligence =
      TransactionIntelligenceService();

  late final AnimationController _entranceController;
  late final Animation<double> _entranceFade;
  late final Animation<Offset> _entranceSlide;

  @override
  void initState() {
    super.initState();
    if (widget.initialType != null) {
      _selectedType = widget.initialType!;
      _selectedCategory =
          _selectedType == TransactionType.income ? 'Salary' : 'Food & Dining';
    }
    // Load budgets when screen initializes
    final user = context.read<AuthBloc>().state;
    if (user is AuthAuthenticated) {
      context.read<BudgetBloc>().add(LoadBudgets(user.user.id));
    }

    _entranceController = AnimationController(
      vsync: this,
      duration: AppMotion.slow,
    );
    _entranceFade = CurvedAnimation(
      parent: _entranceController,
      curve: AppMotion.standard,
    );
    _entranceSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: AppMotion.standard,
    ));
    _entranceController.forward();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final saveIconColor = isDark ? Colors.white : colorScheme.onSurface;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Add Transaction'),
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        titleTextStyle: theme.textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _handleSave,
            child: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: saveIconColor),
                  )
                : Text(
                    'Save',
                    style: TextStyle(
                      color: saveIconColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: BlocListener<BudgetBloc, BudgetState>(
        listener: (context, state) {
          if (state is BudgetLoaded) {
            setState(() {
              _availableBudgets =
                  state.budgets.where((budget) => budget.isActive).toList();
              // Auto-select budget if category matches
              if (_selectedBudget == null && _availableBudgets.isNotEmpty) {
                _selectedBudget = _availableBudgets
                    .where((b) =>
                        b.category.toLowerCase() ==
                        _selectedCategory.toLowerCase())
                    .firstOrNull;
              }
            });
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
          child: FadeTransition(
            opacity: _entranceFade,
            child: SlideTransition(
              position: _entranceSlide,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSectionTitle('Transaction Type'),
                      const SizedBox(height: 8),
                      _buildTransactionTypeSelector(),
                      const SizedBox(height: 20),
                      _buildSectionTitle('Title', icon: LucideIcons.type),
                      const SizedBox(height: 8),
                      _buildTitleField(),
                      const SizedBox(height: 20),
                      _buildSectionTitle('Description',
                          icon: LucideIcons.fileText),
                      const SizedBox(height: 8),
                      _buildDescriptionField(),
                      const SizedBox(height: 20),
                      _buildSectionTitle('Amount',
                          icon: LucideIcons.dollarSign),
                      const SizedBox(height: 8),
                      _buildAmountField(),
                      const SizedBox(height: 20),
                      _buildSectionTitle('Category', icon: LucideIcons.tag),
                      const SizedBox(height: 8),
                      _buildCategorySelector(),
                      const SizedBox(height: 20),
                      _buildSectionTitle('Budget'),
                      const SizedBox(height: 8),
                      _buildBudgetSelector(),
                      if (_selectedType == TransactionType.expense) ...[
                        const SizedBox(height: 20),
                        _buildEssentialToggle(),
                      ],
                      const SizedBox(height: 20),
                      _buildRecurringSection(),
                      const SizedBox(height: 20),
                      _buildSectionTitle('Date'),
                      const SizedBox(height: 8),
                      _buildDateSelector(),
                      const SizedBox(height: 32),
                      _buildSaveButton(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionTypeSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildTypeButton(
            TransactionType.expense,
            'Expense',
            LucideIcons.minusCircle,
            AppColors.error,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildTypeButton(
            TransactionType.income,
            'Income',
            LucideIcons.plusCircle,
            AppColors.success,
          ),
        ),
      ],
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
        if (isSelected) return;
        AppHaptics.selection();
        setState(() {
          _selectedType = type;
          // Update category based on type
          if (type == TransactionType.income) {
            _selectedCategory = 'Salary';
          } else {
            _selectedCategory = 'Food & Dining';
          }
          _categoryWasManuallySelected = false;
          _suggestedCategory = null;
        });
      },
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.standard,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.1)
              : Theme.of(context).colorScheme.surface,
          border: Border.all(
            color: isSelected
                ? color
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            width: 2,
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
      onChanged: (_) => _updateCategorySuggestion(),
      decoration: InputDecoration(
        hintText: 'Enter transaction title',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
      onChanged: (_) => _updateCategorySuggestion(),
      decoration: InputDecoration(
        hintText: 'Enter description (optional)',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      maxLines: 2,
    );
  }

  void _updateCategorySuggestion() {
    if (_categoryWasManuallySelected) return;
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    if (title.isEmpty && description.isEmpty) {
      if (_suggestedCategory != null && mounted) {
        setState(() => _suggestedCategory = null);
      }
      return;
    }

    final suggestion = _intelligence.suggestCategory(
      title: title,
      description: description,
    );
    final validCategories = _selectedType == TransactionType.income
        ? AppCategories.incomeCategories
        : AppCategories.expenseCategories;
    if (!validCategories.contains(suggestion)) return;

    if (mounted) {
      setState(() {
        _suggestedCategory = suggestion;
        _selectedCategory = suggestion;
      });
    }
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        hintText: 'Enter amount',
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 14, right: 4),
          child: Align(
            widthFactor: 1,
            child: Text(
              CurrencyService().symbol,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: _selectedCategory,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          items: categories.map((category) {
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
              _categoryWasManuallySelected = true;
              _suggestedCategory = null;
            });
          },
        ),
        if (_suggestedCategory != null && !_categoryWasManuallySelected)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              'Suggested from your description: $_suggestedCategory',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDateSelector() {
    return InkWell(
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
          border: Border.all(
              color:
                  Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              LucideIcons.calendar,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              formatShortDate(_selectedDate),
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface,
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
        backgroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            )
          : const Text(
              'Save Transaction',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
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

  Widget _buildBudgetSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                const Icon(LucideIcons.alertTriangle, color: AppColors.error),
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
            initialValue: _selectedBudget,
            isExpanded: true,
            decoration: InputDecoration(
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              hintText: 'Select a budget (Optional)',
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              suffixIcon: _selectedBudget != null
                  ? IconButton(
                      icon: const Icon(LucideIcons.x, size: 18),
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
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.7),
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
            validator: (value) => null,
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
                  _selectedBudget!.isOverBudget
                      ? LucideIcons.alertTriangle
                      : LucideIcons.info,
                  color: _selectedBudget!.isOverBudget
                      ? AppColors.error
                      : AppColors.primary,
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
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.8),
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
    );
  }

  Widget _buildEssentialToggle() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SwitchListTile(
        title: Text(
          'Mark as Essential',
          style: TextStyle(
              fontWeight: FontWeight.w600, color: colorScheme.onSurface),
        ),
        subtitle: Text(
          'Is this a "Need" (Housing, Bills) or a "Want"?',
          style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6)),
        ),
        value: _isEssential,
        activeThumbColor: AppColors.primary,
        onChanged: (value) => setState(() => _isEssential = value),
        secondary: Icon(
          _isEssential ? LucideIcons.clipboardCheck : LucideIcons.shoppingBag,
          color: _isEssential ? AppColors.success : AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildRecurringSection() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          SwitchListTile(
            title: Text(
              'Repeat this transaction',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            subtitle: Text(
              'Automatically create future ${_selectedType == TransactionType.income ? 'income' : 'expense'} entries.',
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            value: _isRecurring,
            activeThumbColor: AppColors.primary,
            onChanged: (value) => setState(() => _isRecurring = value),
          ),
          if (_isRecurring)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: DropdownButtonFormField<RecurringTransactionFrequency>(
                initialValue: _recurringFrequency,
                decoration: InputDecoration(
                  labelText: 'Frequency',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: RecurringTransactionFrequency.values.map((frequency) {
                  return DropdownMenuItem(
                    value: frequency,
                    child: Text(frequency.label),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _recurringFrequency = value);
                  }
                },
              ),
            ),
        ],
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
          AppHaptics.error();
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
    } else {
      AppHaptics.error();
    }
  }

  void _createTransaction() {
    final user = context.read<AuthBloc>().state;
    if (user is AuthAuthenticated) {
      final now = DateTime.now();
      final transaction = Transaction(
        id: '',
        userId: user.user.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        amount: double.parse(_amountController.text),
        type: _selectedType,
        category: _selectedCategory,
        budgetId: _selectedBudget?.id,
        isEssential:
            _selectedType == TransactionType.expense ? _isEssential : false,
        date: _selectedDate,
        createdAt: now,
      );

      final recurringTransaction = _isRecurring
          ? RecurringTransaction(
              id: '',
              userId: user.user.id,
              title: transaction.title,
              description: transaction.description,
              amount: transaction.amount,
              type: transaction.type,
              category: transaction.category,
              budgetId: transaction.budgetId,
              isEssential: transaction.isEssential,
              frequency: _recurringFrequency,
              startDate: _selectedDate,
              nextRunAt: _recurringTransactionService.calculateInitialNextRunAt(
                _selectedDate,
                _recurringFrequency,
              ),
              createdAt: now,
              updatedAt: now,
            )
          : null;

      context.read<TransactionBloc>().add(
            AddTransaction(
              transaction,
              recurringTransaction: recurringTransaction,
            ),
          );
    }
  }
}
