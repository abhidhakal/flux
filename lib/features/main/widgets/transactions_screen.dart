import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/models/transaction_model.dart';
import '../../../core/services/currency_service.dart';
import '../../auth/auth_bloc.dart';
import '../../transaction/transaction_bloc.dart';
import '../../transaction/screens/edit_transaction_screen.dart';
import '../../transaction/screens/add_transaction_screen.dart';
import '../../income/screens/edit_income_screen.dart';
import '../../income/income_bloc.dart';
import '../../../core/models/income_model.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/page_transitions.dart';
import '../../../shared/widgets/animated_button.dart';
import '../../../shared/widgets/skeleton_components.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    // Initialize animations
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    // Load transactions when screen initializes
    final user = context.read<AuthBloc>().state;
    if (user is AuthAuthenticated) {
      context.read<TransactionBloc>().add(LoadTransactions(user.user.id));
      context.read<IncomeBloc>().add(LoadIncome(user.user.id));
    }
  }

  Future<void> _onRefresh() async {
    final user = context.read<AuthBloc>().state;
    if (user is AuthAuthenticated) {
      context.read<TransactionBloc>().add(LoadTransactions(user.user.id));
      context.read<IncomeBloc>().add(LoadIncome(user.user.id));
      // Small delay to show the indicator
      await Future.delayed(const Duration(milliseconds: 800));
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: _isSelectionMode 
          ? AppBar(
              backgroundColor: colorScheme.background,
              foregroundColor: colorScheme.onBackground,
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _isSelectionMode = false;
                    _selectedIds.clear();
                  });
                },
              ),
              title: Text('${_selectedIds.length} Selected'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _selectedIds.isEmpty ? null : _deleteSelectedItems,
                ),
              ],
            )
          : AppBar(
              automaticallyImplyLeading: false,
              title: const Text('Transactions'),
              centerTitle: false,
        backgroundColor: colorScheme.background,
        foregroundColor: colorScheme.onBackground,
        iconTheme: IconThemeData(color: colorScheme.onBackground),
        titleTextStyle: TextStyle(
          color: colorScheme.onBackground,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        actions: [
          AnimatedIconButton(
            icon: Icon(Icons.add_rounded, color: colorScheme.onBackground),
            onPressed: () {
              context.pushSmooth(
                const AddTransactionScreen(),
                transitionType: PageTransitionType.slideFromBottom,
              );
            },
            tooltip: 'Add Transaction',
          ),
        ],
      ),

      body: MultiBlocListener(
        listeners: [
          BlocListener<IncomeBloc, IncomeState>(
            listener: (context, state) {
              if (state is IncomeSuccess) {
                AppSnackbar.showSuccess(context, message: state.message);
              }
              if (state is IncomeError) {
                AppSnackbar.showError(context, message: state.message);
              }
            },
          ),
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
          child: Builder(
            builder: (context) {
              final transactionState = context.watch<TransactionBloc>().state;
              final incomeState = context.watch<IncomeBloc>().state;

              if (transactionState is TransactionLoading || incomeState is IncomeLoading) {
                return _buildLoadingState();
              }

              final transactions = (transactionState is TransactionLoaded) 
                  ? transactionState.transactions 
                  : <Transaction>[];
                  
              final incomes = (incomeState is IncomeLoaded)
                  ? incomeState.incomes
                  : <Income>[];

              if (transactionState is TransactionLoaded || incomeState is IncomeLoaded) {
                 final allItems = <dynamic>[...transactions, ...incomes];
                 
                 if (allItems.isEmpty) {
                   return RefreshIndicator(
                     onRefresh: _onRefresh,
                     child: SingleChildScrollView(
                       physics: const AlwaysScrollableScrollPhysics(),
                       child: Container(
                         constraints: BoxConstraints(
                           minHeight: MediaQuery.of(context).size.height * 0.7,
                         ),
                         child: _buildEmptyState(),
                       ),
                     ),
                   );
                 }

                 // Start animations
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_fadeController.status != AnimationStatus.completed) {
                    _fadeController.forward();
                    _slideController.forward();
                  }
                });

                 return RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: _buildTransactionsList(allItems),
                    ),
                  ),
                );
              }

              if (transactionState is TransactionError) {
                 return RefreshIndicator(
                   onRefresh: _onRefresh,
                   child: SingleChildScrollView(
                     physics: const AlwaysScrollableScrollPhysics(),
                     child: Container(
                       constraints: BoxConstraints(
                         minHeight: MediaQuery.of(context).size.height * 0.7,
                       ),
                       child: _buildErrorState(transactionState.message),
                     ),
                   ),
                 );
              }
               if (incomeState is IncomeError) {
                 return RefreshIndicator(
                   onRefresh: _onRefresh,
                   child: SingleChildScrollView(
                     physics: const AlwaysScrollableScrollPhysics(),
                     child: Container(
                       constraints: BoxConstraints(
                         minHeight: MediaQuery.of(context).size.height * 0.7,
                       ),
                       child: _buildErrorState(incomeState.message),
                     ),
                   ),
                 );
              }

              return RefreshIndicator(
                onRefresh: _onRefresh,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Container(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height * 0.7,
                    ),
                    child: _buildEmptyState(),
                  ),
                ),
              );
            },
          ),
        ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 8, // Show 8 skeleton items
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: SkeletonComponents.transactionListItem(context: context),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.receipt_long,
            size: 64,
            color: AppColors.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'No Transactions Yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first transaction to start tracking your finances',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddTransactionScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Transaction'),
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
            'Error Loading Transactions',
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
                context.read<TransactionBloc>().add(LoadTransactions(user.user.id));
              }
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList(List<dynamic> items) {
    // Group transactions by date
    final groupedItems = <String, List<dynamic>>{};
    
    // Sort items by date descending
    items.sort((a, b) {
      final dateA = a is Transaction ? a.date : (a as Income).date;
      final dateB = b is Transaction ? b.date : (b as Income).date;
      return dateB.compareTo(dateA);
    });

    for (final item in items) {
      final date = item is Transaction ? item.date : (item as Income).date;
      final dateKey = _formatDateKey(date);
      groupedItems.putIfAbsent(dateKey, () => []).add(item);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // Added bottom padding
      itemCount: groupedItems.length,
      itemBuilder: (context, index) {
        final dateKey = groupedItems.keys.elementAt(index);
        final dayTransactions = groupedItems[dateKey]!;
        return AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - _fadeAnimation.value)),
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: _buildTransactionGroup(dateKey, dayTransactions),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTransactionGroup(String dateKey, List<dynamic> items) {
    final dayTotal = items.fold(0.0, (sum, item) {
      final amount = item is Income ? item.amount : (item as Transaction).amount;
      final type = item is Income ? TransactionType.income : (item as Transaction).type;
      return sum + (type == TransactionType.income ? amount : -amount);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateKey,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onBackground,
                ),
              ),
              Text(
                '${dayTotal >= 0 ? '+' : ''}${CurrencyService().formatAmount(dayTotal)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: dayTotal >= 0 ? AppColors.success : AppColors.error,
                ),
              ),
            ],
          ),
        ),
        ...items.map((item) => _buildTransactionCard(item)),
        const SizedBox(height: 16),
      ],
    );
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _deleteSelectedItems() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Selected?'),
        content: Text('Are you sure you want to delete ${_selectedIds.length} items?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final user = context.read<AuthBloc>().state;
      if (user is AuthAuthenticated) {
        // Get current data to ID the items
        final transactionState = context.read<TransactionBloc>().state;
        final incomeState = context.read<IncomeBloc>().state;
        
        final transactions = (transactionState is TransactionLoaded) ? transactionState.transactions : <Transaction>[];
        final incomes = (incomeState is IncomeLoaded) ? incomeState.incomes : <Income>[];
        final allItems = <dynamic>[...transactions, ...incomes];

        for (final id in _selectedIds) {
          final item = allItems.firstWhere((e) => (e is Transaction ? e.id : (e as Income).id) == id, orElse: () => null);
          if (item != null) {
            if (item is Income) {
              context.read<IncomeBloc>().add(DeleteIncome(id, user.user.id));
            } else if (item is Transaction) {
              context.read<TransactionBloc>().add(DeleteTransaction(id, user.user.id));
            }
          }
        }
        
        setState(() {
          _isSelectionMode = false;
          _selectedIds.clear();
        });
      }
    }
  }

  Widget _buildTransactionCard(dynamic item) {
    final isIncome = item is Income;
    final title = item is Income ? item.category : (item as Transaction).title;
    final subtitle = item is Income ? (item.notes ?? '') : (item as Transaction).category;
    final amount = item is Income ? item.amount : (item as Transaction).amount;
    final date = item is Income ? item.date : (item as Transaction).date;
    final id = item is Income ? item.id : (item as Transaction).id;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radius12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline,
          width: 1,
        ),
      ),
      child: ListTile(
        leading: _isSelectionMode 
            ? Checkbox(
                value: _selectedIds.contains(id),
                onChanged: (value) => _toggleSelection(id),
                shape: const CircleBorder(),
              )
            : Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isIncome 
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  isIncome ? Icons.add_circle_outline_rounded : Icons.remove_circle_outline_rounded,
                  color: isIncome ? AppColors.success : AppColors.error,
                ),
              ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        trailing: _isSelectionMode
            ? null // Hide trailing deleted/amount info in selection mode for cleaner look, or maybe just delete icon
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${isIncome ? '+' : '-'}${CurrencyService().formatAmount(amount)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isIncome ? AppColors.success : AppColors.error,
                        ),
                      ),
                      Text(
                        _formatTime(date),
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
        onTap: () {
          if (_isSelectionMode) {
            _toggleSelection(id);
          } else {
            _showEditDialog(item);
          }
        },
        onLongPress: () {
          if (!_isSelectionMode) {
            setState(() {
              _isSelectionMode = true;
              _selectedIds.add(id);
            });
          }
        },
      ),
    );
  }

  String _formatDateKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final transactionDate = DateTime(date.year, date.month, date.day);

    if (transactionDate == today) {
      return 'Today';
    } else if (transactionDate == yesterday) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }


  void _showEditDialog(dynamic item) {
    if (item is Transaction) {
       EditTransactionScreen.showEditTransactionPopup(context, item);
    } else if (item is Income) {
       EditIncomeScreen.show(context, item);
    }
  }
}
