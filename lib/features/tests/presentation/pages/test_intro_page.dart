import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_pallete.dart';
import '../../../../core/common/widgets/glass_container.dart';
import '../../../../core/services/test_service.dart';
import 'test_taking_page.dart';

class TestIntroPage extends StatefulWidget {
  final Map<String, dynamic> test;

  const TestIntroPage({super.key, required this.test});

  @override
  State<TestIntroPage> createState() => _TestIntroPageState();
}

class _TestIntroPageState extends State<TestIntroPage> {
  double _slideProgress = 0.0;
  bool _isSliding = false;
  bool _canStart = false;
  bool _isCheckingAttempt = false;
  final TestService _testService = TestService();

  String get title => widget.test['title'] as String? ?? 'Test';
  String get subject => widget.test['subject'] as String? ?? '';
  String get description => widget.test['description'] as String? ?? '';
  int get totalQuestions => widget.test['total_questions'] as int? ?? 15;
  int get duration => widget.test['duration_minutes'] as int? ?? 30;

  bool get _isPastStartDate {
    final startStr = widget.test['start_date'] ?? widget.test['start_time'];
    if (startStr == null) return true;
    try {
      final startDate = DateTime.parse(startStr.toString()).toLocal();
      return DateTime.now().isAfter(startDate);
    } catch (e) {
      return true;
    }
  }

  String _getStartTimeStr() {
    final startStr = widget.test['start_date'] ?? widget.test['start_time'];
    if (startStr == null) return 'soon';
    try {
      final startDate = DateTime.parse(startStr.toString());
      return '${startDate.day}/${startDate.month} ${startDate.hour}:${startDate.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'soon';
    }
  }

