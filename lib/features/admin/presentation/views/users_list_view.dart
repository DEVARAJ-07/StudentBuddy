import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_pallete.dart';
import '../../../../core/common/widgets/glass_container.dart';
import '../../../../core/services/admin_service.dart';

class UsersListView extends StatefulWidget {
  final bool showOnlyUsers; // If true, hide Admins tab (for Admin dashboard)

  const UsersListView({super.key, this.showOnlyUsers = false});

  @override
  State<UsersListView> createState() => _UsersListViewState();
}

class _UsersListViewState extends State<UsersListView>
    with SingleTickerProviderStateMixin {
  final AdminService _adminService = AdminService();
  late TabController _tabController;
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _admins = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // 1 tab if showOnlyUsers, 2 tabs otherwise
    _tabController = TabController(
      length: widget.showOnlyUsers ? 1 : 2,
      vsync: this,
    );
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final users = await _adminService.getAllUsers();
    final admins = await _adminService.getAllAdmins();
    if (mounted) {
      setState(() {
        _users = users;
        _admins = admins;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  'User Management',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppPallete.textPrimary,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn().slideX(begin: -0.1),

          // Tab Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: AppPallete.surface.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(25),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                gradient: AppPallete.primaryGradient,
                borderRadius: BorderRadius.circular(25),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: AppPallete.textSecondary,
              labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
              tabs: widget.showOnlyUsers
                  ? [Tab(text: 'Users (${_users.length})')]
                  : [
                      Tab(text: 'Users (${_users.length})'),
                      Tab(text: 'Admins (${_admins.length})'),
                    ],
            ),
          ).animate().fadeIn(delay: 100.ms),

          const SizedBox(height: 20),

          // Tab Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppPallete.primary),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: widget.showOnlyUsers
                        ? [_buildUsersList(_users, isAdmin: false)]
                        : [
                            _buildUsersList(_users, isAdmin: false),
                            _buildUsersList(_admins, isAdmin: true),
                          ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList(
    List<Map<String, dynamic>> users, {
    required bool isAdmin,
  }) {
    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.people_outline,
              size: 64,
              color: AppPallete.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              isAdmin ? 'No admins found' : 'No users found',
              style: const TextStyle(color: AppPallete.textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppPallete.primary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: users.length + 1,
        itemBuilder: (context, index) {
          if (index == users.length) {
            return const SizedBox(height: 120);
          }
          return _buildUserCard(users[index], index, isAdmin: isAdmin);
        },
      ),
    );
  }

  Widget _buildUserCard(
    Map<String, dynamic> user,
    int index, {
    required bool isAdmin,
  }) {
    final name = user['full_name'] ?? 'Unknown';
    final email = user['email'] ?? '';
    final avatarUrl = user['avatar_url'];
    final gender = user['gender'] ?? 'male';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        borderRadius: BorderRadius.circular(20),
        blur: 15,
        opacity: 0.08,
        color: AppPallete.surface,
        border: Border.all(color: AppPallete.primary.withValues(alpha: 0.1)),
        child: ListTile(
          onTap: () =>
              isAdmin ? _showAdminDetails(user) : _showUserDetails(user),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 10,
          ),
          leading: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppPallete.primary.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 26,
              backgroundImage:
                  avatarUrl != null && avatarUrl.toString().startsWith('http')
                  ? NetworkImage(avatarUrl)
                  : AssetImage(
                          gender == 'female'
                              ? 'assets/images/default_female_avatar.jpg'
                              : 'assets/images/default_male_avatar.jpg',
                        )
                        as ImageProvider,
            ),
          ),
          title: Text(
            name,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              color: AppPallete.textPrimary,
              fontSize: 16,
            ),
          ),
          subtitle: Text(
            email,
            style: TextStyle(
              color: AppPallete.textSecondary.withValues(alpha: 0.8),
              fontSize: 12,
              letterSpacing: 0.2,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isAdmin)
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppPallete.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.send_rounded, size: 18),
                  ),
                  color: AppPallete.primary,
                  onPressed: () => _showMessageDialog(user),
                ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                color: AppPallete.textSecondary.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    ).animate(delay: (index * 50).ms).fadeIn().slideX(begin: 0.05);
  }

  Future<bool> _confirmDelete(Map<String, dynamic> user, bool isAdmin) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppPallete.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_rounded, color: AppPallete.error),
            const SizedBox(width: 8),
            Text(
              'Delete ${isAdmin ? 'Admin' : 'User'}',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: AppPallete.textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete "${user['full_name']}"?\n\nThis action cannot be undone.',
          style: const TextStyle(color: AppPallete.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppPallete.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppPallete.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == true) {
      final success = await _adminService.deleteUser(user['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Deleted successfully' : 'Failed to delete',
            ),
            backgroundColor: success ? AppPallete.success : AppPallete.error,
          ),
        );
        if (success) _loadData();
      }
      return success;
    }
    return false;
  }

  void _showUserDetails(Map<String, dynamic> user) async {
    // Show loading
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final details = await _adminService.getUserFullDetails(user['id']);
    if (!mounted) return;
    Navigator.pop(context); // Close loading

    if (details == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load user details')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _UserDetailSheet(
        user: details,
        onDelete: () async {
          Navigator.pop(context);
          await _confirmDelete(user, false);
        },
        onResetPassword: () => _showResetPasswordDialog(user),
      ),
    );
  }

  void _showAdminDetails(Map<String, dynamic> admin) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _AdminDetailSheet(
        admin: admin,
        onDelete: () async {
          Navigator.pop(context);
          await _confirmDelete(admin, true);
        },
        onResetPassword: () => _showResetPasswordDialog(admin),
      ),
    );
  }

  void _showResetPasswordDialog(Map<String, dynamic> user) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppPallete.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Reset Password',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: AppPallete.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'For: ${user['full_name']}',
              style: const TextStyle(color: AppPallete.textSecondary),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              obscureText: true,
              style: const TextStyle(color: AppPallete.textPrimary),
              decoration: InputDecoration(
                hintText: 'Enter new password',
                hintStyle: const TextStyle(color: AppPallete.textSecondary),
                filled: true,
                fillColor: AppPallete.background,
                prefixIcon: const Icon(
                  Icons.lock_outline_rounded,
                  color: AppPallete.primary,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppPallete.primary),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Minimum 6 characters required',
              style: TextStyle(
                color: AppPallete.textSecondary.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppPallete.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password must be at least 6 characters'),
                  ),
                );
                return;
              }

              final nav = Navigator.of(context);
              final scaffold = ScaffoldMessenger.of(context);

              // Show loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) =>
                    const Center(child: CircularProgressIndicator()),
              );

              final success = await _adminService.updateUserPassword(
                user['id'],
                controller.text,
              );

              if (!mounted) return;

              nav.pop(); // Close loading indicator (it's the top-most route on this navigator)
              nav.pop(); // Close reset dialog

              scaffold.showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? 'Password successfully updated for ${user['full_name']}!'
                        : 'Failed to update password. Admin privileges required.',
                  ),
                  backgroundColor: success
                      ? AppPallete.success
                      : AppPallete.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppPallete.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'Update Password',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showMessageDialog(Map<String, dynamic> user) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppPallete.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Send Message',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: AppPallete.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'To: ${user['full_name']}',
              style: const TextStyle(color: AppPallete.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 4,
              style: const TextStyle(color: AppPallete.textPrimary),
              decoration: InputDecoration(
                hintText: 'Type your message...',
                hintStyle: const TextStyle(color: AppPallete.textSecondary),
                filled: true,
                fillColor: AppPallete.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppPallete.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;

              final nav = Navigator.of(context);
              final scaffold = ScaffoldMessenger.of(context);

              final message =
                  'I am the SuperAdmin from StudentBuddy: ${controller.text.trim()}';

              final success = await _adminService.sendMessage(
                user['id'],
                message,
              );

              nav.pop();
              scaffold.showSnackBar(
                SnackBar(
                  content: Text(
                    success ? 'Message sent!' : 'Failed to send message',
                  ),
                  backgroundColor: success
                      ? AppPallete.success
                      : AppPallete.error,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppPallete.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Send', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ============================================
// USER DETAIL SHEET (Full Details + Graphs)
// ============================================
class _UserDetailSheet extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onDelete;
  final VoidCallback onResetPassword;

  const _UserDetailSheet({
    required this.user,
    required this.onDelete,
    required this.onResetPassword,
  });

  @override
  Widget build(BuildContext context) {
    final name = user['full_name'] ?? 'Unknown';
    final email = user['email'] ?? '';
    final gender = user['gender'] ?? 'male';
    final avatarUrl = user['avatar_url'];
    final createdAt = user['created_at'];
    final progress = user['progress'] as Map<String, dynamic>? ?? {};
    final testResults = user['test_results'] as List? ?? [];
    final mentorsUsed = user['mentors_used'] as List? ?? [];
    final avgScore = user['average_score'] as double? ?? 0;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppPallete.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Avatar and Name
                  CircleAvatar(
                    radius: 40,
                    backgroundImage:
                        avatarUrl != null &&
                            avatarUrl.toString().startsWith('http')
                        ? NetworkImage(avatarUrl)
                        : AssetImage(
                                gender == 'female'
                                    ? 'assets/images/default_female_avatar.jpg'
                                    : 'assets/images/default_male_avatar.jpg',
                              )
                              as ImageProvider,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    name,
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppPallete.textPrimary,
                    ),
                  ),
                  Text(
                    email,
                    style: const TextStyle(color: AppPallete.textSecondary),
                  ),
                  if (createdAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Joined ${_formatDate(createdAt)}',
                      style: const TextStyle(
                        color: AppPallete.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Stats Grid
                  Row(
                    children: [
                      _buildStatBox(
                        'Streak',
                        '${progress['current_streak'] ?? 0}',
                        Icons.local_fire_department_rounded,
                      ),
                      const SizedBox(width: 12),
                      _buildStatBox(
                        'Tests',
                        '${progress['tests_completed'] ?? 0}',
                        Icons.quiz_rounded,
                      ),
                      const SizedBox(width: 12),
                      _buildStatBox(
                        'Avg Score',
                        '${avgScore.toStringAsFixed(0)}%',
                        Icons.score_rounded,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Attended vs Missed (without Performance Trend title)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppPallete.background,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildAttendanceItem(
                          'Attended',
                          '${user['attendance']?['attended'] ?? 0}',
                          Icons.check_circle_rounded,
                          AppPallete.success,
                        ),
                        Container(width: 1, height: 40, color: Colors.white10),
                        _buildAttendanceItem(
                          'Missed',
                          '${user['attendance']?['missed'] ?? 0}',
                          Icons.cancel_rounded,
                          AppPallete.error,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Mentors Used - Interaction Focused
                  _buildSectionTitle('Mentors Used'),
                  if (mentorsUsed.isNotEmpty)
                    Column(
                      children: mentorsUsed.map((m) {
                        // m is now a Map with 'name' and 'domain'
                        final mentorName = m is Map
                            ? (m['name'] ?? 'Unknown')
                            : m.toString();
                        final mentorDomain = m is Map
                            ? (m['domain'] ?? 'General')
                            : '';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppPallete.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppPallete.primary.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: AppPallete.primaryGradient,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.psychology_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      mentorName,
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        color: AppPallete.textPrimary,
                                        fontSize: 14,
                                      ),
                                    ),
                                    if (mentorDomain.isNotEmpty)
                                      Text(
                                        mentorDomain,
                                        style: GoogleFonts.inter(
                                          color: AppPallete.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppPallete.background,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.psychology_outlined,
                            color: AppPallete.textSecondary.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'No mentor interactions yet',
                            style: TextStyle(color: AppPallete.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Test Scores - Title and Marks
                  _buildSectionTitle('Test Scores'),
                  if (testResults.isNotEmpty)
                    ...testResults.take(10).map((result) {
                      final score = result['score'] ?? 0;
                      final title = result['tests']?['title'] ?? 'Test Score';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppPallete.background,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppPallete.primary.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.quiz_rounded,
                                color: AppPallete.primary,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      color: AppPallete.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    result['completed_at'] != null
                                        ? _formatDate(result['completed_at'])
                                        : 'N/A',
                                    style: const TextStyle(
                                      color: AppPallete.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '$score%',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                color: _getScoreColor(score),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    })
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppPallete.background,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.quiz_outlined,
                            color: AppPallete.textSecondary.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'No test scores yet',
                            style: TextStyle(color: AppPallete.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onResetPassword,
                          icon: const Icon(Icons.lock_reset),
                          label: const Text('Reset Password'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppPallete.primary,
                            side: const BorderSide(color: AppPallete.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onDelete,
                          icon: const Icon(Icons.delete_forever),
                          label: const Text('Delete User'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppPallete.error,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(dynamic score) {
    final s = (score as num?)?.toInt() ?? 0;
    if (s >= 80) return AppPallete.success;
    if (s >= 50) return AppPallete.warning;
    return AppPallete.error;
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM d, yyyy').format(date);
    } catch (_) {
      return 'N/A';
    }
  }

  Widget _buildAttendanceItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppPallete.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: AppPallete.textSecondary, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildStatBox(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppPallete.background,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppPallete.primary),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppPallete.textPrimary,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: AppPallete.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppPallete.textPrimary,
          ),
        ),
      ),
    );
  }
}

// ============================================
// ADMIN DETAIL SHEET (Simple)
// ============================================
class _AdminDetailSheet extends StatelessWidget {
  final Map<String, dynamic> admin;
  final VoidCallback onDelete;
  final VoidCallback onResetPassword;

  const _AdminDetailSheet({
    required this.admin,
    required this.onDelete,
    required this.onResetPassword,
  });

  @override
  Widget build(BuildContext context) {
    final name = admin['full_name'] ?? 'Unknown';
    final email = admin['email'] ?? '';
    final gender = admin['gender'] ?? 'male';
    final avatarUrl = admin['avatar_url'];
    final createdAt = admin['created_at'];

    return Container(
      decoration: const BoxDecoration(
        color: AppPallete.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Avatar
          CircleAvatar(
            radius: 40,
            backgroundImage:
                avatarUrl != null && avatarUrl.toString().startsWith('http')
                ? NetworkImage(avatarUrl)
                : AssetImage(
                        gender == 'female'
                            ? 'assets/images/default_female_avatar.jpg'
                            : 'assets/images/default_male_avatar.jpg',
                      )
                      as ImageProvider,
          ),
          const SizedBox(height: 12),

          // Admin Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              gradient: AppPallete.primaryGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'ADMIN',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),

          Text(
            name,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppPallete.textPrimary,
            ),
          ),
          Text(email, style: const TextStyle(color: AppPallete.textSecondary)),

          if (createdAt != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppPallete.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: AppPallete.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Created ${_formatDate(createdAt)}',
                    style: const TextStyle(
                      color: AppPallete.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onResetPassword,
                  icon: const Icon(Icons.lock_reset),
                  label: const Text('Reset Password'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppPallete.primary,
                    side: const BorderSide(color: AppPallete.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_forever),
                  label: const Text('Delete Admin'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppPallete.error,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM d, yyyy').format(date);
    } catch (_) {
      return 'N/A';
    }
  }
}
