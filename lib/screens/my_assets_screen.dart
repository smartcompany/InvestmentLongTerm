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
import '../widgets/asset_price_chart.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<MyAssetsProvider>();
      final appProvider = context.read<AppStateProvider>();
      final currencySymbol = CurrencyProvider.shared.getCurrencySymbol();

      // Provider에 초기 기간 설정
      provider.setSelectedChartYears(_selectedYears);

      // 자산 데이터 로드 및 차트 로드 (통화 정보 포함)
      // loadAssets 내부에서 자산 로드 완료 후 자동으로 차트도 로드됨
      await provider.loadAssets(
        chartYears: _selectedYears,
        targetCurrency: currencySymbol,
        getAssetOriginalCurrency: (assetId) =>
            _getAssetOriginalCurrency(assetId, appProvider),
      );
    });
  }

  // 자산 타입에 따른 원본 통화 결정
  String _getAssetOriginalCurrency(
    String assetId,
    AppStateProvider appProvider,
  ) {
    try {
      final assetOption = appProvider.assets.firstWhere((a) => a.id == assetId);
      // 한국 주식과 부동산은 원화, 나머지는 달러
      if (assetOption.type == 'korean_stock' ||
          assetOption.type == 'real_estate') {
        return '₩';
      } else {
        return '\$';
      }
    } catch (e) {
      return '\$'; // 기본값은 달러
    }
  }

  // 환율 변환된 총 현재 가치 계산
  Future<double?> _getConvertedTotalCurrentValue(
    MyAssetsProvider provider,
    AppStateProvider appProvider,
    String targetCurrency,
  ) async {
    double total = 0.0;
    bool hasValue = false;

    for (final asset in provider.assets) {
      if (asset.currentValue == null) continue;

      final originalCurrency = _getAssetOriginalCurrency(
        asset.assetId,
        appProvider,
      );
      final convertedValue = await CurrencyConverter.shared.convert(
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
    final l10n = AppLocalizations.of(context)!;

    // 통화 변경 감지를 위해 ListenableBuilder 사용
    return ListenableBuilder(
      listenable: CurrencyProvider.shared,
      builder: (context, _) {
        final currencySymbol = CurrencyProvider.shared.getCurrencySymbol();

        // 환율 변환된 총 현재 가치 (FutureBuilder로 처리)
        final convertedTotalCurrentValueFuture = _getConvertedTotalCurrentValue(
          provider,
          appProvider,
          currencySymbol,
        );

    // 상태바 투명하게 설정
    SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle.light.copyWith(
            statusBarColor: Colors.transparent,
          ),
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
                    MediaQuery.of(context).padding.bottom +
                    80, // 탭바 높이 + SafeArea
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
                          ? AssetPriceChart(
                                  spots: provider.portfolioSpots!,
                              startDate: provider.portfolioStartDate,
                              endDate: provider.portfolioEndDate,
                              currencySymbol: currencySymbol,
                              height: 200,
                        )
                      : SizedBox.shrink(),
                ),
                  ],
              // 통계 카드 (자산이 있을 때만 표시)
              if (provider.assets.isNotEmpty)
                Container(
                  margin: EdgeInsets.only(bottom: 24),
                      child: FutureBuilder<double?>(
                        future: convertedTotalCurrentValueFuture,
                        builder: (context, snapshot) {
                          final convertedTotalCurrentValue = snapshot.data;
                          return LiquidGlass(
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
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                                SizedBox(height: 12),
                              Text(
                                  convertedTotalCurrentValue != null
                                      ? '${l10n.currentValue}: $currencySymbol${NumberFormat('#,##0.##').format(convertedTotalCurrentValue)}'
                                      : '${l10n.currentValue}: ${l10n.loadingPrice}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                                SizedBox(height: 12),
                              Text(
                                  convertedTotalCurrentValue != null &&
                                          provider.totalPurchaseAmount > 0
                                      ? '${l10n.totalReturnRate}: ${NumberFormat('#,##0.00').format((convertedTotalCurrentValue / provider.totalPurchaseAmount - 1) * 100)}%'
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
                          );
                        },
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
                    onPressed: () =>
                        _showAddAssetDialog(context, provider, l10n),
                icon: Icon(Icons.add, color: AppColors.navyDark),
                label: Text(
                  l10n.addAsset,
                  style: TextStyle(color: AppColors.navyDark),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
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
      },
    );
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

        // 통화 정보 가져오기
        final appProvider = context.read<AppStateProvider>();
        final currencySymbol = CurrencyProvider.shared.getCurrencySymbol();

        await provider.loadPortfolioChart(
          years: years,
          targetCurrency: currencySymbol,
          getAssetOriginalCurrency: (assetId) =>
              _getAssetOriginalCurrency(assetId, appProvider),
        );
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
    return ListenableBuilder(
      listenable: CurrencyProvider.shared,
      builder: (context, _) {
        final appProvider = context.watch<AppStateProvider>();
        final currencySymbol = CurrencyProvider.shared.getCurrencySymbol();

        // 자산의 원본 통화 확인
        String originalCurrency = '\$'; // 기본값
        try {
          final assetOption = appProvider.assets.firstWhere(
            (a) => a.id == asset.assetId,
          );
          if (assetOption.type == 'korean_stock' ||
              assetOption.type == 'real_estate') {
            originalCurrency = '₩';
          }
        } catch (e) {
          // 기본값 사용
        }

        // 환율 변환된 현재 가치 (FutureBuilder로 처리)
        return FutureBuilder<double?>(
          future: asset.currentValue != null
              ? CurrencyConverter.shared.convert(
                  asset.currentValue!,
                  originalCurrency,
                  currencySymbol,
                )
              : Future.value(null),
          builder: (context, snapshot) {
            final convertedCurrentValue = snapshot.data;

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
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                    ),
                    SizedBox(height: 4),
                    Text(
                              '${l10n.returnRate}: ${NumberFormat('#,##0.00').format((convertedCurrentValue / asset.initialAmount - 1) * 100)}%',
                      style: TextStyle(
                                color:
                                    convertedCurrentValue >= asset.initialAmount
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
                          style: TextStyle(
                            color: AppColors.slate400,
                            fontSize: 14,
                          ),
                ),
            ],
          ),
        ),
      ),
            );
          },
        );
      },
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
      final currencySymbol = CurrencyProvider.shared.getCurrencySymbol();

      await provider.loadPortfolioChart(
        years: _selectedYears,
        targetCurrency: currencySymbol,
        getAssetOriginalCurrency: (assetId) =>
            _getAssetOriginalCurrency(assetId, appProvider),
      );
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
              final appProvider = context.read<AppStateProvider>();
              final currencySymbol = CurrencyProvider.shared
                  .getCurrencySymbol();

              await provider.loadPortfolioChart(
                years: _selectedYears,
                targetCurrency: currencySymbol,
                getAssetOriginalCurrency: (assetId) =>
                    _getAssetOriginalCurrency(assetId, appProvider),
              );
            },
            child: Text(l10n.delete, style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
