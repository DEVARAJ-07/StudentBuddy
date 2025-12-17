import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/common/widgets/glass_container.dart';
import '../widgets/course_card.dart';

class StudentExploreView extends StatelessWidget {
  const StudentExploreView({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = [
      {'name': 'Development', 'icon': Icons.code, 'color': Colors.blue},
      {'name': 'Design', 'icon': Icons.brush, 'color': Colors.purple},
      {'name': 'Business', 'icon': Icons.work, 'color': Colors.orange},
      {'name': 'Marketing', 'icon': Icons.campaign, 'color': Colors.red},
      {'name': 'Music', 'icon': Icons.music_note, 'color': Colors.pink},
      {'name': 'Photography', 'icon': Icons.camera_alt, 'color': Colors.green},
    ];

    return Scaffold(
      backgroundColor:
          Colors.transparent, // Background handled by main Dashboard
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Explore",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 20),
                    GlassContainer(
                      height: 55,
                      borderRadius: BorderRadius.circular(15),
                      blur: 15,
                      opacity: 0.1,
                      child: const TextField(
                        decoration: InputDecoration(
                          hintText: "Search for anything...",
                          hintStyle: TextStyle(color: Colors.black45),
                          prefixIcon: Icon(Icons.search, color: Colors.black54),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Categories
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 15,
                  crossAxisSpacing: 15,
                  childAspectRatio: 2.2,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final category = categories[index];
                  return GlassContainer(
                    borderRadius: BorderRadius.circular(15),
                    blur: 10,
                    opacity: 0.1,
                    color: (category['color'] as Color).withValues(alpha: 0.1),
                    border: Border.all(
                      color: (category['color'] as Color).withValues(
                        alpha: 0.2,
                      ),
                    ),
                    child: InkWell(
                      onTap: () {},
                      borderRadius: BorderRadius.circular(15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            category['icon'] as IconData,
                            color: category['color'] as Color,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            category['name'] as String,
                            style: TextStyle(
                              color: category['color'] as Color,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().scale(delay: (50 * index).ms).fadeIn();
                }, childCount: categories.length),
              ),
            ),

            // Popular Title
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 30, 20, 10),
                child: Text(
                  "Popular Now",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            // Popular List
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  // Using CourseCard from Home feature but wrapped or modified if needed
                  // reusing existing CourseCard directly
                  return CourseCard(
                    title: "Complete Python Bootcamp",
                    subtitle: "Dr. Angela Yu • 4.8 (12k reviews)",
                    imageUrl:
                        "https://picsum.photos/seed/${index + 200}/300/200",
                    accentColor: Colors.amber,
                    onTap: () {},
                  ).animate().fadeIn(delay: (50 * index).ms).slideX();
                }, childCount: 5),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}
