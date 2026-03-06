import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/models/goal_template_model.dart';
import '../../../core/services/enhanced_goal_service.dart';
import '../../../core/services/currency_service.dart';
import '../../auth/auth_bloc.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../goals_bloc.dart';

class GoalTemplatesScreen extends StatefulWidget {
  const GoalTemplatesScreen({super.key});

  static String getTemplateEmoji(GoalTemplateCategory category) {
    switch (category) {
      case GoalTemplateCategory.retirement: return '🏖️';
      case GoalTemplateCategory.health: return '🏥';
      case GoalTemplateCategory.business: return '💼';
      case GoalTemplateCategory.house: return '🏠';
      case GoalTemplateCategory.vacation: return '✈️';
      case GoalTemplateCategory.emergency: return '🚨';
      case GoalTemplateCategory.car: return '🚗';
      case GoalTemplateCategory.education: return '🎓';
      case GoalTemplateCategory.wedding: return '💍';
      case GoalTemplateCategory.other: return '🎯';
    }
  }

  @override
  State<GoalTemplatesScreen> createState() => _GoalTemplatesScreenState();
}

class _GoalTemplatesScreenState extends State<GoalTemplatesScreen>
    with TickerProviderStateMixin {
  final EnhancedGoalService _goalService = EnhancedGoalService();
  final CurrencyService _currencyService = CurrencyService();
  
  List<GoalTemplate> _templates = [];
  List<GoalTemplate> _filteredTemplates = [];
  bool _isLoading = true;
  String _searchQuery = '';
  GoalTemplateCategory? _selectedCategory;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _loadTemplates();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadTemplates() async {
    setState(() => _isLoading = true);
    try {
      final templates = await _goalService.getGoalTemplates();
      if (mounted) {
        setState(() {
          _templates = templates;
          _filteredTemplates = templates;
          _isLoading = false;
        });
        _fadeController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppSnackbar.showError(context, message: 'Error loading templates');
      }
    }
  }

  void _filterTemplates() {
    setState(() {
      _filteredTemplates = _templates.where((t) {
        final matchesSearch = t.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            t.description.toLowerCase().contains(_searchQuery.toLowerCase());
        final matchesCategory = _selectedCategory == null || t.category == _selectedCategory;
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: const Text('Goal Templates'),
        centerTitle: false,
        backgroundColor: isDark ? Colors.black : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(context),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildTemplatesGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.onSurface.withOpacity(0.05),
          ),
        ),
      ),
      child: Column(
        children: [
          TextField(
            onChanged: (value) {
              _searchQuery = value;
              _filterTemplates();
            },
            decoration: InputDecoration(
              hintText: 'Search templates...',
              prefixIcon: const Icon(Icons.search, size: 20),
              filled: true,
              fillColor: colorScheme.onSurface.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: GoalTemplateCategory.values.map((category) {
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category.name[0].toUpperCase() + category.name.substring(1)),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = selected ? category : null;
                        _filterTemplates();
                      });
                    },
                    selectedColor: AppColors.primary.withOpacity(0.2),
                    checkmarkColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.primary : colorScheme.onSurface,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplatesGrid() {
    if (_filteredTemplates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: AppColors.primary.withOpacity(0.3)),
            const SizedBox(height: 16),
            const Text('No templates found'),
          ],
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.85,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _filteredTemplates.length,
        itemBuilder: (context, index) {
          final template = _filteredTemplates[index];
          return _buildTemplateCard(template);
        },
      ),
    );
  }

  Widget _buildTemplateCard(GoalTemplate template) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: () => _showTemplateDetails(template),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.onSurface.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Center(
                child: Text(
                  GoalTemplatesScreen.getTemplateEmoji(template.category),
                  style: const TextStyle(fontSize: 40),
                ),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.timer_outlined, size: 14, color: colorScheme.onSurface.withOpacity(0.4)),
                      const SizedBox(width: 4),
                      Text(
                        '${template.suggestedDurationMonths}m',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.4),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _currencyService.formatAmount(template.suggestedAmount),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTemplateDetails(GoalTemplate template) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TemplateDetailsSheet(
        template: template,
        goalService: _goalService,
        currencyService: _currencyService,
      ),
    );
  }
}

class _TemplateDetailsSheet extends StatefulWidget {
  final GoalTemplate template;
  final EnhancedGoalService goalService;
  final CurrencyService currencyService;

  const _TemplateDetailsSheet({
    required this.template,
    required this.goalService,
    required this.currencyService,
  });

  @override
  State<_TemplateDetailsSheet> createState() => _TemplateDetailsSheetState();
}

class _TemplateDetailsSheetState extends State<_TemplateDetailsSheet> {
  late TextEditingController _amountController;
  int _selectedDurationMonths = 12;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.template.suggestedAmount.toStringAsFixed(0),
    );
    _selectedDurationMonths = widget.template.suggestedDurationMonths;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.template.name,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.template.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    GoalTemplatesScreen.getTemplateEmoji(widget.template.category),
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              'Target Amount',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
              decoration: InputDecoration(
                prefixText: '${widget.currencyService.symbol} ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: colorScheme.onSurface.withOpacity(0.1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: colorScheme.onSurface.withOpacity(0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Timeline',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListWheelScrollView.useDelegate(
                itemExtent: 40,
                perspective: 0.005,
                diameterRatio: 1.2,
                physics: const FixedExtentScrollPhysics(),
                onSelectedItemChanged: (index) {
                  setState(() => _selectedDurationMonths = index + 1);
                },
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: 60,
                  builder: (context, index) {
                    final months = index + 1;
                    final isSelected = _selectedDurationMonths == months;
                    return Center(
                      child: Text(
                        '$months months',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: isSelected ? AppColors.primary : colorScheme.onSurface,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isCreating ? null : _createGoal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isCreating
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Create Goal',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _createGoal() async {
    final amountText = _amountController.text.replaceAll(',', '');
    final amount = double.tryParse(amountText) ?? widget.template.suggestedAmount;
    
    setState(() => _isCreating = true);
    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        await widget.goalService.createGoalFromTemplate(
          widget.template,
          authState.user.id,
          customAmount: amount,
          customDurationMonths: _selectedDurationMonths,
        );
        
        if (mounted) {
          context.read<GoalsBloc>().add(LoadGoals(authState.user.id));
          Navigator.pop(context); // Close sheet
          Navigator.pop(context); // Close screen
          AppSnackbar.showSuccess(context, message: 'Goal created successfully!');
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(context, message: 'Failed to create goal');
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }
}
