import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/goal_template_model.dart';
import '../../../core/services/enhanced_goal_service.dart';
import '../../auth/auth_bloc.dart';
import '../../../shared/widgets/app_snackbar.dart';

class GoalTemplatesScreen extends StatefulWidget {
  const GoalTemplatesScreen({super.key});

  @override
  State<GoalTemplatesScreen> createState() => _GoalTemplatesScreenState();
}

class _GoalTemplatesScreenState extends State<GoalTemplatesScreen>
    with TickerProviderStateMixin {
  final EnhancedGoalService _goalService = EnhancedGoalService();
  late TabController _tabController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  List<GoalTemplate> _templates = [];
  List<GoalTemplate> _filteredTemplates = [];
  bool _isLoading = true;
  String _searchQuery = '';
  GoalTemplateCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Initialize animation controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    // Initialize animations
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _loadTemplates();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadTemplates() async {
    setState(() => _isLoading = true);
    try {
      final templates = await _goalService.getGoalTemplates();
      setState(() {
        _templates = templates;
        _filteredTemplates = templates;
        _isLoading = false;
      });
      
      // Start animations after data is loaded
      _fadeController.forward();
      _slideController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
      AppSnackbar.showError(context, message: 'Failed to load templates');
    }
  }

  void _filterTemplates() {
    setState(() {
      _filteredTemplates = _templates.where((template) {
        final matchesSearch = _searchQuery.isEmpty ||
            template.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            template.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            template.tags.any((tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()));
        
        final matchesCategory = _selectedCategory == null || template.category == _selectedCategory;
        
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Goal Templates'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.lightTextInverse,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.lightTextInverse,
          labelColor: AppColors.lightTextInverse,
          unselectedLabelColor: AppColors.lightTextInverse.withOpacity(0.7),
          tabs: const [
            Tab(text: 'Browse Templates'),
            Tab(text: 'Popular'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBrowseTemplatesTab(),
          _buildPopularTemplatesTab(),
        ],
      ),
    );
  }

  Widget _buildBrowseTemplatesTab() {
    return Column(
      children: [
        _buildSearchAndFilter(),
        Expanded(
          child: _isLoading
              ? _buildLoadingState()
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: _buildTemplatesGrid(),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildPopularTemplatesTab() {
    return FutureBuilder<List<GoalTemplate>>(
      future: _goalService.getPopularTemplates(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading popular templates',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please check your internet connection and try again.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
        
        final popularTemplates = snapshot.data ?? [];
        
        if (popularTemplates.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.star_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No popular templates yet',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Popular templates will appear here as users create and complete goals',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
        
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.8,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: popularTemplates.length,
          itemBuilder: (context, index) {
            return _buildTemplateCard(popularTemplates[index]);
          },
        );
      },
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Search templates...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value);
              _filterTemplates();
            },
          ),
          const SizedBox(height: 16),
          // Category filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCategoryChip('All', null),
                const SizedBox(width: 8),
                ...GoalTemplateCategory.values.map(
                  (category) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildCategoryChip(_getCategoryDisplayName(category), category),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, GoalTemplateCategory? category) {
    final isSelected = _selectedCategory == category;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedCategory = selected ? category : null;
          _filterTemplates();
        });
      },
      selectedColor: AppColors.primary.withOpacity(0.2),
      checkmarkColor: AppColors.primary,
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading Templates...',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Discovering amazing goal templates',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary.withOpacity(0.7),
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
            Icon(
              Icons.search_off,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No templates found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filter',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _filteredTemplates.length,
      itemBuilder: (context, index) {
        final template = _filteredTemplates[index];
        return AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - _fadeAnimation.value)),
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: _buildTemplateCard(template),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTemplateCard(GoalTemplate template) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.9 + (0.1 * value),
          child: Card(
            elevation: 2 + (2 * value),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: InkWell(
              onTap: () => _showTemplateDetails(template),
              borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon and category
              Row(
                children: [
                  Text(
                    template.icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const Spacer(),
                  if (template.isPopular)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Popular',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // Title
              Text(
                template.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // Description
              Expanded(
                child: Text(
                  template.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 12),
              // Difficulty and amount
              Row(
                children: [
                  _buildDifficultyChip(template.difficulty),
                  const Spacer(),
                  Text(
                    '\$${template.suggestedAmount.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Duration
              Text(
                '${template.suggestedDurationMonths} months',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    ));
      },
    );
  }

  Widget _buildDifficultyChip(GoalTemplateDifficulty difficulty) {
    Color color;
    String label;
    
    switch (difficulty) {
      case GoalTemplateDifficulty.easy:
        color = AppColors.success;
        label = 'Easy';
        break;
      case GoalTemplateDifficulty.medium:
        color = AppColors.warning;
        label = 'Medium';
        break;
      case GoalTemplateDifficulty.hard:
        color = AppColors.error;
        label = 'Hard';
        break;
      case GoalTemplateDifficulty.expert:
        color = AppColors.primary;
        label = 'Expert';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showTemplateDetails(GoalTemplate template) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildTemplateDetailsSheet(template),
    );
  }

  Widget _buildTemplateDetailsSheet(GoalTemplate template) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Text(
                        template.icon,
                        style: const TextStyle(fontSize: 48),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              template.name,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getCategoryDisplayName(template.category),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildDifficultyChip(template.difficulty),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Description
                  Text(
                    template.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  // Details
                  _buildDetailRow('Target Amount', '\$${template.suggestedAmount.toStringAsFixed(0)}'),
                  _buildDetailRow('Duration', '${template.suggestedDurationMonths} months'),
                  _buildDetailRow('Difficulty', _getDifficultyDisplayName(template.difficulty)),
                  _buildDetailRow('Completion Rate', '${(template.completionRate * 100).toStringAsFixed(0)}%'),
                  const SizedBox(height: 24),
                  // Tags
                  if (template.tags.isNotEmpty) ...[
                    Text(
                      'Tags',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: template.tags.map((tag) => Chip(
                        label: Text(tag),
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        labelStyle: TextStyle(color: AppColors.primary),
                      )).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],
                  // Tips
                  if (template.metadata['tips'] != null) ...[
                    Text(
                      'Tips',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...(template.metadata['tips'] as List<dynamic>).map((tip) => 
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                            Expanded(child: Text(tip.toString())),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _createGoalFromTemplate(template),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                          ),
                          child: const Text(
                            'Create Goal',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(
            '$label:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Future<void> _createGoalFromTemplate(GoalTemplate template) async {
    try {
      final user = context.read<AuthBloc>().state;
      if (user is AuthAuthenticated) {
        await _goalService.createGoalFromTemplate(template, user.user.id);
        Navigator.pop(context); // Close template details
        Navigator.pop(context); // Close templates screen
        AppSnackbar.showSuccess(context, message: 'Goal created from template!');
      }
    } catch (e) {
      AppSnackbar.showError(context, message: 'Failed to create goal: $e');
    }
  }

  String _getCategoryDisplayName(GoalTemplateCategory category) {
    switch (category) {
      case GoalTemplateCategory.house:
        return 'House';
      case GoalTemplateCategory.car:
        return 'Car';
      case GoalTemplateCategory.vacation:
        return 'Vacation';
      case GoalTemplateCategory.education:
        return 'Education';
      case GoalTemplateCategory.emergency:
        return 'Emergency';
      case GoalTemplateCategory.retirement:
        return 'Retirement';
      case GoalTemplateCategory.wedding:
        return 'Wedding';
      case GoalTemplateCategory.business:
        return 'Business';
      case GoalTemplateCategory.health:
        return 'Health';
      case GoalTemplateCategory.other:
        return 'Other';
    }
  }

  String _getDifficultyDisplayName(GoalTemplateDifficulty difficulty) {
    switch (difficulty) {
      case GoalTemplateDifficulty.easy:
        return 'Easy';
      case GoalTemplateDifficulty.medium:
        return 'Medium';
      case GoalTemplateDifficulty.hard:
        return 'Hard';
      case GoalTemplateDifficulty.expert:
        return 'Expert';
    }
  }
}
