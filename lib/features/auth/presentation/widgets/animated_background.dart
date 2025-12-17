import 'dart:math';
import 'package:flutter/material.dart';

class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({super.key});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Star> _stars = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Generate Stars
    for (int i = 0; i < 100; i++) {
      _stars.add(
        Star(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          size: _random.nextDouble() * 2 + 1,
          speed: _random.nextDouble() * 0.2 + 0.05,
          opacity: _random.nextDouble(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black, // Fallback
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: StarFieldPainter(
              stars: _stars,
              progress: _controller.value,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class Star {
  double x;
  double y;
  final double size;
  final double speed;
  double opacity;

  Star({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });
}

class StarFieldPainter extends CustomPainter {
  final List<Star> stars;
  final double progress;

  StarFieldPainter({required this.stars, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Deep Space Gradient Background
    final Rect rect = Offset.zero & size;
    final Paint bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF000000), // Black
          Color(0xFF150050), // Deep Purple
          Color(0xFF000000), // Black
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    // 2. Draw Moving Stars
    final Paint starPaint = Paint()..color = Colors.white;

    for (var star in stars) {
      // Move star upwards
      double newY = star.y - (star.speed * 0.01);

      // Reset if off screen
      if (newY < 0) {
        newY = 1.0;
        star.x = Random().nextDouble(); // Randomize X on reset
      }
      star.y = newY;

      // Twinkle effect
      double opacity = (star.opacity + sin(progress * 2 * pi) * 0.2).clamp(
        0.1,
        0.8,
      );
      starPaint.color = Colors.white.withValues(alpha: opacity);

      canvas.drawCircle(
        Offset(star.x * size.width, star.y * size.height),
        star.size,
        starPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
