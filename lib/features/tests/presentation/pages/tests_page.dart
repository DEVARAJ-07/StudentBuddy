import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_pallete.dart';
import '../../../../core/common/widgets/glass_container.dart';
import '../../../../core/services/test_service.dart';
import 'test_intro_page.dart';

class TestsPage extends StatefulWidget {
  const TestsPage({super.key});

  @override
  State<TestsPage> createState() => _TestsPageState();
}

class _TestsPageState extends State<TestsPage> {
  final TestService _testService = TestService();
  Map<String, dynamic> _overallScore = {};
  List<Map<String, dynamic>> _activeTests = [];
  List<Map<String, dynamic>> _completedTests = [];
  List<Map<String, dynamic>> _missedTests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // First mark any expired tests as missed in the DB
    await _testService.markExpiredTestsAsMissed();

    final score = await _testService.getOverallScore();
    final active = await _testService.getActiveTests();
    final completed = await _testService.getCompletedTests();
    final missed = await _testService.getMissedTests();

    if (mounted) {
      setState(() {
        _overallScore = score;
        _activeTests = active;
        _completedTests = completed;
        _missedTests = missed;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppPallete.primary,
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppPallete.primary),
                )
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      _buildHeader(),

                      // Overall Score Card
                      _buildOverallScoreCard(),

                      const SizedBox(height: 20),

                      // Active Tests Section
                      _buildSectionTitle('Active Tests', Icons.timer_outlined),

                      if (_activeTests.isEmpty)
                        _buildNoTestsCard()
                      else
                        ..._activeTests.map(
                          (test) => _buildActiveTestCard(test),
                        ),

                      const SizedBox(height: 20),

                      // Completed Tests Section
                      if (_completedTests.isNotEmpty) ...[
                        _buildSectionTitle(
                          'Completed',
                          Icons.check_circle_outline,
                        ),
                        ..._completedTests.map(
                          (result) => _buildCompletedTestCard(result),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Missed Tests Section
                      if (_missedTests.isNotEmpty) ...[
                        _buildSectionTitle(
                          'Missed',
                          Icons.cancel_outlined,
                        ),
                        ..._missedTests.map(
                          (item) => _buildMissedTestCard(item),
                        ),
                        const SizedBox(height: 20),
                      ],

                      const SizedBox(height: 80),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [AppPallete.primary, AppPallete.secondary],
            ).createShader(bounds),
            child: const Text(
              'Tests',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppPallete.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.assignment_turned_in,
                  color: AppPallete.success,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  '${_overallScore['testsCompleted'] ?? 0} Done',
                  style: const TextStyle(
                    color: AppPallete.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1);
  }

  Widget _buildOverallScoreCard() {
    final percentage = (_overallScore['percentage'] as num?)?.toDouble() ?? 0.0;
    final totalScore = _overallScore['totalScore'] ?? 0;
    final totalQuestions = _overallScore['totalQuestions'] ?? 0;

    Color scoreColor = percentage >= 80
        ? AppPallete.success
        : percentage >= 60
        ? Colors.orange
        : percentage >= 40
        ? AppPallete.primary
        : AppPallete.error;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassContainer(
        padding: const EdgeInsets.all(20),
        borderRadius: BorderRadius.circular(24),
        blur: 20,
        opacity: 0.1,
        color: Colors.white,
        child: Column(
          children: [
            Row(
              children: [
                // Circular progress
                SizedBox(
                  width: 90,
                  height: 90,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 90,
                        height: 90,
                        child: CircularProgressIndicator(
                          value: percentage / 100,
                          strokeWidth: 8,
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
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Overall',
                            style: TextStyle(
                              color: AppPallete.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                // Score details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your Performance',
                        style: TextStyle(
                          color: AppPallete.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$totalScore / $totalQuestions marks',
                        style: const TextStyle(
                          color: AppPallete.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _ScoreStat(
                            icon: Icons.check_circle,
                            label: 'Correct',
                            value: '$totalScore',
                            color: AppPallete.success,
                          ),
                          const SizedBox(width: 16),
                          _ScoreStat(
                            icon: Icons.quiz_rounded,
                            label: 'Total',
                            value: '$totalQuestions',
                            color: AppPallete.primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (totalQuestions == 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppPallete.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppPallete.primary,
                      size: 18,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Complete tests to see your overall score',
                        style: TextStyle(
                          color: AppPallete.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1);
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppPallete.textSecondary, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: AppPallete.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoTestsCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: AppPallete.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppPallete.background,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.assignment_outlined,
                color: AppPallete.textSecondary,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Active Tests',
              style: TextStyle(
                color: AppPallete.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tests will appear here when assigned',
              style: TextStyle(color: AppPallete.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildActiveTestCard(Map<String, dynamic> test) {
    final title = test['title'] as String? ?? 'Test';
    final subject = test['subject'] as String? ?? '';
    final totalQuestions = test['total_questions'] as int? ?? 0;
    final duration = test['duration_minutes'] as int? ?? 30;
    final startTime =
        (DateTime.tryParse(test['start_date'] ?? '') ?? DateTime.now())
            .toLocal();
    final endTime =
        (DateTime.tryParse(test['end_date'] ?? '') ?? DateTime.now())
            .toLocal();
    final now = DateTime.now();

    final isUpcoming = now.isBefore(startTime);
    final isExpired = now.isAfter(endTime);
    final isActive = !isUpcoming && !isExpired;

    Color statusColor = isActive
        ? AppPallete.success
        : isUpcoming
        ? Colors.orange
        : AppPallete.error;
    String statusLabel =
        isActive ? 'Active' : isUpcoming ? 'Upcoming' : 'Ended';
    IconData statusIcon = isActive
        ? Icons.play_circle_fill
        : isUpcoming
        ? Icons.schedule
        : Icons.block;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: GestureDetector(
        onTap: () {
          if (isActive) {
            _navigateToTest(test);
          } else if (isUpcoming) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'This test starts on ${_formatDateTime(startTime)}'),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('This test has ended.'),
                backgroundColor: AppPallete.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppPallete.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: statusColor.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.assignment_rounded,
                      color: statusColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: AppPallete.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          subject,
                          style: const TextStyle(
                            color: AppPallete.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, color: statusColor, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          statusLabel,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Stats row
              Row(
                children: [
                  _TestStat(
                    icon: Icons.quiz_outlined,
                    value: '$totalQuestions Questions',
                  ),
                  const SizedBox(width: 20),
                  _TestStat(
                    icon: Icons.timer_outlined,
                    value: '$duration mins',
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Timeline
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppPallete.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Start',
                            style: TextStyle(
                              color: AppPallete.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                          Text(
                            _formatDateTime(startTime),
                            style: const TextStyle(
                              color: AppPallete.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(height: 30, width: 1, color: AppPallete.surface),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'End',
                            style: TextStyle(
                              color: AppPallete.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                          Text(
                            _formatDateTime(endTime),
                            style: const TextStyle(
                              color: AppPallete.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Enter Test Button — enabled only when active
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: isActive ? AppPallete.primaryGradient : null,
                  color: isActive ? null : AppPallete.background,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: AppPallete.primary.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isActive
                          ? Icons.play_arrow_rounded
                          : isUpcoming
                          ? Icons.lock_clock
                          : Icons.lock_outline,
                      color: isActive
                          ? Colors.white
                          : AppPallete.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isActive
                          ? 'Start Test  ›'
                          : isUpcoming
                          ? 'Not Available Yet'
                          : 'Test Ended',
                      style: TextStyle(
                        color: isActive
                            ? Colors.white
                            : AppPallete.textSecondary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.05);
  }

  Widget _buildCompletedTestCard(Map<String, dynamic> result) {
    final test = result['tests'] as Map<String, dynamic>? ?? {};
    final title = test['title'] as String? ?? 'Test';
    final score = result['score'] as int? ?? 0;
    final total = result['total_questions'] as int? ?? 0;
    final percentage = total > 0 ? (score / total * 100).toInt() : 0;

    Color scoreColor = percentage >= 80
        ? AppPallete.success
        : percentage >= 60
        ? Colors.orange
        : AppPallete.error;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppPallete.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: scoreColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.assignment_turned_in_rounded,
                color: scoreColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppPallete.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '$score / $total correct',
                    style: const TextStyle(
                      color: AppPallete.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: scoreColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$percentage%',
                style: TextStyle(
                  color: scoreColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildMissedTestCard(Map<String, dynamic> item) {
    final test = item['tests'] as Map<String, dynamic>? ?? {};
    final title = test['title'] as String? ?? 'Test';
    final endStr = test['end_date'] as String?;
    final endDate = endStr != null
        ? DateTime.tryParse(endStr)?.toLocal()
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppPallete.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppPallete.error.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppPallete.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.cancel_rounded,
                color: AppPallete.error,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppPallete.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    endDate != null
                        ? 'Ended ${_formatDateTime(endDate)}'
                        : 'Deadline passed',
                    style: const TextStyle(
                      color: AppPallete.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppPallete.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Missed',
                style: TextStyle(
                  color: AppPallete.error,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 350.ms);
  }

  String _formatDateTime(DateTime dt) {
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
    final hour = dt.hour > 12 ? dt.hour - 12 : dt.hour;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${months[dt.month - 1]} ${dt.day}, $hour:${dt.minute.toString().padLeft(2, '0')} $ampm';
  }

  Future<void> _navigateToTest(Map<String, dynamic> test) async {
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            TestIntroPage(test: test),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
    
    // Automatically refresh active/completed tests when returning from the text flow
    if (mounted) {
      _loadData();
    }
  }
}

class _ScoreStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _ScoreStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: AppPallete.textSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TestStat extends StatelessWidget {
  final IconData icon;
  final String value;

  const _TestStat({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppPallete.textSecondary, size: 16),
        const SizedBox(width: 6),
        Text(
          value,
          style: const TextStyle(color: AppPallete.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}
