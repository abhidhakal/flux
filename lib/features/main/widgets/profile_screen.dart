import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import '../../../core/services/currency_service.dart';
import '../../../core/services/profile_picture_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/data_export_service.dart';
import '../../../core/models/user_model.dart';
import '../../../shared/widgets/skeleton_components.dart';
import '../../auth/auth_bloc.dart';
import '../../goals/goals_bloc.dart';
import '../../../core/models/goal_model.dart';
import '../../transaction/transaction_bloc.dart';
import '../screens/about_us_screen.dart';
import '../screens/privacy_policy_screen.dart';
import '../screens/terms_of_service_screen.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../subscription/subscription_bloc.dart';
import '../../subscription/presentation/pages/paywall_screen.dart';
import '../../../core/services/widget_service.dart';
import '../../income/income_bloc.dart';
import '../../theme/theme_bloc.dart';
import '../../notifications/screens/notification_settings_screen.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../budget/budget_bloc.dart';
import '../../../core/models/budget_model.dart';
import '../../../core/models/transaction_model.dart';
import '../../../core/models/income_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  String _selectedCountry = 'United States';
  final ImagePicker _picker = ImagePicker();
  final ProfilePictureService _profilePictureService = ProfilePictureService();

  final List<Map<String, String>> _countries = [
    {'name': 'United States', 'currency': 'USD', 'symbol': '\$'},
    {'name': 'United Kingdom', 'currency': 'GBP', 'symbol': '£'},
    {'name': 'European Union', 'currency': 'EUR', 'symbol': '€'},
    {'name': 'Japan', 'currency': 'JPY', 'symbol': '¥'},
    {'name': 'Canada', 'currency': 'CAD', 'symbol': 'C\$'},
    {'name': 'Australia', 'currency': 'AUD', 'symbol': 'A\$'},
    {'name': 'India', 'currency': 'INR', 'symbol': '₹'},
    {'name': 'China', 'currency': 'CNY', 'symbol': '¥'},
    {'name': 'Brazil', 'currency': 'BRL', 'symbol': 'R\$'},
    {'name': 'South Korea', 'currency': 'KRW', 'symbol': '₩'},
    {'name': 'Nepal', 'currency': 'NPR', 'symbol': 'Rs.'},
    {'name': 'Mexico', 'currency': 'MXN', 'symbol': '\$'},
    {'name': 'Singapore', 'currency': 'SGD', 'symbol': 'S\$'},
    {'name': 'Switzerland', 'currency': 'CHF', 'symbol': 'CHF'},
    {'name': 'New Zealand', 'currency': 'NZD', 'symbol': 'NZ\$'},
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _initializeCurrency();
    
    // Load profile image
     final authState = context.read<AuthBloc>().state;
     if (authState is AuthAuthenticated) {
        _profilePictureService.loadProfileImage(userId: authState.user.id).then((_) {
          if (mounted) setState(() {});
        });
     }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fadeController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _initializeCurrency() async {
    await CurrencyService().ensureInitialized();
    setState(() {
      _selectedCountry = CurrencyService().country;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthAuthenticated) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: _buildProfileContent(context, state.user),
            );
          }
          return _buildProfileSkeleton();
        },
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, User user) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Modern Header
        SliverToBoxAdapter(
          child: _buildModernHeader(user, colorScheme, theme),
        ),
        // Stats Row
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: BlocBuilder<GoalsBloc, GoalsState>(
              builder: (context, goalsState) {
                return _buildStatsRow(user, goalsState, colorScheme);
              },
            ),
          ),
        ),
        // Settings Sections
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildSectionHeader('General', colorScheme),
              _buildSettingsGroup([
                _SettingsItem(
                  icon: Icons.person_outline_rounded,
                  title: 'Edit Profile',
                  subtitle: user.displayName ?? user.email,
                  onTap: () => _showEditProfileDialog(user),
                ),
                _SettingsItem(
                  icon: Icons.currency_exchange_rounded,
                  title: 'Currency',
                  subtitle: _selectedCountry,
                  onTap: () => _showCurrencyPicker(),
                ),
              ], colorScheme),
              const SizedBox(height: 24),
              _buildSectionHeader('Preferences', colorScheme),
                BlocBuilder<ThemeBloc, ThemeState>(
                  builder: (context, state) {
                    String mode = 'System';
                    if (state is ThemeLoaded) {
                      if (state.themeMode == ThemeMode.light) mode = 'Light';
                      if (state.themeMode == ThemeMode.dark) mode = 'Dark';
                    }
                    return _buildSettingsGroup([
                      _SettingsItem(
                        icon: Icons.palette_outlined,
                        title: 'Appearance',
                        subtitle: mode,
                        onTap: () => _showAppearancePopup(),
                      ),
                      _SettingsItem(
                        icon: Icons.notifications_outlined,
                        title: 'Notifications',
                        subtitle: 'Manage alerts',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NotificationSettingsScreen(),
                            ),
                          );
                        },
                      ),
                    ], colorScheme);
                  },
                ),
              const SizedBox(height: 24),
              _buildSectionHeader('Subscription', colorScheme),
              BlocBuilder<SubscriptionBloc, SubscriptionState>(
                builder: (context, state) {
                  final isPremium = state is SubscriptionPremium;
                  return _buildSettingsGroup([
                    _SettingsItem(
                      icon: isPremium ? Icons.stars_rounded : Icons.star_outline_rounded,
                      title: isPremium ? 'Manage Subscription' : 'Upgrade to Premium',
                      subtitle: isPremium ? 'Active Plan' : 'Unlock all features',
                      onTap: () {
                        if (isPremium) {
                          _manageSubscription();
                        } else {
                          _navigateToPaywall();
                        }
                      },
                    ),
                  ], colorScheme);
                },
              ),
              const SizedBox(height: 24),
              _buildSectionHeader('Data & Privacy', colorScheme),
              _buildSettingsGroup([
                _SettingsItem(
                  icon: Icons.download_outlined,
                  title: 'Export Data',
                  subtitle: 'CSV or PDF',
                  onTap: () => _handleExportData(),
                ),
                _SettingsItem(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PrivacyPolicyScreen(),
                      ),
                    );
                  },
                ),
                _SettingsItem(
                  icon: Icons.description_outlined,
                  title: 'Terms of Service',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TermsOfServiceScreen(),
                      ),
                    );
                  },
                ),
              ], colorScheme),
              const SizedBox(height: 24),
              _buildSectionHeader('Support', colorScheme),
              _buildSettingsGroup([
                _SettingsItem(
                  icon: Icons.info_outline_rounded,
                  title: 'About Flux',
                  onTap: () => _navigateToAboutUs(),
                ),
              ], colorScheme),
              const SizedBox(height: 32),
              // Sign Out Button
              _buildSignOutButton(colorScheme),
              const SizedBox(height: 150),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildModernHeader(User user, ColorScheme colorScheme, ThemeData theme) {
    return Container(
      margin: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20,
        right: 20,
        bottom: 20,
      ),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark 
            ? colorScheme.surface 
            : colorScheme.surface,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.brightness == Brightness.dark 
                ? colorScheme.surface 
                : Colors.white,
            theme.brightness == Brightness.dark 
                ? colorScheme.primary.withOpacity(0.1) 
                : colorScheme.primaryContainer.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Profile Picture
          GestureDetector(
            onTap: _showImagePickerOptions,
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(4), // Ring width
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary.withOpacity(0.5),
                        colorScheme.tertiary.withOpacity(0.5),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: colorScheme.background, width: 2),
                    ),
                    child: _profilePictureService.buildProfileAvatar(
                      displayName: user.displayName,
                      colorScheme: colorScheme,
                      radius: 48,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: colorScheme.background, width: 3),
                    ),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      color: colorScheme.onPrimary,
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Name
          Text(
            user.displayName ?? 'User',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onBackground,
            ),
          ),
          const SizedBox(height: 4),
          // Email
          Text(
            user.email,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          // Premium Badge
          BlocBuilder<SubscriptionBloc, SubscriptionState>(
            builder: (context, state) {
              final isPremium = state is SubscriptionPremium;
              return GestureDetector(
                onTap: isPremium ? null : () => _navigateToPaywall(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isPremium
                        ? colorScheme.primary.withOpacity(0.1)
                        : colorScheme.surfaceVariant.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: isPremium
                          ? colorScheme.primary // Solid primary
                          : colorScheme.outline, // Solid outline
                      width: 1.5, // Thicker border
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPremium ? Icons.verified_rounded : Icons.star_outline_rounded,
                        size: 14,
                        color: isPremium ? colorScheme.primary : colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isPremium ? 'Premium Member' : 'Get Premium',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isPremium ? colorScheme.primary : colorScheme.onSurfaceVariant,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(User user, GoalsState goalsState, ColorScheme colorScheme) {
    int transactionCount = 0;
    int goalsCount = 0;
    final daysActive = DateTime.now().difference(user.createdAt).inDays + 1;

    final transactionState = context.watch<TransactionBloc>().state;
    if (transactionState is TransactionLoaded) {
      transactionCount = transactionState.transactions.length;
    }
    if (goalsState is GoalsLoaded) {
      goalsCount = goalsState.goals.where((g) => g.status == GoalStatus.active).length;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('$transactionCount', 'Transactions', colorScheme),
          Container(
            width: 1,
            height: 40,
            color: colorScheme.outline.withOpacity(0.1),
          ),
          _buildStatItem('$goalsCount', 'Goals', colorScheme),
          Container(
            width: 1,
            height: 40,
            color: colorScheme.outline.withOpacity(0.1),
          ),
          _buildStatItem('$daysActive', 'Days Active', colorScheme),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, ColorScheme colorScheme) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(List<_SettingsItem> items, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isLast = index == items.length - 1;
          return Column(
            children: [
              _buildSettingsTile(item, colorScheme),
              if (!isLast)
                Divider(
                  height: 1,
                  indent: 56,
                  color: colorScheme.outline.withOpacity(0.1),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSettingsTile(_SettingsItem item, ColorScheme colorScheme) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(item.icon, color: colorScheme.primary, size: 20),
      ),
      title: Text(
        item.title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
        ),
      ),
      subtitle: item.subtitle != null
          ? Text(
              item.subtitle!,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            )
          : null,
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: colorScheme.onSurfaceVariant.withOpacity(0.5),
      ),
      onTap: item.onTap,
    );
  }

  Widget _buildSignOutButton(ColorScheme colorScheme) {
    return OutlinedButton.icon(
      onPressed: () => _showSignOutDialog(),
      icon: Icon(Icons.logout_rounded, color: colorScheme.error),
      label: Text(
        'Sign Out',
        style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.w600),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: colorScheme.error.withOpacity(0.5)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // --- Dialogs and Pickers ---

  void _showCurrencyPicker() {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Select Currency',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _countries.length,
                itemBuilder: (context, index) {
                  final country = _countries[index];
                  final isSelected = country['name'] == _selectedCountry;
                  return ListTile(
                    leading: _buildFlag(country['name']!),
                    title: Text(country['name']!),
                    subtitle: Text(country['currency']!),
                    trailing: isSelected
                        ? Icon(Icons.check_circle, color: colorScheme.primary)
                        : null,
                    onTap: () async {
                      setState(() {
                        _selectedCountry = country['name']!;
                      });
                      await CurrencyService().setCurrency(country['currency']!);
                      if (context.mounted) {
                        WidgetService.refreshWidgets(context);
                      }
                      Navigator.pop(context);
                      AppSnackbar.showSuccess(
                        this.context,
                        message: 'Currency updated to ${country['currency']}',
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlag(String countryName) {
    final Map<String, String> flagByCountry = {
      'United States': '🇺🇸', 'United Kingdom': '🇬🇧', 'European Union': '🇪🇺',
      'Japan': '🇯🇵', 'Canada': '🇨🇦', 'Australia': '🇦🇺', 'India': '🇮🇳',
      'China': '🇨🇳', 'Brazil': '🇧🇷', 'South Korea': '🇰🇷', 'Nepal': '🇳🇵',
      'Mexico': '🇲🇽', 'Singapore': '🇸🇬', 'Switzerland': '🇨🇭', 'New Zealand': '🇳🇿',
    };
    final emoji = flagByCountry[countryName];
    if (emoji != null) {
      return Text(emoji, style: const TextStyle(fontSize: 24));
    }
    return const Icon(Icons.flag_rounded, size: 24);
  }

  void _showAppearancePopup() {
    final colorScheme = Theme.of(context).colorScheme;
    final themeBloc = context.read<ThemeBloc>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (dialogContext) => BlocProvider.value(
        value: themeBloc,
        child: BlocBuilder<ThemeBloc, ThemeState>(
          builder: (context, state) {
            final current = state is ThemeLoaded ? state.themeMode : ThemeMode.system;
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurface.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Appearance',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildThemeOption('Light', Icons.light_mode_rounded, current == ThemeMode.light, () => _changeTheme(dialogContext, ThemeMode.light), colorScheme),
                  const SizedBox(height: 12),
                  _buildThemeOption('Dark', Icons.dark_mode_rounded, current == ThemeMode.dark, () => _changeTheme(dialogContext, ThemeMode.dark), colorScheme),
                  const SizedBox(height: 12),
                  _buildThemeOption('System', Icons.phone_android_rounded, current == ThemeMode.system, () => _changeTheme(dialogContext, ThemeMode.system), colorScheme),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildThemeOption(String title, IconData icon, bool isSelected, VoidCallback onTap, ColorScheme colorScheme) {
    return ListTile(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? colorScheme.primary : colorScheme.outline.withOpacity(0.2),
          width: isSelected ? 2 : 1,
        ),
      ),
      tileColor: isSelected ? colorScheme.primary.withOpacity(0.05) : Colors.transparent,
      leading: Icon(icon, color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant),
      title: Text(title, style: TextStyle(color: colorScheme.onSurface, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
      trailing: isSelected ? Icon(Icons.check_circle, color: colorScheme.primary) : null,
      onTap: onTap,
    );
  }

  void _changeTheme(BuildContext dialogContext, ThemeMode mode) {
    final themeBloc = context.read<ThemeBloc>();
    Navigator.pop(dialogContext);
    Future.delayed(const Duration(milliseconds: 200), () {
      themeBloc.add(ThemeChanged(mode));
    });
  }

  void _showEditProfileDialog(User user) {
    final nameController = TextEditingController(text: user.displayName ?? '');
    final authService = AuthService();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Edit Profile'),
            content: Form(
              key: formKey,
              child: TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Enter a name' : null,
              ),
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setState(() => isLoading = true);
                        try {
                          await authService.updateProfile(
                            userId: user.id,
                            displayName: nameController.text.trim(),
                          );
                          if (mounted) {
                            this.context.read<AuthBloc>().add(AuthCheckRequested());
                            Navigator.pop(context);
                            AppSnackbar.showSuccess(this.context, message: 'Profile updated!');
                          }
                        } catch (e) {
                          setState(() => isLoading = false);
                          if (mounted) {
                            AppSnackbar.showError(context, message: '$e');
                          }
                        }
                      },
                child: isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Save'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSignOutDialog() {
    final authBloc = context.read<AuthBloc>();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              authBloc.add(SignOutRequested());
            },
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _showImagePickerOptions() {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(color: colorScheme.onSurface.withOpacity(0.3), borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            Text('Change Profile Picture', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
            const SizedBox(height: 20),
            ListTile(leading: Icon(Icons.camera_alt_rounded, color: colorScheme.primary), title: const Text('Take Photo'), onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); }),
            ListTile(leading: Icon(Icons.photo_library_rounded, color: colorScheme.primary), title: const Text('Choose from Gallery'), onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); }),
            if (_profilePictureService.profileImage != null)
              ListTile(
                leading: Icon(Icons.delete_rounded, color: colorScheme.error),
                title: Text('Remove Photo', style: TextStyle(color: colorScheme.error)),
                onTap: () { Navigator.pop(context); _removeProfileImage(); },
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source, maxWidth: 512, maxHeight: 512, imageQuality: 85);
      if (image != null) {
        final authState = context.read<AuthBloc>().state;
        if (authState is AuthAuthenticated) {
          await _profilePictureService.setProfileImage(File(image.path), userId: authState.user.id);
          setState(() {});
          AppSnackbar.showSuccess(context, message: 'Profile picture updated!');
        }
      }
    } catch (e) {
      AppSnackbar.showError(context, message: 'Failed to pick image: $e');
    }
  }

  void _removeProfileImage() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      await _profilePictureService.removeProfileImage(userId: authState.user.id);
      setState(() {});
      AppSnackbar.showSuccess(context, message: 'Profile picture removed!');
    }
  }

  Future<void> _manageSubscription() async {
    // Open system subscription settings
    final Uri url = Uri.parse(Platform.isIOS
        ? 'https://apps.apple.com/account/subscriptions'
        : 'https://play.google.com/store/account/subscriptions');
    
    if (!await launchUrl(url)) {
      if (mounted) {
        AppSnackbar.showError(context, message: 'Could not open subscription settings');
      }
    }
  }

  void _handleExportData() {
    final subscriptionState = context.read<SubscriptionBloc>().state;
    if (subscriptionState is SubscriptionPremium) {
      _showExportFormatDialog();
    } else {
      _navigateToPaywall();
    }
  }

  void _showExportFormatDialog() {
    final colorScheme = Theme.of(context).colorScheme;
    int selectedDays = 30; // Default: Last 30 days
    Budget? selectedBudget; // Default: All Budgets
    String selectedFormat = 'pdf'; // Default: PDF

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setModalState) {
          final budgetState = context.read<BudgetBloc>().state;
          final budgets = budgetState is BudgetLoaded ? budgetState.budgets : <Budget>[];
          
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurface.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Export Data',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 24),
                
                // 1. Time Range Selector
                Text(
                  'Time Range',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: selectedDays,
                      isExpanded: true,
                      icon: Icon(Icons.keyboard_arrow_down_rounded, color: colorScheme.onSurface),
                      dropdownColor: colorScheme.surface,
                      items: [
                        const DropdownMenuItem(value: 7, child: Text('Last 7 days')),
                        const DropdownMenuItem(value: 30, child: Text('Last 30 days')),
                        const DropdownMenuItem(value: 90, child: Text('Last 3 months')),
                        const DropdownMenuItem(value: 365, child: Text('Last 1 year')),
                        const DropdownMenuItem(value: -1, child: Text('All time')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setModalState(() => selectedDays = value);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // 2. Budget Filter (Optional)
                if (budgets.isNotEmpty) ...[
                   Text(
                    'Filter by Budget (Optional)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceVariant.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Budget?>(
                        value: selectedBudget,
                        isExpanded: true,
                        icon: Icon(Icons.keyboard_arrow_down_rounded, color: colorScheme.onSurface),
                        dropdownColor: colorScheme.surface,
                        hint: const Text('All Budgets'),
                        items: [
                          DropdownMenuItem<Budget?>(
                            value: null,
                            child: const Text('All Budgets'),
                          ),
                          ...budgets.map((b) => DropdownMenuItem(
                            value: b,
                            child: Text(b.name),
                          )),
                        ],
                        onChanged: (value) {
                          setModalState(() => selectedBudget = value);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // 3. Format Selector
                Text(
                  'Format',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildFormatOption(
                        'PDF', 
                        Icons.picture_as_pdf_rounded, 
                        selectedFormat == 'pdf', 
                        () => setModalState(() => selectedFormat = 'pdf'),
                        colorScheme,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildFormatOption(
                        'CSV', 
                        Icons.table_chart_rounded, 
                        selectedFormat == 'csv', 
                        () => setModalState(() => selectedFormat = 'csv'),
                        colorScheme,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                
                // Action Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      _performExport(
                        format: selectedFormat, 
                        days: selectedDays, 
                        budget: selectedBudget,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Generate Export',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFormatOption(String label, IconData icon, bool isSelected, VoidCallback onTap, ColorScheme colorScheme) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary.withOpacity(0.1) : colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outline.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? colorScheme.primary : colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _performExport({required String format, required int days, Budget? budget}) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final exportService = DataExportService();
      
      // Calculate the cutoff date
      final DateTime? cutoffDate = days > 0 
          ? DateTime.now().subtract(Duration(days: days))
          : null;
      
      // Get transactions and filter
      final transactionState = context.read<TransactionBloc>().state;
      var transactions = transactionState is TransactionLoaded 
          ? transactionState.transactions 
          : <dynamic>[];
      
      // Cast to Transaction List for stronger typing
      List<Transaction> filteredTransactions = transactions.cast<Transaction>();

      print('DEBUG: Total transactions: ${filteredTransactions.length}');

      // Filter by Date
      if (cutoffDate != null) {
        filteredTransactions = filteredTransactions.where((t) => t.date.isAfter(cutoffDate)).toList();
        print('DEBUG: After date filter: ${filteredTransactions.length}');
      }

      // Filter by Budget (Category)
      if (budget != null) {
        final category = budget.category;
        final budgetId = budget.id;
        print('DEBUG: Filtering by Budget Category: "$category" (ID: $budgetId)');
        
        filteredTransactions = filteredTransactions.where((t) {
            final match = t.category == category || t.budgetId == budgetId;
            if (!match && filteredTransactions.length < 10) {
               print('DEBUG: No match for t.category="${t.category}", t.budgetId="${t.budgetId}"');
            }
            return match;
        }).toList();
        print('DEBUG: After budget filter: ${filteredTransactions.length}');
      }
      
      // Get income and filter
      final incomeState = context.read<IncomeBloc>().state;
      var incomes = incomeState is IncomeLoaded 
          ? incomeState.incomes 
          : <dynamic>[];
      
      // Cast to Income List
      List<Income> filteredIncomes = incomes.cast<Income>();

      // Filter by Date
      if (cutoffDate != null) {
        filteredIncomes = filteredIncomes.where((i) => i.date.isAfter(cutoffDate)).toList();
      }

      // Filter by Budget (Linked Incomes)
      if (budget != null) {
        final budgetId = budget.id;
        // Only include incomes EXPLICITLY linked to this budget
        filteredIncomes = filteredIncomes.where((i) => i.budgetId == budgetId).toList();
      }

      // Get user name for PDF
      final authState = context.read<AuthBloc>().state;
      final userName = authState is AuthAuthenticated 
          ? (authState.user.displayName ?? 'User') 
          : 'User';

      File generatedFile;
      if (format == 'csv') {
        final csvContent = exportService.generateCsv(
          filteredTransactions,
          filteredIncomes,
        );
        generatedFile = await exportService.generateFile(
          Uint8List.fromList(csvContent.codeUnits), 
          'csv',
        );
      } else {
        final pdfBytes = await exportService.generatePdf(
          filteredTransactions,
          filteredIncomes,
          userName,
        );
        generatedFile = await exportService.generateFile(
          pdfBytes, 
          'pdf',
        );
      }

      // Close loading dialog
      if (mounted) Navigator.pop(context);
      
      // Show action dialog (Share vs Download)
      if (mounted) {
        _showExportActionDialog(generatedFile, exportService);
      }
      
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);
      
      AppSnackbar.showError(context, message: 'Export failed: $e');
    }
  }
  
  void _showExportActionDialog(File file, DataExportService exportService) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (dialogContext) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Export Ready',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'What would you like to do with the file?',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.download_rounded,
                    label: 'Save',
                    colorScheme: colorScheme,
                    onTap: () async {
                      Navigator.pop(dialogContext);
                      try {
                        final path = await exportService.saveToDownloads(file);
                        if (mounted) {
                           AppSnackbar.showSuccess(this.context, message: 'Saved to $path');
                        }
                      } catch (e) {
                        if (mounted) {
                          AppSnackbar.showError(this.context, message: 'Failed to save: $e');
                        }
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.share_rounded,
                    label: 'Share',
                    colorScheme: colorScheme,
                    isPrimary: true,
                    onTap: () async {
                      Navigator.pop(dialogContext);
                      await exportService.shareFile(file);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required ColorScheme colorScheme,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return Material(
      color: isPrimary ? colorScheme.primary : colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: isPrimary 
                ? null 
                : Border.all(color: colorScheme.outline.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isPrimary ? colorScheme.onPrimary : colorScheme.primary,
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isPrimary ? colorScheme.onPrimary : colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToPaywall() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const PaywallScreen()));
  }

  void _navigateToAboutUs() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutUsScreen()));
  }


  Widget _buildProfileSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonComponents.card(height: 200, context: context, children: [
            Column(children: [
              SkeletonComponents.circle(size: 100, context: context),
              const SizedBox(height: 16),
              SkeletonComponents.textLine(width: 150, height: 28),
            ]),
          ]),
          const SizedBox(height: 20),
          SkeletonComponents.card(height: 80, context: context),
          const SizedBox(height: 16),
          SkeletonComponents.card(height: 150, context: context),
          const SizedBox(height: 12),
          SkeletonComponents.card(height: 150, context: context),
        ],
      ),
    );
  }
}

class _SettingsItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  _SettingsItem({required this.icon, required this.title, this.subtitle, required this.onTap});
}
