import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/investment_config.dart';
import '../providers/app_state_provider.dart';
import '../utils/colors.dart';
import '../widgets/summary_card.dart';
import '../widgets/investment_chart.dart';
import '../widgets/comparison_chart.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppStateProvider>();
    final result = provider.result;

    if (provider.isLoading) {
      return Scaffold(
        backgroundColor: AppColors.navyDark,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.gold),
              SizedBox(height: 20),
              Text(
                '실제 가격 데이터를 가져오는 중...',
                style: TextStyle(color: AppColors.slate300),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.error != null) {
      return Scaffold(
        backgroundColor: AppColors.navyDark,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 64),
                SizedBox(height: 20),
                Text(
                  '오류가 발생했습니다',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  provider.error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.slate400),
                ),
                SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.navyDark,
                  ),
                  child: Text('돌아가기'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (result == null) {
      return Scaffold(
        backgroundColor: AppColors.navyDark,
        body: Center(child: CircularProgressIndicator(color: AppColors.gold)),
      );
    }

    final currencyFormat = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 0,
    );
    final percentFormat = NumberFormat.decimalPercentPattern(decimalDigits: 1);
    final List<ComparisonSeries> comparisonSeries =
        provider.config.type == InvestmentType.recurring
        ? _buildComparisonSeries(provider)
        : [];

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
          "투자 결과",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main Result Card
            SummaryCard(
              title: "현재 가치",
              value: currencyFormat.format(result.finalValue),
              subtitle: "+${percentFormat.format(result.yieldRate / 100)}",
              isHighlight: true,
            ),
            SizedBox(height: 16),

            // Secondary Cards
            Row(
              children: [
                Expanded(
                  child: SummaryCard(
                    title: "총 투자금",
                    value: currencyFormat.format(result.totalInvested),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: SummaryCard(
                    title: "연평균 수익률 (CAGR)",
                    value: "${result.cagr.toStringAsFixed(1)}%",
                  ),
                ),
              ],
            ),

            SizedBox(height: 40),

            // Chart
            Text(
              provider.config.type == InvestmentType.recurring
                  ? "투자 방식 비교"
                  : "자산 성장 추이",
              style: TextStyle(
                color: AppColors.slate300,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            Container(
              height: 300,
              padding: EdgeInsets.only(right: 16, top: 10, bottom: 10),
              decoration: BoxDecoration(
                color: AppColors.navyMedium,
                borderRadius: BorderRadius.circular(20),
              ),
              child: provider.config.type == InvestmentType.recurring
                  ? _buildComparisonChart(comparisonSeries)
                  : InvestmentChart(
                      investedSpots: result.investedSpots,
                      valueSpots: result.valueSpots,
                    ),
            ),
            if (provider.config.type == InvestmentType.recurring &&
                comparisonSeries.isNotEmpty) ...[
              SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 20,
                runSpacing: 12,
                children: comparisonSeries
                    .map((line) => _buildLegendItem(line.label, line.color))
                    .toList(),
              ),
            ],

            SizedBox(height: 40),

            // Insight Message
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.gold),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                "시간을 친구로 만든다면,\n시장은 당신의 편입니다.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  height: 1.5,
                ),
              ),
            ),

            SizedBox(height: 40),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Share functionality placeholder
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("공유하기 기능은 준비중입니다.")),
                      );
                    },
                    icon: Icon(Icons.share, color: Colors.white),
                    label: Text("공유하기", style: TextStyle(color: Colors.white)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.slate700),
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      provider.reset();
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    icon: Icon(Icons.refresh, color: AppColors.navyDark),
                    label: Text(
                      "다시 계산",
                      style: TextStyle(
                        color: AppColors.navyDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonChart(List<ComparisonSeries> series) {
    if (series.length < 2) {
      return Center(child: CircularProgressIndicator(color: AppColors.gold));
    }

    return ComparisonChart(series: series);
  }

  List<ComparisonSeries> _buildComparisonSeries(AppStateProvider provider) {
    final singleResult = provider.singleResult;
    if (singleResult == null) return [];

    final List<ComparisonSeries> series = [
      ComparisonSeries(
        label: "단일 투자",
        color: AppColors.gold,
        spots: singleResult.valueSpots,
        highlightStart: true,
      ),
    ];

    provider.config.selectedFrequencies.forEach((frequency) {
      final result = provider.recurringResults[frequency];
      if (result == null) return;

      final label = "정기 투자 (${frequency == Frequency.monthly ? '매월' : '매주'})";
      final color = frequency == Frequency.monthly
          ? AppColors.success
          : AppColors.info;

      series.add(
        ComparisonSeries(label: label, color: color, spots: result.valueSpots),
      );
    });

    return series;
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
}
