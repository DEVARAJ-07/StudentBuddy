import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_pallete.dart';
import '../../../../core/common/widgets/glass_container.dart';
import 'package:student_buddy/features/mentor/presentation/widgets/create_mentor_dialog.dart';
import 'package:student_buddy/features/mentor/presentation/pages/mentor_chat_page.dart';

class MentorsPage extends StatefulWidget {
  const MentorsPage({super.key});

  @override
  State<MentorsPage> createState() => _MentorsPageState();
}

class _MentorsPageState extends State<MentorsPage> {
  final _supabase = Supabase.instance.client;

  Stream<List<Map<String, dynamic>>> _getMentorsStream() {
    return _supabase
        .from('mentor_creations')
        .stream(primaryKey: ['id'])
        .order('created_at')
        .map((data) => List<Map<String, dynamic>>.from(data));
  }

  void _showCreateMentorDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (context) => const CreateMentorDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "My Mentors",
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppPallete.textPrimary,
                ),
              ).animate().fadeIn().slideX(begin: -0.2),

              const SizedBox(height: 20),

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
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          "Error loading mentors: ${snapshot.error}",
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    }

                    final mentors = snapshot.data ?? [];

                    return GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.85,
                            crossAxisSpacing: 15,
                            mainAxisSpacing: 15,
                          ),
                      itemCount:
                          mentors.length + 1, // +1 for the "Add New" card
                      itemBuilder: (context, index) {
                        // The first item is the "Add New Mentor" button
                        if (index == 0) {
                          return _buildAddMentorCard();
                        }

                        final mentor = mentors[index - 1];
                        return _buildMentorCard(mentor);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddMentorCard() {
    return GestureDetector(
      onTap: _showCreateMentorDialog,
      child: GlassContainer(
        borderRadius: BorderRadius.circular(20),
        blur: 10,
        opacity: 0.05,
        color: AppPallete.primary.withValues(alpha: 0.1),
        border: Border.all(
          color: AppPallete.primary.withValues(alpha: 0.3),
          width: 2,
          style: BorderStyle.solid,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppPallete.primary.withValues(alpha: 0.2),
              ),
              child: const Icon(Icons.add, color: AppPallete.primary, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              "New Mentor",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: AppPallete.textPrimary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ).animate().scale(delay: 100.ms),
    );
  }

  Widget _buildMentorCard(Map<String, dynamic> mentor) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MentorChatPage(mentorData: mentor),
          ),
        );
      },
      child: GlassContainer(
        borderRadius: BorderRadius.circular(20),
        blur: 10, // Use constant blur
        opacity: 0.05,
        color: AppPallete.surface,
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppPallete.primary, AppPallete.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const Spacer(),
              Text(
                mentor['name'] ?? 'Mentor',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: AppPallete.textPrimary,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                mentor['domain'] ?? 'General',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: AppPallete.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ).animate().fadeIn(),
    );
  }
}
