import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_pallete.dart';

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPallete.background,
      appBar: AppBar(
        title: Text(
          "Performance",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Marks Overview
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppPallete.primaryGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppPallete.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _InfoItem(label: "Average", value: "85%"),
                  Container(width: 1, height: 40, color: Colors.white24),
                  _InfoItem(label: "Tests Taken", value: "12"),
                  Container(width: 1, height: 40, color: Colors.white24),
                  _InfoItem(label: "Ranking", value: "#4"),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Subjects Chart (Radar)
            Text(
              "Subject Strength",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              height: 300,
              child: RadarChart(
                RadarChartData(
                  dataSets: [
                    RadarDataSet(
                      fillColor: AppPallete.primary.withValues(alpha: 0.2),
                      borderColor: AppPallete.primary,
                      entryRadius: 3,
                      dataEntries: [
                        const RadarEntry(value: 80), // Physics
                        const RadarEntry(value: 60), // Chem
                        const RadarEntry(value: 90), // Math
                        const RadarEntry(value: 75), // Bio
                        const RadarEntry(value: 85), // Eng
                      ],
                    ),
                  ],
                  radarBackgroundColor: Colors.transparent,
                  borderData: FlBorderData(show: false),
                  radarBorderData: const BorderSide(color: Colors.transparent),
                  titlePositionPercentageOffset: 0.2,
                  titleTextStyle: const TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                  ),
                  tickCount: 1,
                  ticksTextStyle: const TextStyle(color: Colors.transparent),
                  tickBorderData: const BorderSide(color: Colors.transparent),
                  gridBorderData: BorderSide(
                    color: Colors.grey[300]!,
                    width: 1,
                  ),
                  getTitle: (index, angle) {
                    const titles = [
                      "Physics",
                      "Chemistry",
                      "Math",
                      "Biology",
                      "English",
                    ];
                    return RadarChartTitle(text: titles[index]);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  const _InfoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
        ),
      ],
    );
  }
}
