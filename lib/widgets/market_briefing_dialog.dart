import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/market_briefing.dart';
import '../utils/colors.dart';
import 'asset_icon.dart';

Future<void> showMarketBriefingDialog(
  BuildContext context, {
  required MarketBriefing briefing,
}) {
  final l10n = AppLocalizations.of(context)!;

  return showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: AppColors.surface,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.marketBriefingTitle,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            if (briefing.asOfDate.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                briefing.asOfDate,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (briefing.todayHeadline.isNotEmpty) ...[
                  Text(
                    briefing.todayHeadline,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (briefing.assetConditions.isNotEmpty) ...[
                  Text(
                    l10n.marketBriefingConditions,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...briefing.assetConditions.map(
                    (c) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ConditionCard(condition: c),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                _section(l10n.marketBriefingSummary, briefing.marketSummary),
                if (briefing.holdingsFocus.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _bulletSection(
                    l10n.marketBriefingHoldingsFocus,
                    briefing.holdingsFocus,
                  ),
                ],
                const SizedBox(height: 16),
                _section(
                  l10n.marketBriefingOutlook,
                  briefing.nearTermOutlook,
                ),
                if (briefing.watchPoints.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _bulletSection(
                    l10n.marketBriefingWatchPoints,
                    briefing.watchPoints,
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  briefing.disclaimer.isNotEmpty
                      ? briefing.disclaimer
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

class _ConditionCard extends StatelessWidget {
  final HoldingCondition condition;

  const _ConditionCard({required this.condition});

  static ({IconData icon, Color color, Color bg, String fallbackLabel})
      styleFor(String mood) {
    switch (mood) {
      case 'hot':
        return (
          icon: Icons.local_fire_department,
          color: const Color(0xFFE53935),
          bg: const Color(0xFFFFEBEE),
          fallbackLabel: 'Hot',
        );
      case 'choppy':
        return (
          icon: Icons.waves,
          color: const Color(0xFF5C6BC0),
          bg: const Color(0xFFE8EAF6),
          fallbackLabel: 'Choppy',
        );
      case 'cool':
        return (
          icon: Icons.ac_unit,
          color: const Color(0xFF039BE5),
          bg: const Color(0xFFE1F5FE),
          fallbackLabel: 'Cool',
        );
      case 'watch':
        return (
          icon: Icons.visibility_outlined,
          color: const Color(0xFF8E24AA),
          bg: const Color(0xFFF3E5F5),
          fallbackLabel: 'Watch',
        );
      case 'steady':
      default:
        return (
          icon: Icons.spa_outlined,
          color: const Color(0xFF43A047),
          bg: const Color(0xFFE8F5E9),
          fallbackLabel: 'Steady',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = styleFor(condition.mood);
    final label =
        condition.label.isNotEmpty ? condition.label : style.fallbackLabel;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: style.color.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 큰 무드 아이콘 (아이코닉 포인트)
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: style.color,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(style.icon, size: 28, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AssetIcon(assetId: condition.assetId, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        condition.name.isNotEmpty
                            ? condition.name
                            : condition.assetId,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: style.color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(style.icon, size: 15, color: style.color),
                      const SizedBox(width: 5),
                      Text(
                        label,
                        style: TextStyle(
                          color: style.color,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                if (condition.note.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    condition.note,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
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
