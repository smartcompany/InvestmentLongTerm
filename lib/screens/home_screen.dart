import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/app_state_provider.dart';
import '../models/asset_option.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';
import '../widgets/asset_button.dart';
import 'investment_settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Map<String, bool> _expandedTypes = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppStateProvider>().loadAssets();
    });
  }

  AssetOption? _highlightAsset(AppStateProvider provider) {
    if (provider.assets.isEmpty) return null;
    try {
      return provider.assets.firstWhere((a) => a.id == provider.config.asset);
    } catch (_) {
      final cryptos =
          provider.assets.where((a) => a.type == 'crypto').toList();
      if (cryptos.isEmpty) return provider.assets.first;
      return cryptos.firstWhere(
        (a) =>
            a.id.toLowerCase().contains('btc') ||
            a.id.toLowerCase().contains('bitcoin') ||
            a.displayName().contains('비트코인') ||
            a.displayName().toLowerCase().contains('bitcoin'),
        orElse: () => cryptos.first,
      );
    }
  }

  void _openSettings(BuildContext context, AssetOption asset) {
    final provider = context.read<AppStateProvider>();
    provider.selectAsset(asset);
    provider.updateConfig(asset: asset.id);
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const InvestmentSettingsScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.08),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppStateProvider>();
    final l10n = AppLocalizations.of(context)!;
    final highlight = _highlightAsset(provider);
    final highlightName = highlight?.displayName() ??
        provider.assetNameForLocale(assetId: provider.config.asset);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  style: AppTextStyles.homeMainQuestion,
                  children: [
                    TextSpan(
                      text: l10n.homeQuestionPart1(provider.config.yearsAgo),
                    ),
                    const TextSpan(text: '\n'),
                    TextSpan(
                      text: highlightName,
                      style: const TextStyle(color: AppColors.primary),
                    ),
                    TextSpan(
                      text: _homeQuestionSuffix(l10n, highlightName),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.homeDescription,
                style: AppTextStyles.homeSubDescription.copyWith(
                  color: AppColors.textPrimary.withValues(alpha: 0.78),
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              if (provider.isAssetsLoading && provider.assets.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else if (provider.assetsError != null && provider.assets.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Column(
                    children: [
                      Text(
                        l10n.failedToLoadAssetList,
                        style: const TextStyle(color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => provider.loadAssets(),
                        child: Text(l10n.retry),
                      ),
                    ],
                  ),
                )
              else
                ..._buildAssetSections(provider, l10n),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildAssetSections(
    AppStateProvider provider,
    AppLocalizations l10n,
  ) {
    final widgets = <Widget>[];
    final assetsByType = <String, List<AssetOption>>{};
    for (final asset in provider.assets) {
      assetsByType.putIfAbsent(asset.type, () => []).add(asset);
    }

    final order = {
      'crypto': 0,
      'stock': 1,
      'korean_stock': 2,
      'real_estate': 3,
      'commodity': 4,
      'cash': 5,
    };
    final sortedTypes = assetsByType.keys.toList()
      ..sort((a, b) => (order[a] ?? 99).compareTo(order[b] ?? 99));

    for (final type in sortedTypes) {
      final assets = assetsByType[type]!;
      final isExpanded = _expandedTypes[type] ?? false;

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 10),
          child: Text(
            _typeLabel(type, l10n),
            style: AppTextStyles.chartSectionTitle,
          ),
        ),
      );

      final visibleCount = isExpanded
          ? assets.length
          : (assets.length > 2 ? 2 : assets.length);

      for (var i = 0; i < visibleCount; i++) {
        final asset = assets[i];
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AssetButton(
              assetName: asset.displayName(),
              assetId: asset.id,
              type: asset.type,
              isSelected: provider.config.asset == asset.id,
              onTap: () => _openSettings(context, asset),
            ),
          ),
        );
      }

      if (assets.length > 2) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  setState(() => _expandedTypes[type] = !isExpanded);
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isExpanded ? l10n.showLess : l10n.showMore,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: AppColors.primary,
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

    return widgets;
  }

  String _typeLabel(String type, AppLocalizations l10n) {
    switch (type) {
      case 'crypto':
        return l10n.crypto;
      case 'cash':
        return l10n.cash;
      case 'commodity':
        return l10n.commodity;
      case 'korean_stock':
        return l10n.koreanStock;
      case 'real_estate':
        return l10n.realEstate;
      default:
        return l10n.stock;
    }
  }

  String _homeQuestionSuffix(AppLocalizations l10n, String assetName) {
    final full = l10n.homeQuestionPart2(assetName);
    if (full.contains(assetName)) {
      return full.replaceFirst(assetName, '');
    }
    return full;
  }
}
