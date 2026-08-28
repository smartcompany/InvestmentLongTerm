import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../providers/my_assets_provider.dart';
import '../providers/app_state_provider.dart';
import '../providers/currency_provider.dart';
import '../models/my_asset.dart';
import '../utils/colors.dart';
import '../utils/currency_converter.dart';
import '../utils/asset_currency.dart';
import '../utils/text_styles.dart';
import '../widgets/liquid_glass.dart';
import '../widgets/add_asset_dialog.dart';
import '../widgets/app_ui.dart';
import '../widgets/asset_icon.dart';
import '../widgets/asset_price_chart.dart';
import '../widgets/investment_insight_dialog.dart';
import '../widgets/market_briefing_dialog.dart';
import '../services/ad_service.dart';
import '../services/ai_history_service.dart';
import '../services/api_service.dart';
import '../services/notification_navigation.dart';
import '../providers/retire_simulator_provider.dart';
import 'ai_history_screen.dart';
import 'asset_detail_screen.dart';
import 'settings_screen.dart';
import 'retire_simulator.dart';

class MyAssetsScreen extends StatefulWidget {
  const MyAssetsScreen({super.key});

  @override
  State<MyAssetsScreen> createState() => _MyAssetsScreenState();
}

class _MyAssetsScreenState extends State<MyAssetsScreen> {
  int _selectedYears = 1; // 기본값: 1년
  bool _isLoadingAi = false;
  String? _aiLoadingMessage;

