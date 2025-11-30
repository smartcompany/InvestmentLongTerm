import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../utils/colors.dart';

class ComparisonSeries {
  final String label;
  final List<FlSpot> spots;
  final Color color;
  final bool highlightStart;

  const ComparisonSeries({
    required this.label,
    required this.spots,
    required this.color,
    this.highlightStart = false,
  });
}

class ComparisonChart extends StatelessWidget {
  final List<ComparisonSeries> series;

  const ComparisonChart({super.key, required this.series});

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [for (final entry in series) _buildLine(entry)],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => AppColors.navyMedium,
            tooltipPadding: EdgeInsets.all(12),
            tooltipMargin: 16,
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                final flSpot = barSpot;
                final seriesData = series[barSpot.barIndex];
                return LineTooltipItem(
                  '${seriesData.label}: \$${flSpot.y.toStringAsFixed(0)}',
                  TextStyle(
                    color: seriesData.color,
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

  LineChartBarData _buildLine(ComparisonSeries entry) {
    final double? startX = entry.spots.isNotEmpty ? entry.spots.first.x : null;

    return LineChartBarData(
      spots: entry.spots,
      isCurved: true,
      color: entry.color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: entry.highlightStart && startX != null,
        checkToShowDot: (spot, barData) {
          if (startX == null) return false;
          return (spot.x - startX).abs() < 0.0001;
        },
        getDotPainter: (spot, percent, barData, index) {
          return FlDotCirclePainter(
            radius: 6,
            color: entry.color,
            strokeWidth: 2,
            strokeColor: Colors.white,
          );
        },
      ),
      belowBarData: BarAreaData(show: false),
    );
  }
}