  final List<Map<String, dynamic>> _restrictions = [
    {
      'icon': Icons.timer_outlined,
      'title': 'Time Limit',
      'description': 'Complete within the given time',
    },
    {
      'icon': Icons.visibility_off_outlined,
      'title': 'No Going Back',
      'description': 'Cannot return to previous questions',
    },
    {
      'icon': Icons.wifi_off_outlined,
      'title': 'Offline Mode',
      'description': 'Stay connected to submit results',
    },
    {
      'icon': Icons.fullscreen_exit,
      'title': 'Full Screen',
      'description': 'Test runs in immersive mode',
    },
    {
      'icon': Icons.block,
      'title': 'No Switching',
      'description': 'Avoid switching apps during test',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPallete.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Test Info Card
                    _buildTestInfoCard(),

                    const SizedBox(height: 24),

                    // Restrictions Title
                    const Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.orange,
                          size: 22,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Test Restrictions',
                          style: TextStyle(
                            color: AppPallete.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 200.ms),

                    const SizedBox(height: 16),

                    // Restrictions List
                    ...List.generate(_restrictions.length, (index) {
                      return _buildRestrictionItem(_restrictions[index], index);
                    }),

                    const SizedBox(height: 30),

                    // Confirmation checkbox
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() => _canStart = !_canStart);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _canStart
                              ? AppPallete.success.withValues(alpha: 0.1)
                              : AppPallete.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _canStart
                                ? AppPallete.success.withValues(alpha: 0.3)
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: _canStart
                                    ? AppPallete.success
                                    : AppPallete.background,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: _canStart
                                      ? AppPallete.success
                                      : AppPallete.textSecondary,
                                  width: 2,
                                ),
                              ),
                              child: _canStart
                                  ? const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 16,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Text(
                                'I understand and agree to follow all test restrictions',
                                style: TextStyle(
                                  color: AppPallete.textPrimary,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: 400.ms),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),

            // Slide to Start Button
            _buildSlideToStart(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
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
                Icons.close_rounded,
                color: AppPallete.textPrimary,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Test Instructions',
              style: TextStyle(
                color: AppPallete.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1);
  }

  Widget _buildTestInfoCard() {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(24),
      blur: 20,
      opacity: 0.1,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: AppPallete.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.assignment_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppPallete.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppPallete.secondary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        subject,
                        style: const TextStyle(
                          color: AppPallete.secondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (description.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              description,
              style: const TextStyle(
                color: AppPallete.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Stats
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppPallete.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _InfoStat(
                    icon: Icons.quiz_outlined,
                    label: 'Questions',
                    value: '$totalQuestions',
                  ),
                ),
                Container(width: 1, height: 40, color: AppPallete.background),
                Expanded(
                  child: _InfoStat(
                    icon: Icons.timer_outlined,
                    label: 'Duration',
                    value: '$duration mins',
                  ),
                ),
                Container(width: 1, height: 40, color: AppPallete.background),
                const Expanded(
                  child: _InfoStat(
                    icon: Icons.star_outline,
                    label: 'Marks',
                    value: '1 each',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1);
  }

  Widget _buildRestrictionItem(Map<String, dynamic> restriction, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppPallete.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              restriction['icon'] as IconData,
              color: Colors.orange,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  restriction['title'] as String,
                  style: const TextStyle(
                    color: AppPallete.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  restriction['description'] as String,
                  style: const TextStyle(
                    color: AppPallete.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (250 + index * 50).ms).slideX(begin: 0.05);
  }

  bool get _isTestEnded {
    final endStr = widget.test['end_date'] ?? widget.test['end_time'];
    if (endStr == null) return false;
    try {
      final endDate = DateTime.parse(endStr.toString()).toLocal();
      return DateTime.now().isAfter(endDate);
    } catch (e) {
      return false;
    }
  }

  Widget _buildSlideToStart() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: AnimatedOpacity(
        opacity: (_canStart && !_isTestEnded && _isPastStartDate) ? 1.0 : 0.5,
        duration: const Duration(milliseconds: 200),
        child: GestureDetector(
          onHorizontalDragStart:
              (_canStart && !_isTestEnded && _isPastStartDate)
              ? (_) {
                  setState(() => _isSliding = true);
                }
              : (_) {
                  String msg = '';
                  if (_isTestEnded) {
                    msg = 'This test has ended and cannot be taken.';
                  } else if (!_isPastStartDate) {
                    msg =
                        'Test not started yet! Please come back at ${_getStartTimeStr()}';
                  } else if (!_canStart) {
                    msg = 'Please accept the terms to continue.';
                  }

                  if (msg.isNotEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(msg),
                        backgroundColor: _isTestEnded
                            ? AppPallete.error
                            : AppPallete.primary,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
          onHorizontalDragUpdate:
              (_canStart && !_isTestEnded && _isPastStartDate)
              ? (details) {
                  final width = MediaQuery.of(context).size.width - 120;
                  setState(() {
                    _slideProgress = (_slideProgress + details.delta.dx / width)
                        .clamp(0.0, 1.0);
                  });
                }
              : null,
          onHorizontalDragEnd: (_canStart && !_isTestEnded && _isPastStartDate)
              ? (_) {
                  if (_slideProgress > 0.8) {
                    HapticFeedback.heavyImpact();
                    _startTestSafe();
                  } else {
                    setState(() {
                      _slideProgress = 0.0;
                      _isSliding = false;
                    });
                  }
                }
              : null,
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              gradient: (_canStart && !_isTestEnded && _isPastStartDate)
                  ? AppPallete.primaryGradient
                  : null,
              color: (_canStart && !_isTestEnded && _isPastStartDate)
                  ? null
                  : AppPallete.surface,
              borderRadius: BorderRadius.circular(32),
              boxShadow: (_canStart && !_isTestEnded && _isPastStartDate)
                  ? [
                      BoxShadow(
                        color: AppPallete.primary.withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              children: [
                // Progress fill
                AnimatedContainer(
                  duration: const Duration(milliseconds: 50),
                  width:
                      64 +
                      (MediaQuery.of(context).size.width - 104) *
                          _slideProgress,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(32),
                  ),
                ),

                // Slider button
                AnimatedPositioned(
                  duration: _isSliding
                      ? Duration.zero
                      : const Duration(milliseconds: 200),
                  left:
                      4 +
                      (MediaQuery.of(context).size.width - 112) *
                          _slideProgress,
                  top: 4,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Icon(
                      _slideProgress > 0.8
                          ? Icons.check_rounded
                          : Icons.arrow_forward_rounded,
                      color: AppPallete.primary,
                      size: 26,
                    ),
                  ),
                ),

                // Text
                Center(
                  child: AnimatedOpacity(
                    opacity: 1 - _slideProgress,
                    duration: const Duration(milliseconds: 100),
                    child: Text(
                      _isTestEnded
                          ? 'Test Ended'
                          : !_isPastStartDate
                          ? 'Starts at ${_getStartTimeStr()}'
                          : _canStart
                          ? 'Slide to Start Test'
                          : 'Accept terms first',
                      style: TextStyle(
                        color: (_canStart && !_isTestEnded && _isPastStartDate)
                            ? Colors.white
                            : AppPallete.textSecondary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2);
  }

  Future<void> _startTestSafe() async {
    if (_isCheckingAttempt) return;
    setState(() => _isCheckingAttempt = true);

    final testId = widget.test['id'] as String? ?? '';
    final alreadyDone = await _testService.hasCompletedTest(testId);

    if (!mounted) return;

    if (alreadyDone) {
      setState(() {
        _slideProgress = 0.0;
        _isSliding = false;
        _isCheckingAttempt = false;
      });
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppPallete.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Already Completed',
            style: TextStyle(color: AppPallete.textPrimary),
          ),
          content: const Text(
            'You have already completed this test. Each test can only be attempted once.',
            style: TextStyle(color: AppPallete.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK', style: TextStyle(color: AppPallete.primary)),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => _isCheckingAttempt = false);
    _startTest();
  }

  void _startTest() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            TestTakingPage(test: widget.test),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }
}

class _InfoStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppPallete.primary, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: AppPallete.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: AppPallete.textSecondary, fontSize: 10),
        ),
      ],
    );
  }
}
