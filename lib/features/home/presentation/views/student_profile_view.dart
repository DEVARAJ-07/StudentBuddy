import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_pallete.dart';
import '../../../../core/common/widgets/glass_container.dart';

import '../pages/help_center_page.dart';
import '../pages/about_us_page.dart';
import '../../../auth/presentation/pages/login_page.dart';

class StudentProfileView extends StatefulWidget {
  const StudentProfileView({super.key});

  @override
  State<StudentProfileView> createState() => _StudentProfileViewState();
}

class _StudentProfileViewState extends State<StudentProfileView> {
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
          .select('*, user_progress(*)')
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

  String get _userName => _profile?['full_name'] ?? 'User';
  String? get _avatarUrl => _profile?['avatar_url'];
  String get _userEmail => _supabase.auth.currentUser?.email ?? '';
  String get _gender => _profile?['gender'] ?? 'male';

  String get _defaultAvatarPath => _gender == 'female'
      ? 'assets/images/default_female_avatar.jpg'
      : 'assets/images/default_male_avatar.jpg';

  bool _canChangeName() {
    final lastChanged = _profile?['name_changed_at'];
    if (lastChanged == null) return true;
    final lastDate = DateTime.parse(lastChanged);
    return DateTime.now().difference(lastDate).inDays >= 30;
  }

  bool _canChangeAvatar() {
    final lastChanged = _profile?['avatar_changed_at'];
    if (lastChanged == null) return true;
    final lastDate = DateTime.parse(lastChanged);
    return DateTime.now().difference(lastDate).inDays >= 30;
  }

  Future<void> _pickAndUploadImage() async {
    if (!_canChangeAvatar()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can only change your photo once per month.'),
          backgroundColor: AppPallete.error,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppPallete.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Update Profile Photo',
          style: GoogleFonts.poppins(
            color: AppPallete.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppPallete.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: AppPallete.warning,
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'You can only change your photo once per month.',
                  style: TextStyle(color: AppPallete.warning, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppPallete.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppPallete.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Choose Photo',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );

    if (pickedFile == null) return;

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final fileBytes = await pickedFile.readAsBytes();
      final fileName = 'avatar_$userId.${pickedFile.path.split('.').last}';

      await _supabase.storage
          .from('avatars')
          .uploadBinary(
            fileName,
            fileBytes,
            fileOptions: const FileOptions(upsert: true),
          );

      final publicUrl = _supabase.storage
          .from('avatars')
          .getPublicUrl(fileName);

      await _supabase
          .from('profiles')
          .update({
            'avatar_url': publicUrl,
            'avatar_changed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      await _loadProfile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated!'),
            backgroundColor: AppPallete.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error uploading image: $e')));
      }
    }
  }

  Future<void> _showNameEditDialog() async {
    if (!_canChangeName()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can only change your name once per month.'),
          backgroundColor: AppPallete.error,
        ),
      );
      return;
    }

    final controller = TextEditingController(text: _userName);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppPallete.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Change Name',
          style: GoogleFonts.poppins(
            color: AppPallete.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              style: const TextStyle(color: AppPallete.textPrimary),
              decoration: InputDecoration(
                hintText: 'Enter new name',
                hintStyle: const TextStyle(color: AppPallete.textSecondary),
                filled: true,
                fillColor: AppPallete.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppPallete.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: AppPallete.warning,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You can only change your name once per month.',
                      style: TextStyle(color: AppPallete.warning, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppPallete.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppPallete.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && controller.text.trim().isNotEmpty) {
      await _updateName(controller.text.trim());
    }
  }

  Future<void> _updateName(String newName) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase
          .from('profiles')
          .update({
            'full_name': newName,
            'name_changed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      await _loadProfile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Name updated successfully!'),
            backgroundColor: AppPallete.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating name: $e')));
      }
    }
  }

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
        ).showSnackBar(SnackBar(content: Text('Error logging out: $e')));
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppPallete.primary),
              )
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // Profile Header
                    _buildProfileHeader(),
                    const SizedBox(height: 40),
                    // Account Section
                    _buildSettingsSection("Account", [
                      _buildSettingsTile(
                        Icons.person_outline,
                        "Change Name",
                        onTap: _showNameEditDialog,
                      ),
                      _buildSettingsTile(
                        Icons.camera_alt_outlined,
                        "Update Profile Photo",
                        onTap: _pickAndUploadImage,
                      ),
                    ]),
                    const SizedBox(height: 20),
                    // Support Section
                    _buildSettingsSection("Support", [
                      _buildSettingsTile(
                        Icons.help_outline,
                        "Help Center",
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const HelpCenterPage(),
                          ),
                        ),
                      ),
                      _buildSettingsTile(
                        Icons.info_outline,
                        "About Us",
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AboutUsPage(),
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 20),
                    // Logout
                    _buildLogoutButton(),
                    const SizedBox(height: 100),
                  ],
                ),
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
              border: Border.all(color: AppPallete.primary, width: 2),
            ),
            child:
                _avatarUrl != null &&
                    _avatarUrl!.isNotEmpty &&
                    _avatarUrl!.startsWith('http')
                ? CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(_avatarUrl!),
                  )
                : CircleAvatar(
                    radius: 50,
                    backgroundImage: AssetImage(_defaultAvatarPath),
                  ),
          ),
          const SizedBox(height: 16),
          Text(
            _userName,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppPallete.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _userEmail,
            style: const TextStyle(
              color: AppPallete.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1);
  }

  Widget _buildSettingsSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Text(
            title,
            style: GoogleFonts.poppins(
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

  Widget _buildSettingsTile(
    IconData icon,
    String title, {
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppPallete.textPrimary),
      title: Text(title, style: const TextStyle(color: AppPallete.textPrimary)),
      trailing: const Icon(
        Icons.chevron_right,
        color: AppPallete.textSecondary,
      ),
    );
  }

  Widget _buildLogoutButton() {
    return GlassContainer(
      borderRadius: BorderRadius.circular(20),
      blur: 10,
      color: Colors.red.withValues(alpha: 0.1),
      opacity: 0.1,
      child: ListTile(
        onTap: _logout,
        leading: const Icon(Icons.logout, color: Colors.redAccent),
        title: Text(
          "Log Out",
          style: GoogleFonts.poppins(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
