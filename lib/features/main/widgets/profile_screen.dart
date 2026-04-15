import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_theme.dart';
import 'dart:io';
import 'dart:typed_data';
import '../../../core/services/currency_service.dart';
import '../../../core/services/profile_picture_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/data_export_service.dart';
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
import '../../../shared/widgets/app_snackbar.dart';
import '../../budget/budget_bloc.dart';
import '../../../core/models/budget_model.dart';
import '../../../core/models/transaction_model.dart';
import '../../../core/services/user_progress_service.dart';

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
      decoration: AppTheme.surfaceDecoration(context, radius: 28),
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
                        child: _profilePictureService.buildProfileAvatar(
                          displayName: user.displayName,
                          colorScheme: colorScheme,
                          radius: 42,
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
                          Icons.camera_alt_rounded,
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
                          icon: Icons.local_fire_department_rounded,
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
          child:
              _buildStatCard('$transactionCount', 'Transactions', colorScheme),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard('$goalsCount', 'Active goals', colorScheme),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            '${progressSnapshot.activeDays}',
            'Active days',
            colorScheme,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String value, String label, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: AppTheme.surfaceDecoration(context, radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
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
        Icons.chevron_right_rounded,
        color: colorScheme.onSurfaceVariant.withOpacity(0.5),
      ),
      onTap: item.onTap,
    );
  }

  Widget _buildSignOutButton(ColorScheme colorScheme) {
    return OutlinedButton.icon(
      onPressed: () => _showSignOutDialog(),
      icon: Icon(Icons.logout_rounded, color: colorScheme.onError),
      label: Text(
        'Sign Out',
        style:
            TextStyle(color: colorScheme.onError, fontWeight: FontWeight.w600),
      ),
      style: OutlinedButton.styleFrom(
        backgroundColor: colorScheme.error,
        side: BorderSide(color: colorScheme.error),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
                        context,
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
            final current =
                state is ThemeLoaded ? state.themeMode : ThemeMode.system;
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
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
                  _buildThemeOption(
                      'Light',
                      Icons.light_mode_rounded,
                      current == ThemeMode.light,
                      () => _changeTheme(dialogContext, ThemeMode.light),
                      colorScheme),
                  const SizedBox(height: 12),
                  _buildThemeOption(
                      'Dark',
                      Icons.dark_mode_rounded,
                      current == ThemeMode.dark,
                      () => _changeTheme(dialogContext, ThemeMode.dark),
                      colorScheme),
                  const SizedBox(height: 12),
                  _buildThemeOption(
                      'System',
                      Icons.phone_android_rounded,
                      current == ThemeMode.system,
                      () => _changeTheme(dialogContext, ThemeMode.system),
                      colorScheme),
                  const SizedBox(height: 20),
                ],
              ),
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
          ? Icon(Icons.check_circle, color: colorScheme.primary)
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

  void _showEditProfileDialog(User user) {
    final authService = AuthService();
    final isEmailUser = authService.isEmailPasswordUser;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final nameController = TextEditingController(text: user.displayName ?? '');
    final emailController = TextEditingController();
    final currentPwController = TextEditingController();
    final newPwController = TextEditingController();
    final confirmPwController = TextEditingController();

    final nameKey = GlobalKey<FormFieldState>();
    final emailKey = GlobalKey<FormFieldState>();
    final pwKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) {
        bool savingName = false;
        bool savingEmail = false;
        bool savingPw = false;
        bool showCurrentPw = false;
        bool showNewPw = false;
        bool showConfirmPw = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: cs.onSurfaceVariant.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text('Edit Profile',
                          style: theme.textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 32),

                      // ── Display Name ────────────────────────────
                      Text('Display Name',
                          style: theme.textTheme.labelLarge
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              key: nameKey,
                              controller: nameController,
                              textCapitalization: TextCapitalization.words,
                              decoration: _inputDeco(cs, hint: 'Your name'),
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Enter a name'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          _saveButton(
                            loading: savingName,
                            onTap: () async {
                              if (nameKey.currentState?.validate() != true) {
                                return;
                              }
                              setState(() => savingName = true);
                              try {
                                await authService.updateProfile(
                                  userId: user.id,
                                  displayName: nameController.text.trim(),
                                );
                                if (mounted) {
                                  context
                                      .read<AuthBloc>()
                                      .add(AuthCheckRequested());
                                  Navigator.pop(sheetCtx);
                                  AppSnackbar.showSuccess(
                                    context,
                                    message: 'Name updated',
                                  );
                                }
                              } catch (e) {
                                setState(() => savingName = false);
                                if (mounted) {
                                  AppSnackbar.showError(
                                    context,
                                    message: 'Failed to update name',
                                  );
                                }
                              }
                            },
                            cs: cs,
                          ),
                        ],
                      ),

                      if (isEmailUser) ...[
                        const SizedBox(height: 28),
                        Divider(color: cs.outline.withOpacity(0.15)),
                        const SizedBox(height: 20),

                        // ── Email ──────────────────────────────────
                        Text('Change Email',
                            style: theme.textTheme.labelLarge
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(
                          'A verification link will be sent to the new address.',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextFormField(
                                key: emailKey,
                                controller: emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration:
                                    _inputDeco(cs, hint: 'New email address'),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Enter an email';
                                  }
                                  if (!v.contains('@')) {
                                    return 'Enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            _saveButton(
                              loading: savingEmail,
                              onTap: () async {
                                if (emailKey.currentState?.validate() != true) {
                                  return;
                                }
                                setState(() => savingEmail = true);
                                try {
                                  await authService.updateEmail(
                                    userId: user.id,
                                    newEmail: emailController.text.trim(),
                                  );
                                  if (mounted) {
                                    Navigator.pop(sheetCtx);
                                    AppSnackbar.showSuccess(
                                      context,
                                      message:
                                          'Verification email sent — check your inbox',
                                    );
                                  }
                                } catch (e) {
                                  setState(() => savingEmail = false);
                                  if (mounted) {
                                    AppSnackbar.showError(
                                      context,
                                      message: 'Failed to change email',
                                    );
                                  }
                                }
                              },
                              cs: cs,
                            ),
                          ],
                        ),

                        const SizedBox(height: 28),
                        Divider(color: cs.outline.withOpacity(0.15)),
                        const SizedBox(height: 20),

                        // ── Password ───────────────────────────────
                        Text('Change Password',
                            style: theme.textTheme.labelLarge
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: savingPw
                                ? null
                                : () async {
                                    setState(() => savingPw = true);
                                    try {
                                      await authService
                                          .resetPassword(user.email);
                                      if (mounted) {
                                        Navigator.pop(sheetCtx);
                                        AppSnackbar.showSuccess(
                                          context,
                                          message:
                                              'Password reset link sent to ${user.email}',
                                        );
                                      }
                                    } catch (e) {
                                      setState(() => savingPw = false);
                                      if (mounted) {
                                        AppSnackbar.showError(
                                          context,
                                          message:
                                              'Failed to send reset email',
                                        );
                                      }
                                    }
                                  },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: BorderSide(
                                  color: AppColors.primary.withOpacity(0.5)),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            icon: savingPw
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))
                                : const Icon(Icons.mail_outline_rounded,
                                    size: 18),
                            label: const Text('Send password reset email',
                                style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                                child: Divider(
                                    color: cs.outline.withOpacity(0.2))),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Text('or change manually',
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(color: cs.onSurfaceVariant)),
                            ),
                            Expanded(
                                child: Divider(
                                    color: cs.outline.withOpacity(0.2))),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Form(
                          key: pwKey,
                          child: Column(
                            children: [
                              TextFormField(
                                controller: currentPwController,
                                obscureText: !showCurrentPw,
                                decoration: _inputDeco(cs,
                                    hint: 'Current password',
                                    suffix: _eyeToggle(
                                        showCurrentPw,
                                        cs,
                                        () => setState(() =>
                                            showCurrentPw = !showCurrentPw))),
                                validator: (v) => v == null || v.isEmpty
                                    ? 'Enter current password'
                                    : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: newPwController,
                                obscureText: !showNewPw,
                                decoration: _inputDeco(cs,
                                    hint: 'New password',
                                    suffix: _eyeToggle(
                                        showNewPw,
                                        cs,
                                        () => setState(
                                            () => showNewPw = !showNewPw))),
                                validator: (v) {
                                  if (v == null || v.isEmpty)
                                    return 'Enter new password';
                                  if (v.length < 6)
                                    return 'At least 6 characters';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: confirmPwController,
                                obscureText: !showConfirmPw,
                                decoration: _inputDeco(cs,
                                    hint: 'Confirm new password',
                                    suffix: _eyeToggle(
                                        showConfirmPw,
                                        cs,
                                        () => setState(() =>
                                            showConfirmPw = !showConfirmPw))),
                                validator: (v) => v != newPwController.text
                                    ? 'Passwords do not match'
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed: savingPw
                                      ? null
                                      : () async {
                                          if (!pwKey.currentState!.validate()) {
                                            return;
                                          }
                                          setState(() => savingPw = true);
                                          try {
                                            await authService.updatePassword(
                                              currentPassword:
                                                  currentPwController.text,
                                              newPassword: newPwController.text,
                                            );
                                            if (mounted) {
                                              Navigator.pop(sheetCtx);
                                              AppSnackbar.showSuccess(
                                                  context,
                                                  message: 'Password updated');
                                            }
                                          } catch (e) {
                                            setState(() => savingPw = false);
                                            if (mounted) {
                                              final msg = e
                                                  .toString()
                                                  .replaceAll(
                                                      'Exception: ', '');
                                              AppSnackbar.showError(
                                                  context,
                                                  message: msg);
                                            }
                                          }
                                        },
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14)),
                                  ),
                                  child: savingPw
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white))
                                      : const Text('Update Password',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      nameController.dispose();
      emailController.dispose();
      currentPwController.dispose();
      newPwController.dispose();
      confirmPwController.dispose();
    });
  }

  InputDecoration _inputDeco(ColorScheme cs,
      {required String hint, Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      suffixIcon: suffix,
      filled: true,
      fillColor: cs.surfaceVariant.withOpacity(0.35),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.outline.withOpacity(0.15))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.error)),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.error, width: 1.5)),
    );
  }

  Widget _saveButton(
      {required bool loading,
      required VoidCallback onTap,
      required ColorScheme cs}) {
    return SizedBox(
      height: 50,
      child: FilledButton(
        onPressed: loading ? null : onTap,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : const Text('Save', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _eyeToggle(bool visible, ColorScheme cs, VoidCallback onTap) {
    return IconButton(
      icon: Icon(
          visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          size: 20,
          color: cs.onSurfaceVariant),
      onPressed: onTap,
    );
  }

  void _showSignOutDialog() {
    final authBloc = context.read<AuthBloc>();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (dialogContext) => Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(
            24, 12, 24, 40 + MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.onSurfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 28),
            // Icon
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: cs.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(Icons.logout_rounded, color: cs.error, size: 32),
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
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: colorScheme.onSurface.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            Text('Change Profile Picture',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface)),
            const SizedBox(height: 20),
            ListTile(
                leading:
                    Icon(Icons.camera_alt_rounded, color: colorScheme.primary),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                }),
            ListTile(
                leading: Icon(Icons.photo_library_rounded,
                    color: colorScheme.primary),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                }),
            if (_profilePictureService.hasProfileImage)
              ListTile(
                leading: Icon(Icons.delete_rounded, color: colorScheme.error),
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

  void _handleExportData() {
    _showExportFormatDialog();
  }

  void _showExportFormatDialog() {
    final colorScheme = Theme.of(context).colorScheme;
    // filterMode: 'time' or 'budget'
    String filterMode = 'time';
    int selectedDays = 30; // Used only in 'time' mode
    Budget? selectedBudget; // Used only in 'budget' mode
    String selectedFormat = 'pdf'; // Default: PDF

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setModalState) {
          final budgetState = context.read<BudgetBloc>().state;
          final budgets =
              budgetState is BudgetLoaded ? budgetState.budgets : <Budget>[];

          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
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

                // 1. Filter Mode Toggle
                Text(
                  'Filter By',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setModalState(() {
                          filterMode = 'time';
                          selectedBudget = null;
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: filterMode == 'time'
                                ? colorScheme.primary.withOpacity(0.1)
                                : colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: filterMode == 'time'
                                  ? colorScheme.primary
                                  : colorScheme.outline.withOpacity(0.3),
                              width: filterMode == 'time' ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.calendar_month_rounded,
                                color: filterMode == 'time'
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                                size: 20,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Time Range',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: filterMode == 'time'
                                      ? colorScheme.primary
                                      : colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: budgets.isEmpty
                            ? null
                            : () => setModalState(() {
                                  filterMode = 'budget';
                                  selectedDays = 30;
                                }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: budgets.isEmpty
                                ? colorScheme.surfaceVariant.withOpacity(0.2)
                                : filterMode == 'budget'
                                    ? colorScheme.primary.withOpacity(0.1)
                                    : colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: budgets.isEmpty
                                  ? colorScheme.outline.withOpacity(0.1)
                                  : filterMode == 'budget'
                                      ? colorScheme.primary
                                      : colorScheme.outline.withOpacity(0.3),
                              width: filterMode == 'budget' ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.account_balance_wallet_rounded,
                                color: budgets.isEmpty
                                    ? colorScheme.onSurface.withOpacity(0.3)
                                    : filterMode == 'budget'
                                        ? colorScheme.primary
                                        : colorScheme.onSurfaceVariant,
                                size: 20,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                budgets.isEmpty ? 'Budget (none)' : 'Budget',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: budgets.isEmpty
                                      ? colorScheme.onSurface.withOpacity(0.3)
                                      : filterMode == 'budget'
                                          ? colorScheme.primary
                                          : colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 2a. Time Range Selector (shown only in 'time' mode)
                if (filterMode == 'time') ...[
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
                      border: Border.all(
                          color: colorScheme.outline.withOpacity(0.1)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: selectedDays,
                        isExpanded: true,
                        icon: Icon(Icons.keyboard_arrow_down_rounded,
                            color: colorScheme.onSurface),
                        dropdownColor: colorScheme.surface,
                        items: const [
                          DropdownMenuItem(
                              value: 7, child: Text('Last 7 days')),
                          DropdownMenuItem(
                              value: 30, child: Text('Last 30 days')),
                          DropdownMenuItem(
                              value: 90, child: Text('Last 3 months')),
                          DropdownMenuItem(
                              value: 365, child: Text('Last 1 year')),
                          DropdownMenuItem(value: -1, child: Text('All time')),
                        ],
                        onChanged: (value) {
                          if (value != null)
                            setModalState(() => selectedDays = value);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // 2b. Budget Selector (shown only in 'budget' mode)
                if (filterMode == 'budget' && budgets.isNotEmpty) ...[
                  Text(
                    'Select Budget',
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
                      border: Border.all(
                          color: colorScheme.outline.withOpacity(0.1)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Budget?>(
                        value: selectedBudget,
                        isExpanded: true,
                        icon: Icon(Icons.keyboard_arrow_down_rounded,
                            color: colorScheme.onSurface),
                        dropdownColor: colorScheme.surface,
                        hint: const Text('Choose a budget'),
                        items: budgets
                            .map((b) => DropdownMenuItem(
                                  value: b,
                                  child: Text(b.name),
                                ))
                            .toList(),
                        onChanged: (value) =>
                            setModalState(() => selectedBudget = value),
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
                        // In budget mode pass days=-1 so no date cutoff is applied
                        days: filterMode == 'budget' ? -1 : selectedDays,
                        budget: filterMode == 'budget' ? selectedBudget : null,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Generate Export',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

  Widget _buildFormatOption(String label, IconData icon, bool isSelected,
      VoidCallback onTap, ColorScheme colorScheme) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withOpacity(0.1)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outline.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
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

  Future<void> _performExport(
      {required String format, required int days, Budget? budget}) async {
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

      // Get transactions
      final transactionState = context.read<TransactionBloc>().state;
      List<Transaction> filteredTransactions =
          (transactionState is TransactionLoaded
                  ? transactionState.transactions
                  : <Transaction>[])
              .cast<Transaction>();

      if (budget != null) {
        // BUDGET MODE: export all transactions for the chosen budget, ignore date range
        final budgetId = budget.id;

        filteredTransactions =
            filteredTransactions.where((t) => t.budgetId == budgetId).toList();
      } else {
        // TIME MODE: export transactions within the selected time range, no budget filter
        final DateTime? cutoffDate =
            days > 0 ? DateTime.now().subtract(Duration(days: days)) : null;

        if (cutoffDate != null) {
          filteredTransactions = filteredTransactions
              .where((t) => t.date.isAfter(cutoffDate))
              .toList();
        }
      }

      // Get user name for PDF
      final authState = context.read<AuthBloc>().state;
      final userName = authState is AuthAuthenticated
          ? (authState.user.displayName ?? 'User')
          : 'User';

      final now = DateTime.now();
      final todayIso = now.toIso8601String().split('T').first;
      final reportScope = budget != null
          ? 'Scope: Budget - ${budget.name}'
          : 'Scope: Time Range';
      final reportRange = budget != null
          ? 'Range: All records for selected budget'
          : (days > 0
              ? 'Range: ${now.subtract(Duration(days: days)).toIso8601String().split('T').first} to $todayIso'
              : 'Range: All time');

      File generatedFile;
      if (format == 'csv') {
        final csvContent = exportService.generateCsv(filteredTransactions);
        generatedFile = await exportService.generateFile(
          Uint8List.fromList(csvContent.codeUnits),
          'csv',
        );
      } else {
        final pdfBytes = await exportService.generatePdf(
          filteredTransactions,
          userName,
          reportScope: reportScope,
          reportRange: reportRange,
        );
        generatedFile = await exportService.generateFile(
          pdfBytes,
          'pdf',
        );
      }

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      // Show action dialog (Share vs Download)
      if (mounted) {
        _showExportActionDialog(generatedFile, exportService);
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

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
                          AppSnackbar.showSuccess(
                            context,
                            message: 'Saved to $path',
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          AppSnackbar.showError(
                            context,
                            message: 'Failed to save: $e',
                          );
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
                  color:
                      isPrimary ? colorScheme.onPrimary : colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
