import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TestService {
  final SupabaseClient _supabase = Supabase.instance.client;

  String? get currentUserId => _supabase.auth.currentUser?.id;

  // Get overall score for current user
  Future<Map<String, dynamic>> getOverallScore() async {
    try {
      final response = await _supabase
          .from('test_results')
          .select('score, total_questions')
          .eq('user_id', currentUserId ?? '');

      if (response.isEmpty) {
        return {
          'totalScore': 0,
          'totalQuestions': 0,
          'percentage': 0.0,
          'testsCompleted': 0,
        };
      }

      int totalScore = 0;
      int totalQuestions = 0;

      for (var result in response) {
        totalScore += (result['score'] as int?) ?? 0;
        totalQuestions += (result['total_questions'] as int?) ?? 0;
      }

      final percentage = totalQuestions > 0
          ? (totalScore / totalQuestions) * 100
          : 0.0;

      return {
        'totalScore': totalScore,
        'totalQuestions': totalQuestions,
        'percentage': percentage,
        'testsCompleted': response.length,
      };
    } catch (e) {
      debugPrint('Error getting overall score: $e');
      return {
        'totalScore': 0,
        'totalQuestions': 0,
        'percentage': 0.0,
        'testsCompleted': 0,
      };
    }
  }

  // Get active tests assigned to user (excludes completed tests)
  Future<List<Map<String, dynamic>>> getActiveTests() async {
    try {
      final response = await _supabase
          .from('active_tests_for_user')
          .select()
          .eq('user_id', currentUserId ?? '')
          .eq('is_completed', false)
          .order('start_date', ascending: true);

      debugPrint(
        'TestService: Active Tests Found: ${(response as List).length} for user $currentUserId',
      );
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting active tests: $e');
      // Return sample test for demo
      return _getSampleTests();
    }
  }

  // Get completed tests for user
  Future<List<Map<String, dynamic>>> getCompletedTests() async {
    try {
      final response = await _supabase
          .from('test_results')
          .select('*, tests(*)')
          .eq('user_id', currentUserId ?? '')
          .order('completed_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting completed tests: $e');
      return [];
    }
  }

  // Mark expired tests (end_date < now, not completed) as 'missed'
  Future<void> markExpiredTestsAsMissed() async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      await _supabase
          .from('test_assignments')
          .update({'status': 'missed'})
          .eq('user_id', currentUserId ?? '')
          .neq('status', 'completed')
          .neq('status', 'missed')
          .lt('tests.end_date', now);
    } catch (e) {
      // Fallback: fetch assignments and filter locally
      try {
        final assignments = await _supabase
            .from('test_assignments')
            .select('id, status, tests(end_date)')
            .eq('user_id', currentUserId ?? '');

        final now = DateTime.now();
        final expiredIds = <String>[];
        for (final a in assignments) {
          final status = a['status'] as String?;
          if (status == 'completed' || status == 'missed') continue;
          final endStr = (a['tests'] as Map?)?['end_date'] as String?;
          if (endStr == null) continue;
          final endDate = DateTime.tryParse(endStr)?.toLocal();
          if (endDate != null && now.isAfter(endDate)) {
            expiredIds.add(a['id'] as String);
          }
        }
        if (expiredIds.isNotEmpty) {
          await _supabase
              .from('test_assignments')
              .update({'status': 'missed'})
              .inFilter('id', expiredIds);
        }
      } catch (e2) {
        debugPrint('Error marking missed tests: $e2');
      }
    }
  }

  // Get missed tests for user
  Future<List<Map<String, dynamic>>> getMissedTests() async {
    try {
      final response = await _supabase
          .from('test_assignments')
          .select('*, tests(*)')
          .eq('user_id', currentUserId ?? '')
          .eq('status', 'missed');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting missed tests: $e');
      return [];
    }
  }

  // Get test questions
  Future<List<Map<String, dynamic>>> getTestQuestions(String testId) async {
    try {
      final response = await _supabase
          .from('test_questions')
          .select()
          .eq('test_id', testId)
          .order('order_index', ascending: true);

      final questions = List<Map<String, dynamic>>.from(response);
      return questions.map((q) {
        final Map<String, dynamic> mapped = Map.from(q);
        if (mapped['correct_answers'] != null) {
          final ca = mapped['correct_answers'];
          if (ca is List && ca.isNotEmpty) {
            mapped['correct_answer'] = ca.first as int;
          } else if (ca is int) {
            mapped['correct_answer'] = ca;
          }
        }
        return mapped;
      }).toList();
    } catch (e) {
      debugPrint('Error getting questions: $e');
      return _getSampleQuestions();
    }
  }

  // Submit test test results and update assignment status + cumulative progress
  Future<bool> submitTestResult({
    required String testId,
    required int score,
    required int totalQuestions,
    required Map<String, dynamic> answers,
    String? assignmentId, // New: for precise update
  }) async {
    try {
      final percentage = (score / totalQuestions) * 100;
      final wrongCount = totalQuestions - score;

      // 1. Insert result
      debugPrint('TestService: Inserting result for test $testId');
      await _supabase.from('test_results').insert({
        'user_id': currentUserId,
        'test_id': testId,
        'score': score,
        'wrong_count': wrongCount,
        'total_questions': totalQuestions,
        'percentage': percentage,
        'answers': answers,
        'completed_at': DateTime.now().toIso8601String(),
      });

      // 2. Update assignment status
      debugPrint(
        'TestService: Updating assignment status for test $testId (Assignment: $assignmentId)',
      );

      var query = _supabase.from('test_assignments').update({
        'status': 'completed',
      });

      if (assignmentId != null && assignmentId.isNotEmpty) {
        query = query.eq('id', assignmentId);
      } else {
        query = query.eq('test_id', testId).eq('user_id', currentUserId ?? '');
      }

      final updateResponse = await query.select();

      debugPrint('TestService: Update response: $updateResponse');
      if (updateResponse.isEmpty) {
        debugPrint(
          'Warning: No assignment found to update for test $testId and user $currentUserId',
        );
      }

      // 3. Update cumulative progress
      final progressRes = await _supabase
          .from('user_progress')
          .select('total_marks, tests_completed')
          .eq('user_id', currentUserId ?? '')
          .maybeSingle();

      // Fetch all results to calculate avg percentage
      final allResults = await _supabase
          .from('test_results')
          .select('percentage')
          .eq('user_id', currentUserId ?? '');

      double totalPercent = 0;
      for (var r in allResults) {
        totalPercent += (r['percentage'] as num?)?.toDouble() ?? 0;
      }
      final avgPercent = allResults.isNotEmpty
          ? totalPercent / allResults.length
          : percentage;

      if (progressRes != null) {
        final currentTotalMarks = (progressRes['total_marks'] as int?) ?? 0;
        final currentTestsCount = (progressRes['tests_completed'] as int?) ?? 0;
        final newTestsCount = currentTestsCount + 1;
        final newTotalMarks = currentTotalMarks + score;

        await _supabase
            .from('user_progress')
            .update({
              'total_marks': newTotalMarks,
              'tests_completed': newTestsCount,
              'avg_percentage': avgPercent,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', currentUserId ?? '');
      } else {
        // First test! Insert new record
        await _supabase.from('user_progress').insert({
          'user_id': currentUserId,
          'total_marks': score,
          'tests_completed': 1,
          'avg_percentage': percentage,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }

      return true;
    } catch (e) {
      debugPrint('Error submitting result: $e');
      return false;
    }
  }

  // Check if user already completed a test
  Future<bool> hasCompletedTest(String testId) async {
    try {
      final response = await _supabase
          .from('test_results')
          .select('id')
          .eq('user_id', currentUserId ?? '')
          .eq('test_id', testId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  // Sample tests for demo
  List<Map<String, dynamic>> _getSampleTests() {
    final now = DateTime.now();
    return [
      {
        'id': 'sample_test_1',
        'title': 'Mathematics - Algebra Basics',
        'subject': 'Mathematics',
        'description':
            'Test your knowledge of algebraic expressions and equations',
        'total_questions': 15,
        'duration_minutes': 30,
        'start_time': now.subtract(const Duration(hours: 1)).toIso8601String(),
        'end_time': now.add(const Duration(days: 2)).toIso8601String(),
        'created_at': now.toIso8601String(),
      },
    ];
  }

  // Sample 15 questions for demo
  List<Map<String, dynamic>> _getSampleQuestions() {
    return [
      {
        'id': 'q1',
        'question': 'What is the value of x in the equation 2x + 5 = 15?',
        'options': ['x = 5', 'x = 10', 'x = 7', 'x = 3'],
        'correct_answer': 0,
        'explanation':
            'Subtract 5 from both sides: 2x = 10, then divide by 2: x = 5',
      },
      {
        'id': 'q2',
        'question': 'Simplify: 3(2x + 4) - 2x',
        'options': ['4x + 12', '6x + 12', '4x + 4', '8x + 12'],
        'correct_answer': 0,
        'explanation': '3(2x + 4) - 2x = 6x + 12 - 2x = 4x + 12',
      },
      {
        'id': 'q3',
        'question': 'If a = 3 and b = 4, what is a² + b²?',
        'options': ['7', '12', '25', '49'],
        'correct_answer': 2,
        'explanation': 'a² + b² = 3² + 4² = 9 + 16 = 25',
      },
      {
        'id': 'q4',
        'question': 'Solve for y: 3y - 7 = 14',
        'options': ['y = 7', 'y = 21', 'y = 3', 'y = 11'],
        'correct_answer': 0,
        'explanation': 'Add 7 to both sides: 3y = 21, divide by 3: y = 7',
      },
      {
        'id': 'q5',
        'question': 'What is the slope of the line y = 3x + 5?',
        'options': ['5', '3', '8', '-3'],
        'correct_answer': 1,
        'explanation': 'In y = mx + b form, the slope m = 3',
      },
      {
        'id': 'q6',
        'question': 'Factor: x² - 9',
        'options': ['(x-3)(x+3)', '(x-9)(x+1)', '(x-3)²', '(x+3)²'],
        'correct_answer': 0,
        'explanation': 'This is a difference of squares: x² - 9 = (x-3)(x+3)',
      },
      {
        'id': 'q7',
        'question': 'What is √144?',
        'options': ['14', '12', '11', '13'],
        'correct_answer': 1,
        'explanation': '12 × 12 = 144, so √144 = 12',
      },
      {
        'id': 'q8',
        'question': 'Simplify: (2³)²',
        'options': ['32', '64', '16', '128'],
        'correct_answer': 1,
        'explanation': '(2³)² = 2^(3×2) = 2^6 = 64',
      },
      {
        'id': 'q9',
        'question': 'If f(x) = 2x + 1, what is f(3)?',
        'options': ['5', '6', '7', '8'],
        'correct_answer': 2,
        'explanation': 'f(3) = 2(3) + 1 = 6 + 1 = 7',
      },
      {
        'id': 'q10',
        'question': 'Solve: |x - 2| = 5',
        'options': [
          'x = 7 only',
          'x = -3 only',
          'x = 7 or x = -3',
          'x = 3 or x = 7',
        ],
        'correct_answer': 2,
        'explanation': 'x - 2 = 5 → x = 7, or x - 2 = -5 → x = -3',
      },
      {
        'id': 'q11',
        'question':
            'What is the area of a rectangle with length 8 and width 5?',
        'options': ['13', '26', '40', '45'],
        'correct_answer': 2,
        'explanation': 'Area = length × width = 8 × 5 = 40',
      },
      {
        'id': 'q12',
        'question': 'Simplify: 5x + 3y - 2x + y',
        'options': ['3x + 4y', '7x + 4y', '3x + 2y', '7x + 2y'],
        'correct_answer': 0,
        'explanation': 'Combine like terms: (5x - 2x) + (3y + y) = 3x + 4y',
      },
      {
        'id': 'q13',
        'question': 'What is 15% of 200?',
        'options': ['15', '30', '45', '25'],
        'correct_answer': 1,
        'explanation': '15% of 200 = 0.15 × 200 = 30',
      },
      {
        'id': 'q14',
        'question': 'Solve: x/4 = 12',
        'options': ['x = 3', 'x = 16', 'x = 48', 'x = 8'],
        'correct_answer': 2,
        'explanation': 'Multiply both sides by 4: x = 12 × 4 = 48',
      },
      {
        'id': 'q15',
        'question': 'What is the next term in the sequence: 2, 6, 18, 54, ...?',
        'options': ['108', '162', '72', '180'],
        'correct_answer': 1,
        'explanation': 'Each term is multiplied by 3: 54 × 3 = 162',
      },
    ];
  }
}
