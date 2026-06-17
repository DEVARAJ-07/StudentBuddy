import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_pallete.dart';
import '../../../../core/common/widgets/glass_container.dart';

class RoadmapPage extends StatefulWidget {
  final Map<String, dynamic> mentorData;

  const RoadmapPage({super.key, required this.mentorData});

  @override
  State<RoadmapPage> createState() => _RoadmapPageState();
}

class _RoadmapPageState extends State<RoadmapPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<dynamic> _roadmapContent = [];
  Set<String> _completedTopics = {};

  int _totalSubtopics = 0;

  @override
  void initState() {
    super.initState();
    _loadRoadmapAndProgress();
  }

  Future<void> _loadRoadmapAndProgress() async {
    setState(() => _isLoading = true);
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final mentorId = widget.mentorData['id'];
    final domain = widget.mentorData['domain'] ?? 'Programming';
    final level = (widget.mentorData['experience_level'] ?? 'Beginner').toLowerCase();

    try {
      // 1. Load roadmap content
      final resContent = await _supabase
          .from('roadmaps')
          .select('content')
          .eq('domain', domain)
          .eq('level', level)
          .maybeSingle();

      if (resContent != null) {
        _roadmapContent = resContent['content'] as List<dynamic>? ?? [];
      }

      // Count total subtopics
      _totalSubtopics = _roadmapContent.fold(0, (sum, topic) {
        final subs = (topic['subtopics'] as List<dynamic>?) ?? [];
        return sum + subs.length;
      });

      // 2. Load checked progress
      if (mentorId != null) {
        final resProgress = await _supabase
            .from('roadmap_progress')
            .select('completed_topics')
            .eq('user_id', user.id)
            .eq('mentor_id', mentorId)
            .maybeSingle();

        if (resProgress != null) {
          final completed = resProgress['completed_topics'] as List<dynamic>? ?? [];
          _completedTopics = completed.map((e) => e.toString()).toSet();
        }
      }
    } catch (e) {
      debugPrint("Error loading roadmap: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading roadmap: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleSubtopic(String topicId) async {
    setState(() {
      if (_completedTopics.contains(topicId)) {
        _completedTopics.remove(topicId);
      } else {
        _completedTopics.add(topicId);
      }
    });

    final user = _supabase.auth.currentUser;
    if (user == null) return;
    final mentorId = widget.mentorData['id'];
    if (mentorId == null) return; // Can't save progress for preview mentors

    try {
      await _supabase.from('roadmap_progress').upsert({
        'user_id': user.id,
        'mentor_id': mentorId,
        'completed_topics': _completedTopics.toList(),
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id, mentor_id');
    } catch (e) {
      debugPrint("Error saving progress: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final domain = widget.mentorData['domain'] ?? 'Programming';
    final rawLevel = widget.mentorData['experience_level'] ?? 'Beginner';
    final displayLevel = rawLevel[0].toUpperCase() + rawLevel.substring(1).toLowerCase();

    final progressPercent = _totalSubtopics == 0 ? 0.0 : (_completedTopics.length / _totalSubtopics);

    return Scaffold(
      backgroundColor: AppPallete.background,
      body: Stack(
        children: [
          // Background Glow
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppPallete.primary.withValues(alpha: 0.15),
                    blurRadius: 100,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                _buildHeader(domain, displayLevel, progressPercent),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: AppPallete.primary))
                      : _roadmapContent.isEmpty
                          ? const Center(
                              child: Text(
                                "No path curated yet.\nCheck back later!",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white54, fontSize: 16),
                              ),
                            )
                          : _buildTimeline(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String domain, String level, double progress) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$domain Roadmap",
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  "$level Path",
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppPallete.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // Circular Progress
          SizedBox(
            width: 50,
            height: 50,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 4,
                  backgroundColor: Colors.white10,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppPallete.primary),
                ),
                Center(
                  child: Text(
                    "${(progress * 100).toInt()}%",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().scale(delay: 200.ms, curve: Curves.easeOutBack),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: _roadmapContent.length,
      itemBuilder: (context, index) {
        final topicData = _roadmapContent[index];
        final topicName = topicData['topic'] ?? 'Topic';
        final subtopics = (topicData['subtopics'] as List<dynamic>?) ?? [];

        // Calculate if this entire major topic is done
        int topicSubsCompleted = 0;
        for (var i = 0; i < subtopics.length; i++) {
          if (_completedTopics.contains("T${index}_S$i")) {
            topicSubsCompleted++;
          }
        }
        final isTopicFullyDone = subtopics.isNotEmpty && topicSubsCompleted == subtopics.length;

        return _buildTopicNode(
          index: index,
          topicName: topicName,
          subtopics: subtopics,
          isFullyDone: isTopicFullyDone,
          isLast: index == _roadmapContent.length - 1,
        ).animate().fadeIn(delay: Duration(milliseconds: 100 * index)).slideX(begin: 0.1);
      },
    );
  }

  Widget _buildTopicNode({
    required int index,
    required String topicName,
    required List<dynamic> subtopics,
    required bool isFullyDone,
    required bool isLast,
  }) {
    return Stack(
      children: [
        // Vertical Timeline Line
        if (!isLast)
          Positioned(
            left: 27,
            top: 50,
            bottom: -50,
            child: Container(
              width: 2,
              color: isFullyDone ? AppPallete.primary.withValues(alpha: 0.5) : Colors.white10,
            ),
          ),
          
        Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Node Icon
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isFullyDone ? AppPallete.primary.withValues(alpha: 0.2) : AppPallete.surface,
                  border: Border.all(
                    color: isFullyDone ? AppPallete.primary : Colors.white10,
                    width: 2,
                  ),
                  boxShadow: isFullyDone
                      ? [
                          BoxShadow(
                            color: AppPallete.primary.withValues(alpha: 0.4),
                            blurRadius: 12,
                            spreadRadius: 2,
                          )
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    "${index + 1}",
                    style: TextStyle(
                      color: isFullyDone ? Colors.white : Colors.white54,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Topic Content Card
              Expanded(
                child: GlassContainer(
                  borderRadius: BorderRadius.circular(20),
                  padding: const EdgeInsets.all(16),
                  blur: isFullyDone ? 20 : 10,
                  opacity: isFullyDone ? 0.15 : 0.05,
                  color: isFullyDone ? AppPallete.primary : AppPallete.surface,
                  border: Border.all(
                    color: isFullyDone ? AppPallete.primary.withValues(alpha: 0.3) : Colors.white10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        topicName,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isFullyDone ? Colors.white : Colors.white.withValues(alpha: 0.9),
                          decoration: isFullyDone ? TextDecoration.lineThrough : null,
                          decorationColor: AppPallete.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: Colors.white10, height: 1),
                      const SizedBox(height: 8),
                      
                      // Subtopics List
                      ...List.generate(subtopics.length, (subIndex) {
                        final sub = subtopics[subIndex].toString();
                        final topicId = "T${index}_S$subIndex";
                        final isSubDone = _completedTopics.contains(topicId);

                        return GestureDetector(
                          onTap: () => _toggleSubtopic(topicId),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            decoration: BoxDecoration(
                              color: isSubDone 
                                  ? AppPallete.primary.withValues(alpha: 0.1) 
                                  : Colors.white.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSubDone ? AppPallete.primary.withValues(alpha: 0.3) : Colors.transparent,
                              ),
                            ),
                            child: Row(
                              children: [
                                // Checkbox
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: isSubDone ? AppPallete.primary : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isSubDone ? AppPallete.primary : Colors.white30,
                                      width: 1.5,
                                    ),
                                    boxShadow: isSubDone
                                        ? [BoxShadow(color: AppPallete.primary.withValues(alpha: 0.5), blurRadius: 4)]
                                        : [],
                                  ),
                                  child: isSubDone
                                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                // Subtopic Text
                                Expanded(
                                  child: AnimatedDefaultTextStyle(
                                    duration: const Duration(milliseconds: 200),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isSubDone ? Colors.white54 : Colors.white70,
                                      decoration: isSubDone ? TextDecoration.lineThrough : null,
                                      decorationColor: Colors.white54,
                                      decorationStyle: TextDecorationStyle.dashed,
                                    ),
                                    child: Text(sub),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
