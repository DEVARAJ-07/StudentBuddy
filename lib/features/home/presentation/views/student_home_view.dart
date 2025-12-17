import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_pallete.dart';
import '../../../../core/common/widgets/glass_container.dart';

class StudentHomeView extends StatelessWidget {
  final String userName;
  const StudentHomeView({super.key, this.userName = "Student"});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const GlassContainer(
              padding: EdgeInsets.all(30),
              borderRadius: BorderRadius.all(Radius.circular(100)),
              blur: 20,
              opacity: 0.1,
              child: Icon(
                Icons.auto_awesome,
                size: 80,
                color: AppPallete.primary,
              ),
            ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),

            const SizedBox(height: 40),

            Text(
                  "Welcome Back,",
                  style: TextStyle(
                    color: AppPallete.textSecondary,
                    fontSize: 18,
                    letterSpacing: 1.2,
                  ),
                )
                .animate()
                .fadeIn(duration: 300.ms)
                .slideY(begin: 0.2, curve: Curves.easeOutCubic),

            const SizedBox(height: 10),

            Text(
                  userName,
                  style: const TextStyle(
                    color: AppPallete.textPrimary,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                )
                .animate()
                .fadeIn(delay: 100.ms, duration: 300.ms)
                .slideY(begin: 0.2, curve: Curves.easeOutCubic),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: AppPallete.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppPallete.primary.withValues(alpha: 0.2),
                ),
              ),
              child: const Text(
                "Your Personal AI Study Companion",
                style: TextStyle(
                  color: AppPallete.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
          ],
        ),
      ),
    );
  }
}
