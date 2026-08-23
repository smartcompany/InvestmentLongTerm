import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/investment_insight.dart';
import '../utils/colors.dart';

Future<void> showInvestmentInsightDialog(
  BuildContext context, {
  required InvestmentInsight insight,
}) {
  final l10n = AppLocalizations.of(context)!;

  return showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          l10n.aiInsightTitle,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _section(l10n.aiInsightSummary, insight.summary),
                const SizedBox(height: 16),
                _section(l10n.aiInsightOutlook, insight.outlook),
                if (insight.suggestions.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _bulletSection(
                    l10n.aiInsightSuggestions,
                    insight.suggestions,
                  ),
                ],
                if (insight.risks.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _bulletSection(l10n.aiInsightRisks, insight.risks),
                ],
                const SizedBox(height: 16),
                Text(
                  insight.disclaimer.isNotEmpty
                      ? insight.disclaimer
                      : l10n.aiInsightDisclaimer,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.confirm),
          ),
        ],
      );
    },
  );
}

Widget _section(String title, String body) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        body,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          height: 1.45,
        ),
      ),
    ],
  );
}

Widget _bulletSection(String title, List<String> items) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 6),
      ...items.map(
        (item) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '•  ',
                style: TextStyle(color: AppColors.textPrimary, height: 1.45),
              ),
              Expanded(
                child: Text(
                  item,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
