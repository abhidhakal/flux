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
      extendBody: true,
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
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          child: Container(
            height: 85,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(35),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(35),
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
                showSelectedLabels: true,
                showUnselectedLabels: true,
                selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                elevation: 0,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.dashboard_rounded),
                    activeIcon: Icon(Icons.dashboard_rounded, size: 24),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.wallet_rounded),
                    activeIcon: Icon(Icons.wallet_rounded, size: 24),
                    label: 'Budgets',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.receipt_long_rounded),
                    activeIcon: Icon(Icons.receipt_long_rounded, size: 24),
                    label: 'Transactions',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.bar_chart_rounded),
                    activeIcon: Icon(Icons.bar_chart_rounded, size: 24),
                    label: 'Insights',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person_outline_rounded),
                    activeIcon: Icon(Icons.person_outline_rounded, size: 24),
                    label: 'Profile',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
