import 'package:flutter/material.dart';
import 'dart:ui';
import 'home_screen.dart';
import 'retire_simulator.dart';
import 'my_assets_screen.dart';
import '../l10n/app_localizations.dart';
import '../utils/colors.dart';
import '../services/ad_service.dart';

class MainTabScreen extends StatefulWidget {
  final int? initialIndex;

  const MainTabScreen({super.key, this.initialIndex});

  @override
  State<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> {
  late int _currentIndex;
  bool _showMyAssetsButton = false;
  bool _isLoadingAd = false;
  bool _hasShownAdButtonThisSession = false; // 앱 실행 중에만 유지

  List<Widget> get _screens => [
    const HomeScreen(),
    RetireSimulatorScreen(isVisible: _currentIndex == 1),
    const MyAssetsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // 초기 탭 인덱스 설정
    _currentIndex = widget.initialIndex ?? 0;
  }

  void _handleMyAssetsTabTap() {
    // 앱 실행 중 한 번만 버튼 표시 (광고 없이)
    if (!_hasShownAdButtonThisSession) {
      setState(() {
        _currentIndex = 2; // 탭 인덱스 즉시 업데이트
        _showMyAssetsButton = true;
      });
    } else {
      // 이미 본 경우 바로 페이지로 이동
      setState(() {
        _currentIndex = 2;
        _showMyAssetsButton = false;
      });
    }
  }

  Future<void> _handleViewMyAssetsButton() async {
    // 버튼을 누르면 광고를 보고 페이지 진입
    setState(() {
      _isLoadingAd = true;
    });

    try {
      await AdService.shared.loadSettings();

      if (!mounted) return;

      await AdService.shared.showFullScreenAd(
        onAdDismissed: () {
          if (!mounted) return;
          setState(() {
            _isLoadingAd = false;
            _showMyAssetsButton = false;
            _hasShownAdButtonThisSession = true; // 앱 실행 중에만 유지
            _currentIndex = 2;
          });
        },
        onAdFailedToShow: () {
          if (!mounted) return;
          setState(() {
            _isLoadingAd = false;
            _showMyAssetsButton = false;
            _hasShownAdButtonThisSession = true; // 앱 실행 중에만 유지
            _currentIndex = 2;
          });
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingAd = false;
        _showMyAssetsButton = false;
        _hasShownAdButtonThisSession = true; // 앱 실행 중에만 유지
        _currentIndex = 2;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      extendBody: true, // 탭바 뒤로 내용이 스크롤되도록 설정
      body: Stack(
        children: [
          IndexedStack(index: _currentIndex, children: _screens),
          // 첫 진입 시 "내 자산 상태 보기" 버튼 오버레이
          if (_showMyAssetsButton)
            Container(
              color: Colors.black,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l10n.myAssets,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        l10n.myAssetsSubtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                    ),
                    SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _isLoadingAd
                          ? null
                          : _handleViewMyAssetsButton,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        padding: EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoadingAd
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.navyDark,
                                ),
                              ),
                            )
                          : Text(
                              l10n.viewMyAssetsStatus,
                              style: TextStyle(
                                color: AppColors.navyDark,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: Colors.transparent,
            child: SafeArea(
              top: false,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
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
                      icon: Icons.account_balance_wallet,
                      label: l10n.myAssets,
                      index: 2,
                    ),
                  ],
                ),
              ),
            ),
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
            if (index == 2) {
              // "지금 내 자산" 탭 클릭 시
              _handleMyAssetsTabTap();
            } else {
              setState(() {
                _currentIndex = index;
                _showMyAssetsButton = false;
              });
            }
          },
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isSelected ? AppColors.gold : AppColors.slate400,
                  size: 22,
                ),
                SizedBox(height: 2),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? AppColors.gold : AppColors.slate400,
                      fontSize: 10,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
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
