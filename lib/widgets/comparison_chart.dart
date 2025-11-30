import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../utils/colors.dart';

class ComparisonChart extends StatelessWidget {
  final List<FlSpot> singleSpots;
  final List<FlSpot> recurringSpots;

  const ComparisonChart({
    super.key,
    required this.singleSpots,
    required this.recurringSpots,
  });

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          // Single Investment Line
          LineChartBarData(
            spots: singleSpots,
            isCurved: true,
            color: AppColors.gold,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
          // Recurring Investment Line
          LineChartBarData(
            spots: recurringSpots,
            isCurved: true,
            color: AppColors.success,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => AppColors.navyMedium,
            tooltipPadding: EdgeInsets.all(12),
            tooltipMargin: 16,
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                final flSpot = barSpot;
                final isSingle = barSpot.barIndex == 0;
                return LineTooltipItem(
                  '${isSingle ? "단일" : "정기"}: \$${flSpot.y.toStringAsFixed(0)}',
                  TextStyle(
                    color: isSingle ? AppColors.gold : AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}
