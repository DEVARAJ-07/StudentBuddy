import 'dart:math';
import 'package:flutter/material.dart';

class NeuralHologram extends StatefulWidget {
  final double size;
  const NeuralHologram({super.key, this.size = 300});

  @override
  State<NeuralHologram> createState() => _NeuralHologramState();
}

class _NeuralHologramState extends State<NeuralHologram>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: HologramPainter(
            progress: _controller.value,
            color: Colors.cyanAccent,
          ),
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: Center(
              child: Icon(
                Icons.auto_awesome, // Central Spark
                color: Colors.white,
                size: widget.size * 0.2,
              ),
            ),
          ),
        );
      },
    );
  }
}

class HologramPainter extends CustomPainter {
  final double progress;
  final Color color;

  HologramPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    // 1. Draw Rotating Orbits (Atoms/Sci-Fi)
    for (int i = 0; i < 3; i++) {
      final double angleOffset = (i * pi / 3);
      final double rotation = (progress * 2 * pi) + angleOffset;

      paint.color = color.withValues(alpha: 0.6 - (i * 0.1));
      paint.maskFilter = const MaskFilter.blur(BlurStyle.solid, 4);

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(rotation * (i % 2 == 0 ? 1 : -1)); // Component rotation

      // Draw an elliptical orbit
      final Rect oval = Rect.fromCenter(
        center: Offset.zero,
        width: radius * 1.8,
        height: radius * 0.6,
      );
      canvas.drawOval(oval, paint);

      // Draw a "Electron" on the orbit
      final double electronAngle = (progress * 4 * pi) + angleOffset;
      final double ex = (radius * 0.9) * cos(electronAngle);
      final double ey = (radius * 0.3) * sin(electronAngle);

      final Paint glowPaint = Paint()
        ..color = Colors.white
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawCircle(Offset(ex, ey), 6, glowPaint);
      canvas.drawCircle(Offset(ex, ey), 3, Paint()..color = Colors.white);

      canvas.restore();
    }

    // 2. Draw "Neural Nodes" (Background Connectivity)
    final Random rng = Random(42); // Seeded for consistancy
    final Paint nodePaint = Paint()..strokeWidth = 1;

    for (int i = 0; i < 12; i++) {
      // Random positions around center
      double angle = rng.nextDouble() * 2 * pi + (progress * 0.5);
      double dist = rng.nextDouble() * (radius * 0.8);

      Offset p1 = Offset(
        center.dx + cos(angle) * dist,
        center.dy + sin(angle) * dist,
      );

      // Pulse effect
      double pulse = sin((progress * 10) + i);
      nodePaint.color = color.withValues(alpha: 0.3 + (pulse * 0.2).abs());

      canvas.drawCircle(
        p1,
        2 + (pulse * 1),
        nodePaint..style = PaintingStyle.fill,
      );

      // Connect to center if close
      if (dist < radius * 0.5) {
        canvas.drawLine(center, p1, nodePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant HologramPainter oldDelegate) => true;
}
