import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/app_state_provider.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';
import '../widgets/asset_button.dart';
import 'investment_settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

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
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 30,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 60,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
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
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAssetButtons(
    AppStateProvider provider,
    String localeCode,
    AppLocalizations l10n,
  ) {
    final widgets = <Widget>[];
    String? currentType;

    for (final asset in provider.assets) {
      if (currentType != asset.type) {
        currentType = asset.type;
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                currentType == 'crypto' ? l10n.crypto : l10n.stock,
                style: AppTextStyles.chartSectionTitle,
              ),
            ),
          ),
        );
      }

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

    return Column(children: widgets);
  }
}
