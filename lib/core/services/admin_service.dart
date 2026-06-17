import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ============================================
  // STATS
  // ============================================
  Future<Map<String, int>> getDashboardStats() async {
    try {
      final usersCount = await _supabase
          .from('profiles')
          .select('id')
          .eq('role', 'user');
      final adminsCount = await _supabase
          .from('profiles')
          .select('id')
          .eq('role', 'admin');
      final testsCount = await _supabase.from('tests').select('id');
      final mentorsCount = await _supabase
          .from('mentor_creations')
          .select('id');

      return {
        'users': (usersCount as List).length,
        'admins': (adminsCount as List).length,
        'tests': (testsCount as List).length,
        'mentors': (mentorsCount as List).length,
      };
    } catch (e) {
      return {'users': 0, 'admins': 0, 'tests': 0, 'mentors': 0};
    }
  }

  Future<List<Map<String, dynamic>>> getMentorsCreated() async {
    try {
      debugPrint('AdminService: Fetching mentors created...');
      final response = await _supabase
          .from('mentor_creations')
          .select('*, profiles!user_id(full_name)')
          .order('created_at', ascending: false);

      debugPrint('AdminService: Mentors created response: $response');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('AdminService: Error fetching mentors created: $e');
      // Try a simpler query without the join to see if table exists
      try {
        final simpleResponse = await _supabase
            .from('mentor_creations')
            .select('*')
            .order('created_at', ascending: false);
        debugPrint('AdminService: Simple mentors query: $simpleResponse');
        return List<Map<String, dynamic>>.from(simpleResponse);
      } catch (e2) {
        debugPrint('AdminService: Simple query also failed: $e2');
        return [];
      }
    }
  }

  // ============================================
  // USERS
  // ============================================
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final response = await _supabase
          .from('profiles')
          .select(
            '*, user_progress(streak_count, study_hours, tests_completed, total_marks, avg_percentage)',
          )
          .eq('role', 'user')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('AdminService: Error fetching all users: $e');
      return [];
    }
  }

  /// Get all users who can be assigned a test (including admins/super_admins)
  Future<List<Map<String, dynamic>>> getAssignableUsers() async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('id, full_name, email, role')
          .eq('role', 'user')
          .order('full_name', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('AdminService: Error fetching assignable users: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAllAdmins() async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('role', 'admin')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getUserDetails(String userId) async {
    try {
      // Get profile with student_id
      final profile = await _supabase
          .from('profiles')
          .select('*, user_progress(*)')
          .eq('id', userId)
          .maybeSingle();

      if (profile == null) return null;

      // Get test results
      final testResults = await _supabase
          .from('test_results')
          .select('*, tests(title)')
          .eq('user_id', userId)
          .order('completed_at', ascending: false);

      // Get mentor interactions
      final mentors = await _supabase
          .from('mentor_interactions')
          .select('mentor_id, mentor_type, duration_seconds, start_time')
          .eq('user_id', userId)
          .order('start_time', ascending: false);

      return {
        ...profile,
        'test_results': testResults,
        'mentor_interactions': mentors,
        // Map user_progress for easier UI use if needed
        'progress': profile['user_progress'] ?? {},
      };
    } catch (e) {
      debugPrint('AdminService: Error getting user details: $e');
      return null;
    }
  }

  // ============================================
  // MESSAGING
  // ============================================
  Future<bool> sendMessage(String recipientId, String message) async {
    try {
      final senderId = _supabase.auth.currentUser?.id;
      if (senderId == null) return false;

      await _supabase.from('admin_messages').insert({
        'user_id': recipientId, // Target user receiving the message
        'content': message,
        'is_from_admin': true,
        'is_read': false,
      });

      // Also create a notification so the user gets a badge and alert
      await _supabase.from('notifications').insert({
        'user_id': recipientId,
        'sender_id': senderId,
        'type': 'admin_message',
        'title': 'Message from SuperAdmin',
        'message': message.length > 50
            ? '${message.substring(0, 47)}...'
            : message,
        'is_read': false,
      });

      return true;
    } catch (e) {
      debugPrint('AdminService: Error sending message: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getMyMessages() async {
    try {
      final response = await _supabase
          .from('admin_messages')
          .select('*, sender:profiles!user_id(full_name)')
          .eq('is_from_admin', false)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('AdminService: Error fetching student messages: $e');
      return [];
    }
  }

  // ============================================
  // ADMIN CREATION
  // ============================================
  Future<bool> createAdmin({
    required String email,
    required String password,
    required String fullName,
    required String gender,
  }) async {
    try {
      // Create user in Supabase Auth
      final response = await _supabase.auth.admin.createUser(
        AdminUserAttributes(
          email: email,
          password: password,
          emailConfirm: true,
          userMetadata: {
            'full_name': fullName,
            'gender': gender,
            'role': 'admin',
          },
        ),
      );

      if (response.user != null) {
        // Update profile role to admin
        await _supabase
            .from('profiles')
            .update({'role': 'admin', 'full_name': fullName, 'gender': gender})
            .eq('id', response.user!.id);

        return true;
      }
      return false;
    } catch (e) {
      // If admin API not available, try regular signup
      try {
        await _supabase.auth.signUp(
          email: email,
          password: password,
          data: {'full_name': fullName, 'gender': gender, 'role': 'admin'},
        );
        return true;
      } catch (e2) {
        return false;
      }
    }
  }

  // ============================================
  // TEST CREATION
  // ============================================
  Future<String?> createTest({
    required String title,
    String? description,
    required DateTime startDate,
    required DateTime endDate,
    required int durationMinutes,
  }) async {
    try {
      final createdBy = _supabase.auth.currentUser?.id;

      final response = await _supabase
          .from('tests')
          .insert({
            'title': title,
            'description': description,
            'start_date': startDate.toUtc().toIso8601String(),
            'end_date': endDate.toUtc().toIso8601String(),
            'duration_minutes': durationMinutes,
            'created_by': createdBy,
          })
          .select('id')
          .single();

      return response['id'] as String?;
    } catch (e) {
      return null;
    }
  }

  Future<bool> addQuestions(
    String testId,
    List<Map<String, dynamic>> questions,
  ) async {
    try {
      final questionsWithTestId = questions.asMap().entries.map((entry) {
        return {
          'test_id': testId,
          'question_text': entry.value['question'],
          'question_type': entry.value['type'] ?? 'single',
          'options': entry.value['options'],
          'correct_answers': [entry.value['correct_answer'] ?? 0],
          'explanation': entry.value['explanation'],
          'order_index': entry.key,
        };
      }).toList();

      await _supabase.from('test_questions').insert(questionsWithTestId);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Assign test to selected users and notify them
  Future<bool> assignTestToUsers(String testId, List<String> userIds) async {
    try {
      // Create assignments
      final assignments = userIds.map((uid) {
        return {'test_id': testId, 'user_id': uid, 'notified': false};
      }).toList();

      await _supabase.from('test_assignments').insert(assignments);

      // Create notifications for each user
      final testData = await _supabase
          .from('tests')
          .select('title')
          .eq('id', testId)
          .maybeSingle();
      final testTitle = testData?['title'] ?? 'New Test';

      final notifications = userIds.map((uid) {
        return {
          'user_id': uid,
          'type': 'test',
          'title': '📝 New Test Available!',
          'message':
              'A new test "$testTitle" has been assigned to you. Go to Tests tab to take the test now!',
          'is_read': false,
        };
      }).toList();

      await _supabase.from('notifications').insert(notifications);

      debugPrint(
        'AdminService: Assigned test $testId to ${userIds.length} users',
      );
      return true;
    } catch (e) {
      debugPrint('AdminService: Error assigning test: $e');
      return false;
    }
  }

  // ============================================
  // ENHANCED USER DETAILS
  // ============================================
  Future<Map<String, dynamic>?> getUserFullDetails(String userId) async {
    debugPrint('AdminService: Fetching full details for user: $userId');
    try {
      // Get profile with created_at
      final profile = await _supabase
          .from('profiles')
          .select('*, created_at')
          .eq('id', userId)
          .maybeSingle();

      if (profile == null) {
        debugPrint('AdminService: Profile not found for $userId');
        return null;
      }

      // Get user progress (streaks, study hours)
      Map<String, dynamic>? progress;
      try {
        progress = await _supabase
            .from('user_progress')
            .select()
            .eq('user_id', userId)
            .maybeSingle();
        debugPrint('AdminService: Progress for $userId: $progress');
      } catch (e) {
        debugPrint('AdminService: Error fetching user_progress: $e');
        progress = null;
      }

      // Get test results
      List<dynamic> testResults = [];
      try {
        testResults = await _supabase
            .from('test_results')
            .select('*, tests(title)')
            .eq('user_id', userId)
            .order('completed_at', ascending: true);
        debugPrint(
          'AdminService: Test results for $userId: ${testResults.length} records',
        );
      } catch (e) {
        debugPrint('AdminService: Error fetching test_results: $e');
        testResults = [];
      }

      // Get all mentors created by this user
      final List<Map<String, String>> mentorsList = [];
      try {
        final createdMentors = await _supabase
            .from('mentor_creations')
            .select('id, name, domain')
            .eq('user_id', userId);

        for (final m in createdMentors) {
          mentorsList.add({
            'name': m['name'] as String? ?? 'Unknown Mentor',
            'domain': m['domain'] as String? ?? 'General',
          });
        }
        debugPrint('AdminService: Found ${mentorsList.length} created mentors');
      } catch (e) {
        debugPrint('AdminService: Error fetching created mentors: $e');
      }

      // Fallback: If no created mentors, check interactions/chats
      if (mentorsList.isEmpty) {
        final mentorSet = <String>{};
        try {
          // Check chats
          final chatMentors = await _supabase
              .from('chat_messages')
              .select('mentor_id')
              .eq('user_id', userId);
          for (final msg in chatMentors) {
            if (msg['mentor_id'] != null) {
              mentorSet.add(msg['mentor_id'] as String);
            }
          }

          // Check interactions
          final interactions = await _supabase
              .from('mentor_interactions')
              .select('mentor_id')
              .eq('user_id', userId);
          for (final inter in interactions) {
            if (inter['mentor_id'] != null) {
              mentorSet.add(inter['mentor_id'] as String);
            }
          }

          if (mentorSet.isNotEmpty) {
            final mentorDetails = await _supabase
                .from('mentor_creations')
                .select('id, name, domain')
                .inFilter('id', mentorSet.toList());

            for (final m in mentorDetails) {
              mentorsList.add({
                'name': m['name'] as String? ?? 'Unknown Mentor',
                'domain': m['domain'] as String? ?? 'General',
              });
            }
          }
        } catch (e) {
          debugPrint('AdminService: Error fetching interacted mentors: $e');
        }
      }

      // Attendance Logic: Attended vs Missed from assignments
      int attendedCount = 0;
      int missedCount = 0;
      try {
        final assignments = await _supabase
            .from('test_assignments')
            .select('status')
            .eq('user_id', userId);

        for (final item in assignments) {
          final status = item['status'] as String?;
          if (status == 'attended' || status == 'completed') {
            attendedCount++;
          } else if (status == 'missed') {
            missedCount++;
          }
        }
        debugPrint(
          'AdminService: Attendance for $userId -> Attended: $attendedCount, Missed: $missedCount',
        );
      } catch (e) {
        debugPrint('AdminService: Error calculating precise attendance: $e');
        // Fallback to simpler logic if table not found or error
        attendedCount = testResults.length;
        missedCount = 0;
      }

      return {
        ...profile,
        'progress':
            progress ??
            {
              'current_streak': 0,
              'longest_streak': 0,
              'tests_completed': 0,
              'study_hours': 0,
            },
        'test_results': testResults,
        'mentors_used': mentorsList,

        'average_score': _calculateAverageScore(testResults),
        'attendance': {'attended': attendedCount, 'missed': missedCount},
      };
    } catch (e) {
      debugPrint('AdminService: Critical error in getUserFullDetails: $e');
      return null;
    }
  }

  double _calculateAverageScore(List<dynamic> results) {
    if (results.isEmpty) return 0;
    double totalPercent = 0;
    int count = 0;
    for (final r in results) {
      double? percent = (r['percentage'] as num?)?.toDouble();
      if (percent == null) {
        final score = (r['score'] as num?)?.toDouble() ?? 0;
        final total = (r['total_questions'] as num?)?.toDouble() ?? 0;
        percent = total > 0 ? (score / total) * 100 : 0;
      }
      totalPercent += percent;
      count++;
    }
    return count > 0 ? totalPercent / count : 0;
  }

  // ============================================
  // DELETE USER/ADMIN
  // ============================================
  Future<bool> deleteUser(String userId) async {
    try {
      // Delete from profiles (auth.users cascade should handle auth)
      await _supabase.from('profiles').delete().eq('id', userId);

      // Try to delete from auth (may fail if no admin access)
      try {
        await _supabase.auth.admin.deleteUser(userId);
      } catch (_) {
        // Admin API might not be available, but profile is deleted
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  // ============================================
  // RESET PASSWORD (Email-based)
  // ============================================
  Future<bool> resetPasswordByEmail(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Direct password update (requires admin API)
  Future<bool> updateUserPassword(String userId, String newPassword) async {
    try {
      await _supabase.auth.admin.updateUserById(
        userId,
        attributes: AdminUserAttributes(password: newPassword),
      );
      return true;
    } catch (e) {
      // Admin API not available, return false
      return false;
    }
  }
}
