import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/app_state_provider.dart';
import '../models/asset_option.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';
import '../widgets/asset_button.dart';
import '../widgets/common_share_ui.dart';
import '../widgets/tab_navigation.dart';
import 'investment_settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  // 각 자산 타입별 펼침 상태 관리
  final Map<String, bool> _expandedTypes = {};

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppStateProvider>().loadAssets();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigateToSettings(BuildContext context, String asset) {
    context.read<AppStateProvider>().updateConfig(asset: asset);
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            InvestmentSettingsScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: Offset(0, 0.1),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnimatedIcon(IconData icon, double delay) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Better sine wave
        double value = _controller.value + delay;
        if (value > 1.0) value -= 1.0;
        // Use sine for smooth oscillation
        double yOffset = -10 * (value < 0.5 ? value * 2 : (1 - value) * 2);

        return Transform.translate(
          offset: Offset(0, yOffset),
          child: Icon(icon, size: 40, color: AppColors.gold),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppStateProvider>();
    final localeCode = Localizations.localeOf(context).languageCode;
    final selectedAssetName = provider.assetNameForLocale(
      localeCode,
      assetId: provider.config.asset,
    );
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.navyDark, AppColors.navyMedium],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final padding = MediaQuery.of(context).padding;
            return SingleChildScrollView(
              padding: EdgeInsets.only(
                top: padding.top + 20,
                bottom: padding.bottom + 30,
                left: 24,
                right: 24,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 60,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 탭 버튼 (투자 시뮬레이션 / 은퇴 자산 시뮬레이션)
                    TabNavigation(isHomeScreen: true),
                    SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildAnimatedIcon(Icons.trending_up, 0.0),
                        SizedBox(width: 16),
                        _buildAnimatedIcon(Icons.calendar_today, 0.3),
                        SizedBox(width: 16),
                        _buildAnimatedIcon(Icons.bar_chart, 0.6),
                      ],
                    ),
                    SizedBox(height: 32),
                    Text(
                      l10n.homeQuestionPart1(provider.config.yearsAgo),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.homeMainQuestion.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      l10n.homeQuestionPart2(selectedAssetName),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.homeMainQuestion.copyWith(
                        color: AppColors.gold,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      l10n.homeDescription,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.homeSubDescription,
                    ),
                    SizedBox(height: 36),
                    if (provider.isAssetsLoading && provider.assets.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 40),
                          child: CircularProgressIndicator(
                            color: AppColors.gold,
                          ),
                        ),
                      )
                    else if (provider.assetsError != null &&
                        provider.assets.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            Text(
                              l10n.failedToLoadAssetList,
                              style: TextStyle(color: Colors.white),
                            ),
                            SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: () => provider.loadAssets(),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: AppColors.gold),
                              ),
                              child: Text(
                                l10n.retry,
                                style: TextStyle(color: AppColors.gold),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      _buildAssetButtons(provider, localeCode, l10n),
                    // 디버그 모드일 때 공유하기 테스트 버튼
                    if (kDebugMode) ...[
                      SizedBox(height: 40),
                      _buildDebugShareTestButton(context, l10n),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDebugShareTestButton(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.5), width: 2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.bug_report, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text(
                'DEBUG MODE',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                // 더미 공유 텍스트 생성
                final dummyShareText = '''
╔═══════════════════════════════════╗
║   📊 Time Capital 계산 결과      ║
╚═══════════════════════════════════╝

💎 만약 5년 전에 비트코인에 \$10,000를 투자했다면 지금 얼마일까?

┌───────────────────────────────────┐
│ 🏆 단일 투자
│
│   최종 가치: \$150,000
│   수익률: 📈 1,400.0%
│   수익: 💰 \$140,000
└───────────────────────────────────┘

💵 총 투자금액: \$10,000

✨ 장기 투자 매매 계산 결과

🔗 다운로드: https://coinpang.org/app
''';

                await CommonShareUI.showShareOptionsDialog(
                  context: context,
                  shareText: dummyShareText,
                );
              },
              icon: Icon(Icons.share, color: Colors.white),
              label: Text(
                '공유하기 테스트',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssetButtons(
    AppStateProvider provider,
    String localeCode,
    AppLocalizations l10n,
  ) {
    final widgets = <Widget>[];

    // 자산을 타입별로 그룹화
    final Map<String, List<AssetOption>> assetsByType = {};
    for (final asset in provider.assets) {
      assetsByType.putIfAbsent(asset.type, () => []).add(asset);
    }

    // 타입별로 정렬된 순서대로 처리
    final sortedTypes = assetsByType.keys.toList()
      ..sort((a, b) {
        // 타입 순서: crypto, stock, korean_stock, commodity, cash
        final order = {
          'crypto': 0,
          'stock': 1,
          'korean_stock': 2,
          'commodity': 3,
          'cash': 4,
        };
        return (order[a] ?? 99).compareTo(order[b] ?? 99);
      });

    for (final type in sortedTypes) {
      final assets = assetsByType[type]!;
      final isExpanded = _expandedTypes[type] ?? false;

      // 타입 제목 추가
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              type == 'crypto'
                  ? l10n.crypto
                  : type == 'cash'
                  ? l10n.cash
                  : type == 'commodity'
                  ? l10n.commodity
                  : type == 'korean_stock'
                  ? l10n.koreanStock
                  : l10n.stock,
              style: AppTextStyles.chartSectionTitle,
            ),
          ),
        ),
      );

      // 처음 2개만 항상 표시
      final visibleCount = isExpanded
          ? assets.length
          : (assets.length > 2 ? 2 : assets.length);

      for (int i = 0; i < visibleCount; i++) {
        final asset = assets[i];
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AssetButton(
              assetName: asset.displayName(localeCode),
              icon: asset.icon,
              isSelected: provider.config.asset == asset.id,
              onTap: () {
                provider.selectAsset(asset);
                _navigateToSettings(context, asset.id);
              },
            ),
          ),
        );
      }

      // 나머지가 있으면 펼치기/접기 버튼 추가
      if (assets.length > 2) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Center(
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _expandedTypes[type] = !isExpanded;
                  });
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isExpanded ? l10n.showLess : l10n.showMore,
                      style: TextStyle(
                        color: AppColors.gold,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: AppColors.gold,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    }

    return Column(children: widgets);
  }
}
