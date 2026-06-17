import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_pallete.dart';
import '../../../../core/common/widgets/glass_container.dart';
import '../../../auth/presentation/pages/login_page.dart';

class SuperAdminProfileView extends StatefulWidget {
  const SuperAdminProfileView({super.key});

  @override
  State<SuperAdminProfileView> createState() => _SuperAdminProfileViewState();
}

class _SuperAdminProfileViewState extends State<SuperAdminProfileView> {
  final SupabaseClient _supabase = Supabase.instance.client;
  Map<String, dynamic>? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _profile = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String get _userName => _profile?['full_name'] ?? 'Super Admin';
  String get _userEmail => _profile?['email'] ?? '';
  String? get _avatarUrl => _profile?['avatar_url'];
  String get _gender => _profile?['gender'] ?? 'male';
  String get _defaultAvatarPath => _gender == 'female'
      ? 'assets/images/default_female_avatar.jpg'
      : 'assets/images/super_admin_avatar.jpg';

  Future<void> _logout() async {
    try {
      await _supabase.auth.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppPallete.primary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // Profile Header
                  _buildProfileHeader().animate().fadeIn().slideY(begin: -0.1),

                  const SizedBox(height: 30),

                  // Info Section
                  GlassContainer(
                    borderRadius: BorderRadius.circular(20),
                    blur: 10,
                    opacity: 0.05,
                    color: AppPallete.surface,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildInfoTile(
                          Icons.email_rounded,
                          'Email',
                          _userEmail,
                        ),
                        const Divider(
                          color: AppPallete.textSecondary,
                          height: 24,
                        ),
                        _buildInfoTile(
                          Icons.admin_panel_settings_rounded,
                          'Role',
                          'Super Administrator',
                        ),
                        const Divider(
                          color: AppPallete.textSecondary,
                          height: 24,
                        ),
                        _buildInfoTile(
                          Icons.verified_rounded,
                          'Status',
                          'Active',
                          valueColor: AppPallete.success,
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),

                  const SizedBox(height: 20),

                  // Permissions Section
                  GlassContainer(
                    borderRadius: BorderRadius.circular(20),
                    blur: 10,
                    opacity: 0.05,
                    color: AppPallete.surface,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Permissions',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppPallete.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildPermissionTile('Create & Manage Admins'),
                        _buildPermissionTile('Create & Manage Tests'),
                        _buildPermissionTile('View All Users'),
                        _buildPermissionTile('Send Notifications'),
                        _buildPermissionTile('Access Analytics'),
                      ],
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

                  const SizedBox(height: 20),

                  const SizedBox(height: 30),

                  const SizedBox(height: 30),

                  // Logout Button with glow effect
                  GlassContainer(
                        borderRadius: BorderRadius.circular(20),
                        blur: 10,
                        color: Colors.red.withValues(alpha: 0.1),
                        opacity: 0.1,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.redAccent.withValues(alpha: 0.3),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: ListTile(
                            onTap: _logout,
                            leading: const Icon(
                              Icons.logout,
                              color: Colors.redAccent,
                            ),
                            title: Text(
                              'Log Out',
                              style: GoogleFonts.poppins(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .shimmer(
                        duration: 2000.ms,
                        color: Colors.redAccent.withValues(alpha: 0.2),
                      ),

                  const SizedBox(height: 120),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppPallete.primary, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppPallete.primary.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 50,
              backgroundImage:
                  _avatarUrl != null &&
                      _avatarUrl!.isNotEmpty &&
                      _avatarUrl!.startsWith('http')
                  ? NetworkImage(_avatarUrl!)
                  : AssetImage(_defaultAvatarPath) as ImageProvider,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              gradient: AppPallete.primaryGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'SUPER ADMIN',
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _userName,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppPallete.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppPallete.primary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppPallete.primary, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppPallete.textSecondary,
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? AppPallete.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionTile(String permission) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppPallete.success, size: 18),
          const SizedBox(width: 12),
          Text(
            permission,
            style: const TextStyle(color: AppPallete.textPrimary),
          ),
        ],
      ),
    );
  }
}
