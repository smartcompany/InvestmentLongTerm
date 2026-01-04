import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/app_state_provider.dart';
import '../providers/growth_race_provider.dart';
import '../utils/colors.dart';
import 'package:fl_chart/fl_chart.dart';
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

    double progress = 0.0;
    _raceTimer?.cancel();

    _raceTimer = Timer.periodic(Duration(milliseconds: 50), (timer) {
      if (!mounted || !provider.isRacing) {
        timer.cancel();
        return;
      }

      if (progress >= 1.0) {
        timer.cancel();
        return;
      }

      provider.updateRaceProgress(progress);
      progress += 0.01; // 진행도 증가 (약 10초에 완료)
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
        actions: [
          if (provider.isRacing)
            IconButton(
              icon: Icon(Icons.pause, color: Colors.white),
              onPressed: () {
                provider.stopRace();
                _raceTimer?.cancel();
              },
            ),
        ],
      ),
      body: SafeArea(
        child: provider.priceData.isEmpty
            ? Center(
                child: Text(
                  '데이터를 불러오는 중...',
                  style: TextStyle(color: AppColors.slate400),
                ),
              )
            : _buildRaceChart(provider, appProvider, localeCode),
      ),
    );
  }

  Widget _buildRaceChart(
    GrowthRaceProvider provider,
    AppStateProvider appProvider,
    String localeCode,
  ) {
    final priceData = provider.priceData;
    final rankedAssetIds = provider.rankedAssetIds;
    final progress = provider.progress;

    final raceSeries = <RaceChartData>[];
    double maxX = 0.0;
    double minX = 0.0;
    bool hasXData = false;
    // 초기 투자 금액 (100만원)
    const double initialInvestment = 1000000.0;

    // 색상 목록
    final colors = [
      AppColors.gold,
      AppColors.success,
      Colors.blue,
      Colors.purple,
      Colors.pink,
      Colors.orange,
      Colors.cyan,
      Colors.teal,
    ];

    for (int i = 0; i < rankedAssetIds.length; i++) {
      final assetId = rankedAssetIds[i];
      final asset = appProvider.assets.firstWhere((a) => a.id == assetId);
      final data = priceData[assetId];

      if (data != null && data.isNotEmpty) {
        final firstPrice = (data[0]['price'] as num).toDouble();
        final spots = <FlSpot>[];

        // 첫 번째 날짜를 기준으로 설정
        DateTime? startDate;
        try {
          final firstDateStr = data[0]['date'] as String?;
          if (firstDateStr != null) {
            startDate = DateTime.parse(firstDateStr);
          }
        } catch (e) {
          // 날짜 파싱 실패 시 인덱스 사용
        }

        // 진행도에 비례한 인덱스 계산
        final endIndex = ((progress * (data.length - 1))).round().clamp(
          0,
          data.length - 1,
        );
        for (int j = 0; j <= endIndex; j++) {
          final price = (data[j]['price'] as num).toDouble();

          // Y축: 초기 투자 금액으로 산 자산의 현재 가치
          final assetValue = firstPrice > 0
              ? (initialInvestment / firstPrice) * price
              : 0.0;

          // X축: 날짜 사용 (시작일부터의 일수)
          double xValue;
          if (startDate != null) {
            try {
              final dateStr = data[j]['date'] as String?;
              if (dateStr != null) {
                final currentDate = DateTime.parse(dateStr);
                final daysDiff = currentDate.difference(startDate).inDays;
                xValue = daysDiff.toDouble();
              } else {
                xValue = j.toDouble();
              }
            } catch (e) {
              xValue = j.toDouble();
            }
          } else {
            xValue = j.toDouble();
          }

          spots.add(FlSpot(xValue, assetValue));

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

        // 레이블용 수익률 계산 (%)
        final currentPrice =
            data[math.min(endIndex, data.length - 1)]['price'] as num;
        final currentGrowthRate = firstPrice > 0
            ? ((currentPrice.toDouble() - firstPrice) / firstPrice) * 100
            : 0.0;

        raceSeries.add(
          RaceChartData(
            assetId: assetId,
            name: asset.displayName(localeCode),
            icon: asset.icon,
            color: colors[i % colors.length],
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

    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: EdgeInsets.all(16),
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
            ),
    );
  }
}
