import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/goal_model.dart';
import '../../../core/services/currency_service.dart';
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

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'All'; // All, Active, Paused

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
        (goalsState is! GoalsLoaded && goalsState is! GoalsLoading || goalsState is GoalsSuccess)) {
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: const Text('Financial Goals'),
        centerTitle: false,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Goals'),
            Tab(text: 'Completed'),
            Tab(text: 'Insights'),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.add, color: Colors.white),
            onSelected: (value) {
              switch (value) {
                case 'create_manual':
                  final subscriptionState = context.read<SubscriptionBloc>().state;
                  if (subscriptionState is SubscriptionPremium) {
                    context.pushSmooth(
                      const CreateGoalScreen(),
                      transitionType: PageTransitionType.slideFromBottom,
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PaywallScreen()),
                    );
                  }
                  break;
                case 'create_from_template':
                  context.pushSmooth(
                    const GoalTemplatesScreen(),
                    transitionType: PageTransitionType.slideFromRight,
                  );
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'create_manual',
                child: Row(
                  children: [
                    Icon(Icons.edit, color: AppColors.primary),
                    SizedBox(width: 12),
                    Text('Create Custom Goal'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'create_from_template',
                child: Row(
                  children: [
                    Icon(Icons.description_outlined, color: AppColors.primary),
                    SizedBox(width: 12),
                    Text('Use Template'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: BlocListener<AuthBloc, AuthState>(
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
    );
  }

  Widget _buildTabBarView(List<Goal> goals) {
    // Filter goals based on selected filter for Goals tab
    final goalsForTab = goals.where((g) => g.status != GoalStatus.completed && g.status != GoalStatus.cancelled).toList();
    final completedGoals = goals.where((g) => g.status == GoalStatus.completed).toList();

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
        filteredGoals = allGoalsForTab.where((g) => g.status == GoalStatus.active).toList();
        break;
      case 'Paused':
        filteredGoals = allGoalsForTab.where((g) => g.status == GoalStatus.paused).toList();
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
          // Filter Pills
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  _buildFilterChip('All', colorScheme),
                  const SizedBox(width: 8),
                  _buildFilterChip('Active', colorScheme),
                  const SizedBox(width: 8),
                  _buildFilterChip('Paused', colorScheme),
                ],
              ),
            ),
          ),
          // Overview
          if (filteredGoals.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: _buildGoalsOverview(filteredGoals, colorScheme),
              ),
            ),
          // Goals List
          if (filteredGoals.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.flag_outlined, size: 64, color: colorScheme.onSurfaceVariant),
                    const SizedBox(height: 16),
                    Text(
                      'No ${_selectedFilter == 'All' ? '' : _selectedFilter.toLowerCase()} goals',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
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
                        MaterialPageRoute(builder: (context) => EditGoalScreen(goal: goal)),
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
      labelStyle: TextStyle(
        color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      backgroundColor: colorScheme.surfaceVariant.withOpacity(0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide.none,
    );
  }

  Widget _buildGoalsOverview(List<Goal> goals, ColorScheme colorScheme) {
    final currency = CurrencyService().symbol;
    final totalTarget = goals.fold(0.0, (sum, g) => sum + g.targetAmount);
    final totalProgress = goals.fold(0.0, (sum, g) => sum + g.currentAmount);
    final averageProgress = totalTarget > 0 ? (totalProgress / totalTarget * 100) : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildOverviewStat('${goals.length}', 'Goals', colorScheme),
          Container(width: 1, height: 40, color: colorScheme.outline.withOpacity(0.1)),
          _buildOverviewStat('$currency${totalTarget.toStringAsFixed(0)}', 'Target', colorScheme),
          Container(width: 1, height: 40, color: colorScheme.outline.withOpacity(0.1)),
          _buildOverviewStat('${averageProgress.toStringAsFixed(0)}%', 'Progress', colorScheme),
        ],
      ),
    );
  }

  Widget _buildOverviewStat(String value, String label, ColorScheme colorScheme) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
      ],
    );
  }

  Widget _buildCompletedGoalsTab(List<Goal> completedGoals) {
    final colorScheme = Theme.of(context).colorScheme;
    final currency = CurrencyService().symbol;

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
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.check_circle_outline, size: 64, color: colorScheme.onSurfaceVariant),
                      const SizedBox(height: 16),
                      Text('No Completed Goals', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
                    ],
                  ),
                ),
              ],
            )
          : CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.check_circle_rounded, color: AppColors.success),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${completedGoals.length} Goals Completed', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
                                Text('$currency${completedGoals.fold(0.0, (sum, g) => sum + g.targetAmount).toStringAsFixed(0)} saved', style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
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
                          context.read<GoalsBloc>().add(DeleteGoal(goalId, userId));
                        },
                        onEditGoal: (goal) {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => EditGoalScreen(goal: goal)));
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
    final colorScheme = Theme.of(context).colorScheme;
    final activeGoals = allGoals.where((g) => g.status == GoalStatus.active).toList();
    final completedGoals = allGoals.where((g) => g.status == GoalStatus.completed).toList();

    return RefreshIndicator(
      onRefresh: () async {
        final authState = context.read<AuthBloc>().state;
        if (authState is AuthAuthenticated) {
          context.read<GoalsBloc>().add(LoadGoals(authState.user.id));
        }
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Statistics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildStatCard('Active', activeGoals.length.toString(), Icons.flag, AppColors.primary, colorScheme)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('Completed', completedGoals.length.toString(), Icons.check_circle, AppColors.success, colorScheme)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildStatCard('Overdue', activeGoals.where((g) => g.isOverdue).length.toString(), Icons.warning, AppColors.error, colorScheme)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('Near Deadline', activeGoals.where((g) => g.daysRemaining <= 30 && g.daysRemaining > 0).length.toString(), Icons.schedule, AppColors.warning, colorScheme)),
              ],
            ),
            const SizedBox(height: 24),
            Text('Progress Chart', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
              ),
              child: SizedBox(height: 200, child: GoalProgressChart(goals: allGoals)),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text('Error loading goals', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
          const SizedBox(height: 8),
          Text(message, style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              final user = context.read<AuthBloc>().state;
              if (user is AuthAuthenticated) {
                context.read<GoalsBloc>().add(LoadGoals(user.user.id));
              }
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.flag, size: 64, color: colorScheme.primary),
          const SizedBox(height: 16),
          Text('No Goals Yet', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
          const SizedBox(height: 8),
          Text('Create your first financial goal to get started', style: TextStyle(fontSize: 16, color: colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildGoalsSkeleton() {
    return TabBarView(
      controller: _tabController,
      children: [
        ListView(padding: const EdgeInsets.all(16), children: [
          SkeletonComponents.card(height: 80, context: context),
          const SizedBox(height: 16),
          ...List.generate(3, (index) => Padding(padding: const EdgeInsets.only(bottom: 16), child: SkeletonComponents.goalCard(context: context))),
        ]),
        ListView(padding: const EdgeInsets.all(16), children: [
          SkeletonComponents.card(height: 80, context: context),
          const SizedBox(height: 16),
          ...List.generate(2, (index) => Padding(padding: const EdgeInsets.only(bottom: 16), child: SkeletonComponents.goalCard(context: context))),
        ]),
        ListView(padding: const EdgeInsets.all(16), children: [
          Row(children: [Expanded(child: SkeletonComponents.card(height: 100, context: context)), const SizedBox(width: 12), Expanded(child: SkeletonComponents.card(height: 100, context: context))]),
          const SizedBox(height: 24),
          SkeletonComponents.chart(height: 200, context: context),
        ]),
      ],
    );
  }
}
