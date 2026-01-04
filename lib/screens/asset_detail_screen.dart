import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../l10n/app_localizations.dart';
import '../models/my_asset.dart';
import '../providers/my_assets_provider.dart';
import '../providers/app_state_provider.dart';
import '../providers/currency_provider.dart';
import '../utils/colors.dart';
import '../utils/currency_converter.dart';
import '../widgets/liquid_glass.dart';
import '../services/api_service.dart';

class AssetDetailScreen extends StatefulWidget {
  final MyAsset asset;

  const AssetDetailScreen({super.key, required this.asset});

  @override
  State<AssetDetailScreen> createState() => _AssetDetailScreenState();
}

class _AssetDetailScreenState extends State<AssetDetailScreen> {
  List<FlSpot>? _priceSpots;
  bool _isLoading = true;
  double? _currentPrice;

  @override
  void initState() {
    super.initState();
    _loadPriceData();
    _loadCurrentPrice();
  }

  Future<void> _loadPriceData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final provider = context.read<MyAssetsProvider>();
      final spots = await provider.getPriceHistory(widget.asset);
      setState(() {
        _priceSpots = spots;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCurrentPrice() async {
    try {
      final priceData = await ApiService.fetchDailyPrices(
        widget.asset.assetId,
        1,
      );
      if (priceData.isNotEmpty) {
        final latestPrice = (priceData.last['price'] as num?)?.toDouble();
        if (latestPrice != null && latestPrice.isFinite) {
          setState(() {
            _currentPrice = latestPrice;
          });
        }
      }
    } catch (e) {
      debugPrint('Failed to load current price: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final asset = widget.asset;
    final currencyProvider = context.watch<CurrencyProvider>();
    final appProvider = context.watch<AppStateProvider>();
    final localeCode = Localizations.localeOf(context).languageCode;
    final currencySymbol = currencyProvider.getCurrencySymbol(localeCode);

    // 자산 타입에 따른 현재가 통화 결정
    String currentPriceCurrency = '\$'; // 기본값은 달러
    try {
      final assetOption = appProvider.assets.firstWhere(
        (a) => a.id == asset.assetId,
      );
      // 한국 주식과 부동산은 원화, 나머지는 달러
      if (assetOption.type == 'korean_stock' ||
          assetOption.type == 'real_estate') {
        currentPriceCurrency = '₩';
      }
    } catch (e) {
      // 자산을 찾을 수 없으면 기본값(달러) 사용
      debugPrint('Asset not found: ${asset.assetId}');
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.navyDark, AppColors.navyMedium],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 헤더
              Padding(
                padding: EdgeInsets.all(24),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        asset.assetName,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(width: 48), // 뒤로가기 버튼과 균형 맞추기
                  ],
                ),
              ),
              // 자산 정보
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
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
                      _buildInfoRow(
                        l10n.initialAmount,
                        '$currencySymbol${NumberFormat('#,##0.##').format(asset.initialAmount)}',
                      ),
                      SizedBox(height: 8),
                      if (asset.currentValue != null) ...[
                        FutureBuilder<double>(
                          future: () async {
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

                            // 환율 변환된 현재 가치
                            return await CurrencyConverter.shared.convert(
                              asset.currentValue!,
                              originalCurrency,
                              currencySymbol,
                            );
                          }(),
                          builder: (context, snapshot) {
                            final value = snapshot.data;
                            return _buildInfoRow(
                              l10n.currentValue,
                              value != null
                                  ? '$currencySymbol${NumberFormat('#,##0.##').format(value)}'
                                  : l10n.loadingPrice,
                            );
                          },
                        ),
                        SizedBox(height: 8),
                        FutureBuilder<double>(
                          future: () async {
                            // 자산의 원본 통화 확인
                            String originalCurrency = '\$';
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
                            return await CurrencyConverter.shared.convert(
                              asset.currentValue!,
                              originalCurrency,
                              currencySymbol,
                            );
                          }(),
                          builder: (context, snapshot) {
                            final convertedValue = snapshot.data;
                            if (convertedValue == null) {
                              return _buildInfoRow(
                                l10n.returnRate,
                                l10n.loadingPrice,
                              );
                            }
                            final returnRate =
                                ((convertedValue / asset.initialAmount - 1) *
                                100);
                            return _buildInfoRow(
                              l10n.returnRate,
                              '${returnRate.toStringAsFixed(2)}%',
                              color: convertedValue >= asset.initialAmount
                                  ? AppColors.success
                                  : Colors.red,
                            );
                          },
                        ),
                      ] else
                        _buildInfoRow(l10n.loadingPrice, '...'),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),
              // 현재가 정보 카드
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
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
                      _currentPrice != null
                          ? FutureBuilder<double>(
                              future: CurrencyConverter.shared.convert(
                                _currentPrice!,
                                currentPriceCurrency,
                                currencySymbol,
                              ),
                              builder: (context, snapshot) {
                                final convertedPrice = snapshot.data;
                                return _buildInfoRow(
                                  l10n.currentPrice,
                                  convertedPrice != null
                                      ? '$currencySymbol${NumberFormat('#,##0.##').format(convertedPrice)}'
                                      : l10n.loadingPrice,
                                );
                              },
                            )
                          : _buildInfoRow(l10n.currentPrice, l10n.loadingPrice),
                      SizedBox(height: 8),
                      _buildInfoRow(
                        l10n.quantity,
                        NumberFormat('#,##0.##').format(asset.quantity),
                      ),
                      SizedBox(height: 8),
                      _buildInfoRow(
                        l10n.averagePurchasePrice,
                        asset.quantity > 0
                            ? '$currencySymbol${NumberFormat('#,##0.##').format(asset.initialAmount / asset.quantity)}'
                            : '-',
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),
              // 그래프
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: AppColors.gold,
                          ),
                        )
                      : _priceSpots != null && _priceSpots!.isNotEmpty
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
                              gridData: FlGridData(show: false),
                              titlesData: FlTitlesData(show: false),
                              borderData: FlBorderData(show: false),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: _priceSpots!,
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
                      : Center(
                          child: Text(
                            l10n.noPriceData,
                            style: TextStyle(color: AppColors.slate400),
                          ),
                        ),
                ),
              ),
              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: AppColors.slate300, fontSize: 14)),
        Text(
          value,
          style: TextStyle(
            color: color ?? Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
