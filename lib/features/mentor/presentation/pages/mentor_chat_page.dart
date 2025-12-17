import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:student_buddy/core/theme/app_pallete.dart';
import 'package:student_buddy/core/common/widgets/glass_container.dart';
import 'voice_assistant_page.dart';

class MentorChatPage extends StatefulWidget {
  final Map<String, dynamic> mentorData;

  const MentorChatPage({super.key, required this.mentorData});

  @override
  State<MentorChatPage> createState() => _MentorChatPageState();
}

class _MentorChatPageState extends State<MentorChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Chat State
  final List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;
  bool _showUploadMenu = false;

  @override
  void initState() {
    super.initState();
    // Initial Greeting
    _addMessage(
      "assistant",
      "Hello! I am your AI Mentor. How can I help you with ${widget.mentorData['domain'] ?? 'your studies'} today?",
    );
  }

  void _addMessage(String role, String content) {
    setState(() {
      _messages.add({
        "role": role,
        "content": content,
        "timestamp": DateTime.now(),
      });
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final text = _messageController.text;
    _messageController.clear();
    _addMessage("user", text);

    // Simulate AI thinking and typing
    setState(() => _isTyping = true);

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() => _isTyping = false);
        _addMessage(
          "assistant",
          "That's a great question about $text! As an AI, I can help you break this down step-by-step. What specific part are you stuck on?",
        );
      }
    });
  }

  void _toggleUploadMenu() {
    setState(() => _showUploadMenu = !_showUploadMenu);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPallete.background,
      body: Stack(
        children: [
          // Deep Space Background
          Positioned.fill(
            child: Container(
              color: const Color(0xFF0B0F19), // Deepest dark blue/black
            ),
          ),

          // Animated Aurora 1 (Top Left)
          Positioned(
            top: -100,
            left: -100,
            child: Animate(
              onPlay: (controller) => controller.repeat(reverse: true),
              effects: [
                MoveEffect(
                  begin: const Offset(0, 0),
                  end: const Offset(50, 50),
                  duration: 10.seconds,
                ),
                ScaleEffect(
                  begin: const Offset(1, 1),
                  end: const Offset(1.2, 1.2),
                  duration: 15.seconds,
                ),
              ],
              child: Container(
                width: 500,
                height: 500,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF4A00E0).withValues(alpha: 0.2),
                      Colors.transparent,
                    ],
                    stops: const [0.2, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // Animated Aurora 2 (Bottom Right)
          Positioned(
            bottom: -100,
            right: -100,
            child: Animate(
              onPlay: (controller) => controller.repeat(reverse: true),
              effects: [
                MoveEffect(
                  begin: const Offset(0, 0),
                  end: const Offset(-50, -50),
                  duration: 12.seconds,
                ),
                ScaleEffect(
                  begin: const Offset(1, 1),
                  end: const Offset(1.5, 1.5),
                  duration: 20.seconds,
                ),
              ],
              child: Container(
                width: 600,
                height: 600,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF8E2DE2).withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                    stops: const [0.2, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // 3D Perspective Grid
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: CustomPaint(painter: const PerspectiveGridPainter()),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(child: _buildChatList()),
                _buildTypingIndicator(),
                _buildInputArea(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 10), // Floating margin
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppPallete.surface.withValues(
          alpha: 0.85,
        ), // Slightly more opaque for readability
        borderRadius: BorderRadius.circular(30), // Fully rounded
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: AppPallete.textSecondary,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
              ),
            ),
            child: const CircleAvatar(
              radius: 18,
              backgroundColor: Colors.black,
              child: Icon(Icons.auto_awesome, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.mentorData['name'] ?? "AI Mentor",
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  widget.mentorData['domain'] ?? "Assistant",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppPallete.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppPallete.surface.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8E2DE2).withValues(alpha: 0.2),
                  blurRadius: 15,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: IconButton(
              // Premium Glowing Voice Icon
              icon: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFF8E2DE2), Color(0xFF00C6FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: const Icon(
                  Icons.graphic_eq, // The "Best" icon for audio viz
                  color: Colors.white, // Required for shader
                  size: 24,
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VoiceAssistantPage(
                      mentorName: widget.mentorData['name'] ?? "AI Mentor",
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final isUser = msg['role'] == 'user';
        return _buildMessageBubble(msg['content'], isUser);
      },
    );
  }

  Widget _buildMessageBubble(String message, bool isUser) {
    return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            constraints: const BoxConstraints(maxWidth: 280),
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                GlassContainer(
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(isUser ? 20 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 20),
                  ),
                  blur: isUser ? 0 : 10,
                  opacity: isUser ? 1 : 0.05,
                  color: isUser ? Colors.transparent : AppPallete.surface,
                  gradient: isUser
                      ? const LinearGradient(
                          colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
                        )
                      : null,
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    message,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Just now", // In real app, format timestamp
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuart);
  }

  Widget _buildTypingIndicator() {
    if (!_isTyping) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(left: 20, bottom: 20),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppPallete.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppPallete.textSecondary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              "Thinking...",
              style: GoogleFonts.inter(
                color: AppPallete.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn();
  }

  Widget _buildInputArea() {
    return Column(
      children: [
        if (_showUploadMenu)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildUploadOption(
                  Icons.image_rounded,
                  "Image",
                  Colors.pinkAccent,
                ),
                _buildUploadOption(
                  Icons.description_rounded,
                  "Document",
                  Colors.blueAccent,
                ),
                _buildUploadOption(
                  Icons.camera_alt_rounded,
                  "Camera",
                  Colors.orangeAccent,
                ),
              ],
            ),
          ).animate().scale(curve: Curves.easeOutBack),

        Container(
          margin: const EdgeInsets.fromLTRB(
            16,
            0,
            16,
            16,
          ), // Floating bottom margin
          padding: const EdgeInsets.all(8), // Inner padding
          decoration: BoxDecoration(
            color: AppPallete.surface,
            borderRadius: BorderRadius.circular(
              40,
            ), // Fully rounded floating pill
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: _toggleUploadMenu,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _showUploadMenu
                        ? AppPallete.primary
                        : Colors.white.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _showUploadMenu ? Icons.close : Icons.add,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    // Transparent as the outer pill provides the background
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                      filled: true, // Override global theme
                      fillColor: Colors.transparent, // Remove white background
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8E2DE2).withValues(alpha: 0.4),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUploadOption(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            color: AppPallete.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class PerspectiveGridPainter extends CustomPainter {
  const PerspectiveGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Draw vanishing lines (giving depth)
    for (double i = -1; i <= 1; i += 0.1) {
      final xOffset = i * size.width;
      canvas.drawLine(
        Offset(centerX, centerY - 100), // Vanishing point slightly above center
        Offset(centerX + xOffset * 4, size.height + 200),
        paint
          ..color = Colors.white.withValues(
            alpha: (1 - i.abs()) * 0.2,
          ), // Fade on edges
      );
    }

    // Draw horizontal perspective lines
    for (double i = 0; i < 1; i += 0.05) {
      final y =
          size.height - (size.height * i * i); // Logarithmic spacing for depth
      if (y < centerY) continue;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint..color = Colors.white.withValues(alpha: i * 0.2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
