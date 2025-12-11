import 'package:flutter/material.dart';
import '../../../core/constants/app_theme.dart';
import '../../../shared/widgets/offline_indicator.dart';
import '../widgets/dashboard_screen.dart';
import '../widgets/budgets_screen.dart';
import '../widgets/transactions_screen.dart';
import '../widgets/profile_screen.dart';
import '../../analytics/screens/analytics_dashboard_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../subscription/subscription_bloc.dart';
import '../../subscription/presentation/pages/paywall_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const BudgetsScreen(),
    const TransactionsScreen(),
    const AnalyticsDashboardScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Column(
        children: [
          const OfflineIndicator(),
          Expanded(
            child: _screens[_currentIndex],
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        bottom: true,
        child: Container(
          height: 90,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: colorScheme.outline,
                width: 1,
              ),
            ),
            boxShadow: AppTheme.shadowMedium,
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              if (index == 3) {
                final subscriptionState = context.read<SubscriptionBloc>().state;
                if (subscriptionState is! SubscriptionPremium) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const PaywallScreen(),
                    ),
                  );
                  return;
                }
              }
              setState(() {
                _currentIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            selectedItemColor: colorScheme.primary,
            unselectedItemColor: colorScheme.onSurface.withOpacity(0.6),
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_rounded),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.wallet_rounded),
                label: 'Budgets',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long_rounded),
                label: 'Transactions',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart_rounded),
                label: 'Analytics',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline_rounded),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
