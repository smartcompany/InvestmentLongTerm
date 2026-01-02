import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../l10n/app_localizations.dart';
import '../providers/my_assets_provider.dart';
import '../providers/app_state_provider.dart';
import '../providers/currency_provider.dart';
import '../models/my_asset.dart';
import '../utils/colors.dart';
import '../utils/currency_converter.dart';
import '../widgets/liquid_glass.dart';
import '../widgets/add_asset_dialog.dart';
import 'package:fl_chart/fl_chart.dart';
import 'asset_detail_screen.dart';
import 'settings_screen.dart';

class MyAssetsScreen extends StatefulWidget {
  const MyAssetsScreen({super.key});

  @override
  State<MyAssetsScreen> createState() => _MyAssetsScreenState();
}

class _MyAssetsScreenState extends State<MyAssetsScreen> {
  int _selectedYears = 1; // 기본값: 1년

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<MyAssetsProvider>();
      provider.loadAssets();
      // Provider에 초기 기간 설정
      provider.setSelectedChartYears(_selectedYears);
      // 초기 그래프 로드
      provider.loadPortfolioChart(years: _selectedYears);
    });
  }

  // 자산 타입에 따른 원본 통화 결정
  String _getAssetOriginalCurrency(
    String assetId,
    AppStateProvider appProvider,
  ) {
    try {
      final assetOption = appProvider.assets.firstWhere((a) => a.id == assetId);
      // 한국 주식은 원화, 나머지는 달러
      if (assetOption.type == 'korean_stock') {
        return '₩';
      } else {
        return '\$';
      }
    } catch (e) {
      return '\$'; // 기본값은 달러
    }
  }

  // 환율 변환된 총 현재 가치 계산
  double? _getConvertedTotalCurrentValue(
    MyAssetsProvider provider,
    AppStateProvider appProvider,
    String targetCurrency,
  ) {
    double total = 0.0;
    bool hasValue = false;

    for (final asset in provider.assets) {
      if (asset.currentValue == null) continue;

      final originalCurrency = _getAssetOriginalCurrency(
        asset.assetId,
        appProvider,
      );
      final convertedValue = CurrencyConverter.convertSync(
        asset.currentValue!,
        originalCurrency,
        targetCurrency,
      );
      total += convertedValue;
      hasValue = true;
    }

    return hasValue ? total : null;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MyAssetsProvider>();
    final appProvider = context.watch<AppStateProvider>();
    final currencyProvider = context.watch<CurrencyProvider>();
    final localeCode = Localizations.localeOf(context).languageCode;
    final currencySymbol = currencyProvider.getCurrencySymbol(localeCode);
    final l10n = AppLocalizations.of(context)!;

    // 환율 변환된 총 현재 가치
    final convertedTotalCurrentValue = _getConvertedTotalCurrentValue(
      provider,
      appProvider,
      currencySymbol,
    );

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
              // 타이틀과 설정 버튼
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(child: SizedBox()),
                  Text(
                    l10n.myAssets,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        icon: Icon(Icons.settings, color: Colors.white),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => SettingsScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
              // 포트폴리오 그래프 (자산이 있을 때만 표시)
              if (provider.assets.isNotEmpty) ...[
                // 기간 선택 버튼
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildPeriodButton('1Y', 1, provider),
                    SizedBox(width: 8),
                    _buildPeriodButton('3Y', 3, provider),
                    SizedBox(width: 8),
                    _buildPeriodButton('5Y', 5, provider),
                    SizedBox(width: 8),
                    _buildPeriodButton('10Y', 10, provider),
                  ],
                ),
                SizedBox(height: 16),
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
              ],
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
                          '${l10n.totalPurchaseAmount}: $currencySymbol${NumberFormat('#,##0.##').format(provider.totalPurchaseAmount)}',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        SizedBox(height: 12),
                        Text(
                          convertedTotalCurrentValue != null
                              ? '${l10n.currentValue}: $currencySymbol${NumberFormat('#,##0.##').format(convertedTotalCurrentValue)}'
                              : '${l10n.currentValue}: ${l10n.loadingPrice}',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        SizedBox(height: 12),
                        Text(
                          convertedTotalCurrentValue != null &&
                                  provider.totalPurchaseAmount > 0
                              ? '${l10n.totalReturnRate}: ${((convertedTotalCurrentValue / provider.totalPurchaseAmount - 1) * 100).toStringAsFixed(2)}%'
                              : '${l10n.totalReturnRate}: -',
                          style: TextStyle(
                            color:
                                convertedTotalCurrentValue != null &&
                                    provider.totalPurchaseAmount > 0 &&
                                    convertedTotalCurrentValue >=
                                        provider.totalPurchaseAmount
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

  Widget _buildPeriodButton(
    String label,
    int years,
    MyAssetsProvider provider,
  ) {
    final isSelected = _selectedYears == years;
    return GestureDetector(
      onTap: () async {
        setState(() {
          _selectedYears = years;
        });
        // Provider에도 선택된 기간 저장
        provider.setSelectedChartYears(years);
        await provider.loadPortfolioChart(years: years);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gold : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.gold : Colors.white.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.navyDark : Colors.white,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildAssetCard(
    BuildContext context,
    MyAsset asset,
    MyAssetsProvider provider,
    AppLocalizations l10n,
  ) {
    final currencyProvider = context.watch<CurrencyProvider>();
    final appProvider = context.watch<AppStateProvider>();
    final localeCode = Localizations.localeOf(context).languageCode;
    final currencySymbol = currencyProvider.getCurrencySymbol(localeCode);

    // 자산의 원본 통화 확인
    String originalCurrency = '\$'; // 기본값
    try {
      final assetOption = appProvider.assets.firstWhere(
        (a) => a.id == asset.assetId,
      );
      if (assetOption.type == 'korean_stock') {
        originalCurrency = '₩';
      }
    } catch (e) {
      // 기본값 사용
    }

    // 환율 변환된 현재 가치
    double? convertedCurrentValue;
    if (asset.currentValue != null) {
      convertedCurrentValue = CurrencyConverter.convertSync(
        asset.currentValue!,
        originalCurrency,
        currencySymbol,
      );
    }

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
                '${l10n.initialAmount}: $currencySymbol${NumberFormat('#,##0.##').format(asset.initialAmount)}',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              SizedBox(height: 12),
              if (convertedCurrentValue != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${l10n.currentValue}: $currencySymbol${NumberFormat('#,##0.##').format(convertedCurrentValue)}',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${l10n.returnRate}: ${((convertedCurrentValue / asset.initialAmount - 1) * 100).toStringAsFixed(2)}%',
                      style: TextStyle(
                        color: convertedCurrentValue >= asset.initialAmount
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

  Future<void> _showAddAssetDialog(
    BuildContext context,
    MyAssetsProvider provider,
    AppLocalizations l10n,
  ) async {
    // 자산 목록이 로드되지 않았으면 로드
    final appProvider = context.read<AppStateProvider>();
    if (appProvider.assets.isEmpty && !appProvider.isAssetsLoading) {
      appProvider.loadAssets();
    }

    await showDialog(context: context, builder: (context) => AddAssetDialog());
    // 다이얼로그가 닫힌 후 차트 다시 로드 (자산이 추가되었을 수 있으므로)
    if (mounted) {
      await provider.loadPortfolioChart(years: _selectedYears);
    }
  }

  void _deleteAsset(
    BuildContext context,
    String assetId,
    MyAssetsProvider provider,
    AppLocalizations l10n,
  ) async {
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
            onPressed: () async {
              await provider.removeAsset(assetId);
              Navigator.pop(context);
              // 차트 다시 로드
              await provider.loadPortfolioChart(years: _selectedYears);
            },
            child: Text(l10n.delete, style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
