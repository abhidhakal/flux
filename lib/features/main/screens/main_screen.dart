import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../shared/widgets/offline_indicator.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../core/constants/app_theme.dart';
import '../widgets/dashboard_screen.dart';
import '../widgets/budgets_screen.dart';
import '../widgets/transactions_screen.dart';
import '../widgets/profile_screen.dart';
import '../../analytics/screens/analytics_dashboard_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../navigation_cubit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
        final navTheme = theme.bottomNavigationBarTheme;

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;

            final now = DateTime.now();
            final backButtonHasNotBeenPressedOrToastHasExpired =
                _lastPressedAt == null ||
                    now.difference(_lastPressedAt!) >
                        const Duration(seconds: 2);

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
            backgroundColor: AppTheme.pageSurface(context),
            extendBody: true,
            body: Column(
              children: [
                const OfflineIndicator(),
                Expanded(
                  child: IndexedStack(
                    index: navState.currentIndex,
                    children: _screens,
                  ),
                ),
              ],
            ),
            bottomNavigationBar: SafeArea(
              bottom: true,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: 16,
                    ),
                    child: Container(
                      height: 78,
                      decoration: BoxDecoration(
                        color: AppTheme.navigationBarSurface(context),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: AppTheme.navigationBarBorder(context),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.navigationBarShadow(context),
                            blurRadius: 22,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: BottomNavigationBar(
                          currentIndex: navState.currentIndex,
                          onTap: (index) =>
                              context.read<NavigationCubit>().setTab(index),
                          type: BottomNavigationBarType.fixed,
                          backgroundColor: Colors.transparent,
                          selectedItemColor:
                              navTheme.selectedItemColor ?? colorScheme.primary,
                          unselectedItemColor: navTheme.unselectedItemColor ??
                              colorScheme.onSurfaceVariant,
                          showSelectedLabels: true,
                          showUnselectedLabels: true,
                          selectedLabelStyle: navTheme.selectedLabelStyle ??
                              const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 10.5,
                                letterSpacing: 0,
                              ),
                          unselectedLabelStyle: navTheme.unselectedLabelStyle ??
                              const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 10.5,
                                letterSpacing: 0,
                              ),
                          elevation: 0,
                          items: [
                            _navItem(LucideIcons.home, 'Home',
                                selectedColor: navTheme.selectedItemColor ??
                                    colorScheme.primary),
                            _navItem(LucideIcons.coins, 'Budgets',
                                selectedColor: navTheme.selectedItemColor ??
                                    colorScheme.primary),
                            _navItem(LucideIcons.scrollText, 'Transactions',
                                selectedColor: navTheme.selectedItemColor ??
                                    colorScheme.primary),
                            _navItem(LucideIcons.lineChart, 'Insights',
                                selectedColor: navTheme.selectedItemColor ??
                                    colorScheme.primary),
                            _navItem(LucideIcons.user, 'Profile',
                                selectedColor: navTheme.selectedItemColor ??
                                    colorScheme.primary),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Thin Lucide strokes read weakly at nav-bar size against a bare
  /// color-only selected state, so the active icon gets a real size bump
  /// on top of the color change to signal selection clearly.
  BottomNavigationBarItem _navItem(IconData icon, String label,
      {required Color selectedColor}) {
    return BottomNavigationBarItem(
      icon: Padding(
        padding: const EdgeInsets.only(top: 2, bottom: 4),
        child: Icon(icon, size: 21),
      ),
      activeIcon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: selectedColor.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(icon, size: 21, color: selectedColor),
      ),
      label: label,
    );
  }
}
