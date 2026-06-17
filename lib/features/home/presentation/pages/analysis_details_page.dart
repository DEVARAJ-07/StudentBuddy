import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_pallete.dart';
import '../../../../core/common/widgets/glass_container.dart';
import '../../../../core/services/dashboard_service.dart';

class AnalysisDetailsPage extends StatefulWidget {
  final Map<String, dynamic>? userProgress;

  const AnalysisDetailsPage({super.key, this.userProgress});

  @override
  State<AnalysisDetailsPage> createState() => _AnalysisDetailsPageState();
}

class _AnalysisDetailsPageState extends State<AnalysisDetailsPage>
    with SingleTickerProviderStateMixin {
  final DashboardService _dashboardService = DashboardService();
  late AnimationController _animationController;
  late Animation<double> _chartAnimation;

  List<Map<String, dynamic>> _last7DaysStudy = [];
  List<Map<String, dynamic>> _testPerformance = [];
  List<Map<String, dynamic>> _mentorStats = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _chartAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _loadDetailedMetrics();
  }

  Future<void> _loadDetailedMetrics() async {
    final results = await Future.wait([
      _dashboardService.fetchLast7DaysStudy(),
      _dashboardService.fetchTestPerformance(),
      _dashboardService.fetchMentorWeeklyStats(),
    ]);

    if (mounted) {
      setState(() {
        _last7DaysStudy = results[0];
        _testPerformance = results[1];
        _mentorStats = results[2];
      });
      _animationController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  int get _currentStreak =>
      (widget.userProgress?['current_streak'] as int?) ?? 0;
  int get _longestStreak =>
      (widget.userProgress?['longest_streak'] as int?) ?? 0;
  double get _studyHours =>
      (widget.userProgress?['study_hours'] as num?)?.toDouble() ?? 0.0;
  int get _testsCompleted =>
      (widget.userProgress?['tests_completed'] as int?) ?? 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPallete.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadDetailedMetrics,
                color: AppPallete.primary,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),

                      // Streak Section
                      _buildStreakSection(),

                      const SizedBox(height: 24),

                      // Study Hours Chart (MOVED UP)
                      _buildStudyHoursChart(),

                      const SizedBox(height: 24),

                      // Test Performance Graph
                      _buildPerformanceGraph(),

                      const SizedBox(height: 24),

                      // Mentor Time Spent (NEW)
                      _buildMentorPerformance(),

                      const SizedBox(height: 24),

                      // Stats Grid
                      _buildStatsGrid(),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
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
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppPallete.textPrimary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            'Analysis',
            style: TextStyle(
              color: AppPallete.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ).animate().fadeIn().slideX(begin: -0.2),
    );
  }

  Widget _buildStreakSection() {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(24),
      blur: 20,
      opacity: 0.08,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  color: Colors.orange,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily Streak 🔥',
                    style: TextStyle(
                      color: AppPallete.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Keep the fire burning!',
                    style: TextStyle(
                      color: AppPallete.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _StreakStat(
                  label: 'Current Streak',
                  value: '$_currentStreak',
                  unit: 'days',
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StreakStat(
                  label: 'Longest Streak',
                  value: '$_longestStreak',
                  unit: 'days',
                  color: Colors.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Streak Heatmap (7 Days as requested)
          _buildStreakHeatmap(),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildStreakHeatmap() {
    // Check if current/yesterday streak exists
    final List<bool> activity = List.generate(7, (index) {
      // Mock for now, but 7 squares as requested.
      // In a real app we'd fetch actual daily activity.
      return index < _currentStreak;
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Last 7 Days Activity',
          style: TextStyle(color: AppPallete.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 40,
          child: Row(
            children: List.generate(7, (index) {
              final isActive = activity[6 - index]; // Latest on right
              return Expanded(
                child:
                    Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppPallete.primary
                                : AppPallete.surface,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        )
                        .animate(delay: Duration(milliseconds: index * 50))
                        .fadeIn()
                        .scale(),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildStudyHoursChart() {
    // Convert DB data to spots
    final List<BarChartGroupData> barGroups = List.generate(7, (index) {
      double hours = 0;

      // Map index (0-6) to Mon-Sun
      // _last7DaysStudy contains session_date and total_hours
      // Find matching day
      if (_last7DaysStudy.isNotEmpty) {
        final now = DateTime.now();
        final dayOffset =
            index - (now.weekday - 1); // Calculate offset from today
        final targetDate = now.add(Duration(days: dayOffset));
        final dateStr =
            "${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}";

        try {
          final match = _last7DaysStudy.firstWhere(
            (e) => e['session_date'] == dateStr,
          );
          hours = (match['total_hours'] as num).toDouble();
        } catch (_) {}
      }

      return _makeBarGroup(index, hours * _chartAnimation.value);
    });

    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(24),
      blur: 20,
      opacity: 0.08,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.access_time_filled_rounded,
                    color: AppPallete.secondary,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Study Hours',
                    style: TextStyle(
                      color: AppPallete.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppPallete.secondary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_studyHours.toStringAsFixed(1)}h total',
                  style: const TextStyle(
                    color: AppPallete.secondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 150,
            child: AnimatedBuilder(
              animation: _chartAnimation,
              builder: (context, child) {
                return BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 8,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => AppPallete.surface,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            '${rod.toY.toStringAsFixed(1)}h',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                            if (value.toInt() >= 0 && value.toInt() < 7) {
                              return Text(
                                days[value.toInt()],
                                style: const TextStyle(
                                  color: AppPallete.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            }
                            return const SizedBox();
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barGroups: barGroups,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1);
  }

  BarChartGroupData _makeBarGroup(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          gradient: const LinearGradient(
            colors: [AppPallete.secondary, AppPallete.primary],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
          width: 16,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(6),
            topRight: Radius.circular(6),
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceGraph() {
    final List<FlSpot> spots = _testPerformance.isEmpty
        ? [const FlSpot(0, 0)]
        : List.generate(_testPerformance.length, (i) {
            final p =
                (_testPerformance[i]['percentage'] as num?)?.toDouble() ?? 0.0;
            return FlSpot(i.toDouble(), p * _chartAnimation.value);
          });

    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(24),
      blur: 20,
      opacity: 0.08,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics_rounded, color: AppPallete.success),
              SizedBox(width: 10),
              Text(
                'Test Performance',
                style: TextStyle(
                  color: AppPallete.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: AnimatedBuilder(
              animation: _chartAnimation,
              builder: (context, child) {
                return LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 25,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.white.withValues(alpha: 0.05),
                          strokeWidth: 1,
                        );
                      },
                    ),
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (_) => AppPallete.surface,
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            final test = _testPerformance[spot.x.toInt()];
                            final title = test['tests']['title'] ?? 'Test';
                            return LineTooltipItem(
                              '$title\n${spot.y.toStringAsFixed(1)}%',
                              const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 35,
                          getTitlesWidget: (value, meta) => Text(
                            '${value.toInt()}%',
                            style: const TextStyle(
                              color: AppPallete.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() < _testPerformance.length) {
                              final date = DateTime.parse(
                                _testPerformance[value.toInt()]['completed_at'],
                              );
                              return Text(
                                '${date.day}/${date.month}',
                                style: const TextStyle(
                                  color: AppPallete.textSecondary,
                                  fontSize: 10,
                                ),
                              );
                            }
                            return const SizedBox();
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    minY: 0,
                    maxY: 100,
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: AppPallete.primary,
                        barWidth: 3,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              AppPallete.primary.withValues(alpha: 0.2),
                              Colors.transparent,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }

  Widget _buildMentorPerformance() {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(24),
      blur: 20,
      opacity: 0.08,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.psychology_rounded, color: Colors.purpleAccent),
              SizedBox(width: 10),
              Text(
                'Mentor Time spent',
                style: TextStyle(
                  color: AppPallete.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_mentorStats.isEmpty)
            const Center(
              child: Text(
                "No data available",
                style: TextStyle(color: AppPallete.textSecondary, fontSize: 12),
              ),
            )
          else
            SizedBox(
              height: 150,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceEvenly,
                  maxY: 10,
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < _mentorStats.length) {
                            final name =
                                _mentorStats[value
                                        .toInt()]['profiles']['full_name']
                                    as String;
                            return Text(
                              name.split(' ')[0],
                              style: const TextStyle(
                                color: AppPallete.textSecondary,
                                fontSize: 10,
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barTouchData: BarTouchData(
                    touchCallback: (event, response) {
                      if (event is FlTapUpEvent &&
                          response != null &&
                          response.spot != null) {
                        final index = response.spot!.touchedBarGroupIndex;
                        _showMentorDetail(_mentorStats[index]);
                      }
                    },
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => AppPallete.surface,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final name =
                            _mentorStats[groupIndex]['profiles']['full_name']
                                as String;
                        return BarTooltipItem(
                          '$name\n${rod.toY.toStringAsFixed(1)}h',
                          const TextStyle(color: Colors.white, fontSize: 10),
                        );
                      },
                    ),
                  ),
                  barGroups: List.generate(_mentorStats.length, (i) {
                    final hours =
                        (_mentorStats[i]['total_hours'] as num?)?.toDouble() ??
                        0.0;
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: hours * _chartAnimation.value,
                          color: Colors.purpleAccent,
                          width: 20,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1);
  }

  Widget _buildStatsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overall Stats',
          style: TextStyle(
            color: AppPallete.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.quiz_rounded,
                color: AppPallete.primary,
                label: 'Tests Completed',
                value: '$_testsCompleted',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.school_rounded,
                color: AppPallete.success,
                label: 'Avg Score',
                value: _testPerformance.isEmpty
                    ? '0%'
                    : '${(_testPerformance.map((e) => (e['percentage'] as num).toDouble()).reduce((a, b) => a + b) / _testPerformance.length).toStringAsFixed(0)}%',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.timer_rounded,
                color: AppPallete.secondary,
                label: 'Study Time',
                value: '${_studyHours.toStringAsFixed(0)}h',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.emoji_events_rounded,
                color: Colors.amber,
                label: 'Best Streak',
                value: '$_longestStreak days',
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 400.ms);
  }

  void _showMentorDetail(Map<String, dynamic> mentor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MentorDetailPopup(mentor: mentor),
    );
  }
}

class _StreakStat extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _StreakStat({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppPallete.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  unit,
                  style: TextStyle(
                    color: color.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(20),
      blur: 15,
      opacity: 0.08,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: AppPallete.textPrimary,
              fontSize: 22,
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

class _MentorDetailPopup extends StatelessWidget {
  final Map<String, dynamic> mentor;

  const _MentorDetailPopup({required this.mentor});

  @override
  Widget build(BuildContext context) {
    final name = mentor['profiles']['full_name'] as String;
    final studySessions = mentor['sessions'] as List<dynamic>? ?? [];

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: AppPallete.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purpleAccent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.psychology_rounded,
                    color: Colors.purpleAccent,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: AppPallete.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Detailed mentor interactions',
                        style: TextStyle(
                          color: AppPallete.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: studySessions.isEmpty
                ? Center(
                    child: Text(
                      'No interaction logs found for this week.',
                      style: TextStyle(
                        color: AppPallete.textSecondary.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: studySessions.length,
                    itemBuilder: (context, index) {
                      final session = studySessions[index];
                      final date = DateTime.parse(session['created_at']);
                      final duration =
                          (session['duration_seconds'] as int) / 60;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppPallete.surface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${date.day}/${date.month}/${date.year}',
                                  style: const TextStyle(
                                    color: AppPallete.textPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text(
                                  'Interaction Session',
                                  style: TextStyle(
                                    color: AppPallete.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '${duration.toStringAsFixed(1)}m',
                              style: const TextStyle(
                                color: Colors.purpleAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
