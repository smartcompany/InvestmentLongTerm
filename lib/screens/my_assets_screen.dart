import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../l10n/app_localizations.dart';
import '../providers/my_assets_provider.dart';
import '../providers/app_state_provider.dart';
import '../models/my_asset.dart';
import '../utils/colors.dart';
import '../widgets/liquid_glass.dart';
import '../widgets/add_asset_dialog.dart';
import 'package:fl_chart/fl_chart.dart';
import 'asset_detail_screen.dart';

class MyAssetsScreen extends StatefulWidget {
  const MyAssetsScreen({super.key});

  @override
  State<MyAssetsScreen> createState() => _MyAssetsScreenState();
}

class _MyAssetsScreenState extends State<MyAssetsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MyAssetsProvider>().loadAssets();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MyAssetsProvider>();
    final l10n = AppLocalizations.of(context)!;

    // 상태바 투명하게 설정
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
    );

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.navyDark, AppColors.navyMedium],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 24,
            bottom:
                MediaQuery.of(context).padding.bottom + 80, // 탭바 높이 + SafeArea
            left: 24,
            right: 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 타이틀 (가운데 정렬)
              Text(
                l10n.myAssets,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 24),
              // 포트폴리오 그래프 (자산이 있을 때만 표시)
              if (provider.assets.isNotEmpty)
                Container(
                  height: 200,
                  margin: EdgeInsets.only(bottom: 24),
                  child: provider.isLoadingPortfolio
                      ? Center(
                          child: CircularProgressIndicator(
                            color: AppColors.gold,
                          ),
                        )
                      : provider.portfolioSpots != null &&
                            provider.portfolioSpots!.isNotEmpty
                      ? LiquidGlass(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.18),
                              width: 1.5,
                            ),
                          ),
                          padding: EdgeInsets.all(16),
                          child: LineChart(
                            LineChartData(
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                horizontalInterval: _calculatePriceInterval(
                                  provider.portfolioSpots!,
                                ),
                                getDrawingHorizontalLine: (value) {
                                  return FlLine(
                                    color: AppColors.slate700.withOpacity(0.2),
                                    strokeWidth: 1,
                                  );
                                },
                              ),
                              titlesData: FlTitlesData(
                                show: true,
                                rightTitles: AxisTitles(
                                  sideTitles: SideTitles(reservedSize: 0),
                                ),
                                topTitles: AxisTitles(
                                  sideTitles: SideTitles(reservedSize: 0),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    reservedSize: 30,
                                    interval: 0.25,
                                    getTitlesWidget: (value, meta) {
                                      if (provider.portfolioStartDate == null) {
                                        return SizedBox.shrink();
                                      }
                                      final totalDays = provider
                                          .portfolioEndDate!
                                          .difference(
                                            provider.portfolioStartDate!,
                                          )
                                          .inDays;
                                      final daysFromStart = (value * totalDays)
                                          .round();
                                      final date = provider.portfolioStartDate!
                                          .add(Duration(days: daysFromStart));
                                      return Padding(
                                        padding: EdgeInsets.only(top: 8),
                                        child: Text(
                                          DateFormat('MM/dd').format(date),
                                          style: TextStyle(
                                            color: AppColors.slate400,
                                            fontSize: 10,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    reservedSize: 50,
                                    interval: _calculatePriceInterval(
                                      provider.portfolioSpots!,
                                    ),
                                    getTitlesWidget: (value, meta) {
                                      return Text(
                                        NumberFormat('#,###').format(value),
                                        style: TextStyle(
                                          color: AppColors.slate400,
                                          fontSize: 10,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(
                                show: true,
                                border: Border(
                                  bottom: BorderSide(
                                    color: AppColors.slate700.withOpacity(0.3),
                                    width: 1,
                                  ),
                                  left: BorderSide(
                                    color: AppColors.slate700.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                              ),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: provider.portfolioSpots!,
                                  isCurved: true,
                                  color: AppColors.gold,
                                  barWidth: 3,
                                  isStrokeCapRound: true,
                                  dotData: FlDotData(show: false),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: AppColors.gold.withOpacity(0.1),
                                  ),
                                ),
                              ],
                              lineTouchData: LineTouchData(
                                touchTooltipData: LineTouchTooltipData(
                                  getTooltipColor: (touchedSpot) =>
                                      AppColors.navyMedium,
                                  tooltipPadding: EdgeInsets.all(12),
                                  tooltipMargin: 16,
                                  getTooltipItems:
                                      (List<LineBarSpot> touchedBarSpots) {
                                        return touchedBarSpots.map((barSpot) {
                                          return LineTooltipItem(
                                            NumberFormat(
                                              '#,###',
                                            ).format(barSpot.y),
                                            TextStyle(
                                              color: AppColors.gold,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          );
                                        }).toList();
                                      },
                                ),
                              ),
                            ),
                          ),
                        )
                      : SizedBox.shrink(),
                ),
              // 통계 카드 (자산이 있을 때만 표시)
              if (provider.assets.isNotEmpty)
                Container(
                  margin: EdgeInsets.only(bottom: 24),
                  child: LiquidGlass(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.18),
                        width: 1.5,
                      ),
                    ),
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${l10n.totalPurchaseAmount}: ${NumberFormat('#,###').format(provider.totalPurchaseAmount)}',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        SizedBox(height: 12),
                        Text(
                          provider.totalCurrentValue != null
                              ? '${l10n.currentValue}: ${NumberFormat('#,###').format(provider.totalCurrentValue!)}'
                              : '${l10n.currentValue}: ${l10n.loadingPrice}',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        SizedBox(height: 12),
                        Text(
                          provider.totalReturnRate != null
                              ? '${l10n.totalReturnRate}: ${provider.totalReturnRate!.toStringAsFixed(2)}%'
                              : '${l10n.totalReturnRate}: -',
                          style: TextStyle(
                            color:
                                provider.totalReturnRate != null &&
                                    provider.totalReturnRate! >= 0
                                ? AppColors.success
                                : Colors.red,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              // 자산 카드 목록
              ...provider.assets.map((asset) {
                return _buildAssetCard(context, asset, provider, l10n);
              }).toList(),
              // 자산이 없을 때 빈 상태 메시지
              if (provider.assets.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Column(
                    children: [
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 64,
                        color: AppColors.slate400,
                      ),
                      SizedBox(height: 16),
                      Text(
                        l10n.noAssetsRegistered,
                        style: TextStyle(
                          color: AppColors.slate400,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        l10n.addAssetToTrack,
                        style: TextStyle(
                          color: AppColors.slate400,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(height: 24),
              // 자산 추가 버튼 (맨 마지막)
              ElevatedButton.icon(
                onPressed: () => _showAddAssetDialog(context, provider, l10n),
                icon: Icon(Icons.add, color: AppColors.navyDark),
                label: Text(
                  l10n.addAsset,
                  style: TextStyle(color: AppColors.navyDark),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(height: 24), // 하단 여백
            ],
          ),
        ),
      ),
    );
  }

  double _calculatePriceInterval(List<FlSpot> spots) {
    if (spots.isEmpty) return 1000;
    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final range = maxY - minY;
    if (range <= 0) return 1000;

    // 적절한 간격 계산 (약 4-5개의 눈금)
    final interval = range / 4;

    // 반올림하여 깔끔한 숫자로 만들기
    final magnitude = (interval).toStringAsFixed(0).length - 1;
    final factor = math.pow(10, magnitude).toDouble();
    return (interval / factor).ceil() * factor;
  }

  Widget _buildAssetCard(
    BuildContext context,
    MyAsset asset,
    MyAssetsProvider provider,
    AppLocalizations l10n,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => AssetDetailScreen(asset: asset),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        child: LiquidGlass(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.18),
              width: 1.5,
            ),
          ),
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      asset.assetName,
                      style: TextStyle(
                        color: AppColors.gold,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () =>
                        _deleteAsset(context, asset.id, provider, l10n),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text(
                '${l10n.registeredDate}: ${DateFormat('yyyy-MM-dd').format(asset.registeredDate)}',
                style: TextStyle(color: AppColors.slate300, fontSize: 14),
              ),
              SizedBox(height: 8),
              Text(
                '${l10n.initialAmount}: ${NumberFormat('#,###').format(asset.initialAmount)}',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              SizedBox(height: 12),
              if (asset.currentValue != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${l10n.currentValue}: ${NumberFormat('#,###').format(asset.currentValue)}',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${l10n.returnRate}: ${((asset.currentValue! / asset.initialAmount - 1) * 100).toStringAsFixed(2)}%',
                      style: TextStyle(
                        color: asset.currentValue! >= asset.initialAmount
                            ? AppColors.success
                            : Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )
              else
                Text(
                  l10n.loadingPrice,
                  style: TextStyle(color: AppColors.slate400, fontSize: 14),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddAssetDialog(
    BuildContext context,
    MyAssetsProvider provider,
    AppLocalizations l10n,
  ) {
    // 자산 목록이 로드되지 않았으면 로드
    final appProvider = context.read<AppStateProvider>();
    if (appProvider.assets.isEmpty && !appProvider.isAssetsLoading) {
      appProvider.loadAssets();
    }

    showDialog(context: context, builder: (context) => AddAssetDialog());
  }

  void _deleteAsset(
    BuildContext context,
    String assetId,
    MyAssetsProvider provider,
    AppLocalizations l10n,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteAsset),
        content: Text(l10n.deleteAssetConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              provider.removeAsset(assetId);
              Navigator.pop(context);
            },
            child: Text(l10n.delete, style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
