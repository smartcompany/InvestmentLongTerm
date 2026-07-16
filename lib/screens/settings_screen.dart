import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/currency_provider.dart';
import '../providers/my_assets_provider.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';
import '../widgets/liquid_glass.dart';
import '../l10n/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localeCode = Localizations.localeOf(context).languageCode;
    final l10n = AppLocalizations.of(context)!;

    return ListenableBuilder(
      listenable: CurrencyProvider.shared,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.bg,
          appBar: AppBar(
            backgroundColor: AppColors.bg,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(l10n.settings, style: AppTextStyles.appBarTitle),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.currencySettings,
                  style: AppTextStyles.chartSectionTitle,
                ),
                const SizedBox(height: 16),
                LiquidGlass(
                  blur: 10,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border, width: 1.5),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: _buildCurrencyDropdown(
                    context,
                    CurrencyProvider.shared,
                    localeCode,
                    l10n,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCurrencyDropdown(
    BuildContext context,
    CurrencyProvider currencyProvider,
    String localeCode,
    AppLocalizations l10n,
  ) {
    final selectedCurrency = currencyProvider.selectedCurrency;
    final defaultSymbol = currencyProvider.getCurrencySymbol();

    final currencyOptions = [
      {'symbol': null, 'label': l10n.currencyDefault},
      {'symbol': '₩', 'label': l10n.currencyKRW},
      {'symbol': '\$', 'label': l10n.currencyUSD},
      {'symbol': '¥', 'label': l10n.currencyJPY},
      {'symbol': 'CN¥', 'label': l10n.currencyCNY},
    ];

    return DropdownButton<String?>(
      value: selectedCurrency,
      isExpanded: true,
      dropdownColor: AppColors.surface,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
      icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
      underline: Container(height: 2, color: AppColors.primary),
      items: currencyOptions.map((option) {
        final symbol = option['symbol'];
        final label = option['label'] as String;
        final isSelected = symbol == selectedCurrency;

        return DropdownMenuItem<String?>(
          value: symbol,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              if (symbol != null)
                Text(
                  symbol,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                )
              else
                Text(
                  defaultSymbol,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
              const SizedBox(width: 8),
              if (isSelected)
                const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
            ],
          ),
        );
      }).toList(),
      onChanged: (String? newValue) async {
        final myAssetsProvider = context.read<MyAssetsProvider>();
        if (myAssetsProvider.assets.isNotEmpty) {
          final shouldProceed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: AppColors.surface,
              title: Text(
                l10n.currencyChangeWarning,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              content: Text(
                l10n.currencyChangeMessage,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    l10n.cancel,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(
                    l10n.understand,
                    style: const TextStyle(color: AppColors.primary),
                  ),
                ),
              ],
            ),
          );

          if (shouldProceed != true) {
            return;
          }
        }

        if (newValue == null) {
          await CurrencyProvider.shared.resetToDefault(localeCode);
        } else {
          await CurrencyProvider.shared.setCurrency(newValue);
        }
      },
    );
  }
}
