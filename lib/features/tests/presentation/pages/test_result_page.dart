import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_pallete.dart';
import '../../../../core/common/widgets/glass_container.dart';

class TestResultPage extends StatefulWidget {
  final Map<String, dynamic> test;
  final List<Map<String, dynamic>> questions;
  final Map<int, int> answers;
  final int score;

  const TestResultPage({
    super.key,
    required this.test,
    required this.questions,
    required this.answers,
    required this.score,
  });

  @override
  State<TestResultPage> createState() => _TestResultPageState();
}

class _TestResultPageState extends State<TestResultPage>
    with TickerProviderStateMixin {
  late AnimationController _celebrationController;

  int get correctCount => widget.score;
  int get wrongCount => widget.questions.length - widget.score;
  int get totalCount => widget.questions.length;

  double get percentage =>
      totalCount > 0 ? (correctCount / totalCount) * 100 : 0;

  Color get scoreColor => percentage >= 80
      ? AppPallete.success
      : percentage >= 60
      ? Colors.orange
      : percentage >= 40
      ? AppPallete.primary
      : AppPallete.error;

  String get resultMessage {
    if (percentage >= 80) return 'Excellent! 🎉';
    if (percentage >= 60) return 'Good Job! 👍';
    if (percentage >= 40) return 'Keep Trying! 💪';
    return 'Need Practice 📚';
  }

  String get resultDescription {
    if (percentage >= 80) {
      return 'Outstanding performance! Keep up the great work!';
    }
    if (percentage >= 60) {
      return 'Well done! You\'re on the right track.';
    }
    if (percentage >= 40) {
      return 'Good effort! A bit more practice will help.';
    }
    return 'Don\'t give up! Review the topics and try again.';
  }

  @override
  void initState() {
    super.initState();
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    if (percentage >= 80) {
      _celebrationController.forward();
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.mediumImpact();
    }
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    super.dispose();
  }

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
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(
                      context,
                    ).popUntil((route) => route.isFirst),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppPallete.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: AppPallete.textPrimary,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Main Score Section
            _buildScoreSection(),

            const Spacer(),

            // Stats Cards
            _buildStatsRow(),

            const SizedBox(height: 30),

            // Done button
            Padding(
              padding: const EdgeInsets.all(20),
              child: GestureDetector(
                onTap: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: AppPallete.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppPallete.primary.withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Text(
                    'Back to Tests',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreSection() {
    return Column(
      children: [
        // Result message
        Text(
          resultMessage,
          style: TextStyle(
            color: scoreColor,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ).animate().fadeIn().scale(delay: 100.ms),

        const SizedBox(height: 10),

        Text(
          resultDescription,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppPallete.textSecondary, fontSize: 14),
        ).animate().fadeIn(delay: 200.ms),

        const SizedBox(height: 40),

        // Circular score
        GlassContainer(
          padding: const EdgeInsets.all(30),
          borderRadius: BorderRadius.circular(100),
          blur: 20,
          opacity: 0.1,
          color: Colors.white,
          child: SizedBox(
            width: 160,
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 160,
                  height: 160,
                  child: CircularProgressIndicator(
                    value: percentage / 100,
                    strokeWidth: 14,
                    backgroundColor: AppPallete.surface,
                    valueColor: AlwaysStoppedAnimation(scoreColor),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${percentage.toInt()}%',
                      style: TextStyle(
                        color: scoreColor,
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$correctCount / $totalCount',
                      style: const TextStyle(
                        color: AppPallete.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: 300.ms).scale(),

        const SizedBox(height: 30),

        // Test title
        Text(
          widget.test['title'] as String? ?? 'Test',
          style: const TextStyle(
            color: AppPallete.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ).animate().fadeIn(delay: 400.ms),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              icon: Icons.check_circle_rounded,
              label: 'Correct',
              value: '$correctCount',
              color: AppPallete.success,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              icon: Icons.cancel_rounded,
              label: 'Wrong',
              value: '$wrongCount',
              color: AppPallete.error,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              icon: Icons.quiz_rounded,
              label: 'Total',
              value: '$totalCount',
              color: AppPallete.primary,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1);
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: AppPallete.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: AppPallete.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
