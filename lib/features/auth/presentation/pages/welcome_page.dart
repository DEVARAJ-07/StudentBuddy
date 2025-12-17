import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui'; // For ImageFilter
import '../widgets/slide_action_button.dart';
import '../widgets/animated_background.dart';
import '../widgets/neural_hologram.dart';
import 'login_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Full Screen Immersion
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      extendBodyBehindAppBar: true, // Full screen
      backgroundColor: Colors.black, // Fallback
      body: Stack(
        children: [
          // 2. Animated Starfield Background (Canvas Painted)
          const Positioned.fill(child: AnimatedBackground()),

          // 3. 3D Background Animations (Floating Glowing Orbs)
          // Top glow
          Positioned(
            top: -100,
            left: -100,
            child:
                Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF6A11CB).withValues(alpha: 0.3),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF6A11CB,
                            ).withValues(alpha: 0.3),
                            blurRadius: 100,
                            spreadRadius: 50,
                          ),
                        ],
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.2, 1.2),
                      duration: 4.seconds,
                    ),
          ),
          // Bottom glow
          Positioned(
            bottom: -50,
            right: -50,
            child:
                Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF2575FC).withValues(alpha: 0.2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF2575FC,
                            ).withValues(alpha: 0.2),
                            blurRadius: 100,
                            spreadRadius: 40,
                          ),
                        ],
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .moveY(begin: 0, end: 50, duration: 5.seconds),
          ),

          // 4. "Glassy" Foreground Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  const Spacer(),

                  // Holographic Neural Logo (Replaces Image)
                  Hero(
                        tag: 'app_logo',
                        child: SizedBox(
                          height: 300,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [const NeuralHologram(size: 250)],
                          ),
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .moveY(
                        begin: -10,
                        end: 10,
                        duration: 3.seconds,
                        curve: Curves.easeInOut,
                      )
                      .scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.02, 1.02),
                        duration: 4.seconds,
                      )
                      .animate()
                      .fadeIn(),

                  const SizedBox(height: 40),

                  // Glassy Card for Text
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(
                            alpha: 0.05,
                          ), // Super transparent white
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              "Study with the\nStudentBuddy AI",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Never study alone again.\nYour AI friend is by your side.",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.7),
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ).animate().slideY(begin: 0.2, duration: 600.ms).fadeIn(),

                  const Spacer(),

                  // Slide Action Button (Wrapper for Spacing)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: SlideActionButton(
                      onSlideComplete: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginPage(),
                          ),
                        );
                      },
                    ),
                  ).animate().slideY(
                    begin: 1,
                    duration: 600.ms,
                    curve: Curves.easeOutBack,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
