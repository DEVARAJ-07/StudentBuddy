import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_pallete.dart';
import '../../../../core/common/widgets/glass_container.dart';

class QuickStatsCard extends StatelessWidget {
  final int currentStreak;
  final int testsCompleted;
  final double studyHours;

  const QuickStatsCard({
    super.key,
    this.currentStreak = 0,
    this.testsCompleted = 0,
    this.studyHours = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: GlassContainer(
        padding: const EdgeInsets.all(20),
        borderRadius: BorderRadius.circular(24),
        blur: 20,
        opacity: 0.08,
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatItem(
              icon: Icons.local_fire_department_rounded,
              iconColor: Colors.orange,
              value: '$currentStreak',
              label: 'Streak',
              delay: 0,
            ),
            _VerticalDivider(),
            _StatItem(
              icon: Icons.quiz_rounded,
              iconColor: AppPallete.primary,
              value: '$testsCompleted',
              label: 'Tests',
              delay: 100,
            ),
            _VerticalDivider(),
            _StatItem(
              icon: Icons.access_time_filled_rounded,
              iconColor: AppPallete.success,
              value: '${studyHours.toStringAsFixed(1)}h',
              label: 'Study',
              delay: 200,
            ),
          ],
        ),
      ).animate().fadeIn().slideY(begin: 0.1),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final int delay;

  const _StatItem({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                color: AppPallete.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: AppPallete.textSecondary, fontSize: 12),
            ),
          ],
        )
        .animate()
        .fadeIn(delay: Duration(milliseconds: delay))
        .scale(delay: Duration(milliseconds: delay));
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      width: 1,
      color: Colors.white.withValues(alpha: 0.1),
    );
  }
}
