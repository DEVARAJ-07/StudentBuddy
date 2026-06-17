import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_pallete.dart';
import '../../../../core/common/widgets/glass_container.dart';
import '../../../../core/common/widgets/animated_background.dart';
import '../../../../core/services/dashboard_service.dart';

import '../views/student_home_view.dart';

import '../views/student_profile_view.dart';
import 'package:student_buddy/features/mentor/presentation/pages/mentors_page.dart';
import 'package:student_buddy/features/tests/presentation/pages/tests_page.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard>
    with WidgetsBindingObserver {
  int _selectedIndex = 0;
  String _userName = "Student";
  String? _avatarUrl;
  String _gender = 'male';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final DashboardService _dashboardService = DashboardService();
  String? _currentSessionId; // Track current study session

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Listen to app lifecycle
    _fetchUserData();
    _dashboardService.updateDailyStreak(); // Update streak on login
    _startNewSession(); // Start study session tracking
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _endCurrentSession(); // End session on dispose
    super.dispose();
  }

  /// Handle app lifecycle changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // App is going to background or closing
        _endCurrentSession();
        break;
      case AppLifecycleState.resumed:
        // App is back in foreground - start new session
        _startNewSession();
        break;
      case AppLifecycleState.inactive:
        // Brief pause (e.g., phone call) - don't end session yet
        break;
    }
  }

  /// Start a new study session
  Future<void> _startNewSession() async {
    if (_currentSessionId == null) {
      _currentSessionId = await _dashboardService.startStudySession();
      debugPrint('Study session started: $_currentSessionId');
    }
  }

  /// End current study session
  Future<void> _endCurrentSession() async {
    if (_currentSessionId != null) {
      await _dashboardService.endStudySession(_currentSessionId!);
      debugPrint('Study session ended: $_currentSessionId');
      _currentSessionId = null;
    }
  }

  Future<void> _fetchUserData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final data = await Supabase.instance.client
            .from('profiles')
            .select('full_name, avatar_url, gender')
            .eq('id', user.id)
            .single();
        setState(() {
          _userName = data['full_name'] ?? "Student";
          _avatarUrl = data['avatar_url'];
          _gender = data['gender'] ?? 'male';
        });
      } catch (e) {
        debugPrint("Error fetching user data: $e");
      }
    }
  }

  String get _defaultAvatarPath => _gender == 'female'
      ? 'assets/images/default_female_avatar.jpg'
      : 'assets/images/default_male_avatar.jpg';

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Pages list
    final List<Widget> pages = [
      StudentHomeView(userName: _userName), // Pass userName to Home
      const MentorsPage(),
      const TestsPage(),
      const StudentProfileView(),
    ];

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: theme.scaffoldBackgroundColor,
      body: AnimatedBackground(
        child: Stack(
          children: [
            // Current page content
            pages[_selectedIndex],

            // Minimal Glass Bottom Navigation
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 30),
                child:
                    GlassContainer(
                      height: 70,
                      width: 320,
                      blur: 20,
                      opacity: isDark ? 0.1 : 0.4,
                      color: isDark ? AppPallete.surface : Colors.white,
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildNavItem(0, Icons.home_rounded, 'Home'),
                          _buildNavItem(1, Icons.people_alt_rounded, 'Mentors'),
                          _buildNavItem(2, Icons.quiz_rounded, 'Tests'),
                          _buildNavItem(3, Icons.person_rounded, 'Profile'),
                        ],
                      ),
                    ).animate().slideY(
                      begin: 1,
                      duration: 400.ms,
                      curve: Curves.easeOutCubic,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    // Profile uses avatar instead of icon
    if (index == 3) {
      return GestureDetector(
        onTap: () => _onItemTapped(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: isSelected
                  ? BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppPallete.primary, width: 2),
                    )
                  : null,
              child: CircleAvatar(
                radius: 12,
                backgroundImage:
                    _avatarUrl != null &&
                        _avatarUrl!.isNotEmpty &&
                        _avatarUrl!.startsWith('http')
                    ? NetworkImage(_avatarUrl!)
                    : AssetImage(_defaultAvatarPath) as ImageProvider,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  color: AppPallete.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? AppPallete.primary : Colors.grey,
            size: 24,
          ),
          if (isSelected) ...[
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: AppPallete.primary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
