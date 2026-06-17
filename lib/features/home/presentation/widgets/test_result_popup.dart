import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_pallete.dart';
import '../../../../core/common/widgets/glass_container.dart';
import '../../../../core/services/test_service.dart';

void showTestResultPopup(BuildContext context, Map<String, dynamic> test) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => TestResultPopup(test: test),
  );
}

class TestResultPopup extends StatefulWidget {
  final Map<String, dynamic> test;

  const TestResultPopup({super.key, required this.test});

  @override
  State<TestResultPopup> createState() => _TestResultPopupState();
}

class _TestResultPopupState extends State<TestResultPopup> {
  final TestService _testService = TestService();
  List<Map<String, dynamic>> _questions = [];
  bool _isLoading = true;
  int _expandedQuestion = -1;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final testId = widget.test['test_id'] ?? widget.test['id'];
      if (testId == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // 1. Fetch full questions from DB
      final dbQuestions = await _testService.getTestQuestions(testId);

      // 2. Map answers from test results
      // widget.test['answers'] is a Map<String, dynamic> where key is string index
      final userAnswers = widget.test['answers'] as Map<String, dynamic>? ?? {};

      final mappedQuestions = dbQuestions.asMap().entries.map((entry) {
        final index = entry.key;
        final q = entry.value;
        final selected = userAnswers[index.toString()];

        return {
          ...q,
          'question': q['question_text'] ?? q['question'] ?? 'No Question',
          'correctAnswer': q['correct_answer'] ?? 0,
          'selectedAnswer': selected != null
              ? int.tryParse(selected.toString()) ?? -1
              : -1,
          'explanation': q['explanation'] ?? 'No explanation provided.',
        };
      }).toList();

      if (mounted) {
        setState(() {
          _questions = mappedQuestions;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading analysis data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.4,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AppPallete.primary),
        ),
      );
    }

    final score = (widget.test['percentage'] ?? widget.test['score'] ?? 0)
        .toInt();
    final scoreColor = score >= 80
        ? AppPallete.success
        : score >= 60
        ? Colors.orange
        : AppPallete.error;

