import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: const Text('Privacy Policy'),
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
              'Welcome to Flux. We are committed to protecting your personal information and your right to privacy. This Privacy Policy explains what information we collect, how we use it, and your rights in relation to it.',
            ),
            _buildSection(
              context,
              '2. Information We Collect',
              'We collect information that you provide directly to us, such as when you create an account, update your profile, or use our financial tracking features.\n\n'
              '• Personal Information: Name, email address, profile picture.\n'
              '• Financial Data: Transaction records, budget details, and goals you input manually or sync.\n'
              '• Usage Data: Information about how you interact with our app, such as features used and time spent.',
            ),
            _buildSection(
              context,
              '3. How We Use Your Information',
              'We use your personal information for the following purposes:\n\n'
              '• To provide and maintain our Service.\n'
              '• To personalize your experience and provide AI-driven insights.\n'
              '• To notify you about changes to our Service.\n'
              '• To provide customer support.\n'
              '• To monitor the usage of the Service and detect technical issues.',
            ),
            _buildSection(
              context,
              '4. Data Security',
              'The security of your data is important to us. We strive to use commercially acceptable means to protect your Personal Data, including encryption and secure storage protocols. However, remember that no method of transmission over the Internet is 100% secure.',
            ),
            _buildSection(
              context,
              '5. Contact Us',
              'If you have any questions about this Privacy Policy, please contact us:\n\n'
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
