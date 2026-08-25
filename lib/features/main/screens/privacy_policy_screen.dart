import 'package:flutter/material.dart';
import '../../../core/constants/app_theme.dart';
import '../../../shared/widgets/legal_section_text.dart';
import '../../../shared/widgets/premium_page_hero.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      backgroundColor: AppTheme.pageSurface(context),
      body: Column(
        children: [
          const PremiumPageHero(
            title: 'Privacy Policy',
            subtitle: 'How Flux protects your information',
            showBackButton: true,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Effective Date: December 13, 2024',
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const LegalSectionText(
                    title: '1. Introduction',
                    content:
                        'Welcome to Flux. We are committed to protecting your personal information and your right to privacy. This Privacy Policy explains what information we collect, how we use it, and your rights in relation to it.',
                  ),
                  const LegalSectionText(
                    title: '2. Information We Collect',
                    content:
                        'We collect information that you provide directly to us, such as when you create an account, update your profile, or use our financial tracking features.\n\n'
                        '• Personal Information: Name, email address, profile picture.\n'
                        '• Financial Data: Transaction records, budget details, and goals you input manually or sync.\n'
                        '• Usage Data: Information about how you interact with our app, such as features used and time spent.',
                  ),
                  const LegalSectionText(
                    title: '3. How We Use Your Information',
                    content:
                        'We use your personal information for the following purposes:\n\n'
                        '• To provide and maintain our Service.\n'
                        '• To personalize your experience and provide AI-driven insights.\n'
                        '• To notify you about changes to our Service.\n'
                        '• To provide customer support.\n'
                        '• To monitor the usage of the Service and detect technical issues.',
                  ),
                  const LegalSectionText(
                    title: '4. Data Security',
                    content:
                        'The security of your data is important to us. We strive to use commercially acceptable means to protect your Personal Data, including encryption and secure storage protocols. However, remember that no method of transmission over the Internet is 100% secure.',
                  ),
                  const LegalSectionText(
                    title: '5. Contact Us',
                    content:
                        'If you have any questions about this Privacy Policy, please contact us:\n\n'
                        '• By email: info@klivo.com.np\n'
                        '• By visiting our website: klivostudios.com',
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
