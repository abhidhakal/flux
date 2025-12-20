import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/models/goal_model.dart';
import '../../../core/services/currency_service.dart';
import '../goals_bloc.dart';
import '../../auth/auth_bloc.dart';

class GoalCard extends StatefulWidget {
  final Goal goal;
  final Function(String goalId)? onDeleteGoal;
  final Function(Goal goal)? onEditGoal;

  const GoalCard({super.key, required this.goal, this.onDeleteGoal, this.onEditGoal});

  @override
  State<GoalCard> createState() => _GoalCardState();
}

class _GoalCardState extends State<GoalCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    // Start fade-in animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onHover(bool isHovered) {
    if (isHovered) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.shadow.withOpacity(0.08),
                    offset: const Offset(0, 4),
                    blurRadius: 20,
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Theme.of(context).colorScheme.shadow.withOpacity(0.06),
                    offset: const Offset(0, 1),
                    blurRadius: 6,
                    spreadRadius: 0,
                  ),
                ],
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: MouseRegion(
                onEnter: (_) => _onHover(true),
                onExit: (_) => _onHover(false),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 16),
                    _buildDescription(),
                    const SizedBox(height: 18),
                    _buildProgressSection(),
                    const SizedBox(height: 18),
                    _buildActionButtons(context),
                  ],
                ),
              ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
              children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(widget.goal.color),
                Color(widget.goal.color).withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Color(widget.goal.color).withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Color(widget.goal.color).withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            _getIconForType(widget.goal.type),
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.goal.name,
                        style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                  letterSpacing: -0.4,
                        ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                      ),
              const SizedBox(height: 6),
                      Text(
                        widget.goal.typeDisplayName,
                        style: TextStyle(
                  fontSize: 15,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(),
              ],
    );
  }

  Widget _buildDescription() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
            Color(widget.goal.color).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Color(widget.goal.color).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Text(
        widget.goal.description,
        style: TextStyle(
          fontSize: 14,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
          height: 1.5,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.1,
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    Color chipColor;
    IconData icon;

    switch (widget.goal.status) {
      case GoalStatus.active:
        if (widget.goal.isOverdue) {
          chipColor = const Color(0xFFFF3B30);
          icon = Icons.warning_rounded;
        } else {
          chipColor = const Color(0xFF34C759);
          icon = Icons.flag_rounded;
        }
        break;
      case GoalStatus.completed:
        chipColor = const Color(0xFF34C759);
        icon = Icons.check_circle_rounded;
        break;
      case GoalStatus.paused:
        chipColor = const Color(0xFFFF9500);
        icon = Icons.pause_rounded;
        break;
      case GoalStatus.cancelled:
        chipColor = const Color(0xFFFF3B30);
        icon = Icons.cancel_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: chipColor.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(
        widget.goal.statusText,
        style: const TextStyle(
          color: Colors.white,
              fontSize: 13,
          fontWeight: FontWeight.w600,
              letterSpacing: -0.1,
        ),
      ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    final colorScheme = Theme.of(context).colorScheme;
    final goalColor = Color(widget.goal.color);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress bar with percentage
        Row(
          children: [
            Expanded(
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: colorScheme.outline.withOpacity(0.15),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: widget.goal.progress.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: goalColor,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${widget.goal.progressPercentage.toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: goalColor,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 10),
        
        // Amount row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${CurrencyService().formatAmount(widget.goal.currentAmount)} of ${CurrencyService().formatAmount(widget.goal.targetAmount)}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            if (widget.goal.status == GoalStatus.active && widget.goal.daysRemaining > 0)
              Text(
                '${widget.goal.daysRemaining}d left',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: widget.goal.daysRemaining <= 30 
                      ? AppColors.error 
                      : colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    if (widget.goal.status == GoalStatus.completed) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            _showCompletionDialog(context);
          },
          icon: const Icon(Icons.info_outline_rounded, size: 20),
          label: const Text('View Details'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            elevation: 0,
            shadowColor: const Color(0xFF34C759).withOpacity(0.3),
          ),
        ),
      );
    }

    return Row(
      children: [
        if (widget.goal.status == GoalStatus.active) ...[
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                _showAddProgressDialog(context);
              },
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Add Progress'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(widget.goal.color),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 0,
                shadowColor: Color(widget.goal.color).withOpacity(0.3),
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              _showGoalActions(context);
            },
            icon: const Icon(Icons.more_vert_rounded, size: 20),
            label: const Text('More'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              side: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.4),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showAddProgressDialog(BuildContext context) {
    // Capture bloc references BEFORE showing dialog (dialog context can't access providers)
    final goalsBloc = context.read<GoalsBloc>();
    final authState = context.read<AuthBloc>().state;
    String userId = widget.goal.userId;
    if (authState is AuthAuthenticated) {
      userId = authState.user.id;
    }
    
    final amountController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Progress'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('How much progress did you make on "${widget.goal.name}"?'),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: CurrencyService().symbol,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final raw = amountController.text.replaceAll(',', '').trim();
              final amount = double.tryParse(raw);
              if (amount == null || amount <= 0) {
                AppSnackbar.showError(dialogContext, message: 'Enter a valid amount > 0');
                return;
              }
              goalsBloc.add(UpdateGoalProgress(
                goalId: widget.goal.id,
                amount: amount,
                userId: userId,
              ));
              Navigator.pop(dialogContext);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showGoalActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          bottom: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Goal'),
                onTap: () {
                  Navigator.pop(context);
                  widget.onEditGoal?.call(widget.goal);
                },
              ),
              if (widget.goal.status == GoalStatus.active) ...[
                ListTile(
                  leading: const Icon(Icons.pause),
                  title: const Text('Pause Goal'),
                  onTap: () {
                    Navigator.pop(context);
                    _pauseGoal(context);
                  },
                ),
              ] else if (widget.goal.status == GoalStatus.paused) ...[
                ListTile(
                  leading: const Icon(Icons.play_arrow),
                  title: const Text('Resume Goal'),
                  onTap: () {
                    Navigator.pop(context);
                    _resumeGoal(context);
                  },
                ),
              ],
              ListTile(
                leading: const Icon(Icons.delete, color: AppColors.error),
                title: const Text('Delete Goal', style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteGoal(context);
                },
              ),
              // Bottom padding for safe area
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        ),
      ),
    );
  }

  void _showCompletionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Goal Completed!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Congratulations! You completed "${widget.goal.name}"'),
            const SizedBox(height: 16),
            Text('Target Amount: \$${widget.goal.targetAmount.toStringAsFixed(2)}'),
            Text('Completed On: ${widget.goal.completedAt?.toString().split(' ')[0] ?? 'Unknown'}'),
            const SizedBox(height: 16),
            Text(
              'Time to complete: ${widget.goal.createdAt.difference(widget.goal.completedAt!).inDays} days',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Great!'),
          ),
        ],
      ),
    );
  }

  void _pauseGoal(BuildContext context) {
    final updatedGoal = widget.goal.copyWith(status: GoalStatus.paused);
    context.read<GoalsBloc>().add(UpdateGoal(updatedGoal));
  }

  void _resumeGoal(BuildContext context) {
    final updatedGoal = widget.goal.copyWith(status: GoalStatus.active);
    context.read<GoalsBloc>().add(UpdateGoal(updatedGoal));
  }

  void _deleteGoal(BuildContext context) {
    // Capture bloc references BEFORE showing dialog (dialog context can't access providers)
    final goalsBloc = context.read<GoalsBloc>();
    final authState = context.read<AuthBloc>().state;
    String userId = widget.goal.userId;
    if (authState is AuthAuthenticated) {
      userId = authState.user.id;
    }
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Goal'),
        content: Text('Are you sure you want to delete "${widget.goal.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              goalsBloc.add(DeleteGoal(widget.goal.id, userId));
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
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
}
