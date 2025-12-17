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
              // Dark theme picker
              primary: AppPallete.primary,
              onPrimary: Colors.white,
              surface: AppPallete.surface,
              onSurface: Colors.white,
            ),
            dialogTheme: DialogThemeData(backgroundColor: AppPallete.surface),
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
                color: AppPallete.secondary.withValues(alpha: 0.2),
                boxShadow: [
                  BoxShadow(
                    color: AppPallete.secondary.withValues(alpha: 0.2),
                    blurRadius: 100,
                    spreadRadius: 50,
                  ),
                ],
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
                            fontSize: 32,
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
                              AuthField(
                                hintText: 'Full Name',
                                controller: nameController,
                              ),
                              const SizedBox(height: 15),

                              AuthField(
                                hintText: 'Email',
                                controller: emailController,
                              ),
                              const SizedBox(height: 15),

                              GestureDetector(
                                onTap: () => _selectDate(context),
                                child: AbsorbPointer(
                                  child: AuthField(
                                    hintText: 'DOB (DD/MM/YYYY)',
                                    controller: dobController,
                                    suffixIcon: const Padding(
                                      padding: EdgeInsets.all(12.0),
                                      child: Icon(
                                        Icons.calendar_month,
                                        color: AppPallete.primary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 15),

                              AuthField(
                                hintText: 'Password',
                                controller: passwordController,
                                isObscureText: _isPasswordObscure,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordObscure
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: AppPallete.textSecondary,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isPasswordObscure = !_isPasswordObscure;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(height: 15),

                              AuthField(
                                hintText: 'Confirm Password',
                                controller: confirmPasswordController,
                                isObscureText: _isConfirmPasswordObscure,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isConfirmPasswordObscure
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: AppPallete.textSecondary,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isConfirmPasswordObscure =
                                          !_isConfirmPasswordObscure;
                                    });
                                  },
                                ),
                              ),

                              const SizedBox(height: 20),

                              AuthGradientButton(
                                buttonText: 'Sign Up',
                                onPressed: () async {
                                  final name = nameController.text.trim();
                                  final email = emailController.text.trim();
                                  final password = passwordController.text
                                      .trim();
                                  final confirm = confirmPasswordController.text
                                      .trim();

                                  if (name.isEmpty ||
                                      email.isEmpty ||
                                      password.isEmpty ||
                                      confirm.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Please fill all fields"),
                                      ),
                                    );
                                    return;
                                  }

                                  if (password != confirm) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Passwords do not match!",
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  final authRepo = AuthRepositoryImpl(
                                    AuthRemoteDataSourceImpl(
                                      Supabase.instance.client,
                                    ),
                                  );

                                  try {
                                    await authRepo.signUpWithEmailPassword(
                                      email: email,
                                      password: password,
                                      name: name,
                                    );
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Account Created! Please Sign In.",
                                          ),
                                        ),
                                      );
                                      Navigator.pop(context);
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(content: Text("Error: $e")),
                                      );
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 400.ms)
                        .scale(begin: const Offset(0.9, 0.9)),

                    const SizedBox(height: 20),

                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: RichText(
                        text: TextSpan(
                          text: 'Already have an account? ',
                          style: TextStyle(color: AppPallete.textSecondary),
                          children: [
                            TextSpan(
                              text: 'Login',
                              style: TextStyle(
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
