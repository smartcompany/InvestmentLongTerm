import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/retire_simulator_provider.dart';
import '../providers/app_state_provider.dart';
import '../models/asset_option.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';

class RetireSimulatorResultScreen extends StatefulWidget {
  const RetireSimulatorResultScreen({super.key});

  @override
  State<RetireSimulatorResultScreen> createState() =>
      _RetireSimulatorResultScreenState();
}

class _RetireSimulatorResultScreenState
    extends State<RetireSimulatorResultScreen> {
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
    final localeCode = Localizations.localeOf(context).languageCode;
    final currencyFormat = NumberFormat.currency(
      symbol: '₩',
      decimalDigits: 0,
      locale: localeCode,
    );

    final results = provider.runSimulation();
    final summary = provider.getSimulationSummary();

    final totalPath = results['total'] as List<double>? ?? [];
    final assetPaths = results['assets'] as Map<String, List<double>>? ?? {};

    if (totalPath.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.navyDark,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('시뮬레이션 결과', style: AppTextStyles.appBarTitle),
          centerTitle: true,
        ),
        body: Center(
          child: Text(
            '시뮬레이션 결과가 없습니다.',
            style: TextStyle(color: AppColors.slate400),
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

    // 각 자산별 그래프 데이터
    final assetSpotsList = provider.assets.map((asset) {
      AssetOption? assetOption;
      try {
        assetOption = appProvider.assets.firstWhere(
          (a) => a.id == asset.assetId,
        );
      } catch (e) {
        assetOption = null;
      }
      final assetName = assetOption?.displayName(localeCode) ?? asset.assetId;
      final assetPath = assetPaths[asset.assetId] ?? [];
      final spots = assetPath
          .asMap()
          .entries
          .map((e) => FlSpot(e.key / 12.0, e.value))
          .toList();
      return {
        'name': assetName,
        'icon': assetOption?.icon ?? '📈',
        'spots': spots,
        'color': _getAssetColor(asset.assetId),
      };
    }).toList();

    // 시나리오 이름
    final scenarioName = provider.selectedScenario == 'positive'
        ? '긍정적 (+20%)'
        : provider.selectedScenario == 'negative'
        ? '부정적 (-20%)'
        : '중립적 (0%)';

    return Scaffold(
      backgroundColor: AppColors.navyDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('시뮬레이션 결과', style: AppTextStyles.appBarTitle),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 시나리오 및 인출 정보 표시
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.navyMedium,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.slate700),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.gold, size: 20),
                      SizedBox(width: 12),
                      Text(
                        '선택한 시나리오: ',
                        style: TextStyle(
                          color: AppColors.slate300,
                          fontSize: _simulationResultLabelFontSize,
                        ),
                      ),
                      Text(
                        scenarioName,
                        style: TextStyle(
                          color: provider.selectedScenario == 'positive'
                              ? AppColors.success
                              : provider.selectedScenario == 'negative'
                              ? Colors.red
                              : AppColors.gold,
                          fontSize: _simulationResultValueFontSize,
                          fontWeight: FontWeight.bold,
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
                      Text(
                        '월 인출액: ',
                        style: TextStyle(
                          color: AppColors.slate300,
                          fontSize: _simulationResultLabelFontSize,
                        ),
                      ),
                      Text(
                        currencyFormat.format(provider.monthlyWithdrawal),
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: _simulationResultValueFontSize,
                          fontWeight: FontWeight.bold,
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
            ),
            SizedBox(height: 32),
            // 월별 상세 정보
            _buildMonthlyDetails(provider, totalPath, currencyFormat),
            SizedBox(height: 32),
            // 읽기 편한 요약 카드
            _buildReadableSummaryCard(
              provider,
              appProvider,
              summary,
              currencyFormat,
              localeCode,
            ),
            SizedBox(height: 16),
            // 결과 요약
            _buildSummaryCard(
              summary,
              currencyFormat,
              provider.selectedScenario,
            ),
          ],
        ),
      ),
    );
  }

  Color _getAssetColor(String assetId) {
    // 자산별 색상 지정
    switch (assetId.toLowerCase()) {
      case 'bitcoin':
        return AppColors.gold;
      case 'tesla':
        return AppColors.success;
      case 'ethereum':
        return AppColors.info;
      default:
        return AppColors.slate300;
    }
  }

  Widget _buildCombinedChart(
    RetireSimulatorProvider provider,
    List<FlSpot> totalSpots,
    List<Map<String, dynamic>> assetSpotsList,
    NumberFormat currencyFormat,
  ) {
    // 누적 인출액 라인 생성 (월별로 누적)
    final withdrawalSpots = <FlSpot>[];
    double cumulativeWithdrawal = 0.0;
    for (int i = 0; i < totalSpots.length; i++) {
      if (i > 0) {
        // 첫 달부터 인출 시작
        cumulativeWithdrawal += provider.monthlyWithdrawal;
      }
      final year = i / 12.0;
      withdrawalSpots.add(FlSpot(year, cumulativeWithdrawal));
    }

    // 모든 라인 데이터 준비
    final lineBarsData = <LineChartBarData>[
      // 전체 자산 라인
      LineChartBarData(
        spots: totalSpots,
        isCurved: true,
        color: Colors.white,
        barWidth: 4,
        dotData: FlDotData(show: false),
        isStrokeCapRound: true,
      ),
      // 누적 인출액 라인 (점선으로 표시)
      LineChartBarData(
        spots: withdrawalSpots,
        isCurved: true,
        color: Colors.orange.withValues(alpha: 0.7),
        barWidth: 2,
        dotData: FlDotData(show: false),
        dashArray: [5, 5], // 점선
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
          dotData: FlDotData(show: false),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('자산 가치 추이', style: AppTextStyles.chartSectionTitle),
        SizedBox(height: 20),
        Container(
          height: 350,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.navyMedium,
            borderRadius: BorderRadius.circular(20),
          ),
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: provider.simulationYears.toDouble(),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) {
                  return FlLine(color: AppColors.slate700, strokeWidth: 1);
                },
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(
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
                        // 5년 간격으로 표시하거나, 시작/끝 표시
                        if (yearOffset == 0 ||
                            yearOffset == provider.simulationYears ||
                            yearOffset % 5 == 0) {
                          final actualYear = 2025 + yearOffset;
                          return Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                              '$actualYear년',
                              style: TextStyle(
                                color: AppColors.slate300,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }
                      }
                      return Text('');
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 80,
                    interval: _calculateYAxisInterval(totalSpots),
                    getTitlesWidget: (value, meta) {
                      if (value <= 0) return Text('');
                      return Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Text(
                          currencyFormat.format(value),
                          style: TextStyle(
                            color: AppColors.slate300,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.right,
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
                  getTooltipColor: (touchedSpot) => AppColors.navyMedium,
                  tooltipPadding: EdgeInsets.all(12),
                  tooltipMargin: 16,
                  maxContentWidth: 200, // 툴팁 최대 너비 설정 (길면 자동 줄바꿈)
                  getTooltipItems: (List<LineBarSpot> touchedSpots) {
                    return touchedSpots.map((LineBarSpot touchedSpot) {
                      final formattedValue = currencyFormat.format(
                        touchedSpot.y,
                      );
                      return LineTooltipItem(
                        formattedValue,
                        TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 20),
        // 범례
        _buildLegend(totalSpots, assetSpotsList),
      ],
    );
  }

  Widget _buildLegend(
    List<FlSpot> totalSpots,
    List<Map<String, dynamic>> assetSpotsList,
  ) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      runSpacing: 12,
      children: [
        _buildLegendItem('전체 자산', Colors.white, false),
        _buildLegendItem('누적 인출액', Colors.orange.withValues(alpha: 0.7), true),
        ...assetSpotsList.map((assetData) {
          final name = assetData['name'] as String;
          final icon = assetData['icon'] as String;
          final color = assetData['color'] as Color;
          return _buildLegendItem('$icon $name', color, false);
        }),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, bool isDashed) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isDashed)
          CustomPaint(
            size: Size(16, 3),
            painter: DashedLinePainter(color: color),
          )
        else
          Container(width: 16, height: 3, color: color),
        SizedBox(width: 8),
        Text(label, style: TextStyle(color: AppColors.slate300, fontSize: 12)),
      ],
    );
  }

  Widget _buildReadableSummaryCard(
    RetireSimulatorProvider provider,
    AppStateProvider appProvider,
    Map<String, dynamic> summary,
    NumberFormat currencyFormat,
    String localeCode,
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
      final assetName = assetOption?.displayName(localeCode) ?? asset.assetId;
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

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.navyMedium,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.slate700),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description_outlined, color: AppColors.gold, size: 20),
              SizedBox(width: 8),
              Text(
                '시뮬레이션 결과',
                style: TextStyle(
                  color: AppColors.gold,
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
                color: Colors.white,
                fontSize: _simulationResultValueFontSize,
                height: 1.6, // 줄 간격
              ),
              children: [
                TextSpan(text: ''),
                TextSpan(
                  text: initialAssetText,
                  style: TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.bold,
                    fontSize: _simulationResultValueFontSize + 2,
                  ),
                ),
                TextSpan(text: ' 어치의 '),
                TextSpan(
                  text: portfolioText,
                  style: TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.bold,
                    fontSize: _simulationResultValueFontSize + 2,
                  ),
                ),
                TextSpan(text: '를 '),
                TextSpan(
                  text: '${provider.simulationYears}년',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.bold,
                    fontSize: _simulationResultValueFontSize + 2,
                  ),
                ),
                TextSpan(text: '간 보유하고 한달에 '),
                TextSpan(
                  text: monthlyWithdrawalText,
                  style: TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.bold,
                    fontSize: _simulationResultValueFontSize + 2,
                  ),
                ),
                TextSpan(text: '씩 쓴다고 하면 '),
                TextSpan(
                  text: '${provider.simulationYears}년',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.bold,
                    fontSize: _simulationResultValueFontSize + 2,
                  ),
                ),
                TextSpan(text: ' 후 최종 자산은 '),
                TextSpan(
                  text: finalAssetText,
                  style: TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.bold,
                    fontSize: _simulationResultValueFontSize + 2,
                  ),
                ),
                TextSpan(text: '이 됩니다.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    Map<String, dynamic> summary,
    NumberFormat currencyFormat,
    String scenario,
  ) {
    final scenarioColor = scenario == 'positive'
        ? AppColors.success
        : scenario == 'negative'
        ? Colors.red
        : AppColors.gold;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.navyMedium,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scenarioColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '상세 통계',
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
                  '최종 자산',
                  currencyFormat.format(summary['finalAsset']),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  '누적 수익률',
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
                  '총 인출 금액',
                  currencyFormat.format(summary['totalWithdrawn']),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  '순 수익',
                  currencyFormat.format(summary['totalReturn']),
                ),
              ),
            ],
          ),
        ],
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
            color: AppColors.slate400,
            fontSize: _simulationResultLabelFontSize,
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
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
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('월별 상세 내역', style: AppTextStyles.chartSectionTitle),
        SizedBox(height: 16),
        Container(
          height: 400,
          child: ListView.builder(
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
              final monthlyWithdrawal = month > 0
                  ? provider.monthlyWithdrawal
                  : 0.0;

              // 모든 월 표시

              return Container(
                margin: EdgeInsets.only(bottom: 8),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.navyMedium,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.slate700, width: 1),
                ),
                child: Row(
                  children: [
                    // 월 정보
                    Container(
                      width: 60,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${year}년',
                            style: TextStyle(
                              color: AppColors.slate400,
                              fontSize: _monthlyCardYearFontSize,
                            ),
                          ),
                          Text(
                            '${monthInYear}월',
                            style: TextStyle(
                              color: AppColors.gold,
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
                                '자산',
                                style: TextStyle(
                                  color: AppColors.slate400,
                                  fontSize: _monthlyCardLabelFontSize,
                                ),
                              ),
                              Text(
                                currencyFormat.format(currentAsset),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: _monthlyCardValueFontSize,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          if (month > 0) ...[
                            SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '인출',
                                  style: TextStyle(
                                    color: Colors.orange.withValues(alpha: 0.8),
                                    fontSize: _monthlyCardLabelFontSize,
                                  ),
                                ),
                                Text(
                                  '-${currencyFormat.format(monthlyWithdrawal)}',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontSize: _monthlyCardSubValueFontSize,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '변동',
                                  style: TextStyle(
                                    color: AppColors.slate400,
                                    fontSize: _monthlyCardLabelFontSize,
                                  ),
                                ),
                                Text(
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
    );
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
