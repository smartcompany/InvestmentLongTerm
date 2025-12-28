import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../l10n/app_localizations.dart';
import '../models/my_asset.dart';
import '../providers/my_assets_provider.dart';
import '../utils/colors.dart';
import '../widgets/liquid_glass.dart';

class AssetDetailScreen extends StatefulWidget {
  final MyAsset asset;

  const AssetDetailScreen({super.key, required this.asset});

  @override
  State<AssetDetailScreen> createState() => _AssetDetailScreenState();
}

class _AssetDetailScreenState extends State<AssetDetailScreen> {
  List<FlSpot>? _priceSpots;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPriceData();
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final asset = widget.asset;

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
                        l10n.registeredDate,
                        DateFormat('yyyy-MM-dd').format(asset.registeredDate),
                      ),
                      SizedBox(height: 8),
                      _buildInfoRow(
                        l10n.initialAmount,
                        NumberFormat('#,###').format(asset.initialAmount),
                      ),
                      SizedBox(height: 8),
                      if (asset.currentValue != null) ...[
                        _buildInfoRow(
                          l10n.currentValue,
                          NumberFormat('#,###').format(asset.currentValue!),
                        ),
                        SizedBox(height: 8),
                        _buildInfoRow(
                          l10n.returnRate,
                          '${((asset.currentValue! / asset.initialAmount - 1) * 100).toStringAsFixed(2)}%',
                          color: asset.currentValue! >= asset.initialAmount
                              ? AppColors.success
                              : Colors.red,
                        ),
                      ] else
                        _buildInfoRow(l10n.loadingPrice, '...'),
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
