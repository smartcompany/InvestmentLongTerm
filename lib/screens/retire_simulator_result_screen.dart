import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:ui';
import '../providers/retire_simulator_provider.dart';
import '../providers/app_state_provider.dart';
import '../providers/currency_provider.dart';
import '../providers/my_assets_provider.dart';
import '../models/asset_option.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';
import '../utils/retire_chart_style.dart';
import '../widgets/liquid_glass.dart';
import '../widgets/asset_icon.dart';
import '../l10n/app_localizations.dart';
import '../widgets/common_share_ui.dart';
import '../services/ad_service.dart';
import '../services/app_review_service.dart';
import 'main_tab_screen.dart';

class RetireSimulatorResultScreen extends StatefulWidget {
  const RetireSimulatorResultScreen({super.key});

  @override
  State<RetireSimulatorResultScreen> createState() =>
      _RetireSimulatorResultScreenState();
}

class _RetireSimulatorResultScreenState
    extends State<RetireSimulatorResultScreen> {
  bool _isMonthlyDetailsExpanded = false; // 월별 상세 내역 펼침 상태
  bool _hasRequestedReview = false;
  bool _isImportingToMyAssets = false;

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

  // 시뮬레이션 결과 폰트 크기 상수
  static const double _simulationResultTitleFontSize =
      20.0; // "시뮬레이션 요약" 제목 텍스트
  static const double _simulationResultLabelFontSize =
      20.0; // 라벨 텍스트 ("선택한 시나리오:", "월 인출액:", "최종 자산", "누적 수익률" 등)
  static const double _simulationResultValueFontSize =
      15.0; // 값 텍스트 (시나리오 이름, 인출액, 통계 값 등)

  // 월별 상세 내역 폰트 크기 상수
  static const double _monthlyCardYearFontSize = 20.0;
  static const double _monthlyCardMonthFontSize = 20.0;
  static const double _monthlyCardLabelFontSize = 20.0;
  static const double _monthlyCardValueFontSize = 20.0;
  static const double _monthlyCardSubValueFontSize = 20.0;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RetireSimulatorProvider>();
    final appProvider = context.watch<AppStateProvider>();
    final l10n = AppLocalizations.of(context)!;

    return ListenableBuilder(
      listenable: CurrencyProvider.shared,
      builder: (context, _) {
        final currencySymbol = CurrencyProvider.shared.getCurrencySymbol();
        final currencyFormat = NumberFormat.currency(
          symbol: currencySymbol,
          decimalDigits: 0,
        );

        final results = provider.runSimulation();
        final summary = provider.getSimulationSummary();

        final totalPath = results['total'] as List<double>? ?? [];
        final assetPaths =
            results['assets'] as Map<String, List<double>>? ?? {};

        if (totalPath.isEmpty) {
          return Scaffold(
            backgroundColor: AppColors.bg,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                l10n.simulationResultTitle,
                style: AppTextStyles.appBarTitle,
              ),
              centerTitle: true,
            ),
            body: Center(
              child: Text(
                l10n.simulationResultNoData,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          );
        }

        // 전체 자산 그래프 데이터 (월 인덱스를 연도로 변환)
        final totalSpots = totalPath
            .asMap()
            .entries
            .map((e) => FlSpot(e.key / 12.0, e.value))
            .toList();

        // 애니메이션과 동일한 자산 색상 매핑
        final orderedIds = provider.assets.map((a) => a.assetId).toList();
        final nonCashIds =
            orderedIds.where((id) => id != 'cash').toList();
        final colorOrder =
            nonCashIds.isNotEmpty ? nonCashIds : orderedIds;
        final assetColorById = <String, Color>{
          for (var i = 0; i < colorOrder.length; i++)
            colorOrder[i]: RetireChartStyle.assetAt(i),
        };

        final assetSpotsList = provider.assets.map((asset) {
          AssetOption? assetOption;
          try {
            assetOption = appProvider.assets.firstWhere(
              (a) => a.id == asset.assetId,
            );
          } catch (e) {
            assetOption = null;
          }
          final assetName = assetOption?.displayName() ??
              (asset.assetId == 'cash' ? l10n.cash : asset.assetId);
          final assetPath = assetPaths[asset.assetId] ?? [];
          final spots = assetPath
              .asMap()
              .entries
              .map((e) => FlSpot(e.key / 12.0, e.value))
              .toList();
          return {
            'id': asset.assetId,
            'type': assetOption?.type,
            'name': assetName,
            'spots': spots,
            'color': assetColorById[asset.assetId] ??
                RetireChartStyle.assetAt(0),
          };
        }).toList();

        // 시나리오 이름
        final scenarioName = provider.selectedScenario == 'positive'
            ? l10n.scenarioPositive
            : provider.selectedScenario == 'negative'
            ? l10n.scenarioNegative
            : l10n.scenarioNeutral;

        return Scaffold(
          backgroundColor: AppColors.bg,
          appBar: AppBar(
            backgroundColor: AppColors.bg,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              l10n.simulationResultTitle,
              style: AppTextStyles.appBarTitle,
            ),
            centerTitle: true,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 시나리오 및 인출 정보 표시
                  LiquidGlass(
                    blur: 10,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
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
                              Icons.info_outline,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Flexible(
                              child: Wrap(
                                children: [
                                  Text(
                                    l10n.selectedScenario,
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: _simulationResultLabelFontSize,
                                    ),
                                  ),
                                  Text(
                                    scenarioName,
                                    style: TextStyle(
                                      color:
                                          provider.selectedScenario ==
                                              'positive'
                                          ? AppColors.success
                                          : provider.selectedScenario ==
                                                'negative'
                                          ? Colors.red
                                          : AppColors.primary,
                                      fontSize: _simulationResultValueFontSize,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.account_balance_wallet,
                              color: Colors.orange,
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    children: [
                                      Text(
                                        provider.inflationRate > 0
                                            ? l10n.monthlyWithdrawalWithInflation
                                            : l10n.monthlyWithdrawalLabel,
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize:
                                              _simulationResultLabelFontSize,
                                        ),
                                      ),
                                      Text(
                                        currencyFormat.format(
                                          provider.monthlyWithdrawal,
                                        ),
                                        style: TextStyle(
                                          color: Colors.orange,
                                          fontSize:
                                              _simulationResultValueFontSize,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (provider.inflationRate > 0) ...[
                                    SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.trending_up,
                                          color: AppColors.primary,
                                          size: 16,
                                        ),
                                        SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            l10n.inflationRateApplied(
                                              double.parse(
                                                (provider.inflationRate * 100)
                                                    .toStringAsFixed(1),
                                              ),
                                            ),
                                            style: TextStyle(
                                              color: AppColors.primary,
                                              fontSize:
                                                  _simulationResultValueFontSize,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 32),
                  // 통합 차트 (전체 + 각 자산)
                  _buildCombinedChart(
                    provider,
                    totalSpots,
                    assetSpotsList,
                    currencyFormat,
                    l10n,
                  ),
                  SizedBox(height: 32),
                  // 읽기 편한 요약 카드
                  _buildReadableSummaryCard(
                    provider,
                    appProvider,
                    summary,
                    currencyFormat,
                    l10n,
                  ),
                  SizedBox(height: 16),
                  // 결과 요약
                  _buildSummaryCard(
                    summary,
                    currencyFormat,
                    provider.selectedScenario,
                    l10n,
                  ),
                  SizedBox(height: 32),
                  // 월별 상세 정보
                  _buildMonthlyDetails(
                    provider,
                    totalPath,
                    currencyFormat,
                    l10n,
                  ),
                  SizedBox(height: 24),
                  // 공유하기 및 다시 계산 버튼
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
                                  appProvider,
                                  summary,
                                  currencyFormat,
                                  l10n,
                                );
                                await CommonShareUI.showShareOptionsDialog(
                                  context: context,
                                  shareText: shareText,
                                );
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 14),
                                decoration:
                                    SelectedButtonStyle.solidBoxDecoration(
                                      BorderRadius.circular(12),
                                    ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.share,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        l10n.share,
                                        style: AppTextStyles.buttonTextPrimary
                                            .copyWith(
                                              color: Colors.white,
                                              fontSize: 16,
                                            ),
                                        maxLines: 2,
                                        overflow: TextOverflow.visible,
                                        textAlign: TextAlign.center,
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
                              onTap: _isImportingToMyAssets
                                  ? null
                                  : () => _goToMyAssets(
                                        provider,
                                        appProvider,
                                      ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration:
                                    SelectedButtonStyle.solidBoxDecoration(
                                      BorderRadius.circular(12),
                                    ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (_isImportingToMyAssets)
                                      const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    else
                                      const Icon(
                                        Icons.account_balance_wallet_outlined,
                                        color: Colors.white,
                                      ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        l10n.manageInMyAssets,
                                        style: AppTextStyles.buttonTextPrimary
                                            .copyWith(
                                              color: Colors.white,
                                              fontSize: 16,
                                            ),
                                        maxLines: 2,
                                        overflow: TextOverflow.visible,
                                        textAlign: TextAlign.center,
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
                  SizedBox(height: 60),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _goToMyAssets(
    RetireSimulatorProvider provider,
    AppStateProvider appProvider,
  ) async {
    if (_isImportingToMyAssets) return;
    setState(() => _isImportingToMyAssets = true);

    try {
      final myAssets = context.read<MyAssetsProvider>();
      final l10n = AppLocalizations.of(context)!;
      final payload = <({
        String assetId,
        String assetName,
        double quantity,
        double valuation,
      })>[];

      // 보유 현금
      if (provider.cash > 0) {
        payload.add((
          assetId: 'cash',
          assetName: l10n.cash,
          quantity: 1,
          valuation: provider.cash,
        ));
      }

      // 은퇴 시뮬에서 추가한 보유 자산
      for (final h in provider.holdings) {
        if (h.quantity <= 0) continue;
        String name = h.assetId;
        try {
          name = appProvider.assets
              .firstWhere((a) => a.id == h.assetId)
              .displayName();
        } catch (_) {}
        payload.add((
          assetId: h.assetId,
          assetName: name,
          quantity: h.quantity,
          valuation: h.valuation > 0 ? h.valuation : 0,
        ));
      }

      await myAssets.importRetireHoldings(payload);
      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const MainTabScreen(
            initialIndex: 3,
            openMyAssetsGate: true,
          ),
        ),
        (route) => route.isFirst,
      );
    } catch (e) {
      debugPrint('Failed to import holdings to my assets: $e');
      if (mounted) setState(() => _isImportingToMyAssets = false);
    }
  }

  Widget _buildCombinedChart(
    RetireSimulatorProvider provider,
    List<FlSpot> totalSpots,
    List<Map<String, dynamic>> assetSpotsList,
    NumberFormat currencyFormat,
    AppLocalizations l10n,
  ) {
    // 누적 인출액 라인 생성 (월별로 누적, 인플레이션 적용)
    final withdrawalSpots = <FlSpot>[];
    double cumulativeWithdrawal = 0.0;
    for (int i = 0; i < totalSpots.length; i++) {
      if (i > 0) {
        // 인플레이션 적용된 월 인출액 계산
        final year = (i - 1) ~/ 12;
        final monthlyWithdrawalWithInflation =
            provider.monthlyWithdrawal *
            math.pow(1 + provider.inflationRate, year);
        cumulativeWithdrawal += monthlyWithdrawalWithInflation;
      }
      final year = i / 12.0;
      withdrawalSpots.add(FlSpot(year, cumulativeWithdrawal));
    }

    final lineLabels = <String>[
      l10n.totalAssets,
      l10n.cumulativeWithdrawal,
      ...assetSpotsList.map((a) => a['name'] as String),
    ];

    // 모든 라인 데이터 준비
    final lineBarsData = <LineChartBarData>[
      // 전체 자산 라인
      LineChartBarData(
        spots: totalSpots,
        isCurved: true,
        color: RetireChartStyle.total,
        barWidth: 4,
        dotData: const FlDotData(show: false),
        isStrokeCapRound: true,
      ),
      // 누적 인출액 라인 (점선으로 표시)
      LineChartBarData(
        spots: withdrawalSpots,
        isCurved: true,
        color: RetireChartStyle.withdrawal,
        barWidth: 2,
        dotData: const FlDotData(show: false),
        dashArray: const [5, 5],
      ),
    ];

    // 각 자산별 라인 추가
    for (final assetData in assetSpotsList) {
      final spots = assetData['spots'] as List<FlSpot>;
      final color = assetData['color'] as Color;
      lineBarsData.add(
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: color,
          barWidth: 2,
          dotData: const FlDotData(show: false),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.assetValueTrend, style: AppTextStyles.chartSectionTitle),
        const SizedBox(height: 20),
        LiquidGlass(
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
            height: 350,
            padding: const EdgeInsets.all(16),
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: provider.simulationYears.toDouble(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(color: AppColors.border, strokeWidth: 1);
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: provider.simulationYears / 5,
                      getTitlesWidget: (value, meta) {
                        final yearOffset = value.round();
                        if (yearOffset >= 0 &&
                            yearOffset <= provider.simulationYears) {
                          if (yearOffset == 0 ||
                              yearOffset == provider.simulationYears ||
                              yearOffset % 5 == 0) {
                            final actualYear = 2025 + yearOffset;
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                l10n.yearLabel(actualYear),
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 52,
                      interval: _calculateYAxisInterval(totalSpots),
                      getTitlesWidget: (value, meta) {
                        if (value <= 0) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Text(
                            _compactAxisLabel(
                              value,
                              currencyFormat.currencySymbol,
                            ),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: lineBarsData,
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touchedSpot) => AppColors.navyDark,
                    tooltipPadding: const EdgeInsets.all(12),
                    tooltipMargin: 16,
                    maxContentWidth: 220,
                    getTooltipItems: (List<LineBarSpot> touchedSpots) {
                      return touchedSpots.map((LineBarSpot touchedSpot) {
                        final barIndex = touchedSpot.barIndex;
                        final name = (barIndex >= 0 &&
                                barIndex < lineLabels.length)
                            ? lineLabels[barIndex]
                            : '';
                        final formattedValue =
                            currencyFormat.format(touchedSpot.y);
                        final lineColor = barIndex >= 0 &&
                                barIndex < lineBarsData.length
                            ? (lineBarsData[barIndex].color ?? Colors.white)
                            : Colors.white;
                        return LineTooltipItem(
                          '$name\n$formattedValue',
                          TextStyle(
                            color: lineColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            height: 1.35,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        // 범례
        _buildLegend(totalSpots, assetSpotsList, l10n),
      ],
    );
  }

  Widget _buildLegend(
    List<FlSpot> totalSpots,
    List<Map<String, dynamic>> assetSpotsList,
    AppLocalizations l10n,
  ) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      runSpacing: 12,
      children: [
        _buildLegendItem(l10n.totalAssets, RetireChartStyle.total, false),
        _buildLegendItem(
          l10n.cumulativeWithdrawal,
          RetireChartStyle.withdrawal,
          true,
        ),
        ...assetSpotsList.map((assetData) {
          final id = assetData['id'] as String? ?? '';
          final type = assetData['type'] as String?;
          final name = assetData['name'] as String;
          final color = assetData['color'] as Color;
          return _buildLegendItem(
            name,
            color,
            false,
            assetId: id,
            assetType: type,
          );
        }),
      ],
    );
  }

  Widget _buildLegendItem(
    String label,
    Color color,
    bool isDashed, {
    String? assetId,
    String? assetType,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isDashed)
          CustomPaint(
            size: const Size(16, 3),
            painter: DashedLinePainter(color: color),
          )
        else
          Container(width: 16, height: 3, color: color),
        const SizedBox(width: 8),
        if (assetId != null && assetId.isNotEmpty) ...[
          AssetIcon(
            assetId: assetId,
            type: assetType,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
        ],
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildReadableSummaryCard(
    RetireSimulatorProvider provider,
    AppStateProvider appProvider,
    Map<String, dynamic> summary,
    NumberFormat currencyFormat,
    AppLocalizations l10n,
  ) {
    // 초기 자산 금액 포맷팅 (원 단위 포함)
    final initialAssetText = currencyFormat.format(provider.initialAsset);

    // 자산 포트폴리오 구성 문자열 생성
    final assetDescriptions = <String>[];
    for (final asset in provider.assets) {
      AssetOption? assetOption;
      try {
        assetOption = appProvider.assets.firstWhere(
          (a) => a.id == asset.assetId,
        );
      } catch (e) {
        assetOption = null;
      }
      final assetName = assetOption?.displayName() ?? asset.assetId;
      final allocationPercent = (asset.allocation * 100).toStringAsFixed(0);
      assetDescriptions.add('$assetName ($allocationPercent%)');
    }
    final portfolioText = assetDescriptions.join(', ');

    // 월 인출액 포맷팅 (원 단위 포함)
    final monthlyWithdrawalText = currencyFormat.format(
      provider.monthlyWithdrawal,
    );

    // 최종 자산 포맷팅
    final finalAssetText = currencyFormat.format(summary['finalAsset']);

    // 로컬라이징된 문장 생성 (파라미터 순서: initialAsset, portfolio, years, monthlyWithdrawal, finalAsset)
    // 인플레이션이 적용되면 다른 문구 사용
    final localizedText = provider.inflationRate > 0
        ? l10n.simulationResultPrefixWithInflation(
            initialAssetText,
            portfolioText,
            provider.simulationYears,
            monthlyWithdrawalText,
            finalAssetText,
          )
        : l10n.simulationResultPrefix(
            initialAssetText,
            portfolioText,
            provider.simulationYears,
            monthlyWithdrawalText,
            finalAssetText,
          );

    // 강조할 부분들을 찾아서 TextSpan으로 구성
    final parts = _parseLocalizedText(
      localizedText,
      initialAssetText,
      portfolioText,
      '${provider.simulationYears}',
      monthlyWithdrawalText,
      finalAssetText,
    );

    return LiquidGlass(
      blur: 10,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border,
          width: 1.5,
        ),
      ),
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description_outlined, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                l10n.simulationResultTitle,
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: _simulationResultTitleFontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          RichText(
            text: TextSpan(
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: _simulationResultValueFontSize,
                height: 1.6, // 줄 간격
              ),
              children: parts,
            ),
          ),
        ],
      ),
    );
  }

  List<TextSpan> _parseLocalizedText(
    String localizedText,
    String initialAssetText,
    String portfolioText,
    String yearsText,
    String monthlyWithdrawalText,
    String finalAssetText,
  ) {
    final spans = <TextSpan>[];
    final highlightValues = [
      initialAssetText,
      portfolioText,
      yearsText,
      monthlyWithdrawalText,
      finalAssetText,
    ];

    String remainingText = localizedText;
    int lastIndex = 0;

    // 각 강조할 값을 순서대로 찾아서 처리
    for (final value in highlightValues) {
      final index = remainingText.indexOf(value, lastIndex);
      if (index != -1) {
        // 강조 전 텍스트
        if (index > lastIndex) {
          spans.add(TextSpan(text: remainingText.substring(lastIndex, index)));
        }
        // 강조할 값
        spans.add(
          TextSpan(
            text: value,
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: _simulationResultValueFontSize + 2,
            ),
          ),
        );
        lastIndex = index + value.length;
      }
    }

    // 남은 텍스트
    if (lastIndex < remainingText.length) {
      spans.add(TextSpan(text: remainingText.substring(lastIndex)));
    }

    return spans;
  }

  Widget _buildSummaryCard(
    Map<String, dynamic> summary,
    NumberFormat currencyFormat,
    String scenario,
    AppLocalizations l10n,
  ) {
    final scenarioColor = scenario == 'positive'
        ? AppColors.success
        : scenario == 'negative'
        ? Colors.red
        : AppColors.primary;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: scenarioColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: scenarioColor.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.detailedStatistics,
                style: TextStyle(
                  color: scenarioColor,
                  fontSize: _simulationResultTitleFontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: _buildStatItem(
                      l10n.finalAsset,
                      currencyFormat.format(summary['finalAsset']),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildStatItem(
                      l10n.cumulativeReturn,
                      '${(summary['cumulativeReturn'] * 100).toStringAsFixed(1)}%',
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: _buildStatItem(
                      l10n.totalWithdrawn,
                      currencyFormat.format(summary['totalWithdrawn']),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildStatItem(
                      l10n.netProfit,
                      currencyFormat.format(summary['totalReturn']),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: _simulationResultLabelFontSize,
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: _simulationResultValueFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyDetails(
    RetireSimulatorProvider provider,
    List<double> totalPath,
    NumberFormat currencyFormat,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _isMonthlyDetailsExpanded = !_isMonthlyDetailsExpanded;
            });
          },
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.monthlyDetails,
                  style: AppTextStyles.chartSectionTitle,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary, width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isMonthlyDetailsExpanded
                          ? l10n.showLess
                          : l10n.expandView,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      _isMonthlyDetailsExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (_isMonthlyDetailsExpanded) ...[
          SizedBox(height: 16),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: 400),
            child: ListView.builder(
              shrinkWrap: true,
              physics: ClampingScrollPhysics(),
              itemCount: totalPath.length,
              itemBuilder: (context, index) {
                final month = index;
                final year = month ~/ 12;
                final monthInYear = (month % 12) + 1;
                final currentAsset = totalPath[index];
                final previousAsset = index > 0
                    ? totalPath[index - 1]
                    : provider.initialAsset;
                final assetChange = currentAsset - previousAsset;
                // 인플레이션 적용된 월 인출액 계산
                final monthlyWithdrawal = month > 0
                    ? provider.monthlyWithdrawal *
                          math.pow(1 + provider.inflationRate, year)
                    : 0.0;

                // 모든 월 표시

                return LiquidGlass(
                  blur: 8,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.border,
                      width: 1,
                    ),
                  ),
                  padding: EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // 월 정보
                      Container(
                        width: 60,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.yearLabel(year),
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: _monthlyCardYearFontSize,
                              ),
                            ),
                            Text(
                              l10n.monthLabel(monthInYear),
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: _monthlyCardMonthFontSize,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 12),
                      // 자산 정보
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  l10n.asset,
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: _monthlyCardLabelFontSize,
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    currencyFormat.format(currentAsset),
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: _monthlyCardValueFontSize,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.end,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            if (month > 0) ...[
                              SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    l10n.withdrawal,
                                    style: TextStyle(
                                      color: Colors.orange.withValues(
                                        alpha: 0.8,
                                      ),
                                      fontSize: _monthlyCardLabelFontSize,
                                    ),
                                  ),
                                  Flexible(
                                    child: Text(
                                      '-${currencyFormat.format(monthlyWithdrawal)}',
                                      style: TextStyle(
                                        color: Colors.orange,
                                        fontSize: _monthlyCardSubValueFontSize,
                                      ),
                                      textAlign: TextAlign.end,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    l10n.change,
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: _monthlyCardLabelFontSize,
                                    ),
                                  ),
                                  Flexible(
                                    child: Text(
                                      assetChange >= 0
                                          ? '+${currencyFormat.format(assetChange)}'
                                          : currencyFormat.format(assetChange),
                                      style: TextStyle(
                                        color: assetChange >= 0
                                            ? AppColors.success
                                            : Colors.red,
                                        fontSize: _monthlyCardSubValueFontSize,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.end,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  String _compactAxisLabel(double value, String symbol) {
    final abs = value.abs();
    if (symbol == '₩' || symbol == 'KRW') {
      if (abs >= 100000000) {
        return '$symbol${(value / 100000000).toStringAsFixed(1)}억';
      }
      if (abs >= 10000) {
        return '$symbol${(value / 10000).toStringAsFixed(0)}만';
      }
    } else if (symbol == '\$' || symbol == 'USD') {
      if (abs >= 1000000) {
        return '$symbol${(value / 1000000).toStringAsFixed(1)}M';
      }
      if (abs >= 1000) {
        return '$symbol${(value / 1000).toStringAsFixed(0)}K';
      }
    }
    return NumberFormat.compact().format(value);
  }

  // Y축 간격 계산 (자동으로 적절한 간격 설정)
  double _calculateYAxisInterval(List<FlSpot> spots) {
    if (spots.isEmpty) return 1.0;
    final maxValue = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    if (maxValue <= 0) return 1.0;

    // 최대값의 1/5 정도로 간격 설정
    final interval = maxValue / 5.0;

    // 간격을 깔끔한 숫자로 반올림
    final ln10 = math.log(10);
    final magnitude = math
        .pow(10, (math.log(interval) / ln10).floor())
        .toDouble();
    final normalized = interval / magnitude;

    double rounded;
    if (normalized <= 1) {
      rounded = 1 * magnitude;
    } else if (normalized <= 2) {
      rounded = 2 * magnitude;
    } else if (normalized <= 5) {
      rounded = 5 * magnitude;
    } else {
      rounded = 10 * magnitude;
    }

    return rounded;
  }

  String _buildShareText(
    RetireSimulatorProvider provider,
    AppStateProvider appProvider,
    Map<String, dynamic> summary,
    NumberFormat currencyFormat,
    AppLocalizations l10n,
  ) {
    final buffer = StringBuffer();

    // Header
    buffer.writeln('📊 ${l10n.simulationResultTitle}');
    buffer.writeln('');

    // 초기 자산 및 포트폴리오 정보
    final initialAsset = currencyFormat.format(provider.initialAsset);
    final portfolioParts = <String>[];
    for (final asset in provider.assets) {
      final assetOption = appProvider.assets
          .where((a) => a.id == asset.assetId)
          .firstOrNull;
      if (assetOption != null) {
        final assetName = assetOption.displayName();
        final allocationPercent = (asset.allocation * 100).toStringAsFixed(0);
        portfolioParts.add('$assetName ($allocationPercent%)');
      }
    }
    final portfolioText = portfolioParts.join(', ');

    buffer.writeln('💰 초기 자산: $initialAsset');
    buffer.writeln('📈 포트폴리오: $portfolioText');
    buffer.writeln('📅 시뮬레이션 기간: ${provider.simulationYears}년');
    buffer.writeln(
      '💸 월 인출액: ${currencyFormat.format(provider.monthlyWithdrawal)}',
    );

    // 시나리오 정보
    String scenarioText = '';
    switch (provider.selectedScenario) {
      case 'positive':
        scenarioText = '긍정적 (+20%)';
        break;
      case 'negative':
        scenarioText = '부정적 (-20%)';
        break;
      case 'neutral':
      default:
        scenarioText = '중립적 (0%)';
        break;
    }
    buffer.writeln('📊 시나리오: $scenarioText');
    buffer.writeln('');

    // 결과
    buffer.writeln('✨ 시뮬레이션 결과');
    buffer.writeln('');
    buffer.writeln('   최종 자산: ${currencyFormat.format(summary['finalAsset'])}');
    buffer.writeln(
      '   누적 수익률: ${(summary['cumulativeReturn'] * 100).toStringAsFixed(1)}%',
    );
    buffer.writeln(
      '   총 인출액: ${currencyFormat.format(summary['totalWithdrawn'])}',
    );
    buffer.writeln('   순수익: ${currencyFormat.format(summary['totalReturn'])}');
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
}

// 점선을 그리는 CustomPainter
class DashedLinePainter extends CustomPainter {
  final Color color;

  DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashWidth = 3.0;
    const dashSpace = 3.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
