import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_pallete.dart';
import '../../../../features/auth/presentation/pages/login_page.dart';
import 'glass_container.dart';

class GlassDrawer extends StatelessWidget {
  final String userName;
  final int selectedIndex;
  final Function(int) onDestinationSelected;

  const GlassDrawer({
    super.key,
    required this.userName,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Transparent barrier to close drawer
        Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.75,
            height: double.infinity,
            child:
                GlassContainer(
                      blur: 20,
                      opacity: 0.1,
                      color: Colors.black, // Dark themed glass
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                      child: SafeArea(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Drawer Header
                            Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const CircleAvatar(
                                    radius: 30,
                                    backgroundImage: NetworkImage(
                                      'https://i.pravatar.cc/150?img=12',
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    userName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    "Student • Grade 12",
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.7,
                                      ),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const Divider(color: Colors.white24, height: 1),
                            const SizedBox(height: 16),

                            // Menu Items
                            _buildDrawerItem(
                              Icons.grid_view_rounded,
                              "Dashboard",
                              0,
                            ),
                            _buildDrawerItem(Icons.book, "My Courses", 1),
                            _buildDrawerItem(Icons.person, "Profile", 2),

                            const Spacer(),

                            // Logout
                            Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: _buildLogoutItem(context),
                            ),
                          ],
                        ),
                      ),
                    )
                    .animate()
                    .slideX(
                      begin: -1,
                      end: 0,
                      duration: 400.ms,
                      curve: Curves.easeOutQuart,
                    )
                    .fadeIn(),
          ),
        ),
      ],
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, int index) {
    final bool isActive = selectedIndex == index;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onDestinationSelected(index),
        splashColor: Colors.white.withValues(alpha: 0.1),
        highlightColor: Colors.white.withValues(alpha: 0.05),
        child: Container(
          decoration: isActive
              ? BoxDecoration(
                  border: Border(
                    left: BorderSide(color: AppPallete.primary, width: 4),
                  ),
                )
              : null,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              Icon(
                icon,
                color: isActive ? AppPallete.primary : Colors.white70,
                size: 24,
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.white70,
                  fontSize: 16,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutItem(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          await Supabase.instance.client.auth.signOut();
          if (context.mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
              (route) => false,
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: const [
              Icon(Icons.logout, color: Colors.redAccent, size: 24),
              SizedBox(width: 16),
              Text(
                "Logout",
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
