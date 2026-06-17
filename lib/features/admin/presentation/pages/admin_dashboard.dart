import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_pallete.dart';
import '../../../../core/common/widgets/glass_container.dart';
import '../../../../core/common/widgets/animated_background.dart';
import '../views/admin_stats_view.dart';
import '../views/users_list_view.dart';
import '../views/test_creation_view.dart';
import '../views/admin_profile_view.dart';

/// Admin Dashboard - Same as SuperAdmin but without Admin management
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  void _navigateTo(int index) {
    setState(() => _selectedIndex = index);
  }

  // 4 tabs: Dashboard, Users, Tests, Profile (no Admins tab)
  List<Widget> get _pages => [
    AdminStatsView(
      isSuperAdmin: false, // Show as "Admin" not "Super Admin"
      onNavigateToTestCreation: () => _navigateTo(2), // Tests tab
    ),
    const UsersListView(showOnlyUsers: true), // Only show regular users
    const TestCreationView(),
    const AdminProfileView(),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPallete.background,
      body: AnimatedBackground(
        child: Stack(
          children: [
            _pages[_selectedIndex],

            // Bottom Navigation
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child:
                    GlassContainer(
                      height: 70,
                      width: MediaQuery.of(context).size.width - 40,
                      blur: 20,
                      opacity: 0.1,
                      color: AppPallete.surface,
                      borderRadius: BorderRadius.circular(35),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildNavItem(
                            0,
                            Icons.dashboard_rounded,
                            'Dashboard',
                          ),
                          _buildNavItem(1, Icons.people_rounded, 'Users'),
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
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppPallete.primary.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppPallete.primary : Colors.grey,
              size: 24,
            ),
            if (isSelected)
              Text(
                label,
                style: const TextStyle(
                  color: AppPallete.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
