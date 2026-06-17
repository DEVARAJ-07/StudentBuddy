import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_pallete.dart';
import 'package:student_buddy/features/mentor/presentation/widgets/create_mentor_dialog.dart';
import 'package:student_buddy/features/mentor/presentation/pages/mentor_chat_page.dart';

class MentorsPage extends StatefulWidget {
  const MentorsPage({super.key});

  @override
  State<MentorsPage> createState() => _MentorsPageState();
}

class _MentorsPageState extends State<MentorsPage> {
  final _supabase = Supabase.instance.client;
  bool _isOpeningMentor = false; // Prevent multiple opens during swipe

  String? get _userId => _supabase.auth.currentUser?.id;

  Stream<List<Map<String, dynamic>>> _getMentorsStream() {
    final userId = _userId;
    if (userId == null) {
      return Stream.value([]);
    }
    return _supabase
        .from('mentor_creations')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at')
        .map((data) => List<Map<String, dynamic>>.from(data));
  }

  void _showCreateMentorDialog() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (context) => const CreateMentorDialog(),
    );
  }

  void _openMentor(Map<String, dynamic> mentor) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            MentorChatPage(mentorData: mentor),
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
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [AppPallete.primary, AppPallete.secondary],
                ).createShader(bounds),
                child: Text(
                  "Mentors",
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ).animate().fadeIn().slideX(begin: -0.1),

            const SizedBox(height: 24),

            // New Mentor Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildNewMentorCard(),
            ),

            const SizedBox(height: 28),

            // Available Mentors Section Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppPallete.secondary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: AppPallete.secondary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Available Mentors",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppPallete.textPrimary,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 16),

            // Mentors List
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _getMentorsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppPallete.primary,
                      ),
                    );
                  }

                  final mentors = snapshot.data ?? [];

                  if (mentors.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    physics: const BouncingScrollPhysics(),
                    itemCount: mentors.length,
                    itemBuilder: (context, index) {
                      return _buildMentorTile(mentors[index], index);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewMentorCard() {
    return GestureDetector(
      onTap: _showCreateMentorDialog,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppPallete.primary.withValues(alpha: 0.15),
              AppPallete.secondary.withValues(alpha: 0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppPallete.primary.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppPallete.primaryGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppPallete.primary.withValues(alpha: 0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Create New Mentor",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppPallete.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Add a personalized AI mentor for any subject",
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppPallete.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppPallete.primary,
              size: 20,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1);
  }

  Widget _buildMentorTile(Map<String, dynamic> mentor, int index) {
    final name = mentor['name'] ?? 'Mentor';
    final domain = mentor['domain'] ?? 'General';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Dismissible(
        key: Key(mentor['id'].toString()),
        direction: DismissDirection.endToStart,
        confirmDismiss: (direction) async =>
            false, // Don't actually delete, just open
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            gradient: AppPallete.primaryGradient,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.chat_rounded, color: Colors.white, size: 24),
              const SizedBox(height: 4),
              Text(
                'Open',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        onUpdate: (details) {
          // CONSISTENT NAVIGATION GUARD
          if (details.progress > 0.4 &&
              details.direction == DismissDirection.endToStart &&
              !_isOpeningMentor) {
            _isOpeningMentor = true;
            _openMentor(mentor);
            // Reset flag after a reasonable delay to allow pop/back stability
            Future.delayed(const Duration(seconds: 1), () {
              if (mounted) setState(() => _isOpeningMentor = false);
            });
          }
        },
        child: GestureDetector(
          onTap: () {
            if (!_isOpeningMentor) {
              _isOpeningMentor = true;
              _openMentor(mentor);
              Future.delayed(const Duration(seconds: 1), () {
                if (mounted) setState(() => _isOpeningMentor = false);
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppPallete.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppPallete.primary, AppPallete.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 26,
                  ),
                ),

                const SizedBox(width: 16),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppPallete.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppPallete.secondary.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              domain,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppPallete.secondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Swipe hint
                Column(
                  children: [
                    Icon(
                      Icons.swipe_left_rounded,
                      color: AppPallete.textSecondary.withValues(alpha: 0.5),
                      size: 20,
                    ),
                    Text(
                      'Swipe',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        color: AppPallete.textSecondary.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate(delay: (250 + index * 50).ms).fadeIn().slideX(begin: 0.05);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppPallete.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.school_rounded,
              color: AppPallete.textSecondary,
              size: 48,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No mentors yet',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppPallete.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first AI mentor to start learning',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppPallete.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