  @override
  void initState() {
    super.initState();
    NotificationNavigation.pendingAiAction.addListener(_onPendingAiAction);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<MyAssetsProvider>();
      final appProvider = context.read<AppStateProvider>();
      final currencySymbol = CurrencyProvider.shared.getCurrencySymbol();

      provider.setSelectedChartYears(_selectedYears);

      // 은퇴 시뮬에서 방금 import한 목록이 있으면 디스크 재로드로 덮어쓰지 않음
      if (provider.assets.isEmpty) {
        await provider.loadAssets(
          chartYears: _selectedYears,
          targetCurrency: currencySymbol,
          getAssetOriginalCurrency: (assetId) =>
              _getAssetOriginalCurrency(
                assetId,
                appProvider,
                assetType: _resolveAssetType(provider, assetId),
              ),
        );
      } else {
        await provider.loadPortfolioChart(
          years: _selectedYears,
          targetCurrency: currencySymbol,
          getAssetOriginalCurrency: (assetId) =>
              _getAssetOriginalCurrency(
                assetId,
                appProvider,
                assetType: _resolveAssetType(provider, assetId),
              ),
        );
      }

      if (mounted) {
        _consumePendingAiAction();
      }
    });
  }

  @override
  void dispose() {
    NotificationNavigation.pendingAiAction.removeListener(_onPendingAiAction);
    super.dispose();
  }

  void _onPendingAiAction() {
    if (!mounted) return;
    _consumePendingAiAction();
  }

  void _consumePendingAiAction() {
    final action = NotificationNavigation.pendingAiAction.value;
    if (action == null) return;
    NotificationNavigation.pendingAiAction.value = null;

    final provider = context.read<MyAssetsProvider>();
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (action == NotificationNavigation.aiActionMarketBriefing) {
        _handleMarketBriefingTap(context, provider, l10n);
      } else if (action == NotificationNavigation.aiActionPortfolioInsight) {
        _handleAiInsightTap(context, provider, l10n);
      }
    });
  }

  // 자산 타입에 따른 원본 통화 결정
  String _getAssetOriginalCurrency(
    String assetId,
    AppStateProvider appProvider, {
    String? assetType,
  }) {
    return AssetCurrency.originalCurrency(
      assetId,
      appProvider,
      assetType: assetType,
    );
  }

  String _resolveAssetType(MyAssetsProvider provider, String assetId) {
    try {
      return provider.assets.firstWhere((a) => a.assetId == assetId).assetType ??
          '';
    } catch (_) {
      return '';
    }
  }

  // 환율 변환된 총 현재 가치 계산
  Future<double?> _getConvertedTotalCurrentValue(
    MyAssetsProvider provider,
    AppStateProvider appProvider,
    String targetCurrency,
  ) async {
    double total = 0.0;
    bool hasValue = false;

    for (final asset in provider.assets) {
      if (asset.currentValue == null) continue;

      final originalCurrency = _getAssetOriginalCurrency(
        asset.assetId,
        appProvider,
        assetType: asset.assetType,
      );
      final convertedValue = await CurrencyConverter.shared.convert(
        asset.currentValue!,
        originalCurrency,
        targetCurrency,
      );
      total += convertedValue;
      hasValue = true;
    }

    return hasValue ? total : null;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MyAssetsProvider>();
    final appProvider = context.watch<AppStateProvider>();
    final l10n = AppLocalizations.of(context)!;

    // 통화 변경 감지를 위해 ListenableBuilder 사용
    return ListenableBuilder(
      listenable: CurrencyProvider.shared,
      builder: (context, _) {
        final currencySymbol = CurrencyProvider.shared.getCurrencySymbol();

        // 환율 변환된 총 현재 가치 (FutureBuilder로 처리)
        final convertedTotalCurrentValueFuture = _getConvertedTotalCurrentValue(
          provider,
          appProvider,
          currencySymbol,
        );

    // 상태바 투명하게 설정
    SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle.dark.copyWith(
            statusBarColor: Colors.transparent,
          ),
    );

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          SingleChildScrollView(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 16,
            bottom:
                    MediaQuery.of(context).padding.bottom +
                    80, // 탭바 높이 + SafeArea
            left: 14,
            right: 14,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context, l10n, provider.assets.isEmpty),
              if (provider.assets.isNotEmpty) ...[
                const SizedBox(height: 20),
                _buildPortfolioChartSection(provider, currencySymbol),
              ],
              // 통계 카드 (자산이 있을 때만 표시)
              if (provider.assets.isNotEmpty)
                Container(
                  margin: EdgeInsets.only(bottom: 24),
                      child: FutureBuilder<double?>(
                        future: convertedTotalCurrentValueFuture,
                        builder: (context, snapshot) {
                          final convertedTotalCurrentValue = snapshot.data;
                          return LiquidGlass(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.border,
                        width: 1.5,
                      ),
                    ),
                    padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  '${l10n.totalPurchaseAmount}: $currencySymbol${NumberFormat('#,##0.##').format(provider.totalPurchaseAmount)}',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                ),
                              ),
                                SizedBox(height: 12),
                              Text(
                                  convertedTotalCurrentValue != null
                                      ? '${l10n.currentValue}: $currencySymbol${NumberFormat('#,##0.##').format(convertedTotalCurrentValue)}'
                                      : '${l10n.currentValue}: ${l10n.loadingPrice}',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                ),
                              ),
                                SizedBox(height: 12),
                              Text(
                                  convertedTotalCurrentValue != null &&
                                          provider.totalPurchaseAmount > 0
                                      ? '${l10n.totalReturnRate}: ${NumberFormat('#,##0.00').format((convertedTotalCurrentValue / provider.totalPurchaseAmount - 1) * 100)}%'
                                      : '${l10n.totalReturnRate}: -',
                                style: TextStyle(
                                    color:
                                        convertedTotalCurrentValue != null &&
                                            provider.totalPurchaseAmount > 0 &&
                                            convertedTotalCurrentValue >=
                                                provider.totalPurchaseAmount
                                      ? AppColors.success
                                      : Colors.red,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          );
                        },
                  ),
                ),
              // 자산 카드 목록
              ...provider.assets.map((asset) {
                return _buildAssetCard(context, asset, provider, l10n);
              }).toList(),
              // 자산이 없을 때 빈 상태 메시지
              if (provider.assets.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Column(
                    children: [
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 64,
                        color: AppColors.textSecondary.withValues(alpha: 0.7),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.noAssetsRegistered,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.addAssetToTrack,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.homeSubDescription,
                      ),
                      const SizedBox(height: 28),
                      AppPrimaryButton(
                        label: l10n.addAsset,
                        onPressed: () =>
                            _showAddAssetDialog(context, provider, l10n),
                      ),
                    ],
                  ),
                ),
              if (provider.assets.isNotEmpty) ...[
                const SizedBox(height: 8),
                // 자산 관리
                _buildAddAssetButton(context, provider, l10n),
                const SizedBox(height: 14),
                // AI 분석 (같은 그룹·톤)
                _buildAiActionsGroup(context, provider, l10n),
                const SizedBox(height: 14),
                // 장기 계획
                _buildRetireSimButton(context, provider, l10n),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
          if (_isLoadingAi)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.35),
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Flexible(
                          child: Text(
                            _aiLoadingMessage ?? l10n.aiInsightLoading,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
      },
    );
  }

  /// null: 취소, non-null: 진행 (요청 문자열, 빈 문자열 허용)
  Future<String?> _askWatchAdWithRequest(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    return showDialog<String>(
      context: context,
      builder: (context) => _WatchAdWithRequestDialog(l10n: l10n),
    );
  }

  Future<void> _runAfterOptionalAd({
    required bool watchAd,
    required Future<void> Function() proceed,
  }) async {
    if (!watchAd) {
      await proceed();
      return;
    }

    try {
      await AdService.shared.showFullScreenAd(
        onAdDismissed: () {
          proceed();
        },
        onAdFailedToShow: () {
          proceed();
        },
      );
    } catch (_) {
      await proceed();
    }
  }

  Future<void> _handleAiInsightTap(
    BuildContext context,
    MyAssetsProvider provider,
    AppLocalizations l10n,
  ) async {
    if (provider.assets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.aiInsightNeedAssets)),
      );
      return;
    }

    final userRequest = await _askWatchAdWithRequest(context, l10n);
    if (userRequest == null || !mounted) return;

    setState(() {
      _isLoadingAi = true;
      _aiLoadingMessage = l10n.aiInsightLoading;
    });
    await _runAfterOptionalAd(
      watchAd: true,
      proceed: () async {
        if (!mounted) return;
        await _fetchAndShowInsight(
          context,
          provider,
          l10n,
          userRequest: userRequest,
        );
      },
    );
  }

  Future<void> _fetchAndShowInsight(
    BuildContext context,
    MyAssetsProvider provider,
    AppLocalizations l10n, {
    String? userRequest,
  }) async {
    if (!mounted) return;

    try {
      final appProvider = context.read<AppStateProvider>();
      final currencySymbol = CurrencyProvider.shared.getCurrencySymbol();
      final localeCode = Localizations.localeOf(context).languageCode;
      final locale = switch (localeCode) {
        'ko' || 'ja' || 'zh' => localeCode,
        _ => 'en',
      };

      final totalCurrent = await _getConvertedTotalCurrentValue(
        provider,
        appProvider,
        currencySymbol,
      );
      final totalPurchase = provider.totalPurchaseAmount;
      final totalReturn = totalCurrent != null && totalPurchase > 0
          ? (totalCurrent / totalPurchase - 1) * 100
          : null;

      final holdings = <Map<String, dynamic>>[];
      for (final asset in provider.assets) {
        final originalCurrency = _getAssetOriginalCurrency(
          asset.assetId,
          appProvider,
          assetType: asset.assetType,
        );
        double? currentInDisplay;
        if (asset.currentValue != null) {
          currentInDisplay = await CurrencyConverter.shared.convert(
            asset.currentValue!,
            originalCurrency,
            currencySymbol,
          );
        }
        final returnRate = currentInDisplay != null && asset.initialAmount > 0
            ? (currentInDisplay / asset.initialAmount - 1) * 100
            : null;

        final resolvedType = asset.assetType ??
            () {
              try {
                return appProvider.assets
                    .firstWhere((a) => a.id == asset.assetId)
                    .type;
              } catch (_) {
                return null;
              }
            }();

        holdings.add({
          'name': asset.assetName,
          'assetId': asset.assetId,
          if (resolvedType != null) 'type': resolvedType,
          'quantity': asset.quantity,
          'initialAmount': asset.initialAmount,
          if (currentInDisplay != null) 'currentValue': currentInDisplay,
          if (returnRate != null) 'returnRatePct': returnRate,
        });
      }

      debugPrint(
        '[AI Insight] request locale=$locale currency=$currencySymbol '
        'holdings=${holdings.length} purchase=$totalPurchase '
        'current=$totalCurrent return=$totalReturn',
      );
      debugPrint('[AI Insight] holdings payload: $holdings');

      final insight = await ApiService.fetchInvestmentInsight(
        locale: locale,
        displayCurrency: currencySymbol,
        assets: holdings,
        totalPurchaseAmount: totalPurchase,
        totalCurrentValue: totalCurrent,
        totalReturnRatePct: totalReturn,
        userRequest: userRequest,
      );

      debugPrint(
        '[AI Insight] success summaryLen=${insight.summary.length} '
        'outlookLen=${insight.outlook.length} '
        'suggestions=${insight.suggestions.length} '
        'risks=${insight.risks.length}',
      );
      debugPrint('[AI Insight] summary: ${insight.summary}');
      debugPrint('[AI Insight] outlook: ${insight.outlook}');

      if (!mounted) return;
      await AiHistoryService.shared.saveInsight(insight);
      setState(() {
        _isLoadingAi = false;
        _aiLoadingMessage = null;
      });
      await showInvestmentInsightDialog(context, insight: insight);
    } catch (e, st) {
      debugPrint('[AI Insight] failed: $e');
      debugPrint('[AI Insight] stack: $st');
      if (!mounted) return;
      setState(() {
        _isLoadingAi = false;
        _aiLoadingMessage = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            kDebugMode ? '${l10n.aiInsightFailed}\n$e' : l10n.aiInsightFailed,
          ),
          duration: kDebugMode ? const Duration(seconds: 8) : const Duration(seconds: 4),
        ),
      );
    }
  }

  Widget _buildAiActionsGroup(
    BuildContext context,
    MyAssetsProvider provider,
    AppLocalizations l10n,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        children: [
          _buildMarketBriefingButton(context, provider, l10n),
          const SizedBox(height: 8),
          _buildAiInsightButton(context, provider, l10n),
        ],
      ),
    );
  }

  Widget _buildAiInsightButton(
    BuildContext context,
    MyAssetsProvider provider,
    AppLocalizations l10n,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _isLoadingAi
            ? null
            : () => _handleAiInsightTap(context, provider, l10n),
        icon: const Icon(Icons.auto_awesome, size: 20),
        label: Text(
          l10n.aiInsightButton,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Future<void> _handleMarketBriefingTap(
    BuildContext context,
    MyAssetsProvider provider,
    AppLocalizations l10n,
  ) async {
    if (provider.assets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.aiInsightNeedAssets)),
      );
      return;
    }

    final userRequest = await _askWatchAdWithRequest(context, l10n);
    if (userRequest == null || !mounted) return;

    setState(() {
      _isLoadingAi = true;
      _aiLoadingMessage = l10n.marketBriefingLoading;
    });
    await _runAfterOptionalAd(
      watchAd: true,
      proceed: () async {
        if (!mounted) return;
        await _fetchAndShowMarketBriefing(
          context,
          provider,
          l10n,
          userRequest: userRequest,
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _buildHoldingsPayload(
    MyAssetsProvider provider,
    AppStateProvider appProvider,
    String currencySymbol,
  ) async {
    final holdings = <Map<String, dynamic>>[];
    for (final asset in provider.assets) {
      final originalCurrency = _getAssetOriginalCurrency(
        asset.assetId,
        appProvider,
        assetType: asset.assetType,
      );
      double? currentInDisplay;
      if (asset.currentValue != null) {
        currentInDisplay = await CurrencyConverter.shared.convert(
          asset.currentValue!,
          originalCurrency,
          currencySymbol,
        );
      }
      final returnRate = currentInDisplay != null && asset.initialAmount > 0
          ? (currentInDisplay / asset.initialAmount - 1) * 100
          : null;

      final resolvedType = asset.assetType ??
          () {
            try {
              return appProvider.assets
                  .firstWhere((a) => a.id == asset.assetId)
                  .type;
            } catch (_) {
              return null;
            }
          }();

      holdings.add({
        'name': asset.assetName,
        'assetId': asset.assetId,
        if (resolvedType != null) 'type': resolvedType,
        'quantity': asset.quantity,
        'initialAmount': asset.initialAmount,
        if (currentInDisplay != null) 'currentValue': currentInDisplay,
        if (returnRate != null) 'returnRatePct': returnRate,
      });
    }
    return holdings;
  }

  Future<void> _fetchAndShowMarketBriefing(
    BuildContext context,
    MyAssetsProvider provider,
    AppLocalizations l10n, {
    String? userRequest,
  }) async {
    if (!mounted) return;

    try {
      final appProvider = context.read<AppStateProvider>();
      final currencySymbol = CurrencyProvider.shared.getCurrencySymbol();
      final localeCode = Localizations.localeOf(context).languageCode;
      final locale = switch (localeCode) {
        'ko' || 'ja' || 'zh' => localeCode,
        _ => 'en',
      };
      final now = DateTime.now();
      final asOfDate =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final holdings = await _buildHoldingsPayload(
        provider,
        appProvider,
        currencySymbol,
      );

      debugPrint(
        '[Market Briefing] request locale=$locale date=$asOfDate '
        'holdings=${holdings.length}',
      );

      final briefing = await ApiService.fetchMarketBriefing(
        locale: locale,
        displayCurrency: currencySymbol,
        assets: holdings,
        asOfDate: asOfDate,
        userRequest: userRequest,
      );

      debugPrint(
        '[Market Briefing] success headline=${briefing.todayHeadline} '
        'conditions=${briefing.assetConditions.length}',
      );

      if (!mounted) return;
      await AiHistoryService.shared.saveBriefing(briefing);
      setState(() {
        _isLoadingAi = false;
        _aiLoadingMessage = null;
      });
      await showMarketBriefingDialog(context, briefing: briefing);
    } catch (e, st) {
      debugPrint('[Market Briefing] failed: $e');
      debugPrint('[Market Briefing] stack: $st');
      if (!mounted) return;
      setState(() {
        _isLoadingAi = false;
        _aiLoadingMessage = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            kDebugMode
                ? '${l10n.marketBriefingFailed}\n$e'
                : l10n.marketBriefingFailed,
          ),
          duration:
              kDebugMode ? const Duration(seconds: 8) : const Duration(seconds: 4),
        ),
      );
    }
  }

  Widget _buildMarketBriefingButton(
    BuildContext context,
    MyAssetsProvider provider,
    AppLocalizations l10n,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _isLoadingAi
            ? null
            : () => _handleMarketBriefingTap(context, provider, l10n),
        icon: const Icon(Icons.newspaper_outlined, size: 20),
        label: Text(
          l10n.marketBriefingButton,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // ─── 은퇴 시뮬레이션 ───────────────────────────────────────────

  Widget _buildRetireSimButton(
    BuildContext context,
    MyAssetsProvider provider,
    AppLocalizations l10n,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton.icon(
        onPressed: () => _handleRetireSimTap(context, provider, l10n),
        icon: const Icon(Icons.beach_access_outlined, size: 20),
        label: Text(
          l10n.retireSimButton,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          backgroundColor: AppColors.surface,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Future<void> _handleRetireSimTap(
    BuildContext context,
    MyAssetsProvider provider,
    AppLocalizations l10n,
  ) async {
    if (provider.assets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.retireSimNeedAssets)),
      );
      return;
    }

    final retireProvider = context.read<RetireSimulatorProvider>();
    final appProvider = context.read<AppStateProvider>();
    await retireProvider.importFromMyAssets(
      provider.assets,
      appProvider: appProvider,
    );

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const RetireSimulatorScreen(fromMyAssets: true),
      ),
    );

    if (!mounted) return;
    await retireProvider.endMyAssetsSession(
      CurrencyProvider.shared.getCurrencySymbol(),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AppLocalizations l10n,
    bool showSubtitle,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.myAssets,
                style: AppTextStyles.homeMainQuestion.copyWith(fontSize: 26),
              ),
              if (showSubtitle) ...[
                const SizedBox(height: 4),
                Text(
                  l10n.addAssetToTrack,
                  style: AppTextStyles.homeSubDescription.copyWith(fontSize: 14),
                ),
              ],
            ],
          ),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.history_outlined, color: AppColors.textSecondary),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const AiHistoryScreen()),
            );
          },
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.settings_outlined, color: AppColors.textSecondary),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => SettingsScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPortfolioChartSection(
    MyAssetsProvider provider,
    String currencySymbol,
  ) {
    const yearOptions = [1, 3, 5, 10];
    final selectedYears = yearOptions.contains(_selectedYears)
        ? _selectedYears
        : 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: yearOptions.map((years) {
            final selected = years == selectedYears;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: years == yearOptions.last ? 0 : 6,
                ),
                child: Material(
                  color: selected ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: () => _onChartPeriodSelected(provider, years),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color:
                              selected ? AppColors.primary : AppColors.border,
                        ),
                      ),
                      child: Text(
                        '${years}Y',
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: provider.isLoadingPortfolio
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : provider.portfolioSpots != null &&
                      provider.portfolioSpots!.isNotEmpty
                  ? AssetPriceChart(
                      spots: provider.portfolioSpots!,
                      startDate: provider.portfolioStartDate,
                      endDate: provider.portfolioEndDate,
                      currencySymbol: currencySymbol,
                      height: 200,
                    )
                  : const SizedBox.shrink(),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Future<void> _onChartPeriodSelected(
    MyAssetsProvider provider,
    int years,
  ) async {
    if (years == _selectedYears) return;
    setState(() => _selectedYears = years);
    provider.setSelectedChartYears(years);

    final appProvider = context.read<AppStateProvider>();
    final currencySymbol = CurrencyProvider.shared.getCurrencySymbol();

    await provider.loadPortfolioChart(
      years: years,
      targetCurrency: currencySymbol,
      getAssetOriginalCurrency: (assetId) => _getAssetOriginalCurrency(
        assetId,
        appProvider,
        assetType: _resolveAssetType(provider, assetId),
      ),
    );
  }

  Widget _buildAddAssetButton(
    BuildContext context,
    MyAssetsProvider provider,
    AppLocalizations l10n,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton.icon(
        onPressed: () => _showAddAssetDialog(context, provider, l10n),
        icon: const Icon(Icons.add, size: 20),
        label: Text(l10n.addAsset),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          backgroundColor: AppColors.surface,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  void _openAssetDetail(BuildContext context, MyAsset asset) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AssetDetailScreen(asset: asset),
      ),
    );
  }

  Widget _buildAssetMetricRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor ?? AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssetCard(
    BuildContext context,
    MyAsset asset,
    MyAssetsProvider provider,
    AppLocalizations l10n,
  ) {
    return ListenableBuilder(
      listenable: CurrencyProvider.shared,
      builder: (context, _) {
        final appProvider = context.watch<AppStateProvider>();
        final currencySymbol = CurrencyProvider.shared.getCurrencySymbol();
        final originalCurrency = _getAssetOriginalCurrency(
          asset.assetId,
          appProvider,
          assetType: asset.assetType,
        );

        // 환율 변환된 현재 가치 (FutureBuilder로 처리)
        return FutureBuilder<double?>(
          future: asset.currentValue != null
              ? CurrencyConverter.shared.convert(
                  asset.currentValue!,
                  originalCurrency,
                  currencySymbol,
                )
              : Future.value(null),
          builder: (context, snapshot) {
            final convertedCurrentValue = snapshot.data;
            final returnRate = convertedCurrentValue != null &&
                    asset.initialAmount > 0
                ? ((convertedCurrentValue / asset.initialAmount) - 1) * 100
                : null;

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _openAssetDetail(context, asset),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AssetIcon(
                                  assetId: asset.assetId,
                                  type: asset.assetType,
                                  size: 32,
                                ),
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
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      if (asset.assetId == 'cash')
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 2),
                                          child: Text(
                                            '${l10n.annualInterestRate}: ${NumberFormat('#,##0.##').format(asset.annualInterestRate)}%',
                                            style: const TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 13,
                                            ),
                                          ),
                                        )
                                      else
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 2),
                                          child: Text(
                                            '${l10n.quantity}: ${NumberFormat('#,##0.####').format(asset.quantity)}${l10n.retireQtyUnit}',
                                            style: const TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _deleteAsset(
                                    context,
                                    asset.id,
                                    provider,
                                    l10n,
                                  ),
                                  tooltip: l10n.delete,
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                    size: 22,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 36,
                                    minHeight: 36,
                                  ),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            _buildAssetMetricRow(
                              l10n.initialAmount,
                              '$currencySymbol${NumberFormat('#,##0.##').format(asset.initialAmount)}',
                            ),
                            if (convertedCurrentValue != null) ...[
                              if (asset.assetId != 'cash' && asset.quantity > 0)
                                _buildAssetMetricRow(
                                  l10n.currentPrice,
                                  '$currencySymbol${NumberFormat('#,##0.##').format(convertedCurrentValue / asset.quantity)}',
                                ),
                              _buildAssetMetricRow(
                                l10n.currentValue,
                                '$currencySymbol${NumberFormat('#,##0.##').format(convertedCurrentValue)}',
                              ),
                              if (returnRate != null)
                                _buildAssetMetricRow(
                                  l10n.returnRate,
                                  '${NumberFormat('#,##0.00').format(returnRate)}%',
                                  valueColor: convertedCurrentValue >=
                                          asset.initialAmount
                                      ? AppColors.success
                                      : Colors.red,
                                ),
                            ] else
                              _buildAssetMetricRow(
                                l10n.currentValue,
                                l10n.loadingPrice,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Material(
                    color: AppColors.primarySoft,
                    child: InkWell(
                      onTap: () => _openAssetDetail(context, asset),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 11,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.insights_outlined,
                              size: 16,
                              color: AppColors.primary.withValues(alpha: 0.9),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              l10n.viewAssetDetails,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showAddAssetDialog(
    BuildContext context,
    MyAssetsProvider provider,
    AppLocalizations l10n,
  ) async {
    // 자산 목록이 로드되지 않았으면 로드
    final appProvider = context.read<AppStateProvider>();
    if (appProvider.assets.isEmpty && !appProvider.isAssetsLoading) {
      appProvider.loadAssets();
    }

    await showDialog(context: context, builder: (context) => AddAssetDialog());
    // 다이얼로그가 닫힌 후 차트 다시 로드 (자산이 추가되었을 수 있으므로)
    if (mounted) {
      final currencySymbol = CurrencyProvider.shared.getCurrencySymbol();

      await provider.loadPortfolioChart(
        years: _selectedYears,
        targetCurrency: currencySymbol,
        getAssetOriginalCurrency: (assetId) =>
            _getAssetOriginalCurrency(
              assetId,
              appProvider,
              assetType: _resolveAssetType(provider, assetId),
            ),
      );
    }
  }

  void _deleteAsset(
    BuildContext context,
    String assetId,
    MyAssetsProvider provider,
    AppLocalizations l10n,
  ) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteAsset),
        content: Text(l10n.deleteAssetConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              await provider.removeAsset(assetId);
              Navigator.pop(context);
              // 차트 다시 로드
              final appProvider = context.read<AppStateProvider>();
              final currencySymbol = CurrencyProvider.shared
                  .getCurrencySymbol();

              await provider.loadPortfolioChart(
                years: _selectedYears,
                targetCurrency: currencySymbol,
                getAssetOriginalCurrency: (assetId) =>
                    _getAssetOriginalCurrency(
                      assetId,
                      appProvider,
                      assetType: _resolveAssetType(provider, assetId),
                    ),
              );
            },
            child: Text(l10n.delete, style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _WatchAdWithRequestDialog extends StatefulWidget {
  const _WatchAdWithRequestDialog({required this.l10n});

  final AppLocalizations l10n;

  @override
  State<_WatchAdWithRequestDialog> createState() =>
      _WatchAdWithRequestDialogState();
}

class _WatchAdWithRequestDialogState extends State<_WatchAdWithRequestDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return AlertDialog(
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: Text(
        l10n.watchAdChoiceTitle,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.watchAdChoiceMessage,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.aiUserRequestLabel,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              maxLines: 3,
              maxLength: 300,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: l10n.aiUserRequestHint,
                hintStyle: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
                filled: true,
                fillColor: AppColors.bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            l10n.cancel,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: Text(
            l10n.watchAdChoiceWatch,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
