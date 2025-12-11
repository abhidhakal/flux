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
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String _selectedCountry = 'United States';
  final ImagePicker _picker = ImagePicker();
  final ProfilePictureService _profilePictureService = ProfilePictureService();

  @override
  void initState() {
    super.initState();

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

    _initializeCurrency();
    _profilePictureService.loadProfileImage();

    // Start animations after initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fadeController.forward();
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _initializeCurrency() async {
    // Ensure CurrencyService is initialized
    await CurrencyService().ensureInitialized();
    setState(() {
      _selectedCountry = CurrencyService().country;
    });
  }

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
    {'name': 'Argentina', 'currency': 'ARS', 'symbol': '\$'},
    {'name': 'Chile', 'currency': 'CLP', 'symbol': '\$'},
    {'name': 'Colombia', 'currency': 'COP', 'symbol': '\$'},
    {'name': 'Peru', 'currency': 'PEN', 'symbol': 'S/'},
    {'name': 'Venezuela', 'currency': 'VES', 'symbol': 'Bs.'},
    {'name': 'South Africa', 'currency': 'ZAR', 'symbol': 'R'},
    {'name': 'Nigeria', 'currency': 'NGN', 'symbol': '₦'},
    {'name': 'Kenya', 'currency': 'KES', 'symbol': 'KSh'},
    {'name': 'Ghana', 'currency': 'GHS', 'symbol': '₵'},
    {'name': 'Egypt', 'currency': 'EGP', 'symbol': 'E£'},
    {'name': 'Morocco', 'currency': 'MAD', 'symbol': 'د.م.'},
    {'name': 'Saudi Arabia', 'currency': 'SAR', 'symbol': '﷼'},
    {'name': 'United Arab Emirates', 'currency': 'AED', 'symbol': 'د.إ'},
    {'name': 'Qatar', 'currency': 'QAR', 'symbol': '﷼'},
    {'name': 'Kuwait', 'currency': 'KWD', 'symbol': 'د.ك'},
    {'name': 'Turkey', 'currency': 'TRY', 'symbol': '₺'},
    {'name': 'Israel', 'currency': 'ILS', 'symbol': '₪'},
    {'name': 'Pakistan', 'currency': 'PKR', 'symbol': '₨'},
    {'name': 'Bangladesh', 'currency': 'BDT', 'symbol': '৳'},
    {'name': 'Sri Lanka', 'currency': 'LKR', 'symbol': 'Rs.'},
    {'name': 'Singapore', 'currency': 'SGD', 'symbol': 'S\$'},
    {'name': 'Malaysia', 'currency': 'MYR', 'symbol': 'RM'},
    {'name': 'Indonesia', 'currency': 'IDR', 'symbol': 'Rp'},
    {'name': 'Philippines', 'currency': 'PHP', 'symbol': '₱'},
    {'name': 'Thailand', 'currency': 'THB', 'symbol': '฿'},
    {'name': 'Vietnam', 'currency': 'VND', 'symbol': '₫'},
    {'name': 'Hong Kong', 'currency': 'HKD', 'symbol': 'HK\$'},
    {'name': 'Taiwan', 'currency': 'TWD', 'symbol': 'NT\$'},
    {'name': 'New Zealand', 'currency': 'NZD', 'symbol': 'NZ\$'},
    {'name': 'Switzerland', 'currency': 'CHF', 'symbol': 'CHF'},
    {'name': 'Norway', 'currency': 'NOK', 'symbol': 'kr'},
    {'name': 'Sweden', 'currency': 'SEK', 'symbol': 'kr'},
    {'name': 'Denmark', 'currency': 'DKK', 'symbol': 'kr'},
    {'name': 'Poland', 'currency': 'PLN', 'symbol': 'zł'},
    {'name': 'Czech Republic', 'currency': 'CZK', 'symbol': 'Kč'},
    {'name': 'Hungary', 'currency': 'HUF', 'symbol': 'Ft'},
    {'name': 'Romania', 'currency': 'RON', 'symbol': 'lei'},
    {'name': 'Bulgaria', 'currency': 'BGN', 'symbol': 'лв'},
    {'name': 'Croatia', 'currency': 'EUR', 'symbol': '€'},
    {'name': 'Serbia', 'currency': 'RSD', 'symbol': 'дин.'},
    {'name': 'Russia', 'currency': 'RUB', 'symbol': '₽'},
    {'name': 'Ukraine', 'currency': 'UAH', 'symbol': '₴'},
    {'name': 'Belarus', 'currency': 'BYN', 'symbol': 'Br'},
    {'name': 'Iceland', 'currency': 'ISK', 'symbol': 'kr'},
    {'name': 'Greenland', 'currency': 'DKK', 'symbol': 'kr'},
    {'name': 'Jamaica', 'currency': 'JMD', 'symbol': 'J\$'},
    {'name': 'Dominican Republic', 'currency': 'DOP', 'symbol': 'RD\$'},
    {'name': 'Haiti', 'currency': 'HTG', 'symbol': 'G'},
    {'name': 'Costa Rica', 'currency': 'CRC', 'symbol': '₡'},
    {'name': 'Guatemala', 'currency': 'GTQ', 'symbol': 'Q'},
    {'name': 'Honduras', 'currency': 'HNL', 'symbol': 'L'},
    {'name': 'El Salvador', 'currency': 'USD', 'symbol': '\$'},
    {'name': 'Panama', 'currency': 'PAB', 'symbol': 'B/.'},
    {'name': 'Uruguay', 'currency': 'UYU', 'symbol': '\$U'},
    {'name': 'Paraguay', 'currency': 'PYG', 'symbol': '₲'},
    {'name': 'Bolivia', 'currency': 'BOB', 'symbol': 'Bs.'},
    {'name': 'Ethiopia', 'currency': 'ETB', 'symbol': 'Br'},
    {'name': 'Tanzania', 'currency': 'TZS', 'symbol': 'TSh'},
    {'name': 'Uganda', 'currency': 'UGX', 'symbol': 'USh'},
    {'name': 'Zimbabwe', 'currency': 'ZWL', 'symbol': 'Z\$'},
    {'name': 'Algeria', 'currency': 'DZD', 'symbol': 'دج'},
    {'name': 'Tunisia', 'currency': 'TND', 'symbol': 'د.ت'},
    {'name': 'Jordan', 'currency': 'JOD', 'symbol': 'د.ا'},
    {'name': 'Lebanon', 'currency': 'LBP', 'symbol': 'ل.ل'},
    {'name': 'Iraq', 'currency': 'IQD', 'symbol': 'ع.د'},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: const Text('Profile'),
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
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthAuthenticated) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: _buildProfileContent(context, state.user),
              ),
            );
          }
          return _buildProfileSkeleton();
        },
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, User user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 120, left: 16, right: 16, top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Header
          _buildProfileHeader(user),
          const SizedBox(height: 20),

          // Quick Stats Row (now wrapped in BlocBuilder for GoalsBloc)
          BlocBuilder<GoalsBloc, GoalsState>(
            builder: (context, goalsState) {
              return _buildQuickStatsRow(user, goalsState);
            },
          ),
          const SizedBox(height: 16),

          // Profile Details Card
          _buildProfileDetailsCard(user),
          const SizedBox(height: 12),

          // App Settings Card
          _buildAppSettingsCard(),
          const SizedBox(height: 12),

          // Currency Settings Card
          _buildCurrencySettingsCard(),
          const SizedBox(height: 12),

          // Account Actions Card
          _buildAccountActionsCard(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showAppearancePopup() {
    final colorScheme = Theme.of(context).colorScheme;
    final themeBloc = context.read<ThemeBloc>();
    
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: themeBloc,
        child: BlocBuilder<ThemeBloc, ThemeState>(
          builder: (context, state) {
            final ThemeMode current = state is ThemeLoaded ? state.themeMode : ThemeMode.light;
            
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.palette_rounded,
                            color: colorScheme.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Choose Appearance',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select how you want the app to appear',
                      style: TextStyle(
                        fontSize: 16,
                        color: colorScheme.onSurface.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Appearance options - THIS WAS MISSING!
                    _buildAppearanceOption(
                      title: 'Light Mode',
                      subtitle: 'Clean and bright interface',
                      icon: Icons.light_mode_rounded,
                      isSelected: current == ThemeMode.light,
                      onTap: () => _changeTheme(dialogContext, ThemeMode.light),
                    ),
                    const SizedBox(height: 16),
                    _buildAppearanceOption(
                      title: 'Dark Mode',
                      subtitle: 'Easy on the eyes in low light',
                      icon: Icons.dark_mode_rounded,
                      isSelected: current == ThemeMode.dark,
                      onTap: () => _changeTheme(dialogContext, ThemeMode.dark),
                    ),
                    const SizedBox(height: 16),
                    _buildAppearanceOption(
                      title: 'Same as Device',
                      subtitle: 'Follows your device theme settings',
                      icon: Icons.phone_android_rounded,
                      isSelected: current == ThemeMode.system,
                      onTap: () => _changeTheme(dialogContext, ThemeMode.system),
                    ),
                    const SizedBox(height: 32),
                    
                    // Close button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Done',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Add the missing _buildAppearanceOption method
  Widget _buildAppearanceOption({
    required String title,
    String? subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected 
              ? colorScheme.primary.withOpacity(0.12)
              : colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? colorScheme.primary.withOpacity(0.6)
                : colorScheme.outline.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant)
                    .withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: (isSelected ? colorScheme.primary : colorScheme.onSurface)
                            .withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: colorScheme.onPrimary,
                  size: 20,
                ),
              )
            else
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colorScheme.outline.withOpacity(0.3),
                    width: 2,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(User user) {
    final colorScheme = Theme.of(context).colorScheme;

    return RepaintBoundary(
      child: Card(
        elevation: 2,
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: colorScheme.outline,
            width: 1,
          ),
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primaryContainer.withOpacity(0.3),
                colorScheme.secondaryContainer.withOpacity(0.2),
              ],
            ),
          ),
          child: Column(
            children: [
              // Avatar with status indicator
              RepaintBoundary(
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: _showImagePickerOptions,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: _profilePictureService.buildProfileAvatar(
                          displayName: user.displayName,
                          colorScheme: colorScheme,
                          radius: 50,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _showImagePickerOptions,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colorScheme.surface,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.shadow.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.camera_alt_rounded,
                            color: colorScheme.onPrimary,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                user.displayName ?? 'User',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                user.email,
                style: TextStyle(
                  fontSize: 16,
                  color: colorScheme.onSurface.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colorScheme.primary.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  'Premium Member',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Updated to accept goalsState as parameter
  Widget _buildQuickStatsRow(User user, GoalsState goalsState) {
    final colorScheme = Theme.of(context).colorScheme;

    // Defaults
    int transactionCount = 0;
    int goalsCount = 0;
    final daysActive = DateTime.now().difference(user.createdAt).inDays + 1;

    // Transaction count
    final transactionState = context.watch<TransactionBloc>().state;
    if (transactionState is TransactionLoaded) {
      transactionCount = transactionState.transactions.length;
    }

    // Goals count
    if (goalsState is GoalsLoaded) {
      goalsCount = goalsState.goals.length;
    }

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Transactions',
            '$transactionCount',
            Icons.receipt_long_rounded,
            colorScheme.primary,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: _buildStatCard(
            'Goals',
            '$goalsCount',
            Icons.flag_outlined,
            colorScheme.primary,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: _buildStatCard(
            'Days Active',
            '$daysActive',
            Icons.calendar_today_rounded,
            colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    final colorScheme = Theme.of(context).colorScheme;

    return RepaintBoundary(
      child: Card(
        elevation: 2,
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: colorScheme.outline,
            width: 1,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileDetailsCard(User user) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 2,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outline,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.person_rounded,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Profile Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: IconButton(
                    onPressed: () => _showEditProfileDialog(user),
                    icon: Icon(
                      Icons.edit_rounded,
                      color: colorScheme.secondary,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Name', user.displayName ?? 'Not set'),
            _buildDetailRow('Email', user.email),
            _buildDetailRow('Member Since', _formatDate(user.createdAt)),
            _buildDetailRow('User ID', user.id.substring(0, 8) + '...'),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.7),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppSettingsCard() {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 2,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outline,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[600]!.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.settings_rounded,
                    color: Colors.grey[700],
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'App Settings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSettingOption('Appearance', Icons.palette_rounded, () {
              _showAppearancePopup();
            }),
            _buildSettingOption('Notification Settings', Icons.notifications_rounded,
                () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationSettingsScreen(),
                ),
              );
            }),
            _buildSettingSwitch('Biometric Login', false, (value) {}),
            _buildSettingSwitch('Auto Backup', true, (value) {}),
            _buildSettingSwitch('Analytics', false, (value) {}),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingSwitch(
      String title, bool value, Function(bool) onChanged) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingOption(String title, IconData icon, VoidCallback onTap) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: colorScheme.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurface.withOpacity(0.5),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrencySettingsCard() {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 2,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outline,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.currency_exchange_rounded,
                    color: Colors.green,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Currency Settings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildCurrencyDropdown(),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.primary.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.info_outline,
                      color: Colors.blue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Currency will be applied to all transactions, budgets, and financial displays throughout the app.',
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurface.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyDropdown() {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Country & Currency',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: DropdownButtonFormField<Map<String, String>>(
            value: _countries.firstWhere(
              (country) => country['name'] == _selectedCountry,
              orElse: () => _countries.first,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            dropdownColor: colorScheme.surface,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            items: (_countries..sort((a, b) => a['name']!.compareTo(b['name']!))).map((country) {
              return DropdownMenuItem<Map<String, String>>(
                value: country,
                child: Row(
                  children: [
                    _buildFlag(country['name']!),
                    const SizedBox(width: 12),
                    Text('${country['name']} (${country['currency']})'),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) async {
              if (value != null) {
                setState(() {
                  _selectedCountry = value['name']!;
                });
                // Save currency selection globally
                await CurrencyService().setCurrency(value['currency']!);
                AppSnackbar.showSuccess(context,
                    message: 'Currency updated to ${value['currency']}');
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFlag(String countryName) {
    // Simple emoji flag mapping for common countries; fallback to currency symbol colored chip
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
      'Argentina': '🇦🇷',
      'Chile': '🇨🇱',
      'Colombia': '🇨🇴',
      'Peru': '🇵🇪',
      'South Africa': '🇿🇦',
      'Nigeria': '🇳🇬',
      'Kenya': '🇰🇪',
      'Ghana': '🇬🇭',
      'Egypt': '🇪🇬',
      'Morocco': '🇲🇦',
      'Saudi Arabia': '🇸🇦',
      'United Arab Emirates': '🇦🇪',
      'Qatar': '🇶🇦',
      'Kuwait': '🇰🇼',
      'Turkey': '🇹🇷',
      'Israel': '🇮🇱',
      'Pakistan': '🇵🇰',
      'Bangladesh': '🇧🇩',
      'Sri Lanka': '🇱🇰',
      'Singapore': '🇸🇬',
      'Malaysia': '🇲🇾',
      'Indonesia': '🇮🇩',
      'Philippines': '🇵🇭',
      'Thailand': '🇹🇭',
      'Vietnam': '🇻🇳',
      'Hong Kong': '🇭🇰',
      'Taiwan': '🇹🇼',
      'New Zealand': '🇳🇿',
      'Switzerland': '🇨🇭',
      'Norway': '🇳🇴',
      'Sweden': '🇸🇪',
      'Denmark': '🇩🇰',
      'Poland': '🇵🇱',
      'Czech Republic': '🇨🇿',
      'Hungary': '🇭🇺',
      'Romania': '🇷🇴',
      'Bulgaria': '🇧🇬',
      'Serbia': '🇷🇸',
      'Russia': '🇷🇺',
      'Ukraine': '🇺🇦',
      'Iceland': '🇮🇸',
      'Jamaica': '🇯🇲',
      'Dominican Republic': '🇩🇴',
      'Haiti': '🇭🇹',
      'Costa Rica': '🇨🇷',
      'Guatemala': '🇬🇹',
      'Honduras': '🇭🇳',
      'El Salvador': '🇸🇻',
      'Panama': '🇵🇦',
      'Uruguay': '🇺🇾',
      'Paraguay': '🇵🇾',
      'Bolivia': '🇧🇴',
      'Ethiopia': '🇪🇹',
      'Tanzania': '🇹🇿',
      'Uganda': '🇺🇬',
      'Zimbabwe': '🇿🇼',
      'Algeria': '🇩🇿',
      'Tunisia': '🇹🇳',
      'Jordan': '🇯🇴',
      'Lebanon': '🇱🇧',
      'Iraq': '🇮🇶',
    };

    final emoji = flagByCountry[countryName];
    if (emoji != null) {
      return Text(emoji, style: const TextStyle(fontSize: 18));
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Icon(Icons.flag_rounded, size: 14, color: Colors.green),
    );
  }

  Widget _buildAccountActionsCard() {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 2,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outline,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.account_circle_rounded,
                    color: colorScheme.error,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Account Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildActionButton(
              'Export Data',
              Icons.download_outlined,
              () => _handleExportData(),
            ),
            _buildActionButton(
              'Privacy Policy',
              Icons.privacy_tip_outlined,
              () => _showSnackBar('Privacy policy coming soon!'),
            ),
            _buildActionButton(
              'Terms of Service',
              Icons.description_outlined,
              () => _showSnackBar('Terms of service coming soon!'),
            ),
            _buildActionButton(
              'About Us',
              Icons.info_outlined,
              () => _navigateToAboutUs(),
            ),
            _buildActionButton(
              'Sign Out',
              Icons.logout_rounded,
              () => _showSignOutDialog(),
              isDestructive: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, VoidCallback onTap,
      {bool isDestructive = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    final iconColor = isDestructive ? colorScheme.error : colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDestructive
                        ? colorScheme.error
                        : colorScheme.onSurface,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: isDestructive
                    ? colorScheme.error
                    : colorScheme.onSurface.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditProfileDialog(User user) {
    final nameController = TextEditingController(text: user.displayName ?? '');
    final emailController = TextEditingController(text: user.email);
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value == null || value.trim().isEmpty ? 'Enter name' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) =>
                        value == null || value.trim().isEmpty ? 'Enter email' : null,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setState(() => isLoading = true);
                        try {
                          final newName = nameController.text.trim();
                          final newEmail = emailController.text.trim();
                          bool updated = false;

                          if (newName.isNotEmpty && newName != (user.displayName ?? '')) {
                            await authService.updateProfile(
                              userId: user.id,
                              displayName: newName,
                            );
                            updated = true;
                          }

                          if (newEmail.isNotEmpty && newEmail != user.email) {
                            await authService.updateEmail(
                              userId: user.id,
                              newEmail: newEmail,
                            );
                            updated = true;
                          }

                          setState(() => isLoading = false);

                          if (updated && mounted) {
                            context.read<AuthBloc>().add(AuthCheckRequested());
                            Navigator.pop(context);
                            AppSnackbar.showSuccess(this.context, message: 'Profile updated successfully!');
                          } else if (mounted) {
                            Navigator.pop(context);
                            AppSnackbar.showInfo(this.context, message: 'No changes made.');
                          }
                        } catch (e) {
                          setState(() => isLoading = false);
                          if (mounted) {
                            AppSnackbar.showError(context, message: '$e');
                          }
                        }
                      },
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
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
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              authBloc.add(SignOutRequested());
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child:
                const Text('Sign Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _navigateToAboutUs() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AboutUsScreen(),
      ),
    );
  }

  void _handleExportData() {
    final subscriptionState = context.read<SubscriptionBloc>().state;
    if (subscriptionState is SubscriptionPremium) {
      // Mock export functionality
      AppSnackbar.showSuccess(context, message: 'Data exported successfully! (Mock)');
    } else {
      _navigateToPaywall();
    }
  }

  void _navigateToPaywall() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PaywallScreen(),
      ),
    );
  }

  void _showSnackBar(String message) {
    AppSnackbar.showInfo(context, message: message);
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
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
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Change Profile Picture',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(
                Icons.camera_alt_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.photo_library_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_profilePictureService.profileImage != null)
              ListTile(
                leading: Icon(
                  Icons.delete_rounded,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  'Remove Photo',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _removeProfileImage();
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
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

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

  Widget _buildProfileSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile header skeleton
          SkeletonComponents.card(
            height: 200,
            children: [
              Column(
                children: [
                  SkeletonComponents.circle(size: 100, context: context),
                  const SizedBox(height: 16),
                  SkeletonComponents.textLine(width: 150, height: 28),
                  const SizedBox(height: 6),
                  SkeletonComponents.textLine(width: 200, height: 16),
                  const SizedBox(height: 12),
                  SkeletonComponents.textLine(width: 120, height: 32),
                ],
              ),
            ], context: context,
          ),
          const SizedBox(height: 20),
          
          // Quick stats skeleton
          Row(
            children: [
              Expanded(child: SkeletonComponents.card(height: 100, context: context)),
              const SizedBox(width: 4),
              Expanded(child: SkeletonComponents.card(height: 100, context: context)),
              const SizedBox(width: 4),
              Expanded(child: SkeletonComponents.card(height: 100, context: context)),
            ],
          ),
          const SizedBox(height: 16),
          
          // Profile details card skeleton
          SkeletonComponents.card(
            height: 200,
            children: [
              Row(
                children: [
                  SkeletonComponents.circle(size: 32, context: context),
                  const SizedBox(width: 12),
                  SkeletonComponents.textLine(width: 120, height: 18),
                  const Spacer(),
                  SkeletonComponents.circle(size: 32, context: context),
                ],
              ),
              const SizedBox(height: 16),
              ...List.generate(4, (index) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SkeletonComponents.textLine(width: double.infinity, height: 40),
              )),
            ], context: context,
          ),
          const SizedBox(height: 12),
          
          // App settings card skeleton
          SkeletonComponents.card(
            height: 300,
            children: [
              Row(
                children: [
                  SkeletonComponents.circle(size: 32, context: context),
                  const SizedBox(width: 12),
                  SkeletonComponents.textLine(width: 120, height: 18),
                ],
              ),
              const SizedBox(height: 16),
              ...List.generate(5, (index) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: SkeletonComponents.textLine(width: double.infinity, height: 50),
              )),
            ], context: context,
          ),
          const SizedBox(height: 12),
          
          // Currency settings card skeleton
          SkeletonComponents.card(
            height: 200,
            children: [
              Row(
                children: [
                  SkeletonComponents.circle(size: 32, context: context),
                  const SizedBox(width: 12),
                  SkeletonComponents.textLine(width: 150, height: 18),
                ],
              ),
              const SizedBox(height: 16),
              SkeletonComponents.textLine(width: double.infinity, height: 60),
              const SizedBox(height: 16),
              SkeletonComponents.textLine(width: double.infinity, height: 60),
            ], context: context,
          ),
          const SizedBox(height: 12),
          
          // Account actions card skeleton
          SkeletonComponents.card(
            height: 300,
            children: [
              Row(
                children: [
                  SkeletonComponents.circle(size: 32, context: context),
                  const SizedBox(width: 12),
                  SkeletonComponents.textLine(width: 120, height: 18),
                ],
              ),
              const SizedBox(height: 16),
              ...List.generate(5, (index) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SkeletonComponents.textLine(width: double.infinity, height: 50),
              )),
            ], context: context,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _changeTheme(BuildContext dialogContext, ThemeMode mode) {
    // Store the ThemeBloc reference before async operations
    final themeBloc = context.read<ThemeBloc>();
    
    // Close dialog immediately with animation
    Navigator.pop(dialogContext);
    
    // Change theme after dialog animation completes
    Future.delayed(const Duration(milliseconds: 200), () {
      themeBloc.add(ThemeChanged(mode));
    });
  }
}
