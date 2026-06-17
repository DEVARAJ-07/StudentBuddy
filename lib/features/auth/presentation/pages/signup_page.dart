import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_pallete.dart';
import '../../../../core/common/widgets/glass_container.dart';
import '../widgets/auth_field.dart';
import '../widgets/auth_gradient_button.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/datasources/auth_remote_data_source.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final dobController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool _isPasswordObscure = true;
  bool _isConfirmPasswordObscure = true;
  bool _isLoading = false;
  String _selectedGender = 'male';

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    dobController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 15)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppPallete.primary,
              onPrimary: Colors.white,
              surface: AppPallete.surface,
              onSurface: Colors.white,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: AppPallete.surface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        dobController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  Future<void> _handleSignUp() async {
    if (!formKey.currentState!.validate()) return;

    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authRepo = AuthRepositoryImpl(
        AuthRemoteDataSourceImpl(Supabase.instance.client),
      );

      await authRepo.signUpWithEmailPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        name: nameController.text.trim(),
        gender: _selectedGender,
        dob: dobController.text.trim(),
      );

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account Created! Please Sign In.'),
            backgroundColor: AppPallete.success,
          ),
        );
        Navigator.pop(context);
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        String msg = e.message;
        if (msg.toLowerCase().contains('already registered') || e.statusCode == '422') {
          msg = 'This email is already registered. Please Login or use another email.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An unexpected error occurred: $e'),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Widget _buildGenderOption(String title, String value, IconData icon) {
    final isSelected = _selectedGender == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedGender = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppPallete.primary.withValues(alpha: 0.2) : AppPallete.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppPallete.primary : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? AppPallete.primary : AppPallete.textSecondary, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.inter(
                color: isSelected ? AppPallete.primary : AppPallete.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPallete.background,
      body: Stack(
        children: [
          // Ambient Background Glows
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppPallete.secondary.withValues(alpha: 0.15),
                boxShadow: [
                  BoxShadow(
                    color: AppPallete.secondary.withValues(alpha: 0.15),
                    blurRadius: 100,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            bottom: -80,
            right: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppPallete.primary.withValues(alpha: 0.1),
                boxShadow: [
                  BoxShadow(
                    color: AppPallete.primary.withValues(alpha: 0.1),
                    blurRadius: 80,
                    spreadRadius: 40,
                  ),
                ],
              ),
            ),
          ),

          // Back button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppPallete.surface.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppPallete.textPrimary,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Title
                    Text(
                          'Create Account',
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppPallete.textPrimary,
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 600.ms)
                        .slideY(begin: -0.3, end: 0),

                    const SizedBox(height: 10),

                    Text(
                          'Join StudentBuddy Today',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: AppPallete.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 200.ms)
                        .slideY(begin: -0.2, end: 0),

                    const SizedBox(height: 30),

                    // Glassmorphism Card
                    GlassContainer(
                          padding: const EdgeInsets.all(24),
                          borderRadius: BorderRadius.circular(24),
                          blur: 20,
                          opacity: 0.05,
                          color: AppPallete.surface,
                          child: Column(
                            children: [
                              // Full Name
                              AuthField(
                                hintText: 'Full Name',
                                controller: nameController,
                                prefixIcon: const Icon(
                                  Icons.person_outline_rounded,
                                  color: AppPallete.textSecondary,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Email
                              AuthField(
                                hintText: 'Email',
                                controller: emailController,
                                keyboardType: TextInputType.emailAddress,
                                prefixIcon: const Icon(
                                  Icons.mail_outline_rounded,
                                  color: AppPallete.textSecondary,
                                  size: 22,
                                ),
                                validator: AuthField.emailValidator,
                              ),
                              const SizedBox(height: 16),

                              // Date of Birth
                              GestureDetector(
                                onTap: () => _selectDate(context),
                                child: AbsorbPointer(
                                  child: AuthField(
                                    hintText: 'Date of Birth',
                                    controller: dobController,
                                    prefixIcon: const Icon(
                                      Icons.calendar_month_rounded,
                                      color: AppPallete.textSecondary,
                                      size: 22,
                                    ),
                                    suffixIcon: const Icon(
                                      Icons.arrow_drop_down_rounded,
                                      color: AppPallete.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Gender Selection
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildGenderOption('Male', 'male', Icons.male_rounded),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildGenderOption('Female', 'female', Icons.female_rounded),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Password
                              AuthField(
                                hintText: 'Password',
                                controller: passwordController,
                                isObscureText: _isPasswordObscure,
                                prefixIcon: const Icon(
                                  Icons.lock_outline_rounded,
                                  color: AppPallete.textSecondary,
                                  size: 22,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordObscure
                                        ? Icons.visibility_off_rounded
                                        : Icons.visibility_rounded,
                                    color: AppPallete.textSecondary,
                                  ),
                                  onPressed: () {
                                    setState(
                                      () => _isPasswordObscure =
                                          !_isPasswordObscure,
                                    );
                                  },
                                ),
                                validator: AuthField.passwordValidator,
                              ),
                              const SizedBox(height: 16),

                              // Confirm Password
                              AuthField(
                                hintText: 'Confirm Password',
                                controller: confirmPasswordController,
                                isObscureText: _isConfirmPasswordObscure,
                                prefixIcon: const Icon(
                                  Icons.lock_outline_rounded,
                                  color: AppPallete.textSecondary,
                                  size: 22,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isConfirmPasswordObscure
                                        ? Icons.visibility_off_rounded
                                        : Icons.visibility_rounded,
                                    color: AppPallete.textSecondary,
                                  ),
                                  onPressed: () {
                                    setState(
                                      () => _isConfirmPasswordObscure =
                                          !_isConfirmPasswordObscure,
                                    );
                                  },
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please confirm your password';
                                  }
                                  if (value != passwordController.text) {
                                    return 'Passwords do not match';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 24),

                              // Sign Up Button
                              AuthGradientButton(
                                buttonText: _isLoading
                                    ? 'Creating Account...'
                                    : 'Sign Up',
                                onPressed: _isLoading ? null : _handleSignUp,
                              ),
                            ],
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 400.ms)
                        .scale(begin: const Offset(0.95, 0.95)),

                    const SizedBox(height: 24),

                    // Login Link
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: RichText(
                        text: TextSpan(
                          text: 'Already have an account? ',
                          style: GoogleFonts.inter(
                            color: AppPallete.textSecondary,
                          ),
                          children: [
                            TextSpan(
                              text: 'Login',
                              style: GoogleFonts.inter(
                                color: AppPallete.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: 600.ms),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
