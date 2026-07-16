import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'home_screen.dart';
import 'retire_simulator.dart';
import 'my_assets_screen.dart';
import 'growth_race_screen.dart';
import '../l10n/app_localizations.dart';
import '../utils/colors.dart';
import '../services/ad_service.dart';
import '../providers/my_assets_provider.dart';
import '../providers/currency_provider.dart';
import '../widgets/asset_icon.dart';

class MainTabScreen extends StatefulWidget {
  final int? initialIndex;

  /// true면 지금 내 자산 탭 진입 시 광고 게이트(자산 미리보기)를 표시합니다.
  final bool openMyAssetsGate;

  const MainTabScreen({
    super.key,
    this.initialIndex,
    this.openMyAssetsGate = false,
  });

  @override
  State<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> {
  late int _currentIndex;
  bool _showMyAssetsGate = false;
  bool _isLoadingAd = false;
  bool _hasUnlockedMyAssetsThisSession = false;

  List<Widget> get _screens => [
    const HomeScreen(),
    RetireSimulatorScreen(isVisible: _currentIndex == 1),
    const GrowthRaceScreen(),
    const MyAssetsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex ?? 0;
    if (widget.openMyAssetsGate && _currentIndex == 3) {
      _showMyAssetsGate = true;
    }
  }

  void _handleMyAssetsTabTap() {
    if (_hasUnlockedMyAssetsThisSession) {
      setState(() {
        _currentIndex = 3;
        _showMyAssetsGate = false;
      });
      return;
    }

    // 광고 전: 게이트 화면에서 시뮬레이션/등록 자산 미리보기
    setState(() {
      _currentIndex = 3;
      _showMyAssetsGate = true;
    });
  }

  Future<void> _handleViewMyAssetsButton() async {
    setState(() => _isLoadingAd = true);

    void unlock() {
      if (!mounted) return;
      setState(() {
        _isLoadingAd = false;
        _showMyAssetsGate = false;
        _hasUnlockedMyAssetsThisSession = true;
        _currentIndex = 3;
      });
    }

    try {
      await AdService.shared.showFullScreenAd(
        onAdDismissed: unlock,
        onAdFailedToShow: unlock,
      );
    } catch (_) {
      unlock();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          IndexedStack(index: _currentIndex, children: _screens),
          if (_showMyAssetsGate) _buildMyAssetsGate(l10n),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.96),
          border: Border(top: BorderSide(color: AppColors.border)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTabItem(
                  icon: Icons.history,
                  label: l10n.pastAssetSimulation,
                  index: 0,
                ),
                _buildTabItem(
                  icon: Icons.trending_up,
                  label: l10n.retirementSimulation,
                  index: 1,
                ),
                _buildTabItem(
                  icon: Icons.compare_arrows,
                  label: l10n.growthRace,
                  index: 2,
                ),
                _buildTabItem(
                  icon: Icons.account_balance_wallet,
                  label: l10n.myAssets,
                  index: 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 광고 보기 전 게이트: 시뮬레이션에서 넘긴 자산 목록을 보여줌
  Widget _buildMyAssetsGate(AppLocalizations l10n) {
    final myAssets = context.watch<MyAssetsProvider>();
    final currencySymbol = CurrencyProvider.shared.getCurrencySymbol();
    final currencyFormat = NumberFormat.currency(
      symbol: currencySymbol,
      decimalDigits: 0,
    );

    return Container(
      color: AppColors.bg,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.myAssets,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.myAssetsSubtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: myAssets.assets.isEmpty
                    ? Center(
                        child: Text(
                          l10n.noAssetsRegistered,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 15,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: myAssets.assets.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final asset = myAssets.assets[index];
                          final amount = asset.currentValue ?? asset.initialAmount;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                AssetIcon(assetId: asset.assetId, size: 26),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        asset.assetName,
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                        ),
                                      ),
                                      if (asset.assetId != 'cash')
                                        Text(
                                          '${l10n.quantity}: ${NumberFormat('#,##0.####').format(asset.quantity)}${l10n.retireQtyUnit}',
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 12,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Text(
                                  currencyFormat.format(amount),
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoadingAd ? null : _handleViewMyAssetsButton,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoadingAd
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          l10n.viewMyAssetsStatus,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          onTap: () {
            if (index == 3) {
              _handleMyAssetsTabTap();
            } else {
              setState(() {
                _currentIndex = index;
                _showMyAssetsGate = false;
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color:
                      isSelected ? AppColors.primary : AppColors.textSecondary,
                  size: 22,
                ),
                const SizedBox(height: 2),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
