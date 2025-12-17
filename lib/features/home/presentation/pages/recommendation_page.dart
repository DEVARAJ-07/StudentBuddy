import 'package:flutter/material.dart';
import '../../../../core/theme/app_pallete.dart';
import '../../../../core/common/widgets/glass_container.dart';

class RecommendationPage extends StatelessWidget {
  const RecommendationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPallete.background,
      appBar: AppBar(
        title: const Text("Recommendations"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: GlassContainer(
          padding: const EdgeInsets.all(20),
          borderRadius: BorderRadius.circular(20),
          blur: 10,
          opacity: 0.1,
          child: const Text("Recommendation Content Coming Soon!"),
        ),
      ),
    );
  }
}
