import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/constants/categories.dart';
import '../../../core/models/budget_model.dart';
import '../../../core/services/currency_service.dart';
import '../../../shared/widgets/skeleton_components.dart';
import '../../../core/widgets/app_banner_ad.dart';
import '../../auth/auth_bloc.dart';
import '../../budget/budget_bloc.dart';
import '../../transaction/transaction_bloc.dart';
import '../../../shared/widgets/app_snackbar.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Budgets'),
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
            icon: Icon(Icons.add_rounded, color: colorScheme.onBackground),
            onPressed: () {
              _showCreateBudgetDialog();
            },
          ),
        ],
      ),
      body: BlocListener<BudgetBloc, BudgetState>(
        listener: (context, state) {
          if (state is BudgetSuccess) {
            AppSnackbar.showSuccess(context, message: state.message);
            // Reload budgets after successful operation
            final user = context.read<AuthBloc>().state;
            if (user is AuthAuthenticated) {
              context.read<BudgetBloc>().add(LoadBudgets(user.user.id));
            }
          }
          
          if (state is BudgetError) {
            AppSnackbar.showError(context, message: state.message);
          }
        },
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: BlocBuilder<BudgetBloc, BudgetState>(
            builder: (context, state) {
              if (state is BudgetLoading) {
                return _buildBudgetsSkeleton();
              }

              if (state is BudgetLoaded) {
                if (state.budgets.isEmpty) {
                  return _buildEmptyState();
                }
                return _buildBudgetsList(state.budgets);
              }

              if (state is BudgetError) {
                return _buildErrorState(state.message);
              }

              return _buildEmptyState();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.account_balance_wallet,
            size: 64,
            color: AppColors.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'No Budgets Yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first budget to start tracking your spending',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showCreateBudgetDialog,
            icon: const Icon(Icons.add),
            label: const Text('Create Budget'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textInverse,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Error Loading Budgets',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              final user = context.read<AuthBloc>().state;
              if (user is AuthAuthenticated) {
                context.read<BudgetBloc>().add(LoadBudgets(user.user.id));
              }
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetsList(List<Budget> budgets) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 120, left: 16, right: 16, top: 16),
      itemCount: budgets.length + 3, // +1 for overview cards, +1 for heading, +1 for Ad
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildOverviewCards(budgets);
        } else if (index == 1) {
          return _buildBudgetsHeading();
        } else if (index == budgets.length + 2) {
          return const Padding(
            padding: EdgeInsets.only(top: 24),
            child: AppBannerAd(),
          );
        }
        final budget = budgets[index - 2];
        return _buildBudgetCard(budget);
      },
    );
  }

  Widget _buildBudgetsHeading() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 16),
      child: Text(
        'Your Budgets',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: colorScheme.onBackground,
        ),
      ),
    );
  }

  Widget _buildOverviewCards(List<Budget> budgets) {
    final totalBudgetAmount = budgets.fold<double>(0, (sum, budget) => sum + budget.amount);
    final totalSpentAmount = budgets.fold<double>(0, (sum, budget) => sum + budget.spent);
    final totalRemainingAmount = totalBudgetAmount - totalSpentAmount;
    final utilizationPercentage = totalBudgetAmount > 0 ? (totalSpentAmount / totalBudgetAmount) * 100 : 0.0;
    
    return Column(
      children: [
        // Total Budgets Count Card
        _buildOverviewCard(
          title: 'Total Budgets',
          value: budgets.length.toString(),
          subtitle: 'Active budgets',
          icon: Icons.wallet_rounded,
          color: AppColors.primary,
        ),
        const SizedBox(height: 12),
        
        // Budget Utilization Card
        _buildProgressCard(
          title: 'Budget Utilization',
          spent: totalSpentAmount,
          total: totalBudgetAmount,
          remaining: totalRemainingAmount,
          percentage: utilizationPercentage,
        ),
        const SizedBox(height: 12),
        
        // Total Spending Card
        _buildOverviewCard(
          title: 'Total Spending',
          value: CurrencyService().formatAmount(totalSpentAmount),
          subtitle: 'This month',
          icon: Icons.trending_down_rounded,
          color: AppColors.error,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildOverviewCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Card(
      elevation: 2,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outline, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard({
    required String title,
    required double spent,
    required double total,
    required double remaining,
    required double percentage,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    Color progressColor;
    if (percentage >= 90) {
      progressColor = AppColors.error;
    } else if (percentage >= 75) {
      progressColor = AppColors.warning;
    } else {
      progressColor = AppColors.success;
    }
    
    return Card(
      elevation: 2,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outline, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: progressColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.pie_chart_rounded,
                    color: progressColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Progress bar
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: colorScheme.outline.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: (percentage / 100).clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: progressColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Amount details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Spent',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    Text(
                      CurrencyService().formatAmount(spent),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Remaining',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    Text(
                      CurrencyService().formatAmount(remaining),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetCard(Budget budget) {
    final spent = budget.spent;
    final total = budget.totalAvailable;
    final percentage = budget.progressPercentage;
    final isOverBudget = budget.isOverBudget;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Determine card color based on budget status
    Color cardColor;
    Color borderColor;
    if (isOverBudget) {
      cardColor = AppColors.error.withOpacity(0.05);
      borderColor = AppColors.error.withOpacity(0.2);
    } else if (percentage > 80) {
      cardColor = AppColors.warning.withOpacity(0.05);
      borderColor = AppColors.warning.withOpacity(0.2);
    } else {
      cardColor = AppColors.primary.withOpacity(0.05);
      borderColor = AppColors.primary.withOpacity(0.2);
    }

    return InkWell(
      onTap: () => _showEditBudgetDialog(budget),
      borderRadius: BorderRadius.circular(AppTheme.radius16),
      child: Card(
        margin: EdgeInsets.zero, // Card margin handled by ListView separator
        elevation: 0,
        color: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radius16),
          side: BorderSide(
            color: borderColor,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with icon and title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacing8),
                    decoration: BoxDecoration(
                      color: isOverBudget 
                          ? AppColors.error.withValues(alpha: 0.1)
                          : percentage > 80 
                              ? AppColors.warning.withValues(alpha: 0.1)
                              : AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radius8),
                    ),
                    child: Icon(
                      isOverBudget 
                          ? Icons.warning
                          : percentage > 80 
                              ? Icons.trending_up_rounded
                              : Icons.wallet_rounded,
                      color: isOverBudget 
                          ? AppColors.error
                          : percentage > 80 
                              ? AppColors.warning
                              : AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          budget.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          '${budget.category} • ${budget.period.name.toUpperCase()}',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _showDeleteBudgetDialog(budget),
                    icon: const Icon(Icons.delete_outline, color: AppColors.error),
                    tooltip: 'Delete Budget',
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacing8),
              // Amount row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${CurrencyService().formatAmount(spent)} / ${CurrencyService().formatAmount(total)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isOverBudget ? AppColors.error : colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: (percentage / 100).clamp(0.0, 1.0),
                backgroundColor: colorScheme.outline.withValues(alpha: 0.3),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isOverBudget ? AppColors.error : AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${percentage.toStringAsFixed(1)}% used',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isOverBudget ? AppColors.error : colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                  Text(
                    '${CurrencyService().formatAmount(total - spent)} remaining',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              if (isOverBudget)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Over budget by ${CurrencyService().formatAmount(spent - total)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              if (budget.hasRollover)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Includes ${CurrencyService().formatAmount(budget.rolloverAmount)} rollover',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.success,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateBudgetDialog() {
    final nameController = TextEditingController();
    final categoryController = TextEditingController();
    final amountController = TextEditingController();
    BudgetPeriod selectedPeriod = BudgetPeriod.monthly;
    bool enableRollover = false;
    String? selectedCategory;

    // Get user outside the dialog context
    final user = context.read<AuthBloc>().state;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            'Create Budget',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Budget Name',
                    hintText: 'e.g., Monthly Food Budget, Weekly Entertainment',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: AppCategories.expenseCategories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCategory = value;
                      categoryController.text = value ?? '';
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a category';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  decoration: InputDecoration(
                    labelText: 'Budget Amount',
                    hintText: 'e.g., 500',
                    prefixText: CurrencyService().symbol,
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<BudgetPeriod>(
                  initialValue: selectedPeriod,
                  decoration: const InputDecoration(
                    labelText: 'Budget Period',
                  ),
                  items: BudgetPeriod.values.map((period) {
                    return DropdownMenuItem(
                      value: period,
                      child: Text(period.name.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedPeriod = value ?? BudgetPeriod.monthly;
                    });
                  },
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: Text(
                    'Enable Rollover',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    'Unused budget carries over to next period',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  value: enableRollover,
                  onChanged: (value) {
                    setState(() {
                      enableRollover = value ?? false;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty && 
                    selectedCategory != null &&
                    amountController.text.isNotEmpty) {
                  if (user is AuthAuthenticated) {
                    final now = DateTime.now();
                    final startDate = _getStartDate(now, selectedPeriod);
                    final endDate = _getEndDate(startDate, selectedPeriod);
                    
                    final budget = Budget(
                      id: '',  // Will be generated by service
                      userId: user.user.id,
                      name: nameController.text,
                      amount: double.tryParse(amountController.text) ?? 0,
                      period: selectedPeriod,
                      category: selectedCategory!,
                      startDate: startDate,
                      endDate: endDate,
                      createdAt: now,
                      enableRollover: enableRollover,
                    );
                    
                    // Use the parent context, not the dialog context
                    Navigator.of(dialogContext).pop();
                    this.context.read<BudgetBloc>().add(CreateBudget(budget));
                    
                    // Also reload transactions to show the new income
                    this.context.read<TransactionBloc>().add(LoadTransactions(user.user.id));
                  }
                } else {
                  Navigator.of(dialogContext).pop();
                }
              },
              child: Text(
                'Create',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditBudgetDialog(Budget budget) {
    final nameController = TextEditingController(text: budget.name);
    final amountController = TextEditingController(text: budget.amount.toString());
    BudgetPeriod selectedPeriod = budget.period;
    bool enableRollover = budget.enableRollover;
    bool isActive = budget.isActive;
    String? selectedCategory = budget.category;

    // Get user outside the dialog context
    final user = context.read<AuthBloc>().state;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            'Edit Budget',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Budget Name',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: AppCategories.expenseCategories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCategory = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  decoration: InputDecoration(
                    labelText: 'Budget Amount',
                    prefixText: CurrencyService().symbol,
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<BudgetPeriod>(
                  initialValue: selectedPeriod,
                  decoration: const InputDecoration(
                    labelText: 'Budget Period',
                  ),
                  items: BudgetPeriod.values.map((period) {
                    return DropdownMenuItem(
                      value: period,
                      child: Text(period.name.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedPeriod = value ?? BudgetPeriod.monthly;
                    });
                  },
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: Text(
                    'Is Active',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    'Inactive budgets are hidden from most lists',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  value: isActive,
                  onChanged: (value) {
                    setState(() {
                      isActive = value ?? false;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                CheckboxListTile(
                  title: Text(
                    'Enable Rollover',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    'Unused budget carries over to next period',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  value: enableRollover,
                  onChanged: (value) {
                    setState(() {
                      enableRollover = value ?? false;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty && 
                    selectedCategory != null &&
                    amountController.text.isNotEmpty) {
                  if (user is AuthAuthenticated) {
                    final updatedBudget = budget.copyWith(
                      name: nameController.text.trim(),
                      amount: double.tryParse(amountController.text) ?? 0,
                      period: selectedPeriod,
                      category: selectedCategory!,
                      enableRollover: enableRollover,
                      isActive: isActive,
                    );
                    
                    Navigator.of(dialogContext).pop();
                    this.context.read<BudgetBloc>().add(UpdateBudget(updatedBudget));
                  }
                }
              },
              child: Text(
                'Save Changes',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  DateTime _getStartDate(DateTime now, BudgetPeriod period) {
    switch (period) {
      case BudgetPeriod.daily:
        return DateTime(now.year, now.month, now.day);
      case BudgetPeriod.weekly:
        // Start from Monday
        final weekday = now.weekday;
        return DateTime(now.year, now.month, now.day - weekday + 1);
      case BudgetPeriod.monthly:
        return DateTime(now.year, now.month, 1);
      case BudgetPeriod.yearly:
        return DateTime(now.year, 1, 1);
    }
  }

  DateTime _getEndDate(DateTime startDate, BudgetPeriod period) {
    switch (period) {
      case BudgetPeriod.daily:
        return DateTime(startDate.year, startDate.month, startDate.day, 23, 59, 59);
      case BudgetPeriod.weekly:
        return startDate.add(const Duration(days: 7)).subtract(const Duration(seconds: 1));
      case BudgetPeriod.monthly:
        return DateTime(startDate.year, startDate.month + 1, 1).subtract(const Duration(seconds: 1));
      case BudgetPeriod.yearly:
        return DateTime(startDate.year + 1, 1, 1).subtract(const Duration(seconds: 1));
    }
  }

  void _showDeleteBudgetDialog(Budget budget) {
    final budgetBloc = context.read<BudgetBloc>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Budget',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${budget.name}"? This action cannot be undone.',
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
              budgetBloc.add(DeleteBudget(budget.id));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(context).colorScheme.onError),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onRefresh() async {
    final user = context.read<AuthBloc>().state;
    final budgetBloc = context.read<BudgetBloc>();
    
    if (user is AuthAuthenticated) {
      // Recalculate budget spent amounts - this will automatically reload budgets when complete
      budgetBloc.add(RecalculateBudgetSpent(user.user.id));
    }
  }

  Widget _buildBudgetsSkeleton() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Overview cards skeleton
        SkeletonComponents.card(
          height: 100,
          children: [
            Row(
              children: [
                SkeletonComponents.circle(size: 48, context: context),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonComponents.textLine(width: 100, height: 14),
                      const SizedBox(height: 4),
                      SkeletonComponents.textLine(width: 80, height: 20),
                      const SizedBox(height: 2),
                      SkeletonComponents.textLine(width: 60, height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ], context: context,
        ),
        const SizedBox(height: 12),
        
        // Progress card skeleton
        SkeletonComponents.card(
          height: 140,
          children: [
            Row(
              children: [
                SkeletonComponents.circle(size: 48, context: context),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonComponents.textLine(width: 120, height: 14),
                      const SizedBox(height: 4),
                      SkeletonComponents.textLine(width: 60, height: 20),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SkeletonComponents.textLine(width: double.infinity, height: 8),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonComponents.textLine(width: 40, height: 12),
                    SkeletonComponents.textLine(width: 60, height: 14),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SkeletonComponents.textLine(width: 50, height: 12),
                    SkeletonComponents.textLine(width: 70, height: 14),
                  ],
                ),
              ],
            ),
          ], context: context,
        ),
        const SizedBox(height: 12),
        
        // Total spending card skeleton
        SkeletonComponents.card(
          height: 100,
          children: [
            Row(
              children: [
                SkeletonComponents.circle(size: 48, context: context),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonComponents.textLine(width: 100, height: 14),
                      const SizedBox(height: 4),
                      SkeletonComponents.textLine(width: 80, height: 20),
                      const SizedBox(height: 2),
                      SkeletonComponents.textLine(width: 60, height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ], context: context,
        ),
        const SizedBox(height: 16),
        
        // Heading skeleton
        SkeletonComponents.textLine(width: 120, height: 20),
        const SizedBox(height: 16),
        
        // Budget cards skeleton
        ...List.generate(3, (index) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: SkeletonComponents.budgetCard(context: context),
        )),
      ],
    );
  }
}
