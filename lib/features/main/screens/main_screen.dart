import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../shared/widgets/offline_indicator.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../widgets/dashboard_screen.dart';
import '../widgets/budgets_screen.dart';
import '../widgets/transactions_screen.dart';
import '../widgets/profile_screen.dart';
import '../../analytics/screens/analytics_dashboard_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../subscription/subscription_bloc.dart';
import '../../subscription/presentation/pages/paywall_screen.dart';

import '../navigation_cubit.dart';
import '../../../core/widgets/app_banner_ad.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  DateTime? _lastPressedAt;
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
    
    return BlocBuilder<NavigationCubit, NavigationState>(
      builder: (context, navState) {
        return PopScope(
          canPop: false,
          onPopInvoked: (didPop) {
            if (didPop) return;

            final now = DateTime.now();
            final backButtonHasNotBeenPressedOrToastHasExpired =
                _lastPressedAt == null ||
                    now.difference(_lastPressedAt!) > const Duration(seconds: 2);

            if (backButtonHasNotBeenPressedOrToastHasExpired) {
              _lastPressedAt = now;
              AppSnackbar.show(
                context,
                message: 'Swipe again to exit',
                type: AppSnackbarType.info,
              );
            } else {
              SystemNavigator.pop();
            }
          },
          child: Scaffold(
            backgroundColor: colorScheme.background,
          extendBody: true,
          body: Column(
            children: [
              const OfflineIndicator(),
              Expanded(
                child: _screens[navState.currentIndex],
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            bottom: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
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
                      currentIndex: navState.currentIndex,
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
                        context.read<NavigationCubit>().setTab(index);
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
              const AppBannerAd(),
            ],
          ),
        ),
      ),
    );
  },
);
}
}
