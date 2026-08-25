import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/constants/goal_type_icons.dart';
import '../../../core/models/goal_model.dart';
import '../../../core/services/currency_service.dart';
import '../goals_bloc.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/app_form_fields.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class EditGoalScreen extends StatefulWidget {
  final Goal goal;

  const EditGoalScreen({super.key, required this.goal});

  @override
  State<EditGoalScreen> createState() => _EditGoalScreenState();
}

class _EditGoalScreenState extends State<EditGoalScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetAmountController = TextEditingController();

  GoalType _selectedType = GoalType.savings;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 365));
  int _selectedColor = 0xFF0079DC;
  bool _isRecurring = false;
  String? _recurringPeriod;
  bool _isLoading = false;

  late final AnimationController _entranceController;
  late final Animation<double> _entranceFade;
  late final Animation<Offset> _entranceSlide;

  final List<Map<String, dynamic>> _colorOptions = [
    {'color': 0xFF0079DC, 'name': 'Blue'},
    {'color': 0xFF333333, 'name': 'Charcoal'},
    {'color': 0xFF555555, 'name': 'Graphite'},
    {'color': 0xFF777777, 'name': 'Slate'},
    {'color': 0xFF999999, 'name': 'Silver'},
    {'color': 0xFFBBBBBB, 'name': 'Ash'},
    {'color': 0xFFD6D6D6, 'name': 'Stone'},
    {'color': 0xFF222222, 'name': 'Ink'},
  ];

  @override
  void initState() {
    super.initState();
    _prefillForm();

    _entranceController = AnimationController(
      vsync: this,
      duration: AppMotion.slow,
    );
    _entranceFade = CurvedAnimation(
      parent: _entranceController,
      curve: AppMotion.standard,
    );
    _entranceSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: AppMotion.standard,
    ));
    _entranceController.forward();
  }

  void _prefillForm() {
    final goal = widget.goal;
    _nameController.text = goal.name;
    _descriptionController.text = goal.description;
    _targetAmountController.text = goal.targetAmount.toStringAsFixed(0);
    _selectedType = goal.type;
    _selectedDate = goal.targetDate;
    _selectedColor = goal.color;
    _isRecurring = goal.isRecurring;
    _recurringPeriod = goal.recurringPeriod;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _targetAmountController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Edit Goal'),
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
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _handleUpdateGoal,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
      body: BlocListener<GoalsBloc, GoalsState>(
        listener: (context, state) {
          if (state is GoalsLoading) {
            setState(() => _isLoading = true);
          } else {
            setState(() => _isLoading = false);
          }

          if (state is GoalsSuccess) {
            AppSnackbar.showSuccess(context,
                message: 'Goal updated successfully!');
            Navigator.pop(context);
          }

          if (state is GoalsError) {
            AppSnackbar.showError(context, message: state.message);
          }
        },
        child: FadeTransition(
          opacity: _entranceFade,
          child: SlideTransition(
            position: _entranceSlide,
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Goal Preview Header
                    _buildGoalPreview(colorScheme),

                    // Form Content
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Goal Name
                          _buildSectionLabel('Goal Name',
                              icon: LucideIcons.goal),
                          const SizedBox(height: 8),
                          AppTextField(
                            controller: _nameController,
                            hintText: 'e.g., Emergency Fund',
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter a goal name';
                              }
                              return null;
                            },
                            onChanged: (_) => setState(() {}),
                          ),

                          const SizedBox(height: 24),

                          // Target Amount
                          _buildSectionLabel('Target Amount',
                              icon: LucideIcons.dollarSign),
                          const SizedBox(height: 8),
                          AppNumberField(
                            controller: _targetAmountController,
                            hintText: '10,000',
                            prefixText: '${CurrencyService().symbol} ',
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter target amount';
                              }
                              final amount =
                                  double.tryParse(value.replaceAll(',', ''));
                              if (amount == null || amount <= 0) {
                                return 'Please enter a valid amount';
                              }
                              return null;
                            },
                            onChanged: (_) => setState(() {}),
                          ),

                          const SizedBox(height: 24),

                          // Target Date
                          _buildSectionLabel('Target Date'),
                          const SizedBox(height: 8),
                          _buildDateSelector(colorScheme),

                          const SizedBox(height: 24),

                          // Goal Type
                          _buildSectionLabel('Goal Type'),
                          const SizedBox(height: 12),
                          _buildGoalTypeSelector(colorScheme),

                          const SizedBox(height: 24),

                          // Description
                          _buildSectionLabel('Description (Optional)',
                              icon: LucideIcons.fileText),
                          const SizedBox(height: 8),
                          AppTextField(
                            controller: _descriptionController,
                            maxLines: 3,
                            hintText: 'Why is this goal important to you?',
                          ),

                          const SizedBox(height: 24),

                          // Color Selection
                          _buildSectionLabel('Goal Color'),
                          const SizedBox(height: 12),
                          _buildColorSelector(colorScheme),

                          const SizedBox(height: 24),

                          // Recurring Toggle
                          _buildRecurringToggle(colorScheme),

                          const SizedBox(height: 32),

                          // Update Button
                          _buildUpdateButton(colorScheme),

                          const SizedBox(height: 16),

                          // Cancel Button
                          _buildCancelButton(colorScheme),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoalPreview(ColorScheme colorScheme) {
    final progress = widget.goal.progressPercentage;
    final currentAmount = widget.goal.currentAmount;
    final targetAmount =
        double.tryParse(_targetAmountController.text.replaceAll(',', '')) ??
            widget.goal.targetAmount;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(_selectedColor),
            Color(_selectedColor).withValues(alpha: 0.7),
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Goal Icon and Name
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius:
                          BorderRadius.circular(AppTheme.formFieldRadius),
                    ),
                    child: Icon(
                      _getGoalTypeIcon(_selectedType),
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _nameController.text.isEmpty
                              ? 'Goal Name'
                              : _nameController.text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _selectedType.displayName,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Progress
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Progress',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          CurrencyService().formatAmount(currentAmount),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${progress.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Progress Bar
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: (progress / 100).clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Target
              Text(
                'of ${CurrencyService().formatAmount(targetAmount)} target',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label, {IconData? icon}) {
    final color =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7);
    final style = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: color,
    );
    if (icon == null) return Text(label, style: style);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 6),
        Text(label, style: style),
      ],
    );
  }

  Widget _buildDateSelector(ColorScheme colorScheme) {
    final daysRemaining = _selectedDate.difference(DateTime.now()).inDays;

    return InkWell(
      onTap: _selectDate,
      borderRadius: BorderRadius.circular(AppTheme.formFieldRadius),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.formFieldRadius),
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.calendar, color: AppColors.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatDate(_selectedDate),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    daysRemaining > 0
                        ? '$daysRemaining days remaining'
                        : 'Target date passed',
                    style: TextStyle(
                      fontSize: 12,
                      color: daysRemaining > 0
                          ? colorScheme.onSurface.withValues(alpha: 0.6)
                          : AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              color: colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalTypeSelector(ColorScheme colorScheme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: GoalType.values.map((type) {
        final isSelected = _selectedType == type;
        return GestureDetector(
          onTap: () {
            if (isSelected) return;
            AppHaptics.selection();
            setState(() => _selectedType = type);
          },
          child: AnimatedContainer(
            duration: AppMotion.fast,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : colorScheme.outline.withValues(alpha: 0.3),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getGoalTypeIcon(type),
                  size: 18,
                  color: isSelected
                      ? AppColors.primary
                      : colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 6),
                Text(
                  type.displayName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected
                        ? AppColors.primary
                        : colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildColorSelector(ColorScheme colorScheme) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _colorOptions.map((option) {
        final colorValue = option['color'] as int;
        final isSelected = _selectedColor == colorValue;

        return GestureDetector(
          onTap: () {
            if (isSelected) return;
            AppHaptics.selection();
            setState(() => _selectedColor = colorValue);
          },
          child: AnimatedContainer(
            duration: AppMotion.fast,
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Color(colorValue),
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? colorScheme.onSurface : Colors.transparent,
                width: 3,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Color(colorValue).withValues(alpha: 0.4),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: isSelected
                ? const Icon(LucideIcons.check, color: Colors.white, size: 22)
                : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecurringToggle(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.formFieldRadius),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          SwitchListTile(
            title: Text(
              'Recurring Goal',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            subtitle: Text(
              'Goal will reset after completion',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            value: _isRecurring,
            onChanged: (value) {
              AppHaptics.selection();
              setState(() {
                _isRecurring = value;
                if (!value) _recurringPeriod = null;
              });
            },
            activeThumbColor: AppColors.primary,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          ),
          if (_isRecurring) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child:
                        _buildPeriodOption('monthly', 'Monthly', colorScheme),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildPeriodOption('yearly', 'Yearly', colorScheme),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPeriodOption(
      String value, String label, ColorScheme colorScheme) {
    final isSelected = _recurringPeriod == value;
    return GestureDetector(
      onTap: () {
        if (isSelected) return;
        AppHaptics.selection();
        setState(() => _recurringPeriod = value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.formFieldRadius),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : colorScheme.outline.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? AppColors.primary : colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUpdateButton(ColorScheme colorScheme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleUpdateGoal,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.formFieldRadius),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.save, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Update Goal',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildCancelButton(ColorScheme colorScheme) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: () => Navigator.pop(context),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.formFieldRadius),
          ),
        ),
        child: Text(
          'Cancel',
          style: TextStyle(
            fontSize: 16,
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }

  IconData _getGoalTypeIcon(GoalType type) => type.icon;

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primary,
                ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  void _handleUpdateGoal() {
    if (_formKey.currentState!.validate()) {
      if (_isRecurring && _recurringPeriod == null) {
        AppSnackbar.showError(context,
            message: 'Please select a recurring period');
        return;
      }

      final updatedGoal = widget.goal.copyWith(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _selectedType,
        targetAmount:
            double.parse(_targetAmountController.text.replaceAll(',', '')),
        targetDate: _selectedDate,
        color: _selectedColor,
        isRecurring: _isRecurring,
        recurringPeriod: _recurringPeriod,
      );

      context.read<GoalsBloc>().add(UpdateGoal(updatedGoal));
    } else {
      AppHaptics.error();
    }
  }
}

extension GoalTypeExtension on GoalType {
  String get displayName {
    switch (this) {
      case GoalType.savings:
        return 'Savings';
      case GoalType.debt:
        return 'Debt';
      case GoalType.investment:
        return 'Investment';
      case GoalType.emergency:
        return 'Emergency';
      case GoalType.vacation:
        return 'Vacation';
      case GoalType.home:
        return 'Home';
      case GoalType.education:
        return 'Education';
      case GoalType.other:
        return 'Other';
    }
  }
}
