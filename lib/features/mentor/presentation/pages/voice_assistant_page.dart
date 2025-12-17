import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import 'dart:math';

class VoiceAssistantPage extends StatefulWidget {
  final String mentorName;
  const VoiceAssistantPage({super.key, required this.mentorName});

  @override
  State<VoiceAssistantPage> createState() => _VoiceAssistantPageState();
}

class _VoiceAssistantPageState extends State<VoiceAssistantPage>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  bool _isListening = true;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  void _toggleListening() {
    setState(() => _isListening = !_isListening);
    if (_isListening) {
      _pulseController.repeat(reverse: true);
      _rotationController.repeat();
    } else {
      _pulseController.stop();
      _rotationController.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Ambient Background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.6,
                  colors: [Color(0xFF1A0B2E), Colors.black],
                ),
              ),
            ),
          ),

          // Noise Texture Overlay (Optional, simple dot pattern)
          Opacity(
            opacity: 0.05,
            child: CustomPaint(painter: GridPainter(), size: Size.infinite),
          ),

          SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(),

                const Spacer(),

                // Neural Core Visualizer
                _buildNeuralCore(),

                const SizedBox(height: 60),

                // Live Text Transcription
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    _isListening ? "I'm listening..." : "Tap the mic to speak",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.w300,
                      color: Colors.white.withValues(alpha: 0.9),
                      letterSpacing: 1.2,
                    ),
                  ).animate(target: _isListening ? 1 : 0).fadeIn(),
                ),

                const Spacer(),

                // Controls
                _buildControls(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(
              Icons.keyboard_arrow_down,
              color: Colors.white,
              size: 32,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.circle, color: Colors.greenAccent, size: 8),
                const SizedBox(width: 8),
                Text(
                  widget.mentorName.toUpperCase(),
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 32), // Balance spacing
        ],
      ),
    );
  }

  Widget _buildNeuralCore() {
    return SizedBox(
      width: 300,
      height: 300,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer Glow
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: 250 + (_pulseController.value * 30),
                height: 250 + (_pulseController.value * 30),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(
                    0xFF8E2DE2,
                  ).withValues(alpha: 0.1 + (_pulseController.value * 0.1)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4A00E0).withValues(alpha: 0.3),
                      blurRadius: 60,
                      spreadRadius: 10,
                    ),
                  ],
                ),
              );
            },
          ),
          // Rotating Rings
          AnimatedBuilder(
            animation: _rotationController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotationController.value * 2 * pi,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Orbital Dots
                      Positioned(top: 0, left: 100, child: _buildDot()),
                      Positioned(bottom: 0, right: 100, child: _buildDot()),
                    ],
                  ),
                ),
              );
            },
          ),
          // Inner Core
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: 100 + (_pulseController.value * 10),
                height: 100 + (_pulseController.value * 10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [Colors.white, Color(0xFF8E2DE2)],
                    stops: [0.1, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8E2DE2).withValues(alpha: 0.8),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDot() {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: Colors.cyanAccent,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.cyanAccent, blurRadius: 5)],
      ),
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildControlButton(Icons.keyboard_alt_outlined, false),
        const SizedBox(width: 40),
        GestureDetector(
          onTap: _toggleListening,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isListening ? Colors.white : Colors.white10,
              boxShadow: [
                if (_isListening)
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.4),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
              ],
            ),
            child: Icon(
              _isListening ? Icons.graphic_eq : Icons.mic_none,
              color: _isListening ? Colors.black : Colors.white,
              size: 32,
            ),
          ),
        ),
        const SizedBox(width: 40),
        _buildControlButton(Icons.more_horiz, false),
      ],
    );
  }

  Widget _buildControlButton(IconData icon, bool isActive) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.1),
      ),
      child: Icon(icon, color: Colors.white, size: 24),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    // Draw random stars/dots
    final random = Random(42); // Fixed seed for stability
    for (int i = 0; i < 50; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), 1.5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
