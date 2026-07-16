import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/app_state_provider.dart';
import '../providers/retire_simulator_provider.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';
import '../utils/retire_chart_style.dart';
import '../widgets/race_chart.dart';
import 'retire_simulator_result_screen.dart';

class _RetireRaceSeries {
  final String assetId;
  final String name;
  final Color color;
  final List<RacePoint> spots;
  final double initialValue;

  const _RetireRaceSeries({
    required this.assetId,
    required this.name,
    required this.color,
    required this.spots,
    required this.initialValue,
  });
}

/// 은퇴 시뮬레이션 공개 애니메이션.
/// 성장률 경주와 동일한 RaceChart + 사용자가 추가한 자산 각각을 레이스 라인으로 표시.
class RetireChartRevealScreen extends StatefulWidget {
  const RetireChartRevealScreen({super.key});

  @override
  State<RetireChartRevealScreen> createState() =>
      _RetireChartRevealScreenState();
}

class _RetireChartRevealScreenState extends State<RetireChartRevealScreen> {
  static const _withdrawId = 'retire_withdraw';

  Timer? _timer;
  int _revealIndex = 0;
  bool _navigated = false;
  bool _raceComplete = false;

  List<_RetireRaceSeries> _assetSeries = const [];
  List<RacePoint> _withdrawFull = const [];
  double _initialTotal = 0;
  double _minY = 0;
  double _maxY = 1;
  double _raceEndX = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepareAndStart());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _prepareAndStart() {
    final provider = context.read<RetireSimulatorProvider>();
    final appProvider = context.read<AppStateProvider>();
    final l10n = AppLocalizations.of(context)!;
    final results = provider.runSimulation();
    final totalPath = results['total'] as List<double>? ?? [];
    final assetPaths =
        results['assets'] as Map<String, List<double>>? ?? {};

    if (totalPath.isEmpty) {
      _goToResult();
      return;
    }

    final assetSeries = <_RetireRaceSeries>[];
    var colorIndex = 0;

    // 시뮬레이션에 포함된 자산만 (현금 + 보유 자산). cash는 제외하고 실제 투자 자산 우선,
    // cash만 있으면 cash도 표시.
    final orderedIds = provider.assets.map((a) => a.assetId).toList();
    final nonCashIds = orderedIds.where((id) => id != 'cash').toList();
    final idsToShow = nonCashIds.isNotEmpty ? nonCashIds : orderedIds;

    for (final assetId in idsToShow) {
      final path = assetPaths[assetId];
      if (path == null || path.isEmpty) continue;

      String name = assetId;
      try {
        name = appProvider.assets
            .firstWhere((a) => a.id == assetId)
            .displayName();
      } catch (_) {
        if (assetId == 'cash') name = l10n.cash;
      }

      assetSeries.add(
        _RetireRaceSeries(
          assetId: assetId,
          name: name,
          color: RetireChartStyle.assetAt(colorIndex),
          spots: [
            for (var i = 0; i < path.length; i++)
              RacePoint(i.toDouble(), path[i]),
          ],
          initialValue: path.first,
        ),
      );
      colorIndex++;
    }

    // 자산이 하나도 없으면 전체 자산 라인으로 대체
    if (assetSeries.isEmpty) {
      assetSeries.add(
        _RetireRaceSeries(
          assetId: 'retire_total',
          name: l10n.totalAssets,
          color: RetireChartStyle.assetAt(0),
          spots: [
            for (var i = 0; i < totalPath.length; i++)
              RacePoint(i.toDouble(), totalPath[i]),
          ],
          initialValue: totalPath.first,
        ),
      );
    }

    final withdrawFull = <RacePoint>[];
    var cumulative = 0.0;
    for (var i = 0; i < totalPath.length; i++) {
      if (i > 0) {
        final year = (i - 1) ~/ 12;
        cumulative +=
            provider.monthlyWithdrawal *
            math.pow(1 + provider.inflationRate, year);
      }
      withdrawFull.add(RacePoint(i.toDouble(), cumulative));
    }

    var maxY = 0.0;
    var minY = double.infinity;
    for (final s in assetSeries) {
      for (final p in s.spots) {
        if (p.y > maxY) maxY = p.y;
        if (p.y < minY) minY = p.y;
      }
    }
    for (final p in withdrawFull) {
      if (p.y > maxY) maxY = p.y;
      if (p.y < minY) minY = p.y;
    }
    if (!minY.isFinite) minY = 0;
    final pad = math.max((maxY - minY) * 0.1, 1.0);
    final endX = (totalPath.length - 1).toDouble();

    setState(() {
      _assetSeries = assetSeries;
      _withdrawFull = withdrawFull;
      _initialTotal = totalPath.first;
      _maxY = maxY + pad;
      _minY = math.max(0, minY - pad);
      _raceEndX = endX;
      _revealIndex = 0;
      _raceComplete = false;
    });

    _startAnimation();
  }

  void _startAnimation() {
    _timer?.cancel();
    if (_assetSeries.isEmpty) {
      _goToResult();
      return;
    }

    final length = _assetSeries.first.spots.length;
    final step = math.max(1, (length / 200).ceil());

    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final next = _revealIndex + step;
      if (next >= length - 1) {
        setState(() {
          _revealIndex = length - 1;
          _raceComplete = true;
        });
        timer.cancel();
        Future.delayed(const Duration(milliseconds: 700), _goToResult);
        return;
      }
      setState(() => _revealIndex = next);
    });
  }

  void _goToResult() {
    if (_navigated || !mounted) return;
    _navigated = true;
    _timer?.cancel();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const RetireSimulatorResultScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 420),
      ),
    );
  }

  List<RacePoint> _visible(List<RacePoint> full) {
    if (full.isEmpty) return full;
    final end = (_revealIndex + 1).clamp(1, full.length);
    return full.sublist(0, end);
  }

  double _pct(double current, double initial) {
    if (initial <= 0) return 0;
    return ((current - initial) / initial) * 100;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final yearNow = 2025 + (_revealIndex / 12.0).floor();

    final raceEntries = <RaceChartData>[];
    for (final s in _assetSeries) {
      final vis = _visible(s.spots);
      final y = vis.isEmpty ? 0.0 : vis.last.y;
      raceEntries.add(
        RaceChartData(
          assetId: s.assetId,
          name: s.name,
          icon: '',
          color: s.color,
          spots: vis,
          currentGrowthRate: _pct(y, s.initialValue),
          rank: 0, // filled after sort
        ),
      );
    }

    final withdrawVis = _visible(_withdrawFull);
    final withdrawY = withdrawVis.isEmpty ? 0.0 : withdrawVis.last.y;
    raceEntries.add(
      RaceChartData(
        assetId: _withdrawId,
        name: l10n.cumulativeWithdrawal,
        icon: '',
        color: RetireChartStyle.withdrawal,
        spots: withdrawVis,
        currentGrowthRate: _initialTotal > 0
            ? (withdrawY / _initialTotal) * 100
            : 0,
        rank: 0,
      ),
    );

    // 현재 값(또는 성장률) 기준 순위 — 자산 가치 경주에 맞게 현재 Y로 정렬
    final ranked = [...raceEntries]
      ..sort((a, b) {
        final ay = a.spots.isEmpty ? 0.0 : a.spots.last.y;
        final by = b.spots.isEmpty ? 0.0 : b.spots.last.y;
        return by.compareTo(ay);
      });
    final series = [
      for (var i = 0; i < ranked.length; i++)
        RaceChartData(
          assetId: ranked[i].assetId,
          name: ranked[i].name,
          icon: ranked[i].icon,
          color: ranked[i].color,
          spots: ranked[i].spots,
          currentGrowthRate: ranked[i].currentGrowthRate,
          rank: i,
        ),
    ];

    final leadX = series.isEmpty || series.first.spots.isEmpty
        ? 0.0
        : series.map((s) => s.spots.isEmpty ? 0.0 : s.spots.last.x).reduce(math.max);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: _goToResult,
        ),
        title: Text(
          l10n.assetValueTrend,
          style: AppTextStyles.appBarTitle,
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _goToResult,
            child: Text(
              l10n.simulationResultTitle,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
          child: Column(
            children: [
              Text(
                l10n.yearLabel(yearNow),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: _assetSeries.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: AppColors.navyDark,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: RaceChart(
                          series: series,
                          minX: 0,
                          maxX: leadX,
                          minY: _minY,
                          maxY: _maxY,
                          raceStartX: 0,
                          raceEndX: _raceEndX,
                          isRaceComplete: _raceComplete,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
