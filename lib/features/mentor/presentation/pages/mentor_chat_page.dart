import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:student_buddy/core/theme/app_pallete.dart';
import 'package:student_buddy/core/common/widgets/glass_container.dart';
import 'package:student_buddy/features/mentor/data/chat_repository.dart';
import 'package:student_buddy/core/services/multi_model_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:student_buddy/core/services/rag_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:student_buddy/features/mentor/presentation/pages/roadmap_page.dart';
import 'dart:io';
import 'dart:async';

class MentorChatPage extends StatefulWidget {
  final Map<String, dynamic> mentorData;

  const MentorChatPage({super.key, required this.mentorData});

  @override
  State<MentorChatPage> createState() => _MentorChatPageState();
}

class _MentorChatPageState extends State<MentorChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late final MultiModelService _multiModelService;
  late final ChatRepository _chatRepository;
  late final RagService _ragService;
  final SupabaseClient _supabase = Supabase.instance.client;
  Timer? _timestampTimer;

  // Chat State
  final List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;
  bool _isUploading = false;
  String _modelStatus = ''; // Real-time status from MultiModelService

  @override
  void initState() {
    super.initState();
    _chatRepository = ChatRepository();
    _ragService = RagService(Supabase.instance.client);

    final domain = widget.mentorData['domain'] ?? 'Education';
    final name = widget.mentorData['name'] ?? 'Mentor';

    // Initialize MultiModel with persona
    _multiModelService = MultiModelService(
      systemInstruction:
          'You are $name, an expert in $domain. '
          'Your goal is to help students learn $domain concepts effectively. '
          'TEACH LIKE A BEGINNER: Break down complex topics into simple terms. '
          'Use analogies and step-by-step explanations. '
          'GUARDRAILS: If the user asks personal questions or goes off-topic, nicely redirect them back to studying $domain. '
          'Use motivational quotes to boost their confidence when redirecting. '
          'Keep responses concise and engaging for a mobile app chat interface.',
      onStatusUpdate: (modelName, status) {
        if (mounted) {
          setState(() => _modelStatus = '$modelName: $status');
        }
      },
    );

    // Load previous messages
    _loadMessages();

    // Real-time timestamp updates every 30 seconds
    _timestampTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timestampTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    final mentorId = widget.mentorData['id'];
    // If no ID (e.g. preview), just show greeting.
    if (mentorId == null) {
      _addInitialGreeting(scrollToBottom: true);
      return;
    }

    try {
      final history = await _chatRepository.getMessages(mentorId);
      setState(() {
        _messages.clear();
        // Always add the welcoming greeting at the top!
        _addInitialGreeting(scrollToBottom: false);

        if (history.isNotEmpty) {
          for (var msg in history) {
            _messages.add({
              "role": msg.role,
              "content": msg.content,
              "timestamp": msg.timestamp,
            });
          }
        }
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (e) {
      debugPrint("Error loading history: $e");
      _addInitialGreeting(scrollToBottom: true);
    }
  }

  void _addInitialGreeting({bool scrollToBottom = false}) {
    final domain = widget.mentorData['domain'] ?? 'Programming';
    
    final content = "Welcome! I am your personal mentor for the $domain domain. "
        "I will help you learn and master $domain in a simple and effective way. "
        "Based on your current level, I will guide you step by step so you can improve with confidence. "
        "You will practice $domain through easy methods, tricks, and regular exercises. "
        "A structured roadmap is available to track your progress and learning path. "
        "Click the Roadmap button above to view the complete plan—thank you, let’s start learning!";

    _messages.add({
      "role": "assistant",
      "content": content,
      "timestamp": DateTime.now(), // You could use a fake old date to keep it at top if sorted, but we append in order
    });

    if (scrollToBottom) {
      _scrollToBottom();
    }
  }

  // Save and Add Message
  void _addMessage(String role, String content, {bool saveToDb = true}) {
    setState(() {
      _messages.add({
        "role": role,
        "content": content,
        "timestamp": DateTime.now(),
      });
    });
    _scrollToBottom();

    // Save to DB asynchronously if requested
    if (saveToDb) {
      final mentorId = widget.mentorData['id'];
      if (mentorId != null) {
        _chatRepository
            .saveMessage(mentorId: mentorId, content: content, role: role)
            .catchError((e) {
              debugPrint("Error saving message: $e");
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to save message: $e')),
                );
              }
            });
      }
    }
  }

  Future<void> _clearChat() async {
    final mentorId = widget.mentorData['id'];
    if (mentorId == null) return;

    try {
      await _supabase
          .from('chat_messages')
          .delete()
          .eq('mentor_id', mentorId)
          .eq('user_id', _supabase.auth.currentUser!.id);

      setState(() {
        _messages.clear();
      });
      _addInitialGreeting();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Chat cleared!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _pickAndUploadFile() async {
    setState(() => _isUploading = true);
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'txt'],
      );

      if (result != null) {
        PlatformFile file = result.files.first;
        String content = "";

        if (file.extension == 'pdf') {
          final PdfDocument document = PdfDocument(
            inputBytes: File(file.path!).readAsBytesSync(),
          );
          content = PdfTextExtractor(document).extractText();
          document.dispose();
        } else {
          content = await File(file.path!).readAsString();
        }

        if (content.trim().isEmpty) throw Exception("Empty content");

        final chunks = _chunkText(content, 1000);
        for (var chunk in chunks) {
          await _ragService.addDocument(file.name, chunk);
        }

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Learned ${file.name}!')));
          _addMessage("system", "I have read ${file.name}. Ask me about it.");
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  List<String> _chunkText(String text, int chunkSize) {
    List<String> chunks = [];
    for (int i = 0; i < text.length; i += chunkSize) {
      int end = (i + chunkSize < text.length) ? i + chunkSize : text.length;
      chunks.add(text.substring(i, end));
    }
    return chunks;
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

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return 'Just now';

    final now = DateTime.now();
    final diff = now.difference(dateTime);

    // Less than 30 seconds
    if (diff.inSeconds < 30) return 'Just now';

    // Less than 1 minute
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';

    // Less than 60 minutes
    if (diff.inMinutes < 60) {
      return diff.inMinutes == 1 ? '1 min ago' : '${diff.inMinutes} mins ago';
    }

    // Less than 24 hours - show time like "7:40 PM"
    if (diff.inHours < 24) {
      final hour = dateTime.hour;
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      return '$displayHour:$minute $period';
    }

    // Yesterday
    if (diff.inDays == 1) {
      final hour = dateTime.hour;
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      return 'Yesterday $displayHour:$minute $period';
    }

    // Within 7 days - show day and time
    if (diff.inDays < 7) {
      final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final dayName = days[dateTime.weekday - 1];
      final hour = dateTime.hour;
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      return '$dayName $displayHour:$minute $period';
    }

    // Older - show date
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }



  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    if (_isTyping) return; // Prevent multiple requests

    final text = _messageController.text;
    _messageController.clear();

    // 1. Add to UI immediately
    _addMessage("user", text, saveToDb: false);

    setState(() {
      _isTyping = true;
      _modelStatus = 'Initializing models...';
    });

    try {
      // 2. Save to DB BEFORE API call
      final mentorId = widget.mentorData['id'];
      if (mentorId != null) {
        await _chatRepository.saveMessage(
          mentorId: mentorId,
          content: text,
          role: 'user',
        );
      }

      // 3. RAG Retrieval (Inject Context)
      String? ragContext;
      final context = await _ragService.retrieveContext(text);
      if (context != null) {
        ragContext = context;
      }

      // 4. Prepare history for MultiModel
      final history = _messages
          .where((m) => m['role'] != 'system')
          .map(
            (m) => {
              'role': m['role'] as String,
              'content': m['content'] as String,
            },
          )
          .toList();

      final historyToSend = history.sublist(0, history.length - 1);

      // 5. Fire all 3 models in parallel via MultiModelService
      final result = await _multiModelService.sendMessage(
        text,
        history: historyToSend,
        ragContext: ragContext,
      );

      if (mounted) {
        setState(() {
          _isTyping = false;
          _modelStatus = '';
        });

        _addMessage("assistant", result.finalAnswer);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _modelStatus = '';
        });

        String errorMessage = "Sorry, I encountered an error.";
        if (e.toString().contains('429')) {
          errorMessage =
              "I'm receiving too many messages right now. Please try again in a moment.";
        } else if (e.toString().contains('402')) {
          errorMessage = "Mentor is currently busy, switching to backup.";
        } else {
          errorMessage =
              "Connection error: ${e.toString().replaceAll('Exception:', '').trim()}";
        }

        _addMessage("assistant", errorMessage);

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
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
          const Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: CustomPaint(painter: PerspectiveGridPainter()),
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
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppPallete.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(30),
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
          // Back button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppPallete.background.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: AppPallete.textSecondary,
                size: 18,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Avatar
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
              child: Icon(Icons.auto_awesome, color: Colors.white, size: 18),
            ),
          ),

          const SizedBox(width: 12),

          // Name & Domain
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.mentorData['name'] ?? "AI Mentor",
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  widget.mentorData['domain'] ?? "Assistant",
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppPallete.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Delete Button
          GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppPallete.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  title: const Text(
                    'Clear Chat?',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  content: const Text(
                    'This will delete all messages with this mentor.',
                    style: TextStyle(color: Colors.white70),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: AppPallete.textSecondary),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _clearChat();
                      },
                      child: const Text(
                        'Clear',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.delete_outline_rounded,
                color: Colors.red.withValues(alpha: 0.7),
                size: 20,
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Roadmap Button
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
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RoadmapPage(mentorData: widget.mentorData),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF8E2DE2), Color(0xFF00C6FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: const Icon(
                    Icons.map_outlined,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
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
        final timestamp = msg['timestamp'] as DateTime?;
        return _buildMessageBubble(msg['content'], isUser, timestamp);
      },
    );
  }

  Widget _buildMessageBubble(String message, bool isUser, DateTime? timestamp) {
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
                  _formatTime(timestamp),
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
          border: Border.all(
            color: const Color(0xFF8E2DE2).withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Three pulsating dots
                for (int i = 0; i < 3; i++)
                  Animate(
                    onPlay: (controller) => controller.repeat(),
                    effects: [
                      ScaleEffect(
                        begin: const Offset(0.8, 0.8),
                        end: const Offset(1.2, 1.2),
                        duration: 600.ms,
                        delay: (i * 200).ms,
                        curve: Curves.easeInOut,
                      ),
                      FadeEffect(
                        begin: 0.5,
                        end: 1.0,
                        duration: 600.ms,
                        delay: (i * 200).ms,
                        curve: Curves.easeInOut,
                      ),
                    ],
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF8E2DE2),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                const SizedBox(width: 10),
                Text(
                  "Multi-Model Thinking...",
                  style: GoogleFonts.inter(
                    color: AppPallete.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (_modelStatus.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                _modelStatus,
                style: GoogleFonts.inter(
                  color: const Color(0xFF8E2DE2).withValues(alpha: 0.7),
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn().slideX(begin: -0.1);
  }

  Widget _buildInputArea() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppPallete.surface,
        borderRadius: BorderRadius.circular(40),
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
          const SizedBox(width: 8),
          IconButton(
            icon: _isUploading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white54,
                    ),
                  )
                : const Icon(Icons.attach_file, color: Colors.white54),
            onPressed: _pickAndUploadFile,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
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
                  filled: true,
                  fillColor: Colors.transparent,
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
