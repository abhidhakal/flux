import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/constants/goal_type_icons.dart';
import '../../../core/models/goal_model.dart';
import '../../../core/services/currency_service.dart';
import '../goals_bloc.dart';
import '../../auth/auth_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class GoalCard extends StatelessWidget {
  final Goal goal;
  final Function(String goalId)? onDeleteGoal;
  final Function(Goal goal)? onEditGoal;

  const GoalCard({
    super.key,
    required this.goal,
    this.onDeleteGoal,
    this.onEditGoal,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => onEditGoal?.call(goal),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                if (goal.description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    goal.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _buildProgressSection(context),
                const SizedBox(height: 16),
                _buildActionButtons(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final goalColor = Color(goal.color);

    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: goalColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getIconForType(goal.type),
            color: goalColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                goal.name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                goal.typeDisplayName,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        _buildStatusChip(context),
      ],
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    Color statusColor;
    String statusText = goal.statusText;

    switch (goal.status) {
      case GoalStatus.active:
        statusColor = goal.isOverdue ? AppColors.error : AppColors.success;
        break;
      case GoalStatus.completed:
        statusColor = AppColors.success;
        break;
      case GoalStatus.paused:
        statusColor = AppColors.warning;
        break;
      case GoalStatus.cancelled:
        statusColor = AppColors.error;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: statusColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildProgressSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final goalColor = Color(goal.color);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress bar with percentage
        Row(
          children: [
            Expanded(
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: colorScheme.outline.withValues(alpha: 0.1),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: goal.progress.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: goalColor,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${goal.progressPercentage.toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Amount row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  CurrencyService().formatAmount(goal.currentAmount),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  'of ${CurrencyService().formatAmount(goal.targetAmount)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
            if (goal.status == GoalStatus.active && goal.daysRemaining > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${goal.daysRemaining}d left',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: goal.daysRemaining <= 30
                        ? AppColors.error
                        : colorScheme.primary,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    if (goal.status == GoalStatus.completed) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => _showCompletionDialog(context),
          icon: const Icon(LucideIcons.partyPopper, size: 18),
          label: const Text('View Achievement'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        if (goal.status == GoalStatus.active) ...[
          Expanded(
            child: ElevatedButton(
              onPressed: () => _showAddProgressDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text('Add Progress',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 12),
        ],
        IconButton(
          onPressed: () => _showGoalActions(context),
          style: IconButton.styleFrom(
            backgroundColor:
                Theme.of(context).colorScheme.surfaceContainerHighest,
            padding: const EdgeInsets.all(12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(LucideIcons.moreHorizontal),
        ),
      ],
    );
  }

  void _showAddProgressDialog(BuildContext context) {
    final goalsBloc = context.read<GoalsBloc>();
    final authState = context.read<AuthBloc>().state;
    String userId = goal.userId;
    if (authState is AuthAuthenticated) {
      userId = authState.user.id;
    }

    final colorScheme = Theme.of(context).colorScheme;
    final amountController = TextEditingController();
    final focusNode = FocusNode();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Add Progress',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'How much did you save for "${goal.name}"?',
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: amountController,
                focusNode: focusNode,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  hintText: '0.00',
                  prefixText: CurrencyService().symbol,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  final raw = amountController.text.replaceAll(',', '').trim();
                  final amount = double.tryParse(raw);
                  if (amount == null || amount <= 0) {
                    AppSnackbar.showError(context,
                        message: 'Please enter a valid amount');
                    return;
                  }
                  goalsBloc.add(UpdateGoalProgress(
                    goalId: goal.id,
                    amount: amount,
                    userId: userId,
                  ));
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Confirm Contribution',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.5)),
                ),
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(() {
      amountController.dispose();
      focusNode.dispose();
    });
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
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(LucideIcons.pencil),
                title: const Text('Edit Goal'),
                onTap: () {
                  Navigator.pop(context);
                  onEditGoal?.call(goal);
                },
              ),
              if (goal.status == GoalStatus.active) ...[
                ListTile(
                  leading: const Icon(LucideIcons.pause),
                  title: const Text('Pause Goal'),
                  onTap: () {
                    Navigator.pop(context);
                    _pauseGoal(context);
                  },
                ),
              ] else if (goal.status == GoalStatus.paused) ...[
                ListTile(
                  leading: const Icon(LucideIcons.play),
                  title: const Text('Resume Goal'),
                  onTap: () {
                    Navigator.pop(context);
                    _resumeGoal(context);
                  },
                ),
              ],
              ListTile(
                leading: const Icon(LucideIcons.trash2, color: AppColors.error),
                title: const Text('Delete Goal',
                    style: TextStyle(color: AppColors.error)),
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
          children: [
            const Icon(LucideIcons.partyPopper,
                color: AppColors.success, size: 64),
            const SizedBox(height: 16),
            Text('Congratulations! You completed "${goal.name}"'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _pauseGoal(BuildContext context) {
    context
        .read<GoalsBloc>()
        .add(UpdateGoal(goal.copyWith(status: GoalStatus.paused)));
  }

  void _resumeGoal(BuildContext context) {
    context
        .read<GoalsBloc>()
        .add(UpdateGoal(goal.copyWith(status: GoalStatus.active)));
  }

  void _deleteGoal(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    String userId = goal.userId;
    if (authState is AuthAuthenticated) {
      userId = authState.user.id;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Goal'),
        content: Text('Are you sure you want to delete "${goal.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<GoalsBloc>().add(DeleteGoal(goal.id, userId));
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  IconData _getIconForType(GoalType type) => type.icon;
}
