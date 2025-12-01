import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../models/investment_config.dart';
import '../providers/app_state_provider.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';
import '../services/ad_service.dart';
import 'result_screen.dart';

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
        builder: (context) =>
            Center(child: CircularProgressIndicator(color: AppColors.gold)),
      );

      // Calculate results
      await provider.calculate();

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

      // Load ad settings and show ad
      await AdService.shared.loadSettings();

      if (!mounted) return;

      await AdService.shared.showInterstitialAd(
        onAdDismissed: () {
          if (!mounted) return;
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (context) => ResultScreen()));
        },
        onAdFailedToShow: () {
          // If ad fails, proceed anyway
          if (!mounted) return;
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (context) => ResultScreen()));
        },
      );
    }
  }

  String _getCurrencySymbol(String localeCode) {
    switch (localeCode) {
      case 'ko':
        return '₩';
      case 'ja':
        return '¥';
      case 'zh':
        return 'CN¥';
      case 'en':
      default:
        return '\$';
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppStateProvider>();
    final config = provider.config;
    final localeCode = Localizations.localeOf(context).languageCode;
    final assetName = provider.assetNameForLocale(localeCode);
    final l10n = AppLocalizations.of(context)!;
    final currencySymbol = _getCurrencySymbol(localeCode);

    return Scaffold(
      backgroundColor: AppColors.navyDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.investmentSettingsTitle(assetName),
              style: AppTextStyles.settingsAssetTitle,
            ),
            SizedBox(height: 40),

            // Years Slider
            Text(
              l10n.investmentStartDate(
                DateTime.now().year - config.yearsAgo,
                config.yearsAgo,
              ),
              style: AppTextStyles.settingsSectionLabel,
            ),
            SizedBox(height: 10),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: AppColors.gold,
                inactiveTrackColor: AppColors.slate700,
                thumbColor: AppColors.gold,
                overlayColor: AppColors.gold.withValues(alpha: 0.2),
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
                      final formatted = NumberFormat('#,###').format(number);
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
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.slate700),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.gold),
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
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<InvestmentType>(
                segments: [
                  ButtonSegment(
                    value: InvestmentType.single,
                    label: Text(l10n.singleInvestment),
                  ),
                  ButtonSegment(
                    value: InvestmentType.recurring,
                    label: Text(l10n.recurringInvestment),
                  ),
                ],
                selected: {config.type},
                onSelectionChanged: (Set<InvestmentType> newSelection) {
                  provider.updateConfig(type: newSelection.first);
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith<Color>((
                    states,
                  ) {
                    if (states.contains(WidgetState.selected)) {
                      return AppColors.gold;
                    }
                    return AppColors.navyMedium;
                  }),
                  foregroundColor: WidgetStateProperty.resolveWith<Color>((
                    states,
                  ) {
                    if (states.contains(WidgetState.selected)) {
                      return AppColors.navyDark;
                    }
                    return Colors.white;
                  }),
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
                              color: AppColors.slate400,
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
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.navyMedium,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.slate700),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.gold),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _getSummaryText(config, assetName, l10n, currencySymbol),
                      style: TextStyle(color: AppColors.slate300),
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
              child: ElevatedButton(
                onPressed: _calculateAndNavigate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.navyDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  l10n.viewResults,
                  style: AppTextStyles.buttonTextPrimary,
                ),
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
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.gold : AppColors.slate700,
          ),
          color: isSelected
              ? AppColors.gold.withValues(alpha: 0.08)
              : AppColors.navyMedium,
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
                  color: isSelected ? AppColors.gold : AppColors.slate400,
                  width: 2,
                ),
                color: isSelected ? AppColors.gold : Colors.transparent,
              ),
              child: isSelected
                  ? Icon(Icons.check, size: 14, color: AppColors.navyDark)
                  : null,
            ),
            SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
