import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'home_screen.dart';
import 'retire_simulator.dart';
import 'my_assets_screen.dart';
import 'growth_race_screen.dart';
import '../l10n/app_localizations.dart';
import '../utils/colors.dart';
import '../providers/growth_race_provider.dart';
import '../services/onboarding_service.dart';
import '../widgets/my_assets_tab_hint_overlay.dart';
import 'growth_race_chart_screen.dart';

class MainTabScreen extends StatefulWidget {
  final int? initialIndex;

  /// true면 지금 내 자산 탭으로 바로 진입합니다. (은퇴 시뮬 import 후 등)
  final bool openMyAssetsGate;

  /// true면 온보딩 직후 광고 없이 자산 대결 차트를 엽니다.
  final bool openOnboardingRace;

  const MainTabScreen({
    super.key,
    this.initialIndex,
    this.openMyAssetsGate = false,
    this.openOnboardingRace = false,
  });

  @override
  State<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> {
  static const _myAssetsTabIndex = 1;
  static const _retireTabIndex = 3;

  late int _currentIndex;
  bool _showMyAssetsHint = false;
  final GlobalKey _myAssetsTabKey = GlobalKey();

  List<Widget> get _screens => [
    const GrowthRaceScreen(),
    const MyAssetsScreen(),
    const HomeScreen(),
    RetireSimulatorScreen(isVisible: _currentIndex == _retireTabIndex),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex ?? 0;
    if (widget.openMyAssetsGate) {
      _currentIndex = _myAssetsTabIndex;
    }
    if (widget.openOnboardingRace) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openOnboardingRaceChart();
      });
    }
  }

  Future<void> _openOnboardingRaceChart() async {
    final provider = context.read<GrowthRaceProvider>();
    if (provider.priceData.isEmpty) return;

    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const GrowthRaceChartScreen(isOnboarding: true),
        fullscreenDialog: true,
      ),
    );

    if (!mounted) return;
    final shouldShowHint = await OnboardingService.shouldShowMyAssetsHint();
    if (shouldShowHint && mounted) {
      setState(() => _showMyAssetsHint = true);
    }
  }

  Future<void> _dismissMyAssetsHint() async {
    await OnboardingService.markMyAssetsHintShown();
    if (mounted) setState(() => _showMyAssetsHint = false);
  }

  void _handleMyAssetsTabTap() {
    if (_showMyAssetsHint) {
      _dismissMyAssetsHint();
    }
    setState(() => _currentIndex = _myAssetsTabIndex);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Stack(
      children: [
        Scaffold(
          extendBody: true,
          body: IndexedStack(index: _currentIndex, children: _screens),
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
                      icon: Icons.compare_arrows,
                      label: l10n.growthRace,
                      index: 0,
                    ),
                    _buildTabItem(
                      key: _myAssetsTabKey,
                      icon: Icons.account_balance_wallet,
                      label: l10n.myAssets,
                      index: _myAssetsTabIndex,
                    ),
                    _buildTabItem(
                      icon: Icons.history,
                      label: l10n.pastAssetSimulation,
                      index: 2,
                    ),
                    _buildTabItem(
                      icon: Icons.trending_up,
                      label: l10n.retirementSimulation,
                      index: _retireTabIndex,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_showMyAssetsHint)
          MyAssetsTabHintOverlay(
            targetKey: _myAssetsTabKey,
            message: l10n.onboardingMyAssetsHint,
            dismissLabel: l10n.confirm,
            onDismiss: _dismissMyAssetsHint,
            onTargetTap: _handleMyAssetsTabTap,
          ),
      ],
    );
  }

  Widget _buildTabItem({
    Key? key,
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
            if (index == _myAssetsTabIndex) {
              _handleMyAssetsTabTap();
            } else {
              if (_showMyAssetsHint) {
                _dismissMyAssetsHint();
              }
              setState(() => _currentIndex = index);
            }
          },
          child: Container(
            key: key,
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
