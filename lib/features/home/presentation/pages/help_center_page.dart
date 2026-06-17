import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_pallete.dart';
import '../../../../core/common/widgets/glass_container.dart';
import 'about_us_page.dart';

class HelpCenterPage extends StatelessWidget {
  const HelpCenterPage({super.key});

  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'devakrs07@gmail.com',
      query: 'subject=Help Request',
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPallete.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppPallete.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Help Center',
          style: GoogleFonts.poppins(
            color: AppPallete.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Message
            _buildSection(
              icon: Icons.waving_hand_rounded,
              title: "Welcome to Help Center",
              content:
                  "We're here to help you get the most out of Student Buddy. Browse the topics below or contact us directly.",
            ),

            const SizedBox(height: 24),

            // Privacy Policy
            _buildSection(
              icon: Icons.privacy_tip_outlined,
              title: "Privacy Policy",
              content:
                  "Your privacy is important to us. We collect only necessary data to improve your learning experience. Your personal information is never shared with third parties without your consent.",
            ),

            const SizedBox(height: 24),

            // Do's
            _buildSection(
              icon: Icons.check_circle_outline,
              iconColor: AppPallete.success,
              title: "What You Can Do",
              content: """
• Chat with AI mentors for personalized learning
• Track your study progress and streaks
• Take tests and view performance analytics
• Communicate with admins for support
• Upload documents for AI to learn from
""",
            ),

            const SizedBox(height: 24),

            // Don'ts
            _buildSection(
              icon: Icons.cancel_outlined,
              iconColor: AppPallete.error,
              title: "What Not To Do",
              content: """
• Don't share your account credentials
• Avoid uploading copyrighted materials
• Don't use inappropriate language with AI
• Don't attempt to bypass security measures
• Avoid sharing personal sensitive information
""",
            ),

            const SizedBox(height: 32),

            // Action Buttons
            _buildActionTile(
              context,
              icon: Icons.info_outline,
              title: "About Us",
              subtitle: "Learn more about Student Buddy",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AboutUsPage()),
              ),
            ),

            const SizedBox(height: 12),

            _buildActionTile(
              context,
              icon: Icons.email_outlined,
              title: "Contact Support",
              subtitle: "devakrs07@gmail.com",
              onTap: _launchEmail,
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required String content,
    Color? iconColor,
  }) {
    return GlassContainer(
      borderRadius: BorderRadius.circular(16),
      blur: 10,
      opacity: 0.05,
      color: AppPallete.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor ?? AppPallete.primary, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: AppPallete.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: GoogleFonts.inter(
              color: AppPallete.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.05);
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GlassContainer(
      borderRadius: BorderRadius.circular(16),
      blur: 10,
      opacity: 0.05,
      color: AppPallete.surface,
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppPallete.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppPallete.primary),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            color: AppPallete.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: AppPallete.textSecondary, fontSize: 12),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: AppPallete.textSecondary,
        ),
      ),
    );
  }
}
