import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_pallete.dart';
import '../../../../core/common/widgets/glass_container.dart';

import '../views/student_home_view.dart';

import '../views/student_profile_view.dart';
import 'package:student_buddy/features/mentor/presentation/pages/mentors_page.dart';
import 'package:student_buddy/features/tests/presentation/pages/tests_page.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _selectedIndex = 0;
  String _userName = "Student";
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final data = await Supabase.instance.client
            .from('profiles')
            .select('full_name')
            .eq('id', user.id)
            .single();
        setState(() {
          _userName = data['full_name'] ?? "Student";
        });
      } catch (e) {
        debugPrint("Error fetching user data: $e");
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Pages list
    final List<Widget> pages = [
      StudentHomeView(userName: _userName), // Pass userName to Home
      const MentorsPage(),
      const TestsPage(),
      const StudentProfileView(),
    ];

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppPallete.background,
      body: Stack(
        children: [
          // Background - clean dark theme, no extra gradient needed as AppPallete.background is set
          // We can add a subtle radial gradient if we want "Modern UI" depth later,
          // but for now strict adherence to clean dark theme.
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
                    opacity: 0.1,
                    // Make it slightly lighter than background to pop
                    color: AppPallete.surface,
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          onPressed: () => _onItemTapped(0),
                          icon: Icon(
                            Icons.home_rounded,
                            color: _selectedIndex == 0
                                ? AppPallete.primary
                                : Colors.grey,
                            size: 28,
                          ),
                        ),
                        IconButton(
                          onPressed: () => _onItemTapped(1), // Mentors
                          icon: Icon(
                            Icons.people_alt_rounded,
                            color: _selectedIndex == 1
                                ? AppPallete.primary
                                : Colors.grey,
                            size: 28,
                          ),
                        ),
                        IconButton(
                          onPressed: () => _onItemTapped(2), // Tests
                          icon: Icon(
                            Icons.quiz_rounded,
                            color: _selectedIndex == 2
                                ? AppPallete.primary
                                : Colors.grey,
                            size: 28,
                          ),
                        ),
                        IconButton(
                          onPressed: () => _onItemTapped(3), // Profile
                          icon: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: _selectedIndex == 3
                                ? BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppPallete.primary,
                                      width: 2,
                                    ),
                                  )
                                : null,
                            child: const CircleAvatar(
                              radius: 12,
                              backgroundImage: NetworkImage(
                                'https://i.pravatar.cc/150?img=12',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().slideY(
                    begin: 1,
                    duration: 400.ms,
                    curve: Curves.easeOutCubic, // Snappy curve
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
