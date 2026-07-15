import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/app_state_provider.dart';
import '../providers/growth_race_provider.dart';
import '../utils/colors.dart';
import '../utils/chart_image_utils.dart';
import '../widgets/common_share_ui.dart';
import '../services/ad_service.dart';
import '../widgets/race_chart.dart';

class GrowthRaceChartScreen extends StatefulWidget {
  const GrowthRaceChartScreen({super.key});

  @override
  State<GrowthRaceChartScreen> createState() => _GrowthRaceChartScreenState();
}

class _GrowthRaceChartScreenState extends State<GrowthRaceChartScreen>
    with SingleTickerProviderStateMixin {
  Timer? _raceTimer;
  late AnimationController _animationController;
  final GlobalKey _chartKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<GrowthRaceProvider>();
      if (!provider.isRacing && provider.priceData.isNotEmpty) {
        provider.startRace();
        _animateRace();
      }
    });
  }

  @override
  void dispose() {
    _raceTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _animateRace() {
    final provider = context.read<GrowthRaceProvider>();
    final priceData = provider.priceData;

    if (priceData.isEmpty) return;

    // 모든 자산의 날짜 범위에서 가장 오래된 날짜와 가장 최신 날짜 찾기
    DateTime? startDate;
    DateTime? endDate;
    for (final data in priceData.values) {
      if (data.isNotEmpty) {
        try {
          final firstDateStr = data[0]['date'] as String?;
          final lastDateStr = data[data.length - 1]['date'] as String?;
          if (firstDateStr != null && lastDateStr != null) {
            final firstDate = DateTime.parse(firstDateStr);
            final lastDate = DateTime.parse(lastDateStr);
            if (startDate == null || firstDate.isBefore(startDate)) {
              startDate = firstDate;
            }
            if (endDate == null || lastDate.isAfter(endDate)) {
              endDate = lastDate;
            }
          }
        } catch (e) {
          // 날짜 파싱 실패 시 무시
        }
      }
    }

    if (startDate == null || endDate == null) return;

    final start = startDate;
    final end = endDate;

    DateTime currentDate = start;
    final totalDuration = end.difference(start);
    final stepDuration = Duration(
      milliseconds: (totalDuration.inMilliseconds / 200).round(),
    ); // 약 200단계

    _raceTimer?.cancel();

    _raceTimer = Timer.periodic(Duration(milliseconds: 50), (timer) {
      if (!mounted || !provider.isRacing) {
        timer.cancel();
        return;
      }

      if (currentDate.isAfter(end) || currentDate.isAtSameMomentAs(end)) {
        // 마지막 날짜로 설정하여 완료 상태로 만듦
        provider.updateRaceDate(end);
        timer.cancel();
        return;
      }

      provider.updateRaceDate(currentDate);
      currentDate = currentDate.add(stepDuration);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeCode = Localizations.localeOf(context).languageCode;
    final provider = context.watch<GrowthRaceProvider>();
    final appProvider = context.watch<AppStateProvider>();

    return Scaffold(
      backgroundColor: AppColors.navyDark,
      appBar: AppBar(
        backgroundColor: AppColors.navyDark,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            provider.stopRace();
            Navigator.of(context).pop();
          },
        ),
        title: Text(l10n.growthRace, style: TextStyle(color: Colors.white)),
      ),
      body: SafeArea(
        child: provider.priceData.isEmpty
            ? Center(
                child: Text(
                  '데이터를 불러오는 중...',
                  style: TextStyle(color: AppColors.slate400),
                ),
              )
            : _buildRaceChart(provider, appProvider, localeCode, l10n),
      ),
    );
  }

  Widget _buildRaceChart(
    GrowthRaceProvider provider,
    AppStateProvider appProvider,
    String localeCode,
    AppLocalizations l10n,
  ) {
    final priceData = provider.priceData;
    final rankedAssetIds = provider.rankedAssetIds;
    final currentDate = provider.currentDate;

    final raceSeries = <RaceChartData>[];
    double maxX = 0.0;
    double minX = 0.0;
    bool hasXData = false;
    // 레이스 전체 구간 (카메라 pull-out용) — currentDate와 무관하게 전체 데이터에서 계산
    double raceStartX = 0.0;
    double raceEndX = 0.0;
    bool hasRaceRange = false;
    // 초기 투자 금액 (100만원)
    const double initialInvestment = 1000000.0;

    for (final data in priceData.values) {
      if (data.isEmpty) continue;
      try {
        final firstStr = data.first['date'] as String?;
        final lastStr = data.last['date'] as String?;
        if (firstStr == null || lastStr == null) continue;
        final firstMs = DateTime.parse(firstStr).millisecondsSinceEpoch.toDouble();
        final lastMs = DateTime.parse(lastStr).millisecondsSinceEpoch.toDouble();
        if (!hasRaceRange) {
          raceStartX = firstMs;
          raceEndX = lastMs;
          hasRaceRange = true;
        } else {
          if (firstMs < raceStartX) raceStartX = firstMs;
          if (lastMs > raceEndX) raceEndX = lastMs;
        }
      } catch (_) {}
    }

    // 색상은 순위가 아니라 선택 순서 기준으로 고정 (그래프·종목명 동일)
    const colors = [
      AppColors.gold,
      AppColors.success,
      Colors.blue,
      Colors.purple,
      Colors.pink,
      Colors.orange,
      Colors.cyan,
      Colors.teal,
    ];
    final assetColors = <String, Color>{};
    var colorIndex = 0;
    for (final assetId in provider.selectedAssetIds) {
      assetColors[assetId] = colors[colorIndex % colors.length];
      colorIndex++;
    }

    for (int i = 0; i < rankedAssetIds.length; i++) {
      final assetId = rankedAssetIds[i];
      final asset = appProvider.assets.firstWhere((a) => a.id == assetId);
      final data = priceData[assetId];

      if (data != null && data.isNotEmpty) {
        final firstPrice = (data[0]['price'] as num).toDouble();
        final spots = <RacePoint>[];
        double? lastKnownPrice = firstPrice;

        // currentDate까지의 데이터만 차트에 추가
        for (int j = 0; j < data.length; j++) {
          try {
            final dateStr = data[j]['date'] as String?;
            if (dateStr != null) {
              final dataDate = DateTime.parse(dateStr);

              // currentDate가 null이면 모든 데이터 표시, 아니면 currentDate까지만
              if (currentDate != null && dataDate.isAfter(currentDate)) {
                break;
              }

              final price = (data[j]['price'] as num).toDouble();
              lastKnownPrice = price;

              // Y축: 초기 투자 금액으로 산 자산의 현재 가치
              final assetValue = firstPrice > 0
                  ? (initialInvestment / firstPrice) * price
                  : 0.0;

              // X축: 실제 날짜 (DateTime의 millisecondsSinceEpoch 사용)
              final xValue = dataDate.millisecondsSinceEpoch.toDouble();

              spots.add(RacePoint(xValue, assetValue));

              // X축 범위 업데이트
              if (!hasXData) {
                maxX = xValue;
                minX = xValue;
                hasXData = true;
              } else {
                if (xValue > maxX) maxX = xValue;
                if (xValue < minX) minX = xValue;
              }
            }
          } catch (e) {
            // 날짜 파싱 실패 시 무시
          }
        }

        // 레이블용 수익률 계산 (%)
        final currentPrice = lastKnownPrice ?? firstPrice;
        final currentGrowthRate = firstPrice > 0
            ? ((currentPrice - firstPrice) / firstPrice) * 100
            : 0.0;

        raceSeries.add(
          RaceChartData(
            assetId: assetId,
            name: asset.displayName(),
            icon: asset.icon,
            color: assetColors[assetId] ?? colors[i % colors.length],
            spots: spots,
            currentGrowthRate: currentGrowthRate, // 수익률 % (레이블 표시용)
            rank: i,
          ),
        );
      }
    }

    // Y축 범위 설정 - 실제 차트에 그려지는 모든 FlSpot 값에서 계산
    double maxY = 0.0;
    double minY = 0.0;
    bool hasValidData = false;

    for (final series in raceSeries) {
      for (final spot in series.spots) {
        if (spot.y.isFinite) {
          if (!hasValidData) {
            maxY = spot.y;
            minY = spot.y;
            hasValidData = true;
          } else {
            if (spot.y > maxY) maxY = spot.y;
            if (spot.y < minY) minY = spot.y;
          }
        }
      }
    }

    if (!hasValidData) {
      maxY = 1500000.0; // 기본값: 150만원
      minY = 500000.0; // 기본값: 50만원
    } else {
      // 약간의 패딩 추가
      final range = maxY - minY;
      final padding = range > 0 ? range * 0.1 : 100000.0;
      maxY = maxY + padding;
      minY = math.max(0, minY - padding); // 최소값은 0 이상
    }

    final raceComplete = _isRaceComplete(provider, priceData);

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          RepaintBoundary(
            key: _chartKey,
            child: SizedBox(
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.6,
              child: raceSeries.isEmpty
                  ? Center(
                      child: Text(
                        '데이터를 불러오는 중...',
                        style: TextStyle(color: AppColors.slate400),
                      ),
                    )
                  : RaceChart(
                      series: raceSeries,
                      maxX: hasXData ? maxX : 0.0,
                      minX: hasXData ? minX : 0.0,
                      maxY: maxY,
                      minY: minY,
                      raceStartX: hasRaceRange ? raceStartX : minX,
                      raceEndX: hasRaceRange ? raceEndX : maxX,
                      isRaceComplete: raceComplete,
                    ),
            ),
          ),
          if (raceComplete) ...[
            SizedBox(height: 32),
            _buildShareButton(provider, appProvider, localeCode, l10n),
            SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  bool _isRaceComplete(
    GrowthRaceProvider provider,
    Map<String, List<Map<String, dynamic>>> priceData,
  ) {
    final currentDate = provider.currentDate;
    if (currentDate == null) return false;

    // 모든 자산의 가장 최신 날짜 찾기
    DateTime? latestDate;
    for (final data in priceData.values) {
      if (data.isNotEmpty) {
        try {
          final lastDateStr = data[data.length - 1]['date'] as String?;
          if (lastDateStr != null) {
            final date = DateTime.parse(lastDateStr);
            if (latestDate == null || date.isAfter(latestDate)) {
              latestDate = date;
            }
          }
        } catch (e) {
          // 날짜 파싱 실패 시 무시
        }
      }
    }

    if (latestDate == null) return false;
    return currentDate.isAfter(latestDate) ||
        currentDate.isAtSameMomentAs(latestDate);
  }

  Widget _buildShareButton(
    GrowthRaceProvider provider,
    AppStateProvider appProvider,
    String localeCode,
    AppLocalizations l10n,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          final shareText = _buildShareText(
            provider,
            appProvider,
            localeCode,
            l10n,
          );

          // Convert chart to image
          final chartImageBytes = await ChartImageUtils.widgetToImage(
            _chartKey,
          );

          if (!mounted) return;
          await CommonShareUI.showShareOptionsDialog(
            context: context,
            shareText: shareText,
            chartImageBytes: chartImageBytes,
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.navyDark,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: Icon(Icons.share_outlined),
        label: Text(
          l10n.share,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  String _buildShareText(
    GrowthRaceProvider provider,
    AppStateProvider appProvider,
    String localeCode,
    AppLocalizations l10n,
  ) {
    final buffer = StringBuffer();
    final rankedAssetIds = provider.rankedAssetIds;
    final priceData = provider.priceData;

    buffer.writeln('📊 ${l10n.growthRace}');
    buffer.writeln('');
    buffer.writeln('${provider.selectedYears}년 기준 자산들의 성장률을 경주로 비교한 결과입니다.');
    buffer.writeln('');

    for (int i = 0; i < rankedAssetIds.length; i++) {
      final assetId = rankedAssetIds[i];
      final asset = appProvider.assets.firstWhere((a) => a.id == assetId);
      final data = priceData[assetId];

      if (data != null && data.isNotEmpty) {
        final firstPrice = (data[0]['price'] as num).toDouble();
        final lastPrice = (data[data.length - 1]['price'] as num).toDouble();
        final growthRate = firstPrice > 0
            ? ((lastPrice - firstPrice) / firstPrice) * 100
            : 0.0;

        final emoji = i == 0
            ? '🏆'
            : i == 1
            ? '🥈'
            : i == 2
            ? '🥉'
            : '📈';

        buffer.writeln(
          '$emoji ${i + 1}위: ${asset.displayName()} ${asset.icon}',
        );
        buffer.writeln('   수익률: ${growthRate.toStringAsFixed(2)}%');
        buffer.writeln('');
      }
    }

    buffer.writeln('');
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
