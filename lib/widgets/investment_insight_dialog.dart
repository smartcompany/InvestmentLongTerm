import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/investment_insight.dart';
import '../utils/colors.dart';
import 'ai_rich_text.dart';

Future<void> showInvestmentInsightDialog(
  BuildContext context, {
  required InvestmentInsight insight,
}) {
  final l10n = AppLocalizations.of(context)!;
  final maxWidth = MediaQuery.of(context).size.width;

  return showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: AppColors.surface,
        insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
        titlePadding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
        contentPadding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        title: Text(
          l10n.aiInsightTitle,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        content: SizedBox(
          width: maxWidth,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _section(
                  Icons.insights_outlined,
                  l10n.aiInsightSummary,
                  insight.summary,
                ),
                const SizedBox(height: 16),
                _section(
                  Icons.trending_up,
                  l10n.aiInsightOutlook,
                  insight.outlook,
                ),
                if (insight.suggestions.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _bulletSection(
                    Icons.lightbulb_outline,
                    l10n.aiInsightSuggestions,
                    insight.suggestions,
                  ),
                ],
                if (insight.risks.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _bulletSection(
                    Icons.warning_amber_outlined,
                    l10n.aiInsightRisks,
                    insight.risks,
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  insight.disclaimer.isNotEmpty
                      ? insight.disclaimer
                      : l10n.aiInsightDisclaimer,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.confirm,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      );
    },
  );
}

Widget _sectionTitle(IconData icon, String title) {
  return Row(
    children: [
      Icon(icon, size: 18, color: AppColors.primary),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    ],
  );
}

Widget _section(IconData icon, String title, String body) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionTitle(icon, title),
      const SizedBox(height: 6),
      AiRichText(body),
    ],
  );
}

Widget _bulletSection(IconData icon, String title, List<String> items) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionTitle(icon, title),
      const SizedBox(height: 6),
      ...items.map(
        (item) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.circle,
                  size: 7,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: AiRichText(item)),
            ],
          ),
        ),
      ),
    ],
  );
}
