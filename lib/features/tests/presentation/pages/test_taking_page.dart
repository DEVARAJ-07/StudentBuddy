import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_pallete.dart';
import '../../../../core/services/test_service.dart';
import 'test_result_page.dart';

class TestTakingPage extends StatefulWidget {
  final Map<String, dynamic> test;

  const TestTakingPage({super.key, required this.test});

  @override
  State<TestTakingPage> createState() => _TestTakingPageState();
}

class _TestTakingPageState extends State<TestTakingPage> {
  final TestService _testService = TestService();
  List<Map<String, dynamic>> _questions = [];
  final Map<int, int> _answers = {};
  int _currentIndex = 0;
  bool _isLoading = true;
  Timer? _timer;
  int _remainingSeconds = 0;

  String get testId => widget.test['id'] as String? ?? '';
  int get duration => widget.test['duration_minutes'] as int? ?? 30;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    final questions = await _testService.getTestQuestions(testId);
    if (mounted) {
      setState(() {
        _questions = questions;
        _remainingSeconds = duration * 60;
        _isLoading = false;
      });
      _startTimer();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _timer?.cancel();
        _submitTest();
      }
    });
  }

  void _selectAnswer(int answerIndex) {
    HapticFeedback.lightImpact();
    setState(() {
      _answers[_currentIndex] = answerIndex;
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() => _currentIndex++);
    }
  }

  void _previousQuestion() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
    }
  }

  Future<void> _submitTest() async {
    _timer?.cancel();

    // Calculate score
    int score = 0;
    for (int i = 0; i < _questions.length; i++) {
      final correctAnswer = _questions[i]['correct_answer'] as int? ?? 0;
      if (_answers[i] == correctAnswer) {
        score++;
      }
    }

    // Submit to DB
    await _testService.submitTestResult(
      testId: testId,
      score: score,
      totalQuestions: _questions.length,
      answers: _answers.map((k, v) => MapEntry(k.toString(), v)),
      assignmentId: widget.test['assignment_id'],
    );

    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              TestResultPage(
                test: widget.test,
                questions: _questions,
                answers: _answers,
                score: score,
              ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    }
  }

  String get _formattedTime {
    final mins = _remainingSeconds ~/ 60;
    final secs = _remainingSeconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppPallete.background,
        body: Center(
          child: CircularProgressIndicator(color: AppPallete.primary),
        ),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        backgroundColor: AppPallete.background,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.quiz_outlined,
                    size: 64,
                    color: AppPallete.textSecondary,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'No questions found',
                    style: TextStyle(
                      color: AppPallete.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'This test has no questions yet. Please contact your admin.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppPallete.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('Go Back'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppPallete.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final question = _questions[_currentIndex];
    final options = question['options'] as List<dynamic>? ?? [];
    final selectedAnswer = _answers[_currentIndex];

    return Scaffold(
      backgroundColor: AppPallete.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header with timer
            _buildHeader(),

            // Progress bar
            _buildProgressBar(),

            // Question
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Question number
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppPallete.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Question ${_currentIndex + 1} of ${_questions.length}',
                        style: const TextStyle(
                          color: AppPallete.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ).animate().fadeIn(),

                    const SizedBox(height: 20),

                    // Question text
                    Text(
                      question['question_text'] as String? ??
                          question['question'] as String? ??
                          '',
                      style: const TextStyle(
                        color: AppPallete.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ).animate().fadeIn(delay: 100.ms),

                    const SizedBox(height: 30),

                    // Options
                    ...List.generate(options.length, (index) {
                      final isSelected = selectedAnswer == index;
                      return GestureDetector(
                            onTap: () => _selectAnswer(index),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(bottom: 14),
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppPallete.primary.withValues(alpha: 0.1)
                                    : AppPallete.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? AppPallete.primary
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppPallete.primary
                                          : AppPallete.background,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected
                                            ? AppPallete.primary
                                            : AppPallete.textSecondary,
                                        width: 2,
                                      ),
                                    ),
                                    child: Center(
                                      child: isSelected
                                          ? const Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 18,
                                            )
                                          : Text(
                                              String.fromCharCode(65 + index),
                                              style: const TextStyle(
                                                color: AppPallete.textSecondary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      options[index] as String,
                                      style: TextStyle(
                                        color: isSelected
                                            ? AppPallete.primary
                                            : AppPallete.textPrimary,
                                        fontSize: 15,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .animate(delay: (150 + index * 50).ms)
                          .fadeIn()
                          .slideX(begin: 0.05);
                    }),
                  ],
                ),
              ),
            ),

            // Navigation buttons
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isLowTime = _remainingSeconds < 60;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Question counter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppPallete.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.quiz_outlined,
                  color: AppPallete.textSecondary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  '${_answers.length}/${_questions.length}',
                  style: const TextStyle(
                    color: AppPallete.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Timer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isLowTime
                  ? AppPallete.error.withValues(alpha: 0.15)
                  : AppPallete.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.timer_outlined,
                  color: isLowTime
                      ? AppPallete.error
                      : AppPallete.textSecondary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  _formattedTime,
                  style: TextStyle(
                    color: isLowTime
                        ? AppPallete.error
                        : AppPallete.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final progress = (_currentIndex + 1) / _questions.length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 6,
      decoration: BoxDecoration(
        color: AppPallete.surface,
        borderRadius: BorderRadius.circular(3),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            gradient: AppPallete.primaryGradient,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    final isLastQuestion = _currentIndex == _questions.length - 1;
    final hasAnswered = _answers.containsKey(_currentIndex);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppPallete.surface,
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      child: Row(
        children: [
          // Previous button
          if (_currentIndex > 0)
            Expanded(
              child: GestureDetector(
                onTap: _previousQuestion,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppPallete.background,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.arrow_back_rounded,
                        color: AppPallete.textSecondary,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Previous',
                        style: TextStyle(
                          color: AppPallete.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            const Spacer(),

          const SizedBox(width: 12),

          // Next/Submit button
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: () {
                if (isLastQuestion) {
                  _showSubmitDialog();
                } else {
                  _nextQuestion();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: hasAnswered ? AppPallete.primaryGradient : null,
                  color: hasAnswered ? null : AppPallete.surface,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: hasAnswered
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
                    Text(
                      isLastQuestion ? 'Submit Test' : 'Next',
                      style: TextStyle(
                        color: hasAnswered
                            ? Colors.white
                            : AppPallete.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isLastQuestion
                          ? Icons.check_rounded
                          : Icons.arrow_forward_rounded,
                      color: hasAnswered
                          ? Colors.white
                          : AppPallete.textSecondary,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSubmitDialog() {
    final unanswered = _questions.length - _answers.length;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppPallete.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Submit Test?',
          style: TextStyle(
            color: AppPallete.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (unanswered > 0)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '$unanswered question${unanswered > 1 ? 's' : ''} unanswered',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            const Text(
              'Are you sure you want to submit your test?',
              style: TextStyle(color: AppPallete.textSecondary, fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppPallete.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _submitTest();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppPallete.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Submit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
