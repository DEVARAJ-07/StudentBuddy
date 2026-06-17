import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_pallete.dart';
import '../../../../core/common/widgets/glass_container.dart';
import '../widgets/auth_field.dart';
import '../widgets/auth_gradient_button.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isNewPasswordObscure = true;
  bool _isConfirmPasswordObscure = true;
  bool _passwordReset = false;

  @override
  void dispose() {
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!formKey.currentState!.validate()) return;

    if (newPasswordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPasswordController.text),
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _passwordReset = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
            top: -80,
            right: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppPallete.primary.withValues(alpha: 0.15),
                boxShadow: [
                  BoxShadow(
                    color: AppPallete.primary.withValues(alpha: 0.15),
                    blurRadius: 80,
                    spreadRadius: 40,
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
                    // Icon
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _passwordReset
                            ? AppPallete.success.withValues(alpha: 0.15)
                            : AppPallete.primary.withValues(alpha: 0.15),
                      ),
                      child: Icon(
                        _passwordReset
                            ? Icons.check_circle_rounded
                            : Icons.lock_outline_rounded,
                        color: _passwordReset
                            ? AppPallete.success
                            : AppPallete.primary,
                        size: 50,
                      ),
                    ).animate().scale(
                      duration: 500.ms,
                      curve: Curves.elasticOut,
                    ),

                    const SizedBox(height: 30),

                    // Title
                    Text(
                      _passwordReset ? 'Password Updated!' : 'Reset Password',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppPallete.textPrimary,
                      ),
                    ).animate().fadeIn(delay: 100.ms).slideY(begin: -0.2),

                    const SizedBox(height: 12),

                    Text(
                      _passwordReset
                          ? 'Your password has been successfully updated. You can now login with your new password.'
                          : 'Enter your new password below.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppPallete.textSecondary,
                        height: 1.5,
                      ),
                    ).animate().fadeIn(delay: 200.ms),

                    const SizedBox(height: 40),

                    if (!_passwordReset) ...[
                      // Glass Card for password reset
                      GlassContainer(
                            padding: const EdgeInsets.all(24),
                            borderRadius: BorderRadius.circular(24),
                            blur: 20,
                            opacity: 0.05,
                            color: AppPallete.surface,
                            child: Column(
                              children: [
                                AuthField(
                                  hintText: 'New Password',
                                  controller: newPasswordController,
                                  isObscureText: _isNewPasswordObscure,
                                  prefixIcon: const Icon(
                                    Icons.lock_outline_rounded,
                                    color: AppPallete.textSecondary,
                                    size: 22,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isNewPasswordObscure
                                          ? Icons.visibility_off_rounded
                                          : Icons.visibility_rounded,
                                      color: AppPallete.textSecondary,
                                    ),
                                    onPressed: () {
                                      setState(
                                        () => _isNewPasswordObscure =
                                            !_isNewPasswordObscure,
                                      );
                                    },
                                  ),
                                  validator: AuthField.passwordValidator,
                                ),

                                const SizedBox(height: 16),

                                AuthField(
                                  hintText: 'Confirm New Password',
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
                                      return "Please confirm your password";
                                    }
                                    if (value != newPasswordController.text) {
                                      return "Passwords do not match";
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 24),

                                AuthGradientButton(
                                  buttonText: _isLoading
                                      ? 'Resetting...'
                                      : 'Reset Password',
                                  onPressed: _isLoading
                                      ? null
                                      : () => _resetPassword(),
                                ),
                              ],
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 300.ms)
                          .scale(begin: const Offset(0.95, 0.95)),
                    ] else ...[
                      // Success state
                      GlassContainer(
                        padding: const EdgeInsets.all(24),
                        borderRadius: BorderRadius.circular(24),
                        blur: 20,
                        opacity: 0.05,
                        color: AppPallete.surface,
                        child: Column(
                          children: [
                            AuthGradientButton(
                              buttonText: 'Go to Login',
                              onPressed: () {
                                Navigator.popUntil(
                                  context,
                                  (route) => route.isFirst,
                                );
                              },
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 300.ms),
                    ],
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
