import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_pallete.dart';
import '../../../../core/common/widgets/glass_container.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

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
          'About Us',
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
          children: [
            // App Logo/Icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppPallete.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppPallete.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.school_rounded,
                color: Colors.white,
                size: 50,
              ),
            ).animate().fadeIn().scale(),

            const SizedBox(height: 24),

            Text(
              'Student Buddy',
              style: GoogleFonts.poppins(
                color: AppPallete.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const Text(
              'Version 1.0.0',
              style: TextStyle(color: AppPallete.textSecondary, fontSize: 14),
            ),

            const SizedBox(height: 32),

            // Mission
            _buildInfoCard(
              icon: Icons.rocket_launch_rounded,
              title: 'Our Mission',
              content:
                  'To revolutionize education by providing AI-powered personalized learning experiences that adapt to each student\'s unique needs and pace.',
            ),

            const SizedBox(height: 16),

            // What We Offer
            _buildInfoCard(
              icon: Icons.auto_awesome,
              title: 'What We Offer',
              content: """
🤖 AI Mentors - Personalized tutoring in various subjects
📊 Progress Tracking - Monitor your learning journey
📝 Smart Tests - Adaptive assessments to gauge understanding
💬 Community Support - Connect with admins and peers
📚 Document Learning - AI learns from your materials""",
            ),

            const SizedBox(height: 16),

            // Team
            _buildInfoCard(
              icon: Icons.people_rounded,
              title: 'Our Team',
              content:
                  'Built with ❤️ by a passionate team of educators and engineers who believe in the power of technology to transform learning.',
            ),

            const SizedBox(height: 16),

            // Contact
            _buildInfoCard(
              icon: Icons.contact_mail_rounded,
              title: 'Contact Us',
              content: """
📧 Email: devakrs07@gmail.com
🌐 Website: www.studentbuddy.app
📍 Location: Education Tech Hub""",
            ),

            const SizedBox(height: 32),

            // Footer
            const Text(
              '© 2024 Student Buddy. All rights reserved.',
              style: TextStyle(color: AppPallete.textSecondary, fontSize: 12),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppPallete.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppPallete.primary, size: 22),
              ),
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
              height: 1.6,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.05);
  }
}
