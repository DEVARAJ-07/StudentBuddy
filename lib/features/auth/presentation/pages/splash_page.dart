import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_pallete.dart';

class SplashPage extends StatefulWidget {
  final VoidCallback? onFinish;
  final bool showLoadingDots;

  const SplashPage({
    super.key,
    this.onFinish,
    this.showLoadingDots = true,
  });

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _orbitalController;
  late AnimationController _textController;

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _orbitalController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    Future.delayed(const Duration(milliseconds: 3800), () {
      if (mounted && widget.onFinish != null) {
        widget.onFinish!();
      }
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _orbitalController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppPallete.background,
      body: Stack(
        children: [
          // Deep space gradient background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.5,
                  colors: [
                    Color(0xFF0D0D2B),
                    Color(0xFF050510),
                  ],
                ),
              ),
            ),
          ),

          // Animated starfield
          ...List.generate(40, (i) {
            final rand = Random(i * 7 + 3);
            final x = rand.nextDouble() * size.width;
            final y = rand.nextDouble() * size.height;
            final s = rand.nextDouble() * 2.5 + 0.5;
            final delay = rand.nextInt(2000);
            return Positioned(
              left: x,
              top: y,
              child: Container(
                width: s,
                height: s,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .fadeIn(
                    delay: Duration(milliseconds: delay),
                    duration: Duration(milliseconds: 800 + rand.nextInt(1200)),
                  )
                  .fadeOut(duration: 800.ms),
            );
          }),

          // Outer glow ring (slow rotation)
          Center(
            child: AnimatedBuilder(
              animation: _rotationController,
              builder: (_, __) => Transform.rotate(
                angle: _rotationController.value * 2 * pi,
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppPallete.primary.withValues(alpha: 0.15),
                      width: 1,
                    ),
                    gradient: SweepGradient(
                      colors: [
                        Colors.transparent,
                        AppPallete.primary.withValues(alpha: 0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Inner orbit ring (reverse rotation)
          Center(
            child: AnimatedBuilder(
              animation: _orbitalController,
              builder: (_, __) => Transform.rotate(
                angle: -_orbitalController.value * 2 * pi,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppPallete.secondary.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Orbital dot
                      Positioned(
                        top: 4,
                        left: 95,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppPallete.secondary,
                            boxShadow: [
                              BoxShadow(
                                color: AppPallete.secondary.withValues(alpha: 0.8),
                                blurRadius: 12,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Pulsing center glow
          Center(
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (_, __) => Container(
                width: 140 + _pulseController.value * 20,
                height: 140 + _pulseController.value * 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppPallete.primary.withValues(
                          alpha: 0.25 + _pulseController.value * 0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Center logo
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon container
                Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppPallete.primaryGradient,
                        boxShadow: [
                          BoxShadow(
                            color: AppPallete.primary.withValues(alpha: 0.6),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        size: 52,
                        color: Colors.white,
                      ),
                    )
                    .animate()
                    .scale(
                      begin: const Offset(0.2, 0.2),
                      end: const Offset(1.0, 1.0),
                      duration: 900.ms,
                      curve: Curves.easeOutBack,
                    )
                    .fadeIn(duration: 600.ms),

                const SizedBox(height: 28),

                // App name
                ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [AppPallete.primary, AppPallete.secondary],
                      ).createShader(bounds),
                      child: Text(
                        'StudentBuddy',
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.0,
                        ),
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 500.ms, duration: 700.ms)
                    .slideY(
                      begin: 0.3,
                      end: 0,
                      delay: 500.ms,
                      duration: 700.ms,
                      curve: Curves.easeOut,
                    ),

                const SizedBox(height: 8),

                Text(
                      'Your AI-Powered Learning Companion',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppPallete.textSecondary,
                        letterSpacing: 0.3,
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 900.ms, duration: 600.ms)
                    .slideY(
                      begin: 0.2,
                      end: 0,
                      delay: 900.ms,
                      duration: 600.ms,
                    ),

                const SizedBox(height: 60),

                // Loading dots (visible only if requested)
                if (widget.showLoadingDots)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppPallete.primary.withValues(alpha: 0.8),
                      ),
                    )
                        .animate(
                          onPlay: (c) => c.repeat(reverse: true),
                        )
                        .scaleXY(
                          begin: 0.5,
                          end: 1.5,
                          delay: Duration(milliseconds: 200 * i + 1200),
                          duration: 500.ms,
                          curve: Curves.easeInOut,
                        )
                        .fadeIn(delay: Duration(milliseconds: 200 * i + 1200));
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
