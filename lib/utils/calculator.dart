import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import '../models/investment_config.dart';
import '../models/calculation_result.dart';

class InvestmentCalculator {
  static const Map<String, double> growthRates = {
    'bitcoin': 0.85, // 85% annual growth
    'ethereum': 0.95,
    'tesla': 0.45,
    'google': 0.18,
  };

  static CalculationResult calculate(InvestmentConfig config) {
    final annualRate = growthRates[config.asset] ?? 0.0;
    final monthlyRate = pow(1 + annualRate, 1 / 12) - 1;
    final weeklyRate = pow(1 + annualRate, 1 / 52) - 1;

    double totalInvested = 0;
    double currentValue = 0;
    List<FlSpot> investedSpots = [];
    List<FlSpot> valueSpots = [];

    int totalMonths = config.yearsAgo * 12;
    int totalWeeks = config.yearsAgo * 52;

    if (config.type == InvestmentType.single) {
      totalInvested = config.amount;
      currentValue = config.amount * pow(1 + annualRate, config.yearsAgo);

      // Generate spots for chart (monthly points)
      for (int i = 0; i <= totalMonths; i++) {
        double t = i / 12.0;
        double val = config.amount * pow(1 + annualRate, t);
        investedSpots.add(FlSpot(t, config.amount));
        valueSpots.add(FlSpot(t, val));
      }
    } else {
      // Recurring investment
      double periodRate = config.frequency == Frequency.monthly
          ? monthlyRate.toDouble()
          : weeklyRate.toDouble();
      int totalPeriods = config.frequency == Frequency.monthly
          ? totalMonths
          : totalWeeks;
      double periodsPerYear = config.frequency == Frequency.monthly
          ? 12.0
          : 52.0;

      // Calculate per-period investment amount by dividing total amount by number of periods
      double perPeriodAmount = config.amount / totalPeriods;

      for (int i = 0; i <= totalPeriods; i++) {
        // Add investment at the beginning of period
        if (i < totalPeriods) {
          totalInvested += perPeriodAmount;
          currentValue += perPeriodAmount;
        }

        // Record spot (convert period to years)
        double t = i / periodsPerYear;
        investedSpots.add(FlSpot(t, totalInvested));
        valueSpots.add(FlSpot(t, currentValue));

        // Apply growth for this period
        if (i < totalPeriods) {
          currentValue *= (1 + periodRate);
        }
      }
    }

    double yieldRate = (currentValue - totalInvested) / totalInvested * 100;
    // CAGR formula: (End Value / Start Value)^(1/n) - 1
    // For recurring, it's more complex, but we can use IRR or simple approximation.
    // Here we use the simple CAGR of the total portfolio value vs total invested over time?
    // Actually, standard CAGR is for single lump sum.
    // For recurring, we can just show the effective annual return or just keep the growth rate.
    // Let's stick to the requested formula: CAGR = pow(finalValue / totalInvested, 1 / years) - 1
    // Note: This formula is technically for lump sum, but requested in prompt.
    double cagr = 0;
    if (totalInvested > 0 && config.yearsAgo > 0) {
      cagr = (pow(currentValue / totalInvested, 1 / config.yearsAgo) - 1) * 100;
    }

    return CalculationResult(
      totalInvested: totalInvested,
      finalValue: currentValue,
      cagr: cagr,
      yieldRate: yieldRate,
      investedSpots: investedSpots,
      valueSpots: valueSpots,
    );
  }
}
