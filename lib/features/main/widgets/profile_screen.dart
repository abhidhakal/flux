import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_theme.dart';
import 'dart:io';
import '../../../core/services/currency_service.dart';
import '../../../core/services/profile_picture_service.dart';
import '../../../core/models/user_model.dart';
import '../../../core/models/user_progress_model.dart';
import '../../../shared/widgets/skeleton_components.dart';
import '../../auth/auth_bloc.dart';
import '../../goals/goals_bloc.dart';
import '../../../core/models/goal_model.dart';
import '../../transaction/transaction_bloc.dart';
import '../screens/about_us_screen.dart';
import '../screens/privacy_policy_screen.dart';
import '../screens/terms_of_service_screen.dart';
import '../../../core/services/widget_service.dart';
import '../../theme/theme_bloc.dart';
import '../../notifications/screens/notification_settings_screen.dart';
import '../../../shared/widgets/app_bottom_sheet.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/stat_tile.dart';
import '../../../core/services/user_progress_service.dart';
import 'edit_profile_dialog.dart';
import 'export_data_dialog.dart';
import 'package:lucide_icons/lucide_icons.dart';

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
  final UserProgressService _userProgressService = UserProgressService();

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
      _profilePictureService
          .loadProfileImage(userId: authState.user.id)
          .then((_) {
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
    return Scaffold(
      backgroundColor: AppTheme.pageBackground(context),
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
    final transactionState = context.watch<TransactionBloc>().state;
    final progressSnapshot = transactionState is TransactionLoaded
        ? _userProgressService.calculateProgress(transactionState.transactions)
        : UserProgressSnapshot.empty();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Modern Header
        SliverToBoxAdapter(
          child: _buildModernHeader(user, colorScheme, theme, progressSnapshot),
        ),
        // Stats Row
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: BlocBuilder<GoalsBloc, GoalsState>(
              builder: (context, goalsState) {
                return _buildStatsRow(
                    goalsState, colorScheme, progressSnapshot);
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
                  icon: LucideIcons.user,
                  title: 'Edit Profile',
                  subtitle: user.displayName ?? user.email,
                  onTap: () => showEditProfileDialog(context, user),
                ),
                _SettingsItem(
                  icon: LucideIcons.coins,
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
                      icon: LucideIcons.palette,
                      title: 'Appearance',
                      subtitle: mode,
                      onTap: () => _showAppearancePopup(),
                    ),
                    _SettingsItem(
                      icon: LucideIcons.bell,
                      title: 'Notifications',
                      subtitle: 'Manage alerts',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const NotificationSettingsScreen(),
                          ),
                        );
                      },
                    ),
                  ], colorScheme);
                },
              ),
              const SizedBox(height: 24),
              _buildSectionHeader('Data & Privacy', colorScheme),
              _buildSettingsGroup([
                _SettingsItem(
                  icon: LucideIcons.download,
                  title: 'Export Data',
                  subtitle: 'CSV or PDF',
                  onTap: () => showExportFormatDialog(context),
                ),
                _SettingsItem(
                  icon: LucideIcons.shieldCheck,
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
                  icon: LucideIcons.fileText,
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
                  icon: LucideIcons.info,
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

  Widget _buildModernHeader(
    User user,
    ColorScheme colorScheme,
    ThemeData theme,
    UserProgressSnapshot progressSnapshot,
  ) {
    return Container(
      margin: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20,
        right: 20,
        bottom: 20,
      ),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary.withOpacity(0.12),
            AppTheme.cardSurface(context),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: colorScheme.outline.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.34 : 0.10),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
                alpha: theme.brightness == Brightness.dark ? 0.18 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _showImagePickerOptions,
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            colorScheme.primary.withOpacity(0.45),
                            colorScheme.tertiary.withOpacity(0.25),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.cardSurface(context),
                            width: 2,
                          ),
                        ),
                        child: ListenableBuilder(
                          listenable: _profilePictureService,
                          builder: (context, _) =>
                              _profilePictureService.buildProfileAvatar(
                            displayName: user.displayName,
                            colorScheme: colorScheme,
                            radius: 42,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.cardSurface(context),
                            width: 3,
                          ),
                        ),
                        child: Icon(
                          LucideIcons.camera,
                          color: colorScheme.onPrimary,
                          size: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName ?? 'User',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      user.email,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _buildHeaderPill(
                          icon: LucideIcons.flame,
                          label: UserProgressService.formatStreakLabel(
                            progressSnapshot.currentStreak,
                          ),
                          colorScheme: colorScheme,
                          emphasized: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderPill({
    required IconData icon,
    required String label,
    required ColorScheme colorScheme,
    bool emphasized = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: emphasized
            ? colorScheme.primary.withOpacity(0.1)
            : AppTheme.mutedSurface(context),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: emphasized
              ? colorScheme.primary.withOpacity(0.18)
              : colorScheme.outline.withOpacity(0.08),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color:
                emphasized ? colorScheme.primary : colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: emphasized ? colorScheme.primary : colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(
    GoalsState goalsState,
    ColorScheme colorScheme,
    UserProgressSnapshot progressSnapshot,
  ) {
    int transactionCount = 0;
    int goalsCount = 0;

    final transactionState = context.watch<TransactionBloc>().state;
    if (transactionState is TransactionLoaded) {
      transactionCount = transactionState.transactions.length;
    }
    if (goalsState is GoalsLoaded) {
      goalsCount =
          goalsState.goals.where((g) => g.status == GoalStatus.active).length;
    }

    return Row(
      children: [
        Expanded(
          child: _buildStatCard('$transactionCount', 'Transactions'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard('$goalsCount', 'Active goals'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            '${progressSnapshot.activeDays}',
            'Active days',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String value, String label) {
    return StatTile(
      label: label,
      value: value,
      radius: 20,
      bordered: true,
      valueFirst: true,
      valueFontSize: 21,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    );
  }

  Widget _buildSectionHeader(String title, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: AppTheme.sectionTitleStyle(context).copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(
      List<_SettingsItem> items, ColorScheme colorScheme) {
    return Container(
      decoration: AppTheme.surfaceDecoration(context, radius: 20),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
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
        LucideIcons.chevronRight,
        color: colorScheme.onSurfaceVariant.withOpacity(0.5),
      ),
      onTap: item.onTap,
    );
  }

  Widget _buildSignOutButton(ColorScheme colorScheme) {
    return OutlinedButton.icon(
      onPressed: () => _showSignOutDialog(),
      icon: Icon(LucideIcons.logOut, color: colorScheme.error, size: 18),
      label: Text(
        'Sign Out',
        style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.w600),
      ),
      style: OutlinedButton.styleFrom(
        backgroundColor: colorScheme.error.withOpacity(0.06),
        side: BorderSide(color: colorScheme.error.withOpacity(0.25)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }

  // --- Dialogs and Pickers ---

  void _showCurrencyPicker() {
    final colorScheme = Theme.of(context).colorScheme;
    AppBottomSheet.show(
      context,
      radius: 24,
      isScrollControlled: true,
      padding: EdgeInsets.zero,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          children: [
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
              child: Builder(builder: (context) {
                final countries = CurrencyService().getAvailableCurrencies();
                return ListView.builder(
                  itemCount: countries.length,
                  itemBuilder: (context, index) {
                    final country = countries[index];
                    final isSelected = country['country'] == _selectedCountry;
                    return ListTile(
                      leading: _buildFlag(country['country']!),
                      title: Text(country['country']!),
                      subtitle: Text(country['code']!),
                      trailing: isSelected
                          ? Icon(LucideIcons.checkCircle2,
                              color: colorScheme.primary)
                          : null,
                      onTap: () async {
                        setState(() {
                          _selectedCountry = country['country']!;
                        });
                        await CurrencyService().setCurrency(country['code']!);
                        if (context.mounted) {
                          WidgetService.refreshWidgets(context);
                        }
                        Navigator.pop(context);
                        AppSnackbar.showSuccess(
                          context,
                          message: 'Currency updated to ${country['code']}',
                        );
                      },
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlag(String countryName) {
    final Map<String, String> flagByCountry = {
      'United States': '🇺🇸',
      'United Kingdom': '🇬🇧',
      'European Union': '🇪🇺',
      'Japan': '🇯🇵',
      'Canada': '🇨🇦',
      'Australia': '🇦🇺',
      'India': '🇮🇳',
      'China': '🇨🇳',
      'Brazil': '🇧🇷',
      'South Korea': '🇰🇷',
      'Nepal': '🇳🇵',
      'Mexico': '🇲🇽',
      'Singapore': '🇸🇬',
      'Switzerland': '🇨🇭',
      'New Zealand': '🇳🇿',
    };
    final emoji = flagByCountry[countryName];
    if (emoji != null) {
      return Text(emoji, style: const TextStyle(fontSize: 24));
    }
    return const Icon(LucideIcons.flag, size: 24);
  }

  void _showAppearancePopup() {
    final colorScheme = Theme.of(context).colorScheme;
    final themeBloc = context.read<ThemeBloc>();
    AppBottomSheet.show(
      context,
      radius: 24,
      isScrollControlled: false,
      builder: (dialogContext) => BlocProvider.value(
        value: themeBloc,
        child: BlocBuilder<ThemeBloc, ThemeState>(
          builder: (context, state) {
            final current =
                state is ThemeLoaded ? state.themeMode : ThemeMode.system;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Appearance',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 24),
                _buildThemeOption(
                    'Light',
                    LucideIcons.sun,
                    current == ThemeMode.light,
                    () => _changeTheme(dialogContext, ThemeMode.light),
                    colorScheme),
                const SizedBox(height: 12),
                _buildThemeOption(
                    'Dark',
                    LucideIcons.moon,
                    current == ThemeMode.dark,
                    () => _changeTheme(dialogContext, ThemeMode.dark),
                    colorScheme),
                const SizedBox(height: 12),
                _buildThemeOption(
                    'System',
                    LucideIcons.smartphone,
                    current == ThemeMode.system,
                    () => _changeTheme(dialogContext, ThemeMode.system),
                    colorScheme),
                const SizedBox(height: 20),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildThemeOption(String title, IconData icon, bool isSelected,
      VoidCallback onTap, ColorScheme colorScheme) {
    return ListTile(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? colorScheme.primary
              : colorScheme.outline.withOpacity(0.2),
          width: isSelected ? 2 : 1,
        ),
      ),
      tileColor: isSelected
          ? colorScheme.primary.withOpacity(0.05)
          : Colors.transparent,
      leading: Icon(icon,
          color:
              isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant),
      title: Text(title,
          style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
      trailing: isSelected
          ? Icon(LucideIcons.checkCircle2, color: colorScheme.primary)
          : null,
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

  void _showSignOutDialog() {
    final authBloc = context.read<AuthBloc>();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    AppBottomSheet.show(
      context,
      radius: 28,
      isScrollControlled: true,
      padding: EdgeInsets.fromLTRB(
          24, 12, 24, 40 + MediaQuery.of(context).viewInsets.bottom),
      builder: (dialogContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: cs.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(LucideIcons.logOut, color: cs.error, size: 32),
          ),
          const SizedBox(height: 20),
          Text(
            'Sign Out',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "You'll be returned to the welcome screen.\nYour data will remain safe.",
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    side: BorderSide(color: cs.outline.withOpacity(0.4)),
                  ),
                  child: Text('Cancel',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, color: cs.onSurface)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    authBloc.add(SignOutRequested());
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: cs.error,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Sign Out',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showImagePickerOptions() {
    final colorScheme = Theme.of(context).colorScheme;
    AppBottomSheet.show(
      context,
      radius: 20,
      isScrollControlled: false,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Change Profile Picture',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface)),
          const SizedBox(height: 20),
          ListTile(
              leading: Icon(LucideIcons.camera, color: colorScheme.primary),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              }),
          ListTile(
              leading: Icon(LucideIcons.image, color: colorScheme.primary),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              }),
          if (_profilePictureService.hasProfileImage)
            ListTile(
              leading: Icon(LucideIcons.trash2, color: colorScheme.error),
              title: Text('Remove Photo',
                  style: TextStyle(color: colorScheme.error)),
              onTap: () async {
                Navigator.pop(context);
                await _removeProfileImage();
              },
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
          source: source, maxWidth: 512, maxHeight: 512, imageQuality: 85);
      if (image != null) {
        final authState = context.read<AuthBloc>().state;
        if (authState is AuthAuthenticated) {
          final imageFile = File(image.path);
          final saveFuture = _profilePictureService.setProfileImage(imageFile,
              userId: authState.user.id);
          setState(() {});
          await saveFuture;
          if (!mounted) return;
          setState(() {});
          AppSnackbar.showSuccess(context, message: 'Profile picture updated!');
        }
      }
    } on ProfilePictureTooLargeException catch (_) {
      if (!mounted) return;
      AppSnackbar.showError(context,
          message: 'Profile picture must be under 2 MB.');
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(context, message: 'Failed to pick image: $e');
    }
  }

  Future<void> _removeProfileImage() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    try {
      await _profilePictureService.removeProfileImage(
          userId: authState.user.id);
      if (!mounted) return;
      setState(() {});
      AppSnackbar.showSuccess(context, message: 'Profile picture removed!');
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(context,
          message: 'Failed to remove profile picture: $e');
    }
  }

  void _navigateToAboutUs() {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => const AboutUsScreen()));
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

  _SettingsItem(
      {required this.icon,
      required this.title,
      this.subtitle,
      required this.onTap});
}
