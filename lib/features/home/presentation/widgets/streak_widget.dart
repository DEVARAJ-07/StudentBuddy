import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/common/widgets/glass_container.dart';

class StreakWidget extends StatelessWidget {
  const StreakWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data: 60 days of activity (0 to 4 intensity)
    final List<int> activity = List.generate(60, (index) => (index * 7) % 5);

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(20),
      blur: 15,
      opacity: 0.1,
      width: double.infinity,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Daily Streak 🔥",
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "You're on a 12-day streak!",
                    style: TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber),
                ),
                child: const Text(
                  "12 Days",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Heatmap Grid
          SizedBox(
            height: 100, // Fixed height for the grid
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 15, // Days per row
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: activity.length,
              itemBuilder: (context, index) {
                final intensity = activity[index];
                return Container(
                  decoration: BoxDecoration(
                    color: _getColor(intensity),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ).animate().fadeIn(delay: (index * 10).ms).scale();
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getColor(int intensity) {
    if (intensity == 0) {
      return Colors.white.withValues(
        alpha: 0.1,
      ); // Inactive cell (dark theme friendly)
    }
    // High contrast scale
    if (intensity == 1) return const Color(0xFF64B5F6); // Light Blue
    if (intensity == 2) return const Color(0xFF42A5F5);
    if (intensity == 3) return const Color(0xFF2196F3);
    return const Color(0xFF1565C0); // Dark Blue (Max intensity)
  }
}
