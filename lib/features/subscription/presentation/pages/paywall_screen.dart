import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../../../core/constants/app_theme.dart';
import '../../subscription_bloc.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  String _selectedPlanId = 'premium_yearly';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.x, color: colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: BlocConsumer<SubscriptionBloc, SubscriptionState>(
        listener: (context, state) {
          if (state is SubscriptionPremium) {
            Navigator.of(context).pop();
            if (state.isNewPurchase) {
              AppSnackbar.showSuccess(context,
                  message: 'Welcome to Flux Premium!');
            }
          } else if (state is SubscriptionError) {
            AppSnackbar.showError(context, message: state.message);
          }
        },
        builder: (context, state) {
          if (state is SubscriptionLoading) {
            return _buildLoadingState(colorScheme);
          }

          List<ProductDetails> products = [];
          if (state is SubscriptionFree) {
            products = state.products;
          }

          if (products.isNotEmpty &&
              !products.any((p) => p.id == _selectedPlanId)) {
            if (products.any((p) => p.id == 'premium_yearly')) {
              _selectedPlanId = 'premium_yearly';
            } else {
              _selectedPlanId = products.first.id;
            }
          }

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const Spacer(flex: 1),

                  // Title
                  Text(
                    'Go Premium',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'Unlock all features',
                    style: TextStyle(
                      fontSize: 15,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),

                  const Spacer(flex: 1),

                  // Features - compact
                  _buildBenefitRow(LucideIcons.flag, 'Unlimited custom goals'),
                  const SizedBox(height: 10),
                  _buildBenefitRow(LucideIcons.download, 'Export your data'),
                  const SizedBox(height: 10),
                  _buildBenefitRow(LucideIcons.lineChart, 'Advanced insights'),

                  const Spacer(flex: 1),

                  // Subscription options
                  if (products.isEmpty)
                    _buildErrorState()
                  else
                    ...products.map((product) => _buildPlanCard(product)),

                  const Spacer(flex: 1),

                  // CTA Button
                  if (products.isNotEmpty)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final product = products.firstWhere(
                            (p) => p.id == _selectedPlanId,
                            orElse: () => products.first,
                          );
                          context.read<SubscriptionBloc>().add(
                                SubscriptionPurchaseRequested(product),
                              );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Subscribe Now',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 12),

                  // Restore + Cancel
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {
                          context
                              .read<SubscriptionBloc>()
                              .add(SubscriptionRestoreRequested());
                        },
                        child: Text(
                          'Restore',
                          style: TextStyle(
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Text(
                        '•',
                        style: TextStyle(
                          color: colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Maybe later',
                          style: TextStyle(
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState(ColorScheme colorScheme) {
    return Center(
      child: CircularProgressIndicator(color: colorScheme.primary),
    );
  }

  Widget _buildBenefitRow(IconData icon, String text) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
          ),
        ),
        const Spacer(),
        Icon(LucideIcons.checkCircle2, color: AppColors.success, size: 20),
      ],
    );
  }

  Widget _buildPlanCard(ProductDetails product) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = _selectedPlanId == product.id;
    final isYearly = product.id == 'premium_yearly';

    return GestureDetector(
      onTap: () => setState(() => _selectedPlanId = product.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : colorScheme.outline.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Radio
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : colorScheme.outline,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),

            // Title
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        product.title.replaceAll(RegExp(r'\(.*\)'), '').trim(),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                          fontSize: 14,
                        ),
                      ),
                      if (isYearly) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'SAVE 33%',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Price
            Text(
              product.price,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.alertCircle, color: colorScheme.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Unable to load plans',
              style: TextStyle(color: colorScheme.error, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
