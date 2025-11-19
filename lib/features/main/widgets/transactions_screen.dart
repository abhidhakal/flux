import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/models/transaction_model.dart';
import '../../../core/services/currency_service.dart';
import '../../auth/auth_bloc.dart';
import '../../transaction/transaction_bloc.dart';
import '../../transaction/screens/edit_transaction_screen.dart';
import '../../transaction/screens/add_transaction_screen.dart';
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
      appBar: AppBar(
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
      body: BlocListener<TransactionBloc, TransactionState>(
        listener: (context, state) {
          if (state is TransactionSuccess) {
            AppSnackbar.showSuccess(context, message: state.message);
          }
          
          if (state is TransactionError) {
            AppSnackbar.showError(context, message: state.message);
          }
        },
        child: BlocBuilder<TransactionBloc, TransactionState>(
          builder: (context, state) {
            if (state is TransactionLoading) {
              return _buildLoadingState();
            }

            if (state is TransactionLoaded) {
              if (state.transactions.isEmpty) {
                return _buildEmptyState();
              }
              
              // Start animations when data is loaded
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _fadeController.forward();
                _slideController.forward();
              });
              
              return FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _buildTransactionsList(state.transactions),
                ),
              );
            }

            if (state is TransactionError) {
              return _buildErrorState(state.message);
            }

            return _buildEmptyState();
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

  Widget _buildTransactionsList(List<Transaction> transactions) {
    // Group transactions by date
    final groupedTransactions = <String, List<Transaction>>{};
    for (final transaction in transactions) {
      final dateKey = _formatDateKey(transaction.date);
      groupedTransactions.putIfAbsent(dateKey, () => []).add(transaction);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedTransactions.length,
      itemBuilder: (context, index) {
        final dateKey = groupedTransactions.keys.elementAt(index);
        final dayTransactions = groupedTransactions[dateKey]!;
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

  Widget _buildTransactionGroup(String dateKey, List<Transaction> transactions) {
    final dayTotal = transactions.fold(0.0, (sum, t) => 
        sum + (t.type == TransactionType.income ? t.amount : -t.amount));

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
        ...transactions.map((transaction) => _buildTransactionCard(transaction)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTransactionCard(Transaction transaction) {
    final isIncome = transaction.type == TransactionType.income;
    
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
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isIncome 
                ? AppColors.success.withValues(alpha: 0.1)
                : AppColors.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            isIncome ? Icons.add_circle_outline_rounded : Icons.remove_circle_outline_outlined,
            color: isIncome ? AppColors.success : AppColors.error,
          ),
        ),
        title: Text(
          transaction.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          transaction.category,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isIncome ? '+' : '-'}${CurrencyService().formatAmount(transaction.amount)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isIncome ? AppColors.success : AppColors.error,
                  ),
                ),
                Text(
                  _formatTime(transaction.date),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => _showDeleteTransactionDialog(transaction),
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              tooltip: 'Delete Transaction',
            ),
          ],
        ),
        onTap: () {
          _showEditTransactionDialog(transaction);
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


  void _showEditTransactionDialog(Transaction transaction) {
    EditTransactionScreen.showEditTransactionPopup(context, transaction);
  }

  void _showDeleteTransactionDialog(Transaction transaction) {
    final transactionBloc = context.read<TransactionBloc>();
    final user = context.read<AuthBloc>().state;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Transaction',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${transaction.title}"? This action cannot be undone.',
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
              if (user is AuthAuthenticated) {
                transactionBloc.add(DeleteTransaction(transaction.id, user.user.id));
              }
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
}
