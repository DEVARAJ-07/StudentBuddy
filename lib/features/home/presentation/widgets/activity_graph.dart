import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_pallete.dart';
import '../../../../core/common/widgets/glass_container.dart';

class ActivityGraph extends StatelessWidget {
  final List<DateTime> loginDates;

  const ActivityGraph({super.key, this.loginDates = const []});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(20),
        blur: 15,
        opacity: 0.08,
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppPallete.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.grid_view_rounded,
                        color: AppPallete.success,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Activity',
                      style: TextStyle(
                        color: AppPallete.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                // Legend
                Row(
                  children: [
                    const Text(
                      'Less',
                      style: TextStyle(
                        color: AppPallete.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(width: 4),
                    ..._buildLegend(),
                    const SizedBox(width: 4),
                    const Text(
                      'More',
                      style: TextStyle(
                        color: AppPallete.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Month labels
            _buildMonthLabels(),

            const SizedBox(height: 8),

            // Activity grid
            _buildActivityGrid(),

            const SizedBox(height: 8),

            // Day labels
            _buildDayLabels(),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  List<Widget> _buildLegend() {
    final colors = [
      AppPallete.surface,
      AppPallete.success.withValues(alpha: 0.3),
      AppPallete.success.withValues(alpha: 0.5),
      AppPallete.success.withValues(alpha: 0.7),
      AppPallete.success,
    ];

    return colors.map((color) {
      return Container(
        width: 10,
        height: 10,
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      );
    }).toList();
  }

  Widget _buildMonthLabels() {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return Row(
      children: [
        const SizedBox(width: 28), // Space for day labels
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: months.map((month) {
              return Text(
                month,
                style: const TextStyle(
                  color: AppPallete.textSecondary,
                  fontSize: 9,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDayLabels() {
    return const Row(
      children: [
        SizedBox(width: 28),
        Text(
          'Mon',
          style: TextStyle(color: AppPallete.textSecondary, fontSize: 9),
        ),
        Spacer(),
        Text(
          'Wed',
          style: TextStyle(color: AppPallete.textSecondary, fontSize: 9),
        ),
        Spacer(),
        Text(
          'Fri',
          style: TextStyle(color: AppPallete.textSecondary, fontSize: 9),
        ),
        Spacer(),
      ],
    );
  }

  Widget _buildActivityGrid() {
    // Generate activity data for the past year (52 weeks x 7 days)
    final now = DateTime.now();
    final startDate = DateTime(now.year - 1, now.month, now.day);

    // Create a set of login dates for quick lookup
    final loginDateSet = loginDates
        .map((d) => DateTime(d.year, d.month, d.day).toString())
        .toSet();

    // Mock some login dates for demo
    final mockLoginDates = _generateMockLoginDates();
    for (var date in mockLoginDates) {
      loginDateSet.add(DateTime(date.year, date.month, date.day).toString());
    }

    return SizedBox(
      height: 80,
      child: Row(
        children: [
          // Day abbreviations column
          const Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('', style: TextStyle(fontSize: 8)),
              Text(
                'M',
                style: TextStyle(color: AppPallete.textSecondary, fontSize: 8),
              ),
              Text('', style: TextStyle(fontSize: 8)),
              Text(
                'W',
                style: TextStyle(color: AppPallete.textSecondary, fontSize: 8),
              ),
              Text('', style: TextStyle(fontSize: 8)),
              Text(
                'F',
                style: TextStyle(color: AppPallete.textSecondary, fontSize: 8),
              ),
              Text('', style: TextStyle(fontSize: 8)),
            ],
          ),
          const SizedBox(width: 4),
          // Grid
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cellSize = (constraints.maxWidth - 51) / 52; // 52 weeks

                return Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: List.generate(52, (weekIndex) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(7, (dayIndex) {
                        final daysFromStart = weekIndex * 7 + dayIndex;
                        final date = startDate.add(
                          Duration(days: daysFromStart),
                        );
                        final dateKey = DateTime(
                          date.year,
                          date.month,
                          date.day,
                        ).toString();
                        final hasActivity = loginDateSet.contains(dateKey);
                        final intensity = hasActivity ? _getIntensity(date) : 0;

                        return Container(
                          width: cellSize - 1,
                          height: 9,
                          margin: const EdgeInsets.all(0.5),
                          decoration: BoxDecoration(
                            color: _getColorForIntensity(intensity),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        );
                      }),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<DateTime> _generateMockLoginDates() {
    final now = DateTime.now();
    final dates = <DateTime>[];

    // Add some random dates for demo
    for (int i = 0; i < 365; i += 1) {
      final date = now.subtract(Duration(days: i));
      // Simulate ~40% login rate with some patterns
      if ((i % 3 == 0) || (i % 7 == 0) || (date.weekday <= 5 && i % 2 == 0)) {
        dates.add(date);
      }
    }

    return dates;
  }

  int _getIntensity(DateTime date) {
    // Mock intensity based on day of week (more activity on weekdays)
    if (date.weekday <= 5) {
      return (date.day % 4) + 1; // 1-4
    }
    return (date.day % 2) + 1; // 1-2 for weekends
  }

  Color _getColorForIntensity(int intensity) {
    switch (intensity) {
      case 0:
        return AppPallete.surface.withValues(alpha: 0.5);
      case 1:
        return AppPallete.success.withValues(alpha: 0.3);
      case 2:
        return AppPallete.success.withValues(alpha: 0.5);
      case 3:
        return AppPallete.success.withValues(alpha: 0.7);
      case 4:
        return AppPallete.success;
      default:
        return AppPallete.surface;
    }
  }
}