    final theme = Theme.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppPallete.surface.withValues(alpha: 0.5),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppPallete.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: const Icon(
                          Icons.arrow_downward_rounded,
                          color: AppPallete.textPrimary,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.test['title'] ?? 'Test Analysis',
                            style: const TextStyle(
                              color: AppPallete.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.test['subject'] ??
                                'Detailed Performance Report',
                            style: const TextStyle(
                              color: AppPallete.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        gradient: AppPallete.primaryGradient,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: scoreColor.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        '$score%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Score summary
                GlassContainer(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(16),
                  borderRadius: BorderRadius.circular(20),
                  blur: 15,
                  opacity: 0.1,
                  color: AppPallete.surface,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(
                        icon: Icons.check_circle_rounded,
                        label: 'Correct',
                        value: '${widget.test['score'] ?? 0}',
                        color: AppPallete.success,
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                      _StatItem(
                        icon: Icons.cancel_rounded,
                        label: 'Wrong',
                        value: '${widget.test['wrong_count'] ?? 0}',
                        color: AppPallete.error,
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                      _StatItem(
                        icon: Icons.quiz_rounded,
                        label: 'Total',
                        value:
                            '${widget.test['total_questions'] ?? _questions.length}',
                        color: AppPallete.primary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn().slideY(begin: -0.1),

          // Questions list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _questions.length,
              itemBuilder: (context, index) {
                final question = _questions[index];
                return _QuestionCard(
                  index: index,
                  question: question,
                  isExpanded: _expandedQuestion == index,
                  onExpandTap: () {
                    setState(() {
                      _expandedQuestion = _expandedQuestion == index
                          ? -1
                          : index;
                    });
                  },
                ).animate(delay: (index * 50).ms).fadeIn().slideX(begin: 0.1);
              },
            ),
          ),

          // Bottom padding
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: AppPallete.textSecondary, fontSize: 11),
        ),
      ],
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final int index;
  final Map<String, dynamic> question;
  final bool isExpanded;
  final VoidCallback onExpandTap;

  const _QuestionCard({
    required this.index,
    required this.question,
    required this.isExpanded,
    required this.onExpandTap,
  });

  @override
  Widget build(BuildContext context) {
    final options = question['options'] as List<dynamic>? ?? [];
    final correctAnswer = question['correctAnswer'] as int? ?? 0;
    final selectedAnswer = question['selectedAnswer'] as int? ?? -1;
    final isCorrect = selectedAnswer != -1 && correctAnswer == selectedAnswer;
    final isUnattempted = selectedAnswer == -1;
    final explanation = question['explanation'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppPallete.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUnattempted
              ? AppPallete.textSecondary.withValues(alpha: 0.2)
              : isCorrect
              ? AppPallete.success.withValues(alpha: 0.3)
              : AppPallete.error.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // Question header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isUnattempted
                        ? AppPallete.textSecondary.withValues(alpha: 0.1)
                        : isCorrect
                        ? AppPallete.success.withValues(alpha: 0.15)
                        : AppPallete.error.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: isUnattempted
                            ? AppPallete.textSecondary
                            : isCorrect
                            ? AppPallete.success
                            : AppPallete.error,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    question['question'] ?? '',
                    style: const TextStyle(
                      color: AppPallete.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
                Icon(
                  isUnattempted
                      ? Icons.help_outline_rounded
                      : isCorrect
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  color: isUnattempted
                      ? AppPallete.textSecondary
                      : isCorrect
                      ? AppPallete.success
                      : AppPallete.error,
                  size: 24,
                ),
              ],
            ),
          ),

          // Options
          ...options.asMap().entries.map((entry) {
            final optIndex = entry.key;
            final option = entry.value as String;
            final isThisCorrect = optIndex == correctAnswer;
            final isThisSelected = optIndex == selectedAnswer;

            Color bgColor;
            Color borderColor;
            Color textColor;

            if (isThisCorrect) {
              bgColor = AppPallete.success.withValues(alpha: 0.15);
              borderColor = AppPallete.success;
              textColor = AppPallete.success;
            } else if (isThisSelected && !isThisCorrect) {
              bgColor = AppPallete.error.withValues(alpha: 0.15);
              borderColor = AppPallete.error;
              textColor = AppPallete.error;
            } else {
              bgColor = Colors.transparent;
              borderColor = Colors.transparent;
              textColor = AppPallete.textSecondary;
            }

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor, width: 1.5),
              ),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isThisCorrect
                          ? AppPallete.success
                          : isThisSelected
                          ? AppPallete.error
                          : AppPallete.surface,
                    ),
                    child: Center(
                      child: Text(
                        String.fromCharCode(65 + optIndex), // A, B, C, D
                        style: TextStyle(
                          color: isThisCorrect || isThisSelected
                              ? Colors.white
                              : AppPallete.textSecondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      option,
                      style: TextStyle(
                        color: isThisCorrect || isThisSelected
                            ? textColor
                            : AppPallete.textPrimary,
                        fontSize: 13,
                        fontWeight: isThisCorrect
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (isThisCorrect)
                    const Icon(
                      Icons.check_rounded,
                      color: AppPallete.success,
                      size: 18,
                    ),
                  if (isThisSelected && !isThisCorrect)
                    const Icon(
                      Icons.close_rounded,
                      color: AppPallete.error,
                      size: 18,
                    ),
                ],
              ),
            );
          }),

          // Explanation button
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                GestureDetector(
                  onTap: onExpandTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: AppPallete.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isExpanded
                              ? Icons.visibility_off_rounded
                              : Icons.lightbulb_rounded,
                          color: AppPallete.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isExpanded ? 'Hide Explanation' : 'Show Explanation',
                          style: const TextStyle(
                            color: AppPallete.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Expanded explanation
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppPallete.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppPallete.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.lightbulb_rounded,
                          color: AppPallete.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            explanation,
                            style: const TextStyle(
                              color: AppPallete.textPrimary,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  crossFadeState: isExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 200),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
