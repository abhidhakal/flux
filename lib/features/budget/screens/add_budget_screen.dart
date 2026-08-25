import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/constants/categories.dart';
import '../../../core/models/budget_model.dart';
import '../../../core/services/currency_service.dart';
import '../../auth/auth_bloc.dart';
import '../../budget/budget_bloc.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/premium_upgrade_prompt.dart';
import '../../../shared/widgets/field_label.dart';
import '../../../shared/widgets/app_form_fields.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AddBudgetScreen extends StatefulWidget {
  const AddBudgetScreen({super.key});

  @override
  State<AddBudgetScreen> createState() => _AddBudgetScreenState();
}

class _AddBudgetScreenState extends State<AddBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _weeklyTargetController = TextEditingController();

  BudgetPeriod _selectedPeriod = BudgetPeriod.monthly;
  String _selectedCategory = AppCategories.expenseCategories.first;
  bool _enableRollover = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _weeklyTargetController.dispose();
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
        title: const Text('Add Budget'),
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
            onPressed: _isLoading ? null : _handleSave,
            child: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: saveIconColor),
                  )
                : Text(
                    'Save',
                    style: TextStyle(
                      color: saveIconColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: BlocListener<BudgetBloc, BudgetState>(
        listener: (context, state) {
          if (state is BudgetLoading) {
            setState(() => _isLoading = true);
          } else {
            setState(() => _isLoading = false);
          }

          if (state is BudgetSuccess) {
            AppSnackbar.showSuccess(context, message: state.message);
            Navigator.pop(context);
          }

          if (state is BudgetError) {
            if (state.message.contains('Upgrade to Flux Pro')) {
              PremiumUpgradePrompt.show(context, message: state.message);
            } else {
              AppSnackbar.showError(context, message: state.message);
            }
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSectionTitle('Budget Name', icon: LucideIcons.type),
                const SizedBox(height: 8),
                AppTextField(
                  controller: _nameController,
                  hintText: 'e.g., Monthly Food Budget',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a budget name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _buildSectionTitle('Amount', icon: LucideIcons.dollarSign),
                const SizedBox(height: 8),
                AppNumberField(
                  controller: _amountController,
                  hintText: 'Enter amount',
                  prefixText: '${CurrencyService().symbol} ',
                  decimal: true,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter an amount';
                    }
                    final amount = double.tryParse(value);
                    if (amount == null || amount <= 0) {
                      return 'Please enter a valid amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _buildSectionTitle('Weekly Target', icon: LucideIcons.target),
                const SizedBox(height: 8),
                AppNumberField(
                  controller: _weeklyTargetController,
                  hintText: 'Optional spending limit per week',
                  prefixText: '${CurrencyService().symbol} ',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return null;
                    final amount = double.tryParse(value);
                    if (amount == null || amount <= 0) {
                      return 'Enter a valid weekly target';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _buildSectionTitle('Category', icon: LucideIcons.tag),
                const SizedBox(height: 8),
                AppDropdownField<String>(
                  value: _selectedCategory,
                  items: AppCategories.expenseCategories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.circle,
                            size: 10,
                            color: Color(AppCategories.getColor(category)),
                          ),
                          const SizedBox(width: 8),
                          Text(category),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) =>
                      setState(() => _selectedCategory = value!),
                ),
                const SizedBox(height: 20),
                _buildSectionTitle('Period'),
                const SizedBox(height: 8),
                _buildPeriodSelector(),
                const SizedBox(height: 20),
                _buildRolloverToggle(),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.formFieldRadius)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Create Budget',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ],
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

  Widget _buildPeriodSelector() {
    return Row(
      children: BudgetPeriod.values.map((period) {
        final isSelected = _selectedPeriod == period;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedPeriod = period),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : Theme.of(context)
                          .colorScheme
                          .outline
                          .withValues(alpha: 0.4),
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(AppTheme.formFieldRadius),
              ),
              child: Text(
                period.name[0].toUpperCase() + period.name.substring(1),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                  color: isSelected
                      ? AppColors.primary
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRolloverToggle() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(AppTheme.formFieldRadius),
      ),
      child: SwitchListTile(
        title: Text(
          'Enable Rollover',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          'Unused budget carries over to next period',
          style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6)),
        ),
        value: _enableRollover,
        onChanged: (value) => setState(() => _enableRollover = value),
        activeThumbColor: AppColors.primary,
      ),
    );
  }

  void _handleSave() {
    if (!_formKey.currentState!.validate()) return;

    final user = context.read<AuthBloc>().state;
    if (user is! AuthAuthenticated) return;

    final now = DateTime.now();
    final startDate = _getStartDate(now, _selectedPeriod);
    final endDate = _getEndDate(startDate, _selectedPeriod);
    final weeklyTarget =
        double.tryParse(_weeklyTargetController.text.trim()) ?? 0;

    final budget = Budget(
      id: '',
      userId: user.user.id,
      name: _nameController.text.trim(),
      amount: double.parse(_amountController.text.trim()),
      period: _selectedPeriod,
      category: _selectedCategory,
      startDate: startDate,
      endDate: endDate,
      createdAt: now,
      enableRollover: _enableRollover,
      weeklyTarget: weeklyTarget,
    );

    context.read<BudgetBloc>().add(CreateBudget(budget));
  }

  DateTime _getStartDate(DateTime now, BudgetPeriod period) {
    switch (period) {
      case BudgetPeriod.daily:
        return DateTime(now.year, now.month, now.day);
      case BudgetPeriod.weekly:
        final weekday = now.weekday;
        return DateTime(now.year, now.month, now.day - weekday + 1);
      case BudgetPeriod.monthly:
        return DateTime(now.year, now.month, 1);
      case BudgetPeriod.yearly:
        return DateTime(now.year, 1, 1);
    }
  }

  DateTime _getEndDate(DateTime startDate, BudgetPeriod period) {
    switch (period) {
      case BudgetPeriod.daily:
        return DateTime(
            startDate.year, startDate.month, startDate.day, 23, 59, 59);
      case BudgetPeriod.weekly:
        return startDate
            .add(const Duration(days: 7))
            .subtract(const Duration(seconds: 1));
      case BudgetPeriod.monthly:
        return DateTime(startDate.year, startDate.month + 1, 1)
            .subtract(const Duration(seconds: 1));
      case BudgetPeriod.yearly:
        return DateTime(startDate.year + 1, 1, 1)
            .subtract(const Duration(seconds: 1));
    }
  }
}
