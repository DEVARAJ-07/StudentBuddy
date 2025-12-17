import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_pallete.dart';
import '../../../../core/common/widgets/glass_container.dart';
import 'package:student_buddy/features/mentor/presentation/pages/mentor_chat_page.dart';

class CreateMentorDialog extends StatefulWidget {
  const CreateMentorDialog({super.key});

  @override
  State<CreateMentorDialog> createState() => _CreateMentorDialogState();
}

class _CreateMentorDialogState extends State<CreateMentorDialog> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

  // Form Data
  String? _selectedDomain;
  final TextEditingController _customDomainController = TextEditingController();
  String? _selectedExperience;
  String? _selectedFocus;
  String? _selectedGuidance;
  String? _selectedPace;
  final TextEditingController _additionalContextController =
      TextEditingController();

  final int _totalQuestions = 6;

  void _nextPage() {
    if (_currentPage < _totalQuestions - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _submitMentorCreation();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _submitMentorCreation() async {
    setState(() => _isLoading = true);

    try {
      final domain = _selectedDomain == "Other"
          ? _customDomainController.text
          : _selectedDomain;

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception("User not logged in");

      final response = await Supabase.instance.client
          .from('mentor_creations')
          .insert({
            'user_id': user.id,
            'name': "$domain Mentor", // Auto-generate name for now
            'domain': domain,
            'experience_level': _selectedExperience,
            'learning_focus': _selectedFocus,
            'guidance_style': _selectedGuidance,
            'learning_pace': _selectedPace,
            'additional_context': _additionalContextController.text,
          })
          .select()
          .single();

      if (mounted) {
        Navigator.pop(context); // Close dialog
        // Navigate to Chat
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MentorChatPage(mentorData: response),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error creating mentor: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: GlassContainer(
        borderRadius: BorderRadius.circular(24),
        blur: 20,
        opacity: 0.1,
        color: AppPallete.surface,
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        child: Container(
          height: 600, // Fixed height for constraints
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  if (_currentPage > 0)
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: AppPallete.textSecondary,
                      ),
                      onPressed: _previousPage,
                    ),
                  Expanded(
                    child: Text(
                      "Create Your Mentor",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppPallete.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: AppPallete.textSecondary,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Progress Bar
              LinearProgressIndicator(
                value: (_currentPage + 1) / _totalQuestions,
                backgroundColor: Colors.white10,
                color: AppPallete.primary,
                minHeight: 4,
                borderRadius: BorderRadius.circular(2),
              ),

              const SizedBox(height: 20),

              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  children: [
                    _buildQuestionStep(
                      "Question 1: Domain Selection",
                      "Which domain do you want mentorship in?",
                      _buildRadioOptions(
                        [
                          "Programming",
                          "Operating Systems",
                          "Database Management Systems",
                          "Computer Networks",
                          "Web Development",
                          "Other",
                        ],
                        _selectedDomain,
                        (val) => setState(() => _selectedDomain = val),
                      ),
                      extraInput: _selectedDomain == "Other"
                          ? _buildTextInput(
                              "Specify Domain",
                              _customDomainController,
                            )
                          : null,
                    ),
                    _buildQuestionStep(
                      "Question 2: Experience Level",
                      "What is your current experience level in this domain?",
                      _buildRadioOptions(
                        ["Beginner", "Intermediate", "Advanced"],
                        _selectedExperience,
                        (val) => setState(() => _selectedExperience = val),
                      ),
                    ),
                    _buildQuestionStep(
                      "Question 3: Learning Focus",
                      "What is your primary learning focus?",
                      _buildRadioOptions(
                        [
                          "Understanding core concepts",
                          "Building practical skills or projects",
                          "Exam or interview preparation",
                          "Revision and improvement",
                        ],
                        _selectedFocus,
                        (val) => setState(() => _selectedFocus = val),
                      ),
                    ),
                    _buildQuestionStep(
                      "Question 4: Guidance Style",
                      "How would you like your mentor to guide you?",
                      _buildRadioOptions(
                        [
                          "Step-by-step explanations",
                          "Practice-based and problem-solving guidance",
                          "Project-oriented mentoring",
                          "A balanced combination of all",
                        ],
                        _selectedGuidance,
                        (val) => setState(() => _selectedGuidance = val),
                      ),
                    ),
                    _buildQuestionStep(
                      "Question 5: Learning Pace",
                      "How do you want your learning pace to be planned?",
                      _buildRadioOptions(
                        [
                          "Slow and detailed",
                          "Moderate and balanced",
                          "Fast and goal-driven",
                          "Adaptive based on my performance",
                        ],
                        _selectedPace,
                        (val) => setState(() => _selectedPace = val),
                      ),
                    ),
                    _buildQuestionStep(
                      "Optional Question 6: Additional Requirements",
                      "Any specific goals or challenges you want the mentor to focus on?",
                      const SizedBox.shrink(),
                      extraInput: _buildTextInput(
                        "e.g. Preparing for exams, struggling with basics...",
                        _additionalContextController,
                        maxLines: 4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppPallete.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _currentPage == _totalQuestions - 1
                              ? "Create Mentor"
                              : "Next",
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack),
    );
  }

  Widget _buildQuestionStep(
    String title,
    String question,
    Widget content, {
    Widget? extraInput,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppPallete.primary,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          question,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppPallete.textPrimary,
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                content,
                if (extraInput != null) ...[
                  const SizedBox(height: 15),
                  extraInput,
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRadioOptions(
    List<String> options,
    String? groupValue,
    Function(String) onChanged,
  ) {
    return Column(
      children: options.map((option) {
        final isSelected = groupValue == option;
        return GestureDetector(
          onTap: () => onChanged(option),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppPallete.primary.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppPallete.primary : Colors.white10,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: isSelected
                      ? AppPallete.primary
                      : AppPallete.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    option,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : AppPallete.textSecondary,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTextInput(
    String hint,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
        filled: true,
        fillColor: Colors.black26,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
    );
  }
}
