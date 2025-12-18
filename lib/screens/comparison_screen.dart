import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/investment_config.dart';
import '../models/calculation_result.dart';
import '../providers/app_state_provider.dart';
import '../utils/calculator.dart';
import '../utils/colors.dart';
import '../widgets/comparison_chart.dart';
import '../widgets/liquid_glass.dart';

class ComparisonScreen extends StatelessWidget {
  const ComparisonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppStateProvider>();
    final config = provider.config;

    // Calculate for Single Investment
    final singleConfig = InvestmentConfig(
      asset: config.asset,
      yearsAgo: config.yearsAgo,
      amount: config.amount,
      type: InvestmentType.single,
      frequency: Frequency.monthly, // Frequency doesn't matter for single
    );
    final singleResult = InvestmentCalculator.calculate(singleConfig);

    // Calculate for Recurring Investment
    final recurringConfig = InvestmentConfig(
      asset: config.asset,
      yearsAgo: config.yearsAgo,
      amount: config.amount,
      type: InvestmentType.recurring,
      frequency: Frequency.monthly, // Default to monthly for comparison
    );
    final recurringResult = InvestmentCalculator.calculate(recurringConfig);

    final currencyFormat = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 0,
    );
    final chartSeries = [
      ComparisonSeries(
        label: "단일 투자",
        spots: singleResult.valueSpots,
        color: AppColors.gold,
        highlightStart: true,
      ),
      ComparisonSeries(
        label: "정기 투자 (매월)",
        spots: recurringResult.valueSpots,
        color: AppColors.success,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.navyDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "투자 방식 비교",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Chart
            Text(
              "자산 성장 비교",
              style: TextStyle(
                color: AppColors.slate300,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            LiquidGlass(
              blur: 10,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.18),
                  width: 1.5,
                ),
              ),
              child: Container(
                height: 300,
                padding: EdgeInsets.only(right: 16, top: 10, bottom: 10),
                child: ComparisonChart(series: chartSeries),
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem("단일 투자", AppColors.gold),
                SizedBox(width: 20),
                _buildLegendItem("정기 투자 (매월)", AppColors.success),
              ],
            ),

            SizedBox(height: 40),

            // Comparison Cards
            Text(
              "최종 결과 비교",
              style: TextStyle(
                color: AppColors.slate300,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            _buildComparisonCard(
              "단일 투자 (거치식)",
              singleResult,
              currencyFormat,
              AppColors.gold,
            ),
            SizedBox(height: 16),
            _buildComparisonCard(
              "정기 투자 (적립식)",
              recurringResult,
              currencyFormat,
              AppColors.success,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 8),
        Text(label, style: TextStyle(color: AppColors.slate300, fontSize: 14)),
      ],
    );
  }

  Widget _buildComparisonCard(
    String title,
    CalculationResult result,
    NumberFormat format,
    Color color,
  ) {
    final percentFormat = NumberFormat.decimalPercentPattern(decimalDigits: 1);

    return LiquidGlass(
      blur: 10,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
      ),
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "최종 가치",
                    style: TextStyle(color: AppColors.slate400, fontSize: 14),
                  ),
                  SizedBox(height: 4),
                  Text(
                    format.format(result.finalValue),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "수익률",
                    style: TextStyle(color: AppColors.slate400, fontSize: 14),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "+${percentFormat.format(result.yieldRate / 100)}",
                    style: TextStyle(
                      color: color,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 12),
          Divider(color: AppColors.slate700),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "총 투자금: ${format.format(result.totalInvested)}",
                style: TextStyle(color: AppColors.slate400, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
