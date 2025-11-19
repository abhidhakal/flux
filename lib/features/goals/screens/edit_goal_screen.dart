import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/goal_model.dart';
import '../goals_bloc.dart';
import '../../../shared/widgets/app_snackbar.dart';

class EditGoalScreen extends StatefulWidget {
  final Goal goal;

  const EditGoalScreen({super.key, required this.goal});

  @override
  State<EditGoalScreen> createState() => _EditGoalScreenState();
}

class _EditGoalScreenState extends State<EditGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetAmountController = TextEditingController();
  
  GoalType _selectedType = GoalType.savings;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 365));
  int _selectedColor = 0xFF084879;
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
    final goal = widget.goal;
    _nameController.text = goal.name;
    _descriptionController.text = goal.description;
    _targetAmountController.text = goal.targetAmount.toString();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: const Text('Edit Goal'),
        centerTitle: false,
        backgroundColor: colorScheme.background,
        foregroundColor: colorScheme.onBackground,
        iconTheme: IconThemeData(color: colorScheme.onBackground),
        titleTextStyle: TextStyle(
          color: colorScheme.onBackground,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: BlocListener<GoalsBloc, GoalsState>(
        listener: (context, state) {
          if (state is GoalsSuccess) {
            AppSnackbar.showSuccess(context, message: state.message);
            Navigator.pop(context);
          }
          
          if (state is GoalsError) {
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
                const Icon(Icons.edit, color: AppColors.primary, size: 32),
                const SizedBox(width: 12),
                const Text(
                  'Edit Financial Goal',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Update your goal details and track your progress',
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
            const Text(
              'Basic Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
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
            const Text(
              'Goal Type',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<GoalType>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Select Goal Type',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: GoalType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.displayName),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
              },
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
            const Text(
              'Target Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _targetAmountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Target Amount',
                hintText: 'Enter target amount',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter target amount';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid amount';
                }
                if (double.parse(value) <= 0) {
                  return 'Amount must be greater than 0';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _selectDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Target Date',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
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
            const Text(
              'Goal Color',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _colorOptions.map((color) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColor = color;
                    });
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(color),
                      shape: BoxShape.circle,
                      border: _selectedColor == color
                          ? Border.all(color: AppColors.textPrimary, width: 3)
                          : null,
                    ),
                    child: _selectedColor == color
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
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
            const Text(
              'Recurring Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Make this a recurring goal'),
              subtitle: const Text('Goal will reset after completion'),
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
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _handleUpdateGoal,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textInverse,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Update Goal'),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  void _handleUpdateGoal() {
    if (_formKey.currentState!.validate()) {
      final updatedGoal = widget.goal.copyWith(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _selectedType,
        targetAmount: double.parse(_targetAmountController.text),
        targetDate: _selectedDate,
        color: _selectedColor,
        isRecurring: _isRecurring,
        recurringPeriod: _recurringPeriod,
      );

      context.read<GoalsBloc>().add(UpdateGoal(updatedGoal));
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
