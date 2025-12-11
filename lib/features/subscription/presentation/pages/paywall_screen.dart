import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../subscription_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import 'dart:ui';
import '../../../../shared/widgets/app_snackbar.dart';

class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close, color: Colors.white, size: 20),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: BlocConsumer<SubscriptionBloc, SubscriptionState>(
        listener: (context, state) {
          if (state is SubscriptionPremium) {
            Navigator.of(context).pop();
            if (state.isNewPurchase) {
              AppSnackbar.showSuccess(context, message: 'Welcome to Flux Premium!');
            }
          } else if (state is SubscriptionError) {
            AppSnackbar.showError(context, message: state.message);
          }
        },
        builder: (context, state) {
          if (state is SubscriptionLoading) {
            return _buildLoadingState();
          }

          ProductDetails? monthlyProduct;
          if (state is SubscriptionFree) {
            final products = state.products;
            try {
              monthlyProduct = products.firstWhere(
                (p) => p.id == 'premium_monthly',
              );
            } catch (_) {
              monthlyProduct = null;
            }
          }

          return Stack(
            children: [
              // 1. Premium Animated Background
              _buildBackground(isDark),

              // 2. Content ScrollView
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      SizedBox(height: MediaQuery.of(context).padding.top + 60),
                      
                      // Premium Badge
                      _buildPremiumBadge(),
                      const SizedBox(height: 24),
                      
                      // Title & Subtitle
                      Text(
                        'Unlock Your Full\nPotential',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Get unlimited access to AI insights, custom goals, and advanced analytics.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withOpacity(0.8),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Features Carousel (Glassmorphism)
                      _buildGlassContainer(
                        child: Column(
                          children: [
                            _buildFeatureRow(
                              context,
                              icon: Icons.auto_awesome_rounded,
                              title: 'AI Intelligence',
                              description: 'Smart spending insights & advice',
                              color: Colors.amber,
                            ),
                            _buildDivider(),
                            _buildFeatureRow(
                              context,
                              icon: Icons.pie_chart_rounded,
                              title: 'Advanced Analytics',
                              description: 'Deep dive into your financial data',
                              color: Colors.blueAccent,
                            ),
                            _buildDivider(),
                            _buildFeatureRow(
                              context,
                              icon: Icons.track_changes_rounded,
                              title: 'Unlimited Goals',
                              description: 'Set and track multiple targets',
                              color: Colors.greenAccent,
                            ),
                            _buildDivider(),
                            _buildFeatureRow(
                              context,
                              icon: Icons.cloud_upload_rounded,
                              title: 'Data Export',
                              description: 'Export to CSV/PDF anytime',
                              color: Colors.purpleAccent,
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 40),

                      // Pricing & CTA
                      _buildPricingSection(monthlyProduct, context),
                      
                      const SizedBox(height: 20),
                      
                      // Restore Purchase
                      TextButton(
                        onPressed: () {
                          context
                              .read<SubscriptionBloc>()
                              .add(SubscriptionRestoreRequested());
                        },
                        child: Text(
                          'Restore Purchases',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Legal Text
                      Text(
                        'Subscription automatically renews. Cancel anytime.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBackground(bool isDark) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A1A2E), // Deep Blue/Black
            Color(0xFF16213E),
            Color(0xFF0F3460),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Ambient Orbs
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.amber.withOpacity(0.15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.2),
                    blurRadius: 100,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blueAccent.withOpacity(0.1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueAccent.withOpacity(0.1),
                    blurRadius: 120,
                    spreadRadius: 40,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.amber),
            const SizedBox(height: 16),
            Text(
              'Loading Store...',
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.1),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, color: Colors.amber, size: 16),
          SizedBox(width: 8),
          Text(
            'FLUX PREMIUM',
            style: TextStyle(
              color: Colors.amber,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassContainer({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildFeatureRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Divider(color: Colors.white.withOpacity(0.1), height: 1),
    );
  }

  Widget _buildPricingSection(ProductDetails? product, BuildContext context) {
    if (product == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Store Unavailable\n(Check Debug Mode)',
                style: TextStyle(color: Colors.red.shade200),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Text(
          '${product.price} / month',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Start your 7-day free trial today',
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              context.read<SubscriptionBloc>().add(
                    SubscriptionPurchaseRequested(product),
                  );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
            ),
            child: const Text(
              'Start Free Trial',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
