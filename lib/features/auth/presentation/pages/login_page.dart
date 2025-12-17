import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_pallete.dart';
import '../../../../core/common/widgets/glass_container.dart';
import '../widgets/auth_field.dart';
import '../widgets/auth_gradient_button.dart';
import '../../../home/presentation/pages/student_dashboard.dart';
import '../../../admin/presentation/pages/admin_dashboard.dart';
import 'signup_page.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/datasources/auth_remote_data_source.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  late final authRepo = AuthRepositoryImpl(
    AuthRemoteDataSourceImpl(Supabase.instance.client),
  );

  bool _isObscure = true;

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
  }

  void _setupAuthListener() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      if (data.event == AuthChangeEvent.signedIn) {
        if (!mounted) return;
        final userId = data.session?.user.id;
        if (userId != null) {
          _checkRoleAndRedirect(userId);
        }
      }
    });
  }

  Future<void> _checkRoleAndRedirect(String userId) async {
    final role = await authRepo.getUserRole(userId);
    if (!mounted) return;

    if (role == 'admin' || role == 'super_admin') {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const AdminDashboard()),
        (route) => false,
      );
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const StudentDashboard()),
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      await authRepo.signInWithGoogle();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Login Failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPallete.background, // Dark Theme
      body: Stack(
        children: [
          // Ambient Background Glows
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppPallete.primary.withValues(alpha: 0.2),
                boxShadow: [
                  BoxShadow(
                    color: AppPallete.primary.withValues(alpha: 0.2),
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
                    // Brand Logo/Title Row
                    Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Replace with Icon if image not available or keep image if transparent
                            const Icon(
                              Icons.auto_awesome,
                              color: AppPallete.primary,
                              size: 40,
                            ),
                            const SizedBox(width: 15),
                            Text(
                              'StudentBuddy',
                              style: GoogleFonts.poppins(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppPallete.textPrimary,
                              ),
                            ),
                          ],
                        )
                        .animate()
                        .fadeIn(duration: 600.ms)
                        .slideY(begin: -0.3, end: 0),

                    const SizedBox(height: 10),

                    Text(
                          'Your Personal AI Mentor',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: AppPallete.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 200.ms)
                        .slideY(begin: -0.2, end: 0),

                    const SizedBox(height: 40),

                    // Glass Card
                    GlassContainer(
                          padding: const EdgeInsets.all(24),
                          borderRadius: BorderRadius.circular(24),
                          blur: 20,
                          opacity: 0.05, // Dark glass
                          color: AppPallete.surface,
                          child: Column(
                            children: [
                              AuthField(
                                hintText: 'Email',
                                controller: emailController,
                              ),
                              const SizedBox(height: 15),
                              AuthField(
                                hintText: 'Password',
                                controller: passwordController,
                                isObscureText: _isObscure,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isObscure
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: AppPallete.textSecondary,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isObscure = !_isObscure;
                                    });
                                  },
                                ),
                              ),

                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {},
                                  child: Text(
                                    "Forgot Password?",
                                    style: GoogleFonts.inter(
                                      color: AppPallete.primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 10),

                              AuthGradientButton(
                                buttonText: 'Sign In',
                                onPressed: () async {
                                  final email = emailController.text.trim();
                                  final password = passwordController.text
                                      .trim();

                                  if (email.isEmpty || password.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Please enter Email and Password",
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  try {
                                    await authRepo.signInWithEmailPassword(
                                      email: email,
                                      password: password,
                                    );
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Error: ${e.toString()}',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),

                              const SizedBox(height: 30),

                              Row(
                                children: const [
                                  Expanded(
                                    child: Divider(color: Colors.white24),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    child: Text(
                                      "OR",
                                      style: TextStyle(color: Colors.white54),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(color: Colors.white24),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              _SocialLoginButton(
                                text: "Continue with Google",
                                iconPath: 'assets/images/google.png',
                                onTap: _handleGoogleSignIn,
                              ),
                              const SizedBox(height: 15),
                            ],
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 400.ms)
                        .scale(begin: const Offset(0.9, 0.9)),

                    const SizedBox(height: 20),

                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignupPage(),
                          ),
                        );
                      },
                      child: RichText(
                        text: TextSpan(
                          text: 'Don\'t have an account? ',
                          style: TextStyle(color: AppPallete.textSecondary),
                          children: [
                            TextSpan(
                              text: 'Sign Up',
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

class _SocialLoginButton extends StatefulWidget {
  final String text;
  final String iconPath;
  final VoidCallback onTap;

  const _SocialLoginButton({
    required this.text,
    required this.iconPath,
    required this.onTap,
  });

  @override
  State<_SocialLoginButton> createState() => _SocialLoginButtonState();
}

class _SocialLoginButtonState extends State<_SocialLoginButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(30),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: _isHovered
                ? AppPallete.primary.withValues(alpha: 0.1)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: _isHovered ? AppPallete.primary : Colors.white24,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ensure asset exists or use Icon as fallback
              // Image.asset(widget.iconPath, width: 24, height: 24),
              const Icon(
                Icons.g_mobiledata,
                color: Colors.white,
                size: 28,
              ), // Temp fallback
              const SizedBox(width: 15),
              Text(
                widget.text,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: AppPallete.textPrimary,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
