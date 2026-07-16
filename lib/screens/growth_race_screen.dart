import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/app_state_provider.dart';
import '../providers/growth_race_provider.dart';
import '../models/asset_option.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';
import '../widgets/app_ui.dart';
import '../widgets/asset_icon.dart';
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
  final Map<String, bool> _expandedTypes = {};

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

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.selectAssetToCompare,
                style: AppTextStyles.homeMainQuestion.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.selectUpToAssets,
                style: AppTextStyles.homeSubDescription,
              ),
              const SizedBox(height: 24),

              Text(l10n.duration, style: AppTextStyles.settingsSectionLabel),
              const SizedBox(height: 12),
              Row(
                children: [1, 3, 5, 7, 10].map((years) {
                  final isSelected = provider.selectedYears == years;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTap: () => provider.setSelectedYears(years),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.border,
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '${years}Y',
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textPrimary,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),

              if (appProvider.isAssetsLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else if (appProvider.assets.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      l10n.failedToLoadAssetList,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                )
              else
                _buildAssetSelectionList(appProvider.assets, provider),

              const SizedBox(height: 32),

              if (kDebugMode) ...[
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: provider.selectedAssetIds.isEmpty ||
                            provider.isLoading ||
                            _isLoadingAd ||
                            _isStartingDirect
                        ? null
                        : _startRaceDirect,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isStartingDirect
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            '바로 시작 (Debug)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              AppPrimaryButton(
                label: provider.selectedAssetIds.isEmpty
                    ? l10n.watchAdAndStart
                    : l10n.compareSelectedAssets(
                        provider.selectedAssetIds.length,
                      ),
                loading: provider.isLoading || _isLoadingAd || _isStartingDirect,
                onPressed: provider.selectedAssetIds.isEmpty ||
                        provider.isLoading ||
                        _isLoadingAd ||
                        _isStartingDirect
                    ? null
                    : _startRace,
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssetSelectionList(
    List<AssetOption> assets,
    GrowthRaceProvider provider,
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

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 10.0;
        // 균일 카드 그리드: 화면 폭 기준 4~5열
        final columns = (constraints.maxWidth / 78).floor().clamp(4, 5);
        final cardWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        final cardHeight = cardWidth * 1.35;
        final collapsedCount = columns; // 한 줄만 먼저 노출

        return Column(
          children: sortedTypes.map((type) {
            final typeAssets = assetsByType[type]!;
            final isExpanded = _expandedTypes[type] ?? false;
            final visible = isExpanded
                ? typeAssets
                : typeAssets.take(collapsedCount).toList();
            final l10n = AppLocalizations.of(context)!;

            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _getTypeName(type),
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (typeAssets.length > collapsedCount)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _expandedTypes[type] = !isExpanded;
                              });
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  isExpanded ? l10n.showLess : l10n.showMore,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Icon(
                                  isExpanded
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                  color: AppColors.textSecondary,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: visible.map((asset) {
                      final isSelected =
                          provider.selectedAssetIds.contains(asset.id);
                      return SizedBox(
                        width: cardWidth,
                        height: cardHeight,
                        child: _AssetGridCard(
                          asset: asset,
                          selected: isSelected,
                          onTap: () => provider.toggleAsset(asset.id),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  String _getTypeName(String type) {
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

class _AssetGridCard extends StatelessWidget {
  final AssetOption asset;
  final bool selected;
  final VoidCallback onTap;

  const _AssetGridCard({
    required this.asset,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
          decoration: BoxDecoration(
            color: selected ? AppColors.primarySoft : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: selected ? 0.06 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AssetIcon(
                      assetId: asset.id,
                      type: asset.type,
                      size: 22,
                    ),
                    const SizedBox(height: 4),
                    Flexible(
                      child: Text(
                        asset.displayName(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 11,
                          fontWeight:
                              selected ? FontWeight.w800 : FontWeight.w600,
                          height: 1.15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                const Positioned(
                  top: 0,
                  right: 0,
                  child: Icon(
                    Icons.check_circle,
                    color: AppColors.primary,
                    size: 16,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
