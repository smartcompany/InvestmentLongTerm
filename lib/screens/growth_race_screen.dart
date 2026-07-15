import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/app_state_provider.dart';
import '../providers/growth_race_provider.dart';
import '../models/asset_option.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';
import '../services/ad_service.dart';
import 'growth_race_chart_screen.dart';

class GrowthRaceScreen extends StatefulWidget {
  const GrowthRaceScreen({super.key});

  @override
  State<GrowthRaceScreen> createState() => _GrowthRaceScreenState();
}

class _GrowthRaceScreenState extends State<GrowthRaceScreen> {
  bool _isLoadingAd = false;
  bool _isStartingDirect = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appProvider = context.read<AppStateProvider>();
      if (appProvider.assets.isEmpty && !appProvider.isAssetsLoading) {
        appProvider.loadAssets();
      }
    });
  }

  Future<void> _launchRace() async {
    final provider = context.read<GrowthRaceProvider>();
    await provider.loadPriceData();
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const GrowthRaceChartScreen(),
        fullscreenDialog: true,
      ),
    );
  }

  Future<void> _startRaceDirect() async {
    if (_isStartingDirect || _isLoadingAd) return;
    setState(() => _isStartingDirect = true);
    try {
      await _launchRace();
    } finally {
      if (mounted) setState(() => _isStartingDirect = false);
    }
  }

  void _startRace() async {
    setState(() {
      _isLoadingAd = true;
    });

    try {
      await AdService.shared.showFullScreenAd(
        onAdDismissed: () async {
          if (!mounted) return;
          try {
            await _launchRace();
          } finally {
            if (mounted) {
              setState(() {
                _isLoadingAd = false;
              });
            }
          }
        },
        onAdFailedToShow: () async {
          // 광고 실패 시에도 그냥 시작
          if (!mounted) return;
          try {
            await _launchRace();
          } finally {
            if (mounted) {
              setState(() {
                _isLoadingAd = false;
              });
            }
          }
        },
      );
    } catch (e) {
      // 예외 발생 시에도 상태 리셋
      if (mounted) {
        setState(() {
          _isLoadingAd = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final appProvider = context.watch<AppStateProvider>();
    final provider = context.watch<GrowthRaceProvider>();
    final localeCode = Localizations.localeOf(context).languageCode;

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
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 타이틀
                Text(
                  l10n.growthRace,
                  style: AppTextStyles.homeMainQuestion.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '자산들의 성장률을 경주로 비교해보세요',
                  style: TextStyle(color: AppColors.slate400, fontSize: 14),
                ),
                SizedBox(height: 32),

                // 년도 선택
                Text('기간 선택', style: AppTextStyles.settingsSectionLabel),
                SizedBox(height: 12),
                Row(
                  children: [1, 3, 5, 7, 10].map((years) {
                    final isSelected = provider.selectedYears == years;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: GestureDetector(
                          onTap: () => provider.setSelectedYears(years),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.gold
                                  : Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                '${years}Y',
                                style: TextStyle(
                                  color: isSelected
                                      ? AppColors.navyDark
                                      : Colors.white,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 32),

                // 자산 선택
                Text(
                  '자산 선택 (${provider.selectedAssetIds.length}개 선택됨)',
                  style: AppTextStyles.settingsSectionLabel,
                ),
                SizedBox(height: 12),

                if (appProvider.isAssetsLoading)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(color: AppColors.gold),
                    ),
                  )
                else if (appProvider.assets.isEmpty)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        '자산을 불러올 수 없습니다',
                        style: TextStyle(color: AppColors.slate400),
                      ),
                    ),
                  )
                else
                  _buildAssetSelectionList(
                    appProvider.assets,
                    provider,
                    localeCode,
                  ),

                SizedBox(height: 32),

                // Debug: 광고 없이 바로 시작
                if (kDebugMode) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed:
                          provider.selectedAssetIds.isEmpty ||
                              provider.isLoading ||
                              _isLoadingAd ||
                              _isStartingDirect
                          ? null
                          : _startRaceDirect,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.gold,
                        side: BorderSide(color: AppColors.gold),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isStartingDirect
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: AppColors.gold,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              '바로 시작 (Debug)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(height: 12),
                ],

                // Start 버튼
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed:
                        provider.selectedAssetIds.isEmpty ||
                            provider.isLoading ||
                            _isLoadingAd ||
                            _isStartingDirect
                        ? null
                        : _startRace,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.navyDark,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: provider.isLoading || _isLoadingAd
                        ? CircularProgressIndicator(
                            color: AppColors.navyDark,
                            strokeWidth: 2,
                          )
                        : Text(
                            l10n.watchAdAndStart,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAssetSelectionList(
    List<AssetOption> assets,
    GrowthRaceProvider provider,
    String localeCode,
  ) {
    final assetsByType = <String, List<AssetOption>>{};
    for (final asset in assets) {
      assetsByType.putIfAbsent(asset.type, () => []).add(asset);
    }

    final typeOrder = {
      'crypto': 0,
      'stock': 1,
      'korean_stock': 2,
      'real_estate': 3,
      'commodity': 4,
      'cash': 5,
    };

    final sortedTypes = assetsByType.keys.toList()
      ..sort((a, b) => (typeOrder[a] ?? 999).compareTo(typeOrder[b] ?? 999));

    return Column(
      children: sortedTypes.map((type) {
        final typeAssets = assetsByType[type]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: 16, bottom: 8),
              child: Text(
                _getTypeName(type, localeCode),
                style: TextStyle(
                  color: AppColors.slate400,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: typeAssets.map((asset) {
                final isSelected = provider.selectedAssetIds.contains(asset.id);
                return GestureDetector(
                  onTap: () => provider.toggleAsset(asset.id),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.gold
                          : Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.gold
                            : Colors.white.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(asset.icon, style: TextStyle(fontSize: 18)),
                        SizedBox(width: 8),
                        Text(
                          asset.displayName(),
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.navyDark
                                : Colors.white,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      }).toList(),
    );
  }

  String _getTypeName(String type, String localeCode) {
    final l10n = AppLocalizations.of(context)!;
    switch (type) {
      case 'crypto':
        return l10n.crypto;
      case 'stock':
        return l10n.stock;
      case 'korean_stock':
        return l10n.koreanStock;
      case 'real_estate':
        return l10n.realEstate;
      case 'commodity':
        return l10n.commodity;
      case 'cash':
        return l10n.cash;
      default:
        return type;
    }
  }
}
