import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for fetching and managing dashboard data from Supabase
class DashboardService {
  final SupabaseClient _client = Supabase.instance.client;

  // SharedPreferences keys for session tracking
  static const String _sessionStartKey = 'study_session_start_time';
  static const String _sessionIdKey = 'study_session_id';

  /// Get the current user's ID
  String? get _userId => _client.auth.currentUser?.id;

  // ==================== USER PROGRESS ====================

  /// Fetch user's progress (streak, study hours, tests completed, marks, percentage)
  Future<Map<String, dynamic>?> fetchUserProgress() async {
    if (_userId == null) return null;

    try {
      // First, recover any unclosed sessions from previous app runs
      await _recoverUnfinishedSession();

      // Sync tests completed from test_results
      final testStats = await _client
          .from('user_test_summary')
          .select()
          .eq('user_id', _userId!)
          .maybeSingle();

      if (testStats != null) {
        await _client
            .from('user_progress')
            .update({'tests_completed': testStats['completed_count']})
            .eq('user_id', _userId!);
      }

      final response = await _client
          .from('user_progress')
          .select('*, profiles(full_name, student_id, role)')
          .eq('user_id', _userId!)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Error fetching user progress: $e');
      return null;
    }
  }

  /// Fetch summary for the student dashboard using the optimized view
  Future<Map<String, dynamic>> fetchTestSummary() async {
    if (_userId == null) return {'active': 0, 'completed': 0, 'missed': 0};

    try {
      final now = DateTime.now();
      debugPrint(
        'DashboardService: Fetching summary using view for user $_userId',
      );

      // Query the optimized view
      final response = await _client
          .from('student_test_dashboard')
          .select('*')
          .eq('user_id', _userId!);

      debugPrint(
        'DashboardService: VIEW response length: ${(response as List).length} for user $_userId',
      );

      final directAssignments = await _client
          .from('test_assignments')
          .select('id, test_id')
          .eq('user_id', _userId!);
      debugPrint(
        'DashboardService: DIRECT assignments count: ${(directAssignments as List).length}',
      );

      final allTests = await _client.from('tests').select('id, title');
      debugPrint(
        'DashboardService: TOTAL tests in DB: ${(allTests as List).length}',
      );

      final tests = response as List;
      int active = 0;
      int completed = 0;
      int missed = 0;

      for (final test in tests) {
        // If result_id exists or status is explicitly completed
        if (test['result_id'] != null ||
            test['assignment_status'] == 'completed') {
          completed++;
          continue;
        }

        final endDateStr = test['end_date'];
        final startDateStr = test['start_date'];
        final endDate = endDateStr != null
            ? DateTime.tryParse(endDateStr.toString())
            : null;
        final startDate = startDateStr != null
            ? DateTime.tryParse(startDateStr.toString())
            : null;

        if (endDate != null && endDate.isBefore(now)) {
          missed++;
        } else if (startDate != null && startDate.isBefore(now)) {
          // Only active if START date is in the past (has started)
          active++;
        }
        // Scheduled tests (startDate > now) are not counted yet
      }

      debugPrint(
        'DashboardService: VIEW Summary - Active: $active, Done: $completed, Missed: $missed',
      );
      return {'active': active, 'completed': completed, 'missed': missed};
    } catch (e) {
      debugPrint('Error calculating view-based test summary: $e');
      return {'active': 0, 'completed': 0, 'missed': 0};
    }
  }

