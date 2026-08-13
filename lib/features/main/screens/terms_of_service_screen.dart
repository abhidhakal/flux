import 'package:flutter/material.dart';
import '../../../shared/widgets/legal_section_text.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Terms of Service'),
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: theme.textTheme.displaySmall?.copyWith(
          fontSize: 24,
          letterSpacing: -1,
        ),
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Effective Date: December 13, 2024',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 24),
            const LegalSectionText(
              title: '1. Introduction',
              content:
                  'These Terms of Service govern your use of the Flux mobile application operated by Klivo Studios. By accessing or using our Service, you agree to be bound by these Terms.',
            ),
            const LegalSectionText(
              title: '2. Use of Service',
              content:
                  'You must be at least 13 years old to use this Service. You agree not to use the Service for any illegal or unauthorized purpose. You are responsible for maintaining the confidentiality of your account and password.',
            ),
            const LegalSectionText(
              title: '3. Subscriptions',
              content:
                  'Some parts of the Service are billed on a subscription basis. You will be billed in advance on a recurring and periodic basis (such as monthly or annually). You may cancel your Subscription at any time through your account settings.',
            ),
            const LegalSectionText(
              title: '4. Intellectual Property',
              content:
                  'The Service and its original content, features, and functionality are and will remain the exclusive property of Klivo Studios and its licensors. The Service is protected by copyright, trademark, and other laws.',
            ),
            const LegalSectionText(
              title: '5. Termination',
              content:
                  'We may terminate or suspend your account immediately, without prior notice or liability, for any reason whatsoever, including without limitation if you breach the Terms.',
            ),
            const LegalSectionText(
              title: '6. Limitation of Liability',
              content:
                  'In no event shall Klivo Studios, nor its directors, employees, partners, agents, suppliers, or affiliates, be liable for any indirect, incidental, special, consequential or punitive damages, including without limitation, loss of profits, data, use, goodwill, or other intangible losses, resulting from your access to or use of or inability to access or use the Service.',
            ),
            const LegalSectionText(
              title: '7. Changes',
              content:
                  'We reserve the right, at our sole discretion, to modify or replace these Terms at any time. If a revision is material we will try to provide at least 30 days notice prior to any new terms taking effect.',
            ),
            const LegalSectionText(
              title: '8. Contact Us',
              content:
                  'If you have any questions about these Terms, please contact us:\n\n'
                  '• By email: info@klivo.com.np\n'
                  '• By visiting our website: klivostudios.com',
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
