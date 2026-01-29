import 'package:home_widget/home_widget.dart';
import 'currency_service.dart';
import '../../features/transaction/transaction_bloc.dart';
import '../../features/income/income_bloc.dart';
import '../../core/models/transaction_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class WidgetService {
  static const String _androidWidgetName = 'BalanceWidgetProvider';

  static Future<void> updateBalanceWidget({
    required double balance,
    required double income,
    required double expenses,
    required int transactionCount,
  }) async {
    try {
      final currencyService = CurrencyService();
      await currencyService.ensureInitialized();
      
      await HomeWidget.saveWidgetData<String>('balance', currencyService.formatAmount(balance));
      await HomeWidget.saveWidgetData<String>('income', currencyService.formatAmount(income));
      await HomeWidget.saveWidgetData<String>('expenses', currencyService.formatAmount(expenses));
      await HomeWidget.saveWidgetData<int>('transactionCount', transactionCount);
      
      // Update all 3 widgets
      await HomeWidget.updateWidget(
        name: 'BalanceWidgetProvider',
        androidName: 'BalanceWidgetProvider',
      );
      await HomeWidget.updateWidget(
        name: 'SummaryWidgetProvider',
        androidName: 'SummaryWidgetProvider',
      );
      await HomeWidget.updateWidget(
        name: 'ActionWidgetProvider',
        androidName: 'ActionWidgetProvider',
      );
      
      print('✅ All widgets updated: Balance: $balance, Transactions: $transactionCount');
    } catch (e) {
      print('❌ Error updating widget: $e');
    }
  }

  static void refreshWidgets(BuildContext context) {
    try {
      final transactionState = context.read<TransactionBloc>().state;
      final incomeState = context.read<IncomeBloc>().state;

      if (transactionState is TransactionLoaded && incomeState is IncomeLoaded) {
        final expenses = transactionState.transactions.where((t) => t.type == TransactionType.expense).toList();
        final totalExpenses = expenses.fold(0.0, (sum, t) => sum + t.amount);
        final totalIncome = incomeState.incomes.fold(0.0, (sum, i) => sum + i.amount);
        final balance = totalIncome - totalExpenses;

        updateBalanceWidget(
          balance: balance,
          income: totalIncome,
          expenses: totalExpenses,
          transactionCount: transactionState.transactions.length,
        );
      }
    } catch (e) {
      print('❌ Error refreshing widgets: $e');
    }
  }
}
