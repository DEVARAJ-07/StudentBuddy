import 'package:flutter/material.dart';
import '../../../../core/theme/app_pallete.dart';
import '../../../../core/common/widgets/glass_container.dart';

class StudentProfileView extends StatelessWidget {
  const StudentProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Profile Header
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppPallete.primary, width: 2),
                      ),
                      child: const CircleAvatar(
                        radius: 50,
                        backgroundImage: NetworkImage(
                          'https://i.pravatar.cc/150?img=12',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Alex Johnson",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppPallete.textPrimary,
                      ),
                    ),
                    const Text(
                      "Student • Grade 12",
                      style: TextStyle(color: AppPallete.textSecondary),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Settings List with Glass Blocks
              _buildSettingsSection("Account", [
                _buildSettingsTile(
                  Icons.person_outline,
                  "Personal Information",
                ),
                _buildSettingsTile(Icons.security_outlined, "Security"),
                _buildSettingsTile(
                  Icons.notifications_outlined,
                  "Notifications",
                ),
              ]),

              const SizedBox(height: 20),

              _buildSettingsSection("Support", [
                _buildSettingsTile(Icons.help_outline, "Help Center"),
                _buildSettingsTile(Icons.info_outline, "About Us"),
              ]),

              const SizedBox(height: 20),
              GlassContainer(
                borderRadius: BorderRadius.circular(20),
                blur: 10,
                color: Colors.red.withValues(alpha: 0.1),
                opacity: 0.1,
                child: ListTile(
                  onTap: () {},
                  leading: const Icon(Icons.logout, color: Colors.redAccent),
                  title: const Text(
                    "Log Out",
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: AppPallete.textPrimary,
            ),
          ),
        ),
        GlassContainer(
          borderRadius: BorderRadius.circular(20),
          blur: 10,
          opacity: 0.05,
          color: AppPallete.surface,
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSettingsTile(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: AppPallete.textPrimary),
      title: Text(title, style: const TextStyle(color: AppPallete.textPrimary)),
      trailing: const Icon(
        Icons.chevron_right,
        color: AppPallete.textSecondary,
      ),
      onTap: () {},
    );
  }
}
