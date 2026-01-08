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
          backgroundColor: AppColors.navyDark,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(l10n.settings, style: AppTextStyles.appBarTitle),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.currencySettings,
                  style: AppTextStyles.chartSectionTitle,
                ),
                SizedBox(height: 16),
                LiquidGlass(
                  blur: 10,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                      width: 1.5,
                    ),
                  ),
                  padding: EdgeInsets.all(16),
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

    // 통화 옵션 리스트
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
      dropdownColor: AppColors.navyMedium,
      style: TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
      icon: Icon(Icons.arrow_drop_down, color: AppColors.gold),
      underline: Container(height: 2, color: AppColors.gold),
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
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
              if (symbol != null)
                Text(
                  symbol,
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                )
              else
                Text(
                  defaultSymbol,
                  style: TextStyle(color: AppColors.slate400, fontSize: 16),
                ),
              SizedBox(width: 8),
              if (isSelected)
                Icon(Icons.check_circle, color: AppColors.gold, size: 20),
            ],
          ),
        );
      }).toList(),
      onChanged: (String? newValue) async {
        // 통화 변경 전에 자산이 있는지 확인
        final myAssetsProvider = context.read<MyAssetsProvider>();
        if (myAssetsProvider.assets.isNotEmpty) {
          // 자산이 있으면 경고 다이얼로그 표시
          final shouldProceed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: AppColors.navyMedium,
              title: Text(
                l10n.currencyChangeWarning,
                style: TextStyle(color: Colors.white),
              ),
              content: Text(
                l10n.currencyChangeMessage,
                style: TextStyle(color: AppColors.slate300),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    l10n.cancel,
                    style: TextStyle(color: AppColors.slate400),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(
                    l10n.understand,
                    style: TextStyle(color: AppColors.gold),
                  ),
                ),
              ],
            ),
          );

          // 사용자가 취소했으면 통화 변경하지 않음
          if (shouldProceed != true) {
            return;
          }
        }

        // 통화 변경
        if (newValue == null) {
          await CurrencyProvider.shared.resetToDefault(localeCode);
        } else {
          await CurrencyProvider.shared.setCurrency(newValue);
        }
      },
    );
  }
}
