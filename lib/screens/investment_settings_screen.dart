import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import '../l10n/app_localizations.dart';
import '../models/investment_config.dart';
import '../providers/app_state_provider.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';
import '../widgets/liquid_glass.dart';
import '../services/ad_service.dart';
import '../providers/currency_provider.dart';
import 'result_screen.dart';
import 'settings_screen.dart';

class InvestmentSettingsScreen extends StatefulWidget {
  const InvestmentSettingsScreen({super.key});

  @override
  State<InvestmentSettingsScreen> createState() =>
      _InvestmentSettingsScreenState();
}

class _InvestmentSettingsScreenState extends State<InvestmentSettingsScreen> {
  final TextEditingController _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final config = context.read<AppStateProvider>().config;
      // If amount is default (1000), adjust based on locale
      if (config.amount == 1000) {
        final localeCode = Localizations.localeOf(context).languageCode;
        double newAmount = 1000;
        if (localeCode == 'ko') {
          newAmount = 1000000;
        } else if (localeCode == 'ja' || localeCode == 'zh') {
          newAmount =
              100000; // 100,000 for Yen/Yuan (approx $1000 scale, starting with 1)
        }

        if (newAmount != 1000) {
          context.read<AppStateProvider>().updateConfig(amount: newAmount);
          _amountController.text = NumberFormat('#,###').format(newAmount);
        } else {
          _amountController.text = NumberFormat('#,###').format(config.amount);
        }
      } else {
        _amountController.text = NumberFormat('#,###').format(config.amount);
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _calculateAndNavigate() async {
    final provider = context.read<AppStateProvider>();
    final l10n = AppLocalizations.of(context)!;
    String cleanAmount = _amountController.text.replaceAll(',', '');
    double? amount = double.tryParse(cleanAmount);
    if (amount != null) {
      provider.updateConfig(amount: amount);

      // Show loading
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withValues(alpha: 0.7), // 반투명 배경으로 터치 차단
        builder: (context) => WillPopScope(
          onWillPop: () async => false, // 뒤로가기 버튼도 차단
          child: Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 3,
            ),
          ),
        ),
      );

      // 광고 표시와 계산을 병렬로 실행
      debugPrint('📊 계산 시작');
      final calculationFuture = provider.calculate();

