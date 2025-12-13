import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: const Text('Terms of Service'),
        centerTitle: false,
        backgroundColor: colorScheme.background,
        foregroundColor: colorScheme.onBackground,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: colorScheme.onBackground,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: colorScheme.onBackground),
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
                color: colorScheme.onSurfaceVariant.withOpacity(0.8),
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              '1. Introduction',
              'These Terms of Service govern your use of the Flux mobile application operated by Klivo Studios. By accessing or using our Service, you agree to be bound by these Terms.',
            ),
            _buildSection(
              context,
              '2. Use of Service',
              'You must be at least 13 years old to use this Service. You agree not to use the Service for any illegal or unauthorized purpose. You are responsible for maintaining the confidentiality of your account and password.',
            ),
            _buildSection(
              context,
              '3. Subscriptions',
              'Some parts of the Service are billed on a subscription basis. You will be billed in advance on a recurring and periodic basis (such as monthly or annually). You may cancel your Subscription at any time through your account settings.',
            ),
            _buildSection(
              context,
              '4. Intellectual Property',
              'The Service and its original content, features, and functionality are and will remain the exclusive property of Klivo Studios and its licensors. The Service is protected by copyright, trademark, and other laws.',
            ),
            _buildSection(
              context,
              '5. Termination',
              'We may terminate or suspend your account immediately, without prior notice or liability, for any reason whatsoever, including without limitation if you breach the Terms.',
            ),
            _buildSection(
              context,
              '6. Limitation of Liability',
              'In no event shall Klivo Studios, nor its directors, employees, partners, agents, suppliers, or affiliates, be liable for any indirect, incidental, special, consequential or punitive damages, including without limitation, loss of profits, data, use, goodwill, or other intangible losses, resulting from your access to or use of or inability to access or use the Service.',
            ),
            _buildSection(
              context,
              '7. Changes',
              'We reserve the right, at our sole discretion, to modify or replace these Terms at any time. If a revision is material we will try to provide at least 30 days notice prior to any new terms taking effect.',
            ),
            _buildSection(
              context,
              '8. Contact Us',
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

  Widget _buildSection(BuildContext context, String title, String content) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onBackground,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onSurface.withOpacity(0.8),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
