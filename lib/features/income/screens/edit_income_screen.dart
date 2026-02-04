import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/constants/categories.dart';
import '../../../core/models/income_model.dart';
import '../../../core/services/currency_service.dart';
import '../../auth/auth_bloc.dart';
import '../income_bloc.dart';
import '../../../core/models/budget_model.dart';
import '../../budget/budget_bloc.dart';
import '../../../shared/widgets/app_snackbar.dart';

class EditIncomeScreen extends StatefulWidget {
  final Income income;

  const EditIncomeScreen({super.key, required this.income});

  // Static method to show edit popup
  static void show(BuildContext context, Income income) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: EditIncomeScreen(income: income),
      ),
    );
  }

  @override
  State<EditIncomeScreen> createState() => _EditIncomeScreenState();
}

class _EditIncomeScreenState extends State<EditIncomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _selectedCategory = 'Salary';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  List<Budget> _availableBudgets = [];
  Budget? _selectedBudget;

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.income.amount.toString();
    _notesController.text = widget.income.notes ?? '';
    
    // Safety check for category
    _selectedCategory = widget.income.category;
    if (!AppCategories.incomeCategories.contains(_selectedCategory)) {
      if (_selectedCategory == 'Other' && AppCategories.incomeCategories.contains('Other Income')) {
        _selectedCategory = 'Other Income';
      } else if (AppCategories.incomeCategories.contains('Other Income')) {
        _selectedCategory = 'Other Income';
      } else {
        _selectedCategory = AppCategories.incomeCategories.first;
      }
    }
    
    _selectedDate = widget.income.date;
    
    // Load budgets
    final user = context.read<AuthBloc>().state;
    if (user is AuthAuthenticated) {
        context.read<BudgetBloc>().add(LoadBudgets(user.user.id));
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return SafeArea(
      bottom: true,
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.outline.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  'Edit Income',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          // Form
          Expanded(
            child: MultiBlocListener(
              listeners: [
                BlocListener<BudgetBloc, BudgetState>(
                  listener: (context, state) {
                    if (state is BudgetLoaded) {
                      setState(() {
                        _availableBudgets = state.budgets
                            .where((budget) => budget.isActive)
                            .toList();
                        
                        // Set selected budget if income has budgetId
                        if (widget.income.budgetId != null && widget.income.budgetId!.isNotEmpty) {
                          _selectedBudget = _availableBudgets
                              .where((b) => b.id == widget.income.budgetId)
                              .firstOrNull;
                        }
                      });
                    }
                  },
                ),
                BlocListener<IncomeBloc, IncomeState>(
                  listener: (context, state) {
                    if (state is IncomeSuccess) {
                      // Wait for snackbar or close immediately
                      Navigator.pop(context);
                    }
                    
                    if (state is IncomeError) {
                      AppSnackbar.showError(context, message: state.message);
                    }
                    
                    setState(() {
                      _isLoading = state is IncomeLoading;
                    });
                  },
                ),
              ],
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Amount'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Enter amount',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.attach_money_rounded),
                          prefixText: CurrencyService().symbol + ' ',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter an amount';
                          }
                          final amount = double.tryParse(value);
                          if (amount == null || amount <= 0) {
                            return 'Please enter a valid positive amount';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      _buildSectionTitle('Category'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.category_rounded),
                        ),
                        items: AppCategories.incomeCategories.map((category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        )).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

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
                              Icon(Icons.calendar_today_rounded, color: colorScheme.onBackground),
                              const SizedBox(width: 12),
                              Text(
                                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                style: TextStyle(fontSize: 16, color: colorScheme.onBackground),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      _buildBudgetSelector(),
                      const SizedBox(height: 16),

                      _buildSectionTitle('Notes'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _notesController,
                        decoration: InputDecoration(
                          hintText: 'Add notes (optional)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.note_rounded),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveIncome,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoading
                              ? CircularProgressIndicator(color: Theme.of(context).colorScheme.onPrimary)
                              : Text(
                                  'Update Income',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onPrimary,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onBackground,
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

  void _saveIncome() {
    if (_formKey.currentState!.validate()) {
      final updatedIncome = widget.income.copyWith(
        amount: double.parse(_amountController.text),
        category: _selectedCategory,
        date: _selectedDate,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        budgetId: _selectedBudget?.id,
      );
      
      context.read<IncomeBloc>().add(UpdateIncome(updatedIncome));
    }
  }

  Widget _buildBudgetSelector() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Budget'),
        const SizedBox(height: 8),
        DropdownButtonFormField<Budget>(
          value: _selectedBudget,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            hintText: 'Select a budget (Optional)',
            prefixIcon: const Icon(Icons.account_balance_wallet_rounded),
            suffixIcon: _selectedBudget != null 
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () => setState(() => _selectedBudget = null),
                )
              : null,
          ),
          items: [
            if (_availableBudgets.isNotEmpty)
              ..._availableBudgets.map((budget) {
                return DropdownMenuItem<Budget>(
                  value: budget,
                  child: Text(
                    budget.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }),
          ],
          onChanged: (budget) {
            setState(() {
              _selectedBudget = budget;
            });
          },
          // Just simple display, no warning needed for Income (it's good!)
          validator: (value) => null, 
        ),
      ],
    );
  }
}
