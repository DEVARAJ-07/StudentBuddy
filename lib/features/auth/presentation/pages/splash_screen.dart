import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_pallete.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onFinish;
  const SplashScreen({super.key, required this.onFinish});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Orbital rings ──────────────────────────────────────────────────────────
  late AnimationController _orbitA;
  late AnimationController _orbitB;
  late AnimationController _orbitC;
  // ── Logo ───────────────────────────────────────────────────────────────────
  late AnimationController _glowCtrl;
  late AnimationController _rippleCtrl;  // expanding ripple rings
  // ── Typing text ────────────────────────────────────────────────────────────
  late AnimationController _typingCtrl;
  // ── Shooting stars ─────────────────────────────────────────────────────────
  late AnimationController _starCtrl;
  // ── Hex grid pulse ─────────────────────────────────────────────────────────
  late AnimationController _hexCtrl;
  // ── Slide-to-start ─────────────────────────────────────────────────────────
  late AnimationController _slideController;

  // Typed letters state
  final String _fullText = 'StudentBuddy';
  int _typedCount = 0;
  bool _cursorVisible = true;

  @override
  void initState() {
    super.initState();

    _orbitA = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3000))
      ..repeat();
    _orbitB = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 4200))
      ..repeat();
    _orbitC = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 5800))
      ..repeat();

    _glowCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);

    _rippleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2400))
      ..repeat();

    _typingCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000));

    _starCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3000))
      ..repeat();

    _hexCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3000))
      ..repeat(reverse: true);

    _slideController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
        upperBound: 1.0,
        lowerBound: 0.0);

    // Start typewriter after 600 ms delay
    Future.delayed(const Duration(milliseconds: 600), _startTyping);
    // Cursor blink
    _blinkCursor();
  }

  void _startTyping() async {
    for (int i = 1; i <= _fullText.length; i++) {
      await Future.delayed(const Duration(milliseconds: 80));
      if (mounted) setState(() => _typedCount = i);
    }
  }

  void _blinkCursor() async {
    while (mounted) {
      await Future.delayed(const Duration(milliseconds: 530));
      if (mounted) setState(() => _cursorVisible = !_cursorVisible);
    }
  }

  @override
  void dispose() {
    _orbitA.dispose();
    _orbitB.dispose();
    _orbitC.dispose();
    _glowCtrl.dispose();
    _rippleCtrl.dispose();
    _typingCtrl.dispose();
    _starCtrl.dispose();
    _hexCtrl.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _onDragEnd(DragEndDetails details) {
    if (_slideController.value > 0.82) {
      _slideController.animateTo(1.0, curve: Curves.easeOutExpo).then((_) {
        HapticFeedback.heavyImpact();
        widget.onFinish();
      });
    } else {
      const spring =
          SpringDescription(mass: 1, stiffness: 60, damping: 10);
      _slideController.animateWith(SpringSimulation(
        spring,
        _slideController.value,
        0.0,
        -(details.primaryVelocity ?? 0) / MediaQuery.of(context).size.width,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final cx = size.width / 2;
    final cy = size.height * 0.42;

    return Scaffold(
      backgroundColor: const Color(0xFF070718),
      body: Stack(
        children: [
          // ── 1. Deep radial gradient ─────────────────────────────────────
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.2),
                  radius: 1.3,
                  colors: [Color(0xFF0E1140), Color(0xFF050510)],
                ),
              ),
            ),
          ),

          // ── 2. Hex grid (animated pulse) ────────────────────────────────
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _hexCtrl,
              builder: (_, __) => CustomPaint(
                painter: _HexGridPainter(pulse: _hexCtrl.value),
              ),
            ),
          ),

          // ── 3. Shooting stars ──────────────────────────────────────────
          ...List.generate(6, (i) {
            final rand = Random(i * 31 + 7);
            final delay = rand.nextDouble() * 0.8;
            final angle = -0.3 - rand.nextDouble() * 0.4; // downward-right
            final startY = rand.nextDouble() * size.height * 0.5;
            final len = 80.0 + rand.nextDouble() * 60;
            return Positioned.fill(
              child: AnimatedBuilder(
                animation: _starCtrl,
                builder: (_, __) {
                  final t = (_starCtrl.value - delay).clamp(0.0, 1.0);
                  if (t == 0) return const SizedBox.shrink();
                  final x = t * (size.width + 200) - 100;
                  final y = startY + t * 120;
                  return CustomPaint(
                    painter: _ShootingStarPainter(
                      x: x,
                      y: y,
                      angle: angle,
                      length: len,
                      opacity: (t < 0.1
                          ? t / 0.1
                          : t > 0.8
                              ? (1 - t) / 0.2
                              : 1.0) *
                          (0.4 + i * 0.05),
                    ),
                  );
                },
              ),
            );
          }),

          // ── 4. Bloom behind logo ────────────────────────────────────────
          Positioned(
            left: cx - 140,
            top: cy - 140,
            child: AnimatedBuilder(
              animation: _glowCtrl,
              builder: (_, __) => Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppPallete.primary.withValues(
                          alpha: 0.22 + _glowCtrl.value * 0.14),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── 5. Expanding ripple rings ───────────────────────────────────
          Positioned(
            left: cx - 150,
            top: cy - 150,
            child: AnimatedBuilder(
              animation: _rippleCtrl,
              builder: (_, __) => CustomPaint(
                size: const Size(300, 300),
                painter: _RipplePainter(progress: _rippleCtrl.value),
              ),
            ),
          ),

          // ── 6. Three orbital rings (React atom style) ───────────────────
          Positioned.fill(
            child: AnimatedBuilder(
              animation: Listenable.merge([_orbitA, _orbitB, _orbitC]),
              builder: (_, __) => CustomPaint(
                painter: _AtomPainter(
                  cx: cx,
                  cy: cy,
                  rx: size.width * 0.40,
                  ry: size.width * 0.13,
                  progressA: _orbitA.value,
                  progressB: _orbitB.value,
                  progressC: _orbitC.value,
                ),
              ),
            ),
          ),

          // ── 7. Logo with 3D Y-flip entrance ────────────────────────────
          Positioned(
            left: cx - 44,
            top: cy - 44,
            child: AnimatedBuilder(
              animation: _glowCtrl,
              builder: (_, child) => Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF61DAFB), AppPallete.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppPallete.primary.withValues(
                          alpha: 0.55 + _glowCtrl.value * 0.3),
                      blurRadius: 28 + _glowCtrl.value * 18,
                      spreadRadius: 3,
                    ),
                    BoxShadow(
                      color: const Color(0xFF61DAFB)
                          .withValues(alpha: 0.18 + _glowCtrl.value * 0.12),
                      blurRadius: 60,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(Icons.school_rounded,
                    size: 46, color: Colors.white),
              ),
            )
                .animate()
                .scale(
                  begin: const Offset(0, 0),
                  delay: 100.ms,
                  duration: 1000.ms,
                  curve: Curves.elasticOut,
                )
                .then()
                .shimmer(delay: 200.ms, duration: 1200.ms,
                    color: Colors.white.withValues(alpha: 0.4)),
          ),

          // ── 8. Typewriter "StudentBuddy" ────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            top: cy + 66,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [
                        Color(0xFF61DAFB),
                        Colors.white,
                        Color(0xFFB48EFF),
                      ],
                      stops: [0.0, 0.45, 1.0],
                    ).createShader(bounds),
                    child: Text(
                      _fullText.substring(0, _typedCount),
                      style: GoogleFonts.poppins(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.3,
                      ),
                    ),
                  ),
                  // blinking cursor
                  AnimatedOpacity(
                    opacity: (_typedCount < _fullText.length && _cursorVisible)
                        ? 1.0
                        : 0.0,
                    duration: const Duration(milliseconds: 100),
                    child: Container(
                      width: 3,
                      height: 36,
                      margin: const EdgeInsets.only(left: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF61DAFB),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── 9. Tagline fade-in after typing ─────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            top: cy + 108,
            child: AnimatedOpacity(
              opacity: _typedCount >= _fullText.length ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 600),
              child: Text(
                '— Your Academic Companion —',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.32),
                  letterSpacing: 1.8,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),

          // ── 10. Slide bar ───────────────────────────────────────────────
          Positioned(
            left: 28,
            right: 28,
            bottom: 52,
            child: AnimatedOpacity(
                  opacity: _typedCount >= 6 ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 700),
                  child: SizedBox(
                    height: 66,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final maxSlide = constraints.maxWidth - 66;
                        return AnimatedBuilder(
                          animation: _slideController,
                          builder: (context, _) {
                            final t = _slideController.value;
                            return Container(
                              height: 66,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(33),
                                color: Colors.white.withValues(alpha: 0.03),
                                border: Border.all(
                                  color: Color.lerp(
                                    Colors.white.withValues(alpha: 0.1),
                                    const Color(0xFF61DAFB)
                                        .withValues(alpha: 0.7),
                                    t,
                                  )!,
                                  width: 1.5,
                                ),
                                boxShadow: t > 0
                                    ? [
                                        BoxShadow(
                                          color: AppPallete.primary
                                              .withValues(alpha: t * 0.35),
                                          blurRadius: 24,
                                        ),
                                        BoxShadow(
                                          color: AppPallete.primary
                                              .withValues(alpha: 0.5 + t * 0.4),
                                          blurRadius: 16 + t * 20,
                                          spreadRadius: 1,
                                        ),
                                        BoxShadow(
                                          color: const Color(0xFF61DAFB)
                                              .withValues(alpha: t * 0.3),
                                          blurRadius: 30,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Stack(
                                clipBehavior: Clip.antiAlias,
                                children: [
                                  // Comet trail fill
                                  if (t > 0)
                                    Positioned.fill(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(33),
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: Container(
                                            width: 66 + maxSlide * t,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  const Color(0xFF61DAFB)
                                                      .withValues(alpha: 0.15),
                                                  AppPallete.primary
                                                      .withValues(alpha: 0.05),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                  // Hint label
                                  Center(
                                    child: Opacity(
                                      opacity:
                                          (1.0 - t * 2).clamp(0.0, 1.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Slide to continue',
                                            style: GoogleFonts.inter(
                                              color: Colors.white
                                                  .withValues(alpha: 0.4),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              letterSpacing: 0.5,
                                            ),
                                          )
                                              .animate(
                                                  onPlay: (c) =>
                                                      c.repeat())
                                              .shimmer(
                                                duration: 2.seconds,
                                                delay: 600.ms,
                                                color: Colors.white
                                                    .withValues(alpha: 0.65),
                                              ),
                                          const SizedBox(width: 6),
                                          Icon(
                                            Icons.chevron_right_rounded,
                                            color: Colors.white
                                                .withValues(alpha: 0.25),
                                            size: 18,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // Handle
                                  Positioned(
                                    left: t * maxSlide,
                                    child: GestureDetector(
                                      onHorizontalDragUpdate: (d) {
                                        if (_slideController.isAnimating) {
                                          return;
                                        }
                                        _slideController.value +=
                                            d.delta.dx / maxSlide;
                                      },
                                      onHorizontalDragEnd: _onDragEnd,
                                      child: Container(
                                        width: 66,
                                        height: 66,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            colors: [
                                              Color(0xFF61DAFB),
                                              AppPallete.primary,
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                        ),
                                        child: Icon(
                                          t > 0.78
                                              ? Icons.check_rounded
                                              : Icons.arrow_forward_rounded,
                                          color: Colors.white,
                                          size: 26,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                )
                .animate()
                .fadeIn(delay: 1200.ms, duration: 600.ms)
                .slideY(
                  begin: 0.4,
                  end: 0,
                  delay: 1200.ms,
                  duration: 600.ms,
                  curve: Curves.easeOut,
                ),
          ),
        ],
      ),
    );
  }
}

// ═══ Painters ════════════════════════════════════════════════════════════════

/// Draws all 3 orbital ellipses + orbiting dots in one pass
class _AtomPainter extends CustomPainter {
  final double cx, cy, rx, ry;
  final double progressA, progressB, progressC;

  const _AtomPainter({
    required this.cx,
    required this.cy,
    required this.rx,
    required this.ry,
    required this.progressA,
    required this.progressB,
    required this.progressC,
  });

  void _drawOrbit(Canvas canvas, double rotation, double progress,
      Color color) {
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(rotation);

    // Draw ellipse path
    const tilt = pi / 5.5;
    final ringPaint = Paint()
      ..color = color.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;

    final path = Path();
    for (int i = 0; i <= 360; i++) {
      final a = i * pi / 180;
      final x = cos(a) * rx;
      final y = sin(a) * ry * cos(tilt);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, ringPaint);

    // Orbiting dot
    final dotAngle = progress * 2 * pi;
    final dotX = cos(dotAngle) * rx;
    final dotY = sin(dotAngle) * ry * cos(tilt);

    // Comet tail
    const tailLength = 6;
    for (int t = tailLength; t >= 1; t--) {
      final ta = (progress - t * 0.018) * 2 * pi;
      final tx = cos(ta) * rx;
      final ty = sin(ta) * ry * cos(tilt);
      canvas.drawCircle(
        Offset(tx, ty),
        1.8 * (tailLength - t) / tailLength,
        Paint()
          ..color = color.withValues(alpha: 0.08 * (tailLength - t))
          ..style = PaintingStyle.fill,
      );
    }

    // Glow
    canvas.drawCircle(
      Offset(dotX, dotY),
      9,
      Paint()
        ..color = color.withValues(alpha: 0.2)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    // Core
    canvas.drawCircle(
      Offset(dotX, dotY),
      4.5,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );

    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    _drawOrbit(canvas, 0, progressA, const Color(0xFF61DAFB));
    _drawOrbit(canvas, 2 * pi / 3, progressB, AppPallete.primary);
    _drawOrbit(canvas, 4 * pi / 3, progressC, AppPallete.secondary);
  }

  @override
  bool shouldRepaint(_AtomPainter old) =>
      old.progressA != progressA ||
      old.progressB != progressB ||
      old.progressC != progressC;
}

/// Expanding ripple rings from the logo center
class _RipplePainter extends CustomPainter {
  final double progress;
  _RipplePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    for (int i = 0; i < 3; i++) {
      final t = (progress + i / 3) % 1.0;
      final radius = 30.0 + t * 150;
      final alpha = (1.0 - t) * 0.12;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = AppPallete.primary.withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(_RipplePainter old) => old.progress != progress;
}

/// Subtle hex grid with pulsing opacity
class _HexGridPainter extends CustomPainter {
  final double pulse;
  _HexGridPainter({required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    const hexSize = 26.0;
    const w = hexSize * 2;
    const h = hexSize * sqrt2;
    final paint = Paint()
      ..color =
          Colors.white.withValues(alpha: 0.025 + pulse * 0.012)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (double y = -hexSize; y < size.height + hexSize; y += h) {
      for (double x = -hexSize; x < size.width + w; x += w * 1.5) {
        final offset = (x / (w * 3)).floor().isEven ? 0 : h / 2;
        _drawHex(canvas, Offset(x, y + offset), hexSize, paint);
        _drawHex(canvas, Offset(x + w, y + offset), hexSize, paint);
      }
    }
  }

  void _drawHex(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = pi / 180 * (60 * i - 30);
      final p = Offset(
          center.dx + size * cos(angle), center.dy + size * sin(angle));
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_HexGridPainter old) => old.pulse != pulse;
}

/// Single shooting star with comet tail
class _ShootingStarPainter extends CustomPainter {
  final double x, y, angle, length, opacity;
  _ShootingStarPainter(
      {required this.x,
      required this.y,
      required this.angle,
      required this.length,
      required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final tailX = x - cos(angle) * length;
    final tailY = y - sin(angle) * length;

    canvas.drawLine(
      Offset(tailX, tailY),
      Offset(x, y),
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.transparent,
            Colors.white.withValues(alpha: opacity),
          ],
        ).createShader(
          Rect.fromPoints(Offset(tailX, tailY), Offset(x, y)),
        )
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke,
    );

    // tip glow
    canvas.drawCircle(
      Offset(x, y),
      2,
      Paint()
        ..color = Colors.white.withValues(alpha: opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
  }

  @override
  bool shouldRepaint(_ShootingStarPainter old) => old.x != x || old.y != y;
}
