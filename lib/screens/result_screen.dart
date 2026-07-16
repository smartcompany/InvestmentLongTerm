import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../l10n/app_localizations.dart';
import '../models/calculation_result.dart';
import '../models/investment_config.dart';
import '../providers/app_state_provider.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';
import '../widgets/common_share_ui.dart';
import '../widgets/asset_price_chart.dart';
import '../widgets/comparison_chart.dart';
import '../widgets/liquid_glass.dart';
import '../widgets/asset_icon.dart';
import '../services/ad_service.dart';
import '../services/app_review_service.dart';
import '../utils/chart_image_utils.dart';
import 'package:flutter/rendering.dart';
import 'main_tab_screen.dart';
import '../providers/currency_provider.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final GlobalKey _chartKey = GlobalKey();
  bool _hasRequestedReview = false;

  @override
  void initState() {
    super.initState();
    // 화면이 완전히 렌더링된 후 리뷰 요청
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_hasRequestedReview) {
        _hasRequestedReview = true;
        AppReviewService.requestReviewIfAppropriate();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppStateProvider>();
    final result = provider.result;
    final l10n = AppLocalizations.of(context)!;
    final currencySymbol = CurrencyProvider.shared.getCurrencySymbol();

    if (provider.isLoading) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 20),
              Text(
                l10n.fetchingPriceData,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.error != null) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
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
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  provider.error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
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
        backgroundColor: AppColors.bg,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final currencyFormat = NumberFormat.currency(
      symbol: currencySymbol,
      decimalDigits: 0,
    );
    final percentFormat = NumberFormat.decimalPercentPattern(decimalDigits: 1);
    final strategySummaries = _buildStrategySummaries(provider, l10n);
    final List<ComparisonSeries> comparisonSeries =
        provider.config.type == InvestmentType.recurring
        ? _buildComparisonSeries(provider, l10n)
        : [];

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(l10n.investmentResults, style: AppTextStyles.appBarTitle),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          top: 24,
          left: 24,
          right: 24,
          bottom: MediaQuery.of(context).padding.bottom + 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 투자 기간 정보
            LiquidGlass(
              blur: 10,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.border,
                  width: 1.5,
                ),
              ),
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.investmentStartDate(
                            DateTime.now().year - provider.config.yearsAgo,
                            provider.config.yearsAgo,
                          ),
                          style: AppTextStyles.resultStatValue.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (provider.selectedAsset != null) ...[
                    SizedBox(height: 12),
                    Row(
                      children: [
                        AssetIcon(
                          assetId: provider.selectedAsset!.id,
                          type: provider.selectedAsset!.type,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            provider.assetNameForLocale(),
                            style: AppTextStyles.resultStatValue.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 20),
            for (int i = 0; i < strategySummaries.length; i++) ...[
              _buildStrategySummaryCard(
                summary: strategySummaries[i],
                currencyFormat: currencyFormat,
                percentFormat: percentFormat,
                totalInvestment: currencyFormat.format(provider.config.amount),
                showTotalInvestment: true,
                provider: provider,
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
            RepaintBoundary(
              key: _chartKey,
              child: provider.config.type == InvestmentType.recurring
                  ? LiquidGlass(
                      blur: 10,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.border,
                          width: 1.5,
                        ),
                      ),
                      child: Container(
                        height: 300,
                        padding: EdgeInsets.only(
                          right: 16,
                          top: 10,
                          bottom: 10,
                        ),
                        child: _buildComparisonChart(
                          comparisonSeries,
                          currencySymbol,
                        ),
                      ),
                    )
                  : AssetPriceChart(
                      spots: result.valueSpots,
                      startDate: DateTime.now().subtract(
                        Duration(days: provider.config.yearsAgo * 365),
                      ),
                      endDate: DateTime.now(),
                      currencySymbol: currencySymbol,
                      height: 300,
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
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.35),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.2),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Text(
                    l10n.insightMessage,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.insightMessage,
                  ),
                ),
              ),
            ),

            SizedBox(height: 40),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: GestureDetector(
                        onTap: () async {
                          final shareText = _buildShareText(
                            provider,
                            currencyFormat,
                            percentFormat,
                            strategySummaries,
                            l10n,
                          );

                          // Convert chart to image
                          final chartImageBytes =
                              await ChartImageUtils.widgetToImage(_chartKey);

                          await CommonShareUI.showShareOptionsDialog(
                            context: context,
                            shareText: shareText,
                            chartImageBytes: chartImageBytes,
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          decoration: SelectedButtonStyle.solidBoxDecoration(
                            BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.share, color: Colors.white),
                              SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  l10n.share,
                                  style: AppTextStyles.buttonTextPrimary
                                      .copyWith(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.visible,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: GestureDetector(
                        onTap: () {
                          // MainTabScreen의 은퇴 시뮬레이터 탭으로 이동 (인덱스 1)
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (context) =>
                                  const MainTabScreen(initialIndex: 1),
                            ),
                            (route) => route.isFirst, // 홈 화면까지만 유지
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          decoration: SelectedButtonStyle.solidBoxDecoration(
                            BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.arrow_back, color: Colors.white),
                              SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  l10n.retirementSimulation,
                                  style: AppTextStyles.buttonTextPrimary
                                      .copyWith(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.visible,
                                ),
                              ),
                            ],
                          ),
                        ),
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

  Widget _buildComparisonChart(
    List<ComparisonSeries> series,
    String currencySymbol,
  ) {
    if (series.length < 2) {
      return Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    return ComparisonChart(series: series, currencySymbol: currencySymbol);
  }

  Widget _buildStrategySummaryCard({
    required _StrategySummary summary,
    required NumberFormat currencyFormat,
    required NumberFormat percentFormat,
    required String totalInvestment,
    required bool showTotalInvestment,
    required AppStateProvider provider,
    required AppLocalizations l10n,
  }) {
    final result = summary.result;
    final gain = result.finalValue - result.totalInvested;
    final gainPositive = gain >= 0;
    final gainText =
        "${gainPositive ? '+' : '-'}${currencyFormat.format(gain.abs())}";
    final textColor = AppColors.textPrimary;
    final secondaryTextColor = AppColors.textSecondary;

    final cardContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                summary.label,
                style: AppTextStyles.resultCardTitle.copyWith(color: textColor),
              ),
            ),
            if (summary.highlight) ...[
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(l10n.bestReturn, style: AppTextStyles.badgeText),
              ),
            ],
          ],
        ),
        SizedBox(height: 18),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: 12,
          runSpacing: 4,
          children: [
            Text(
              currencyFormat.format(result.finalValue),
              style: AppTextStyles.resultCardValueBig.copyWith(
                color: textColor,
              ),
            ),
              Text(
              "${result.yieldRate >= 0 ? '+' : ''}${percentFormat.format(result.yieldRate / 100)}",
              style: AppTextStyles.resultCardYield.copyWith(
                color: result.yieldRate >= 0
                    ? AppColors.success
                    : Colors.redAccent,
              ),
            ),
          ],
        ),
        Divider(
          color: AppColors.border,
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
                  value:
                      "${result.cagr >= 0 ? '+' : ''}${result.cagr.toStringAsFixed(1)}%",
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.savings_outlined,
                color: AppColors.primary,
                size: 16,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getInvestmentText(
                    summary,
                    totalInvestment,
                    provider,
                    currencyFormat,
                    l10n,
                  ),
                  style: AppTextStyles.resultStatValue.copyWith(
                    color: secondaryTextColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        summary.highlight
            ? Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: SelectedButtonStyle.softSelectedDecoration(
                  BorderRadius.circular(24),
                ),
                child: cardContent,
              )
            : LiquidGlass(
                blur: 10,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.border,
                    width: 1.5,
                  ),
                ),
                padding: EdgeInsets.all(20),
                child: cardContent,
              ),
      ],
    );
  }

  /// 투자 금액 텍스트 생성
  /// 단일 투자: 총 투자금 표시
  /// 정기 투자: 주기별 투자 금액 표시 (매월/매주)
  String _getInvestmentText(
    _StrategySummary summary,
    String totalInvestment,
    AppStateProvider provider,
    NumberFormat currencyFormat,
    AppLocalizations l10n,
  ) {
    // 정기 투자인지 확인
    if (summary.label.contains(l10n.recurringInvestment)) {
      final isMonthly = summary.label.contains(l10n.monthly);
      final yearsAgo = provider.config.yearsAgo;
      final totalInvested = summary.result.totalInvested;

      // 주기별 투자 금액 계산
      final periodAmount = isMonthly
          ? totalInvested /
                (yearsAgo * 12) // 매월 금액
          : totalInvested / (yearsAgo * 52); // 매주 금액

      final frequencyText = isMonthly ? l10n.monthly : l10n.weekly;
      final formattedAmount = currencyFormat.format(periodAmount);

      return '${l10n.investmentAmountLabel}: $formattedAmount / $frequencyText';
    } else {
      // 단일 투자: 총 투자금 표시
      return l10n.totalInvested(totalInvestment);
    }
  }

  Widget _buildStatTile({
    required String label,
    required String value,
    required Color textColor,
    required Color secondaryTextColor,
    required bool highlight,
    required AppLocalizations l10n,
  }) {
    // value가 양수(+)인지 확인
    final isPositive = value.startsWith('+');
    final valueColor = isPositive ? AppColors.success : Colors.redAccent;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: highlight ? AppColors.primarySoft : AppColors.bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlight ? AppColors.primary.withValues(alpha: 0.35) : AppColors.border,
        ),
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
            style: AppTextStyles.resultStatValue.copyWith(color: valueColor),
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
        color: AppColors.primary,
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
    NumberFormat currencyFormat,
    NumberFormat percentFormat,
    List<_StrategySummary> summaries,
    AppLocalizations l10n,
  ) {
    final buffer = StringBuffer();
    final assetName = provider.assetNameForLocale();
    final formattedAmount = currencyFormat.format(provider.config.amount);

    // Header with emoji
    buffer.writeln('📊 ${l10n.shareTextHeader}');
    buffer.writeln('');

    // Title
    buffer.writeln(
      '💎 ${l10n.shareTextTitle(formattedAmount, assetName, provider.config.yearsAgo)}',
    );
    buffer.writeln('');

    // Results section with clean formatting
    for (int i = 0; i < summaries.length; i++) {
      final summary = summaries[i];
      final result = summary.result;
      final emoji = summary.highlight ? '🏆' : (i == 0 ? '💎' : '📈');
      final yieldEmoji = result.yieldRate >= 0 ? '📈' : '📉';
      final gain = result.finalValue - result.totalInvested;
      final gainEmoji = gain >= 0 ? '💰' : '📉';

      buffer.writeln('$emoji ${summary.label}');
      buffer.writeln('');

      // 정기 투자인 경우 투자 금액 정보 추가 (기간으로 나눈 금액)
      if (summary.label.contains(l10n.recurringInvestment)) {
        final isMonthly = summary.label.contains(l10n.monthly);
        final frequencyText = isMonthly ? l10n.monthly : l10n.weekly;

        // 총 투자 금액을 기간으로 나눠서 주기별 금액 계산
        final yearsAgo = provider.config.yearsAgo;
        final totalInvested = result.totalInvested;
        final periodAmount = isMonthly
            ? totalInvested /
                  (yearsAgo * 12) // 매월 금액
            : totalInvested / (yearsAgo * 52); // 매주 금액

        buffer.writeln(
          '   ${l10n.investmentAmountLabel}: ${currencyFormat.format(periodAmount)} / $frequencyText',
        );
        buffer.writeln('');
      }

      buffer.writeln(
        '   ${l10n.finalValue}: ${currencyFormat.format(result.finalValue)}',
      );
      buffer.writeln(
        '   ${l10n.yieldRateLabel}: $yieldEmoji ${percentFormat.format(result.yieldRate / 100)}',
      );
      buffer.writeln(
        '   ${l10n.cagr}: ${result.cagr >= 0 ? '+' : ''}${result.cagr.toStringAsFixed(1)}%',
      );
      buffer.writeln(
        '   ${l10n.gain}: $gainEmoji ${currencyFormat.format(gain.abs())}',
      );
      if (i < summaries.length - 1) {
        buffer.writeln('');
        buffer.writeln('─────────────────────────────');
        buffer.writeln('');
      }
    }
    buffer.writeln('');

    // Total invested
    buffer.writeln(
      '💵 ${l10n.totalInvestmentAmount}: ${currencyFormat.format(provider.config.amount)}',
    );
    buffer.writeln('');

    // Footer
    buffer.writeln('✨ ${l10n.shareTextFooter}');

    // Add download URL if available
    final downloadUrl = AdService.shared.downloadUrl;
    if (downloadUrl != null && downloadUrl.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('🔗 ${l10n.downloadLink(downloadUrl)}');
    }

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