  /// Fetch tests by status
  /// Fetch tests by status using the optimized view
  Future<List<Map<String, dynamic>>> fetchTestsByStatus(String status) async {
    if (_userId == null) return [];

    try {
      final now = DateTime.now();
      debugPrint(
        'DashboardService: Fetching tests ($status) using view for user $_userId',
      );

      final response = await _client
          .from('student_test_dashboard')
          .select('*')
          .eq('user_id', _userId!);

      final tests = response as List;
      final List<Map<String, dynamic>> results = [];

      for (final test in tests) {
        final isCompletedResult =
            test['result_id'] != null ||
            test['assignment_status'] == 'completed';

        // Handle completed status
        if (status == 'completed') {
          if (isCompletedResult) {
            results.add({
              'id': test['result_id'] ?? test['test_id'],
              'test_id': test['test_id'],
              'title': test['title'],
              'subject': test['subject'],
              'description': test['description'],
              'score': test['score'],
              'total_questions':
                  test['result_total_questions'] ??
                  test['test_total_questions'],
              'percentage': test['percentage'],
              'completed_at': test['completed_at'],
              'wrong_count': test['wrong_count'],
              'answers': test['answers'],
            });
          }
          continue;
        }

        // For non-completed, skip if already done
        if (isCompletedResult) continue;

        final endDateStr = test['end_date'];
        final startDateStr = test['start_date'];
        final endDate = endDateStr != null
            ? DateTime.tryParse(endDateStr.toString())
            : null;
        final startDate = startDateStr != null
            ? DateTime.tryParse(startDateStr.toString())
            : null;

        if (status == 'active') {
          final isStarted = startDate != null && startDate.isBefore(now);
          final isNotEnded = endDate == null || endDate.isAfter(now);
          if (isStarted && isNotEnded) {
            results.add({
              'id': test['test_id'],
              'assignment_id': test['assignment_id'],
              'title': test['title'],
              'subject': test['subject'],
              'description': test['description'],
              'start_date': startDateStr,
              'end_date': endDateStr,
              'duration_minutes': test['duration_minutes'],
              'total_questions': test['test_total_questions'],
            });
          }
        } else if (status == 'missed') {
          final isMissed = endDate != null && endDate.isBefore(now);
          if (isMissed) {
            results.add({
              'id': test['test_id'],
              'assignment_id': test['assignment_id'],
              'title': test['title'],
              'subject': test['subject'],
              'description': test['description'],
              'start_date': startDateStr,
              'end_date': endDateStr,
              'duration_minutes': test['duration_minutes'],
              'total_questions': test['test_total_questions'],
            });
          }
        }
      }

      return results;
    } catch (e) {
      debugPrint('Error fetching view-based tests by status: $e');
    }
    return [];
  }

  /// Update streak on daily login using RPC for atomic accuracy
  Future<void> updateDailyStreak() async {
    if (_userId == null) return;

    try {
      await _client.rpc('update_user_streak', params: {'p_user_id': _userId});
    } catch (e) {
      debugPrint('Error updating daily streak: $e');
    }
  }

  // ==================== ANALYTICS TRACKING ====================

  // Flag to prevent multiple recovery attempts in same session
  static bool _hasRecoveredSession = false;

