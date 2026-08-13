import 'package:flutter/material.dart';

import '../../features/subscription/presentation/pages/paywall_screen.dart';
import 'app_snackbar.dart';

class PremiumUpgradePrompt {
  static void show(BuildContext context, {required String message}) {
    AppSnackbar.show(
      context,
      message: message,
      type: AppSnackbarType.warning,
      duration: const Duration(seconds: 6),
      actionLabel: 'Upgrade',
      onAction: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PaywallScreen()),
        );
      },
    );
  }
}
