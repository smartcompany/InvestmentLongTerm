import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/colors.dart';

class ComparisonSeries {
  final String label;
  final List<FlSpot> spots;
  final Color color;
  final bool highlightStart;
  final int renderPriority;
  final List<int>? dashArray;
  final double? barWidth;

  const ComparisonSeries({
    required this.label,
    required this.spots,
    required this.color,
    this.highlightStart = false,
    this.renderPriority = 0,
    this.dashArray,
    this.barWidth,
  });
}

class ComparisonChart extends StatelessWidget {
  final List<ComparisonSeries> series;
  final String currencySymbol;

  const ComparisonChart({
    super.key,
    required this.series,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final sortedSeries = [...series]
      ..sort((a, b) => a.renderPriority.compareTo(b.renderPriority));

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [for (final entry in sortedSeries) _buildLine(entry)],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => AppColors.navyMedium,
            tooltipPadding: EdgeInsets.all(12),
            tooltipMargin: 16,
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              final numberFormat = NumberFormat('#,###');
              return touchedBarSpots.map((barSpot) {
                final flSpot = barSpot;
                final seriesData = sortedSeries[barSpot.barIndex];
                return LineTooltipItem(
                  '${seriesData.label}: $currencySymbol${numberFormat.format(flSpot.y)}',
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
      barWidth: entry.barWidth ?? 3,
      isStrokeCapRound: true,
      dashArray: entry.dashArray,
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
