import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_pallete.dart';
import '../../../../core/common/widgets/glass_container.dart';
import '../../../../core/services/admin_service.dart';

class AdminStatsView extends StatefulWidget {
  final bool isSuperAdmin; // If true, show "Super Admin" and Admins stat
  final VoidCallback? onNavigateToAdminCreation;
  final VoidCallback? onNavigateToTestCreation;

  const AdminStatsView({
    super.key,
    this.isSuperAdmin = true,
    this.onNavigateToAdminCreation,
    this.onNavigateToTestCreation,
  });

  @override
  State<AdminStatsView> createState() => _AdminStatsViewState();
}

class _AdminStatsViewState extends State<AdminStatsView> {
  final AdminService _adminService = AdminService();
  Map<String, int> _stats = {'users': 0, 'admins': 0, 'tests': 0};

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await _adminService.getDashboardStats();
    if (mounted) {
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadStats,
        color: AppPallete.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: AppPallete.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isSuperAdmin ? 'Super Admin' : 'Admin',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppPallete.textPrimary,
                        ),
                      ),
                      const Text(
                        'Dashboard Overview',
                        style: TextStyle(
                          color: AppPallete.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ).animate().fadeIn().slideX(begin: -0.1),

              const SizedBox(height: 30),

              // Stats Cards
              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(color: AppPallete.primary),
                )
              else
                widget.isSuperAdmin
                    // SuperAdmin: 4 boxes (Users, Admins, Tests, Mentors)
                    ? Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  'Total Users',
                                  _stats['users'] ?? 0,
                                  Icons.people_rounded,
                                  const Color(0xFF00C6FF),
                                  0,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildStatCard(
                                  'Total Admins',
                                  _stats['admins'] ?? 0,
                                  Icons.admin_panel_settings_rounded,
                                  const Color(0xFF7F00FF),
                                  1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  'Total Tests',
                                  _stats['tests'] ?? 0,
                                  Icons.quiz_rounded,
                                  const Color(0xFFFF8C00),
                                  2,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildStatCard(
                                  'Mentors Created',
                                  _stats['mentors'] ?? 0,
                                  Icons.psychology_rounded,
                                  const Color(0xFF00FA9A),
                                  3,
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    // Admin: 3 boxes only (Users, Tests, Mentors) - no Active box
                    : Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  'Total Users',
                                  _stats['users'] ?? 0,
                                  Icons.people_rounded,
                                  const Color(0xFF00C6FF),
                                  0,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildStatCard(
                                  'Total Tests',
                                  _stats['tests'] ?? 0,
                                  Icons.quiz_rounded,
                                  const Color(0xFFFF8C00),
                                  1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Single centered Mentors box
                          _buildStatCard(
                            'Mentors Created',
                            _stats['mentors'] ?? 0,
                            Icons.psychology_rounded,
                            const Color(0xFF00FA9A),
                            2,
                          ),
                        ],
                      ),

              const SizedBox(height: 30),

              // Mentors Created Detail (New)
              Text(
                'Mentors Created',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppPallete.textPrimary,
                ),
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 16),

              FutureBuilder<List<Map<String, dynamic>>>(
                future: _adminService.getMentorsCreated(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final mentors = snapshot.data ?? [];
                  if (mentors.isEmpty) {
                    return GlassContainer(
                      padding: const EdgeInsets.all(20),
                      borderRadius: BorderRadius.circular(16),
                      child: const Center(
                        child: Text(
                          'No mentors created yet',
                          style: TextStyle(color: AppPallete.textSecondary),
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: mentors.take(5).map((mentor) {
                      final creator =
                          mentor['profiles']?['full_name'] ?? 'Unknown';
                      final date = mentor['created_at'] != null
                          ? DateTime.parse(
                              mentor['created_at'],
                            ).toLocal().toString().split(' ')[0]
                          : 'N/A';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: GlassContainer(
                          padding: const EdgeInsets.all(16),
                          borderRadius: BorderRadius.circular(16),
                          opacity: 0.05,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppPallete.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.person_pin_rounded,
                                  color: AppPallete.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      mentor['name'] ?? 'Unnamed Mentor',
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.bold,
                                        color: AppPallete.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      'By $creator • $date',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppPallete.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppPallete.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  mentor['domain'] ?? 'General',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppPallete.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),

              const SizedBox(height: 30),

              // Quick Actions
              Text(
                'Quick Actions',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppPallete.textPrimary,
                ),
              ).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 16),

              // Quick Actions - Conditional based on role
              if (widget.isSuperAdmin)
                Row(
                  children: [
                    Expanded(
                      child: _buildActionCard(
                        'Create Admin',
                        Icons.person_add_rounded,
                        () => widget.onNavigateToAdminCreation?.call(),
                        4,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildActionCard(
                        'Create Test',
                        Icons.add_circle_rounded,
                        () => widget.onNavigateToTestCreation?.call(),
                        5,
                      ),
                    ),
                  ],
                )
              else
                // Admin only gets Create Test
                _buildActionCard(
                  'Create Test',
                  Icons.add_circle_rounded,
                  () => widget.onNavigateToTestCreation?.call(),
                  4,
                ),

              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    int value,
    IconData icon,
    Color color,
    int index,
  ) {
    return GlassContainer(
          borderRadius: BorderRadius.circular(24),
          blur: 15,
          opacity: 0.08,
          color: AppPallete.surface,
          border: Border.all(color: color.withValues(alpha: 0.15), width: 1.5),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: color.withValues(alpha: 0.2)),
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppPallete.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.trending_up_rounded,
                      color: AppPallete.success,
                      size: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TweenAnimationBuilder<int>(
                tween: IntTween(begin: 0, end: value),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeOutCubic,
                builder: (context, val, child) {
                  return Text(
                    val.toString(),
                    style: GoogleFonts.poppins(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: AppPallete.textPrimary,
                      letterSpacing: -1,
                    ),
                  );
                },
              ),
              Text(
                title,
                style: TextStyle(
                  color: AppPallete.textSecondary.withValues(alpha: 0.7),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        )
        .animate(delay: (index * 100).ms)
        .fadeIn()
        .scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOutBack);
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    VoidCallback onTap,
    int index,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        borderRadius: BorderRadius.circular(16),
        blur: 10,
        opacity: 0.05,
        color: AppPallete.surface,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppPallete.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppPallete.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppPallete.textPrimary,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppPallete.textSecondary,
              size: 16,
            ),
          ],
        ),
      ),
    ).animate(delay: (index * 100).ms).fadeIn().slideX(begin: 0.1);
  }
}
