import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_pallete.dart';

class TestArenaPage extends StatefulWidget {
  const TestArenaPage({super.key});

  @override
  State<TestArenaPage> createState() => _TestArenaPageState();
}

class _TestArenaPageState extends State<TestArenaPage> {
  // Config
  static const int totalQuestions = 30;
  int currentQuestionIndex = 0;
  int? selectedOption;

  // Timer
  Timer? _timer;
  int _secondsRemaining = 45 * 60; // 45 Minutes

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer?.cancel();
        // Auto-submit
      }
    });
  }

  String get timerText {
    final minutes = (_secondsRemaining / 60).floor().toString().padLeft(2, '0');
    final seconds = (_secondsRemaining % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Mock Question
    final question =
        "What is the primary function of the mitochondria in a cell?";
    final options = [
      "Protein Synthesis",
      "Powerhouse (ATP Production)",
      "DNA Replication",
      "Cell Division",
    ];

    final progress = (currentQuestionIndex + 1) / totalQuestions;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header (Timer & Progress)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Physics Final",
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      Text(
                        "Q${currentQuestionIndex + 1} / $totalQuestions",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
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
                      color: _secondsRemaining < 300
                          ? Colors.red.withValues(alpha: 0.1)
                          : AppPallete.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.timer,
                          size: 16,
                          color: _secondsRemaining < 300
                              ? Colors.red
                              : AppPallete.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          timerText,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _secondsRemaining < 300
                                ? Colors.red
                                : AppPallete.primary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Progress Bar
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[100],
              color: AppPallete.success,
              minHeight: 4,
            ),

            // Question Area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      question,
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: AppPallete.textPrimary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Options
                    ...List.generate(options.length, (index) {
                      final isSelected = selectedOption == index;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedOption = index;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppPallete.secondary.withValues(alpha: 0.1)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? AppPallete.secondary
                                  : Colors.grey[300]!,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? AppPallete.secondary
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected
                                        ? AppPallete.secondary
                                        : Colors.grey[400]!,
                                    width: 2,
                                  ),
                                ),
                                child: isSelected
                                    ? const Icon(
                                        Icons.check,
                                        size: 16,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  options[index],
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? AppPallete.primary
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // Bottom Action Bar
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Flag Button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.flag_outlined,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Next Button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: selectedOption != null
                          ? () {
                              // Next Question Logic
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppPallete.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        "Next Question",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
