import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/goal_model.dart';
import '../../auth/auth_bloc.dart';
import '../goals_bloc.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../core/services/currency_service.dart';

class CreateGoalScreen extends StatefulWidget {
  final Map<String, dynamic>? prefillData;

  const CreateGoalScreen({super.key, this.prefillData});

  @override
  State<CreateGoalScreen> createState() => _CreateGoalScreenState();
}

class _CreateGoalScreenState extends State<CreateGoalScreen> {
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

  final List<Map<String, dynamic>> _colorOptions = [
    {'color': 0xFF0079DC, 'name': 'Blue'},
    {'color': 0xFF00C851, 'name': 'Green'},
    {'color': 0xFFFF6B6B, 'name': 'Coral'},
    {'color': 0xFFFFB300, 'name': 'Amber'},
    {'color': 0xFF805AD5, 'name': 'Purple'},
    {'color': 0xFF00B4D8, 'name': 'Teal'},
    {'color': 0xFFE91E63, 'name': 'Pink'},
    {'color': 0xFF607D8B, 'name': 'Slate'},
  ];

  @override
  void initState() {
    super.initState();
    _prefillForm();
  }

  void _prefillForm() {
    if (widget.prefillData != null) {
      final data = widget.prefillData!;
      _nameController.text = data['name'] ?? '';
      _descriptionController.text = data['description'] ?? '';
      _targetAmountController.text = data['targetAmount']?.toString() ?? '';
      _selectedType = data['type'] ?? GoalType.savings;
      _selectedDate = data['targetDate'] ?? DateTime.now().add(const Duration(days: 365));
      _selectedColor = data['color'] ?? 0xFF0079DC;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _targetAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: const Text('Create Goal'),
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
            onPressed: _isLoading ? null : _handleCreateGoal,
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
                    'Create',
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
            AppSnackbar.showSuccess(context, message: state.message);
            Navigator.pop(context);
          } else if (state is GoalsError) {
            AppSnackbar.showError(context, message: state.message);
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Goal Name
                _buildSectionLabel('Goal Name'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: _inputDecoration(
                    hintText: 'e.g., Emergency Fund',
                    icon: Icons.flag_rounded,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a goal name';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 24),

                // Target Amount
                _buildSectionLabel('Target Amount'),
                const SizedBox(height: 8),
                TextFormField(
                    controller: _targetAmountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                    ),
                    decoration: _inputDecoration(
                        hintText: '10,000',
                        icon: Icons.attach_money_rounded,
                        prefixText: CurrencyService().symbol,
                    ),
                    validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                            return 'Please enter target amount';
                        }
                        final amount = double.tryParse(value.replaceAll(',', ''));
                        if (amount == null || amount <= 0) {
                            return 'Please enter a valid amount';
                        }
                        return null;
                    },
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
                _buildSectionLabel('Description (Optional)'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: _inputDecoration(
                    hintText: 'Why is this goal important to you?',
                    icon: Icons.notes_rounded,
                  ),
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
                
                // Create Button (Bottom)
                _buildCreateButton(colorScheme),

                const SizedBox(height: 16),
                
                 // Cancel Button
                _buildCancelButton(colorScheme),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData icon,
    String? prefixText,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.4)),
      prefixIcon: Icon(icon, color: AppColors.primary),
      prefixText: prefixText,
      prefixStyle: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      filled: true,
      fillColor: colorScheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

    Widget _buildDateSelector(ColorScheme colorScheme) {
    final daysRemaining = _selectedDate.difference(DateTime.now()).inDays;
    
    return InkWell(
      onTap: _selectDate,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_month_rounded, color: AppColors.primary),
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
                          ? colorScheme.onSurface.withOpacity(0.6) 
                          : AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: colorScheme.onSurface.withOpacity(0.4),
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
          onTap: () => setState(() => _selectedType = type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected 
                  ? AppColors.primary.withOpacity(0.1) 
                  : colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected 
                    ? AppColors.primary 
                    : colorScheme.outline.withOpacity(0.3),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getGoalTypeIcon(type),
                  size: 18,
                  color: isSelected ? AppColors.primary : colorScheme.onSurface.withOpacity(0.6),
                ),
                const SizedBox(width: 6),
                Text(
                  type.typeDisplayName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? AppColors.primary : colorScheme.onSurface.withOpacity(0.8),
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
          onTap: () => setState(() => _selectedColor = colorValue),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
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
                        color: Color(colorValue).withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 22)
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
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
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            value: _isRecurring,
            onChanged: (value) {
              setState(() {
                _isRecurring = value;
                if (!value) _recurringPeriod = null;
              });
            },
            activeColor: AppColors.primary,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          ),
          if (_isRecurring) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildPeriodOption('monthly', 'Monthly', colorScheme),
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

  Widget _buildPeriodOption(String value, String label, ColorScheme colorScheme) {
    final isSelected = _recurringPeriod == value;
    return GestureDetector(
      onTap: () => setState(() => _recurringPeriod = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : colorScheme.outline.withOpacity(0.3),
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
            borderRadius: BorderRadius.circular(12),
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
                  Icon(Icons.add_circle_outline_rounded, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Create Goal',
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
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'Cancel',
          style: TextStyle(
            fontSize: 16,
            color: colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ),
    );
  }

  void _handleCreateGoal() {
    if (_formKey.currentState!.validate()) {
      if (_isRecurring && _recurringPeriod == null) {
        AppSnackbar.showError(context, message: 'Please select a recurring period');
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
          targetAmount: double.parse(_targetAmountController.text.replaceAll(',', '')),
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
    }
  }

  IconData _getGoalTypeIcon(GoalType type) {
    switch (type) {
      case GoalType.savings:
        return Icons.savings_rounded;
      case GoalType.debt:
        return Icons.credit_card_off_rounded;
      case GoalType.investment:
        return Icons.trending_up_rounded;
      case GoalType.emergency:
        return Icons.health_and_safety_rounded;
      case GoalType.vacation:
        return Icons.flight_rounded;
      case GoalType.home:
        return Icons.home_rounded;
      case GoalType.education:
        return Icons.school_rounded;
      case GoalType.other:
        return Icons.flag_rounded;
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
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
