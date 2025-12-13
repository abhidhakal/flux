import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/services/currency_service.dart';
import '../../../core/services/profile_picture_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/models/user_model.dart';
import '../../../shared/widgets/skeleton_components.dart';
import '../../auth/auth_bloc.dart';
import '../../goals/goals_bloc.dart';
import '../../transaction/transaction_bloc.dart';
import '../screens/about_us_screen.dart';
import '../screens/privacy_policy_screen.dart';
import '../screens/terms_of_service_screen.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../subscription/presentation/pages/paywall_screen.dart';
import '../../subscription/subscription_bloc.dart';
import '../../theme/theme_bloc.dart';
import '../../notifications/screens/notification_settings_screen.dart';
import '../../../shared/widgets/app_snackbar.dart';

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
    _profilePictureService.loadProfileImage();
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
              _buildSettingsGroup([
                _SettingsItem(
                  icon: Icons.palette_outlined,
                  title: 'Appearance',
                  subtitle: 'Theme settings',
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
              ], colorScheme),
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
              const SizedBox(height: 100),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildModernHeader(User user, ColorScheme colorScheme, ThemeData theme) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20,
        left: 24,
        right: 24,
        bottom: 24,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer.withOpacity(0.4),
            colorScheme.background,
          ],
        ),
      ),
      child: Column(
        children: [
          // Profile Picture
          GestureDetector(
            onTap: _showImagePickerOptions,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: _profilePictureService.buildProfileAvatar(
                    displayName: user.displayName,
                    colorScheme: colorScheme,
                    radius: 55,
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
                      size: 16,
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
          const SizedBox(height: 12),
          // Premium Badge
          BlocBuilder<SubscriptionBloc, SubscriptionState>(
            builder: (context, state) {
              final isPremium = state is SubscriptionPremium;
              return GestureDetector(
                onTap: isPremium ? null : () => _navigateToPaywall(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isPremium
                        ? colorScheme.primary.withOpacity(0.1)
                        : colorScheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isPremium
                          ? colorScheme.primary.withOpacity(0.3)
                          : colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPremium ? Icons.star_rounded : Icons.lock_outline_rounded,
                        size: 16,
                        color: isPremium ? colorScheme.primary : colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isPremium ? 'Premium Member' : 'Upgrade to Premium',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isPremium ? colorScheme.primary : colorScheme.onSurfaceVariant,
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
      goalsCount = goalsState.goals.length;
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
        await _profilePictureService.setProfileImage(File(image.path));
        setState(() {});
        AppSnackbar.showSuccess(context, message: 'Profile picture updated!');
      }
    } catch (e) {
      AppSnackbar.showError(context, message: 'Failed to pick image: $e');
    }
  }

  void _removeProfileImage() async {
    await _profilePictureService.removeProfileImage();
    setState(() {});
    AppSnackbar.showSuccess(context, message: 'Profile picture removed!');
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
      AppSnackbar.showSuccess(context, message: 'Data exported successfully! (Mock)');
    } else {
      _navigateToPaywall();
    }
  }

  void _navigateToPaywall() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const PaywallScreen()));
  }

  void _navigateToAboutUs() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutUsScreen()));
  }

  void _showSnackBar(String message) {
    AppSnackbar.showInfo(context, message: message);
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
