import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/constants/goal_type_icons.dart';
import '../../../core/models/goal_model.dart';
import '../../auth/auth_bloc.dart';
import '../goals_bloc.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/premium_upgrade_prompt.dart';
import '../../../core/services/currency_service.dart';
import '../../../shared/widgets/field_label.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CreateGoalScreen extends StatefulWidget {
  final Map<String, dynamic>? prefillData;

  const CreateGoalScreen({super.key, this.prefillData});

  @override
  State<CreateGoalScreen> createState() => _CreateGoalScreenState();
}

class _CreateGoalScreenState extends State<CreateGoalScreen>
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
    if (widget.prefillData != null) {
      final data = widget.prefillData!;
      _nameController.text = data['name'] ?? '';
      _descriptionController.text = data['description'] ?? '';
      _targetAmountController.text = data['targetAmount']?.toString() ?? '';
      _selectedType = data['type'] ?? GoalType.savings;
      _selectedDate =
          data['targetDate'] ?? DateTime.now().add(const Duration(days: 365));
      _selectedColor = data['color'] ?? 0xFF0079DC;
    }
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
    final isDark = theme.brightness == Brightness.dark;
    final saveIconColor = isDark ? Colors.white : colorScheme.onSurface;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Create Goal'),
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        titleTextStyle: theme.textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _handleCreateGoal,
            child: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: saveIconColor,
                    ),
                  )
                : Text(
                    'Save',
                    style: TextStyle(
                      color: saveIconColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
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
            AppSnackbar.showSuccess(context, message: state.message);
            Navigator.pop(context);
          } else if (state is GoalsError) {
            if (state.message.contains('Upgrade to Flux Pro')) {
              PremiumUpgradePrompt.show(context, message: state.message);
            } else {
              AppSnackbar.showError(context, message: state.message);
            }
          }
        },
        child: FadeTransition(
          opacity: _entranceFade,
          child: SlideTransition(
            position: _entranceSlide,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSectionTitle('Goal Name', icon: LucideIcons.flag),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      decoration: _inputDecoration(
                        hintText: 'e.g., Emergency Fund',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a goal name';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Target Amount
                    _buildSectionTitle('Target Amount',
                        icon: LucideIcons.wallet),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _targetAmountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: _inputDecoration(
                        hintText: 'Enter target amount',
                        prefixText: '${CurrencyService().symbol} ',
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
                    ),

                    const SizedBox(height: 20),

                    // Target Date
                    _buildSectionTitle('Deadline'),
                    const SizedBox(height: 8),
                    _buildDateSelector(colorScheme),

                    const SizedBox(height: 20),

                    // Goal Type
                    _buildSectionTitle('Goal Type'),
                    const SizedBox(height: 8),
                    _buildGoalTypeSelector(colorScheme),

                    const SizedBox(height: 20),

                    // Description
                    _buildSectionTitle('Description',
                        icon: LucideIcons.fileText),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 2,
                      decoration: _inputDecoration(
                        hintText: 'Add details (optional)',
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Color Selection
                    _buildSectionTitle('Color'),
                    const SizedBox(height: 8),
                    _buildColorSelector(colorScheme),

                    const SizedBox(height: 20),

                    // Recurring Toggle
                    _buildRecurringToggle(colorScheme),

                    const SizedBox(height: 32),

                    // Create Button (Bottom)
                    _buildCreateButton(colorScheme),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, {IconData? icon}) {
    if (icon != null) return FieldLabel(icon: icon, label: title);
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    String? prefixText,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return InputDecoration(
      hintText: hintText,
      prefixText: prefixText,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.error, width: 2),
      ),
      hintStyle: theme.textTheme.bodyLarge?.copyWith(
        color: colorScheme.onSurface.withValues(alpha: 0.45),
      ),
      prefixStyle: theme.textTheme.bodyLarge?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w500,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildDateSelector(ColorScheme colorScheme) {
    final daysRemaining = _selectedDate.difference(DateTime.now()).inDays;

    return InkWell(
      onTap: _selectDate,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(LucideIcons.calendar,
                  size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatDate(_selectedDate),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    daysRemaining > 0
                        ? '$daysRemaining days until goal reached'
                        : 'Deadline has passed',
                    style: TextStyle(
                      fontSize: 13,
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : colorScheme.outline.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getGoalTypeIcon(type),
                  size: 17,
                  color: isSelected
                      ? AppColors.primary
                      : colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 8),
                Text(
                  type.typeDisplayName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? AppColors.primary
                        : colorScheme.onSurface.withValues(alpha: 0.7),
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
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          SwitchListTile(
            title: Text(
              'Recurring Goal',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            subtitle: Text(
              'Reset progress automatically after completion',
              style: TextStyle(
                fontSize: 13,
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
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          if (_isRecurring) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
      child: AnimatedContainer(
        duration: AppMotion.fast,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : colorScheme.outline.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? AppColors.primary
                  : colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCreateButton(ColorScheme colorScheme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleCreateGoal,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
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
                'Create Goal',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  void _handleCreateGoal() {
    if (_formKey.currentState!.validate()) {
      if (_isRecurring && _recurringPeriod == null) {
        AppSnackbar.showError(context,
            message: 'Please select a recurring period');
        return;
      }

      final user = context.read<AuthBloc>().state;
      if (user is AuthAuthenticated) {
        final goal = Goal(
          id: const Uuid().v4(),
          userId: user.user.id,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          type: _selectedType,
          targetAmount:
              double.parse(_targetAmountController.text.replaceAll(',', '')),
          currentAmount: 0.0,
          status: GoalStatus.active,
          targetDate: _selectedDate,
          createdAt: DateTime.now(),
          color: _selectedColor,
          isRecurring: _isRecurring,
          recurringPeriod: _recurringPeriod,
        );

        context.read<GoalsBloc>().add(CreateGoal(goal));
      }
    } else {
      AppHaptics.error();
    }
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
}
