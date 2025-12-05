import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/currency_provider.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyProvider = context.watch<CurrencyProvider>();
    final localeCode = Localizations.localeOf(context).languageCode;

    return Scaffold(
      backgroundColor: AppColors.navyDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('설정', style: AppTextStyles.appBarTitle),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('통화 설정', style: AppTextStyles.chartSectionTitle),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.navyMedium,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.slate700),
              ),
              child: Column(
                children: [
                  _buildCurrencyOption(
                    context,
                    currencyProvider,
                    localeCode,
                    '₩',
                    '원 (KRW)',
                    '한국 원',
                  ),
                  Divider(color: AppColors.slate700),
                  _buildCurrencyOption(
                    context,
                    currencyProvider,
                    localeCode,
                    '\$',
                    '달러 (USD)',
                    '미국 달러',
                  ),
                  Divider(color: AppColors.slate700),
                  _buildCurrencyOption(
                    context,
                    currencyProvider,
                    localeCode,
                    '¥',
                    '엔 (JPY)',
                    '일본 엔',
                  ),
                  Divider(color: AppColors.slate700),
                  _buildCurrencyOption(
                    context,
                    currencyProvider,
                    localeCode,
                    'CN¥',
                    '위안 (CNY)',
                    '중국 위안',
                  ),
                  Divider(color: AppColors.slate700),
                  _buildCurrencyOption(
                    context,
                    currencyProvider,
                    localeCode,
                    null,
                    '기본값 (언어별 자동)',
                    '언어에 따라 자동으로 설정',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyOption(
    BuildContext context,
    CurrencyProvider currencyProvider,
    String localeCode,
    String? currencySymbol,
    String title,
    String subtitle,
  ) {
    final isSelected = currencySymbol == null
        ? currencyProvider.selectedCurrency == null
        : currencyProvider.selectedCurrency == currencySymbol;
    final defaultSymbol = currencyProvider.getCurrencySymbol(localeCode);

    return InkWell(
      onTap: () async {
        if (currencySymbol == null) {
          await currencyProvider.resetToDefault(localeCode);
        } else {
          await currencyProvider.setCurrency(currencySymbol);
        }
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: AppColors.slate400, fontSize: 14),
                  ),
                ],
              ),
            ),
            if (currencySymbol != null)
              Text(
                currencySymbol,
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
            SizedBox(width: 12),
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? AppColors.gold : AppColors.slate400,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
