import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_pallete.dart';
import '../../../../core/common/widgets/glass_container.dart';

class StatsGraphWidget extends StatelessWidget {
  const StatsGraphWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      height: 300,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(20),
      blur: 15,
      opacity: 0.1,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Performance Overview",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const style = TextStyle(
                          color: Colors.black54,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        );
                        String text;
                        switch (value.toInt()) {
                          case 0:
                            text = 'Mon';
                            break;
                          case 2:
                            text = 'Tue';
                            break;
                          case 4:
                            text = 'Wed';
                            break;
                          case 6:
                            text = 'Thu';
                            break;
                          case 8:
                            text = 'Fri';
                            break;
                          case 10:
                            text = 'Sat';
                            break;
                          default:
                            return Container();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(text, style: style),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 10,
                minY: 0,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 40),
                      FlSpot(2, 65),
                      FlSpot(4, 55),
                      FlSpot(6, 80),
                      FlSpot(8, 70),
                      FlSpot(10, 90),
                    ],
                    isCurved: true,
                    color: AppPallete.primary,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppPallete.primary.withValues(alpha: 0.2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
