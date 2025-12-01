import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/calculation_result.dart';
import '../models/investment_config.dart';
import '../providers/app_state_provider.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';
import '../widgets/common_share_ui.dart';
import '../widgets/investment_chart.dart';
import '../widgets/comparison_chart.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppStateProvider>();
    final result = provider.result;
    final l10n = AppLocalizations.of(context)!;

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
                l10n.fetchingPriceData,
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
                  l10n.errorOccurred,
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
                  child: Text(l10n.goBack),
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
    final strategySummaries = _buildStrategySummaries(provider, l10n);
    final localeCode = Localizations.localeOf(context).languageCode;
    final List<ComparisonSeries> comparisonSeries =
        provider.config.type == InvestmentType.recurring
        ? _buildComparisonSeries(provider, l10n)
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
        title: Text(l10n.investmentResults, style: AppTextStyles.appBarTitle),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < strategySummaries.length; i++) ...[
              _buildStrategySummaryCard(
                summary: strategySummaries[i],
                currencyFormat: currencyFormat,
                percentFormat: percentFormat,
                totalInvestment: currencyFormat.format(provider.config.amount),
                showTotalInvestment: i == 0,
                l10n: l10n,
              ),
              SizedBox(height: 24),
            ],
            SizedBox(height: 40),

            // Chart
            Text(
              provider.config.type == InvestmentType.recurring
                  ? l10n.compareInvestmentStrategies
                  : l10n.assetGrowthTrend,
              style: AppTextStyles.chartSectionTitle,
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
                l10n.insightMessage,
                textAlign: TextAlign.center,
                style: AppTextStyles.insightMessage,
              ),
            ),

            SizedBox(height: 40),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final shareText = _buildShareText(
                        provider,
                        localeCode,
                        currencyFormat,
                        percentFormat,
                        strategySummaries,
                        l10n,
                      );
                      CommonShareUI.showShareOptionsDialog(
                        context: context,
                        shareText: shareText,
                      );
                    },
                    icon: Icon(Icons.share, color: Colors.white),
                    label: Text(
                      l10n.share,
                      style: AppTextStyles.shareButtonLabel,
                    ),
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
                      l10n.recalculate,
                      style: AppTextStyles.buttonTextPrimary.copyWith(
                        color: AppColors.navyDark,
                        fontSize: 16,
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

  Widget _buildStrategySummaryCard({
    required _StrategySummary summary,
    required NumberFormat currencyFormat,
    required NumberFormat percentFormat,
    required String totalInvestment,
    required bool showTotalInvestment,
    required AppLocalizations l10n,
  }) {
    final result = summary.result;
    final gain = result.finalValue - result.totalInvested;
    final gainPositive = gain >= 0;
    final gainText =
        "${gainPositive ? '+' : '-'}${currencyFormat.format(gain.abs())}";
    final textColor = summary.highlight ? AppColors.navyDark : Colors.white;
    final secondaryTextColor = summary.highlight
        ? AppColors.navyDark.withValues(alpha: 0.7)
        : AppColors.slate300;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: summary.highlight
                ? LinearGradient(
                    colors: [AppColors.gold, AppColors.goldLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: summary.highlight ? null : AppColors.navyMedium,
            borderRadius: BorderRadius.circular(24),
            border: summary.highlight
                ? null
                : Border.all(color: AppColors.slate700),
            boxShadow: summary.highlight
                ? [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.35),
                      blurRadius: 25,
                      offset: Offset(0, 10),
                    ),
                  ]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    summary.label,
                    style: AppTextStyles.resultCardTitle.copyWith(
                      color: textColor,
                    ),
                  ),
                  Spacer(),
                  if (summary.highlight)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.navyDark.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        l10n.bestReturn,
                        style: AppTextStyles.badgeText,
                      ),
                    ),
                ],
              ),
              SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    currencyFormat.format(result.finalValue),
                    style: AppTextStyles.resultCardValueBig.copyWith(
                      color: textColor,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    percentFormat.format(result.yieldRate / 100),
                    style: AppTextStyles.resultCardYield.copyWith(
                      color: result.yieldRate >= 0
                          ? AppColors.success
                          : Colors.redAccent,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6),
              Text(
                gainText,
                style: AppTextStyles.resultCardGain.copyWith(
                  color: gainPositive ? AppColors.success : Colors.redAccent,
                ),
              ),
              SizedBox(height: 18),
              Divider(
                color: summary.highlight
                    ? AppColors.navyDark.withValues(alpha: 0.1)
                    : AppColors.slate700,
              ),
              SizedBox(height: 14),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _buildStatTile(
                        label: l10n.returnOnInvestment,
                        value: gainText,
                        textColor: textColor,
                        secondaryTextColor: secondaryTextColor,
                        highlight: summary.highlight,
                        l10n: l10n,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildStatTile(
                        label: l10n.cagr,
                        value: "${result.cagr.toStringAsFixed(1)}%",
                        textColor: textColor,
                        secondaryTextColor: secondaryTextColor,
                        highlight: summary.highlight,
                        l10n: l10n,
                      ),
                    ),
                  ],
                ),
              ),
              if (showTotalInvestment) ...[
                SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.savings_outlined,
                      color: summary.highlight
                          ? AppColors.navyDark
                          : AppColors.gold,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Text(
                      l10n.totalInvested(totalInvestment),
                      style: AppTextStyles.resultStatValue.copyWith(
                        color: secondaryTextColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatTile({
    required String label,
    required String value,
    required Color textColor,
    required Color secondaryTextColor,
    required bool highlight,
    required AppLocalizations l10n,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.navyDark.withValues(alpha: 0.08)
            : AppColors.navyDark.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: AppTextStyles.resultStatLabel.copyWith(
              color: secondaryTextColor,
            ),
          ),
          SizedBox(height: 6),
          Text(
            value,
            style: AppTextStyles.resultStatValue.copyWith(color: textColor),
          ),
        ],
      ),
    );
  }

  List<ComparisonSeries> _buildComparisonSeries(
    AppStateProvider provider,
    AppLocalizations l10n,
  ) {
    final singleResult = provider.singleResult;
    if (singleResult == null) return [];

    final List<ComparisonSeries> series = [
      ComparisonSeries(
        label: l10n.singleInvestment,
        color: AppColors.gold,
        spots: singleResult.valueSpots,
        highlightStart: true,
        renderPriority: 2,
      ),
    ];

    final frequencies = provider.config.selectedFrequencies.toList()
      ..sort((a, b) => a.index.compareTo(b.index));

    for (final frequency in frequencies) {
      final result = provider.recurringResults[frequency];
      if (result == null) continue;

      final freqText = frequency == Frequency.monthly
          ? l10n.monthly
          : l10n.weekly;
      final label = "${l10n.recurringInvestment} ($freqText)";
      final color = frequency == Frequency.monthly
          ? AppColors.success
          : AppColors.info;
      final priority = frequency == Frequency.weekly ? 0 : 1;
      final dash = frequency == Frequency.weekly ? [6, 6] : null;
      final width = frequency == Frequency.weekly ? 2.5 : 3.0;

      series.add(
        ComparisonSeries(
          label: label,
          color: color,
          spots: result.valueSpots,
          renderPriority: priority,
          dashArray: dash,
          barWidth: width,
        ),
      );
    }

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
        Text(label, style: AppTextStyles.chartLegend),
      ],
    );
  }

  String _buildShareText(
    AppStateProvider provider,
    String localeCode,
    NumberFormat currencyFormat,
    NumberFormat percentFormat,
    List<_StrategySummary> summaries,
    AppLocalizations l10n,
  ) {
    final buffer = StringBuffer();
    final assetName = provider.assetNameForLocale(localeCode);
    buffer.writeln(l10n.shareTextTitle(provider.config.yearsAgo, assetName));
    for (final summary in summaries) {
      final result = summary.result;
      buffer.writeln(
        "${summary.label}: ${currencyFormat.format(result.finalValue)} (${percentFormat.format(result.yieldRate / 100)})",
      );
    }
    buffer.writeln(
      l10n.totalInvested(currencyFormat.format(provider.config.amount)),
    );
    buffer.writeln(l10n.shareTextFooter);
    return buffer.toString();
  }

  List<_StrategySummary> _buildStrategySummaries(
    AppStateProvider provider,
    AppLocalizations l10n,
  ) {
    final summaries = <_StrategySummary>[];

    if (provider.config.type == InvestmentType.single) {
      final single = provider.singleResult ?? provider.result;
      if (single != null) {
        summaries.add(
          _StrategySummary(
            label: l10n.singleInvestment,
            result: single,
            highlight: true,
          ),
        );
      }
      return summaries;
    }

    final singleResult = provider.singleResult;
    if (singleResult != null) {
      summaries.add(
        _StrategySummary(label: l10n.singleInvestment, result: singleResult),
      );
    }

    final frequencies = provider.config.selectedFrequencies.toList()
      ..sort((a, b) => a.index.compareTo(b.index));

    for (final frequency in frequencies) {
      final result = provider.recurringResults[frequency];
      if (result == null) continue;

      final freqText = frequency == Frequency.monthly
          ? l10n.monthly
          : l10n.weekly;
      final label = "${l10n.recurringInvestment} ($freqText)";
      summaries.add(_StrategySummary(label: label, result: result));
    }

    if (summaries.isEmpty) {
      final fallback = provider.result;
      if (fallback != null) {
        summaries.add(
          _StrategySummary(
            label: l10n.investmentResults,
            result: fallback,
            highlight: true,
          ),
        );
      }
      return summaries;
    }

    final bestIndex = summaries
        .asMap()
        .entries
        .reduce(
          (best, entry) =>
              entry.value.result.finalValue > best.value.result.finalValue
              ? entry
              : best,
        )
        .key;

    return summaries
        .asMap()
        .entries
        .map((entry) => entry.value.copyWith(highlight: entry.key == bestIndex))
        .toList();
  }
}

class _StrategySummary {
  final String label;
  final CalculationResult result;
  final bool highlight;

  const _StrategySummary({
    required this.label,
    required this.result,
    this.highlight = false,
  });

  _StrategySummary copyWith({bool? highlight}) {
    return _StrategySummary(
      label: label,
      result: result,
      highlight: highlight ?? this.highlight,
    );
  }
}
