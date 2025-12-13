import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/goal_model.dart';
import '../../auth/auth_bloc.dart';
import '../goals_bloc.dart';
import '../../../shared/widgets/app_snackbar.dart';

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
  int _selectedColor = 0xFF084879; // Default primary color
  bool _isRecurring = false;
  String? _recurringPeriod;

  final List<int> _colorOptions = [
    0xFF084879, // Primary
    0xFF38A169, // Success
    0xFFE53E3E, // Error
    0xFFF56505, // Warning
    0xFF3182CE, // Blue
    0xFF805AD5, // Purple
    0xFFD69E2E, // Yellow
    0xFF319795, // Teal
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
      _selectedColor = data['color'] ?? 0xFF084879;
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
      ),
      body: BlocListener<GoalsBloc, GoalsState>(
        listener: (context, state) {
          if (state is GoalsSuccess) {
            AppSnackbar.showSuccess(context, message: state.message);
            Navigator.pop(context);
          } else if (state is GoalsError) {
            AppSnackbar.showError(context, message: state.message);
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildBasicInfoSection(),
                const SizedBox(height: 24),
                _buildGoalTypeSection(),
                const SizedBox(height: 24),
                _buildTargetSection(),
                const SizedBox(height: 24),
                _buildColorSection(),
                const SizedBox(height: 24),
                _buildRecurringSection(),
                const SizedBox(height: 32),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
                const Icon(Icons.flag, color: AppColors.primary, size: 32),
                const SizedBox(width: 12),
                Text(
                  'Create Financial Goal',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Set a clear financial target and track your progress',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Basic Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Goal Name',
                hintText: 'e.g., Emergency Fund, Vacation Savings',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.edit),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a goal name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Describe your goal and why it\'s important to you',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalTypeSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Goal Type',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: GoalType.values.map((type) {
                final isSelected = _selectedType == type;
                return ChoiceChip(
                  label: Text(type.displayName),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedType = type;
                      });
                    }
                  },
                  backgroundColor: AppColors.surface,
                  selectedColor: AppColors.primary.withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onBackground,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Target & Timeline',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _targetAmountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Target Amount',
                hintText: '0.00',
                border: OutlineInputBorder(),
                prefixText: '\$',
                prefixIcon: Icon(Icons.account_balance_wallet),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a target amount';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Please enter a valid amount';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text('Target Date'),
              subtitle: Text(
                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 3650)), // 10 years
                );
                if (date != null) {
                  setState(() {
                    _selectedDate = date;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Goal Color',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _colorOptions.map((color) {
                final isSelected = _selectedColor == color;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColor = color;
                    });
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Color(color),
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: AppColors.primary, width: 3)
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 24,
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecurringSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recurring Goal',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text('Make this a recurring goal'),
              subtitle: Text('Automatically reset after completion'),
              value: _isRecurring,
              onChanged: (value) {
                setState(() {
                  _isRecurring = value;
                  if (!value) {
                    _recurringPeriod = null;
                  }
                });
              },
            ),
            if (_isRecurring) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _recurringPeriod,
                decoration: const InputDecoration(
                  labelText: 'Recurring Period',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.repeat),
                ),
                items: const [
                  DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                  DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
                ],
                onChanged: (value) {
                  setState(() {
                    _recurringPeriod = value;
                  });
                },
                validator: (value) {
                  if (_isRecurring && value == null) {
                    return 'Please select a recurring period';
                  }
                  return null;
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text('Cancel'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _handleCreateGoal,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textInverse,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text('Create Goal'),
          ),
        ),
      ],
    );
  }

  void _handleCreateGoal() {
    if (_formKey.currentState!.validate()) {
      final user = context.read<AuthBloc>().state;
      if (user is AuthAuthenticated) {
        final goal = Goal(
          id: const Uuid().v4(),
          userId: user.user.id,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          type: _selectedType,
          targetAmount: double.parse(_targetAmountController.text),
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
}

extension GoalTypeExtension on GoalType {
  String get displayName {
    switch (this) {
      case GoalType.savings:
        return 'Savings';
      case GoalType.debt:
        return 'Debt Repayment';
      case GoalType.investment:
        return 'Investment';
      case GoalType.emergency:
        return 'Emergency Fund';
      case GoalType.vacation:
        return 'Vacation';
      case GoalType.home:
        return 'Home Purchase';
      case GoalType.education:
        return 'Education';
      case GoalType.other:
        return 'Other';
    }
  }
}
