import 'package:flutter/material.dart';
import '../../../../core/theme/app_pallete.dart';
import '../../../../core/services/dashboard_service.dart';
import '../../../../core/services/notification_service.dart';
import '../widgets/greeting_header.dart';
import '../widgets/quick_stats_card.dart';
import '../widgets/analysis_card.dart';
import '../widgets/luck_card_widget.dart';
import '../widgets/monthly_activity_calendar.dart';
import '../widgets/about_section.dart';
import '../widgets/notification_center.dart';
import '../pages/analysis_details_page.dart';

class StudentHomeView extends StatefulWidget {
  final String userName;
  const StudentHomeView({super.key, this.userName = "Student"});

  @override
  State<StudentHomeView> createState() => _StudentHomeViewState();
}

class _StudentHomeViewState extends State<StudentHomeView>
    with WidgetsBindingObserver {
  final DashboardService _dashboardService = DashboardService();
  final NotificationService _notificationService = NotificationService();
  Map<String, dynamic>? _userProgress;
  bool _isLoading = true;
  int _notificationCount = 0;
  int _messageCount = 0;
  String? _currentSessionId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startSession();
    _loadData();
    // Permission requests removed - OS handles when needed
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopSession();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startSession();
      _loadData();
    } else if (state == AppLifecycleState.paused) {
      _stopSession();
    }
  }

  Future<void> _startSession() async {
    _currentSessionId ??= await _dashboardService.startStudySession();
  }

  Future<void> _stopSession() async {
    if (_currentSessionId != null) {
      await _dashboardService.endStudySession(_currentSessionId!);
      _currentSessionId = null;
    }
  }

  Future<void> _loadData() async {
    // Update daily streak on app open
    await _dashboardService.updateDailyStreak();

    // Fetch user progress
    final progress = await _dashboardService.fetchUserProgress();

    if (mounted) {
      setState(() {
        _userProgress = progress;
        _isLoading = false;
      });
      _loadNotificationCount();
    }
  }

  Future<void> _loadNotificationCount() async {
    final unreadNotifications = await _notificationService.getUnreadCount();
    final unreadMessages = await _notificationService.getUnreadMessageCount();

    if (mounted) {
      setState(() {
        _notificationCount = unreadNotifications;
        _messageCount = unreadMessages;
      });
    }
  }

  void _navigateToAnalysis() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            AnalysisDetailsPage(userProgress: _userProgress),
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
  }

  @override
  Widget build(BuildContext context) {
    final int currentStreak = (_userProgress?['current_streak'] as int?) ?? 0;
    final int testsCompleted = (_userProgress?['tests_completed'] as int?) ?? 0;
    final double studyHours =
        (_userProgress?['study_hours'] as num?)?.toDouble() ?? 0.0;

    // Extract role safely
    final profile = _userProgress?['profiles'] as Map<String, dynamic>?;
    final String role = (profile?['role'] as String?) ?? 'user';
    final bool isRegularUser = role == 'user';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppPallete.primary,
          backgroundColor: AppPallete.surface,
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppPallete.primary),
                )
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Greeting Header
                      GreetingHeader(
                        userName: widget.userName,
                        notificationCount: _notificationCount,
                        messageCount: _messageCount,
                        onNotificationTap: () async {
                          await showNotificationCenter(context);
                          // Refresh notification count after closing
                          _loadNotificationCount();
                        },
                        onMessageRefresh: _loadNotificationCount,
                      ),

                      const SizedBox(height: 8),

                      // Quick Stats (with streak, tests, study hours)
                      QuickStatsCard(
                        currentStreak: currentStreak,
                        testsCompleted: testsCompleted,
                        studyHours: studyHours,
                      ),

                      const SizedBox(height: 8),

                      // Analysis Card
                      AnalysisCard(
                        onTap: _navigateToAnalysis,
                        testsCompleted: testsCompleted,
                        studyHours: studyHours,
                      ),

                      const SizedBox(height: 8),

                      // Activity Calendar
                      const MonthlyActivityCalendar(),

                      const SizedBox(height: 20),

                      // Lucky Draw Game (Users Only)
                      if (isRegularUser) ...[
                        const LuckCardWidget(),
                        const SizedBox(height: 20),
                      ],

                      // About Section (FAQs, Contact, Privacy)
                      const AboutSection(),

                      // Bottom padding for navigation
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
