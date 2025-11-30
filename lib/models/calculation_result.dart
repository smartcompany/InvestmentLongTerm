import 'package:fl_chart/fl_chart.dart';

class CalculationResult {
  final double totalInvested;
  final double finalValue;
  final double cagr;
  final double yieldRate;
  final List<FlSpot> investedSpots;
  final List<FlSpot> valueSpots;

  CalculationResult({
    required this.totalInvested,
    required this.finalValue,
    required this.cagr,
    required this.yieldRate,
    required this.investedSpots,
    required this.valueSpots,
  });
}
