import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_theme.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo container with gradient
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radius24),
                boxShadow: AppTheme.shadowMedium,
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.asset(
                  'assets/images/flux_logo.png',
                  width: 44,
                  height: 44,
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacing32),
            
            // App name
            Text(
              'Flux',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppTheme.spacing8),
            
            // Tagline
            Text(
              'Smart Financial Management',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colorScheme.onBackground.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppTheme.spacing48),
            
            // Loading indicator
            Container(
              padding: const EdgeInsets.all(AppTheme.spacing20),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radius16),
                border: Border.all(
                  color: colorScheme.outline,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing16),
                  Text(
                    'Loading your dashboard...',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
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
}
