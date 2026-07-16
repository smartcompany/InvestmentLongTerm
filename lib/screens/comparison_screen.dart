import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/investment_config.dart';
import '../models/calculation_result.dart';
import '../providers/app_state_provider.dart';
import '../providers/currency_provider.dart';
import '../utils/calculator.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';
import '../widgets/comparison_chart.dart';
import '../widgets/liquid_glass.dart';

class ComparisonScreen extends StatelessWidget {
  const ComparisonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppStateProvider>();
    final config = provider.config;

    final singleConfig = InvestmentConfig(
      asset: config.asset,
      yearsAgo: config.yearsAgo,
      amount: config.amount,
      type: InvestmentType.single,
      frequency: Frequency.monthly,
    );
    final singleResult = InvestmentCalculator.calculate(singleConfig);

    final recurringConfig = InvestmentConfig(
      asset: config.asset,
      yearsAgo: config.yearsAgo,
      amount: config.amount,
      type: InvestmentType.recurring,
      frequency: Frequency.monthly,
    );
    final recurringResult = InvestmentCalculator.calculate(recurringConfig);

    final currencySymbol = CurrencyProvider.shared.getCurrencySymbol();
    final currencyFormat = NumberFormat.currency(
      symbol: currencySymbol,
      decimalDigits: 0,
    );
    final chartSeries = [
      ComparisonSeries(
        label: "단일 투자",
        spots: singleResult.valueSpots,
        color: AppColors.primary,
        highlightStart: true,
      ),
      ComparisonSeries(
        label: "정기 투자 (매월)",
        spots: recurringResult.valueSpots,
        color: AppColors.success,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "투자 방식 비교",
          style: AppTextStyles.appBarTitle,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "자산 성장 비교",
              style: AppTextStyles.chartSectionTitle,
            ),
            const SizedBox(height: 20),
            LiquidGlass(
              blur: 10,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border, width: 1.5),
              ),
              child: Container(
                height: 300,
                padding: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
                child: ComparisonChart(
                  series: chartSeries,
                  currencySymbol: currencySymbol,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem("단일 투자", AppColors.primary),
                const SizedBox(width: 20),
                _buildLegendItem("정기 투자 (매월)", AppColors.success),
              ],
            ),
            const SizedBox(height: 40),
            Text(
              "최종 결과 비교",
              style: AppTextStyles.chartSectionTitle,
            ),
            const SizedBox(height: 16),
            _buildComparisonCard(
              "단일 투자 (거치식)",
              singleResult,
              currencyFormat,
              AppColors.primary,
            ),
            const SizedBox(height: 16),
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
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
      ),
      padding: const EdgeInsets.all(20),
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
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "최종 가치",
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    format.format(result.finalValue),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    "수익률",
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
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
          const SizedBox(height: 12),
          const Divider(color: AppColors.border),
          const SizedBox(height: 12),
          Text(
            "총 투자금: ${format.format(result.totalInvested)}",
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
