import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../utils/colors.dart';

class RaceChartData {
  final String assetId;
  final String name;
  final String icon;
  final Color color;
  final List<FlSpot> spots;
  final double currentGrowthRate;
  final int rank; // 0-based rank

  RaceChartData({
    required this.assetId,
    required this.name,
    required this.icon,
    required this.color,
    required this.spots,
    required this.currentGrowthRate,
    required this.rank,
  });
}

class RaceChart extends StatelessWidget {
  final List<RaceChartData> series;
  final double maxX;
  final double minX;
  final double maxY;
  final double minY;

  const RaceChart({
    super.key,
    required this.series,
    required this.maxX,
    this.minX = 0.0,
    required this.maxY,
    required this.minY,
  });

  @override
  Widget build(BuildContext context) {
    // 순위에 따라 정렬 (rank 오름차순)
    final sortedSeries = [...series]..sort((a, b) => a.rank.compareTo(b.rank));

    return Stack(
      children: [
        // 차트는 전체 영역 사용
        LineChart(
          LineChartData(
            gridData: FlGridData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: sortedSeries.map((data) {
              return LineChartBarData(
                spots: data.spots,
                isCurved: true,
                color: data.color,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(show: false),
                belowBarData: BarAreaData(show: false),
              );
            }).toList(),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (touchedSpot) => AppColors.navyMedium,
                tooltipPadding: EdgeInsets.all(12),
                tooltipMargin: 16,
                getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                  if (touchedBarSpots.isEmpty) return [];

                  // 날짜는 한 번만 계산 (모든 spot이 같은 날짜이므로)
                  final firstSpot = touchedBarSpots.first;
                  final date = DateTime.fromMillisecondsSinceEpoch(
                    firstSpot.x.toInt(),
                  );
                  final formattedDate = DateFormat('yyyy-MM-dd').format(date);

                  return touchedBarSpots.asMap().entries.map((entry) {
                    final index = entry.key;
                    final barSpot = entry.value;
                    final flSpot = barSpot;
                    final seriesData = sortedSeries[barSpot.barIndex];
                    final isLast = index == touchedBarSpots.length - 1;

                    // Y축 값은 포트폴리오 가치 (원 단위), 초기 투자금 100만원 기준으로 수익률 계산
                    const initialInvestment = 1000000.0;
                    final currentValue = flSpot.y;
                    final growthRate =
                        ((currentValue - initialInvestment) /
                            initialInvestment) *
                        100;
                    final formattedRate =
                        '${growthRate >= 0 ? '+' : ''}${growthRate.toStringAsFixed(1)}%';

                    final text = isLast
                        ? '${seriesData.name}: $formattedRate\n$formattedDate'
                        : '${seriesData.name}: $formattedRate';

                    return LineTooltipItem(
                      text,
                      TextStyle(
                        color: seriesData.color,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }).toList();
                },
              ),
            ),
            minX: minX,
            maxX: maxX,
            minY: minY,
            maxY: maxY,
          ),
        ),
        // 왼쪽 상단에 자산 목록 표시
        Positioned(
          left: 0,
          top: 0,
          width: 160,
          child: Padding(
            padding: EdgeInsets.only(top: 8, right: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: sortedSeries.map((data) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(data.icon, style: TextStyle(fontSize: 16)),
                      SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          data.name,
                          style: TextStyle(
                            color: data.color,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 4),
                      Text(
                        '${data.currentGrowthRate >= 0 ? '+' : ''}${data.currentGrowthRate.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: data.currentGrowthRate >= 0
                              ? AppColors.success
                              : Colors.red,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
