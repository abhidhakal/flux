import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/goal_model.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  void _loadGoalsIfNeeded(BuildContext context) {
    final goalsState = context.read<GoalsBloc>().state;
    final user = context.read<AuthBloc>().state;
    
    print('🎯 GOALS SCREEN: _loadGoalsIfNeeded called');
    print('🎯 GOALS SCREEN: Auth state: ${user.runtimeType}');
    print('🎯 GOALS SCREEN: Goals state: ${goalsState.runtimeType}');
    
    // Only load if we don't have goals loaded and user is authenticated
    // Also ensure we're not already loading
    if (user is AuthAuthenticated && 
        goalsState is! GoalsLoaded && 
        goalsState is! GoalsLoading) {
      print('🎯 GOALS SCREEN: Loading goals for user: ${user.user.id}');
      context.read<GoalsBloc>().add(LoadGoals(user.user.id));
      // Don't load statistics immediately to avoid state conflicts
      // Statistics will be loaded when needed in the insights tab
    } else {
      print('🎯 GOALS SCREEN: Not loading goals - user: ${user.runtimeType}, goalsState: ${goalsState.runtimeType}');
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
        backgroundColor: colorScheme.background,
        foregroundColor: colorScheme.onBackground,
        iconTheme: IconThemeData(color: colorScheme.onBackground),
        titleTextStyle: TextStyle(
          color: colorScheme.onBackground,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: colorScheme.primary,
          labelColor: colorScheme.primary,
          unselectedLabelColor: colorScheme.onBackground,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
            Tab(text: 'Insights'),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.add, color: colorScheme.onBackground),
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
                      MaterialPageRoute(
                        builder: (context) => const PaywallScreen(),
                      ),
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
          // Load goals when authentication is complete
          if (authState is AuthAuthenticated) {
            _loadGoalsIfNeeded(context);
          }
        },
        child: BlocBuilder<GoalsBloc, GoalsState>(
          builder: (context, state) {
          // Safety net: try to load goals if we're in initial state and user is authenticated
          if (state is GoalsInitial) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _loadGoalsIfNeeded(context);
            });
            return _buildGoalsSkeleton();
          }

          // Show loading indicator only if we're loading and have no previous data
          if (state is GoalsLoading) {
            // Check if we have any previous goals data to show while loading
            final bloc = context.read<GoalsBloc>();
            if (bloc.state is GoalsLoaded) {
              // Continue showing previous data while loading
              final previousGoals = (bloc.state as GoalsLoaded).goals;
              if (previousGoals.isNotEmpty) {
                return _buildTabBarView(previousGoals);
              }
            }
            return _buildGoalsSkeleton();
          }

          // Get goals from current state
          List<Goal> goals = [];
          if (state is GoalsLoaded) {
            goals = state.goals;
            print('🎯 GOALS SCREEN: Found ${goals.length} goals in GoalsLoaded state');
          } else if (state is GoalStatisticsLoaded) {
            // When statistics are loaded, we need to get goals from previous state
            // This happens when GetGoalStatistics is called after LoadGoals
            final bloc = context.read<GoalsBloc>();
            // Check if we have goals in the bloc's state history
            if (bloc.state is GoalsLoaded) {
              goals = (bloc.state as GoalsLoaded).goals;
              print('🎯 GOALS SCREEN: Found ${goals.length} goals in previous GoalsLoaded state');
            }
          } else if (state is GoalsSuccess) {
            // Try to get goals from previous state
            final previousState = context.read<GoalsBloc>().state;
            if (previousState is GoalsLoaded) {
              goals = previousState.goals;
              print('🎯 GOALS SCREEN: Found ${goals.length} goals in GoalsSuccess state');
            }
          } else {
            print('🎯 GOALS SCREEN: Current state is ${state.runtimeType}, no goals found');
          }

          if (goals.isNotEmpty) {
            return _buildTabBarView(goals);
          }

          if (state is GoalsError) {
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
                    'Error loading goals',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
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

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.flag,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'No Goals Yet',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create your first financial goal to get started',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
        ),
      ),
    );
  }

  Widget _buildTabBarView(List<Goal> goals) {
    final activeGoals = goals.where((g) => g.status == GoalStatus.active).toList();
    final completedGoals = goals.where((g) => g.status == GoalStatus.completed).toList();

    return TabBarView(
      controller: _tabController,
      children: [
        _buildActiveGoalsTab(activeGoals),
        _buildCompletedGoalsTab(completedGoals),
        _buildInsightsTab(goals),
      ],
    );
  }

  Widget _buildActiveGoalsTab(List<Goal> activeGoals) {
    return RefreshIndicator(
      onRefresh: () async {
        // Get current user and reload goals
        final authState = context.read<AuthBloc>().state;
        if (authState is AuthAuthenticated) {
          context.read<GoalsBloc>().add(LoadGoals(authState.user.id));
        }
      },
      child: activeGoals.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 120),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.flag_outlined,
                        size: 64,
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Active Goals',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create a new goal to start your financial journey',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            )
          : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildGoalsOverview(activeGoals),
                  const SizedBox(height: 32),
                  _buildGoalsList(activeGoals),
                ],
              ),
            ),
    );
  }

  Widget _buildCompletedGoalsTab(List<Goal> completedGoals) {
    return RefreshIndicator(
      onRefresh: () async {
        // Get current user and reload goals
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
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 64,
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Completed Goals',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Complete your first goal to see it here',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            )
          : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildCompletedGoalsOverview(completedGoals),
                  const SizedBox(height: 32),
                  _buildGoalsList(completedGoals),
                ],
              ),
            ),
    );
  }

  Widget _buildInsightsTab(List<Goal> allGoals) {
    return BlocBuilder<GoalsBloc, GoalsState>(
      builder: (context, state) {
        if (state is GoalStatisticsLoaded) {
          final stats = state.statistics;
          
          return RefreshIndicator(
            onRefresh: () async {
              // Get current user and reload goals
              final authState = context.read<AuthBloc>().state;
              if (authState is AuthAuthenticated) {
                context.read<GoalsBloc>().add(LoadGoals(authState.user.id));
                context.read<GoalsBloc>().add(GetGoalStatistics(authState.user.id));
              }
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatisticsCards(stats),
                  const SizedBox(height: 24),
                  _buildProgressChart(allGoals),
                  const SizedBox(height: 24),
                  _buildGoalRecommendations(),
                ],
              ),
            ),
          );
        }

        // Show basic insights even without statistics
        return RefreshIndicator(
          onRefresh: () async {
            // Get current user and reload goals
            final authState = context.read<AuthBloc>().state;
            if (authState is AuthAuthenticated) {
              context.read<GoalsBloc>().add(LoadGoals(authState.user.id));
              context.read<GoalsBloc>().add(GetGoalStatistics(authState.user.id));
            }
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBasicStatistics(allGoals),
                  const SizedBox(height: 24),
                  _buildProgressChart(allGoals),
                  const SizedBox(height: 24),
                  _buildGoalRecommendations(),
                ],
              ),
            ),
          );
      },
    );
  }

  Widget _buildGoalsOverview(List<Goal> goals) {
    final totalTarget = goals.fold(0.0, (sum, g) => sum + g.targetAmount);
    final totalProgress = goals.fold(0.0, (sum, g) => sum + g.currentAmount);
    final averageProgress = totalTarget > 0 ? (totalProgress / totalTarget * 100) : 0.0;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Active Goals',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildOverviewStat(
                  'Goals',
                  goals.length.toString(),
                  const Color(0xFF007AFF),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildOverviewStat(
                  'Target',
                  '\$${totalTarget.toStringAsFixed(0)}',
                  const Color(0xFF34C759),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildOverviewStat(
                  'Progress',
                  '${averageProgress.toStringAsFixed(0)}%',
                  const Color(0xFFFF9500),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedGoalsOverview(List<Goal> goals) {
    final totalCompleted = goals.fold(0.0, (sum, g) => sum + g.targetAmount);
    final averageCompletionTime = goals.isNotEmpty 
        ? goals.fold(0.0, (sum, g) => sum + g.createdAt.difference(g.completedAt!).inDays) / goals.length
        : 0.0;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.08),
            offset: const Offset(0, 4),
            blurRadius: 20,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.06),
            offset: const Offset(0, 1),
            blurRadius: 6,
            spreadRadius: 0,
          ),
        ],
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
          width: 1.5,
        ),
      ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              Row(
                children: [
                  Container(
                width: 56,
                height: 56,
                    decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF10B981),
                      const Color(0xFF10B981).withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                      color: const Color(0xFF10B981).withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                  Icons.check_circle_rounded,
                      color: Colors.white,
                  size: 28,
                    ),
                  ),
              const SizedBox(width: 20),
              Text(
              'Completed Goals',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                  letterSpacing: -0.5,
              ),
            ),
                ],
              ),
          const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                child: _buildOverviewStat(
                    'Completed',
                    goals.length.toString(),
                  const Color(0xFF10B981),
                  ),
                ),
              const SizedBox(width: 20),
                Expanded(
                child: _buildOverviewStat(
                    'Total Value',
                  '\$${totalCompleted.toStringAsFixed(0)}',
                  const Color(0xFF3B82F6),
                  ),
                ),
              const SizedBox(width: 20),
                Expanded(
                child: _buildOverviewStat(
                    'Avg. Days',
                    averageCompletionTime.toStringAsFixed(0),
                  const Color(0xFF8B5CF6),
                  ),
                ),
              ],
            ),
          ],
      ),
    );
  }

  Widget _buildOverviewStat(String label, String value, Color color) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsList(List<Goal> goals) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Your Goals',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
              letterSpacing: -0.4,
            ),
          ),
        ),
        const SizedBox(height: 20),
        ...goals.asMap().entries.map((entry) {
          final index = entry.key;
          final goal = entry.value;
          return TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 300 + (index * 100)),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GoalCard(
          goal: goal,
          onDeleteGoal: (goalId) {
            final authState = context.read<AuthBloc>().state;
            String? userId;
            if (authState is AuthAuthenticated) {
              userId = authState.user.id;
            }
            context.read<GoalsBloc>().add(DeleteGoal(goalId, userId ?? goal.userId));
          },
          onEditGoal: (goal) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EditGoalScreen(goal: goal),
              ),
            );
          },
                    ),
                  ),
                ),
              );
            },
          );
        }),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildBasicStatistics(List<Goal> goals) {
    final activeGoals = goals.where((g) => g.status == GoalStatus.active).toList();
    final completedGoals = goals.where((g) => g.status == GoalStatus.completed).toList();
    final overdueGoals = activeGoals.where((g) => g.isOverdue).length;
    final nearDeadlineGoals = activeGoals.where((g) => g.daysRemaining <= 30 && g.daysRemaining > 0).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Goal Statistics',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onBackground,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Active Goals',
                activeGoals.length.toString(),
                Icons.flag,
                AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Completed',
                completedGoals.length.toString(),
                Icons.check_circle,
                AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Overdue',
                overdueGoals.toString(),
                Icons.warning,
                AppColors.error,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Near Deadline',
                nearDeadlineGoals.toString(),
                Icons.schedule,
                AppColors.warning,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatisticsCards(Map<String, dynamic> stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Goal Statistics',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onBackground,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Active Goals',
                stats['activeGoals'].toString(),
                Icons.flag,
                AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Completed',
                stats['completedGoals'].toString(),
                Icons.check_circle,
                AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Overdue',
                stats['overdueGoals'].toString(),
                Icons.warning,
                AppColors.error,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Near Deadline',
                stats['nearDeadlineGoals'].toString(),
                Icons.schedule,
                AppColors.warning,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Card(
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outline,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressChart(List<Goal> goals) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Goals Progress',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: GoalProgressChart(goals: goals),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalRecommendations() {
    return BlocBuilder<GoalsBloc, GoalsState>(
      builder: (context, state) {
        if (state is GoalRecommendationsLoaded) {
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lightbulb, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'AI Recommendations',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...state.recommendations.map((rec) => _buildRecommendationCard(rec)),
                ],
              ),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildRecommendationCard(Map<String, dynamic> recommendation) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Color(recommendation['color']),
          child: Icon(
            _getIconForType(recommendation['type']),
            color: Colors.white,
          ),
        ),
        title: Text(
          recommendation['name'],
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onBackground,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(recommendation['description']),
            const SizedBox(height: 4),
            Text(
              'Target: \$${recommendation['targetAmount'].toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.success,
              ),
            ),
          ],
        ),
        trailing: Chip(
          label: Text(recommendation['priority']),
          backgroundColor: _getPriorityColor(recommendation['priority']),
          labelStyle: const TextStyle(color: Colors.white),
        ),
        onTap: () {
          // Navigate to create goal with pre-filled data
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateGoalScreen(
                prefillData: recommendation,
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getIconForType(GoalType type) {
    switch (type) {
      case GoalType.savings:
        return Icons.savings;
      case GoalType.debt:
        return Icons.credit_card;
      case GoalType.investment:
        return Icons.trending_up;
      case GoalType.emergency:
        return Icons.emergency;
      case GoalType.vacation:
        return Icons.beach_access;
      case GoalType.home:
        return Icons.home;
      case GoalType.education:
        return Icons.school;
      case GoalType.other:
        return Icons.flag;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return AppColors.error;
      case 'medium':
        return AppColors.warning;
      case 'low':
        return AppColors.success;
      default:
        return AppColors.primary;
    }
  }

  Widget _buildGoalsSkeleton() {
    return TabBarView(
      controller: _tabController,
      children: [
        // Active goals skeleton
        ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Overview skeleton
            SkeletonComponents.card(
              height: 120,
              children: [
                SkeletonComponents.textLine(width: 100, height: 18),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: SkeletonComponents.textLine(width: 60, height: 24)),
                    const SizedBox(width: 20),
                    Expanded(child: SkeletonComponents.textLine(width: 60, height: 24)),
                    const SizedBox(width: 20),
                    Expanded(child: SkeletonComponents.textLine(width: 60, height: 24)),
                  ],
                ),
              ], context: context,
            ),
            const SizedBox(height: 32),
            // Goals list skeleton
            ...List.generate(3, (index) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: SkeletonComponents.goalCard(context: context),
            )),
          ],
        ),
        // Completed goals skeleton
        ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SkeletonComponents.card(
              height: 120,
              children: [
                Row(
                  children: [
                    SkeletonComponents.circle(size: 40, context: context),
                    const SizedBox(width: 16),
                    SkeletonComponents.textLine(width: 120, height: 18),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: SkeletonComponents.textLine(width: 60, height: 24)),
                    const SizedBox(width: 20),
                    Expanded(child: SkeletonComponents.textLine(width: 60, height: 24)),
                    const SizedBox(width: 20),
                    Expanded(child: SkeletonComponents.textLine(width: 60, height: 24)),
                  ],
                ),
              ], context: context,
            ),
            const SizedBox(height: 32),
            ...List.generate(2, (index) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: SkeletonComponents.goalCard(context: context),
            )),
          ],
        ),
        // Insights skeleton
        ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Statistics skeleton
            Column(
              children: [
                SkeletonComponents.textLine(width: 120, height: 18),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: SkeletonComponents.card(height: 100, context: context)),
                    const SizedBox(width: 12),
                    Expanded(child: SkeletonComponents.card(height: 100, context: context)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: SkeletonComponents.card(height: 100, context: context)),
                    const SizedBox(width: 12),
                    Expanded(child: SkeletonComponents.card(height: 100, context: context)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Chart skeleton
            SkeletonComponents.chart(height: 200, context: context),
            const SizedBox(height: 24),
            // Recommendations skeleton
            SkeletonComponents.card(
              height: 200,
              children: [
                Row(
                  children: [
                    SkeletonComponents.circle(size: 24, context: context),
                    const SizedBox(width: 8),
                    SkeletonComponents.textLine(width: 150, height: 18),
                  ],
                ),
                const SizedBox(height: 16),
                ...List.generate(3, (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SkeletonComponents.listItem(height: 80, context: context),
                )),
              ], context: context,
            ),
          ],
        ),
      ],
    );
  }
}