  /// Recover any unclosed session from previous app run
  Future<void> _recoverUnfinishedSession() async {
    // Only recover once per app session
    if (_hasRecoveredSession) return;
    _hasRecoveredSession = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedStartTime = prefs.getString(_sessionStartKey);
      final savedSessionId = prefs.getString(_sessionIdKey);

      // Always clear saved session data FIRST to prevent infinite loops
      await prefs.remove(_sessionStartKey);
      await prefs.remove(_sessionIdKey);

      if (savedStartTime != null) {
        final startTime = DateTime.parse(savedStartTime);
        final endTime = DateTime.now();
        final duration = endTime.difference(startTime).inSeconds;

        // Only count sessions less than 24 hours (avoid stale data)
        if (duration > 0 && duration < 86400) {
          debugPrint('Recovering session: ${duration / 60} minutes');

          // Update the database session if we have the ID
          if (savedSessionId != null) {
            try {
              await _client
                  .from('study_sessions')
                  .update({
                    'end_time': endTime.toIso8601String(),
                    'duration_seconds': duration,
                  })
                  .eq('id', savedSessionId);
            } catch (e) {
              debugPrint('Error updating session in DB: $e');
            }
          }

          // Add to study hours (wrapped in try-catch)
          try {
            await addStudyHours(duration / 3600);
          } catch (e) {
            debugPrint('Error adding study hours: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Error recovering session: $e');
    }
  }

  /// Start a study session (saved locally for recovery)
  Future<String?> startStudySession() async {
    if (_userId == null) return null;
    try {
      final now = DateTime.now();

      // Save session start time to SharedPreferences for recovery
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sessionStartKey, now.toIso8601String());

      // Also insert into database for complete records
      final response = await _client
          .from('study_sessions')
          .insert({'user_id': _userId, 'start_time': now.toIso8601String()})
          .select()
          .single();

      // Save session ID for recovery
      await prefs.setString(_sessionIdKey, response['id']);

      debugPrint('Study session started: ${response['id']}');
      return response['id'];
    } catch (e) {
      debugPrint('Error starting study session: $e');
      return null;
    }
  }

  /// End a study session
  Future<void> endStudySession(String sessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedStartTime = prefs.getString(_sessionStartKey);

      if (savedStartTime == null) {
        debugPrint('No saved session start time found');
        return;
      }

      final startTime = DateTime.parse(savedStartTime);
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime).inSeconds;

      // Update database
      await _client
          .from('study_sessions')
          .update({
            'end_time': endTime.toIso8601String(),
            'duration_seconds': duration,
          })
          .eq('id', sessionId);

      // Add to total study hours
      await addStudyHours(duration / 3600);

      // Clear saved session data
      await prefs.remove(_sessionStartKey);
      await prefs.remove(_sessionIdKey);

      debugPrint('Study session ended: ${duration / 60} minutes');
    } catch (e) {
      debugPrint('Error ending study session: $e');
    }
  }

  /// Track mentor interaction
  Future<void> trackMentorInteraction(
    String mentorId,
    Duration duration,
  ) async {
    if (_userId == null) return;
    try {
      await _client.from('mentor_interactions').insert({
        'user_id': _userId,
        'mentor_id': mentorId,
        'start_time': DateTime.now().subtract(duration).toIso8601String(),
        'end_time': DateTime.now().toIso8601String(),
        'duration_seconds': duration.inSeconds,
      });
    } catch (e) {
      debugPrint('Error tracking mentor interaction: $e');
    }
  }

  /// Fetch last 7 days study hours for graph
  Future<List<Map<String, dynamic>>> fetchLast7DaysStudy() async {
    if (_userId == null) return [];
    try {
      final response = await _client
          .from('last_7_days_study')
          .select()
          .eq('user_id', _userId!)
          .order('session_date', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching 7 days study: $e');
      return [];
    }
  }

  /// Fetch login dates for a specific month (from study_sessions)
  Future<List<Map<String, dynamic>>> fetchLoginDatesForMonth(
    int year,
    int month,
  ) async {
    if (_userId == null) return [];
    try {
      final startOfMonth = DateTime(year, month, 1);
      final endOfMonth = DateTime(year, month + 1, 0, 23, 59, 59);

      final response = await _client
          .from('study_sessions')
          .select('start_time')
          .eq('user_id', _userId!)
          .gte('start_time', startOfMonth.toIso8601String())
          .lte('start_time', endOfMonth.toIso8601String());

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching login dates: $e');
      return [];
    }
  }

  /// Fetch test performance for graph
  Future<List<Map<String, dynamic>>> fetchTestPerformance() async {
    if (_userId == null) return [];
    try {
      final response = await _client
          .from('test_results')
          .select('completed_at, percentage, tests(title)')
          .eq('user_id', _userId!)
          .order('completed_at', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching test performance: $e');
      return [];
    }
  }

  /// Fetch mentor weekly stats for graph and detailed logs
  Future<List<Map<String, dynamic>>> fetchMentorWeeklyStats() async {
    if (_userId == null) return [];
    try {
      final stats = await _client
          .from('mentor_weekly_stats')
          .select('total_hours, total_seconds, mentor_id, profiles(full_name)')
          .eq('user_id', _userId!);

      final interactions = await _client
          .from('mentor_interactions')
          .select()
          .eq('user_id', _userId!)
          .gte(
            'start_time',
            DateTime.now().subtract(const Duration(days: 7)).toIso8601String(),
          )
          .order('created_at', ascending: false);

      return (stats as List).map((stat) {
        final mentorId = stat['mentor_id'];
        final sessions = (interactions as List)
            .where((i) => i['mentor_id'] == mentorId)
            .toList();
        return {...stat as Map<String, dynamic>, 'sessions': sessions};
      }).toList();
    } catch (e) {
      debugPrint('Error fetching mentor stats: $e');
      return [];
    }
  }

  /// Add study hours
  Future<void> addStudyHours(double hours) async {
    if (_userId == null) return;
    if (hours <= 0) {
      debugPrint('Warning: Attempted to add non-positive study hours: $hours');
      return;
    }

    try {
      final existing = await fetchUserProgress();
      final currentHours =
          (existing?['study_hours'] as num?)?.toDouble() ?? 0.0;

      await _client.from('user_progress').upsert({
        'user_id': _userId,
        'study_hours': currentHours + hours,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error adding study hours: $e');
    }
  }

  /// Increment tests completed
  Future<void> incrementTestsCompleted() async {
    if (_userId == null) return;

    try {
      final existing = await fetchUserProgress();
      final currentTests = (existing?['tests_completed'] as int?) ?? 0;

      await _client.from('user_progress').upsert({
        'user_id': _userId,
        'tests_completed': currentTests + 1,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error incrementing tests: $e');
    }
  }

  // ==================== PROJECTS ====================

  /// Fetch user's projects
  Future<List<Map<String, dynamic>>> fetchProjects() async {
    if (_userId == null) return [];

    try {
      final response = await _client
          .from('user_projects')
          .select()
          .eq('user_id', _userId!)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching projects: $e');
      return [];
    }
  }

  /// Create a new project
  Future<void> createProject({
    required String title,
    String? description,
    String color = '#2979FF',
    DateTime? deadline,
  }) async {
    if (_userId == null) return;

    try {
      await _client.from('user_projects').insert({
        'user_id': _userId,
        'title': title,
        'description': description,
        'color': color,
        'deadline': deadline?.toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error creating project: $e');
    }
  }

  // ==================== SCHEDULE ====================

  /// Fetch today's schedule
  Future<List<Map<String, dynamic>>> fetchTodaySchedule() async {
    if (_userId == null) return [];

    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final response = await _client
          .from('user_schedule')
          .select()
          .eq('user_id', _userId!)
          .gte('start_time', startOfDay.toIso8601String())
          .lt('start_time', endOfDay.toIso8601String())
          .order('start_time', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching schedule: $e');
      return [];
    }
  }

  /// Add a schedule event
  Future<void> addScheduleEvent({
    required String title,
    String? description,
    required DateTime startTime,
    required DateTime endTime,
    String color = '#2979FF',
  }) async {
    if (_userId == null) return;

    try {
      await _client.from('user_schedule').insert({
        'user_id': _userId,
        'title': title,
        'description': description,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
        'color': color,
      });
    } catch (e) {
      debugPrint('Error adding schedule event: $e');
    }
  }

  // ==================== TASKS ====================

  /// Fetch tasks for a project
  Future<List<Map<String, dynamic>>> fetchTasks(String projectId) async {
    if (_userId == null) return [];

    try {
      final response = await _client
          .from('user_tasks')
          .select()
          .eq('project_id', projectId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching tasks: $e');
      return [];
    }
  }

  /// Create a task
  Future<void> createTask({
    required String projectId,
    required String title,
    String? description,
    DateTime? dueDate,
    String priority = 'medium',
  }) async {
    if (_userId == null) return;

    try {
      await _client.from('user_tasks').insert({
        'user_id': _userId,
        'project_id': projectId,
        'title': title,
        'description': description,
        'due_date': dueDate?.toIso8601String(),
        'priority': priority,
      });

      // Update project task count
      final project = await _client
          .from('user_projects')
          .select('total_tasks')
          .eq('id', projectId)
          .single();

      await _client
          .from('user_projects')
          .update({'total_tasks': (project['total_tasks'] as int) + 1})
          .eq('id', projectId);
    } catch (e) {
      debugPrint('Error creating task: $e');
    }
  }

  /// Toggle task completion
  Future<void> toggleTaskCompletion(String taskId, bool isCompleted) async {
    try {
      await _client
          .from('user_tasks')
          .update({'is_completed': isCompleted})
          .eq('id', taskId);
    } catch (e) {
      debugPrint('Error toggling task: $e');
    }
  }
}
