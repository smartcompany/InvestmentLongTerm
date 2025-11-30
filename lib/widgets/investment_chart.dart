import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../utils/colors.dart';

class InvestmentChart extends StatelessWidget {
  final List<FlSpot> investedSpots;
  final List<FlSpot> valueSpots;

  const InvestmentChart({
    super.key,
    required this.investedSpots,
    required this.valueSpots,
  });

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: investedSpots,
            isCurved: true,
            color: AppColors.slate700,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
          LineChartBarData(
            spots: valueSpots,
            isCurved: true,
            color: AppColors.gold,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.gold.withValues(alpha: 0.1),
            ),
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
                return LineTooltipItem(
                  '\$${flSpot.y.toStringAsFixed(0)}',
                  TextStyle(
                    color: barSpot.barIndex == 1
                        ? AppColors.gold
                        : AppColors.slate400,
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
