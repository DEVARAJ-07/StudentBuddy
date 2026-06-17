import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_pallete.dart';

/// A premium 3D animated background with aurora effects.
/// Optimized for performance with reduced animations.
class AnimatedBackground extends StatelessWidget {
  final Widget child;
  final bool showGrid;

  const AnimatedBackground({
    super.key,
    required this.child,
    this.showGrid = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // Background Base with theme-aware gradient
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        const Color(0xFF0B0F19),
                        const Color(0xFF0D1117),
                        const Color(0xFF0B0F19),
                      ]
                    : [
                        const Color(0xFFF1F5F9), // Light Grey-White
                        const Color(0xFFF8FAFC),
                        const Color(0xFFF1F5F9),
                      ],
              ),
            ),
          ),
        ),

        // Aurora Glow 1 (Top Left)
        Positioned(
          top: -100,
          left: -100,
          child: Animate(
            onPlay: (controller) => controller.repeat(reverse: true),
            effects: [FadeEffect(begin: 0.4, end: 0.8, duration: 6.seconds)],
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    (isDark ? AppPallete.primary : AppPallete.lightPrimary)
                        .withValues(alpha: isDark ? 0.2 : 0.1),
                    (isDark ? AppPallete.primary : AppPallete.lightPrimary)
                        .withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
        ),

        // Aurora Glow 2 (Bottom Right)
        Positioned(
          bottom: -150,
          right: -100,
          child: Animate(
            onPlay: (controller) => controller.repeat(reverse: true),
            effects: [FadeEffect(begin: 0.4, end: 0.7, duration: 8.seconds)],
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    (isDark
                            ? const Color(0xFF00C6FF)
                            : AppPallete.lightSecondary)
                        .withValues(alpha: isDark ? 0.15 : 0.1),
                    (isDark
                            ? const Color(0xFF0072FF)
                            : AppPallete.lightSecondary)
                        .withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
        ),

        // Main Content
        Positioned.fill(child: child),
      ],
    );
  }
}
