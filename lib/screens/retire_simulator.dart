import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/asset_option.dart';
import '../providers/retire_simulator_provider.dart';
import '../providers/app_state_provider.dart';
import '../providers/currency_provider.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';
import '../widgets/app_ui.dart';
import '../widgets/asset_icon.dart';
import '../l10n/app_localizations.dart';
import '../services/ad_service.dart';
import 'retire_chart_reveal_screen.dart';

class RetireSimulatorScreen extends StatefulWidget {
  final bool isVisible;

  const RetireSimulatorScreen({super.key, this.isVisible = false});

  @override
  State<RetireSimulatorScreen> createState() => _RetireSimulatorScreenState();
}

class _RetireSimulatorScreenState extends State<RetireSimulatorScreen> {
  final TextEditingController _cashController = TextEditingController();
  final TextEditingController _monthlyController = TextEditingController();
  final Map<String, TextEditingController> _qtyControllers = {};
  String? _lastCurrencySymbol;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<RetireSimulatorProvider>();
      await provider.loadSettings();
      if (!mounted) return;
      _syncControllers(provider);
    });
  }

  @override
  void dispose() {
    _cashController.dispose();
    _monthlyController.dispose();
    for (final c in _qtyControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _syncControllers(RetireSimulatorProvider provider) {
    _cashController.text = NumberFormat('#,###').format(provider.cash.toInt());
    _monthlyController.text =
        NumberFormat('#,###').format(provider.monthlyWithdrawal.toInt());
    for (final h in provider.holdings) {
      _qtyControllers.putIfAbsent(
        h.assetId,
        () => TextEditingController(
          text: _formatQty(h.quantity),
        ),
      );
      final ctrl = _qtyControllers[h.assetId]!;
      final next = _formatQty(h.quantity);
      if (ctrl.text != next) ctrl.text = next;
    }
    // drop controllers for removed holdings
    final ids = provider.holdings.map((h) => h.assetId).toSet();
    final stale = _qtyControllers.keys.where((k) => !ids.contains(k)).toList();
    for (final id in stale) {
      _qtyControllers.remove(id)?.dispose();
    }
  }

  String _formatQty(double q) {
    if (q == q.roundToDouble()) return q.round().toString();
    return q.toString();
  }

  double _parseNumber(String text) {
    return double.tryParse(text.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
  }

  String _currencyUnit(String symbol) {
    switch (symbol) {
      case '₩':
        return '원';
      case '¥':
        return '円';
      case 'CN¥':
        return '元';
      default:
        return symbol;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RetireSimulatorProvider>();
    final appProvider = context.watch<AppStateProvider>();
    final l10n = AppLocalizations.of(context)!;
    final localeCode = Localizations.localeOf(context).languageCode;

    return ListenableBuilder(
      listenable: CurrencyProvider.shared,
      builder: (context, _) {
        final currencySymbol = CurrencyProvider.shared.getCurrencySymbol();
        final currencyUnit = _currencyUnit(currencySymbol);
        final currencyFormat = NumberFormat.currency(
          symbol: currencySymbol,
          decimalDigits: 0,
          locale: localeCode,
        );

        if (_lastCurrencySymbol != currencySymbol) {
          _lastCurrencySymbol = currencySymbol;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            provider.updateCurrencyDefaults(currencySymbol);
            _syncControllers(provider);
          });
        }

        if (appProvider.assets.isEmpty && !appProvider.isAssetsLoading) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            appProvider.loadAssets();
          });
        }

        return Scaffold(
          backgroundColor: AppColors.bg,
          body: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            behavior: HitTestBehavior.opaque,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.retirementSimulation,
                      style: AppTextStyles.homeMainQuestion.copyWith(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.retireFormSubtitle,
                      style: AppTextStyles.homeSubDescription.copyWith(
                        color: AppColors.textPrimary.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 24),

                    _sectionLabel(l10n.retireCashLabel),
                    const SizedBox(height: 8),
                    AppCard(
                      child: _amountField(
                        controller: _cashController,
                        unit: currencyUnit,
                        onChanged: (v) => provider.setCash(_parseNumber(v)),
                      ),
                    ),

                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: _sectionLabel(l10n.retireHoldingsLabel)),
                        Material(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            onTap: () => _openAssetPicker(
                              appProvider,
                              provider,
                              l10n,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.add,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    l10n.addAsset,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (provider.holdings.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          l10n.retireHoldingsEmpty,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      )
                    else
                      ...provider.holdings.map((h) {
                        final option = _findOption(appProvider, h.assetId);
                        final qtyCtrl = _qtyControllers.putIfAbsent(
                          h.assetId,
                          () => TextEditingController(text: _formatQty(h.quantity)),
                        );
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: AppCard(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                AssetIcon(
                                  assetId: h.assetId,
                                  type: option?.type,
                                  size: 22,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        option?.displayName() ?? h.assetId,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        h.isLoadingPrice
                                            ? l10n.loadingPrice
                                            : '(${currencyFormat.format(h.valuation)})',
                                        style: TextStyle(
                                          color: h.isLoadingPrice
                                              ? AppColors.textSecondary
                                              : AppColors.primary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: 88,
                                  child: TextField(
                                    controller: qtyCtrl,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'[\d.]'),
                                      ),
                                    ],
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                    decoration: InputDecoration(
                                      isDense: true,
                                      hintText: l10n.quantity,
                                      suffixText: l10n.retireQtyUnit,
                                      suffixStyle: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 10,
                                      ),
                                      filled: true,
                                      fillColor: AppColors.bg,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: const BorderSide(
                                          color: AppColors.border,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: const BorderSide(
                                          color: AppColors.border,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: const BorderSide(
                                          color: AppColors.primary,
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                    onChanged: (v) {
                                      provider.updateHoldingQuantity(
                                        h.assetId,
                                        _parseNumber(v),
                                      );
                                    },
                                  ),
                                ),
                                IconButton(
                                  onPressed: () =>
                                      provider.removeHolding(h.assetId),
                                  icon: const Icon(
                                    Icons.close,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),

                    const SizedBox(height: 8),
                    AppCard(
                      color: AppColors.primarySoft,
                      child: Row(
                        children: [
                          Text(
                            l10n.retireTotalNetWorth,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            currencyFormat.format(provider.totalNetWorth),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    _sectionLabel(l10n.retireMonthlySpendLabel),
                    const SizedBox(height: 8),
                    AppCard(
                      child: _amountField(
                        controller: _monthlyController,
                        unit: currencyUnit,
                        onChanged: (v) =>
                            provider.setMonthlyWithdrawal(_parseNumber(v)),
                      ),
                    ),

                    const SizedBox(height: 24),
                    _sectionLabel(l10n.duration),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [1, 3, 5, 7, 10, 15, 20, 30].map((y) {
                        return AppChip(
                          label: '$y${l10n.year}',
                          selected: provider.simulationYears == y,
                          onTap: () => provider.setSimulationYears(y),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),
                    _sectionLabel(l10n.inflationRate),
                    const SizedBox(height: 4),
                    Text(
                      l10n.inflationRateDesc,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    AppCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: Slider(
                              value: provider.inflationRate,
                              min: 0,
                              max: 0.1,
                              // 0.1% 단위 (0% ~ 10%) — 0.5% 단위는 너무 튀김
                              divisions: 100,
                              onChanged: provider.setInflationRate,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${(provider.inflationRate * 100).toStringAsFixed(1)}%',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    _sectionLabel(l10n.scenarioSelection),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _scenarioChip(
                            selected: provider.selectedScenario == 'positive',
                            label: l10n.scenarioPositive,
                            color: AppColors.success,
                            onTap: () =>
                                provider.setSelectedScenario('positive'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _scenarioChip(
                            selected: provider.selectedScenario == 'neutral',
                            label: l10n.scenarioNeutral,
                            color: AppColors.primary,
                            onTap: () =>
                                provider.setSelectedScenario('neutral'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _scenarioChip(
                            selected: provider.selectedScenario == 'negative',
                            label: l10n.scenarioNegative,
                            color: AppColors.danger,
                            onTap: () =>
                                provider.setSelectedScenario('negative'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),
                    if (kDebugMode) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton(
                          onPressed: provider.canRunSimulation
                              ? () => _runSimulationDirect(provider)
                              : null,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            '바로 실행 (Debug)',
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
                      label: provider.canRunSimulation
                          ? l10n.runSimulation
                          : (provider.isLoadingAnyPrice ||
                                  !provider.allCagrLoaded
                              ? l10n.loadingAnnualReturn
                              : l10n.runSimulation),
                      loading: false,
                      onPressed: provider.canRunSimulation
                          ? () => _runSimulation(provider)
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: AppTextStyles.settingsSectionLabel.copyWith(
        color: AppColors.textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _amountField({
    required TextEditingController controller,
    required String unit,
    required ValueChanged<String> onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[\d,]')),
        TextInputFormatter.withFunction((oldValue, newValue) {
          if (newValue.text.isEmpty) return newValue;
          final clean = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
          final n = int.tryParse(clean);
          if (n == null) return oldValue;
          final formatted = NumberFormat('#,###').format(n);
          return TextEditingValue(
            text: formatted,
            selection: TextSelection.collapsed(offset: formatted.length),
          );
        }),
      ],
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        suffixText: unit,
        suffixStyle: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
        border: InputBorder.none,
        isDense: true,
      ),
      onChanged: onChanged,
    );
  }

  Widget _scenarioChip({
    required bool selected,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : AppColors.border,
            width: selected ? 2 : 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? color : AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  AssetOption? _findOption(AppStateProvider app, String assetId) {
    try {
      return app.assets.firstWhere((a) => a.id == assetId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _openAssetPicker(
    AppStateProvider appProvider,
    RetireSimulatorProvider provider,
    AppLocalizations l10n,
  ) async {
    if (appProvider.assets.isEmpty) {
      await appProvider.loadAssets();
    }
    if (!mounted) return;

    final selected = await showModalBottomSheet<AssetOption>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final assets = appProvider.assets
            .where((a) => a.id != 'cash')
            .where((a) => !provider.holdings.any((h) => h.assetId == a.id))
            .toList();

        final byType = <String, List<AssetOption>>{};
        for (final a in assets) {
          byType.putIfAbsent(a.type, () => []).add(a);
        }
        final order = {
          'crypto': 0,
          'stock': 1,
          'korean_stock': 2,
          'real_estate': 3,
          'commodity': 4,
          'cash': 5,
        };
        final types = byType.keys.toList()
          ..sort((a, b) => (order[a] ?? 99).compareTo(order[b] ?? 99));

        String typeLabel(String t) {
          switch (t) {
            case 'crypto':
              return l10n.crypto;
            case 'korean_stock':
              return l10n.koreanStock;
            case 'real_estate':
              return l10n.realEstate;
            case 'commodity':
              return l10n.commodity;
            case 'cash':
              return l10n.cash;
            default:
              return l10n.stock;
          }
        }

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.45,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      l10n.selectAssetsTitle,
                      style: AppTextStyles.settingsAssetTitle,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    children: [
                      for (final type in types) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 12, bottom: 8),
                          child: Text(
                            typeLabel(type),
                            style: AppTextStyles.chartSectionTitle,
                          ),
                        ),
                        ...byType[type]!.map(
                          (asset) => ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                            ),
                            leading: AssetIcon(
                              assetId: asset.id,
                              type: asset.type,
                              size: 22,
                            ),
                            title: Text(
                              asset.displayName(),
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            trailing: const Icon(
                              Icons.add_circle_outline,
                              color: AppColors.primary,
                            ),
                            onTap: () => Navigator.pop(context, asset),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (selected != null) {
      await provider.addHolding(
        selected.id,
        quantity: 1,
        assetType: selected.type,
      );
      if (!mounted) return;
      _syncControllers(provider);
    }
  }

  Future<void> _runSimulationDirect(RetireSimulatorProvider provider) async {
    await provider.saveSettings();
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const RetireChartRevealScreen(),
      ),
    );
  }

  Future<void> _runSimulation(RetireSimulatorProvider provider) async {
    await provider.saveSettings();
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
    );

    await AdService.shared.showFullScreenAd(
      onAdDismissed: () {
        if (!mounted) return;
        Navigator.of(context).pop();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const RetireChartRevealScreen(),
          ),
        );
      },
      onAdFailedToShow: () {
        if (!mounted) return;
        Navigator.of(context).pop();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const RetireChartRevealScreen(),
          ),
        );
      },
    );
  }
}
