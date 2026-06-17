import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_pallete.dart';
import '../../../../core/common/widgets/glass_container.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPallete.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppPallete.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppPallete.textPrimary,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Privacy Policy',
                    style: TextStyle(
                      color: AppPallete.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: -0.1),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection(
                      'Last Updated',
                      'December 19, 2024',
                      Icons.calendar_today_rounded,
                    ),

                    _buildSection(
                      '1. Information We Collect',
                      'We collect information you provide directly to us, including:\n\n• Account information (name, email, password)\n• Profile information (date of birth, preferences)\n• Test results and learning progress\n• Chat messages with AI mentors\n• Usage data and app interactions',
                      Icons.info_outline_rounded,
                    ),

                    _buildSection(
                      '2. How We Use Your Information',
                      'We use the information we collect to:\n\n• Provide, maintain, and improve our services\n• Personalize your learning experience\n• Track and analyze your progress\n• Send you notifications and updates\n• Respond to your comments and questions\n• Ensure security and prevent fraud',
                      Icons.settings_rounded,
                    ),

                    _buildSection(
                      '3. Data Storage & Security',
                      'Your data is securely stored using industry-standard encryption. We use Supabase as our backend provider, which implements:\n\n• Row-level security policies\n• SSL/TLS encryption in transit\n• AES-256 encryption at rest\n• Regular security audits',
                      Icons.security_rounded,
                    ),

                    _buildSection(
                      '4. Data Sharing',
                      'We do not sell your personal information. We may share your information only:\n\n• With your consent\n• To comply with legal obligations\n• To protect our rights and safety\n• With service providers who assist our operations',
                      Icons.share_rounded,
                    ),

                    _buildSection(
                      '5. Your Rights',
                      'You have the right to:\n\n• Access your personal data\n• Correct inaccurate data\n• Delete your account and data\n• Export your data\n• Opt-out of marketing communications',
                      Icons.verified_user_rounded,
                    ),

                    _buildSection(
                      '6. Cookies & Analytics',
                      'We use analytics to understand how our app is used and to improve our services. This data is anonymized and aggregated.',
                      Icons.analytics_rounded,
                    ),

                    _buildSection(
                      '7. Children\'s Privacy',
                      'Our service is designed for students of all ages. For users under 13, we require parental consent and collect only necessary information for educational purposes.',
                      Icons.child_care_rounded,
                    ),

                    _buildSection(
                      '8. Changes to Policy',
                      'We may update this policy from time to time. We will notify you of any changes by posting the new policy on this page and updating the "Last Updated" date.',
                      Icons.update_rounded,
                    ),

                    _buildSection(
                      '9. Contact Us',
                      'If you have any questions about this Privacy Policy, please contact us at:\n\nEmail: devakrs07@gmail.com',
                      Icons.contact_mail_rounded,
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(16),
        blur: 15,
        opacity: 0.08,
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppPallete.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: AppPallete.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: const TextStyle(
                color: AppPallete.textSecondary,
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 100.ms);
  }
}