      // 광고 표시 (사용자가 광고를 보는 동안 계산이 백그라운드에서 진행됨)
      await AdService.shared.showFullScreenAd(
        onAdDismissed: () async {
          if (!mounted) return;
          // 광고가 끝나면 계산 완료 대기
          debugPrint('⏳ 광고 종료 - 계산 완료 대기 중...');
          await calculationFuture;
          debugPrint('✅ 계산 완료!');

          if (!mounted) return;
          Navigator.of(context).pop(); // Close loading dialog

          if (provider.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.calculationError(provider.error!)),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }

          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (context) => ResultScreen()));
        },
        onAdFailedToShow: () async {
          // 광고 실패 시에도 계산 완료 대기
          if (!mounted) return;
          debugPrint('❌ 광고 실패 - 계산 완료 대기 중...');
          await calculationFuture;
          debugPrint('✅ 계산 완료!');

          if (!mounted) return;
          Navigator.of(context).pop(); // Close loading dialog

          if (provider.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.calculationError(provider.error!)),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }

          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (context) => ResultScreen()));
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppStateProvider>();
    final config = provider.config;
    final assetName = provider.assetNameForLocale();
    final l10n = AppLocalizations.of(context)!;

    return ListenableBuilder(
      listenable: CurrencyProvider.shared,
      builder: (context, _) {
        final currencySymbol = CurrencyProvider.shared.getCurrencySymbol();

        return Scaffold(
          backgroundColor: AppColors.bg,
          appBar: AppBar(
            backgroundColor: AppColors.bg,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              l10n.investmentSettingsTitle(assetName),
              style: AppTextStyles.appBarTitle,
            ),
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Years Slider
                Text(
                  l10n.investmentStartDate(
                    DateTime.now().year - config.yearsAgo,
                    config.yearsAgo,
                  ),
                  style: AppTextStyles.settingsSectionLabel,
                ),
                SizedBox(height: 10),
                LiquidGlass(
                  blur: 10,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.border,
                      width: 1.5,
                    ),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: AppColors.primary,
                      inactiveTrackColor: AppColors.border,
                      thumbColor: AppColors.primary,
                      overlayColor: AppColors.primary.withValues(alpha: 0.2),
                      trackHeight: 4,
                      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 10),
                    ),
                    child: Slider(
                      value: config.yearsAgo.toDouble(),
                      min: 1,
                      max: 10,
                      divisions: 9,
                      onChanged: (value) {
                        provider.updateConfig(yearsAgo: value.toInt());
                      },
                    ),
                  ),
                ),

                SizedBox(height: 30),

                // Amount Input
                Text(
                  l10n.investmentAmountLabel,
                  style: AppTextStyles.settingsSectionLabel,
                ),
                SizedBox(height: 10),
                TextField(
                  controller: _amountController,
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      String cleanText = value.replaceAll(',', '');
                      if (cleanText.isNotEmpty) {
                        final number = int.tryParse(cleanText);
                        if (number != null) {
                          final formatted = NumberFormat(
                            '#,###',
                          ).format(number);
                          if (formatted != value) {
                            _amountController.value = TextEditingValue(
                              text: formatted,
                              selection: TextSelection.collapsed(
                                offset: formatted.length,
                              ),
                            );
                          }
                        }
                      }
                    }
                    setState(() {});
                  },
                  onTapOutside: (event) =>
                      FocusManager.instance.primaryFocus?.unfocus(),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: AppTextStyles.settingsAmountInput,
                  decoration: InputDecoration(
                    prefixText: "$currencySymbol ",
                    prefixStyle: AppTextStyles.settingsAmountPrefix,
                    suffixIcon: GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const SettingsScreen(),
                          ),
                        );
                      },
                      child: Tooltip(
                        message: l10n.currencySettings,
                        child: Icon(
                          Icons.currency_exchange,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),

                SizedBox(height: 30),

                // Investment Type
                Text(
                  l10n.investmentTypeLabel,
                  style: AppTextStyles.settingsSectionLabel,
                ),
                SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.border,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildInvestmentTypeButton(
                              label: l10n.singleInvestment,
                              isSelected: config.type == InvestmentType.single,
                              onTap: () {
                                provider.updateConfig(
                                  type: InvestmentType.single,
                                );
                              },
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: _buildInvestmentTypeButton(
                              label: l10n.recurringInvestment,
                              isSelected:
                                  config.type == InvestmentType.recurring,
                              onTap: () {
                                provider.updateConfig(
                                  type: InvestmentType.recurring,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Frequency (Animated)
                AnimatedSwitcher(
                  duration: Duration(milliseconds: 300),
                  child: config.type == InvestmentType.recurring
                      ? Padding(
                          key: ValueKey("frequency-options"),
                          padding: EdgeInsets.only(top: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.investmentFrequencyLabel,
                                style: AppTextStyles.settingsSectionLabel,
                              ),
                              SizedBox(height: 12),
                              Wrap(
                                spacing: 16,
                                runSpacing: 12,
                                children: [
                                  _buildFrequencyOption(
                                    Frequency.monthly,
                                    l10n.monthly,
                                    provider,
                                  ),
                                  _buildFrequencyOption(
                                    Frequency.weekly,
                                    l10n.weekly,
                                    provider,
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                l10n.frequencySelectionHint,
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        )
                      : SizedBox.shrink(key: ValueKey("frequency-empty")),
                ),

                SizedBox(height: 40),

                // Summary Preview
                LiquidGlass(
                  blur: 10,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.border,
                      width: 1.5,
                    ),
                  ),
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.primary),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _getSummaryText(
                            config,
                            assetName,
                            l10n,
                            currencySymbol,
                          ),
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 40),

                // Calculate Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: GestureDetector(
                        onTap: _calculateAndNavigate,
                        child: Container(
                          width: double.infinity,
                          height: 56,
                          decoration: SelectedButtonStyle.solidBoxDecoration(
                            BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              l10n.viewResults,
                              style: AppTextStyles.buttonTextPrimary.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInvestmentTypeButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: isSelected
            ? SelectedButtonStyle.solidBoxDecoration(BorderRadius.circular(8))
            : BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.white, width: 2),
                  color: Colors.white,
                ),
                child: Icon(Icons.check, size: 14, color: AppColors.primary),
              ),
              SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrequencyOption(
    Frequency value,
    String label,
    AppStateProvider provider,
  ) {
    final isSelected = provider.config.selectedFrequencies.contains(value);

    return GestureDetector(
      onTap: () => provider.toggleFrequencySelection(value),
      child: isSelected
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: SelectedButtonStyle.solidBoxDecoration(
                    BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                          color: Colors.white,
                        ),
                        child: Icon(
                          Icons.check,
                          size: 14,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        label,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : LiquidGlass(
              blur: 10,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.border,
                  width: 1.5,
                ),
              ),
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.textSecondary, width: 2),
                      color: Colors.transparent,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  String _getSummaryText(
    InvestmentConfig config,
    String assetName,
    AppLocalizations l10n,
    String currencySymbol,
  ) {
    String amount = _amountController.text.isEmpty
        ? '0'
        : _amountController.text;
    String formattedAmount = "$currencySymbol$amount";

    if (config.type == InvestmentType.single) {
      return l10n.summarySingle(formattedAmount, assetName, config.yearsAgo);
    } else {
      // Calculate per-period investment amount
      String cleanAmount = amount.replaceAll(',', '');
      double? totalAmount = double.tryParse(cleanAmount);

      if (totalAmount == null || totalAmount == 0) {
        // Default to monthly if no amount
        return l10n.summaryRecurringMonthly(
          assetName,
          "$currencySymbol 0",
          config.yearsAgo,
        );
      }

      // Calculate per-period amount based on last clicked frequency
      // Use config.frequency which stores the last clicked frequency
      final lastClickedFrequency = config.frequency;

      double perPeriodAmount;
      bool useWeekly;

      if (lastClickedFrequency == Frequency.weekly) {
        // Weekly: total / (years * 52)
        perPeriodAmount = totalAmount / (config.yearsAgo * 52);
        useWeekly = true;
      } else {
        // Monthly: total / (years * 12)
        perPeriodAmount = totalAmount / (config.yearsAgo * 12);
        useWeekly = false;
      }

      String formattedPerPeriodAmount =
          "$currencySymbol${NumberFormat('#,###').format(perPeriodAmount.round())}";

      if (useWeekly) {
        return l10n.summaryRecurringWeekly(
          assetName,
          formattedPerPeriodAmount,
          config.yearsAgo,
        );
      } else {
        return l10n.summaryRecurringMonthly(
          assetName,
          formattedPerPeriodAmount,
          config.yearsAgo,
        );
      }
    }
  }
}
