import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/models/goal_model.dart';
import '../../../core/services/currency_service.dart';
import '../../../core/services/planning_insights_service.dart';
import '../../../core/services/widget_service.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/skeleton_components.dart';
import '../../auth/auth_bloc.dart';
import '../goals_bloc.dart';
import '../widgets/goal_card.dart';
import '../widgets/goal_progress_chart.dart';
import '../widgets/create_goal_screen.dart';

import '../../subscription/presentation/pages/paywall_screen.dart';
import '../../subscription/subscription_bloc.dart';
import 'goal_templates_screen.dart';
import 'edit_goal_screen.dart';
import '../../../shared/widgets/page_transitions.dart';
import '../../../shared/widgets/app_bottom_sheet.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/stat_tile.dart';
import '../../../shared/widgets/premium_page_hero.dart';
import '../../../shared/widgets/app_section_header.dart';
import '../../../core/services/feature_flag_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'All'; // All, Active, Paused
  final PlanningInsightsService _planning = PlanningInsightsService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  void _loadGoalsIfNeeded(BuildContext context) {
    final goalsState = context.read<GoalsBloc>().state;
    final user = context.read<AuthBloc>().state;

    // Reload goals if:
    // - Not already loaded or loading
    // - OR current state is GoalsSuccess (transient state after create/delete/update)
    if (user is AuthAuthenticated &&
        (goalsState is! GoalsLoaded && goalsState is! GoalsLoading ||
            goalsState is GoalsSuccess)) {
      context.read<GoalsBloc>().add(LoadGoals(user.user.id));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.pageSurface(context),
      body: Column(
        children: [
          PremiumPageHero(
            title: 'Goals',
            subtitle: 'Stay focused on what matters most',
            showBackButton: true,
            actions: [
              PremiumPageHeroAction(
                icon: LucideIcons.plus,
                tooltip: 'Add goal',
                onPressed: () => _showAddGoalOptions(context),
              ),
            ],
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            padding: const EdgeInsets.all(4),
            decoration: AppTheme.surfaceDecoration(
              context,
              radius: AppTheme.cardRadius,
              subtle: true,
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding: EdgeInsets.zero,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelColor: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.5),
              unselectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(text: 'Goals'),
                Tab(text: 'Completed'),
                Tab(text: 'Insights'),
              ],
            ),
          ),
          Expanded(
            child: BlocListener<AuthBloc, AuthState>(
              listener: (context, authState) {
                if (authState is AuthAuthenticated) {
                  _loadGoalsIfNeeded(context);
                }
              },
              child: BlocConsumer<GoalsBloc, GoalsState>(
                // Only rebuild on data states, not on success/transient states
                buildWhen: (previous, current) {
                  return current is GoalsLoaded ||
                      current is GoalsLoading ||
                      current is GoalsInitial ||
                      current is GoalsError;
                },
                listener: (context, state) {
                  // Show snackbar on success/error
                  if (state is GoalsSuccess) {
                    AppSnackbar.showSuccess(context, message: state.message);
                  } else if (state is GoalsError) {
                    AppSnackbar.showError(context, message: state.message);
                  }
                },
                builder: (context, state) {
                  if (state is GoalsInitial) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _loadGoalsIfNeeded(context);
                    });
                    return _buildGoalsSkeleton();
                  }

                  if (state is GoalsLoading) {
                    return _buildGoalsSkeleton();
                  }

                  List<Goal> goals = [];
                  if (state is GoalsLoaded) {
                    goals = state.goals;
                    WidgetService.refreshWidgets(context);
                  }

                  if (goals.isNotEmpty) {
                    return _buildTabBarView(goals);
                  }

                  if (state is GoalsError) {
                    return _buildErrorState(state.message);
                  }

                  return _buildEmptyState();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddGoalOptions(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    AppBottomSheet.show(
      context,
      radius: AppTheme.cardRadius,
      isScrollControlled: false,
      padding: const EdgeInsets.symmetric(vertical: 24),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Add New Goal',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(LucideIcons.pencil, color: AppColors.primary),
            ),
            title: const Text('Create Custom Goal',
                style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Design a goal from scratch'),
            onTap: () {
              Navigator.pop(context);
              final subscriptionState = context.read<SubscriptionBloc>().state;
              if (!FeatureFlagService.isSubscriptionEnabled ||
                  subscriptionState is SubscriptionPremium) {
                context.pushSmooth(
                  const CreateGoalScreen(),
                  transitionType: PageTransitionType.slideFromBottom,
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const PaywallScreen()),
                );
              }
            },
          ),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(LucideIcons.fileText, color: colorScheme.secondary),
            ),
            title: const Text('Use Template',
                style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Choose from common savings goals'),
            onTap: () {
              Navigator.pop(context);
              context.pushSmooth(
                const GoalTemplatesScreen(),
                transitionType: PageTransitionType.slideFromRight,
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTabBarView(List<Goal> goals) {
    // Filter goals based on selected filter for Goals tab
    final goalsForTab = goals
        .where((g) =>
            g.status != GoalStatus.completed &&
            g.status != GoalStatus.cancelled)
        .toList();
    final completedGoals =
        goals.where((g) => g.status == GoalStatus.completed).toList();

    return TabBarView(
      controller: _tabController,
      children: [
        _buildGoalsTab(goalsForTab),
        _buildCompletedGoalsTab(completedGoals),
        _buildInsightsTab(goals),
      ],
    );
  }

  Widget _buildGoalsTab(List<Goal> allGoalsForTab) {
    final colorScheme = Theme.of(context).colorScheme;

    // Apply filter
    List<Goal> filteredGoals;
    switch (_selectedFilter) {
      case 'Active':
        filteredGoals =
            allGoalsForTab.where((g) => g.status == GoalStatus.active).toList();
        break;
      case 'Paused':
        filteredGoals =
            allGoalsForTab.where((g) => g.status == GoalStatus.paused).toList();
        break;
      default:
        filteredGoals = allGoalsForTab;
    }

    return RefreshIndicator(
      onRefresh: () async {
        final authState = context.read<AuthBloc>().state;
        if (authState is AuthAuthenticated) {
          context.read<GoalsBloc>().add(LoadGoals(authState.user.id));
        }
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: AppTheme.surfaceDecoration(context,
                    radius: AppTheme.cardRadius, subtle: true),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildFilterChip('All', colorScheme),
                    const SizedBox(width: 4),
                    _buildFilterChip('Active', colorScheme),
                    const SizedBox(width: 4),
                    _buildFilterChip('Paused', colorScheme),
                  ],
                ),
              ),
            ),
          ),
          if (filteredGoals.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _buildGoalsOverview(filteredGoals, colorScheme),
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
                child: AppSectionHeader(title: 'Your goals'),
              ),
            ),
          ],
          // Goals List
          if (filteredGoals.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.goal,
                        size: 64, color: colorScheme.onSurfaceVariant),
                    const SizedBox(height: 16),
                    Text(
                      'No ${_selectedFilter == 'All' ? '' : _selectedFilter.toLowerCase()} goals',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => GoalCard(
                    goal: filteredGoals[index],
                    onDeleteGoal: (goalId) {
                      final authState = context.read<AuthBloc>().state;
                      String userId = filteredGoals[index].userId;
                      if (authState is AuthAuthenticated) {
                        userId = authState.user.id;
                      }
                      context.read<GoalsBloc>().add(DeleteGoal(goalId, userId));
                    },
                    onEditGoal: (goal) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => EditGoalScreen(goal: goal)),
                      );
                    },
                  ),
                  childCount: filteredGoals.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, ColorScheme colorScheme) {
    final isSelected = _selectedFilter == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = label;
        });
      },
      selectedColor: colorScheme.primary,
      showCheckmark: false,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      labelStyle: TextStyle(
        color:
            isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      backgroundColor: AppTheme.cardSurface(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      side: BorderSide.none,
    );
  }

  Widget _buildGoalsOverview(List<Goal> goals, ColorScheme colorScheme) {
    final totalTarget = goals.fold(0.0, (sum, g) => sum + g.targetAmount);
    final totalProgress = goals.fold(0.0, (sum, g) => sum + g.currentAmount);
    final averageProgress =
        totalTarget > 0 ? (totalProgress / totalTarget * 100) : 0.0;
    final plans = _planning.fundingPlans(goals);
    final monthlyFunding =
        plans.fold<double>(0, (total, plan) => total + plan.monthlyAmount);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.surfaceDecoration(
        context,
        radius: AppTheme.cardRadius,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildOverviewStat('${goals.length}', 'Goals', colorScheme),
              Container(
                  width: 1,
                  height: 40,
                  color: colorScheme.outline.withValues(alpha: 0.1)),
              _buildOverviewStat(CurrencyService().formatAmountCompact(totalTarget),
                  'Target', colorScheme),
              Container(
                  width: 1,
                  height: 40,
                  color: colorScheme.outline.withValues(alpha: 0.1)),
              _buildOverviewStat('${averageProgress.toStringAsFixed(0)}%',
                  'Progress', colorScheme),
            ],
          ),
          if (monthlyFunding > 0) ...[
            const SizedBox(height: 14),
            Text(
              'Suggested monthly funding: ${CurrencyService().formatAmount(monthlyFunding)}',
              style: TextStyle(
                color: colorScheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOverviewStat(
      String value, String label, ColorScheme colorScheme) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface)),
        const SizedBox(height: 4),
        Text(label,
            style:
                TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
      ],
    );
  }

  Widget _buildCompletedGoalsTab(List<Goal> completedGoals) {
    final colorScheme = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: () async {
        final authState = context.read<AuthBloc>().state;
        if (authState is AuthAuthenticated) {
          context.read<GoalsBloc>().add(LoadGoals(authState.user.id));
        }
      },
      child: completedGoals.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 120),
                const EmptyStateView(
                  icon: LucideIcons.checkCircle2,
                  title: 'No Completed Goals',
                  titleFontSize: 18,
                ),
              ],
            )
          : CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: AppTheme.surfaceDecoration(context,
                          radius: AppTheme.cardRadius),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(LucideIcons.checkCircle2,
                                color: AppColors.success),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${completedGoals.length} Goals Completed',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.onSurface)),
                                Text(
                                    '${CurrencyService().formatAmountCompact(completedGoals.fold(0.0, (sum, g) => sum + g.targetAmount))} saved',
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: colorScheme.onSurfaceVariant)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => GoalCard(
                        goal: completedGoals[index],
                        onDeleteGoal: (goalId) {
                          final authState = context.read<AuthBloc>().state;
                          String userId = completedGoals[index].userId;
                          if (authState is AuthAuthenticated) {
                            userId = authState.user.id;
                          }
                          context
                              .read<GoalsBloc>()
                              .add(DeleteGoal(goalId, userId));
                        },
                        onEditGoal: (goal) {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      EditGoalScreen(goal: goal)));
                        },
                      ),
                      childCount: completedGoals.length,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
    );
  }

  Widget _buildInsightsTab(List<Goal> allGoals) {
    final activeGoals =
        allGoals.where((g) => g.status == GoalStatus.active).toList();
    final completedGoals =
        allGoals.where((g) => g.status == GoalStatus.completed).toList();

    return RefreshIndicator(
      onRefresh: () async {
        final authState = context.read<AuthBloc>().state;
        if (authState is AuthAuthenticated) {
          context.read<GoalsBloc>().add(LoadGoals(authState.user.id));
        }
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppSectionHeader(title: 'Statistics'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                    child: _statCard('Active', activeGoals.length.toString(),
                        LucideIcons.goal, AppColors.primary)),
                const SizedBox(width: 12),
                Expanded(
                    child: _statCard(
                        'Completed',
                        completedGoals.length.toString(),
                        LucideIcons.checkCircle2,
                        AppColors.success)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: _statCard(
                        'Overdue',
                        activeGoals.where((g) => g.isOverdue).length.toString(),
                        LucideIcons.alertTriangle,
                        AppColors.error)),
                const SizedBox(width: 12),
                Expanded(
                    child: _statCard(
                        'Near Deadline',
                        activeGoals
                            .where((g) =>
                                g.daysRemaining <= 30 && g.daysRemaining > 0)
                            .length
                            .toString(),
                        LucideIcons.clock,
                        AppColors.warning)),
              ],
            ),
            const SizedBox(height: 24),
            const AppSectionHeader(title: 'Progress Chart'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.surfaceDecoration(context,
                  radius: AppTheme.cardRadius),
              child: SizedBox(
                  height: 200, child: GoalProgressChart(goals: allGoals)),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return StatTile(
      label: title,
      value: value,
      icon: icon,
      accentColor: color,
      radius: AppTheme.cardRadius,
      valueFirst: true,
      centered: true,
      valueFontSize: 24,
    );
  }

  Widget _buildErrorState(String message) {
    return EmptyStateView(
      icon: LucideIcons.alertCircle,
      iconColor: AppColors.error,
      title: 'Error loading goals',
      subtitle: message,
      actionLabel: 'Retry',
      onAction: () {
        final user = context.read<AuthBloc>().state;
        if (user is AuthAuthenticated) {
          context.read<GoalsBloc>().add(LoadGoals(user.user.id));
        }
      },
    );
  }

  Widget _buildEmptyState() {
    final colorScheme = Theme.of(context).colorScheme;
    return EmptyStateView(
      icon: LucideIcons.goal,
      iconColor: colorScheme.primary,
      title: 'No Goals Yet',
      titleFontSize: 24,
      subtitle: 'Create your first financial goal to get started',
    );
  }

  Widget _buildGoalsSkeleton() {
    return TabBarView(
      controller: _tabController,
      children: [
        ListView(padding: const EdgeInsets.all(16), children: [
          SkeletonComponents.card(height: 80, context: context),
          const SizedBox(height: 16),
          ...List.generate(
              3,
              (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: SkeletonComponents.goalCard(context: context))),
        ]),
        ListView(padding: const EdgeInsets.all(16), children: [
          SkeletonComponents.card(height: 80, context: context),
          const SizedBox(height: 16),
          ...List.generate(
              2,
              (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: SkeletonComponents.goalCard(context: context))),
        ]),
        ListView(padding: const EdgeInsets.all(16), children: [
          Row(children: [
            Expanded(
                child: SkeletonComponents.card(height: 100, context: context)),
            const SizedBox(width: 12),
            Expanded(
                child: SkeletonComponents.card(height: 100, context: context))
          ]),
          const SizedBox(height: 24),
          SkeletonComponents.chart(height: 200, context: context),
        ]),
      ],
    );
  }
}
