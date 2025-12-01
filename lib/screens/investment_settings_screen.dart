import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/investment_config.dart';
import '../providers/app_state_provider.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';
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
    final config = context.read<AppStateProvider>().config;
    _amountController.text = config.amount.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _calculateAndNavigate() async {
    final provider = context.read<AppStateProvider>();
    final l10n = AppLocalizations.of(context)!;
    double? amount = double.tryParse(_amountController.text);
    if (amount != null) {
      provider.updateConfig(amount: amount);
      await provider.calculate();

      if (!mounted) return;

      if (provider.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.calculationError(provider.error!)),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (context) => ResultScreen()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppStateProvider>();
    final config = provider.config;
    final localeCode = Localizations.localeOf(context).languageCode;
    final assetName = provider.assetNameForLocale(localeCode);
    final l10n = AppLocalizations.of(context)!;

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
              l10n.investmentStartDate(config.yearsAgo),
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
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: AppTextStyles.settingsAmountInput,
              decoration: InputDecoration(
                prefixText: "\$ ",
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
                      _getSummaryText(config, assetName, l10n),
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
  ) {
    String amount = _amountController.text.isEmpty
        ? '0'
        : _amountController.text;

    if (config.type == InvestmentType.single) {
      return l10n.summarySingle(config.yearsAgo, assetName, amount);
    } else {
      final hasMonthly = config.selectedFrequencies.contains(Frequency.monthly);
      final hasWeekly = config.selectedFrequencies.contains(Frequency.weekly);

      String freqLabel;
      if (hasMonthly && hasWeekly) {
        freqLabel = l10n.monthlyAndWeekly;
      } else if (hasMonthly) {
        freqLabel = l10n.monthly;
      } else {
        freqLabel = l10n.weekly;
      }

      return l10n.summaryRecurring(
        config.yearsAgo,
        assetName,
        freqLabel,
        amount,
      );
    }
  }
}
