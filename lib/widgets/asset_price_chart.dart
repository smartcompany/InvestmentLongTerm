import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../utils/colors.dart';
import '../widgets/liquid_glass.dart';

/// 자산 가격 그래프 공통 위젯
/// 통화 변환, 날짜 표시, 툴팁 등이 포함된 완전한 그래프 위젯
class AssetPriceChart extends StatelessWidget {
  final List<FlSpot> spots;
  final DateTime? startDate;
  final DateTime? endDate;
  final String currencySymbol;
  final double? height;
  final bool showGrid;
  final bool showAxisLabels;

  const AssetPriceChart({
    super.key,
    required this.spots,
    required this.startDate,
    required this.endDate,
    required this.currencySymbol,
    this.height,
    this.showGrid = true,
    this.showAxisLabels = true,
  });

  @override
  Widget build(BuildContext context) {
    if (spots.isEmpty) {
      return Container(
        height: height ?? 200,
        child: Center(
          child: Text('데이터가 없습니다', style: TextStyle(color: AppColors.slate400)),
        ),
      );
    }

    final chartWidget = LineChart(
      LineChartData(
        gridData: showGrid
            ? FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: _calculatePriceInterval(spots),
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: AppColors.slate700.withOpacity(0.2),
                    strokeWidth: 1,
                  );
                },
              )
            : FlGridData(show: false),
        titlesData: showAxisLabels
            ? FlTitlesData(
                show: true,
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(reservedSize: 0),
                ),
                topTitles: AxisTitles(sideTitles: SideTitles(reservedSize: 0)),
                bottomTitles: startDate != null && endDate != null &&
                        spots.isNotEmpty
                    ? AxisTitles(
                        sideTitles: SideTitles(
                          reservedSize: 30,
                          interval: 0.25,
                          getTitlesWidget: (value, meta) {
                            final totalDays = endDate!
                                .difference(startDate!)
                                .inDays;
                            final maxX = spots
                                .map((s) => s.x)
                                .reduce((a, b) => a > b ? a : b);
                            final normalizedX =
                                maxX > 0 ? (value / maxX) : 0.0;
                            final daysFromStart =
                                (normalizedX * totalDays).round();
                            final date = startDate!.add(
                              Duration(days: daysFromStart),
                            );
                            return Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text(
                                DateFormat('MM/dd').format(date),
                                style: TextStyle(
                                  color: AppColors.slate400,
                                  fontSize: 10,
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    : AxisTitles(sideTitles: SideTitles(reservedSize: 0)),
                leftTitles: showGrid
                    ? AxisTitles(
                        sideTitles: SideTitles(
                          reservedSize: 50,
                          interval: _calculatePriceInterval(spots),
                          getTitlesWidget: (value, meta) {
                            return Text(
                              NumberFormat('#,###').format(value),
                              style: TextStyle(
                                color: AppColors.slate400,
                                fontSize: 10,
                              ),
                            );
                          },
                        ),
                      )
                    : AxisTitles(sideTitles: SideTitles(reservedSize: 0)),
              )
            : FlTitlesData(show: false),
        borderData: showGrid
            ? FlBorderData(
                show: true,
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.slate700.withOpacity(0.3),
                    width: 1,
                  ),
                  left: BorderSide(
                    color: AppColors.slate700.withOpacity(0.3),
                    width: 1,
                  ),
                ),
              )
            : FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.gold,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.gold.withOpacity(0.1),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => AppColors.navyMedium,
            tooltipPadding: EdgeInsets.all(12),
            tooltipMargin: 16,
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              // 날짜 계산: 서버는 x를 년 단위(0~yearsAgo)로 보내므로, 0~1로 정규화 후 날짜 계산
              DateTime? selectedDate;
              if (startDate != null && endDate != null && spots.isNotEmpty) {
                final totalDays = endDate!.difference(startDate!).inDays;
                final maxX = spots.map((s) => s.x).reduce((a, b) => a > b ? a : b);
                final x = touchedBarSpots.first.x;
                final normalizedX = maxX > 0 ? (x / maxX) : 0.0;
                final daysFromStart = (normalizedX * totalDays).round();
                selectedDate = startDate!.add(Duration(days: daysFromStart));
              }

              // 그래프 데이터는 이미 선택된 통화로 변환되어 있으므로 그대로 표시
              final value = touchedBarSpots.first.y;

              // 가격과 날짜를 하나의 LineTooltipItem에 표시 (줄바꿈 사용)
              String tooltipText =
                  '$currencySymbol${NumberFormat('#,###').format(value)}';
              if (selectedDate != null) {
                tooltipText +=
                    '\n${DateFormat('yyyy-MM-dd').format(selectedDate)}';
              }

              // touchedBarSpots의 각 항목마다 정확히 하나의 LineTooltipItem 반환
              return touchedBarSpots.map((barSpot) {
                return LineTooltipItem(
                  tooltipText,
                  TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold),
                );
              }).toList();
            },
          ),
        ),
      ),
    );

    if (height != null) {
      return Container(
        height: height,
        child: LiquidGlass(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.18),
              width: 1.5,
            ),
          ),
          padding: EdgeInsets.all(16),
          child: chartWidget,
        ),
      );
    }

    return LiquidGlass(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.18), width: 1.5),
      ),
      padding: EdgeInsets.all(16),
      child: chartWidget,
    );
  }

  double _calculatePriceInterval(List<FlSpot> spots) {
    if (spots.isEmpty) return 1000;
    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final range = maxY - minY;
    if (range <= 0) return 1000;

    // 적절한 간격 계산 (약 4-5개의 눈금)
    final interval = range / 4;

    // 반올림하여 깔끔한 숫자로 만들기
    final magnitude = (interval).toStringAsFixed(0).length - 1;
    final factor = math.pow(10, magnitude).toDouble();
    return (interval / factor).ceil() * factor;
  }
}
