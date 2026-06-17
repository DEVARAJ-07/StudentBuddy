import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_pallete.dart';

/// Premium Luck Card Game Widget with enhanced visuals
class LuckCardWidget extends StatefulWidget {
  const LuckCardWidget({super.key});

  @override
  State<LuckCardWidget> createState() => _LuckCardWidgetState();
}

class _LuckCardWidgetState extends State<LuckCardWidget>
    with TickerProviderStateMixin {
  final SupabaseClient _supabase = Supabase.instance.client;
  final Random _random = Random();

  int _playsRemaining = 3;
  bool _isLoading = true;
  bool _isShuffling = false;
  int? _selectedCardIndex;
  String? _revealedResult;
  int _totalLuckPoints = 0;
  String _userName = 'Player';

  late AnimationController _shuffleController;
  late AnimationController _pulseController;
  late AnimationController _flipController;
  late AnimationController _sparkleController;

  @override
  void initState() {
    super.initState();
    _shuffleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _loadData();
  }

  @override
  void dispose() {
    _shuffleController.dispose();
    _pulseController.dispose();
    _flipController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final profile = await _supabase
          .from('profiles')
          .select('full_name')
          .eq('id', userId)
          .maybeSingle();

      _userName = profile?['full_name'] ?? 'Player';

      final today = DateTime.now().toIso8601String().split('T')[0];
      final plays = await _supabase
          .from('luck_card_plays')
          .select()
          .eq('user_id', userId)
          .eq('play_date', today);

      final progress = await _supabase
          .from('user_progress')
          .select('luck_points')
          .eq('user_id', userId)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _playsRemaining = 3 - (plays as List).length;
          _totalLuckPoints = (progress?['luck_points'] as int?) ?? 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading luck card data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _shuffleCards() async {
    if (_playsRemaining <= 0 || _isShuffling) return;

    HapticFeedback.mediumImpact();
    setState(() {
      _isShuffling = true;
      _selectedCardIndex = null;
      _revealedResult = null;
    });

    await _shuffleController.forward(from: 0);

    if (mounted) {
      setState(() => _isShuffling = false);
    }
  }

  Future<void> _selectCard(int index) async {
    if (_playsRemaining <= 0 || _selectedCardIndex != null || _isShuffling) {
      return;
    }

    HapticFeedback.heavyImpact();
    setState(() => _selectedCardIndex = index);

    await Future.delayed(const Duration(milliseconds: 400));

    final roll = _random.nextDouble();
    String result;
    if (roll < 0.3) {
      result = 'win';
    } else if (roll < 0.8) {
      result = 'lose';
    } else {
      result = 'joker';
    }

    final points = result == 'win' ? 10 : (result == 'lose' ? 2 : 0);

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId != null) {
        await _supabase.from('luck_card_plays').insert({
          'user_id': userId,
          'result': result,
          'points_earned': points,
        });

        await _supabase
            .from('user_progress')
            .update({'luck_points': _totalLuckPoints + points})
            .eq('user_id', userId);
      }
    } catch (e) {
      debugPrint('Error saving luck card play: $e');
    }

    setState(() {
      _revealedResult = result;
      _playsRemaining--;
      _totalLuckPoints += points;
    });

    _flipController.forward(from: 0);
    if (result == 'win') {
      _sparkleController.forward(from: 0);
    }

    if (result == 'joker' && mounted) {
      await Future.delayed(const Duration(milliseconds: 300));
      _showJokerPopup();
    }
  }

  void _showJokerPopup() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2D1B4E), Color(0xFF1A1035)],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.purple.withValues(alpha: 0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withValues(alpha: 0.5),
                blurRadius: 50,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🃏', style: TextStyle(fontSize: 80))
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.15, 1.15),
                    duration: 700.ms,
                  ),
              const SizedBox(height: 24),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Colors.amber, Colors.orange],
                ).createShader(bounds),
                child: Text(
                  'CONGRATULATIONS!',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _userName,
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'You are the JOKER today!',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 10,
                ),
                child: Text(
                  'Got It!',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ).animate().scale(curve: Curves.elasticOut, duration: 500.ms),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 300,
        child: Center(
          child: CircularProgressIndicator(color: AppPallete.primary),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppPallete.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppPallete.primary.withValues(alpha: 0.2)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppPallete.surface,
            AppPallete.primary.withValues(alpha: _isShuffling ? 0.12 : 0.04),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppPallete.primary.withValues(alpha: _isShuffling ? 0.3 : 0.15),
            blurRadius: _isShuffling ? 40 : 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppPallete.primary.withValues(alpha: 0.2),
                          AppPallete.secondary.withValues(alpha: 0.15),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.style_rounded,
                      color: AppPallete.primary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lucky Draw',
                        style: GoogleFonts.poppins(
                          color: AppPallete.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$_playsRemaining plays remaining',
                        style: const TextStyle(
                          color: AppPallete.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Shuffle Button
              GestureDetector(
                onTap: _playsRemaining > 0 ? _shuffleCards : null,
                child: AnimatedBuilder(
                  animation: _shuffleController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _shuffleController.value * 2 * 3.14159,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: _playsRemaining > 0
                              ? const LinearGradient(
                                  colors: [
                                    AppPallete.primary,
                                    AppPallete.secondary,
                                  ],
                                )
                              : null,
                          color: _playsRemaining > 0
                              ? null
                              : Colors.grey.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: _playsRemaining > 0
                              ? [
                                  BoxShadow(
                                    color: AppPallete.primary.withValues(
                                      alpha: 0.4,
                                    ),
                                    blurRadius: 12,
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          Icons.shuffle_rounded,
                          color: _playsRemaining > 0
                              ? Colors.white
                              : Colors.grey,
                          size: 24,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Points Display
          AnimatedBuilder(
            animation: _pulseController,
            builder: (_, __) => Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.amber.withValues(alpha: 0.15),
                    Colors.orange.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.amber.withValues(
                    alpha: 0.2 + _pulseController.value * 0.3,
                  ),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withValues(
                      alpha: _pulseController.value * 0.15,
                    ),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.stars_rounded,
                      color: Colors.amber,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    '$_totalLuckPoints',
                    style: GoogleFonts.poppins(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: AppPallete.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'POINTS',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.amber.shade700,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 28),

          // Sparkle burst effect on win
          Stack(
            alignment: Alignment.center,
            children: [
              if (_revealedResult == 'win')
                AnimatedBuilder(
                  animation: _sparkleController,
                  builder: (_, __) {
                    return Opacity(
                      opacity: (1 - _sparkleController.value).clamp(0, 1),
                      child: Transform.scale(
                        scale: 0.5 + _sparkleController.value * 1.5,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Colors.amber.withValues(alpha: 0.4),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              // Cards Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(3, (index) => _buildCard(index)),
              ),
            ],
          ),

          // Result Message
          if (_revealedResult != null)
            Container(
              margin: const EdgeInsets.only(top: 24),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _revealedResult == 'win'
                      ? [
                          Colors.green.withValues(alpha: 0.2),
                          Colors.green.withValues(alpha: 0.1),
                        ]
                      : _revealedResult == 'joker'
                      ? [
                          Colors.purple.withValues(alpha: 0.2),
                          Colors.purple.withValues(alpha: 0.1),
                        ]
                      : [
                          Colors.orange.withValues(alpha: 0.2),
                          Colors.orange.withValues(alpha: 0.1),
                        ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color:
                      (_revealedResult == 'win'
                              ? Colors.green
                              : _revealedResult == 'joker'
                              ? Colors.purple
                              : Colors.orange)
                          .withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _revealedResult == 'win'
                        ? '🎉'
                        : _revealedResult == 'joker'
                        ? '🃏'
                        : '💪',
                    style: const TextStyle(fontSize: 26),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    _revealedResult == 'win'
                        ? 'You Won +10 Points!'
                        : _revealedResult == 'joker'
                        ? 'Joker! 0 Points'
                        : '+2 Points, Try Again!',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _revealedResult == 'win'
                          ? Colors.green
                          : _revealedResult == 'joker'
                          ? Colors.purple
                          : Colors.orange,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: 0.15),
        ],
      ),
    );
  }

  Widget _buildCard(int index) {
    final isSelected = _selectedCardIndex == index;
    final isRevealed = isSelected && _revealedResult != null;
    final isDisabled = _playsRemaining <= 0 || _selectedCardIndex != null;
    final isAvailable = !isDisabled && !isSelected;

    return GestureDetector(
      onTap: () => _selectCard(index),
      child: AnimatedBuilder(
        animation: Listenable.merge([_shuffleController, _pulseController]),
        builder: (context, child) {
          final shuffleOffset = _isShuffling
              ? sin(_shuffleController.value * 3.14159 * 4 + index * 2) * 20
              : 0.0;

          final pulseScale = isAvailable
              ? 1.0 + (_pulseController.value * 0.02)
              : 1.0;

          return Transform.translate(
            offset: Offset(shuffleOffset, 0),
            child: Transform.scale(
              scale: pulseScale,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                width: isSelected ? 110 : 100,
                height: isSelected ? 160 : 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: isRevealed
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: _revealedResult == 'win'
                              ? [
                                  const Color(0xFF1B5E20),
                                  const Color(0xFF2E7D32),
                                ]
                              : _revealedResult == 'lose'
                              ? [
                                  const Color(0xFFE65100),
                                  const Color(0xFFF57C00),
                                ]
                              : [
                                  const Color(0xFF4A148C),
                                  const Color(0xFF7B1FA2),
                                ],
                        )
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDisabled
                              ? [
                                  const Color(0xFF424242),
                                  const Color(0xFF616161),
                                ]
                              : [AppPallete.primary, AppPallete.secondary],
                        ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? Colors.amber.withValues(alpha: 0.6)
                          : isAvailable
                          ? AppPallete.primary.withValues(alpha: 0.4)
                          : Colors.black.withValues(alpha: 0.3),
                      blurRadius: isSelected ? 25 : 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  border: Border.all(
                    color: isSelected
                        ? Colors.amber
                        : Colors.white.withValues(alpha: 0.15),
                    width: isSelected ? 3 : 1.5,
                  ),
                ),
                child: Stack(
                  children: [
                    // Inner gradient overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withValues(alpha: 0.15),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.1),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Content
                    Center(
                      child: isRevealed
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _revealedResult == 'win'
                                      ? '🏆'
                                      : _revealedResult == 'lose'
                                      ? '😅'
                                      : '🃏',
                                  style: const TextStyle(fontSize: 40),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _revealedResult == 'win'
                                        ? '+10'
                                        : _revealedResult == 'lose'
                                        ? '+2'
                                        : '0',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ).animate().fadeIn().scale()
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withValues(alpha: 0.15),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '?',
                                      style: GoogleFonts.poppins(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white.withValues(
                                          alpha: isDisabled ? 0.4 : 0.9,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(
                                      alpha: isDisabled ? 0.05 : 0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    isDisabled ? 'LOCKED' : 'TAP',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white.withValues(
                                        alpha: isDisabled ? 0.4 : 0.8,
                                      ),
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
