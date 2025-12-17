import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_pallete.dart';
import '../widgets/neural_hologram.dart';
import 'welcome_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    // Navigate to Welcome Page after animation
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, a, b) => const WelcomePage(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPallete.primary,
      body: Center(
        child:
            Hero(
                  tag: 'app_logo',
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: const BoxDecoration(shape: BoxShape.circle),
                    child: const NeuralHologram(size: 200),
                  ),
                )
                .animate()
                .scale(duration: 1.seconds, curve: Curves.easeOutBack)
                .fadeIn(duration: 800.ms)
                .fadeOut(duration: 500.ms, delay: 1.seconds),
      ),
    );
  }
}
