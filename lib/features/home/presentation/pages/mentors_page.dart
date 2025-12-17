import 'package:flutter/material.dart';
import '../../../../core/theme/app_pallete.dart';
import '../../../../core/common/widgets/glass_container.dart';

class MentorsPage extends StatelessWidget {
  const MentorsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: GlassContainer(
          padding: const EdgeInsets.all(20),
          borderRadius: BorderRadius.circular(20),
          blur: 10,
          opacity: 0.1,
          child: const Text(
            "Mentors Page Coming Soon!",
            style: TextStyle(color: AppPallete.textPrimary),
          ),
        ),
      ),
    );
  }
}
